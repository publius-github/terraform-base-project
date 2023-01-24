#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

MODULE="${1}"
ENVIRONMENT="${2}"
ACTION="${3}"

if [[ "${MODULE}" == "accounts" || "${MODULE}" == "infrastructure" || "${MODULE}" == "general" ]]; then
  TF_PATH="terraform/${MODULE}"
else
  TF_PATH="terraform/${MODULE}/${ENVIRONMENT}"
fi

CONTAINER_NAME="$(date +%s)_workspaces_terraforming"
TERRAFORM_VERSION=$(cat "${SCRIPT_DIR}"/../../"${TF_PATH}"/.terraform_version)
ROOT_FOLDER="${SCRIPT_DIR}/../../"
TF_FOLDER="${SCRIPT_DIR}/../../terraform/"

function setup_colors {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' BLUE='\033[0;34m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' BLUE='' YELLOW=''
  fi
}

setup_colors

function usage {
  printf "%s\n${YELLOW}------------------------------------------------------------${NOFORMAT}"
  printf "%s\n${YELLOW}terraform.sh script allows you to manage terraform in docker${NOFORMAT}\n\n"
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [global options] <subcommand> [args]
Script description here.
Examples:
$(basename "${BASH_SOURCE[0]}") MODULE ENVIRONMENT ACTION"
$(basename "${BASH_SOURCE[0]}") envs nonprod plan/apply/destroy
EOF
  printf "%s${YELLOW}------------------------------------------------------------${NOFORMAT}\n"
  exit
}

function cleanup {
  trap - SIGINT SIGTERM ERR EXIT
  printf "%s\n${BLUE}[INFO] Starting terraform cleanup.${NOFORMAT}\n"

  USER_ID="$(id -u)"
  GROUP_ID="$(id -g)"

  docker run \
  --rm \
  --env USER_ID="${USER_ID}" \
  --env GROUP_ID="${GROUP_ID}" \
  --volume "${ROOT_FOLDER}:/infrastructure" \
  --workdir /infrastructure \
  busybox \
  chown -R "${USER_ID}":"${GROUP_ID}" plan.out .terraform > /dev/null 2>&1 || true
  printf "%s${BLUE}[INFO] Finished terraform cleanup.${NOFORMAT}\n\n"
}

function terraform_init {
  printf "%s\n${GREEN}==> Starting terraform init container...${NOFORMAT}\n"
  docker run \
  --rm \
  --name "${CONTAINER_NAME}_init" \
  --volume "${HOME}/.aws:/root/.aws" \
  --volume "${ROOT_FOLDER}:/infrastructure" \
  --env "${MODULE}" \
  --env "${ENVIRONMENT}" \
  --workdir /infrastructure/"${TF_PATH}" \
  --entrypoint="/bin/sh" \
  hashicorp/terraform:"${TERRAFORM_VERSION}" \
  -c "git config --global --add safe.directory '*' && terraform init -input=false"
}

function terraform_workspaces {
  docker run \
  --rm \
  --name "${CONTAINER_NAME}_plan" \
  --env USER_ID="$(id -u)" \
  --env GROUP_ID="$(id -g)" \
  --volume "${HOME}/.aws:/root/.aws" \
  --volume "${HOME}/.ssh:/root/.ssh" \
  --volume "${ROOT_FOLDER}:/infrastructure" \
  --workdir /infrastructure/"${TF_PATH}" \
  --entrypoint="/bin/sh" \
  hashicorp/terraform:"${TERRAFORM_VERSION}" \
  -c "terraform workspace select ${ENVIRONMENT} || terraform workspace new ${ENVIRONMENT}"
}

function terraform_plan {
  terraform_init
  terraform_workspaces

  printf "%s\n${GREEN}==> Starting terraform plan container...${NOFORMAT}\n"
  docker run \
  --rm \
  --name "${CONTAINER_NAME}_plan" \
  --env USER_ID="$(id -u)" \
  --env GROUP_ID="$(id -g)" \
  --volume "${HOME}/.aws:/root/.aws" \
  --volume "${HOME}/.ssh:/root/.ssh" \
  --volume "${ROOT_FOLDER}:/infrastructure" \
  --workdir /infrastructure/"${TF_PATH}" \
  hashicorp/terraform:"${TERRAFORM_VERSION}" \
  plan -out=plan.out -input=false

  exit $?
}

function terraform_apply {
  terraform_init

  printf "%s\n${GREEN}==> Starting terraform apply container...${NOFORMAT}\n"
  docker run \
  --rm \
  --name "${CONTAINER_NAME}_apply" \
  --volume "${HOME}/.aws:/root/.aws" \
  --volume "${ROOT_FOLDER}:/infrastructure" \
  --workdir /infrastructure/"${TF_PATH}" \
  --entrypoint="/bin/sh" \
  hashicorp/terraform:"${TERRAFORM_VERSION}" \
  -c "terraform apply plan.out"

  exit $?
}

function terraform_destroy {
  terraform_init

  printf "%s\n${GREEN}==> Starting terraform destroy container...${NOFORMAT}\n"
  docker run \
  --rm \
  --name "${CONTAINER_NAME}_destroy" \
  --volume "${HOME}/.aws:/root/.aws" \
  --volume "${ROOT_FOLDER}:/infrastructure" \
  --workdir /infrastructure/"${TF_PATH}" \
  --entrypoint="/bin/sh" \
  hashicorp/terraform:"${TERRAFORM_VERSION}" \
  -c "terraform destroy --auto-approve"

  exit $?
}

case ${ACTION} in
  plan)
    terraform_plan
    ;;

  apply)
    terraform_apply
    ;;

  destroy)
    terraform_destroy
    ;;

  *)
    usage "$@"
    printf "%s\n${RED}\"${ACTION}\" is not a valid action."
    exit 1
    ;;
esac
