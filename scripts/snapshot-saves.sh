#!/usr/bin/env bash
set -euo pipefail

FACTORIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && git rev-parse --show-toplevel)"
readonly FACTORIO_ROOT

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

# Iterate through all location-specific '-saves' buckets defined in our lib JSON and backup into an Archive-class
# bucket with location/timestamp sub-directories.

# shellcheck disable=SC2154
for location in "${!FACTORIO_SERVER_LOCATIONS[@]}"; do
  stat=$(gsutil -m stat "gs://${CLOUDSDK_CORE_PROJECT:?}-saves-$location/_autosave*.zip" 2> /dev/null || true)

  if [[ ${#stat} -eq 0 ]]; then
    continue
  fi

  grep_output=$(grep goog-reserved-file-mtime <<< "$stat" | cut -d":" -f2)
  mapfile -t mtimes <<< "$grep_output"
  mtime_high_score=0

  for mtime in "${mtimes[@]}"; do
    if ((mtime > mtime_high_score)); then
      mtime_high_score=$mtime
    fi
  done

  snapshot_timestamp=$(TZ=UTC factorio::util::run_date --date="@$mtime_high_score" "+%Y%m%d.%H%M%S%z")

  gsutil -m -o "GSUtil:parallel_process_count=1" \
    rsync -P -x ".*\.tmp\.zip" \
    "gs://$CLOUDSDK_CORE_PROJECT-saves-$location" \
    "gs://$CLOUDSDK_CORE_PROJECT-backup-saves/$location-$snapshot_timestamp"
done
