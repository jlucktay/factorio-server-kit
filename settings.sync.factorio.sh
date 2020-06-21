#!/usr/bin/env bash

bucket=${CLOUDSDK_CORE_PROJECT:?}-storage

gsutil -m rsync -n -x ".*\.sh$|.*\.gitignore$" ./lib/ gs://"$bucket"/lib/
