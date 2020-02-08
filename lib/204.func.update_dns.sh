#!/usr/bin/env bash
set -euo pipefail

function factorio::dns::update() {
  echo "Updating the 'A' record '$1' in Cloud DNS with new IP '$2'..."

  gcloud \
    dns record-sets transaction \
    start \
    --zone=factorio-server \
    &> /dev/null

  old_dns_ip=$(
    gcloud --format=json \
      dns record-sets list \
      --filter="name:${FACTORIO_DNS_NAME:?}." \
      --zone=factorio-server \
      | jq --raw-output '.[].rrdatas[]'
  )

  gcloud \
    dns record-sets transaction \
    remove "$old_dns_ip" \
    --name="$FACTORIO_DNS_NAME." \
    --ttl=30 \
    --type=A \
    --zone=factorio-server \
    &> /dev/null

  gcloud \
    dns record-sets transaction \
    add "$2" \
    --name="$FACTORIO_DNS_NAME." \
    --ttl=30 \
    --type=A \
    --zone=factorio-server \
    &> /dev/null

  gcloud \
    dns record-sets transaction \
    execute \
    --zone=factorio-server \
    &> /dev/null
}
