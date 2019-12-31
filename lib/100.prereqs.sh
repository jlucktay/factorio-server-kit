#!/usr/bin/env bash
set -euo pipefail

readonly script_name=$(basename "${BASH_SOURCE[-1]}")

### Check for presence of other variables/tools
# Variable - FACTORIO_ROOT
test -n "${FACTORIO_ROOT:-}" || {
  echo >&2 "$script_name: FACTORIO_ROOT is not defined; it should be set to the root path of this project."
  exit 1
}

# Tool - Google Cloud SDK
hash gcloud 2> /dev/null || {
  echo >&2 "$script_name requires the Google Cloud SDK ('gcloud') but it's not installed: \
https://cloud.google.com/sdk/install"
  exit 1
}

hash gsutil 2> /dev/null || {
  echo >&2 "$script_name requires the Google Cloud SDK ('gsutil') but it's not installed: \
https://cloud.google.com/sdk/install"
  exit 1
}

# Tool - JQ
hash jq 2> /dev/null || {
  echo >&2 "$script_name requires 'jq' but it's not installed: \
https://github.com/stedolan/jq/wiki/Installation"
  exit 1
}
