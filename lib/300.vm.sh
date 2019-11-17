#!/usr/bin/env bash
set -euo pipefail

function factorio::vm::delete_all() {
    mapfile -t old_instances < <( gcloud --configuration=factorio --format=json compute instances list \
    | jq --raw-output '.[].name' )

    for old_instance in "${old_instances[@]}"; do
        echo "${script_name:-}: old instance: $old_instance"
        gcloud --configuration=factorio --format=json compute instances delete "$old_instance"
    done
}
