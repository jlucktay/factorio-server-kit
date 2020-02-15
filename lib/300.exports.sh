#!/usr/bin/env bash
set -euo pipefail

#shellcheck disable=SC2016
function factorio::env::set_location() {
  echo 'export CLOUDSDK_COMPUTE_ZONE="'"${1:?}"'"'
  echo 'export CLOUDSDK_COMPUTE_REGION="${CLOUDSDK_COMPUTE_ZONE:0:-2}"'
  echo 'export CLOUDSDK_FUNCTIONS_REGION="$CLOUDSDK_COMPUTE_REGION"'
}

tmp_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
tmp_locations_json="$tmp_script_dir/locations.json"

declare -A FACTORIO_SERVER_LOCATIONS

for_loop_limit=$(jq length "$tmp_locations_json")

for ((i = 0; i < for_loop_limit; i += 1)); do
  tmp_location_zone=$(jq --raw-output ".[$i] | .location + \"=\" + .zone" "$tmp_locations_json")

  IFS="=" read -r tmp_location tmp_zone <<< "$tmp_location_zone"

  FACTORIO_SERVER_LOCATIONS["$tmp_location"]="$tmp_zone"

  unset tmp_location_zone tmp_location tmp_zone

  if [ "$(jq --raw-output ".[$i].default" "$tmp_locations_json")" == "true" ]; then
    default_location=$(jq --raw-output ".[$i].location" "$tmp_locations_json")
    default_zone=$(jq --raw-output ".[$i].zone" "$tmp_locations_json")
  fi
done

unset tmp_locations_json tmp_script_dir

# Associative array with valid locations/zones
export FACTORIO_SERVER_LOCATIONS

declare -rx FACTORIO_DNS_NAME=factorio.menagerie.games
declare -rx FACTORIO_IMAGE_FAMILY=packtorio
declare -rx FACTORIO_LOCATION="${default_location:?}" # locations.json should have "default: true" on one location
unset default_location

# Define this once per script invocation, so that it can be used consistently across builds, deployments, etc
readonly FACTORIO_IMAGE_NAME="$FACTORIO_IMAGE_FAMILY-$(TZ=UTC date +%Y%m%d-%H%M%S)"
export FACTORIO_IMAGE_NAME

eval "$(factorio::env::set_location "${default_zone:?}")" # locations.json should have "default: true" on one location
unset default_zone

# Ref: https://www.packer.io/downloads.html
# Look for the 'packer_<version>_linux_amd64.zip' checksum, which is what our Docker image uses
declare -rx FACTORIO_PACKER_VERSION=1.5.4
declare -rx FACTORIO_PACKER_VERSION_SHA256SUM=c7277f64d217c7d9ccfd936373fe352ea935454837363293f8668f9e42d8d99d
