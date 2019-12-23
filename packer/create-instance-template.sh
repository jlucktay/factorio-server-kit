#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob globstar
IFS=$'\n\t'

script_dir="$(cd "$(dirname "${BASH_SOURCE[-1]}")" &> /dev/null && pwd)"

### Build arguments list for gcloud
gcloud_args=(
  compute
  instance-templates
  create
  "--boot-disk-device-name=packtorio-1"
  "--boot-disk-size=10GB"
  "--boot-disk-type=pd-standard"
  "--description=https://github.com/jlucktay/factorio-workbench"
  "--format=json"
  "--image-project=jlucktay-factorio"
  "--image=$IMAGE_NAME"
  "--machine-type=n2-standard-2"
  "--maintenance-policy=TERMINATE"
  "--metadata-from-file=startup-script=$script_dir/startup.sh,shutdown-script=$script_dir/shutdown.sh"
  "--network-tier=PREMIUM"
  "--network=projects/jlucktay-factorio/global/networks/default"
  "--no-restart-on-failure"
  "--preemptible"
  "--project=jlucktay-factorio"
  "--reservation-affinity=any"
  "--scopes=https://www.googleapis.com/auth/cloud-platform"
  "--service-account=factorio-server@jlucktay-factorio.iam.gserviceaccount.com"
  "--tags=factorio,grafana,ssh"
  "$IMAGE_NAME"
)

### Show arguments and execute with them
echo "Running 'gcloud' with following arguments:"
echo "${gcloud_args[@]}"

gcloud "${gcloud_args[@]}"
