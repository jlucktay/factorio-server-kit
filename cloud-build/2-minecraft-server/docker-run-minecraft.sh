#!/usr/bin/env bash
set -euxo pipefail

container_name="minecraft"
image_name="itzg/minecraft-bedrock-server"
image_tag="latest"
image="$image_name":"$image_tag"

docker rm "$container_name" || true
docker pull "$image"

docker run \
  --detach \
  --env EULA=TRUE \
  --env GID=1014 \
  --env MAX_THREADS=0 \
  --env UID=1014 \
  --env VERSION=LATEST \
  --name="$container_name" \
  --publish=19132:19132/udp \
  --restart=on-failure \
  --volume=/opt/minecraft:/data \
  "$image"
