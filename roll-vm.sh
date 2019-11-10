#!/usr/bin/env bash
set -euo pipefail

mapfile -t old_instances < <( gcloud compute instances list --format=json | jq --raw-output '.[].name' )

for old_instance in "${old_instances[@]}"; do
    echo "old instance: $old_instance"
    gcloud compute instances delete "$old_instance" --format=json --quiet
done

new_instance=$( gcloud compute instances create "factorio-$( gdate '+%Y%m%d-%H%M%S' )" \
    --format=json \
    --maintenance-policy=TERMINATE \
    --metadata-from-file startup-script=startup.sh,shutdown-script=shutdown.sh \
    --preemptible \
    --source-instance-template=factorio-container-10 \
    --tags=factorio,grafana,ssh )

new_instance_name=$( echo "$new_instance" | jq --raw-output '.[].name' )

echo "new instance name: '$new_instance_name'"

gcloud compute instances tail-serial-port-output "$new_instance_name" | grep startup-script
