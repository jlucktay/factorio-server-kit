# Welcome to Factorio Workbench 👋

[![License: The Unlicense](https://img.shields.io/badge/License-The%20Unlicense-yellow.svg)][1]
[![Twitter: jlucktay](https://img.shields.io/twitter/follow/jlucktay.svg?style=social)][2]

> Running our own Factorio server on Google Cloud

Much like the game itself, this project aims to automate as much as possible.

## Usage

The project is primarily driven by Bash scripts, supported by Cloud Build pipelines and Terraform infrastructure-as-code.

### Bash scripts

- [roll-vm.sh](scripts/roll-vm.sh) - the main point of execution; will run up a GCE VM in the given location (see `--help`) with
    Docker containers for the Factorio server itself, as well as Grafana and Prometheus to tie into
    [Graftorio](https://github.com/afex/graftorio)

#### Library

Each of the above scripts taps into a common library of functionality under the [lib](lib/) directory.

### Cloud Build pipelines

### Terraform IaC

## Author

👤 **James Lucktaylor**

- Website: jameslucktaylor.info
- GitHub: [@jlucktay](https://github.com/jlucktay)
- Twitter: [@jlucktay][2]
- LinkedIn: [@jlucktay](https://linkedin.com/in/jlucktay)

## Show your support

Give a ⭐️ if this project helped you!

## 📝 License

Copyright © 2020 [James Lucktaylor](https://github.com/jlucktay).

This project is [The Unlicense](https://choosealicense.com/licenses/unlicense/) licensed.

***
_This README was generated with ❤️ by [readme-md-generator](https://github.com/kefranabg/readme-md-generator)_

[1]: https://choosealicense.com/licenses/unlicense/
[2]: https://twitter.com/jlucktay
