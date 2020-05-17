#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

readonly FACTORIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && git rev-parse --show-toplevel)"

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

function_name=cleanup-instances
topic_name=$function_name

gcloud_list_args=(
  --format json
  functions
  list
  --filter "name:$function_name"
)

echo "Looking for existing '$function_name' functions deployed outside the '${CLOUDSDK_FUNCTIONS_REGION:?}' region..."
mapfile -t functions_list < <(gcloud "${gcloud_list_args[@]}" | jq --raw-output '.[].name')

delete_region=()

for ((i = 0; i < ${#functions_list[@]}; i += 1)); do
  func=${functions_list[$i]##*locations/}
  func=${func%%/functions*}

  if [ "$func" != "${CLOUDSDK_FUNCTIONS_REGION:?}" ]; then
    delete_region+=("$func")
  fi
done

for ((i = 0; i < ${#delete_region[@]}; i += 1)); do
  gcloud_delete_args=(
    functions
    delete
    "$function_name"
    --region "${delete_region[$i]}"
    --quiet
  )

  echo -n "Cleaning up existing function: gcloud "
  echo "${gcloud_delete_args[@]}"
  gcloud "${gcloud_delete_args[@]}"
done

gcloud_deploy_args=(
  functions
  deploy
  "$function_name"
  --entry-point "Instances"
  --max-instances 1
  --runtime go113
  --trigger-topic "$topic_name"
)

echo -n "Deploying '$function_name' with arguments: "
echo "${gcloud_deploy_args[@]}"
gcloud "${gcloud_deploy_args[@]}"
