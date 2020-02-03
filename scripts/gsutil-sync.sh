#!/usr/bin/env bash
set -euo pipefail
shopt -s globstar nullglob
IFS=$'\n\t'

readonly FACTORIO_ROOT="$(git rev-parse --show-toplevel)"

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

mkdir -pv "$FACTORIO_ROOT/gs/${CLOUDSDK_CORE_PROJECT:?}-storage/"

gsutil -m rsync -r -u \
  -x "saves.*" \
  "gs://$CLOUDSDK_CORE_PROJECT-storage/" \
  "$FACTORIO_ROOT/gs/$CLOUDSDK_CORE_PROJECT-storage/"
