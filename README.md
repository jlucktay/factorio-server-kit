# Factorio Workbench

Running our own Factorio server.

## Notes

### Create VM

See the [(re)roll VM script](roll-vm.sh) and related [library](lib/) functions.

#### Optional

- set VM size with `--machine-type=<NAME>`
  - look up available sizes with `gcloud compute machine-types list --zones=us-west2-b --sort-by=CPUS`
  - e.g. `--machine-type=n1-standard-2`

``` text
To "disable" RCON don't expose port 27015, i.e. start the server without -p 27015:27015/tcp.
RCON is still running, but nobody can to connect to it.
```

### Startup script

- ~~set up Fuse to mount GCS bucket~~
- ~~get Factorio config/server settings from bucket~~
- ~~start up Docker container~~

### Map (generation) settings

The two settings files `map-settings.json` and `map-gen-settings.json` can be created from a map exchange string in the
game as outlined
[here](https://wiki.factorio.com/Command_line_parameters#Creating_the_JSON_files_from_a_map_exchange_string).

## Other improvements

- ~~Bake a [proper image](https://cloud.google.com/compute/docs/images) for the server, rather than bootstrap
  everything every time~~
- Add more signals to `trap` call in `startup.sh`?
  - `$ bat /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include/sys/signal.h`
- Wire all of the logs up to Stackdriver [including Docker][1]
  - Further reading:
    - [Google Cloud Logging driver](https://docs.docker.com/config/containers/logging/gcplogs/)
    - [Docker Logging](https://www.fluentd.org/guides/recipes/docker-logging)
    - [About the Logging agent](https://cloud.google.com/logging/docs/agent/)

[1]: https://cloud.google.com/community/tutorials/docker-gcplogs-driver
