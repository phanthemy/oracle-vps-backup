#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: RESTORE FIREWALL (UFW RULES)
# Idempotent: Yes
# ==============================================================================

set -euo pipefail

echo "==> Configuring UFW Firewall..."

# Default policies
ufw default deny incoming
ufw default allow outgoing

# Allow standard SSH, HTTP, HTTPS
ufw allow 22/tcp comment "SSH"
ufw allow 80/tcp comment "HTTP Web"
ufw allow 443/tcp comment "HTTPS Web"
ufw allow 443/udp comment "HTTP3 QUIC"

# Allow internal loopback
ufw allow in on lo

echo "y" | ufw enable || true

echo "==> UFW Firewall active rules:"
ufw status numbered
