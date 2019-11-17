#!/usr/bin/env bash
set -euo pipefail

FACTORIO_ROOT=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )

for lib in "${FACTORIO_ROOT}"/lib/*.sh; do
    # shellcheck disable=SC1090
    source "$lib"
done

factorio::password

factorio_instance=$( gcloud compute instances list \
    --configuration=factorio \
    --format=json )

factorio_instance_name=$( echo "$factorio_instance" | jq --raw-output '.[].name' )
# echo "factorio_instance_name: '$factorio_instance_name'"

factorio_instance_ip=$( echo "$factorio_instance" | jq --raw-output '.[].networkInterfaces[].accessConfigs[].natIP' )
# echo "factorio_instance_ip: '$factorio_instance_ip'"

# curl \
#     --data '{
#         "confirmNew": "'"${password:-}"'",
#         "newPassword": "'"${password}"'",
#         "oldPassword": "admin"
#     }' \
#     --header "Accept: application/json" \
#     --header "Content-Type: application/json" \
#     --request PUT \
#     --silent \
#     "http://admin:admin@${factorio_instance_ip}:3000/api/user/password" \
#     | jq

# curl \
#     --data '{
#         "access": "proxy",
#         "isDefault": true,
#         "jsonData": {
#             "timeInterval": "10s"
#         },
#         "name": "Graftorio - Prometheus",
#         "type": "prometheus",
#         "url": "http://prometheus:9090"
#     }' \
#     --header "Accept: application/json" \
#     --header "Content-Type: application/json" \
#     --request POST \
#     --silent \
#     "http://admin:${password}@${factorio_instance_ip}:3000/api/datasources" \
#     | jq

# curl \
#     --data '{
#         "dashboard": {
#             "id": null,
#             "timezone": "browser",
#             "title": "Hello Factorio",
#             "uid": null
#         },
#         "message": "grafana-setup.sh",
#         "overwrite": false
#     }' \
#     --header "Accept: application/json" \
#     --header "Content-Type: application/json" \
#     --request POST \
#     --silent \
#     "http://admin:${password}@${factorio_instance_ip}:3000/api/dashboards/db" \
#     | jq

curl \
    --header "Accept: application/json" \
    --request GET \
    --silent \
    "http://admin:${password}@${factorio_instance_ip}:3000/api/dashboards/uid/Yv5ie31Wk" \
    | jq
