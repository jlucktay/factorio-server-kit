# TODO

## 2020-11-12

- look into `tcp_syncookies`/possible SYN flooding log message
  - <https://stackoverflow.com/questions/4174688/what-does-possible-syn-flooding-on-port-8009-sending-cookies-mean-in-var-log>
- tee errors to stdout/log file as well as the GCP logger

## 2020-11-05

- see about turning off unattended-upgrade when preemptible server runs up
- bin Ubuntu for Debian

## Finish documenting/testing/implementing the _New Project Bootstrap_ journey

## Add `htop` config to baked image

- `.config/htop/htoprc`
- Look at [GCE account service/daemon](https://github.com/GoogleCloudPlatform/compute-image-packages)
  - See if there is a default `/etc/something/` directory that serves as a template for new home directories

## Ship GCE `goppuku` log out to BigQuery/Spanner/whatever

Run some basic analysis of /played.

## Make a dashboard for science pack production in Grafana

WIP; see:

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

[1]: https://cloud.google.com/community/tutorials/docker-gcplogs-driver
