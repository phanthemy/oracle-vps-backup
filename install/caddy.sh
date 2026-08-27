#!/usr/bin/env bash
# ==============================================================================
# INSTALL: CADDY WEB SERVER (AUTOMATIC TLS & REVERSE PROXY)
# Idempotent: Yes
# ==============================================================================

set -euo pipefail

echo "==> Installing official Caddy web server..."

apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg || true
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list

apt-get update -y
apt-get install -y caddy

systemctl enable caddy
systemctl start caddy

echo "==> Caddy Server installed successfully! Version: $(caddy version)"
