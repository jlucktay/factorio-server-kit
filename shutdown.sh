#!/usr/bin/env bash
set -euxo pipefail
IFS=$'\n\t'

logger "=== Shutting down!"

logger "=== Pushing Factorio saves to Storage..."
gsutil -m rsync -P /opt/factorio/saves gs://jlucktay-factorio-asia/saves

logger "=== Done!"
