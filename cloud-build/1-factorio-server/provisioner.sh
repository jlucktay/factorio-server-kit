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
curl --remote-name --show-error --silent https://dl.google.com/cloudagents/add-logging-agent-repo.sh
bash add-logging-agent-repo.sh --also-install

logger "=== Set Docker's log driver to google-fluentd (gcplogs)"
mkdir --parents --verbose /etc/docker
# echo '{"log-driver":"gcplogs","log-opts":{"env":"VERSION","gcp-log-cmd":"true","labels":"maintainer"}}' | tee /etc/docker/daemon.json # TODO: fix permissions error
# 2019-12-26T11:40:44+11:00: ==> googlecompute: docker: Error response from daemon: failed to initialize logging driver: unable to connect or authenticate with Google Cloud Logging: rpc error: code = PermissionDenied desc = Request had insufficient authentication scopes.

logger "=== Set Bash as shell in crontab"
sed --expression "s,^SHELL=/bin/sh$,SHELL=/bin/bash,g" --in-place /etc/crontab

logger "=== Fix root's PS1"
sed --expression "s/#force_color_prompt=yes/force_color_prompt=yes/g" --in-place /root/.bashrc

logger "=== Prepare for GCP SDK install"
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

apt-get install --assume-yes --no-install-recommends apt-transport-https ca-certificates gnupg

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

logger "=== Patch up the system and install Docker, GCP SDK, jq, etc etc"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes --no-install-recommends \
  docker-compose \
  docker.io \
  git \
  google-cloud-sdk \
  jq \
  libarchive-tools \
  python3-crcmod \
  wget
DEBIAN_FRONTEND=noninteractive apt-get upgrade --assume-yes
apt-get autoremove --assume-yes

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

logger "+++ Users added via OS Login - TODO"

logger "=== Set up 'factorio' and 'grafana' users/groups"
groupadd --gid 845 factorio
useradd --gid 845 --uid 845 factorio
groupadd --gid 472 grafana
useradd --gid 472 --uid 472 grafana

logger "=== Create the necessary folder structure"
mkdir --parents --verbose /opt/factorio/{config,mods,saves}

logger "=== Fix up Factorio permissions"
chown --changes --recursive factorio:factorio /opt/factorio

logger "=== Add factorio.com secrets to environment"
if ! secrets="$(gsutil cat "gs://${CLOUDSDK_CORE_PROJECT:?}-storage/lib/secrets.json")" \
  || ! USERNAME="$(jq --exit-status --raw-output ".username" <<< "$secrets")" \
  || ! TOKEN="$(jq --exit-status --raw-output ".token" <<< "$secrets")"; then

  echo >&2 "Error retrieving secrets."
  exit 1
fi
export USERNAME
export TOKEN
export UPDATE_MODS_ON_START=true

logger "=== Move uploaded file(s) into place"
mkdir --parents --verbose /etc/skel/.config/procps
mv --verbose /tmp/toprc /etc/skel/.config/procps/toprc

mv --verbose /tmp/docker-run-factorio.sh /usr/bin/
chown --changes root:root /usr/bin/docker-run-factorio.sh
chmod --changes u+x /usr/bin/docker-run-factorio.sh

logger "=== Run up Factorio with Docker start script"
systemctl enable docker
docker-run-factorio.sh

logger "=== Install our server seppuku binary"
mkdir --parents --verbose /tmp/goppuku /var/log/goppuku
cd /tmp/goppuku
get_download_url jlucktay goppuku Linux_x86_64 | wget --input-file=- --progress=dot:giga -O - | tar vxz
mv --verbose goppuku /usr/bin/

logger "=== Check that the Factorio container came up OK"
declare -i dtop=0

until docker top factorio; do
  ((dtop += 1))

  if [[ $dtop -gt 30 ]]; then
    exit 1
  fi

  docker logs --tail=25 factorio

  sleep 3s
done

logger "=== Tidy up Factorio and get ready to shut down"
docker rm --force factorio
rm --force --verbose /opt/factorio/saves/*.zip

logger "=== Bail out here if we're not adding Graftorio"
if [[ ${GRAFTORIO_ADDON:?} -ne 1 ]]; then
  exit 0
fi

logger "=== Pull latest Graftorio and set up"
git clone --depth 1 -- https://github.com/TheVirtualCrew/graftorio /opt/factorio/mods/graftorio
mkdir --parents --verbose /opt/factorio/mods/graftorio/data/grafana
mkdir --parents --verbose /opt/factorio/mods/graftorio/data/prometheus

logger "=== Install yq"
get_download_url mikefarah yq linux_amd64.tar.gz | wget --input-file=- --progress=dot:giga -O - | tar vxz
mv --verbose ./yq_linux_amd64 /usr/bin/yq

logger "=== Fix up some settings in Graftorio Docker Compose YAML"
yq_expression='( .services.*.restart = "always" ) | '

yq_expression+='( .services.exporter.image = "prom/node-exporter:v1.0.1" ) | '
yq_expression+='( .services.exporter.volumes = [ "/opt/factorio/script-output/graftorio:/textfiles:ro" ] ) | '

yq_expression+='( .services.grafana.image = "grafana/grafana:7.3.7" ) | '
yq_expression+='( .services.grafana.user = "grafana" ) | '
yq_expression+='( .services.grafana.volumes = [ "grafana-storage:/var/lib/grafana" ] ) | '

yq_expression+='( .services.prometheus.image = "prom/prometheus:v2.24.1" ) | '
yq_expression+='( .services.prometheus.user = "nobody" ) | '
yq_expression+='( .services.prometheus.volumes = [ '
yq_expression+='"/opt/factorio/mods/graftorio/data/prometheus:/prometheus", '
yq_expression+='"/opt/factorio/mods/graftorio/data/prometheus.yml:/etc/prometheus/prometheus.yml:ro" ] ) | '

yq_expression+='( .volumes = { "grafana-storage": {} } )'

yq eval --inplace "$yq_expression" /opt/factorio/mods/graftorio/docker-compose.yml

logger "=== Fix up Graftorio permissions cf. https://github.com/TheVirtualCrew/graftorio#installation"
chown --changes --recursive nobody /opt/factorio/mods/graftorio
chown --changes --recursive grafana:grafana /opt/factorio/mods/graftorio/data/grafana

logger "=== Run up Graftorio with Docker Compose"
docker-compose --file=/opt/factorio/mods/graftorio/docker-compose.yml up -d

logger "=== Wait for Grafana to become available"
until (echo > /dev/tcp/localhost/3000) &> /dev/null; do
  sleep 10s
done

logger "=== Get Grafana password from secrets"
if ! grafana_password="$(jq --exit-status --raw-output ".password" <<< "$secrets")"; then
  echo >&2 "Error retrieving secrets."
  exit 1
fi

logger "=== Poll Grafana API with password change request until it succeeds"
data_string='{ '
data_string+='"confirmNew": "'"$grafana_password"'", '
data_string+='"newPassword": "'"$grafana_password"'", '
data_string+='"oldPassword": "admin" '
data_string+='}'

until curl --request GET --silent "http://admin:$grafana_password@localhost:3000/api/user" \
  | jq --exit-status '.isGrafanaAdmin'; do
  curl \
    --data "$data_string" \
    --header "Accept: application/json" \
    --header "Content-Type: application/json" \
    --include \
    --max-time 10 \
    --request PUT \
    --verbose \
    "http://admin:admin@localhost:3000/api/user/password" || {
    docker-compose --file=/opt/factorio/mods/graftorio/docker-compose.yml logs --tail=5 grafana
    sleep 10s
  }
done

logger "=== Check that the Graftorio containers all came up OK"
declare -i dctop=0

until docker-compose --file=/opt/factorio/mods/graftorio/docker-compose.yml top exporter grafana prometheus; do
  ((dctop += 1))

  if [[ $dctop -gt 30 ]]; then
    exit 1
  fi

  docker-compose --file=/opt/factorio/mods/graftorio/docker-compose.yml logs --tail=25 prometheus

  sleep 3s
done

logger "=== Tidy up Graftorio and get ready to shut down"
docker-compose --file=/opt/factorio/mods/graftorio/docker-compose.yml stop
