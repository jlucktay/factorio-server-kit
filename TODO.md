# TODO

## add htop config to baked image

- .config/htop/htoprc
- look at [GCE account service/daemon](https://github.com/GoogleCloudPlatform/compute-image-packages)
  - see if there is a default /etc/something/ directory that serves as a template for new home directories

## ship GCE gopukku log out to BigQuery/Spanner/whatever

- run some basic analysis of /played

## make a dashboard for science pack production in Grafana

- WIP: see:
  - `grafana.json`
  - `scripts/grafana-setup.sh`
  - [this](https://community.grafana.com/t/how-create-dashboard-and-panel-via-api/10947)
  - [and this](https://www.youtube.com/watch?v=sKNZMtoSHN4)

## try out AWS z1d EC2 (4.0 GHz)

## write a proper service definition for gopukku

- [systemd Services](https://wiki.debian.org/systemd/Services)
- [Writing a systemd Service in Python](https://github.com/torfsen/python-systemd-tutorial)
- [Use systemd to Start a Linux Service at Boot](https://www.linode.com/docs/quick-answers/linux/start-service-at-boot/)
- [How to configure systemd to start a service automatically after a crash in Linux](https://www.2daygeek.com/linux-systemd-auto-restart-services-when-down/)

## Wire all of the logs up to Stackdriver [including Docker][1]

- Further reading:
  - [Google Cloud Logging driver](https://docs.docker.com/config/containers/logging/gcplogs/)
  - [Docker Logging](https://www.fluentd.org/guides/recipes/docker-logging)
  - [About the Logging agent](https://cloud.google.com/logging/docs/agent/)

[1]: https://cloud.google.com/community/tutorials/docker-gcplogs-driver
