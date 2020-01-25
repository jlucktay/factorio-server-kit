#!/usr/bin/env bash
set -euxo pipefail
IFS=$'\n\t'

### Helper functions
function get_download_url() {
  curl --silent "https://api.github.com/repos/$1/$2/releases/latest" 2> /dev/null \
    | jq --raw-output ".assets[]
      | select(.browser_download_url | contains(\"$3\"))
      | .browser_download_url"
}
# Usage:   get_download_url <author> <repo> <release pattern>
# Example: get_download_url 99designs aws-vault linux_amd64

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
cd /opt/factorio/mods
get_download_url afex graftorio graftorio \
  | wget --input-file=- --progress=dot:giga
mkdir --parents --verbose /opt/graftorio/data/grafana
mkdir --parents --verbose /opt/graftorio/data/prometheus
bsdtar --strip-components=1 -xvf /opt/factorio/mods/graftorio*.zip --directory /opt/graftorio

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

logger "=== Set up Docker start script, and run everything up with Docker and Compose"
systemctl enable docker

cat << EOF > /usr/bin/docker-run-factorio.sh
docker pull factoriotools/factorio:latest

docker run \
  --detach \
  --name=factorio \
  --publish=27015:27015/tcp \
  --publish=34197:34197/udp \
  --restart=on-failure \
  --volume=/opt/factorio:/factorio \
  factoriotools/factorio:latest
EOF

chmod --changes u+x /usr/bin/docker-run-factorio.sh
/usr/bin/docker-run-factorio.sh

docker-compose --file=/opt/graftorio/docker-compose.yml up -d

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

logger "=== Install our server seppuku binary"
mkdir --parents --verbose /tmp/gopukku /var/log/gopukku
cd /tmp/gopukku
get_download_url jlucktay gopukku linux_amd64 \
  | wget --input-file=- --progress=dot:giga
tar -zxvf gopukku*.tar.gz
mv --verbose gopukku /usr/bin/

logger "=== Check that the Factorio server container came up OK"
docker top factorio

logger "=== Tidy up and get ready to shut down"
docker stop factorio
rm --force --verbose /opt/factorio/saves/*.zip
