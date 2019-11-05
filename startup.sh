#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Drop a note when this script is done (note: 'done' might include exiting prematurely due to an error!)
trap "echo DONE >> /root/startup-script.log" INT TERM EXIT

# Fix root's PS1
sed --expression "s/#force_color_prompt=yes/force_color_prompt=yes/g" --in-place /root/.bashrc

# Patch up the system and install Docker and the GCP SDK
apt update
apt install --assume-yes --no-install-recommends docker.io google-cloud-sdk
apt upgrade --assume-yes --no-install-recommends
apt autoremove --assume-yes

# Set up 'factorio' user and group
groupadd --gid 845 factorio
useradd --gid 845 --uid 845 factorio

# Create the necessary folder structure
mkdir --parents /opt/factorio/config
mkdir --parents /opt/factorio/saves

# Get the server and map configs and saves from Storage
gsutil cp gs://jlucktay-factorio-asia/*-settings.json /opt/factorio/config/
gsutil cp -P gs://jlucktay-factorio-asia/saves/* /opt/factorio/saves/

# Fix up permissions
chown --recursive 845:845 /opt/factorio

# Run up the server and set 'restart=always' to have it come back up after a reboot
docker run \
    --detach \
    --name factorio \
    --publish 27015:27015/tcp \
    --publish 34197:34197/udp \
    --restart=always \
    --volume /opt/factorio:/factorio \
    factoriotools/factorio

# Give the server a minute to warm up
sleep 60s

# Schedule a cron job to push the saves back to Storage
echo "*/5 * * * * root gsutil -m rsync -P /opt/factorio/saves gs://jlucktay-factorio-asia/saves >> /opt/factorio/cron.log 2>&1" >> /etc/crontab

# Let the upgrades from Apt kick in properly
reboot
