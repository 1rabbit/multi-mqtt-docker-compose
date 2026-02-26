#!/bin/sh
# entrypoint.sh — container startup script for eclipse-mosquitto
#
# Generates /mosquitto/config/mosquitto.conf from environment variables,
# optionally creates a password file, then exec's mosquitto.
#
# Environment variables (all optional, defaults shown):
#   MQTT_PORT             - listener port inside the container (default: 1883)
#   MQTT_ALLOW_ANONYMOUS  - allow unauthenticated connections (default: false)
#   MQTT_PERSISTENCE      - enable message persistence to disk (default: false)
#   MQTT_TLS_ENABLED      - enable TLS listener (default: false)
#   MQTT_CAFILE           - path to CA chain file (required when TLS enabled)
#   MQTT_CERTFILE         - path to full-chain certificate (required when TLS enabled)
#   MQTT_KEYFILE          - path to private key (required when TLS enabled)
#   MQTT_USERNAME         - username for single-user auth (optional)
#   MQTT_PASSWORD         - password for single-user auth (optional)
#
# When MQTT_USERNAME and MQTT_PASSWORD are both set, a password file is
# created via mosquitto_passwd and authentication is enforced.
set -e

MQTT_PORT="${MQTT_PORT:-1883}"
MQTT_ALLOW_ANONYMOUS="${MQTT_ALLOW_ANONYMOUS:-false}"
MQTT_PERSISTENCE="${MQTT_PERSISTENCE:-false}"
MQTT_TLS_ENABLED="${MQTT_TLS_ENABLED:-false}"

CONF="/mosquitto/config/mosquitto.conf"

# --- Build mosquitto.conf ---
cat > "$CONF" <<EOF
listener ${MQTT_PORT}
EOF

if [ "$MQTT_TLS_ENABLED" = "true" ]; then
  cat >> "$CONF" <<EOF
cafile ${MQTT_CAFILE}
certfile ${MQTT_CERTFILE}
keyfile ${MQTT_KEYFILE}
require_certificate false
EOF
fi

cat >> "$CONF" <<EOF

persistence ${MQTT_PERSISTENCE}
persistence_location /mosquitto/data/

allow_anonymous ${MQTT_ALLOW_ANONYMOUS}
EOF

# --- Password file ---
if [ -n "${MQTT_USERNAME:-}" ] && [ -n "${MQTT_PASSWORD:-}" ]; then
  PASSFILE="/mosquitto/config/passwordfile"
  touch "$PASSFILE"
  chmod 0700 "$PASSFILE"
  mosquitto_passwd -b "$PASSFILE" "$MQTT_USERNAME" "$MQTT_PASSWORD"
  chown 1883:1883 "$PASSFILE"
  echo "password_file ${PASSFILE}" >> "$CONF"
fi

echo "--- Generated mosquitto.conf ---"
cat "$CONF"
echo "--------------------------------"

exec mosquitto -c "$CONF"
