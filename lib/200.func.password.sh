#!/usr/bin/env bash
set -euo pipefail

function factorio::password() {
  test -f "${FACTORIO_ROOT:-}/lib/password.json" || {
    err "'$FACTORIO_ROOT/lib/password.json' required but not found."
    exit 1
  }

  readonly FACTORIO_PASSWORD=$(jq --raw-output '.password' "$FACTORIO_ROOT/lib/password.json")

  test "$FACTORIO_PASSWORD" != "null" || {
    err "'$FACTORIO_ROOT/lib/password.json' did not contain a value under the 'password' key."
    exit 1
  }
}
