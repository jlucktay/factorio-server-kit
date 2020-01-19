#!/usr/bin/env bash
set -euo pipefail

readonly script_name=$(basename "${BASH_SOURCE[-1]}")

# Error logging function
function err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] ${script_name:-}: $*" >&2
}

### Check for presence of other variables/tools
# Variable - FACTORIO_ROOT
test -n "${FACTORIO_ROOT:-}" || {
  err "FACTORIO_ROOT is not defined; it should be set to the root path of this project."
  exit 1
}

# Tool - Google Cloud SDK
hash gcloud 2> /dev/null || {
  err "Google Cloud SDK ('gcloud') required but not found:
- https://cloud.google.com/sdk/install"
  exit 1
}

hash gsutil 2> /dev/null || {
  err "Google Cloud SDK ('gsutil') required but not found:
- https://cloud.google.com/sdk/install"
  exit 1
}

# Tool - JQ
hash jq 2> /dev/null || {
  err "'jq' required but not found:
- https://github.com/stedolan/jq/wiki/Installation"
  exit 1
}

# Tool - realpath from GNU coreutils
hash realpath 2> /dev/null || {
  err "'realpath' from GNU coreutils required but not found:
- https://formulae.brew.sh/formula/coreutils
- https://www.gnu.org/software/coreutils/"
  exit 1
}
