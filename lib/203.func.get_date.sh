#!/usr/bin/env bash
set -euo pipefail

# Necessary wrapper for 'date' calls other than (for example) 'date "+%Y%m%d.%H%M%S%z"'
function factorio::run_date() {
  if hash gdate; then
    gdate "$@"
  else
    date "$@"
  fi
}
