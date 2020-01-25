#!/usr/bin/env bash
set -euo pipefail
shopt -s globstar nullglob
IFS=$'\n\t'

### Test the newly baked image

instance_name="packer-${PACKER_BUILD_NAME:-}-test-${PACKER_RUN_UUID:-}"

# Create instance from image
gcloud_args=(
  "--format=json"
  compute
  instances
  create
  "--image=$IMAGE_NAME"
  "--tags=factorio,grafana,ssh-from-world"
  "--zone=$IMAGE_ZONE"
  "$instance_name"
)

echo "Running 'gcloud' with following arguments:"
echo "${gcloud_args[@]}"

new_instance=$(gcloud "${gcloud_args[@]}")
new_instance_ip=$(jq --raw-output '.[0].networkInterfaces[0].accessConfigs[0].natIP' <<< "$new_instance")

# Poll port 22 and wait for it to open up
until nmap -Pn -p22 "$new_instance_ip" | grep "^22/tcp" | grep -c open &> /dev/null; do
  sleep 1s
done

# Sleep a little longer
sleep 30s

# Test if the Factorio container is running
gcloud_args=(
  compute
  ssh
  '--command="docker top factorio"'
  "--zone=$IMAGE_ZONE"
  "$instance_name"
)

echo "Running 'gcloud' with following arguments:"
echo "${gcloud_args[@]}"

gcloud "${gcloud_args[@]}"

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
