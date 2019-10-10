# Factorio Workbench

Running our own Factorio server.

## Notes

### Create VM

- create instance (see latest template) with 'factorio' and 'ssh' network tags
- use bootstrap script (gs/jlucktay-factorio-asia/factorio.sh)

``` text
To "disable" RCON don't expose port 27015, i.e. start the server without -p 27015:27015/tcp.
RCON is still running, but nobody can to connect to it.
```

### Bootstrap/user data

- set up Fuse to mount GCS bucket
- get Factorio config/server settings from bucket
- start up Docker container

### Removed from scripts to save for later

#### Pull scripts from GitHub

``` shell
git clone https://github.com/Bisa/factorio-init.git /opt/factorio-init
git clone https://github.com/narc0tiq/factorio-updater.git /opt/factorio-updater
```

#### Configure 'factorio-init' and install Factorio

``` shell
cp /opt/factorio-init/config.example /opt/factorio-init/config
sed --expression "s/UPDATE_SCRIPT=\/path\/to\/update_factorio.py/UPDATE_SCRIPT=\/opt\/factorio-updater\/update_factorio.py/g" --in-place /opt/factorio-init/config
/opt/factorio-init/factorio install
```

#### Get the server config from Storage

``` shell
gsutil cp gs://jlucktay-factorio-asia/server-settings.json /opt/factorio/data
```

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
