#!/bin/bash
# renew-cert.sh — copy a renewed certbot certificate into the certs/ directory
#                 and restart the TLS broker container.
#
# Requires: certbot, sudo, docker
#
# Usage:
#   Edit DOMAIN and DEST below to match your setup, then run:
#     ./renew-cert.sh
#
# What it does:
#   1. Asks certbot for the path to the most recently expiring valid certificate
#      for DOMAIN.
#   2. Copies chain.pem, fullchain.pem, and privkey.pem from that certbot-managed
#      path into DEST (the directory mounted into the tls container as ./certs/).
#   3. Restarts the tls broker container so it loads the new certificate.
#
# This script is intended to be run after certbot has renewed the certificate,
# e.g. from a post-renewal hook in /etc/letsencrypt/renewal-hooks/deploy/.
set -euo pipefail

# Domain the TLS certificate covers.
DOMAIN="your.domain.example"

# Destination directory — must match the host-side path mounted into the
# tls service as ./certs in docker-compose.yml.
DEST="/path/to/multi-mqtt-docker-compose/certs"

# Find the valid cert covering our domain (picks the latest expiry)
CERT_PATH=$(sudo certbot certificates --domain "$DOMAIN" 2>/dev/null \
  | awk '/Expiry Date:.*\(VALID:/{date=$3; valid=1} /Certificate Path:/ && valid{print date, $NF; valid=0}' \
  | sort -r | head -1 | awk '{print $2}')

if [ -z "$CERT_PATH" ]; then
  echo "ERROR: No valid certificate found for $DOMAIN" >&2
  exit 1
fi

CERT_DIR=$(dirname "$CERT_PATH")
echo "Using certs from: $CERT_DIR"

mkdir -p "$DEST"

sudo cp "$CERT_DIR/chain.pem"     "$DEST/"
sudo cp "$CERT_DIR/fullchain.pem" "$DEST/"
sudo cp "$CERT_DIR/privkey.pem"   "$DEST/"

# Restart the TLS broker so it picks up the new certificate.
# The container name is the default Compose-generated name for the tls service.
docker restart -t 30 multi-mqtt-docker-compose-broker-tls-1

