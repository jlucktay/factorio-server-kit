#!/usr/bin/env bash
set -euo pipefail

# Arguments:
# - 1: type of server               ["factorio", "minecraft"]
# - 2: IP to update into the record

function factorio::dns::update() {
  set -x

  # The DNS name/'A' record to update ["factorio.menagerie.games.", "minecraft.menagerie.games."]
  local dns_name="${1:?}.menagerie.games."

  echo "Updating the 'A' record '$dns_name' in Cloud DNS with new IP '${2:?}'..."

  local zone="factorio-server" # TODO: straighten this out, and stop running DNS out of one project

  gcloud \
    dns record-sets transaction \
    start \
    --zone="$zone" \
    &> /dev/null

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
    --zone="$zone" \
    &> /dev/null

  gcloud \
    dns record-sets transaction \
    add "$2" \
    --name="$dns_name" \
    --ttl=30 \
    --type=A \
    --zone="$zone" \
    &> /dev/null

  gcloud \
    dns record-sets transaction \
    execute \
    --zone="$zone" \
    &> /dev/null

  set +x
}
