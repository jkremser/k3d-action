#!/bin/bash
# Copyright 2021 Absa Group Limited
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Generated by GoLic, for more details see: https://github.com/AbsaOSS/golic

set -o errexit
set -o pipefail
#set -o nounset     ;handling unset environment variables manually
#set -x             ;debugging

YELLOW=
CYAN=
RED=
NC=
K3D_URL=https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh
DEFAULT_K3D_VERSION=v5.3.0

#######################
#
#     FUNCTIONS
#
#######################
usage(){
  cat <<EOF

  Usage: $(basename "$0") <COMMAND>
  Commands:
      deploy            deploy custom k3d cluster

  Environment variables:
      deploy
                        CLUSTER_NAME (Required) k3d cluster name.

                        ARGS (Optional) k3d arguments.

                        K3D_VERSION (Optional) k3d version.
EOF
}

panic() {
  (>&2 echo -e " - ${RED}$*${NC}")
  usage
  exit 1
}

deploy(){
    local name=${CLUSTER_NAME}
    local arguments=${ARGS:-}
    local k3dVersion=${K3D_VERSION:-${DEFAULT_K3D_VERSION}}

    if [[ -z "${CLUSTER_NAME}" ]]; then
      panic "CLUSTER_NAME must be set"
    fi

    echo -e "${YELLOW}Downloading ${CYAN}k3d@${k3dVersion} ${NC}see: ${K3D_URL}"
    curl --silent --fail ${K3D_URL} | TAG=${k3dVersion} bash

    echo -e "\existing_network${YELLOW}Deploy cluster ${CYAN}$name ${NC}"
    eval "k3d cluster create $name --wait $arguments"
    wait_for_nodes
}

# waits until all nodes are ready
wait_for_nodes(){
  echo -e "${YELLOW}wait until all agents are ready${NC}"
  while :
  do
    readyNodes=1
    statusList=$(kubectl get nodes --no-headers | awk '{ print $2}')
    # shellcheck disable=SC2162
    while read status
    do
      if [ "$status" == "NotReady" ] || [ "$status" == "" ]
      then
        readyNodes=0
        break
      fi
    done <<< "$(echo -e  "$statusList")"
    # all nodes are ready; exit
    if [[ $readyNodes == 1 ]]
    then
      break
    fi
    sleep 1
  done
}
#######################
#
#     GUARDS SECTION
#
#######################
if [[ "$#" -lt 1 ]]; then
  usage
  exit 1
fi
if [[ -z "${NO_COLOR}" ]]; then
      YELLOW="\033[0;33m"
      CYAN="\033[1;36m"
      NC="\033[0m"
      RED="\033[0;91m"
fi

#######################
#
#     COMMANDS
#
#######################
case "$1" in
    "deploy")
       deploy
    ;;
#    "<put new command here>")
#       command_handler
#    ;;
      *)
  usage
  exit 0
  ;;
esac
