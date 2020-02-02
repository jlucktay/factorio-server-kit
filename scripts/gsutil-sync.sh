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

mkdir -pv "$FACTORIO_ROOT/gs/jlucktay-factorio-storage/"

gsutil -m rsync -r -u \
  -x "saves.*" \
  gs://jlucktay-factorio-storage/ \
  "$FACTORIO_ROOT/gs/jlucktay-factorio-storage/"
