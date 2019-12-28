#!/usr/bin/env bash
set -euxo pipefail
IFS=$'\n\t'

# Log setup and function
cd /tmp
curl --remote-name --show-error --silent https://dl.google.com/cloudagents/install-logging-agent.sh
bash install-logging-agent.sh

logger "=== Set Docker's log driver to google-fluentd (gcplogs)"
mkdir --parents --verbose /etc/docker
# echo '{"log-driver":"gcplogs","log-opts":{"env":"VERSION","gcp-log-cmd":"true","labels":"maintainer"}}' | tee /etc/docker/daemon.json # TODO: fix permissions error
# 2019-12-26T11:40:44+11:00: ==> googlecompute: docker: Error response from daemon: failed to initialize logging driver: unable to connect or authenticate with Google Cloud Logging: rpc error: code = PermissionDenied desc = Request had insufficient authentication scopes.

logger "=== Set Bash as shell in crontab"
sed --expression "s,^SHELL=/bin/sh$,SHELL=/bin/bash,g" --in-place /etc/crontab

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
apt upgrade --assume-yes
apt autoremove --assume-yes

logger "=== Set up 'factorio' user and group"
groupadd --gid 845 factorio
useradd --gid 845 --uid 845 factorio

logger "=== Create the necessary folder structure"
mkdir --parents --verbose /opt/factorio/config
mkdir --parents --verbose /opt/factorio/saves

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
rm --force --verbose docker-compose.{1..6}.yml
mv --force --verbose docker-compose.7.yml docker-compose.yml

logger "=== Fix up Graftorio permissions"
chown --changes --recursive nobody /opt/graftorio

logger "=== Enable Docker auto-restart, and run everything up with Docker Compose"
systemctl enable docker
docker run \
  --detach \
  --name factorio \
  --publish 27015:27015/tcp \
  --publish 34197:34197/udp \
  --volume /opt/factorio:/factorio \
  factoriotools/factorio
docker-compose --file=/opt/graftorio/docker-compose.yml up -d

logger "=== Give the containers a moment to warm up"
sleep 10s

logger "=== Tidy up and get ready to shut down"
docker stop factorio
rm --force --verbose /opt/factorio/saves/*.zip

logger "=== Manage Docker as non-root users"
logger "+++ Users already present"
while IFS= read -r line; do
  user_id=$(cut --delimiter=":" --fields=3 <<< "$line")

  if ((user_id > 1000)) && ((user_id < 65534)); then
    user_name=$(cut --delimiter=":" --fields=1 <<< "$line")
    usermod --append --groups docker "$user_name"
  fi
done < /etc/passwd

logger "+++ Users added via conventional adduser"
echo 'EXTRA_GROUPS="docker"' | tee --append /etc/adduser.conf
echo 'ADD_EXTRA_GROUPS=1' | tee --append /etc/adduser.conf

logger "+++ Users added via GCE bootstrap (ref: \
https://github.com/GoogleCloudPlatform/compute-image-packages/tree/master/packages/python-google-compute-engine)"
gce_groups=$(grep "^groups = " /etc/default/instance_configs.cfg)
gce_groups+=",docker"

cat << EOF > /etc/default/instance_configs.cfg.template
[Accounts]
$gce_groups
EOF

/usr/bin/google_instance_setup

logger "=== Get Go and install our server seppuku binary"
snap install go --classic
/snap/bin/go get github.com/jlucktay/factorio-workbench/go-rcon
