#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

log_file=/root/startup.log

if test -f "$log_file" ; then
    log "=== '$log_file' already exists, exiting." >> "$log_file"
    exit 0
fi

# Functions
function logsetup {
    exec > >(tee --append "$log_file")
    exec 2>&1
}

function log {
    echo "[$(date --rfc-3339=seconds)]: $*"
}

logsetup

# Drop a note when this script is done (note: 'done' might include exiting prematurely due to an error!)
trap 'log DONE' INT TERM EXIT

log "=== Fix root's PS1"
sed --expression "s/#force_color_prompt=yes/force_color_prompt=yes/g" --in-place /root/.bashrc

log "=== Patch up the system and install Docker and the GCP SDK"
log "--- apt update"
apt update
log "--- apt install --assume-yes --no-install-recommends docker.io google-cloud-sdk"
apt install --assume-yes --no-install-recommends docker.io google-cloud-sdk
log "--- apt upgrade --assume-yes --no-install-recommends"
apt upgrade --assume-yes --no-install-recommends
log "--- apt autoremove --assume-yes"
apt autoremove --assume-yes

log "=== Set up 'factorio' user and group"
groupadd --gid 845 factorio
useradd --gid 845 --uid 845 factorio

log "=== Create the necessary folder structure"
mkdir --parents --verbose /opt/factorio/config
mkdir --parents --verbose /opt/factorio/saves

log "=== Get the configs and saves from Storage"
gsutil -m cp gs://jlucktay-factorio-asia/*-settings.json /opt/factorio/config/
gsutil -m cp -P gs://jlucktay-factorio-asia/saves/* /opt/factorio/saves/

log "=== Fix up permissions"
chown --changes --recursive factorio:factorio /opt/factorio

log "=== Run up the server and set 'restart=always' to have it come back up after a reboot"
docker run \
    --detach \
    --name factorio \
    --publish 27015:27015/tcp \
    --publish 34197:34197/udp \
    --restart=always \
    --volume /opt/factorio:/factorio \
    factoriotools/factorio

log "=== Give the server some time to warm up"
sleep 30s

log "=== Schedule a cron job to push the saves back to Storage"
echo "*/5 * * * * root gsutil -m rsync -P /opt/factorio/saves gs://jlucktay-factorio-asia/saves >> /opt/factorio/cron.log 2>&1" | tee --append /etc/crontab

log "=== Let the upgrades from Apt kick in properly"
reboot
