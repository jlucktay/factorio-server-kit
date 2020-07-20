# Welcome to the Factorio Server Kit 👋

[![License: The Unlicense](https://img.shields.io/badge/License-The%20Unlicense-yellow.svg)][1]
[![Twitter: jlucktay](https://img.shields.io/twitter/follow/jlucktay.svg?style=social)][2]
[![Wakatime tracker](https://wakatime.com/badge/github/jlucktay/factorio-server-kit.svg)][3]

> Running your own Factorio server on Google Cloud

Much like [the game] itself, this project aims to automate as much as possible, when it comes to running your own
Factorio server.

The scripts are based around the use of [preemptible VMs] which keeps running costs low.

## Installation

### Initial setup

1. Make sure the following tools are installed, available in your `$PATH`, and (where necessary) authorised:
    1. [Google Cloud SDK] - [quickstarts][gc-quick]
        1. [Installation][gc-inst]
        1. [Authorisation][gc-auth]
    1. [jq]
        1. [Installation][jq-inst]
    1. [Terraform]
        1. [Installation][tf-inst]
1. Get started on the [GCP Free Tier] and [create a new Google Cloud project][gc-project]
    - **Note: you are responsible for the running costs incurred by this project** beyond the limits of the Free Tier.
      Every effort has been made to optimise and minimise the costs of resource usage, and as of this writing running a
      server for ~50 hours a month cost less than £5 in total, but this is an isolated example from a sample size of 1.
1. Set the `CLOUDSDK_CORE_PROJECT` environment variable to the Google Cloud project ID
    1. For example: `export CLOUDSDK_CORE_PROJECT=my-factorio-server-kit`
1. Run up the Terraform stack to provision infrastructure in GCP (implemented? -> ❌/✅)
    1. Cloud Pub/Sub topic `cleanup-instances` ✅
    1. Cloud Scheduler job `cleanup-instances` to publish to topic ❌
    1. Cloud Function `cleanup-instances` to clean up terminated instances, triggered by topic ✅
    1. Cloud Storage buckets
        1. `<project>-backup-saves` ❌
        1. `<project>-saves-<location>` ✅
        1. `<project>-storage` ❌
    1. Cloud DNS (optional)
        1. Managed zone ❌
        1. Record set ❌
1. Run the Cloud Build pipelines in order
    1. [Packer builder Docker image]
    1. [Factorio server VM image]

### As desired

1. Fire off the `roll-vm.sh` Bash script described below

## Usage

The project is primarily driven by Bash scripts, supported by Cloud Build pipelines and Terraform
infrastructure-as-code.

### Cloud Build pipelines

### Terraform IaC

### Bash scripts

- [roll-vm.sh] - the main point of execution; will run up a GCE VM hosting Docker containers for
    the Factorio server itself, as well as additional containers with Grafana and Prometheus that tie into [Graftorio]
  - the location/region that the VM will deploy to follows a default based on the [`locations.json` file], and can be
        overridden with a `--<location>` flag; see `roll-vm.sh --help` for more information
  - the [machine type] of the VM can be specified with the `--machine-type=...` flag
- [delete-vm.sh] - deletes any VMs currently running in the project, optionally filtering by name

#### Library

Each of the above scripts taps into a common library of functionality under the [lib](lib/) directory.

### Other notes

### Map (re)generation settings

The two settings files `map-settings.json` and `map-gen-settings.json` can be created from a map exchange string in the
game [as outlined here][map-settings].

## Upstream issues outstanding

- [Graftorio support for Factorio 0.18.x](https://github.com/afex/graftorio/pull/15)

## Related projects

### goppuku

[`goppuku`] is a small Go binary/service I built to have a server shut itself down
if the player count stays at zero for fifteen consecutive minutes.

The latest release of `goppuku` is installed in the Factorio server image by
[Packer's provisioner script].

## Author

👤 **James Lucktaylor**

- Website: jameslucktaylor.info
- GitHub: [@jlucktay][4]
- Twitter: [@jlucktay][2]
- LinkedIn: [@jlucktay][linkedin]

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update documentation and tests as appropriate.

## Show your support

Give a ⭐️ if this project helped you!

## 📝 License

Copyright © 2020 [James Lucktaylor][4].

This project is licensed with [the Unlicense].

***
_This README was generated with ❤️ by [readme-md-generator](https://github.com/kefranabg/readme-md-generator)_

[`goppuku`]: https://github.com/jlucktay/goppuku
[`locations.json` file]: lib/locations.json
[1]: https://choosealicense.com/licenses/unlicense/
[2]: https://twitter.com/jlucktay
[3]: https://wakatime.com/badge/github/jlucktay/factorio-server-kit
[4]: https://github.com/jlucktay
[delete-vm.sh]: scripts/delete-vm.sh
[Factorio server VM image]: cloud-build/1-factorio-server/README.md
[gc-auth]: https://cloud.google.com/sdk/docs/authorizing
[gc-inst]: https://cloud.google.com/sdk/install
[gc-project]: https://cloud.google.com/resource-manager/docs/creating-managing-projects
[gc-quick]: https://cloud.google.com/sdk/docs/quickstarts
[GCP Free Tier]: https://cloud.google.com/free/
[Google Cloud SDK]: https://cloud.google.com/sdk
[Graftorio]: https://github.com/afex/graftorio
[jq-inst]: https://github.com/stedolan/jq/wiki/Installation
[jq]: http://stedolan.github.io/jq/
[linkedin]: https://linkedin.com/in/jlucktay
[machine type]: https://cloud.google.com/compute/docs/machine-types
[map-settings]: https://wiki.factorio.com/Command_line_parameters#Creating_the_JSON_files_from_a_map_exchange_string
[Packer builder Docker image]: cloud-build/0-packer/README.md
[Packer's provisioner script]: cloud-build/1-factorio-server/provisioner.sh
[preemptible VMs]: https://cloud.google.com/compute/docs/instances/preemptible
[roll-vm.sh]: scripts/roll-vm.sh
[Terraform]: https://www.terraform.io
[tf-inst]: https://learn.hashicorp.com/terraform/getting-started/install.html
[the game]: https://factorio.com
[the Unlicense]: https://unlicense.org
