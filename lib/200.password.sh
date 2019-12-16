#!/usr/bin/env bash
set -euo pipefail

function factorio::password() {
  test -f "${FACTORIO_ROOT:-}/lib/password.json" || {
    echo >&2 "${script_name:-} requires '$FACTORIO_ROOT/lib/password.json' but it was not found."
    exit 1
  }

  password=$(jq --raw-output '.password' "$FACTORIO_ROOT/lib/password.json")

  test "$password" != "null" || {
    echo >&2 "'$FACTORIO_ROOT/lib/password.json' did not contain a value under the 'password' key."
    exit 1
  }
}
