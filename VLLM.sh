#!/bin/bash
set -e
source "/home/aanliker/DeepSeek-VL/util.sh"

usage() {
  echo -e 'Usage: train [COMMAND] [OPTIONS]

Commands:
  train          Run the LLM on Sagemaker.
Options:
  run:
  --run_name [name]       Name of training run.
' 1>&2
}

command="${1}"
if [ "${1}" = "help" ] || [ -z "${1}" ] || ( [ "${command}" != "train" ] && [ "${command}" != "sync" ] && [ "${command}" != "play" ] && [ "${command}" != "list" ] ); then
  usage
  exit 1
fi
shift

run_name=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --run_name)
      run_name="$2"
      shift # past argument
      shift # past value
      ;;
  esac
done


# Export correct profile
export AWS_PROFILE=ascento-machine-learning

# Remember current directory
current_dir="$PWD"

# Allow all local processes to make connections to the X server
# This fails when running this command without a display(ssh), and that's okay
xhost "+local:*" > /dev/null 2>&1 || true

sso_session_check_and_login() {
  # Check if the sso session is alive, otherwise log in
  local SSO_ACCOUNT=$(aws sts get-caller-identity --query "Account" --profile ascento-machine-learning)
  if ! [ ${#SSO_ACCOUNT} -eq 14 ];  then 
    echo "Please log in to the SSO session"
    aws sso login --profile ascento-machine-learning
  fi
}

if [ "${command}" = "train" ]; then
sso_session_check_and_login
cd /home/aanliker/DeepSeek-VL/sagemaker/ && ./run.sh --run_name=$run_name --task="VLLM"
cd "$current_dir"
  exit 0
fi

