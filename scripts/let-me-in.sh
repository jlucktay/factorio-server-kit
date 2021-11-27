#!/usr/bin/env bash
set -euo pipefail

FACTORIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && git rev-parse --show-toplevel)"
readonly FACTORIO_ROOT

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

curl_output=$(curl --silent http://httpbin.org/ip | jq --raw-output '.origin')
[[ $curl_output =~ ([0-9]{1,3}\.){3}[0-9]{1,3} ]]
my_ip=${BASH_REMATCH[0]}

### Look at current rule to see if it needs to be changed
gcloud_firewall_describe_args=(
  compute
  firewall-rules
  describe
  default-allow-ssh
  --format=json
)

echo "Describing firewall rule: gcloud ${gcloud_firewall_describe_args[*]}"
description=$(gcloud "${gcloud_firewall_describe_args[@]}")

### Update the firewall rule if the IP differs
if [ "$my_ip/32" != "$(jq --raw-output '.sourceRanges[0]' <<< "$description")" ]; then
  gcloud_firewall_update_args=(
    compute
    firewall-rules
    update
    default-allow-ssh
    "--source-ranges=$my_ip/32"
  )

  echo "Updating firewall rule: gcloud ${gcloud_firewall_update_args[*]}"
  gcloud "${gcloud_firewall_update_args[@]}"
fi

### Get Factorio server instance and SSH into it
gcloud_instance_list_args=(
  compute
  instances
  list
  --filter="name:factorio-*"
  --format=json
  --limit=1
)

echo "Listing existing instances: gcloud ${gcloud_instance_list_args[*]}"
instance=$(gcloud "${gcloud_instance_list_args[@]}")

if [ "$(jq length <<< "$instance")" == 0 ]; then
  err "there are no instances currently running"
fi

name=$(jq --raw-output ".[0].name" <<< "$instance")
zone=$(basename "$(jq --raw-output ".[0].zone" <<< "$instance")")

gcloud_ssh_args=(
  compute
  ssh
  "$name"
  --zone="$zone"
)

echo "SSHing into Factorio server instance: gcloud ${gcloud_ssh_args[*]}"
gcloud "${gcloud_ssh_args[@]}"
