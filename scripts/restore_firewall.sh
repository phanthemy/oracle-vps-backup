#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: RESTORE FIREWALL (UFW RULES - PORTABLE)
# Target: Portable across Oracle Cloud, VMware, Hetzner, Vultr, DigitalOcean
# Idempotent: Yes
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared helpers
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/common.sh"

log_step "Configuring UFW Firewall..."

if command -v ufw >/dev/null 2>&1; then
    # Default policies
    ufw default deny incoming
    ufw default allow outgoing

    # Allow standard SSH, HTTP, HTTPS, HTTP3
    ufw allow 22/tcp comment "SSH"
    ufw allow 80/tcp comment "HTTP Web"
    ufw allow 443/tcp comment "HTTPS Web"
    ufw allow 443/udp comment "HTTP3 QUIC"

    # Allow internal loopback
    ufw allow in on lo

    echo "y" | ufw enable || true
    log_success "UFW Firewall enabled and active."

    echo "==> UFW Firewall active rules:"
    ufw status numbered
else
    log_warn "UFW is not installed. Skipping firewall configuration."
fi
