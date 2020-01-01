#!/usr/bin/env bash
set -euo pipefail

tmp_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
tmp_locations_json="$tmp_script_dir/locations.json"

declare -A FACTORIO_SERVER_LOCATIONS

for ((i = 0; i < $(jq length "$tmp_locations_json"); i += 1)); do
  IFS="=" read -r tmp_location tmp_zone \
    <<< "$(jq --raw-output '.['"$i"'] | .location +"="+ .zone' "$tmp_locations_json")"

  FACTORIO_SERVER_LOCATIONS[$tmp_location]="$tmp_zone"

  unset tmp_location tmp_zone
done

unset tmp_script_dir tmp_locations_json

# Associative array with valid locations/zones
export FACTORIO_SERVER_LOCATIONS
