#!/usr/bin/env bash
set -euo pipefail

readonly FACTORIO_IMAGE_FAMILY=packtorio
readonly FACTORIO_IMAGE_NAME="${FACTORIO_IMAGE_FAMILY}-$(date +%Y%m%d-%H%M%S)"
readonly FACTORIO_IMAGE_ZONE=australia-southeast1-b
export FACTORIO_IMAGE_FAMILY
export FACTORIO_IMAGE_NAME
export FACTORIO_IMAGE_ZONE

# Ref: https://cloud.google.com/sdk/gcloud/reference/topic/startup
CLOUDSDK_CORE_PROJECT=jlucktay-factorio
export CLOUDSDK_CORE_PROJECT

CLOUDSDK_COMPUTE_REGION=australia-southeast1
export CLOUDSDK_COMPUTE_REGION

CLOUDSDK_COMPUTE_ZONE=australia-southeast1-b
export CLOUDSDK_COMPUTE_ZONE
