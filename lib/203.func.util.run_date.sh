#!/usr/bin/env bash
set -euo pipefail

# Necessary wrapper for 'date' calls other than (for example) 'date "+%Y%m%d.%H%M%S%z"'
function factorio::util::run_date() {
  if hash gdate &> /dev/null; then
    gdate "$@"
  else
    date "$@"
  fi
}
