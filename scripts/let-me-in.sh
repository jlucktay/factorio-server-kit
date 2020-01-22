#!/usr/bin/env bash
set -euo pipefail
shopt -s globstar nullglob
IFS=$'\n\t'

script_dir="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && pwd)"
FACTORIO_ROOT=$(realpath --canonicalize-existing "$script_dir/..")

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

curl_output=$(curl --silent http://httpbin.org/ip | jq --raw-output '.origin')
read -d "," -r my_ip <<< "$curl_output"

### Build arguments list for gcloud
gcloud_args=(
  compute
  firewall-rules
  update
  "--source-ranges=$my_ip/32"
  default-allow-ssh
)

### Show arguments and execute with them
echo "Running 'gcloud' with following arguments:"
echo "${gcloud_args[@]}"

gcloud "${gcloud_args[@]}"

### Get Factorio server instance and SSH into it
instance=$(
  gcloud \
    --format=json \
    compute \
    instances \
    list \
    --filter="name:factorio-*" \
    --limit=1
)

if [ "$(jq length <<< "$instance")" == 0 ]; then
  err "there are currently no instances running"
  exit 0
fi

name=$(jq --raw-output ".[0].name" <<< "$instance")
zone=$(basename "$(jq --raw-output ".[0].zone" <<< "$instance")")

gcloud \
  compute \
  ssh \
  --zone="$zone" \
  "$name"
