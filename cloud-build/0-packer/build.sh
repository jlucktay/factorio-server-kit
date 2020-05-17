#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

readonly FACTORIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && git rev-parse --show-toplevel)"

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && pwd)"

# Submit build and block (not async)
substitutions=(
  "_PACKER_VERSION=$FACTORIO_PACKER_VERSION"
  "_PACKER_VERSION_SHA256SUM=$FACTORIO_PACKER_VERSION_SHA256SUM"
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
gcloud "${gcloud_build_args[@]}"

# Collect untagged digest(s)
base_image=gcr.io/${CLOUDSDK_CORE_PROJECT:?}/packer

gcloud_list_untagged_args=(
  --format json
  container
  images
  list-tags
  --filter "NOT tags:* OR NOT tags:$FACTORIO_PACKER_VERSION"
  "$base_image"
)

echo -n "Listing untagged digests: gcloud "
echo "${gcloud_list_untagged_args[@]}"
digests=$(gcloud "${gcloud_list_untagged_args[@]}")
for_loop_limit=$(jq length <<< "$digests")

# Prepare to delete untagged digest(s)
gcloud_delete_args=(
  container
  images
  delete
  --force-delete-tags
  --quiet
)

pre_loop_count=${#gcloud_delete_args[@]}

for ((i = 0; i < for_loop_limit; i += 1)); do
  digest_hash=$(jq --raw-output ".[$i].digest" <<< "$digests")
  gcloud_delete_args+=("$base_image@$digest_hash")
done

# Only run the delete command if any arguments were added to the array
if [ ${#gcloud_delete_args[@]} -gt "$pre_loop_count" ]; then
  echo -n "Deleting untagged digests: gcloud "
  echo "${gcloud_delete_args[@]}"
  gcloud "${gcloud_delete_args[@]}"
fi
