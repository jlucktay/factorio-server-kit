#!/usr/bin/env bash
set -euxo pipefail
IFS=$'\n\t'

# Drop a note when this script is done (note: 'done' might include exiting prematurely due to an error!)
done_file=/root/startup-script.done
trap 'touch $done_file; logger "DONE"' INT TERM EXIT

# Test for reruns
if test -f "$done_file" ; then
    exit 0
fi

# Log setup and function
cd /tmp
curl --remote-name --show-error --silent https://dl.google.com/cloudagents/install-logging-agent.sh
bash install-logging-agent.sh

logger "=== Fix root's PS1"
sed --expression "s/#force_color_prompt=yes/force_color_prompt=yes/g" --in-place /root/.bashrc

logger "=== Patch up the system and install Docker, GCP SDK, JQ, etc etc"
apt update
apt install --assume-yes --no-install-recommends \
    docker-compose \
    docker.io \
    google-cloud-sdk \
    jq \
    libarchive-tools
apt upgrade --assume-yes --no-install-recommends
apt autoremove --assume-yes

logger "=== Set up 'factorio' user and group"
groupadd --gid 845 factorio
useradd --gid 845 --uid 845 factorio

logger "=== Create the necessary folder structure"
mkdir --parents --verbose /opt/factorio/config
mkdir --parents --verbose /opt/factorio/saves

logger "=== Get the configs and saves from Storage"
gsutil -m cp gs://jlucktay-factorio-asia/*-settings.json /opt/factorio/config/
gsutil -m cp -P gs://jlucktay-factorio-asia/saves/* /opt/factorio/saves/

logger "=== Fix up Factorio permissions"
chown --changes --recursive factorio:factorio /opt/factorio

logger "=== Get latest Graftorio release and extract to set up local database against"
mkdir --parents --verbose /opt/factorio/mods
curl --silent https://api.github.com/repos/afex/graftorio/releases/latest \
    | jq --raw-output ".assets[].browser_download_url" \
    | wget --input-file=- --output-document=/opt/factorio/mods/graftorio_0.0.7.zip
mkdir --parents --verbose /opt/graftorio/data/grafana
mkdir --parents --verbose /opt/graftorio/data/prometheus
bsdtar --strip-components=1 -xvf /opt/factorio/mods/graftorio_0.0.7.zip --directory /opt/graftorio

logger "=== Fix up some settings in Graftorio Docker Compose YAML"
cd /opt/graftorio
snap install yq
/snap/bin/yq write - services.exporter.volumes[0] "/opt/factorio/script-output/graftorio:/textfiles" \
    < docker-compose.yml \
    > docker-compose.1.yml
/snap/bin/yq write - services.*.restart always \
    < docker-compose.1.yml \
    > docker-compose.2.yml
/snap/bin/yq write - services.prometheus.user nobody \
    < docker-compose.2.yml \
    > docker-compose.3.yml
/snap/bin/yq write - services.grafana.user nobody \
    < docker-compose.3.yml \
    > docker-compose.4.yml
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

logger "=== Fix up Graftorio permissions"
chown --changes --recursive nobody /opt/graftorio

logger "=== Enable Docker auto-restart, and run everything up with Docker Compose"
systemctl enable docker
docker run \
    --detach \
    --name factorio \
    --publish 27015:27015/tcp \
    --publish 34197:34197/udp \
    --restart=always \
    --volume /opt/factorio:/factorio \
    factoriotools/factorio
docker-compose --file=/opt/graftorio/docker-compose.yml up -d

logger "=== Give the containers/servers some time to warm up"
sleep 30s

logger "=== Schedule a cron job to push the saves back to Storage"
echo "*/5 * * * * root gsutil -m rsync -P /opt/factorio/saves gs://jlucktay-factorio-asia/saves >> /opt/factorio/cron.log 2>&1" | tee --append /etc/crontab

logger "=== Let the upgrades from Apt kick in properly"
reboot
