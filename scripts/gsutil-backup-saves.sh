#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob globstar

# TODO: distribute latest saves across all buckets?

gsutil -m \
  rsync -P -x ".*\.tmp\.zip" \
  gs://jlucktay-factorio-asia/saves \
  "gs://jlucktay-factorio-asia/saves-$(TZ=UTC gdate +%Y%m%d)"
