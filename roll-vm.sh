#!/usr/bin/env bash
set -euo pipefail

FACTORIO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

for lib in "${FACTORIO_ROOT}"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

factorio::vm::delete_all

new_instance=$(gcloud compute instances create "factorio-$(gdate '+%Y%m%d-%H%M%S')" \
  --configuration=factorio \
  --format=json \
  --source-instance-template=factorio-container-22)

new_instance_id=$(echo "$new_instance" | jq --raw-output '.[].id')

logs_link="https://console.cloud.google.com/logs/viewer?project=jlucktay-factorio&resource=gce_instance/instance_id/${new_instance_id}&interval=NO_LIMIT"

echo "Opening the log viewer link: '$logs_link'"

open "$logs_link"
