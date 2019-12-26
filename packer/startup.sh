#!/usr/bin/env bash
set -euxo pipefail
IFS=$'\n\t'

logger "=== Get configs and game saves from Storage"
# gsutil -m cp gs://jlucktay-factorio-asia/fluentd/* /etc/google-fluentd/config.d/ # currently empty
gsutil -m cp gs://jlucktay-factorio-asia/*-settings.json /opt/factorio/config/
gsutil -m cp gs://jlucktay-factorio-asia/server-*list.json /opt/factorio/config/
gsutil -m cp -P gs://jlucktay-factorio-asia/saves/* /opt/factorio/saves/

logger "=== Fix up Factorio permissions"
chown --changes --recursive factorio:factorio /opt/factorio

logger "=== Schedule a cron job (if not already present) to push the saves back to Storage"
cron_job="* * * * * root"                         # Schedule, and user to run as
cron_job+=' gsutil -m rsync -P -x ".*\.tmp\.zip"' # -m parallel, -P preserve timestamps, -x exclude pattern
cron_job+=' /opt/factorio/saves'                  # Source path
cron_job+=' gs://jlucktay-factorio-asia/saves'    # Destination path
cron_job+=' |& logger'                            # Send everything to Stackdriver

if ! grep -F "$cron_job" /etc/crontab &> /dev/null; then
  echo "$cron_job" >> /etc/crontab
fi

logger "=== Start up the Factorio server"
docker start factorio

logger "=== Start up our server seppuku binary"
/home/packer/go/bin/go-rcon &> /tmp/go-rcon.log &
