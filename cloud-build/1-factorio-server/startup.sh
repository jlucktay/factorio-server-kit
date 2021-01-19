#!/usr/bin/env bash
set -euxo pipefail

logger "=== Get project ID from metadata"
project_id=$(
  curl \
    --header "Metadata-Flavor: Google" \
    --silent \
    metadata.google.internal/computeMetadata/v1/project/project-id
)

logger "=== Get configs from Storage"
locations=$(gsutil cat "gs://$project_id-storage/lib/locations.json")

# Configs may or may not exist in Storage
gsutil -m cp "gs://$project_id-storage/fluentd/*" /etc/google-fluentd/config.d/ || true
gsutil -m cp "gs://$project_id-storage/config/*-settings.json" /opt/factorio/config/ || true
gsutil -m cp "gs://$project_id-storage/config/server-*list.json" /opt/factorio/config/ || true

logger "=== Get most recent game saves from appropriate Storage bucket"
mtime_high_score=0
most_recent_saves_location=

mapfile -t arr_locations < <(jq --raw-output ".[].location" <<< "$locations")

for location in "${arr_locations[@]}"; do
  stat=$(gsutil -m stat "gs://$project_id-saves-$location/_autosave*.zip" 2> /dev/null || true)

  if [ ${#stat} -eq 0 ]; then
    continue
  fi

  mapfile -t mtimes < <(grep goog-reserved-file-mtime <<< "$stat" | cut -d":" -f2)

  for mtime in "${mtimes[@]}"; do
    if ((mtime > mtime_high_score)); then
      mtime_high_score=$mtime
      most_recent_saves_location=$location
    fi
  done
done

if [ -n "$most_recent_saves_location" ]; then
  gsutil -m cp -P "gs://$project_id-saves-$most_recent_saves_location/*" /opt/factorio/saves/
fi

logger "=== Fix up Factorio permissions"
chown --changes --recursive factorio:factorio /opt/factorio

logger "=== Get instance's zone from metadata, to push new saves to the local bucket"
instance_zone=$(
  curl \
    --header "Metadata-Flavor: Google" \
    --silent \
    metadata.google.internal/computeMetadata/v1/instance/zone
)

push_saves_to=$(
  jq --raw-output \
    '.[] | select(.zone == "'"$(basename "$instance_zone")"'") | .location' \
    <<< "$locations"
)

logger "=== Schedule a cron job (if not already present) to push the saves back to Storage"
cron_job="* * * * * root"                          # Schedule, and user to run as
cron_job+=' gsutil -m rsync -P -x ".*\.tmp\.zip"'  # -m parallel, -P preserve timestamps, -x exclude pattern
cron_job+=' /opt/factorio/saves'                   # Source path
cron_job+=" gs://$project_id-saves-$push_saves_to" # Destination bucket (co-located with instance)
cron_job+=' |& logger'                             # Send everything to Stackdriver

if ! grep -F "$cron_job" /etc/crontab &> /dev/null; then
  echo "$cron_job" >> /etc/crontab
fi

logger "=== Add factorio.com secrets to environment"
if ! secrets="$(gsutil cat "gs://$project_id-storage/lib/secrets.json")" \
  || ! USERNAME="$(jq --exit-status --raw-output ".username" <<< "$secrets")" \
  || ! TOKEN="$(jq --exit-status --raw-output ".token" <<< "$secrets")"; then

  echo >&2 "Error retrieving secrets."
  exit 1
fi
export USERNAME
export TOKEN
# export UPDATE_MODS_ON_START=true # TODO(jlucktay): re-enable once Graftorio is OK with Factorio v0.18

logger "=== Upgrade and (re)start the Factorio server"
docker-run-factorio.sh

logger "=== Start up our server seppuku binary"
goppuku &> "/var/log/goppuku/goppuku.$(TZ=UTC date +%Y%m%d.%H%M%S).log" &
