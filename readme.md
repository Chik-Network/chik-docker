# Official Chik Docker Container

## Quick Start

These examples shows valid setups using Chik for both docker run and docker-compose. Note that you should read some documentation at some point, but this is a good place to start.

### Docker run
Simple example:
```bash
docker run --name chik --expose=8444 -v /path/to/plots:/plots -d ghcr.io/chik-network/chik:latest
```
Syntax
```bash
docker run [--name <container-name>] [--expose=<port>] [-v </path/to/plots:/plots>] -d ghcr.io/chik-network/chik:latest
```
Optional Docker parameters:
- Give the container a name: `--name=chik`
- Accept incoming connections: `--expose=8444`
- Volume mount plots: `-v /path/to/plots:/plots`


### Docker compose

```yaml
version: "3.6"
services:
  chik:
    container_name: chik
    restart: unless-stopped
    image: ghcr.io/chik-network/chik:latest
    ports:
      - 8444:8444
    volumes:
      - /path/to/plots:/plots
```

## Configuration

You can modify the behavior of your Chik container by setting specific environment variables.

### Timezone

Set the timezone for the container (optional, defaults to UTC).
Timezones can be configured using the `TZ` env variable. A list of supported time zones can be found [here](http://manpages.ubuntu.com/manpages/focal/man3/DateTime::TimeZone::Catalog.3pm.html)
```bash
-e TZ="America/Chicago"
```

### Add your custom keys

To use your own keys pass a file with your mnemonic as arguments on startup
```bash
-v /path/to/key/file:/path/in/container -e keys="/path/in/container"
```
or pass keys into the running container with your mnemonic
```bash
docker exec -it <container-name> venv/bin/chik keys add
```
alternatively you can pass in your local keychain, if you have previously deployed chik with these keys on the host machine
```bash
-v ~/.local/share/python_keyring/:/root/.local/share/python_keyring/
```
or if you would like to persist the entire mainnet subdirectory and not touch the key directories at all
```bash
-v ~/.chik/mainnet:/root/.chik/mainnet -e keys="persistent"
```


### Persist configuration, db, and keyring

You can persist whole db and configuration, simply mount it to Host.
```bash
-v ~/.chik:/root/.chik \
-v ~/.chik_keys:/root/.chik_keys
```

### Farmer only

To start a farmer only node pass
```bash
-e service="farmer-only"
```

### Harvester only

To start a harvester only node pass
```bash
-e service="harvester" -e farmer_address="addres.of.farmer" -e farmer_port="portnumber" -v /path/to/ssl/ca:/path/in/container -e ca="/path/in/container" -e keys="none"
```

### Configure full_node peer

To set the full_node peer's hostname and port, set the "full_node_peer" environment variable with the format `hostname:port`
```bash
-e full_node_peer="node:8444"
```
This will configure the full_node peer hostname and port for the wallet, farmer, and timelord sections of the config.yaml file.

### Plots

The `plots_dir` environment variable can be used to specify the directory containing the plots, it supports PATH-style colon-separated directories.

Or, you can simply mount `/plots` path to your host machine.

Set the environment variable `recursive_plot_scan` to `true` to enable the recursive plot scan configuration option.

### Log level
To set the log level to one of CRITICAL, ERROR, WARNING, INFO, DEBUG, NOTSET
```bash
-e log_level="DEBUG"
```

### Peer Count
To set the peer_count and outbound_peer_count

for example to set both to 20 use
```bash
-e peer_count="20"
```

```bash
-e outbound_peer_count="20"
```

### UPnP
To disable UPnP support (enabled by default)
```bash
-e upnp="false"
```

### Log to file
Log file can be used by external tools like chikdog, etc. Enabled by default.

To disable log file generation, use
```bash
-e log_to_file="false"
```

### Docker Compose

```yaml
version: "3.6"
services:
  chik:
    container_name: chik
    restart: unless-stopped
    image: ghcr.io/chik-network/chik:latest
    ports:
      - 8444:8444
    environment:
      # Farmer Only
#     service: farmer-only
      # Harvester Only
#     service: harvester
#     farmer_address: 192.168.0.10
#     farmer_port: 8447
#     ca: /path/in/container
#     keys: generate
      # Harvester Only END
      # If you would like to add keys manually via mnemonic file
#     keys: /path/in/container
      # OR
      # Disable key generation on start
#     keys: 
      TZ: ${TZ}
      # Enable UPnP
#     upnp: true
      # Enable log file generation
#     log_to_file: true
    volumes:
      - /path/to/plots:/plots
      - /home/user/.chik:/root/.chik
#     - /home/user/mnemonic:/path/in/container
```

## CLI

You can run commands externally with venv (this works for most chik [CLI commands](https://github.com/Chik-Network/chik-blockchain/wiki/CLI-Commands-Reference))
```bash
docker exec -it chik venv/bin/chik plots add -d /plots
```

### Is it working?

You can see status from outside the container
```bash
docker exec -it chik venv/bin/chik show -s -c
```
or
```bash
docker exec -it chik venv/bin/chik farm summary
```

### Connect to testnet?

```bash
docker run -d --expose=58444 -e testnet=true --name chik ghcr.io/chik-network/chik:latest
```

#### Need a wallet?

To get new wallet, execute command and follow the prompts:

```bash
docker exec -it chik-farmer1 venv/bin/chik wallet show
```

## Building

```bash
docker build -t chik --build-arg BRANCH=latest .
```

## Healthchecks

The Dockerfile includes a HEALTHCHECK instruction that runs one or more curl commands against the Chik RPC API. In Docker, this can be disabled using an environment variable `-e healthcheck=false` as part of the `docker run` command. Or in docker-compose you can add it to your Chik service, like so:

```yaml
version: "3.6"
services:
  chik:
    ...
    environment:
      healthcheck: "false"
```

In Kubernetes, Docker healthchecks are disabled by default. Instead, readiness and liveness probes should be used, which can be configured in a Pod or Deployment manifest file like the following:

```yaml
livenessProbe:
  exec:
    command:
    - /bin/sh
    - -c
    - '/usr/local/bin/docker-healthcheck.sh || exit 1'
  initialDelaySeconds: 60
readinessProbe:
  exec:
    command:
    - /bin/sh
    - -c
    - '/usr/local/bin/docker-healthcheck.sh || exit 1'
  initialDelaySeconds: 60
```

See [Configure Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) for more information about configuring readiness and liveness probes for Kubernetes clusters. The `initialDelaySeconds` parameter may need to be adjusted higher or lower depending on the speed to start up on the host the container is running on.
