#!/bin/bash

# shellcheck disable=SC2034
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLACK='\033[0;30m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NO_COLOR='\033[0m'

LOG_INFO(){
  echo -e "${GREEN}[INFO]: $1${NO_COLOR}"
}

LOG_WARNING (){
  echo -e "${YELLOW}[WARNING]: $1${NO_COLOR}"
}

LOG_ERROR(){
  echo -e "${RED}[ERROR]: $1${NO_COLOR}"
}

create_symbolic_link() {
  local source=${1:?}
  local target=${2:?}
  rm -f "${target}"
  ln -s "${source}" "${target}"
}

package_available() {
  local package="$1"
  # Check if the package is available in the repository
  available=$(apt-cache show "$package" 2>/dev/null)

  # If the package is not found in the repository, return 1 (not available)
  if [ -z "$available" ]; then
    return 1
  else
    return 0
  fi
}

RELEASE_CODENAME="$(lsb_release -cs || echo 'unknown')"

case "${RELEASE_CODENAME}" in
    "jammy")
      ROS_DISTRO="humble"
    ;;
    *)
      ROS_DISTRO="unknown"
    ;;
esac

export RELEASE_CODENAME
export ROS_DISTRO
