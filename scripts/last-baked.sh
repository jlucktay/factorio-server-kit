#!/usr/bin/env bash
set -euo pipefail

image_baked_timestamp=$(
  gcloud compute images list \
    --filter="family:packtorio" \
    --format=json \
    | jq --raw-output '.[].creationTimestamp'
)

gdate --date="$image_baked_timestamp"
