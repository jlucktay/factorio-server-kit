#!/usr/bin/env bash
set -euo pipefail

FACTORIO_ROOT=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )

for lib in "${FACTORIO_ROOT}"/lib/*.sh; do
    # shellcheck disable=SC1090
    source "$lib"
done

factorio::vm::delete_all

new_instance=$( gcloud compute instances create "factorio-$( gdate '+%Y%m%d-%H%M%S' )" \
    --configuration=factorio \
    --format=json \
    --source-instance-template=factorio-container-11 )

new_instance_name=$( echo "$new_instance" | jq --raw-output '.[].name' )

echo "new instance name: '$new_instance_name'"

gcloud --configuration=factorio compute instances tail-serial-port-output "$new_instance_name" \
| grep startup-script
