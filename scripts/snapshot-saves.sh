#!/usr/bin/env bash
set -euo pipefail
shopt -s globstar nullglob
IFS=$'\n\t'

script_dir="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && pwd)"
FACTORIO_ROOT=$(realpath --canonicalize-existing "$script_dir/..")

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

# Iterate through all location-specific '-saves' buckets defined in our lib JSON and backup into an Archive-class
# bucket with location/timestamp sub-directories

# shellcheck disable=SC2154
for location in "${!FACTORIO_SERVER_LOCATIONS[@]}"; do
  stat=$(gsutil stat "gs://jlucktay-factorio-saves-$location/_autosave*.zip" 2> /dev/null || true)

  if [ ${#stat} -eq 0 ]; then
    continue
  fi

  mtimes=$(grep goog-reserved-file-mtime <<< "$stat" | cut -d":" -f2)
  mtime_high_score=0

  for mtime in $mtimes; do
    if ((mtime > mtime_high_score)); then
      mtime_high_score=$mtime
    fi
  done

  gsutil -m \
    rsync -P -x ".*\.tmp\.zip" \
    "gs://jlucktay-factorio-saves-$location" \
    "gs://jlucktay-factorio-backup-saves/$location-$(TZ=UTC date -r "$mtime_high_score" "+%Y%m%d.%H%M%S%z")"
done
