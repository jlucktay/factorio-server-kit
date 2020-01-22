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

# Ref: https://cloud.google.com/community/tutorials/dnssec-cloud-dns-domains
checksigned() {
  ZONE=$(basename "$1" .).
  if [ "$ZONE" = .. ]; then
    ZONE=.
  fi
  NAME=$(basename "$ZONE" .)
  NO_NS=true
  NO_SEC=false

  dig +cd +noall +answer +nocl +nottl NS "$ZONE" @publicdns.goog | {
    # Check each delegated name server
    while read -r DOMAIN TYPE NS; do
      if [ "$DOMAIN $TYPE" != "$ZONE NS" ]; then
        continue
      fi
      NO_NS=false
      if dig +cd +dnssec +norecurse DNSKEY "$ZONE" "@$NS" \
        | grep -E 'RRSIG[[:space:]]+DNSKEY' > /dev/null; then
        echo "$NS has DNSSEC data for $NAME"
      else
        echo "$NS does not have DNSSEC data for $NAME"
        NO_SEC=true
      fi
    done

    if "$NO_NS"; then
      echo "$NAME is not a delegated DNS zone"
    else
      if "$NO_SEC"; then
        return
      fi
      MINTTL=$(dig +cd SOA "$ZONE" @publicdns.goog \
        | awk '/^[^;]/ && $4=="SOA" { print $11 }')
      echo "Negative cache for $NAME expires after $MINTTL seconds."
    fi
  }
}

checksigned "$1"
