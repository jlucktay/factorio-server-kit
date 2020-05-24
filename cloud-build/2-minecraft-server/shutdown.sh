#!/usr/bin/env bash
set -euxo pipefail
IFS=$'\n\t'

logger "=== Called 'shutdown-script'!"

logger "=== Waiting for Minecraft container to stop..."
while docker top minecraft &> /dev/null; do
  sleep 1s
done

logger "=== Get project ID from metadata, and location details from Storage"
project_id=$(curl --header "Metadata-Flavor: Google" --silent \
  metadata.google.internal/computeMetadata/v1/project/project-id)
locations=$(gsutil cat "gs://$project_id-storage/lib/locations.json")

logger "=== Get instance's zone from metadata, to back up saves to the local bucket"
instance_zone=$(curl --header "Metadata-Flavor: Google" --silent \
  metadata.google.internal/computeMetadata/v1/instance/zone)

push_saves_to=$(
  jq --raw-output \
    '.[] | select(.zone == "'"$(basename "$instance_zone")"'") | .location' \
    <<< "$locations"
)

logger "=== Pushing Minecraft saves to Storage..."
gsutil -m rsync -P /opt/minecraft/worlds "gs://$project_id-saves-$push_saves_to" |& logger

logger "=== Done!"
