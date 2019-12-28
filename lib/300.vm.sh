#!/usr/bin/env bash
set -euo pipefail

function factorio::vm::delete_all() {
  local old_instances i
  old_instances=$(
    gcloud \
      --format=json \
      compute \
      instances \
      list
  )

  for ((i = 0; i < $(jq length <<< "$old_instances"); i += 1)); do
    local name zone
    name=$(jq --raw-output ".[$i].name" <<< "$old_instances")
    zone=$(basename "$(jq --raw-output ".[$i].zone" <<< "$old_instances")")

    gcloud \
      --format=json \
      compute \
      instances \
      delete \
      --quiet \
      --zone="$zone" \
      "$name"
  done
}
