#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob globstar
IFS=$'\n\t'

script_dir="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && pwd)"

gcloud --project=jlucktay-factorio builds submit "$script_dir" --config="$script_dir/cloudbuild.yaml"
