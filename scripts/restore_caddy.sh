#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: RESTORE CADDYFILE CONFIGURATION (PORTABLE)
# Target: Portable across Oracle Cloud, VMware, Hetzner, Vultr, DigitalOcean
# Idempotent: Yes
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared helpers
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/common.sh"

CADDY_CONFIG="${SCRIPT_DIR}/../configs/caddy/Caddyfile"

log_step "Restoring Caddyfile configuration..."

if [ -f "$CADDY_CONFIG" ]; then
    mkdir -p /etc/caddy
    cp "$CADDY_CONFIG" /etc/caddy/Caddyfile
    
    # Also support user-level containerized Caddy if directory exists
    if [ -d "${APP_HOME}/caddy" ]; then
        mkdir -p "${APP_HOME}/caddy/conf"
        cp "$CADDY_CONFIG" "${APP_HOME}/caddy/conf/Caddyfile"
        chown -R "${APP_USER}:${APP_USER}" "${APP_HOME}/caddy" || true
    fi

    # Validate and reload Caddy if running
    if systemctl is-active --quiet caddy; then
        caddy validate --config /etc/caddy/Caddyfile
        systemctl reload caddy
        log_success "Caddy service reloaded successfully."
    fi
else
    log_warn "No Caddyfile found at $CADDY_CONFIG"
fi
