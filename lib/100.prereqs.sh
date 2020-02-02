#!/usr/bin/env bash
set -euo pipefail

readonly script_name="$(basename "${BASH_SOURCE[-1]}")"

# Error logging function
function err() {
  echo >&2 "[$(date +'%Y-%m-%dT%H:%M:%S%z')] ${script_name:?}: $*"
  exit 1
}

### Check for presence of other variables/tools
# Variable - FACTORIO_ROOT
if [ -z "${FACTORIO_ROOT:?}" ]; then
  err "FACTORIO_ROOT is not defined; it should be set to the root path of this project."
fi

# Tool - Google Cloud SDK
if ! hash gcloud 2> /dev/null; then
  err "Google Cloud SDK ('gcloud') required but not found:
- https://cloud.google.com/sdk/install"
fi

if ! hash gsutil 2> /dev/null; then
  err "Google Cloud SDK ('gsutil') required but not found:
- https://cloud.google.com/sdk/install"
fi

# Tool - JQ
if ! hash jq 2> /dev/null; then
  err "'jq' required but not found:
- https://github.com/stedolan/jq/wiki/Installation"
fi
