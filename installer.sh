#!/bin/bash
# Author: Alejandro M. BERNARDIS
# Email: alejandro.bernardis at gmail.com
# Created: 2019/11/11 10:49

set -e

# colors
BLACK=$(printf '\033[30m')
RED=$(printf '\033[31m')
GREEN=$(printf '\033[32m')
YELLOW=$(printf '\033[33m')
BLUE=$(printf '\033[34m')
MAGENTA=$(printf '\033[35m')
CYAN=$(printf '\033[36m')
GRAY=$(printf '\033[37m')

# styles
NORMAL=$(printf '\033[0m')
BOLD=$(printf '\033[1m')
RESET=$(printf '\033[m')
GREEN_BULLET="${GREEN} > ${RESET}"
YELLOW_BULLET="${YELLOW} ! ${RESET}"
CYAN_BULLET="${CYAN} ? ${RESET}"
ERROR_RESET="${RESET}${RED}"

# imprime el error en pantalla y sale
error_and_exit() {
  local message=${1:-"Not controlled"}
  local code=${2:-"1"}
  echo >&2 "${YELLOW_BULLET}${RED}(e) ${message}.${RESET}"
  exit $code
}

# welcome
echo "${GREEN_BULLET}${CYAN}${BOLD}REGISTRY INSTALLER v1.0 (pichu)${RESET}"

# verificamos que el script se ejecute como root
[ "$(id -u)" -eq "0" ] \
  || error_and_exit "run script with ${BOLD}\"root\"${ERROR_RESET} user" 1

# verificamos los comandos principales
for cmd in docker docker-compose htpasswd git; do
  if ! command -v $cmd &> /dev/null; then
    error_and_exit "command ${BOLD}\"$cmd\"${ERROR_RESET} not found" 2
  fi
done

# actualizamos el repositorio
git pull --rebase --stat origin master

# base path
_base_path="$(pwd)/master"

# creamos los directorios
mkdir -p $_base_path/{auth,cache,certs,data}

# punto de control
if [ -z "$(ls -A ${_base_path}/data)" ]; then
  echo "
${YELLOW_BULLET}${YELLOW} El directorio ${BOLD}\"${_base_path}/data\"${RESET}${YELLOW}
    no se encuentra vacío, en el proceso
    de instalación éste será borrado.
"
  echo -n "${CYAN_BULLET} Desea continuar (N/y): ${RESET}"
  read answer
  [ "${answer}" == "y" ] || exit -1
  echo ""
fi

# verificamos que nada este deplegado
! (docker-compose ps -q &> /dev/null) \
  || docker-compose down

# purgamos los archivos en caso de existir
yes | rm -fr $_base_path/auth/* $_base_path/cache/* $_base_path/data/*

# creamos los usuarios para acceder a la registry
htpasswd_file="${_base_path}/auth/htpasswd"
touch $htpasswd_file
htpasswd -bB $htpasswd_file admin y34r2.19g=
# htpasswd -bB $htpasswd_file user0001 P4sW0r.1
# htpasswd -bB $htpasswd_file user0002 P4sW0r.2

# creamos la red para la registry
(docker network inspect registry &> /dev/null) \
  || docker network create --subnet=172.100.0.0/24 --driver=bridge registry

# desplegamos
docker-compose --compatibility up -d

# reparamos los permisos del directorio
chgrp -R docker "$(pwd)"

# au revoir
[ $? -eq 0 ] && echo "${GREEN}${BOLD}Done.${RESET}"
