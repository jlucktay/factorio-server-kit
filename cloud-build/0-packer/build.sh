#!/usr/bin/env bash
set -euo pipefail
shopt -s globstar nullglob
IFS=$'\n\t'

script_dir="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && pwd)"
FACTORIO_ROOT=$(realpath --canonicalize-existing "$script_dir/../..")

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

# Submit build and block (not async)
substitutions=(
  "_PACKER_VERSION=$FACTORIO_PACKER_VERSION"
  "_PACKER_VERSION_SHA256SUM=$FACTORIO_PACKER_VERSION_SHA256SUM"
)

gcloud \
  builds \
  submit \
  --config="$script_dir/cloudbuild.yaml" \
  --substitutions="$(factorio::join_by , "${substitutions[@]}")" \
  "$script_dir"

# Collect untagged digest(s)
base_image=gcr.io/${CLOUDSDK_CORE_PROJECT:?}/packer

gcloud_list_tags_args=(
  "--format=json"
  container
  images
  list-tags
  "$base_image"
  "--filter=NOT tags:*"
)

digests=$(gcloud "${gcloud_list_tags_args[@]}")

# Prepare to delete untagged digest(s)
gcloud_delete_args=(
  container
  images
  delete
  --quiet
)

for ((i = 0; i < "$(jq length <<< "$digests")"; i += 1)); do
  digest_hash=$(jq --raw-output ".[$i].digest" <<< "$digests")
  gcloud_delete_args+=("$base_image@$digest_hash")
done

gcloud "${gcloud_delete_args[@]}"
