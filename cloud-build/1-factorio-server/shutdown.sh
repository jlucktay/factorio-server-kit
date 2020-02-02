#!/usr/bin/env bash
set -euxo pipefail
shopt -s globstar nullglob
IFS=$'\n\t'

logger "=== Called 'shutdown-script'!"
locations=$(gsutil cat gs://jlucktay-factorio-storage/lib/locations.json)

logger "=== Waiting for Factorio container to stop..."
while docker top factorio &> /dev/null; do
  sleep 1s
done

logger "=== Get instance's zone from metadata, to back up saves to the local bucket"
instance_zone=$(
  curl \
    --header "Metadata-Flavor: Google" \
    --silent \
    metadata.google.internal/computeMetadata/v1/instance/zone
)

push_saves_to=$(
  jq --raw-output \
    '.[] | select(.zone == "'"$(basename "$instance_zone")"'") | .location' \
    <<< "$locations"
)

logger "=== Pushing Factorio saves to Storage..."
gsutil -m rsync -P -x ".*\.tmp\.zip" /opt/factorio/saves "gs://jlucktay-factorio-saves-$push_saves_to" |& logger

logger "=== Done!"
