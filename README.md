# Factorio Workbench

Running our own Factorio server.

## Notes

### Create VM

- create instance (see [latest template])
  - [bootstrap script](bootstrap.sh) is set as custom metadata
  - `factorio` and `ssh` network tags are part of the template

``` shell
gcloud compute instances create factorio-$(gdate '+%Y%m%d-%H%M%S') \
    --source-instance-template=factorio-container-8
```

``` text
To "disable" RCON don't expose port 27015, i.e. start the server without -p 27015:27015/tcp.
RCON is still running, but nobody can to connect to it.
```

### Bootstrap/user data

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

[latest template]: https://console.cloud.google.com/compute/instanceTemplates/details/factorio-container-8?project=jlucktay-factorio
