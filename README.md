# multi-mqtt-docker-compose

Run multiple independent [Eclipse Mosquitto](https://mosquitto.org/) MQTT brokers via Docker Compose, each isolated on its own port with its own credentials.

## How it works

Each broker runs the official `eclipse-mosquitto` image with a custom entrypoint that generates `mosquitto.conf` at startup from environment variables — no config files to manage manually. Each service in `docker-compose.yml` is a fully independent broker instance.

## Quick start

```sh
# Start all brokers
docker compose up -d

# Stop all brokers
docker compose down

# View logs for a specific broker
docker compose logs -f broker-tls
```

## Example services

Each service in `docker-compose.yml` is an independent broker — rename, adjust ports, or add more to fit your setup.

| Service     | Host port | Protocol | Username    |
|-------------|-----------|----------|-------------|
| chirpstack1 | 1883      | MQTT     | chirpstack1 |
| chirpstack2 | 1884      | MQTT     | chirpstack2 |
| analyzer    | 1885      | MQTT     | analyzer    |
| ingest      | 1886      | MQTT     | ingest      |
| multiplexer | 1887      | MQTT     | multiplexer |
| broker-tls  | 8883      | MQTTS    | broker-tls  |

## Configuration

Before deploying, edit `docker-compose.yml` and replace every `changeme` password with a real value.

Each service is configured entirely via environment variables:

| Variable               | Default | Description                                        |
|------------------------|---------|----------------------------------------------------|
| `MQTT_USERNAME`        | —       | Username for authentication                        |
| `MQTT_PASSWORD`        | —       | Password for authentication                        |
| `MQTT_ALLOW_ANONYMOUS` | false   | Allow unauthenticated connections                  |
| `MQTT_PERSISTENCE`     | false   | Enable message persistence to disk                 |
| `MQTT_PORT`            | 1883    | Listener port inside the container                 |
| `MQTT_TLS_ENABLED`     | false   | Enable TLS (MQTTS)                                 |
| `MQTT_CAFILE`          | —       | Path to CA chain file (TLS only)                   |
| `MQTT_CERTFILE`        | —       | Path to full-chain certificate file (TLS only)     |
| `MQTT_KEYFILE`         | —       | Path to private key file (TLS only)                |

## TLS (MQTTS)

The `broker-tls` service listens on port 8883 with TLS enabled. It expects certificate files in `./certs/`:

```
certs/
  chain.pem
  fullchain.pem
  privkey.pem
```

### renew-cert.sh

`renew-cert.sh` keeps the broker's certificate up to date. It:

1. Finds the valid certbot-managed certificate for your domain
2. Copies `chain.pem`, `fullchain.pem`, and `privkey.pem` into `DEST` (the host path mounted as `./certs/`)
3. Restarts the `tls` container so it loads the new certificate

Edit `DOMAIN` and `DEST` at the top of the script before using it, then run:

```sh
./renew-cert.sh
```

### Automating with cron

certbot renews certificates automatically but does not restart the broker. Schedule `renew-cert.sh` weekly so the container always picks up a fresh cert:

```sh
crontab -e
```

Add this line (runs every Monday at 03:00):

```
0 3 * * 1 /path/to/multi-mqtt-docker-compose/renew-cert.sh
```

The script is safe to run even when the certificate has not changed — it just copies and restarts, which confirms the broker is using the current cert.
