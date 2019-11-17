#!/usr/bin/env bash
set -euxo pipefail
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

log "=== Patch up the system and install Docker, GCP SDK, JQ, etc etc"
log "--- apt update"
apt update
log "--- apt install --assume-yes --no-install-recommends ..."
apt install --assume-yes --no-install-recommends \
    docker-compose \
    docker.io \
    google-cloud-sdk \
    jq \
    libarchive-tools
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

log "=== Fix up Factorio permissions"
chown --changes --recursive factorio:factorio /opt/factorio

log "=== Get latest Graftorio release and extract"
log "--- add Graftorio mod to Factorio server"
mkdir --parents --verbose /opt/factorio/mods
curl --silent https://api.github.com/repos/afex/graftorio/releases/latest \
    | jq --raw-output ".assets[].browser_download_url" \
    | wget --input-file=- --output-document=/opt/factorio/mods/graftorio_0.0.7.zip
log "--- extract Graftorio release to set up local database against"
mkdir --parents --verbose /opt/graftorio/data/grafana
mkdir --parents --verbose /opt/graftorio/data/prometheus
bsdtar --strip-components=1 -xvf /opt/factorio/mods/graftorio_0.0.7.zip --directory /opt/graftorio

log "=== Fix up some settings in Graftorio Docker Compose YAML"
cd /opt/graftorio
log "--- snap install yq"
snap install yq
log "--- set volume for exporter"
/snap/bin/yq write - services.exporter.volumes[0] "/opt/factorio/script-output/graftorio:/textfiles" \
    < docker-compose.yml \
    > docker-compose.1.yml
log "--- set restart=always for all 3x services"
/snap/bin/yq write - services.*.restart always \
    < docker-compose.1.yml \
    > docker-compose.2.yml
log "--- set user=nobody for all prometheus and grafana services"
/snap/bin/yq write - services.prometheus.user nobody \
    < docker-compose.2.yml \
    > docker-compose.3.yml
/snap/bin/yq write - services.grafana.user nobody \
    < docker-compose.3.yml \
    > docker-compose.4.yml
log "--- set absolute paths for all volumes"
/snap/bin/yq write - services.prometheus.volumes[0] "/opt/graftorio/data/prometheus:/prometheus" \
    < docker-compose.4.yml \
    > docker-compose.5.yml
/snap/bin/yq write - services.prometheus.volumes[1] \
    "/opt/graftorio/data/prometheus.yml:/etc/prometheus/prometheus.yml" \
    < docker-compose.5.yml \
    > docker-compose.6.yml
/snap/bin/yq write - services.grafana.volumes[0] "/opt/graftorio/data/grafana:/var/lib/grafana" \
    < docker-compose.6.yml \
    > docker-compose.7.yml
rm -fv docker-compose.{1..6}.yml
mv -fv docker-compose.7.yml docker-compose.yml

log "=== Fix up Graftorio permissions"
chown --changes --recursive nobody /opt/graftorio

log "=== Run up Docker, Docker Compose, and the Factorio server"
log "--- enable the Docker service so that it starts whenever the system (re)boots"
systemctl enable docker
log "--- set 'restart=always' to have the container itself also come back up after a reboot"
docker run \
    --detach \
    --name factorio \
    --publish 27015:27015/tcp \
    --publish 34197:34197/udp \
    --restart=always \
    --volume /opt/factorio:/factorio \
    factoriotools/factorio
docker-compose --file=/opt/graftorio/docker-compose.yml up -d

log "=== Give the servers some time to warm up"
sleep 30s

log "=== Schedule a cron job to push the saves back to Storage"
echo "*/5 * * * * root gsutil -m rsync -P /opt/factorio/saves gs://jlucktay-factorio-asia/saves >> /opt/factorio/cron.log 2>&1" | tee --append /etc/crontab

log "=== Let the upgrades from Apt kick in properly"
reboot
