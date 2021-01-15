#!/usr/bin/env bash
set -euxo pipefail

### Helper functions
function get_download_url() {
  curl --silent "https://api.github.com/repos/$1/$2/releases/latest" 2> /dev/null \
    | jq --arg contains "$3" --exit-status --raw-output \
      '.assets[] | select(.browser_download_url | contains($contains)) | .browser_download_url'
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

logger "=== Patch up the system and install Docker, GCP SDK, jq, etc etc"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes --no-install-recommends \
  docker-compose \
  docker.io \
  google-cloud-sdk \
  jq \
  libarchive-tools
apt-get upgrade --assume-yes
apt-get autoremove --assume-yes

logger "=== Set up 'factorio' user and group"
groupadd --gid 845 factorio
useradd --gid 845 --uid 845 factorio

logger "=== Create the necessary folder structure"
mkdir --parents --verbose /opt/factorio/config
mkdir --parents --verbose /opt/factorio/saves

logger "=== Fix up Factorio permissions"
chown --changes --recursive factorio:factorio /opt/factorio

logger "=== Pull latest Graftorio and set up"
git clone --depth 1 -- https://github.com/TheVirtualCrew/graftorio /opt/factorio/mods/graftorio
mkdir --parents --verbose /opt/factorio/mods/graftorio/data/grafana
mkdir --parents --verbose /opt/factorio/mods/graftorio/data/prometheus

logger "=== Install yq"
get_download_url mikefarah yq linux_amd64.tar.gz | wget --input-file=- --progress=dot:giga -O - | tar vxz
mv -iv ./yq_linux_amd64 /usr/bin/yq

logger "=== Fix up some settings in Graftorio Docker Compose YAML"
yq_expression='(.services.*.restart = "always") | '
yq_expression+='(.services.exporter.volumes[0] = "/opt/factorio/script-output/graftorio:/textfiles") | '
yq_expression+='(.services.grafana.user = "nobody") | '
yq_expression+='(.services.grafana.volumes[0] = "/opt/factorio/mods/graftorio/data/grafana:/var/lib/grafana") | '
yq_expression+='(.services.prometheus.user = "nobody") | '
yq_expression+='(.services.prometheus.volumes[0] = "/opt/factorio/mods/graftorio/data/prometheus:/prometheus") | '
yq_expression+='(.services.prometheus.volumes[1] = "/opt/factorio/mods/graftorio/data/prometheus.yml:/etc/prometheus/prometheus.yml")'

yq eval --inplace "$yq_expression" /opt/factorio/mods/graftorio/docker-compose.yml

logger "=== Fix up Graftorio permissions"
chown --changes --recursive nobody /opt/factorio/mods/graftorio

logger "=== Add factorio.com secrets to environment"
if ! secrets="$(gsutil cat "gs://${CLOUDSDK_CORE_PROJECT:?}-storage/lib/secrets.json")" \
  || ! USERNAME="$(jq --exit-status --raw-output ".username" <<< "$secrets")" \
  || ! TOKEN="$(jq --exit-status --raw-output ".token" <<< "$secrets")"; then

  echo >&2 "Error retrieving secrets."
  exit 1
fi
export USERNAME
export TOKEN
# export UPDATE_MODS_ON_START=true # TODO(jlucktay): re-enable once Graftorio is OK with Factorio v0.18

logger "=== Set up Docker start script, and run everything up with Docker and Compose"
systemctl enable docker
mv -v /tmp/docker-run-factorio.sh /usr/bin/docker-run-factorio.sh
chown --changes root:root /usr/bin/docker-run-factorio.sh
chmod --changes u+x /usr/bin/docker-run-factorio.sh
/usr/bin/docker-run-factorio.sh

docker-compose --file=/opt/factorio/mods/graftorio/docker-compose.yml up -d

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

logger "=== Wait for Grafana to become available"
while ! (echo > /dev/tcp/localhost/3000) &> /dev/null; do
  sleep 1s
done

logger "=== Reset Grafana password"
if ! grafana_password="$(jq --exit-status --raw-output ".password" <<< "$secrets")"; then
  echo >&2 "Error retrieving secrets."
  exit 1
fi

curl \
  --data '{
    "confirmNew": "'"$grafana_password"'",
    "newPassword": "'"$grafana_password"'",
    "oldPassword": "admin"
  }' \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --include \
  --max-time 5 \
  --request PUT \
  --retry 10 \
  --retry-connrefused \
  --retry-delay 1 \
  --retry-max-time 60 \
  --verbose \
  "http://admin:admin@localhost:3000/api/user/password"

logger "=== Install our server seppuku binary"
mkdir --parents --verbose /tmp/goppuku /var/log/goppuku
cd /tmp/goppuku
get_download_url jlucktay goppuku linux_amd64 \
  | wget --input-file=- --progress=dot:giga
tar -zxvf goppuku*.tar.gz
mv --verbose goppuku /usr/bin/

logger "=== Check that the Factorio server container came up OK"
docker top factorio

logger "=== Tidy up and get ready to shut down"
docker stop factorio
rm --force --verbose /opt/factorio/saves/*.zip
