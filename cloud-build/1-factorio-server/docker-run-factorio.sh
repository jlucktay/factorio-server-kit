#!/usr/bin/env bash
set -euxo pipefail

container_name="factorio"
image_name="factoriotools/factorio"
image_tag="stable"
image="$image_name":"$image_tag"

docker rm "$container_name" || true
docker pull "$image"

docker run \
  --detach \
  --env USERNAME \
  --env TOKEN \
  --env UPDATE_MODS_ON_START \
  --name="$container_name" \
  --publish=27015:27015/tcp \
  --publish=34197:34197/udp \
  --restart=on-failure \
  --volume=/opt/"$container_name":/"$container_name" \
  "$image"
