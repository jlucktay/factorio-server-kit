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
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes --no-install-recommends \
  docker-compose \
  docker.io \
  google-cloud-sdk \
  jq \
  libarchive-tools
apt-get upgrade --assume-yes
apt-get autoremove --assume-yes

logger "=== Set up 'minecraft' user and group"
groupadd --gid 1014 minecraft
useradd --gid 1014 --uid 1014 minecraft

logger "=== Create the necessary folder structure"
mkdir --parents --verbose /opt/minecraft

logger "=== Fix up Minecraft permissions"
chown --changes --recursive minecraft:minecraft /opt/minecraft

logger "=== Set up Docker start script, and run up Docker"
systemctl enable docker
mv -v /tmp/docker-run-minecraft.sh /usr/bin/docker-run-minecraft.sh
chown --changes root:root /usr/bin/docker-run-minecraft.sh
chmod --changes u+x /usr/bin/docker-run-minecraft.sh
/usr/bin/docker-run-minecraft.sh

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

# TODO vvv - need to set some config for gopukku, most likely; rcon details

logger "=== Install our server seppuku binary"
mkdir --parents --verbose /tmp/gopukku /var/log/gopukku
cd /tmp/gopukku
get_download_url jlucktay gopukku linux_amd64 \
  | wget --input-file=- --progress=dot:giga
tar -zxvf gopukku*.tar.gz
mv --verbose gopukku /usr/bin/

# TODO ^^^

logger "=== Check that the Factorio server container came up OK"
docker top minecraft

logger "=== Tidy up and get ready to shut down"
docker stop minecraft

# TODO vvv - necessary?
rm --force --verbose /opt/minecraft/saves/*.zip
# TODO ^^^
