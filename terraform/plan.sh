#!/usr/bin/env bash
set -euo pipefail

readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && pwd)"
readonly FACTORIO_ROOT="$(git -C "$script_dir" rev-parse --show-toplevel)"

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

# shellcheck disable=SC2154
export TF_VAR_project_id="$CLOUDSDK_CORE_PROJECT"

cd "$script_dir"
terraform plan
