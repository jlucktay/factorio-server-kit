#!/usr/bin/env bash
set -euo pipefail

function factorio::vm::delete_all() {
  local old_instances, i
  old_instances=$(
    gcloud compute instances list \
      --format=json \
      --project=jlucktay-factorio
  )

  for ((i = 0; i < $(echo "$old_instances" | jq length); i += 1)); do
    local name, raw_zone, zone
    name=$(echo "$old_instances" | jq --raw-output ".[$i].name")

    raw_zone=$(echo "$old_instances" | jq --raw-output ".[$i].zone")
    zone=$(basename "$raw_zone")

    gcloud compute instances delete \
      --format=json \
      --project=jlucktay-factorio \
      --zone="$zone" \
      "$name"
  done
}
