#!/usr/bin/env bash
set -euo pipefail

function factorio::password() {
  if [ ! -f "${FACTORIO_ROOT:?}/lib/password.json" ]; then
    err "'$FACTORIO_ROOT/lib/password.json' required but not found."
    exit 1
  fi

  readonly FACTORIO_PASSWORD=$(jq --raw-output '.password' "$FACTORIO_ROOT/lib/password.json")

  test "$FACTORIO_PASSWORD" != "null" || {
    err "'$FACTORIO_ROOT/lib/password.json' did not contain a value under the 'password' key."
    exit 1
  }
}
