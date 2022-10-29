#!/usr/bin/env bash
set -euo pipefail

FACTORIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && git rev-parse --show-toplevel)"
readonly FACTORIO_ROOT

bucket=${CLOUDSDK_CORE_PROJECT:?}-storage

for d in config lib; do
  (
    set -x

    gsutil -m -o "GSUtil:parallel_process_count=1" \
      rsync -x ".*\.sh$|.*\.gitignore$" "$FACTORIO_ROOT"/"$d"/ gs://"$bucket"/"$d"/
  )

  echo
done
