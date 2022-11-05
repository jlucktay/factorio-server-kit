#!/usr/bin/env bash
set -euo pipefail

FACTORIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && git rev-parse --show-toplevel)"
readonly FACTORIO_ROOT

bucket=${CLOUDSDK_CORE_PROJECT:?}-storage

for f in "$FACTORIO_ROOT"/{config,mods,lib}/*.json; do
  stripped_prefix=${f#"$FACTORIO_ROOT/"}

  gsutil_output=$(gsutil cat "gs://$bucket/$stripped_prefix")

  if ! f_diff=$(diff --minimal --side-by-side --suppress-common-lines "$f" - <<< "$gsutil_output"); then
    printf "f: '%s'\n%s\n\n" "$f" "$f_diff"
  else
    echo "'$stripped_prefix' matches"
  fi
done
