#!/usr/bin/env bash
set -euo pipefail
shopt -s globstar nullglob
IFS=$'\n\t'

# test the newly baked image
## create vm from image
## run a 180s loop to nmap ports 22, 3000 (TCP) and 34197 (UDP)
### sudo nmap -sS -sU -p T:22,3000,U:34197 factorio.menagerie.games 35.197.184.219
## delete vm

instance_name="packer-${PACKER_BUILD_NAME:-}-test-${PACKER_RUN_UUID:-}"

# Create instance from image
gcloud_args=(
  "--format=json"
  compute
  instances
  create
  "--image=$IMAGE_NAME"
  "--machine-type=n1-standard-2"
  "--tags=factorio,grafana,ssh-from-world"
  "--zone=$IMAGE_ZONE"
  "$instance_name"
)

echo "Running 'gcloud' with following arguments:"
echo "${gcloud_args[@]}"

new_instance=$(gcloud "${gcloud_args[@]}")
new_instance_ip=$(jq --raw-output '.[0].networkInterfaces[0].accessConfigs[0].natIP' <<< "$new_instance")

echo "IP: '$new_instance_ip'"

# Delete instance
gcloud_args=(
  "--format=json"
  compute
  instances
  delete
  "--quiet"
  "--zone=$IMAGE_ZONE"
  "$instance_name"
)

echo "Running 'gcloud' with following arguments:"
echo "${gcloud_args[@]}"

gcloud "${gcloud_args[@]}"
