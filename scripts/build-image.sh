#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob globstar
IFS=$'\n\t'

packer build -timestamp-ui ./packer/googlecompute.json

# Clean up old images; all but most recent
gcloud_args=(
  compute
  images
  list
  "--filter=family:packtorio"
  "--format=json"
  "--project=jlucktay-factorio"
  '--sort-by=~creationTimestamp'
)

images=$(gcloud "${gcloud_args[@]}")

# i is 1 to preserve the first/newest image
for ((i = 1; i < $(jq length <<< "$images"); i += 1)); do
  image_name=$(jq --raw-output ".[$i].name" <<< "$images")

  echo "Pruning old image '$image_name'..."
  gcloud compute images delete \
    --project=jlucktay-factorio \
    --quiet \
    "$image_name"
done
