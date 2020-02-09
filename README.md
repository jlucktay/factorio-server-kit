# Welcome to Factorio Workbench 👋

[![License: The Unlicense](https://img.shields.io/badge/License-The%20Unlicense-yellow.svg)][1]
[![Twitter: jlucktay](https://img.shields.io/twitter/follow/jlucktay.svg?style=social)][2]
[![Wakatime tracker](https://wakatime.com/badge/github/jlucktay/factorio-workbench.svg)][3]

> Running your own Factorio server on Google Cloud

Much like the game itself, this project aims to automate as much as possible, when it comes to running your own
Factorio server.

The scripts are based around the use of [preemptible VMs] which keeps running costs low.

## Installation

### Initial setup

1. Populate the configuration files with your settings
1. Create the `<project>-tfstate` Terraform state bucket in Storage
1. Run up the Terraform stack to provision infrastructure in GCP (implemented? -> ❌/✅)
    1. Cloud Pub/Sub topic `cleanup-instances` ❌
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

- [roll-vm.sh](scripts/roll-vm.sh) - the main point of execution; will run up a GCE VM hosting Docker containers for
    the Factorio server itself, as well as additional containers with Grafana and Prometheus that tie into [Graftorio]
  - the location/region that the VM will deploy to follows a default based on the [`locations.json` file], and can be
        overridden with a `--<location>` flag; see `roll-vm.sh --help` for more information
  - the [machine type] of the VM can be specified with the `--machine-type=...` flag
- [delete-vm.sh](scripts/delete-vm.sh) - deletes any VMs currently running in the project, optionally filtering by name

#### Library

Each of the above scripts taps into a common library of functionality under the [lib](lib/) directory.

### Other notes

### Map (re)generation settings

The two settings files `map-settings.json` and `map-gen-settings.json` can be created from a map exchange string in the
game as outlined
[here](https://wiki.factorio.com/Command_line_parameters#Creating_the_JSON_files_from_a_map_exchange_string).

## Upstream issues outstanding

- [Graftorio support for Factorio 0.18.x](https://github.com/afex/graftorio/pull/15)

## Related projects

### `gopukku`

[`gopukku`](https://github.com/jlucktay/gopukku) is a small Go binary/service I built to have a server shut itself down
if the player count stays at zero for fifteen consecutive minutes.

The latest release of `gopukku` is installed in the Factorio server image by
[Packer's provisioner script](cloud-build/1-factorio-server/provisioner.sh).

## Author

👤 **James Lucktaylor**

- Website: jameslucktaylor.info
- GitHub: [@jlucktay](https://github.com/jlucktay)
- Twitter: [@jlucktay][2]
- LinkedIn: [@jlucktay](https://linkedin.com/in/jlucktay)

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update documentation and tests as appropriate.

## Show your support

Give a ⭐️ if this project helped you!

## 📝 License

Copyright © 2020 [James Lucktaylor](https://github.com/jlucktay).

This project is [The Unlicense](https://choosealicense.com/licenses/unlicense/) licensed.

***
_This README was generated with ❤️ by [readme-md-generator](https://github.com/kefranabg/readme-md-generator)_

[`locations.json` file]: lib/locations.json
[1]: https://choosealicense.com/licenses/unlicense/
[2]: https://twitter.com/jlucktay
[3]: https://wakatime.com/badge/github/jlucktay/factorio-workbench
[Factorio server VM image]: cloud-build/1-factorio-server/README.md
[Graftorio]: https://github.com/afex/graftorio
[machine type]: https://cloud.google.com/compute/docs/machine-types
[Packer builder Docker image]: cloud-build/0-packer/README.md
[preemptible VMs]: https://cloud.google.com/compute/docs/instances/preemptible
