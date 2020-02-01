#!/usr/bin/env bash
set -euo pipefail

function factorio::password() {
  if [ ! -f "${FACTORIO_ROOT:?}/lib/password.json" ]; then
    err "'$FACTORIO_ROOT/lib/password.json' required but not found."
    exit 1
  fi

  local tmp_password

  if ! tmp_password="$(jq --exit-status --raw-output '.password' "$FACTORIO_ROOT/lib/password.json")"; then
    err "'$FACTORIO_ROOT/lib/password.json' did not contain a value under the 'password' key."
  fi

  echo "$tmp_password"
}
