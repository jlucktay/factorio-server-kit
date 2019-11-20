#!/usr/bin/env bash
set -euxo pipefail
IFS=$'\n\t'

logger "=== Pre-empted!"

logger "=== Stopping Docker..."
docker stop factorio

logger "=== Pushing Factorio saves to Storage..."
gsutil -m rsync -P /opt/factorio/saves gs://jlucktay-factorio-asia/saves

logger "=== Done!"
