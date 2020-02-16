#!/usr/bin/env bash
set -euo pipefail

#shellcheck disable=SC2016
function factorio::env::set_location() {
  echo 'export CLOUDSDK_COMPUTE_ZONE="'"${1:?}"'"'
  echo 'export CLOUDSDK_COMPUTE_REGION="${CLOUDSDK_COMPUTE_ZONE:0:-2}"'
  echo 'export CLOUDSDK_FUNCTIONS_REGION="$CLOUDSDK_COMPUTE_REGION"'
}
