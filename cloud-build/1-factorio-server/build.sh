#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob globstar
IFS=$'\n\t'

script_dir="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && pwd)"
image_name="packtorio-$(date +%Y%m%d-%H%M%S)"

# With thanks to:
# https://stackoverflow.com/questions/1527049/how-can-i-join-elements-of-an-array-in-bash
function join_by() {
  local d=$1
  shift
  echo -n "$1"
  shift
  printf "%s" "${@/#/$d}"
}

substitutions=(
  "_IMAGE_FAMILY=packtorio"
  "_IMAGE_NAME=$image_name"
  "_IMAGE_ZONE=australia-southeast1-b"
)

gcloud --project=jlucktay-factorio \
  builds \
  submit \
  --config="$script_dir/cloudbuild.yaml" \
  --substitutions="$(join_by , "${substitutions[@]}")" \
  "$script_dir"
