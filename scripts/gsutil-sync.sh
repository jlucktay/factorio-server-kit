#!/usr/bin/env bash
set -euo pipefail

FACTORIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && git rev-parse --show-toplevel)"
readonly FACTORIO_ROOT

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

mkdir -pv "$FACTORIO_ROOT/gs/${CLOUDSDK_CORE_PROJECT:?}-storage/"

gsutil -m -o "GSUtil:parallel_process_count=1" \
  rsync -r -u -x "saves.*" \
  "gs://$CLOUDSDK_CORE_PROJECT-storage/" \
  "$FACTORIO_ROOT/gs/$CLOUDSDK_CORE_PROJECT-storage/"
