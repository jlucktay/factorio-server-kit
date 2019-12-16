#!/usr/bin/env bash
set -euo pipefail

function factorio::vm::delete_all() {
  old_instances=$(gcloud compute instances list \
    --configuration=factorio \
    --format=json)

  for ((i = 0; i < $(echo "$old_instances" | jq length); i += 1)); do
    name=$(echo "$old_instances" | jq --raw-output ".[$i].name")

    raw_zone=$(echo "$old_instances" | jq --raw-output ".[$i].zone")
    zone=$(basename "$raw_zone")

    gcloud compute instances delete \
      --configuration=factorio \
      --format=json \
      --zone="$zone" \
      "$name"
  done
}
