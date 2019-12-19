#!/usr/bin/env bash
set -euo pipefail

function factorio::vm::delete_all() {
  local old_instances i
  old_instances=$(
    gcloud compute instances list \
      --format=json \
      --project=jlucktay-factorio
  )

  for ((i = 0; i < $(echo "$old_instances" | jq length); i += 1)); do
    local name zone
    name=$(jq --raw-output ".[$i].name" <<< "$old_instances")
    zone=$(basename "$(jq --raw-output ".[$i].zone" <<< "$old_instances")")

    gcloud compute instances delete \
      --format=json \
      --project=jlucktay-factorio \
      --zone="$zone" \
      "$name"
  done
}
