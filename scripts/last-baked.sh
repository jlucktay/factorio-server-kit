#!/usr/bin/env bash
set -euo pipefail
shopt -s globstar nullglob
IFS=$'\n\t'

readonly FACTORIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && git rev-parse --show-toplevel)"

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

image_baked_timestamp=$(
  gcloud compute images list \
    --filter="family:${FACTORIO_IMAGE_FAMILY:?}" \
    --format=json \
    | jq --raw-output '.[].creationTimestamp'
)

factorio::util::run_date --date="$image_baked_timestamp"
