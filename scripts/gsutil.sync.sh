#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob globstar

mkdir -pv gs/jlucktay-factorio-asia/

gsutil -m rsync -P -r -u \
  -x "saves/_autosave.\.zip$|saves/_autosave.\.tmp\.zip$|saves-.*/.*\.zip$" \
  gs://jlucktay-factorio-asia/ \
  ./gs/jlucktay-factorio-asia/
