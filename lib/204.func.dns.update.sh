#!/usr/bin/env bash
set -euo pipefail

# Arguments:
# - 1: type of server               ["factorio"]
# - 2: IP to update into the record

function factorio::dns::update() {
  # The DNS name/'A' record to update ["factorio.menagerie.games."]
  local dns_name="${1:?}.menagerie.games."
  local zone="$1-server"

  echo "Updating the 'A' record '$dns_name' in zone '$zone' of Cloud DNS with new IP '${2:?}'..."

  gcloud \
    dns record-sets transaction \
    start \
    --zone="$zone"

  old_dns_ip=$(
    gcloud --format=json \
      dns record-sets list \
      --filter="name:$dns_name" \
      --zone="$zone" \
      | jq --raw-output '.[].rrdatas[]'
  )

  gcloud \
    dns record-sets transaction \
    remove "$old_dns_ip" \
    --name="$dns_name" \
    --ttl=30 \
    --type=A \
    --zone="$zone"

  gcloud \
    dns record-sets transaction \
    add "$2" \
    --name="$dns_name" \
    --ttl=30 \
    --type=A \
    --zone="$zone"

  gcloud \
    dns record-sets transaction \
    execute \
    --zone="$zone"
}
