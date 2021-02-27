#!/usr/bin/env bash
set -euo pipefail

readonly script_dir=$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && pwd)
readonly FACTORIO_ROOT="$(git -C "$script_dir" rev-parse --show-toplevel)"

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

cd "$script_dir"

mapfile -t func_names < <(go doc | awk -F' |\\\(' '$1 == "func" { print $2 }')

for func_name in ${func_names[*]}; do
  function_name=$(echo "cleanup-$func_name" | awk '{ print tolower($0) }')

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

    echo "Cleaning up existing function: gcloud ${gcloud_delete_args[*]}"
    gcloud "${gcloud_delete_args[@]}"
  done

  gcloud_deploy_args=(
    functions
    deploy
    "$function_name"
    --entry-point "$func_name"
    --max-instances 1
    --runtime go113
    --trigger-topic "$function_name"
  )

  echo "Deploying '$function_name': gcloud ${gcloud_deploy_args[*]}"
  gcloud "${gcloud_deploy_args[@]}"
done
