#!/usr/bin/env bash
set -euo pipefail
shopt -s globstar nullglob
IFS=$'\n\t'

script_dir="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && pwd)"
FACTORIO_ROOT=$(realpath --canonicalize-existing "$script_dir/..")

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

select_location=${1:-london}
locations=$(gsutil cat gs://jlucktay-factorio-storage/lib/locations.json)
zone=$(jq --raw-output ".[] | select( .location == \"$select_location\" ) | .zone" <<< "$locations")

gcloud_args=(
  compute
  instances
  create
  --image-family ubuntu-1804-lts
  --image-project ubuntu-os-cloud
  --machine-type f1-micro
  --preemptible
  --tags ssh
  --zone "$zone"
  "ssh-ubuntu-$select_location"
)

echo "Running 'gcloud' with following arguments:"
echo "${gcloud_args[@]}"

gcloud "${gcloud_args[@]}"
