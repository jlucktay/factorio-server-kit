#!/usr/bin/env bash
set -euxo pipefail
shopt -s globstar nullglob
IFS=$'\n\t'

docker rm factorio || true
docker pull factoriotools/factorio:latest

docker run \
  --detach \
  --env USERNAME \
  --env TOKEN \
  --env UPDATE_MODS_ON_START \
  --name=factorio \
  --publish=27015:27015/tcp \
  --publish=34197:34197/udp \
  --restart=on-failure \
  --volume=/opt/factorio:/factorio \
  factoriotools/factorio:latest
