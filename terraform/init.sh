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

bucket_suffix="-tfstate"
bucket_name="gs://${CLOUDSDK_CORE_PROJECT:?}$bucket_suffix"

gsutil_args=(
  mb
  -c standard
  -l EU
  -b off
  "$bucket_name"
)

echo -n "Making sure Cloud Storage bucket '$bucket_name' for Terraform state exists, with arguments: "
echo "${gsutil_args[@]}"
gsutil "${gsutil_args[@]}" &> /dev/null || true

# shellcheck disable=SC2154
export TF_CLI_ARGS_init="-backend-config=\"bucket=$CLOUDSDK_CORE_PROJECT$bucket_suffix\""

cd "$script_dir"
terraform init
