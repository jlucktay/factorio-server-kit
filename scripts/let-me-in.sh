#!/usr/bin/env bash
set -euo pipefail
shopt -s globstar nullglob
IFS=$'\n\t'

readonly FACTORIO_ROOT="$(git rev-parse --show-toplevel)"

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

curl_output=$(curl --silent http://httpbin.org/ip | jq --raw-output '.origin')
[[ $curl_output =~ ([0-9]{1,3}\.){3}[0-9]{1,3} ]]
my_ip=${BASH_REMATCH[0]}

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
fi

name=$(jq --raw-output ".[0].name" <<< "$instance")
zone=$(basename "$(jq --raw-output ".[0].zone" <<< "$instance")")

gcloud \
  compute \
  ssh \
  --zone="$zone" \
  "$name"
