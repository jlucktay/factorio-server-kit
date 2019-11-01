#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Drop a note when this script is done (note: 'done' might include exiting prematurely due to an error!)
trap "echo DONE >> /root/startup-script.log" INT TERM EXIT

# Fix root's $PS1
sed --expression "s/#force_color_prompt=yes/force_color_prompt=yes/g" --in-place /root/.bashrc

# Patch up, and install Docker
apt update
apt install --assume-yes --no-install-recommends docker.io
apt upgrade --assume-yes --no-install-recommends
apt autoremove --assume-yes

# Set up 'factorio' user and group
groupadd --gid 845 factorio
useradd --gid 845 --uid 845 factorio

# Create the necessary folder structure
mkdir --parents /opt/factorio/config
chown --recursive 845:845 /opt/factorio

# Get the server config from Storage
PATH+=:/snap/bin && export PATH
gsutil cp gs://jlucktay-factorio-asia/server-settings.json /opt/factorio/config/
chown --recursive 845:845 /opt/factorio

# Run the server
docker run \
    --detach \
    --name factorio \
    --publish 27015:27015/tcp \
    --publish 34197:34197/udp \
    --restart=always \
    --volume /opt/factorio:/factorio \
    factoriotools/factorio
