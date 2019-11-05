# Factorio Workbench

Running our own Factorio server.

## Notes

### Create VM

- create instance (see [latest template])
  - [startup](startup.sh) and [shutdown](shutdown.sh) scripts should be set(/overriden from template) as custom
  metadata
    - `--metadata-from-file startup-script=startup.sh,shutdown-script=shutdown.sh`
  - `factorio` and `ssh` network tags are part of the template, for firewall rules
- OPTIONAL
  - set `--preemptible` flag
    - also need to set appropriate maintenance policy
      - `--maintenance-policy=TERMINATE`
  - set VM size with `--machine-type=<NAME>`
    - look up available sizes with `gcloud compute machine-types list --zones=us-west2-b --sort-by=CPUS`
    - e.g. `--machine-type=n1-standard-2`

``` shell
gcloud compute instances create factorio-$(gdate '+%Y%m%d-%H%M%S') \
    --metadata-from-file startup-script=startup.sh,shutdown-script=shutdown.sh \
    --source-instance-template=factorio-container-10
```

``` shell
gcloud compute instances create factorio-$(gdate '+%Y%m%d-%H%M%S') \
    --maintenance-policy=TERMINATE \
    --metadata-from-file startup-script=startup.sh,shutdown-script=shutdown.sh \
    --preemptible \
    --source-instance-template=factorio-container-10
```

``` text
To "disable" RCON don't expose port 27015, i.e. start the server without -p 27015:27015/tcp.
RCON is still running, but nobody can to connect to it.
```

### Startup script

- ~~set up Fuse to mount GCS bucket~~
- get Factorio config/server settings from bucket
- start up Docker container

### Map (generation) settings

The two settings files `map-settings.json` and `map-gen-settings.json` can be created from a map exchange string in the
game as outlined
[here](https://wiki.factorio.com/Command_line_parameters#Creating_the_JSON_files_from_a_map_exchange_string).

### Removed from scripts to save for later

#### Configure Factorio service in systemd

``` shell
cp /opt/factorio-init/factorio.service.example /etc/systemd/system/factorio.service
systemctl daemon-reload
systemctl enable factorio
systemctl status --full factorio >> /root/startup-script.log
```

#### [cloud-init](https://cloudinit.readthedocs.io/en/latest/topics/examples.html#reboot-poweroff-when-finished)

``` shell
reboot
```

[latest template]: https://console.cloud.google.com/compute/instanceTemplates/details/factorio-container-10?project=jlucktay-factorio
