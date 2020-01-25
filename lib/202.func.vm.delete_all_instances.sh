#!/usr/bin/env bash
set -euo pipefail

function factorio::vm::delete_all_instances() {
  local delete_instances i
  local gcloud_list_args=(
    "--format=json"
    compute
    instances
    list
  )

  if test -n "${1:-}"; then
    gcloud_list_args+=("--filter=name:$1")
  fi

  delete_instances=$(gcloud "${gcloud_list_args[@]}")

  for ((i = 0; i < $(jq length <<< "$delete_instances"); i += 1)); do
    local name zone
    name=$(jq --raw-output ".[$i].name" <<< "$delete_instances")
    zone=$(basename "$(jq --raw-output ".[$i].zone" <<< "$delete_instances")")

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
