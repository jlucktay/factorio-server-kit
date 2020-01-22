#!/usr/bin/env bash
set -euxo pipefail
IFS=$'\n\t'

logger "=== Get configs from Storage"
locations_json="/etc/locations.json"
gsutil cp gs://jlucktay-factorio-storage/lib/locations.json "$locations_json"
# gsutil -m cp gs://jlucktay-factorio-storage/fluentd/* /etc/google-fluentd/config.d/ # currently empty
gsutil -m cp gs://jlucktay-factorio-storage/config/*-settings.json /opt/factorio/config/
gsutil -m cp gs://jlucktay-factorio-storage/config/server-*list.json /opt/factorio/config/

logger "=== Get most recent game saves from appropriate Storage bucket"
mtime_high_score=0

for ((i = 0; i < $(jq length "$locations_json"); i += 1)); do
  location="$(jq --raw-output ".[$i] | .location" "$locations_json")"

  for mtime in $(gsutil stat "gs://jlucktay-factorio-saves-$location/_autosave*.zip" \
    | grep goog-reserved-file-mtime \
    | cut -d":" -f2); do

    if ((mtime > mtime_high_score)); then
      mtime_high_score=$mtime
      most_recent_saves_location=$location
    fi
  done
done

gsutil -m cp -P "gs://jlucktay-factorio-saves-$most_recent_saves_location/*" /opt/factorio/saves/

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
    "$locations_json"
)

logger "=== Schedule a cron job (if not already present) to push the saves back to Storage"
cron_job="* * * * * root"                                # Schedule, and user to run as
cron_job+=' gsutil -m rsync -P -x ".*\.tmp\.zip"'        # -m parallel, -P preserve timestamps, -x exclude pattern
cron_job+=' /opt/factorio/saves'                         # Source path
cron_job+=" gs://jlucktay-factorio-saves-$push_saves_to" # Destination bucket (co-located with instance)
cron_job+=' |& logger'                                   # Send everything to Stackdriver

if ! grep -F "$cron_job" /etc/crontab &> /dev/null; then
  echo "$cron_job" >> /etc/crontab
fi

logger "=== Update and start the Factorio server"
/usr/bin/docker-run-factorio.sh

logger "=== Start up our server seppuku binary"
gopukku &> "/var/log/gopukku/gopukku.$(TZ=UTC date +%Y%m%d.%H%M%S).log" &
