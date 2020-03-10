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

# punto de control
if [ ! -z "$(ls -AR $dst)" ]; then
  echo -n "${CYAN_BULLET} Do you really want to continue (N/y): ${RESET}"
  read answer
  [ "$answer" == "y" ] || error_and_exit "Good bye." 3
  echo ""
fi

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
    error_and_exit "this installer needs the ability to run commands as ${BOLD}\"root\"${ERROR_RESET}." 2
  fi
fi

# purgamos la registry
$shx "$dco exec master sh -c '/bin/registry garbage-collect --dry-run /etc/docker/registry/config.yml'"

# au revoir
[ $? -eq 0 ] && echo "${GREEN}${BOLD}Done.${RESET}"
