#!/usr/bin/env bash
# ==============================================================================
# INSTALL: CADDY WEB SERVER (AUTOMATIC TLS & REVERSE PROXY - PORTABLE)
# Idempotent: Yes
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared helpers
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/common.sh"

log_step "Installing official Caddy web server..."

apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg || true
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list

apt-get update -y
apt-get install -y caddy

systemctl enable caddy
systemctl start caddy

log_success "Caddy Server installed successfully! Version: $(caddy version)"
