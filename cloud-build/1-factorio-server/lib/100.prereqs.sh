#!/usr/bin/env bash
set -euo pipefail

script_name="$(basename "${BASH_SOURCE[-1]}")"
readonly script_name

# Error logging function
function err() {
  local err_date
  err_date=$(date +'%Y-%m-%dT%H:%M:%S%z')
  echo >&2 "[$err_date] ${script_name:?}: $*"
  exit 1
}

# Check for availability of some necessary tools
for tool in curl cut jq sed; do
  tool_command=$(command -v "$tool" || true)

  if [[ -n $tool_command ]] && [[ -x $tool_command ]]; then
    echo "OK to execute '$tool_command'."
  else
    err "Can't execute '$tool'!"
  fi
done

# Set project ID from metadata
PROJECT_ID=$(
  curl \
    --header "Metadata-Flavor: Google" \
    --silent \
    metadata.google.internal/computeMetadata/v1/project/project-id
)

declare -rx PROJECT_ID
