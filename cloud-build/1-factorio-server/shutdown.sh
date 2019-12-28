#!/usr/bin/env bash
set -euxo pipefail
IFS=$'\n\t'

logger "=== Called 'shutdown-script'!"

logger "=== Waiting for Factorio container to stop..."
while docker top factorio &> /dev/null; do
  sleep 1s
done

logger "=== Pushing Factorio saves to Storage..."
gsutil -m rsync -P -x ".*\.tmp\.zip" /opt/factorio/saves gs://jlucktay-factorio-asia/saves |& logger

logger "=== Done!"
