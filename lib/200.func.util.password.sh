#!/usr/bin/env bash
set -euo pipefail

function factorio::util::password() {
  local secrets_json="${FACTORIO_ROOT:?}/lib/secrets.json"

  if [ ! -f "$secrets_json" ]; then
    err "'$secrets_json' required but not found."
  fi

  local password

  if ! password="$(jq --exit-status --raw-output '.password' "$secrets_json")"; then
    err "'$secrets_json' did not contain a value under the 'password' key."
  fi

  echo "$password"
}
