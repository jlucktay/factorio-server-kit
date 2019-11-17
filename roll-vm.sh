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
    --maintenance-policy=TERMINATE \
    --metadata-from-file startup-script=startup.sh,shutdown-script=shutdown.sh \
    --preemptible \
    --source-instance-template=factorio-container-10 \
    --tags=factorio,grafana,ssh )

new_instance_name=$( echo "$new_instance" | jq --raw-output '.[].name' )

echo "new instance name: '$new_instance_name'"

gcloud --configuration=factorio compute instances tail-serial-port-output "$new_instance_name" \
| grep startup-script
