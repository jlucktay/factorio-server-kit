#!/usr/bin/env bash
set -euo pipefail
shopt -s globstar nullglob
IFS=$'\n\t'

readonly FACTORIO_ROOT="$(git rev-parse --show-toplevel)"

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

gcloud_deploy_args=(
  functions
  deploy
  cleanup-instances
  --entry-point "Instances"
  --max-instances 1
  --runtime go113
  --trigger-topic "cleanup-instances"
)

echo "Running 'gcloud' with following arguments:"
echo "${gcloud_deploy_args[@]}"

gcloud "${gcloud_deploy_args[@]}"
