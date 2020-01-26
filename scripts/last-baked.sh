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

image_baked_timestamp=$(
  gcloud compute images list \
    --filter="family:packtorio" \
    --format=json \
    | jq --raw-output '.[].creationTimestamp'
)

factorio::run_date --date="$image_baked_timestamp"
