#!/usr/bin/env bash
set -euo pipefail
shopt -s globstar nullglob
IFS=$'\n\t'

readonly FACTORIO_ROOT="$(git rev-parse --show-toplevel)"

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && pwd)"

# Push lib JSON to Storage
gsutil_args=(
  -m
  cp
  -P
  "$FACTORIO_ROOT/lib/locations.json"
  "$FACTORIO_ROOT/lib/secrets.json"
  gs://jlucktay-factorio-storage/lib/
)

gsutil "${gsutil_args[@]}"

# Submit build and block (not async)
substitutions=(
  "_IMAGE_FAMILY=$FACTORIO_IMAGE_FAMILY"
  "_IMAGE_NAME=$FACTORIO_IMAGE_NAME"
  "_IMAGE_ZONE=$FACTORIO_IMAGE_ZONE"
)

gcloud_args=(
  builds
  submit
  "--config=$script_dir/cloudbuild.yaml"
  "--substitutions=$(factorio::join_by , "${substitutions[@]}")"
  "$script_dir"
)

# If the build fails, clean up any instances created
if ! gcloud "${gcloud_args[@]}"; then
  factorio::vm::delete_instances "packer-*"
  exit 1
fi

# Clean up old image(s); all but most recent
gcloud_args=(
  "--format=json"
  compute
  images
  list
  "--filter=family:$FACTORIO_IMAGE_FAMILY"
  '--sort-by=~creationTimestamp'
)

images=$(gcloud "${gcloud_args[@]}")
for_loop_limit=$(jq length <<< "$images")

# 'i' starts from 1 to preserve the first/newest image
for ((i = 1; i < for_loop_limit; i += 1)); do
  image_name=$(jq --raw-output ".[$i].name" <<< "$images")

  echo "Pruning old image '$image_name'..."
  gcloud \
    compute \
    images \
    delete \
    --quiet \
    "$image_name"
done
