#!/usr/bin/env bash
set -euo pipefail
shopt -s globstar nullglob
IFS=$'\n\t'

readonly FACTORIO_ROOT="$(git rev-parse --show-toplevel)"

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

select_location=${1:-${FACTORIO_LOCATION:?}}
name="ssh-ubuntu-$select_location"

eval "$(factorio::set_env_location "${FACTORIO_SERVER_LOCATIONS[$select_location]:?}")"

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

echo "Running 'gcloud' with following arguments:"
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
