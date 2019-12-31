#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob globstar

gsutil -m \
  rsync -P -x ".*\.tmp\.zip" \
  gs://jlucktay-factorio-asia/saves \
  "gs://jlucktay-factorio-asia/saves-$(TZ=UTC gdate +%Y%m%d)"
