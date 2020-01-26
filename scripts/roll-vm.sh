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

# Argument defaults
location=tokyo
zone=${FACTORIO_SERVER_LOCATIONS[$location]:-"LOCATION_KEY_NOT_FOUND"}

machine_type=
open_logs=0

# TODO: Los Angeles DC doesn't have N2 machine type, but it does have E2

if [ "$zone" == "LOCATION_KEY_NOT_FOUND" ]; then
  err "location key '$location' was not found in $(realpath "$FACTORIO_ROOT/lib/locations.json")."
  exit 1
fi

### Set up usage/help output
function usage() {
  cat << HEREDOC

  Usage: ${script_name:-} [--help | [--logs] [--machine-type=...] --<location>]

  Optional arguments:
    -h, --help             show this help message and exit
    -l, --logs             open the Stackdriver Logging page after creating the server
    -m, --machine-type     provision the server VM with this machine-type hardware spec
                           see 'gcloud compute machine-types list' for valid values

  Optional arguments for server location:
HEREDOC

  # https://www.reddit.com/r/bash/comments/5wma5k/is_there_a_way_to_sort_an_associative_array_by/debbjsp/
  mapfile -d '' sorted_keys < <(printf '%s\0' "${!FACTORIO_SERVER_LOCATIONS[@]}" | sort --zero-terminated)

  for key in "${sorted_keys[@]}"; do
    printf '        --%-16s run from %s' "$key" "${FACTORIO_SERVER_LOCATIONS[$key]}"

    if [ "$zone" == "${FACTORIO_SERVER_LOCATIONS[$key]}" ]; then
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
    -m=* | --machine-type=*)
      machine_type=${i#*=}
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

if test -n "$machine_type"; then
  echo -n "Validating machine type '$machine_type'..."
  mapfile -t valid_machine_types_in_zone < <(
    gcloud "--format=value(name)" \
      compute \
      machine-types \
      list \
      --zones="${FACTORIO_SERVER_LOCATIONS[$location]}"
  )

  valid_mt=0

  for ((i = 0; i < ${#valid_machine_types_in_zone[@]}; i += 1)); do
    echo -n "."
    if [ "$machine_type" == "${valid_machine_types_in_zone[$i]}" ]; then
      valid_mt=1
      break
    fi
  done

  if ((valid_mt == 0)); then
    echo
    err "machine type '$machine_type' is not valid in zone '${FACTORIO_SERVER_LOCATIONS[$location]}'."
    exit 1
  fi

  echo " valid and available in zone '${FACTORIO_SERVER_LOCATIONS[$location]}'."
fi

# Delete any old servers that may already be deployed within the project
factorio::vm::delete_instances factorio-*

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
  err "no instance templates named 'packtorio-*' were found"
  exit 1
fi

# Create instance from template
gcloud_args=(
  "--format=json"
  compute
  instances
  create
)

if test -n "$machine_type"; then
  gcloud_args+=("--machine-type=$machine_type")
fi

gcloud_args+=(
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

echo "Updating the A record '${FACTORIO_DNS_NAME:-}' in Cloud DNS with new IP of '$new_instance_ip'..."

gcloud \
  dns record-sets transaction \
  start \
  --zone=factorio-server \
  &> /dev/null

old_dns_ip=$(
  gcloud --format=json \
    dns record-sets list \
    --filter="name:${FACTORIO_DNS_NAME}." \
    --zone=factorio-server \
    | jq --raw-output '.[].rrdatas[]'
)

gcloud \
  dns record-sets transaction \
  remove "$old_dns_ip" \
  --name="${FACTORIO_DNS_NAME}." \
  --ttl=30 \
  --type=A \
  --zone=factorio-server \
  &> /dev/null

gcloud \
  dns record-sets transaction \
  add "$new_instance_ip" \
  --name="${FACTORIO_DNS_NAME}." \
  --ttl=30 \
  --type=A \
  --zone=factorio-server \
  &> /dev/null

gcloud \
  dns record-sets transaction \
  execute \
  --zone=factorio-server \
  &> /dev/null

if ((open_logs == 1)); then
  logs_link="https://console.cloud.google.com/logs/viewer?project=${CLOUDSDK_CORE_PROJECT:-}"
  logs_link+="&resource=gce_instance/instance_id/${new_instance_id}"

  echo "Opening the log viewer link: '$logs_link'"
  open "$logs_link"
fi
