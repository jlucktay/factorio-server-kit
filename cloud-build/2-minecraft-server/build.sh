#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

readonly FACTORIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && git rev-parse --show-toplevel)"

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && pwd)"

#

# TODO: Terraform this service account
# https://console.cloud.google.com/cloud-build/settings/service-account
# https://console.cloud.google.com/iam-admin/iam

#

# Submit build and block (not async)
substitutions=(
  "_IMAGE_FAMILY=${MINECRAFT_IMAGE_FAMILY:?}"
  "_IMAGE_NAME=${MINECRAFT_IMAGE_NAME:?}"
  "_IMAGE_ZONE=${CLOUDSDK_COMPUTE_ZONE:?}"
)

gcloud_build_args=(
  builds
  submit
  --config "$script_dir/cloudbuild.yaml"
  --substitutions "$(factorio::util::join_by , "${substitutions[@]}")"
  "$script_dir"
)

echo -n "Submitting synchronous Cloud Build: gcloud "
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
  --filter "family:$MINECRAFT_IMAGE_FAMILY"
  --sort-by ~creationTimestamp
)

echo -n "Listing images: gcloud "
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

  echo -n "Pruning old image: gcloud "
  echo "${gcloud_image_delete_args[@]}"
  gcloud "${gcloud_image_delete_args[@]}"
done
