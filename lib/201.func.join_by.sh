#!/usr/bin/env bash
set -euo pipefail

# With thanks to:
# https://stackoverflow.com/questions/1527049/how-can-i-join-elements-of-an-array-in-bash
function factorio::util::join_by() {
  local d="$1"
  shift
  echo -n "$1"
  shift
  printf "%s" "${@/#/$d}"
}
