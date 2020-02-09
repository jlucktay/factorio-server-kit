#!/usr/bin/env bash
set -euo pipefail

function factorio::vm::delete_instances() {
  local delete_instances i
  local gcloud_list_args=(
    "--format=json"
    compute
    instances
    list
  )

  if [ -n "${1:-}" ]; then
    gcloud_list_args+=("--filter=name:$1")
  fi

  echo -n "Listing instances with arguments: "
  echo "${gcloud_list_args[@]}"
  delete_instances=$(gcloud "${gcloud_list_args[@]}")
  for_loop_limit=$(jq length <<< "$delete_instances")

  for ((i = 0; i < for_loop_limit; i += 1)); do
    local name zone
    name=$(jq --raw-output ".[$i].name" <<< "$delete_instances")
    zone=$(basename "$(jq --raw-output ".[$i].zone" <<< "$delete_instances")")

    local gcloud_delete_args=(
      "--format=json"
      compute
      instances
      delete
      --quiet
      "--zone=$zone"
      "$name"
    )

    echo -n "Deleting instance with arguments: "
    echo "${gcloud_delete_args[@]}"
    gcloud "${gcloud_delete_args[@]}"
  done
}
