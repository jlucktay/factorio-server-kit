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
  "gs://${CLOUDSDK_CORE_PROJECT:?}-storage/lib/"
)

echo -n "Copying files to Cloud Storage with arguments: "
echo "${gsutil_args[@]}"
gsutil "${gsutil_args[@]}"

# Submit build and block (not async)
substitutions=(
  "_IMAGE_FAMILY=${FACTORIO_IMAGE_FAMILY:?}"
  "_IMAGE_NAME=${FACTORIO_IMAGE_NAME:?}"
  "_IMAGE_ZONE=${CLOUDSDK_COMPUTE_ZONE:?}"
)

gcloud_build_args=(
  builds
  submit
  --config "$script_dir/cloudbuild.yaml"
  --substitutions "$(factorio::util::join_by , "${substitutions[@]}")"
  "$script_dir"
)

echo -n "Submitting synchronous Cloud Build with arguments: "
echo "${gcloud_build_args[@]}"
if ! gcloud "${gcloud_build_args[@]}"; then
  # If the build fails, clean up any instances created
  factorio::vm::delete_instances "packer-*"
  exit 1
fi

# Clean up old image(s); all but most recent
gcloud_image_list_args=(
  --format json
  compute
  images
  list
  --filter "family:$FACTORIO_IMAGE_FAMILY"
  --sort-by ~creationTimestamp
)

echo -n "Listing images with arguments: "
echo "${gcloud_image_list_args[@]}"
images=$(gcloud "${gcloud_image_list_args[@]}")
for_loop_limit=$(jq length <<< "$images")

# 'i' starts from 1 to preserve the first/newest image
for ((i = 1; i < for_loop_limit; i += 1)); do
  image_name=$(jq --raw-output ".[$i].name" <<< "$images")

  gcloud_image_delete_args=(
    compute
    images
    delete
    --quiet
    "$image_name"
  )

  echo -n "Pruning old image with arguments: "
  echo "${gcloud_image_delete_args[@]}"
  gcloud "${gcloud_image_delete_args[@]}"
done
