#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob globstar
IFS=$'\n\t'

script_dir="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && pwd)"
FACTORIO_ROOT=$script_dir/..

for lib in "${FACTORIO_ROOT}"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

# Default zone/location
location=losangeles
zone=${FACTORIO_SERVER_LOCATIONS[$location]:-"LOCATION_KEY_NOT_FOUND"}

if [ "$zone" == "LOCATION_KEY_NOT_FOUND" ]; then
  echo >&2 "${script_name:-}: location key '$location' was not found in $(realpath "$FACTORIO_ROOT/lib/locations.json")."
  exit 1
fi

### Set up usage/help output
function usage() {
  cat << HEREDOC

  Usage: ${script_name:-} [--help | [--logs] --<location>]

  Optional arguments:
    -h, --help            show this help message and exit
    -l, --logs            open the Stackdriver Logging page after creating the server

  Server location:
HEREDOC

  # https://www.reddit.com/r/bash/comments/5wma5k/is_there_a_way_to_sort_an_associative_array_by/debbjsp/
  mapfile -d '' sorted_keys < <(printf '%s\0' "${!FACTORIO_SERVER_LOCATIONS[@]}" | sort --zero-terminated)

  for key in "${sorted_keys[@]}"; do
    printf '        --%-16srun from %s' "$key" "${FACTORIO_SERVER_LOCATIONS[$key]}"

    if [ "$zone" == "${FACTORIO_SERVER_LOCATIONS[$key]}" ]; then
      printf ' (default location)'
    fi

    printf '\n'
  done

  cat << HEREDOC

  NOTE: if multiple locations are specified, the last one wins

HEREDOC
}

# Other argument defaults
open_logs=0

### Parse given arguments
for i in "$@"; do
  case $i in
  -h | --help)
    usage
    exit 0
    ;;
  -l | --logs)
    open_logs=1
    shift
    ;;
  *)
    location=${1:2}
    if test "${FACTORIO_SERVER_LOCATIONS[$location]+is_set}"; then
      shift
    else
      usage
      exit 1
    fi
    ;;
  esac
done

# Delete any old servers that may already be deployed within the project
factorio::vm::delete_all_instances

# Look up latest instance template
gcloud_args=(
  "--format=value(name)"
  compute
  instance-templates
  list
  "--filter=name:packtorio-*"
  "--limit=1"
  "--sort-by=~creationTimestamp"
)

echo "Running 'gcloud' with following arguments:"
echo "${gcloud_args[@]}"

instance_template=$(gcloud "${gcloud_args[@]}")

if test -z "$instance_template"; then
  echo "$script_name: no instance templates named 'packtorio-*' were found"
  exit 1
fi

# Create instance from template
gcloud_args=(
  "--format=json"
  compute
  instances
  create
  "--source-instance-template=$instance_template"
  "--subnet=default"
  "--zone=${FACTORIO_SERVER_LOCATIONS[$location]}"
  "factorio-$location-$(TZ=UTC date '+%Y%m%d-%H%M%S')"
)

echo "Running 'gcloud' with following arguments:"
echo "${gcloud_args[@]}"

new_instance=$(gcloud "${gcloud_args[@]}")
new_instance_id=$(jq --raw-output '.[0].id' <<< "$new_instance")
new_instance_ip=$(jq --raw-output '.[0].networkInterfaces[0].accessConfigs[0].natIP' <<< "$new_instance")

echo "Server IP: $new_instance_ip"

if ((open_logs == 1)); then
  logs_link="https://console.cloud.google.com/logs/viewer?project=${CLOUDSDK_CORE_PROJECT:-}"
  logs_link+="&resource=gce_instance/instance_id/${new_instance_id}"

  echo "Opening the log viewer link: '$logs_link'"
  open "$logs_link"
fi
