#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob globstar
IFS=$'\n\t'

packer build -timestamp-ui ./packer/googlecompute.json
