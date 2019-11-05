#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

docker stop factorio

gsutil -m rsync -P /opt/factorio/saves gs://jlucktay-factorio-asia/saves
