#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
TF_FOLDER="${SCRIPT_DIR}/../../terraform/"
CONTAINER_NAME="$(date +%s)_workspaces_terraforming"
DEFAULT_TF_VERSION="1.1.4"

function setup_colors {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' BLUE='\033[0;34m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' BLUE='' YELLOW=''
  fi
}

setup_colors

function cleanup {
  trap - SIGINT SIGTERM ERR EXIT
  printf "%s\n${BLUE}[INFO] Start cleanup.${NOFORMAT}\n"

  USER_ID="$(id -u)"
  GROUP_ID="$(id -g)"

  docker run \
  --rm \
  --env USER_ID="${USER_ID}" \
  --env GROUP_ID="${GROUP_ID}" \
  --volume "${SCRIPT_DIR}/../../terraform:/infrastructure" \
  --workdir /infrastructure \
  busybox \
  chown -R "${USER_ID}":"${GROUP_ID}" . > /dev/null 2>&1 || true
  printf "%s${BLUE}[INFO] Cleanup finished.${NOFORMAT}\n\n"
}

function generate_readme {
  printf "%s\n${YELLOW}[INFO] Generate README.md for ${PWD}${NOFORMAT}\n"

  if ls "${dir}"/README.md &>/dev/null; then
    if grep -q '<!-- TFDOC_START -->' "${dir}"/README.md; then
      :
    else
      printf "\n\n" >> "${dir}"/README.md
      echo '<!-- TFDOC_START -->' >> "${dir}"/README.md
      echo '<!-- TFDOC_END -->' >> "${dir}"/README.md
    fi

  else
    printf "\n\n" >> "${dir}"/README.md
    echo '<!-- TFDOC_START -->' >> "${dir}"/README.md
    echo '<!-- TFDOC_END -->' >> "${dir}"/README.md
  fi

  docker run --rm \
    -v "${PWD}":/data \
    -e DELIM_START='<!-- TFDOC_START -->' \
    -e DELIM_CLOSE='<!-- TFDOC_END -->' \
    cytopia/terraform-docs \
    terraform-docs-replace-012 --sort-by required md README.md &>/dev/null
}

function terraform_fmt {
  printf "%s\n${GREEN}[INFO] Start terraform fmt container for ${PWD}${NOFORMAT}"
  docker run \
  --rm \
  --name "${CONTAINER_NAME}_fmt" \
  --volume "${PWD}:/infrastructure" \
  --workdir /infrastructure \
  hashicorp/terraform:"${TERRAFORM_VERSION}" \
  fmt . &>/dev/null 
}

function recursive_format {
  for dir in "${1}"/*
  do
    if [[ -d "${dir}" ]]; then 
      cd "${dir}"
      
      if ls "${dir}"/*.tf &>/dev/null; then
        if [[ ! -f "${dir}"/.terraform_version ]]; then
          echo "${DEFAULT_TF_VERSION}" > "${dir}"/.terraform_version
        fi

        TERRAFORM_VERSION=$(cat "${dir}"/.terraform_version)
        terraform_fmt
        generate_readme
      fi
      recursive_format "${dir}"
    fi
  done 
}

# Entrypoint

recursive_format ${TF_FOLDER}
