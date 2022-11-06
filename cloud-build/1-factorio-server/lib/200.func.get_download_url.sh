#!/usr/bin/env bash
set -euo pipefail

### Helper function to retrieve a download URL for the latest GitHub release
# Usage:   get_download_url <author> <repo> <release pattern>
# Example: get_download_url 99designs aws-vault linux_amd64
function get_download_url() {
  curl --silent "https://api.github.com/repos/$1/$2/releases/latest" 2> /dev/null \
    | jq --arg contains "$3" --exit-status --raw-output \
      '.assets[] | select(.browser_download_url | contains($contains)) | .browser_download_url'
}
