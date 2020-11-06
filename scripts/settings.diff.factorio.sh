#!/usr/bin/env bash
set -euo pipefail

readonly FACTORIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && git rev-parse --show-toplevel)"

bucket=${CLOUDSDK_CORE_PROJECT:?}-storage

for f in "$FACTORIO_ROOT"/config/*.json "$FACTORIO_ROOT"/lib/*.json; do
  stripped_prefix=${f#"$FACTORIO_ROOT/"}

  if ! f_diff=$(
    diff \
      --minimal \
      --side-by-side \
      --suppress-common-lines \
      "$f" \
      <(gsutil cat gs://"$bucket"/"$stripped_prefix")
  ); then
    printf "f: '%s'\n%s\n\n" "$f" "$f_diff"
  else
    echo "'$stripped_prefix' matches"
  fi
done
