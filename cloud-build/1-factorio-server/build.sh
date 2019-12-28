#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob globstar
IFS=$'\n\t'

script_dir="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && pwd)"
image_name="packtorio-$(date +%Y%m%d-%H%M%S)"

# With thanks to:
# https://stackoverflow.com/questions/1527049/how-can-i-join-elements-of-an-array-in-bash
function join_by() {
  local d=$1
  shift
  echo -n "$1"
  shift
  printf "%s" "${@/#/$d}"
}

substitutions=(
  "_IMAGE_FAMILY=packtorio"
  "_IMAGE_NAME=$image_name"
  "_IMAGE_ZONE=australia-southeast1-b"
)

gcloud --project=jlucktay-factorio \
  builds \
  submit \
  --config="$script_dir/cloudbuild.yaml" \
  --substitutions="$(join_by , "${substitutions[@]}")" \
  "$script_dir"

# Clean up old image(s); all but most recent
gcloud_args=(
  "--format=json"
  "--project=jlucktay-factorio"
  compute
  images
  list
  "--filter=family:$FACTORIO_IMAGE_FAMILY"
  '--sort-by=~creationTimestamp'
)

images=$(gcloud "${gcloud_args[@]}")

# 'i' starts from 1 to preserve the first/newest image
for ((i = 1; i < $(jq length <<< "$images"); i += 1)); do
  image_name=$(jq --raw-output ".[$i].name" <<< "$images")

  echo "Pruning old image '$image_name'..."
  gcloud \
    --project=jlucktay-factorio \
    compute \
    images \
    delete \
    --quiet \
    "$image_name"
done
