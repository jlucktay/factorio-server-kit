#!/usr/bin/env bash
set -euo pipefail

tmp_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# With thanks to:
# https://stackoverflow.com/questions/26717277/converting-a-json-object-into-a-bash-associative-array
declare -A FACTORIO_SERVER_LOCATIONS
while IFS="=" read -r key value; do
  FACTORIO_SERVER_LOCATIONS[$key]="$value"
done < <(jq --raw-output 'to_entries[] | .key + "=" + .value' "$tmp_script_dir/locations.json")

unset tmp_script_dir

# Associative array with valid locations/zones
export FACTORIO_SERVER_LOCATIONS
