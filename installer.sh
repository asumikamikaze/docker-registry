#!/bin/bash
# --
# ak | Docker Registry for Development v1.0
#
# Author(s):
#   - Alejandro M. BERNARDIS <ambernardis at asumikamikaze.com>
#   - Gabriel H. CETRARO <ghcetraro at asumikamikaze.com>
# Created: 2020-03-08
# ~
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

# verifica si el comando existe
command_exists() {
  command -v "$@" > /dev/null 2>&1
}

# welcome
echo "${GREEN_BULLET}${CYAN}${BOLD}REGISTRY INSTALLER v1.0${RESET}"

# verificamos los comandos principales
for cmd in git curl docker docker-compose; do
  if ! command_exists $cmd; then
    error_and_exit "command ${BOLD}\"$cmd\"${ERROR_RESET} not found" 1
  fi
done

# definimos el contexto de ejecución
shx="sh -c"
pth="$(pwd)"
dco="docker-compose --log-level ERROR"

# verificamos que el script se ejecute como root
if [ "$(id -un 2>/dev/null || true)" != "root" ]; then
  if command_exists sudo; then
    shx="sudo -E sh -c"
  elif command_exists su; then
    shx="su -c"
  else
    error_and_exit "This installer needs the ability to run commands as ${BOLD}\"root\"${ERROR_RESET}." 2
  fi
fi

# actualizamos el repositorio
if [ -d "${pth}/.git" ]; then
  $shx "git pull --rebase --stat origin master"
else
  [ -d "$pth/docker-registry" ] && $shx "yes | rm -vfr $pth/docker-registry"
  $shx "git clone -b master --single-branch https://github.com/asumikamikaze/docker-registry.git"
  cd docker-registry
  pth="$(pwd)"
fi

# cargamos las variables de entorno
src_env=$pth/.env
if [ -f $src_env ]; then
  source $src_env
fi

# definimos el directorio destino
dst=${BASEPATH:-"/data/registry/master"}
pss="${dst}/auth/htpasswd"

# verificamos que nada este deplegado
! ($shx "$dco ps -q &> /dev/null") \
  || $shx "$dco down"

# punto de control
if [ ! -z "$(ls -AR $dst)" ]; then
  echo "${YELLOW_BULLET}${YELLOW} the ${BOLD}'${pth}/data'${RESET}${YELLOW}
    directory is not empty, in the installation
    process it will be deleted."
  echo -n "${CYAN_BULLET} Continue (N/y): ${RESET}"
  read answer
  [ "$answer" == "y" ] || error_and_exit "Good bye." 3
  echo ""
fi

# regeneramos la estructura de directorios
$shx "yes | rm -vfr $dst"
$shx "mkdir -vp $dst/{auth,cache,certs,data}"
$shx "yes | cp -vf $pth/{.env,config.yml,docker-compose.yml,prune.sh} $dst/"
$shx "touch $pss"

# creamos la red para la registry
($shx "docker network inspect registry &> /dev/null") \
  || $shx "docker network create --subnet=172.100.0.0/24 --driver=bridge registry"

# desplegamos
$shx "$dco --compatibility up -d"

# creamos los usuarios
check_times=0
while :
do
  if ($shx "$dco ps -q master &> /dev/null"); then
    $shx "$dco exec master htpasswd -Bbn admin admin > $pss"
    break
  fi
  [ $check_times -gt 9 ] && break
  ((check_times++))
  sleep 5
done

# reparamos los permisos del directorio
$shx "chgrp -R docker $dst"

# au revoir
[ $? -eq 0 ] && echo "${GREEN}${BOLD}Done.${RESET}"
