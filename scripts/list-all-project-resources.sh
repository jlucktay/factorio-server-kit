#!/usr/bin/env bash
set -euo pipefail
shopt -s globstar nullglob
IFS=$'\n\t'

script_dir="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && pwd)"
FACTORIO_ROOT=$(realpath --canonicalize-existing "$script_dir/..")

for lib in "$FACTORIO_ROOT"/lib/*.sh; do
  # shellcheck disable=SC1090
  source "$lib"
done

gcloud alpha resources list \
  --filter="jlucktay-factorio" \
  --uri \
  | grep --extended-regexp --invert-match "\/subnetworks\/default$" \
  | sort --ignore-case

#
# VSCode support for Terraform 0.12 is available and experimental:
# https://github.com/mauve/vscode-terraform/issues/157
#

# https://www.terraform.io/docs/providers/google/r/cloudfunctions_function.html
# -> gcloud --format=json functions describe cleanup-instances | jq
#
# https://www.terraform.io/docs/providers/google/r/cloud_scheduler_job.html
# -> gcloud --format=json scheduler jobs describe cleanup-instances | jq
#
# https://www.terraform.io/docs/providers/google/r/pubsub_topic.html
# -> gcloud --format=json pubsub topics describe cleanup-instances | jq
#
# https://www.terraform.io/docs/providers/google/r/storage_bucket.html
# -> gsutil ls -p jlucktay-factorio
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
#
# https://www.terraform.io/docs/providers/google/d/datasource_google_netblock_ip_ranges.html
# https://cloud.google.com/compute/docs/faq#find_ip_range
