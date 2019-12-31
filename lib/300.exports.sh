#!/usr/bin/env bash
set -euo pipefail

declare -rx FACTORIO_IMAGE_FAMILY=packtorio
declare -rx FACTORIO_IMAGE_ZONE=australia-southeast1-b

FACTORIO_IMAGE_NAME="${FACTORIO_IMAGE_FAMILY}-$(TZ=UTC date +%Y%m%d-%H%M%S)"
readonly FACTORIO_IMAGE_NAME
export FACTORIO_IMAGE_NAME

# Ref: https://cloud.google.com/sdk/gcloud/reference/topic/startup
declare -rx CLOUDSDK_CORE_PROJECT=jlucktay-factorio
declare -rx CLOUDSDK_COMPUTE_REGION=${FACTORIO_IMAGE_ZONE:0:-2}
declare -rx CLOUDSDK_COMPUTE_ZONE=$FACTORIO_IMAGE_ZONE
