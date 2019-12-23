#!/usr/bin/env bash
set -euo pipefail

FACTORIO_ROOT=$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && pwd)/..

for lib in "${FACTORIO_ROOT}"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

factorio::vm::delete_all
