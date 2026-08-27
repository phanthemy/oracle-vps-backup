#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: RESTORE CADDYFILE CONFIGURATION
# Idempotent: Yes
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CADDY_CONFIG="${SCRIPT_DIR}/../configs/caddy/Caddyfile"

echo "==> Restoring Caddyfile configuration..."

if [ -f "$CADDY_CONFIG" ]; then
    mkdir -p /etc/caddy
    cp "$CADDY_CONFIG" /etc/caddy/Caddyfile
    
    # Also support /home/hung/caddy/conf/Caddyfile if dockerized
    mkdir -p /home/hung/caddy/conf
    cp "$CADDY_CONFIG" /home/hung/caddy/conf/Caddyfile
    chown -R ubuntu:ubuntu /home/hung/caddy || true

    # Validate and reload Caddy if running
    if systemctl is-active --quiet caddy; then
        caddy validate --config /etc/caddy/Caddyfile
        systemctl reload caddy
        echo "==> Caddy service reloaded successfully."
    fi
else
    echo "==> Warning: No Caddyfile found at $CADDY_CONFIG"
fi
