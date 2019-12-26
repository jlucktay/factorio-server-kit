#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob globstar
IFS=$'\n\t'

FACTORIO_ROOT=$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && pwd)/..

for lib in "${FACTORIO_ROOT}"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

script_name=$(basename "${BASH_SOURCE[-1]}")

# Associative array with valid locations/zones
readonly -A locations=(
  [london]="europe-west2-c"
  [losangeles]="us-west2-a"
  [sydney]="australia-southeast1-b"
)

# Default zone/location
location=losangeles
zone=${locations[$location]}

### Set up usage/help output
function usage() {
  cat << HEREDOC

  Usage: $script_name [--help | [--logs] --<location>]

  Optional arguments:
    -h, --help            show this help message and exit
    -l, --logs            open the Stackdriver Logging page after creating the server

  Server location:
HEREDOC

  # https://www.reddit.com/r/bash/comments/5wma5k/is_there_a_way_to_sort_an_associative_array_by/debbjsp/
  mapfile -d '' sorted_keys < <(printf '%s\0' "${!locations[@]}" | sort -z)

  for key in "${sorted_keys[@]}"; do
    printf '        --%-16srun from %s' "$key" "${locations[$key]}"

    if [ "$zone" == "${locations[$key]}" ]; then
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
    if test "${locations[$location]+is_set}"; then
      shift
    else
      usage
      exit 1
    fi
    ;;
  esac
done

# Delete any old servers that may already be deployed within the project
factorio::vm::delete_all

# Look up latest instance template
gcloud_args=(
  compute
  instance-templates
  list
  "--filter=name:packer-*"
  "--format=value(name)"
  "--limit=1"
  "--project=jlucktay-factorio"
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
  compute
  instances
  create
  "--format=json"
  "--project=jlucktay-factorio"
  "--source-instance-template=$instance_template"
  "--subnet=default"
  "--zone=${locations[$location]}"
  "factorio-$location-$(TZ=UTC date '+%Y%m%d-%H%M%S')"
)

echo "Running 'gcloud' with following arguments:"
echo "${gcloud_args[@]}"

new_instance=$(gcloud "${gcloud_args[@]}")
new_instance_id=$(jq --raw-output '.[0].id' <<< "$new_instance")
new_instance_ip=$(jq --raw-output '.[0].networkInterfaces[0].accessConfigs[0].natIP' <<< "$new_instance")

echo "Server IP: $new_instance_ip"

if ((open_logs == 1)); then
  logs_link="https://console.cloud.google.com/logs/viewer?project=jlucktay-factorio"
  logs_link+="&resource=gce_instance/instance_id/${new_instance_id}"

  echo "Opening the log viewer link: '$logs_link'"
  open "$logs_link"
fi
