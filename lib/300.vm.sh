#!/usr/bin/env bash
set -euo pipefail

function factorio::vm::delete_all() {
    mapfile -t old_instances < <( gcloud compute instances list \
        --configuration=factorio \
        --format=json \
        | jq --raw-output '.[].name' )

    for old_instance in "${old_instances[@]}"; do
        echo "${script_name:-}: old instance: $old_instance"
        gcloud compute instances delete "$old_instance" \
            --configuration=factorio \
            --format=json
    done
}
