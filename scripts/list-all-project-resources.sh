#!/usr/bin/env bash
set -euo pipefail

FACTORIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && git rev-parse --show-toplevel)"
readonly FACTORIO_ROOT

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

gcloud alpha resources list \
  --filter="${CLOUDSDK_CORE_PROJECT:?}" \
  --uri \
  | grep --extended-regexp --invert-match "\/subnetworks\/default$" \
  | sort --ignore-case

# https://console.cloud.google.com/cloudscheduler?project=jlucktay-factorio
# runs every 15 minutes to publish to Pub/Sub so that cleanup-instances Cloud Function is triggered
# https://www.terraform.io/docs/providers/google/r/cloud_scheduler_job.html
# -> gcloud --format=json scheduler jobs describe cleanup-instances | jq
#
# https://www.terraform.io/docs/providers/google/r/cloudfunctions_function.html
# -> gcloud --format=json functions describe cleanup-instances | jq
#
# https://www.terraform.io/docs/providers/google/r/storage_bucket.html
# -> gsutil ls -p $CLOUDSDK_CORE_PROJECT
# --> one bucket per location/zone in lib/locations.json
# --> other one-off buckets
#
# https://www.terraform.io/docs/providers/google/r/storage_bucket_object.html
# -> aforementioned locations.json
#
# https://www.terraform.io/docs/providers/google/r/dns_managed_zone.html
# -> gcloud dns managed-zones describe factorio-server
#
# https://www.terraform.io/docs/providers/google/r/dns_record_set.html
# -> gcloud dns record-sets list --zone=factorio-server
#
# Google Cloud resource IP ranges, to e.g. whitelist incoming ssh traffic for the build pipeline
# https://www.terraform.io/docs/providers/google/d/datasource_google_netblock_ip_ranges.html
# https://cloud.google.com/compute/docs/faq#find_ip_range
