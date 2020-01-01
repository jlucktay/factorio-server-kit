#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob globstar
IFS=$'\n\t'

script_dir="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && pwd)"
FACTORIO_ROOT=$script_dir/..

for lib in "${FACTORIO_ROOT}"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

mkdir -pv "${FACTORIO_ROOT}/gs/jlucktay-factorio-asia/"

gsutil -m rsync -r -u \
  -x "saves.*" \
  gs://jlucktay-factorio-asia/ \
  "${FACTORIO_ROOT}/gs/jlucktay-factorio-asia/"
