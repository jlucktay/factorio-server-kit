#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && pwd)"
FACTORIO_ROOT=$(realpath --canonicalize-existing "$script_dir/..")

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

factorio::password

# One time only

echo "Updating password..."
curl \
  --data '{
    "confirmNew": "'"${FACTORIO_PASSWORD:-}"'",
    "newPassword": "'"$FACTORIO_PASSWORD"'",
    "oldPassword": "admin"
  }' \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --request PUT \
  --silent \
  "http://admin:admin@${FACTORIO_DNS_NAME:-}:3000/api/user/password" \
  | jq

echo "Adding Prometheus data source..."
curl \
  --data '{
    "access": "proxy",
    "isDefault": true,
    "jsonData": {
      "timeInterval": "10s"
    },
    "name": "Graftorio - Prometheus",
    "type": "prometheus",
    "url": "http://prometheus:9090"
  }' \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --request POST \
  --silent \
  "http://admin:$FACTORIO_PASSWORD@$FACTORIO_DNS_NAME:3000/api/datasources" \
  | jq

echo -n "Adding new dashboard..."
new_dashboard=$(
  curl \
    --data '{
      "dashboard": {
        "id": null,
        "timezone": "browser",
        "title": "Hello Factorio",
        "uid": null
      },
      "message": "grafana-setup.sh",
      "overwrite": false
    }' \
    --header "Accept: application/json" \
    --header "Content-Type: application/json" \
    --request POST \
    --silent \
    "http://admin:$FACTORIO_PASSWORD@$FACTORIO_DNS_NAME:3000/api/dashboards/db" \
    | jq
)
echo " done."

jq '.' <<< "$new_dashboard"

new_dashboard_uid=$(jq --raw-output '.uid' <<< "$new_dashboard")

echo "New dashboard UID: '$new_dashboard_uid'"

echo "Getting new dashboard..."
curl \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --request GET \
  --silent \
  "http://admin:$FACTORIO_PASSWORD@$FACTORIO_DNS_NAME:3000/api/dashboards/uid/$new_dashboard_uid" \
  | jq

# Per boot

# One time vs per boot? TBD
