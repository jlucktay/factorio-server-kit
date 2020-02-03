# Welcome to Factorio Workbench 👋

[![License: The Unlicense](https://img.shields.io/badge/License-The%20Unlicense-yellow.svg)][1]
[![Twitter: jlucktay](https://img.shields.io/twitter/follow/jlucktay.svg?style=social)][2]
[![Wakatime tracker](https://wakatime.com/badge/github/jlucktay/factorio-workbench.svg)][3]

> Running your own Factorio server on Google Cloud

Much like the game itself, this project aims to automate as much as possible, when it comes to running your own
Factorio server.

The scripts are based around the use of [preemptible VMs] which keeps running costs low.

## Installation

### Once-off (/infrequently recurring)

1. Run the Cloud Build pipelines in order
    1. Packer builder Docker image
    1. Factorio server VM image
1. Run up the Terraform infra (buckets et al)
1. Deploy the Cloud Function to clean up terminated instances
1. Populate the configuration files with your settings

### As desired

1. Fire off the `roll-vm.sh` Bash script described below

## Usage

The project is primarily driven by Bash scripts, supported by Cloud Build pipelines and Terraform
infrastructure-as-code.

### Cloud Build pipelines

### Terraform IaC

### Bash scripts

- [roll-vm.sh](scripts/roll-vm.sh) - the main point of execution; will run up a GCE VM in a default (or specific; see
    `--help`) location, hosting Docker containers for the Factorio server itself, as well as Grafana and Prometheus to
    tie into [Graftorio](https://github.com/afex/graftorio)
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

Please make sure to update tests as appropriate.

## Show your support

Give a ⭐️ if this project helped you!

## 📝 License

Copyright © 2020 [James Lucktaylor](https://github.com/jlucktay).

This project is [The Unlicense](https://choosealicense.com/licenses/unlicense/) licensed.

***
_This README was generated with ❤️ by [readme-md-generator](https://github.com/kefranabg/readme-md-generator)_

[1]: https://choosealicense.com/licenses/unlicense/
[2]: https://twitter.com/jlucktay
[3]: https://wakatime.com/badge/github/jlucktay/factorio-workbench
[preemptible VMs]: https://cloud.google.com/compute/docs/instances/preemptible
[machine type]: https://cloud.google.com/compute/docs/machine-types
