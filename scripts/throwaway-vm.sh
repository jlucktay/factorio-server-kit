#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

readonly FACTORIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && git rev-parse --show-toplevel)"

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

select_location=${1:-${FACTORIO_LOCATION:?}}
name="ssh-ubuntu-$select_location"

# shellcheck disable=SC2154 # Already defined by 'lib' scripts above
if [ -z "${FACTORIO_SERVER_LOCATIONS[$select_location]+is_set}" ]; then
  err "Location '$select_location' is not valid."
fi

eval "$(factorio::env::set_location "${FACTORIO_SERVER_LOCATIONS[$select_location]:?}")"

gcloud_create_args=(
  compute
  instances
  create
  --image-family ubuntu-1804-lts
  --image-project ubuntu-os-cloud
  --machine-type f1-micro
  --scopes https://www.googleapis.com/auth/cloud-platform
  --tags ssh
  "$name"
)

echo -n "Creating instance: gcloud "
echo "${gcloud_create_args[@]}"
gcloud "${gcloud_create_args[@]}"

echo "SSHing into '$name':"
gcloud_ssh_args=(
  compute
  ssh
  "$name"
)

while ! gcloud "${gcloud_ssh_args[@]}"; do
  sleep 1s
done

factorio::vm::delete_instances "$name"
