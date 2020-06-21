#!/usr/bin/env bash

bucket=${CLOUDSDK_CORE_PROJECT:?}-storage

for f in config/*.json; do
  echo "f: $f"
  diff "$f" <(gsutil cat gs://"$bucket"/"$f")
done

for f in lib/*.json; do
  echo "f: $f"
  diff "$f" <(gsutil cat gs://"$bucket"/"$f")
done
