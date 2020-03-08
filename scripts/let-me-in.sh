#!/usr/bin/env bash
set -euo pipefail
shopt -s globstar nullglob
IFS=$'\n\t'

readonly FACTORIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && git rev-parse --show-toplevel)"

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

curl_output=$(curl --silent http://httpbin.org/ip | jq --raw-output '.origin')
[[ $curl_output =~ ([0-9]{1,3}\.){3}[0-9]{1,3} ]]
my_ip=${BASH_REMATCH[0]}

### Build arguments list for gcloud
gcloud_firewall_update_args=(
  compute
  firewall-rules
  update
  "--source-ranges=$my_ip/32"
  default-allow-ssh
)

### Show arguments and execute with them
echo -n "Updating firewall rules: gcloud "
echo "${gcloud_firewall_update_args[@]}"
gcloud "${gcloud_firewall_update_args[@]}"

### Get Factorio server instance and SSH into it
gcloud_instance_list_args=(
  --format json
  compute
  instances
  list
  --filter "name:factorio-*"
  --limit 1
)

echo -n "Listing existing instances: gcloud "
echo "${gcloud_instance_list_args[@]}"
instance=$(gcloud "${gcloud_instance_list_args[@]}")

if [ "$(jq length <<< "$instance")" == 0 ]; then
  err "there are no instances currently running"
fi

name=$(jq --raw-output ".[0].name" <<< "$instance")
zone=$(basename "$(jq --raw-output ".[0].zone" <<< "$instance")")

gcloud_ssh_args=(
  compute
  ssh
  --zone "$zone"
  "$name"
)

echo -n "SSHing into Factorio server instance: gcloud "
echo "${gcloud_ssh_args[@]}"
gcloud "${gcloud_ssh_args[@]}"
