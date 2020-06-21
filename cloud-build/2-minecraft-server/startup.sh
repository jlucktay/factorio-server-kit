#!/usr/bin/env bash
set -euxo pipefail
IFS=$'\n\t'

logger "=== Get project ID from metadata"
project_id=$(curl --header "Metadata-Flavor: Google" --silent \
  metadata.google.internal/computeMetadata/v1/project/project-id)

logger "=== Get configs from Storage"
locations=$(gsutil cat "gs://$project_id-storage/lib/locations.json")

# Configs may or may not exist in Storage
gsutil -m cp "gs://$project_id-storage/config/server.properties" /opt/minecraft/ || true
gsutil -m cp "gs://$project_id-storage/config/whitelist.json" /opt/minecraft/ || true

logger "=== Get most recent game saves from appropriate Storage bucket"
mtime_high_score=0
most_recent_saves_location=

mapfile -t arr_locations < <(jq --raw-output ".[].location" <<< "$locations")

for location in "${arr_locations[@]}"; do
  if ! stat="$(gsutil -m ls -r "gs://$project_id-saves-$location" 2> /dev/null \
    | grep -Ev --null "(:$|^$)" | xargs -0 -n 1 gsutil -m stat)"; then
    :
  fi

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
  mkdir --parents --verbose /opt/minecraft/worlds
  gsutil -m cp -r -P "gs://$project_id-saves-$most_recent_saves_location/*" /opt/minecraft/worlds
fi

logger "=== Fix up Minecraft permissions"
chown --changes --recursive minecraft:minecraft /opt/minecraft

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
cron_job='* * * * * root'                          # Schedule, and user to run as
cron_job+=' gsutil -m rsync -P -r '                # -m parallel, -P preserve timestamps, -r recursive
cron_job+=' /opt/minecraft/worlds'                 # Source path
cron_job+=" gs://$project_id-saves-$push_saves_to" # Destination bucket (co-located with instance)
cron_job+=' |& logger'                             # Send everything to Stackdriver

if ! grep -F "$cron_job" /etc/crontab &> /dev/null; then
  echo "$cron_job" >> /etc/crontab
fi

logger "=== Upgrade and (re)start the Minecraft server"
/usr/bin/docker-run-minecraft.sh

exit 0

#
#
#

# TODO
logger "=== Start up our server seppuku binary"
gopukku &> "/var/log/gopukku/gopukku.$(TZ=UTC date +%Y%m%d.%H%M%S).log" &
