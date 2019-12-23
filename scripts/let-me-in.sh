#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob globstar
IFS=$'\n\t'

FACTORIO_ROOT=$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && pwd)/..
export FACTORIO_ROOT

for lib in "${FACTORIO_ROOT}"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

script_name=$(basename "${BASH_SOURCE[-1]}")

curl_output=$(curl --silent http://httpbin.org/ip | jq --raw-output '.origin')
read -d "," -r my_ip <<< "$curl_output"

### Build arguments list for gcloud
gcloud_args=(
  compute
  firewall-rules
  update
  "--project=jlucktay-factorio"
  "--source-ranges=$my_ip/32"
  default-allow-ssh
)

### Show arguments and execute with them
echo "Running 'gcloud' with following arguments:"
echo "${gcloud_args[@]}"

gcloud "${gcloud_args[@]}"

### Get instance and SSH into it
instance=$(
  gcloud compute instances list \
    --format=json \
    --limit=1 \
    --project=jlucktay-factorio
)

if [ "$(jq length <<< "$instance")" == 0 ]; then
  echo "$script_name: there are currently no instances running"
  exit 0
fi

name=$(jq --raw-output ".[0].name" <<< "$instance")
zone=$(basename "$(jq --raw-output ".[0].zone" <<< "$instance")")

gcloud compute ssh \
  --project=jlucktay-factorio \
  --zone="$zone" \
  "$name"
