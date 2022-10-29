# TODO

## 2020-11-12

- look into `tcp_syncookies`/possible SYN flooding log message
  - <https://stackoverflow.com/questions/4174688/what-does-possible-syn-flooding-on-port-8009-sending-cookies-mean-in-var-log>
- tee errors to stdout/log file as well as the GCP logger

## 2020-11-05

- see about turning off unattended-upgrade when preemptible server runs up
- bin Ubuntu for Debian

## 2021-01-19

- figure out container volume settings: <https://docs.docker.com/compose/compose-file/compose-file-v3/>
- troubleshoot Prometheus
  - <https://prometheus.io/docs/prometheus/latest/installation/#using-docker>
  - <https://prometheus.io/docs/guides/cadvisor/>
  - make sure Prometheus is running as the `nobody` user per the
    [Dockerfile](https://github.com/prometheus/prometheus/blob/b7fe028740b7b36a31c2deda1e2b74aa566fc0ee/Dockerfile#L21)

## Finish documenting/testing/implementing the _New Project Bootstrap_ journey

## Ship GCE `goppuku` log out to BigQuery/Spanner/whatever

Run some basic analysis of /played.

## Make a dashboard for science pack production in Grafana

WIP; see:

- [my notes on Notion](https://www.notion.so/jlucktay/The-Factory-Must-Grow-86efaae54e1a4a06930ee1e62e92d30d)
  - Graftorio addon building/troubleshooting guide:
    1. consider setting [this flag](https://www.packer.io/docs/commands/build#on-error-cleanup)
    1. `export CLOUDSDK` before running any other scripts
    1. For both Docker (Factorio) & Docker Compose (Graftorio) use `yq` to set `restart=no`

        ```shell
        yq eval --inplace '(.services.*.restart = "no") | (.services.*.restart style="double")' ./docker-compose.yml
        ```

- [grafana.json](./grafana.json)
- [scripts/grafana-setup.sh](./scripts/grafana-setup.sh)
- [This thread](https://community.grafana.com/t/how-create-dashboard-and-panel-via-api/10947)
- [And this video](https://www.youtube.com/watch?v=sKNZMtoSHN4)

## Try out AWS z1d EC2 (4.0 GHz)

Factorio leans quite heavily on a single thread.
_Some_ calculations can be handled on a second thread, but single-highest core speed is key, and Google Cloud instances
top out at around 3.2~3.6 GHz.

## Write a proper service definition for `goppuku`

- [systemd Services](https://wiki.debian.org/systemd/Services)
- [Writing a systemd Service in Python](https://github.com/torfsen/python-systemd-tutorial)
- [Use systemd to Start a Linux Service at Boot](https://www.linode.com/docs/quick-answers/linux/start-service-at-boot/)
- [How to configure systemd to start a service automatically after a crash in Linux](https://www.2daygeek.com/linux-systemd-auto-restart-services-when-down/)

### `systemctl`/`systemd` is preferred over `init`/`init.d` and `SysVInit`

- <https://askubuntu.com/questions/911525/difference-between-systemctl-init-d-and-service>

## Wire all of the logs up to Stackdriver [including Docker][1]

Further reading:

- [Google Cloud Logging driver](https://docs.docker.com/config/containers/logging/gcplogs/)
- [Docker Logging](https://www.fluentd.org/guides/recipes/docker-logging)
- [About the Logging agent](https://cloud.google.com/logging/docs/agent/)

## Make DNS change in roll-vm.sh optional

Not every user will have purchased a domain to use in such a way.

## Make mod management more dynamic

Currently hard-coded to Graftorio and that's about it.
[This](https://github.com/mroote/factorio-server-manager) looks pretty good!

- Move from `afex/graftorio` to <https://github.com/TheVirtualCrew/graftorio>

## Define VM service account with Terraform

`factorio-server@${PROJECT_ID}.iam.gserviceaccount.com` won't exist by default in a new GCP project.

## Los Angeles DC doesn't have N2 machine type, but it does have E2

## Only update DNS if old vs new IP has changed

## Leverage Spot VMs on Google Cloud

- <https://cloud.google.com/compute/docs/instances/spot>

[1]: https://cloud.google.com/community/tutorials/docker-gcplogs-driver
