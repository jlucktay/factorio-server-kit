#!/usr/bin/env bash
set -euo pipefail

FACTORIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && git rev-parse --show-toplevel)"
readonly FACTORIO_ROOT

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

# Argument defaults
location=${FACTORIO_LOCATION:?}
machine_type=
open_logs=0
server_type=factorio
template_filter="${FACTORIO_IMAGE_FAMILY:?}-*"
zone=${FACTORIO_SERVER_LOCATIONS[$FACTORIO_LOCATION]:?"'location' key \
'$FACTORIO_LOCATION' not found in '$FACTORIO_ROOT/lib/locations.json'."}

### Set up usage/help output
function usage() {
  cat << HEREDOC

  Usage: ${script_name:?} [ --help | [--logs] [--machine-type=...] [--<server type>] [--<location>] ]

  Optional arguments:
    -h, --help             show this help message and exit
    -l, --logs             open the Stackdriver Logging page after creating the server
    -m, --machine-type     provision the server VM with this machine-type hardware spec
                           see 'gcloud compute machine-types list' for valid values

  Optional arguments for server type:
        --factorio         Factorio server using the 'factoriotools/factorio' image (default type)

  Optional arguments for server location:
HEREDOC

  # https://www.reddit.com/r/bash/comments/5wma5k/is_there_a_way_to_sort_an_associative_array_by/debbjsp/
  sorted_locations=$(printf '%s\0' "${!FACTORIO_SERVER_LOCATIONS[@]}" | sort --zero-terminated)
  mapfile -d '' sorted_keys <<< "$sorted_locations"

  for key in "${sorted_keys[@]}"; do
    printf '        --%-16s run from %s' "$key" "${FACTORIO_SERVER_LOCATIONS[$key]}"

    if [[ $zone == "${FACTORIO_SERVER_LOCATIONS[$key]}" ]]; then
      printf ' (default location)'
    fi

    printf '\n'
  done

  cat << HEREDOC

  NOTE: if multiple locations are specified, the last one wins

  Example:
    $script_name --logs --machine-type=f1-micro --sydney
      provision a server with f1-micro hardware in the Sydney (australia-southeast1) region, and open the Stackdriver
      logs page after the server is created
HEREDOC
}

### Parse given arguments
for arg in "$@"; do
  case $arg in
    -h | --help)
      usage
      exit 0
      ;;
    -l | --logs)
      open_logs=1
      shift
      ;;
    -m=* | --machine-type=*)
      machine_type=${arg#*=}
      shift
      ;;
    --factorio)
      server_type=factorio
      template_filter="${FACTORIO_IMAGE_FAMILY:?}-*"
      shift
      ;;
    *)
      location=${arg:2}
      if [[ -n ${FACTORIO_SERVER_LOCATIONS[$location]+is_set} ]]; then
        shift
      else
        usage
        exit 1
      fi
      ;;
  esac
done

eval_input=$(factorio::env::set_location "${FACTORIO_SERVER_LOCATIONS[$location]}")
eval "$eval_input"

if [[ -n $machine_type ]]; then
  echo -n "Validating machine type '$machine_type'..."
  gcloud_machine_list=$(gcloud "--format=value(name)" compute machine-types list)
  mapfile -t valid_machine_types_in_zone <<< "$gcloud_machine_list"
  valid_mt=0

  for ((i = 0; i < ${#valid_machine_types_in_zone[@]}; i += 1)); do
    echo -n "."
    if [[ $machine_type == "${valid_machine_types_in_zone[$i]}" ]]; then
      valid_mt=1
      break
    fi
  done

  if ((valid_mt == 0)); then
    echo
    err "machine type '$machine_type' is not valid in zone '${CLOUDSDK_COMPUTE_ZONE:?}'."
  fi

  unset valid_mt

  echo " valid and available in zone '$CLOUDSDK_COMPUTE_ZONE'."
fi

# Delete any old servers that may already be deployed within the project
factorio::vm::delete_instances "$server_type"-*

# Look up latest instance template
gcloud_template_list_args=(
  --format "value(name)"
  compute
  instance-templates
  list
  --filter "name:$template_filter"
  --limit 1
  --sort-by ~creationTimestamp
)

echo -n "Listing instance templates: gcloud "
echo "${gcloud_template_list_args[@]}"
instance_template=$(gcloud "${gcloud_template_list_args[@]}")

if [[ -z $instance_template ]]; then
  err "no instance templates named '$template_filter' were found"
fi

# Create instance from template
gcloud_instance_create_args=(
  --format json
  compute
  instances
  create
)

if [[ -n $machine_type ]]; then
  gcloud_instance_create_args+=("--machine-type=$machine_type")
fi

gcloud_instance_create_args+=(
  --source-instance-template "$instance_template"
  --subnet default
  "$server_type-$location-$(TZ=UTC date '+%Y%m%d-%H%M%S')"
)

echo -n "Creating instance: gcloud "
echo "${gcloud_instance_create_args[@]}"
new_instance=$(gcloud "${gcloud_instance_create_args[@]}")
new_instance_id=$(jq --raw-output '.[0].id' <<< "$new_instance")
new_instance_ip=$(jq --raw-output '.[0].networkInterfaces[0].accessConfigs[0].natIP' <<< "$new_instance")

factorio::dns::update "$server_type" "$new_instance_ip"

if ((open_logs == 1)); then
  logs_link="https://console.cloud.google.com/logs/viewer?project=${CLOUDSDK_CORE_PROJECT:?}"
  logs_link+="&resource=gce_instance/instance_id/$new_instance_id"

  echo "Opening the log viewer link: '$logs_link'"
  open "$logs_link"
fi
