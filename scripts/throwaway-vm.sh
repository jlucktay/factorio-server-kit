#!/usr/bin/env bash
set -euo pipefail

FACTORIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && git rev-parse --show-toplevel)"
readonly FACTORIO_ROOT

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

select_location=${1:-${FACTORIO_LOCATION:?}}
name="throwaway-$select_location"

# Already defined by 'lib' scripts above
if [[ -z ${FACTORIO_SERVER_LOCATIONS[$select_location]+is_set} ]]; then
  err "Location '$select_location' is not valid."
fi

eval_input=$(factorio::env::set_location "${FACTORIO_SERVER_LOCATIONS[$select_location]:?}")
eval "$eval_input"

gcloud_create_args=(
  compute
  instances
  create
  --image-family debian-11
  --image-project debian-cloud
  --machine-type n1-standard-2
  --scopes https://www.googleapis.com/auth/cloud-platform
  --tags ssh
  "$name"
)

echo "Creating instance: gcloud ${gcloud_create_args[*]}"
gcloud "${gcloud_create_args[@]}"

echo "SSHing into '$name':"
gcloud_ssh_args=(
  compute
  ssh
  "$name"
)

until gcloud "${gcloud_ssh_args[@]}"; do
  sleep 1
done

factorio::vm::delete_instances "$name"
