#!/usr/bin/env bash
# ==============================================================================
# INSTALL: REDIS IN-MEMORY CACHE (PORTABLE)
# Idempotent: Yes
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared helpers
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/common.sh"

log_step "Installing Redis Server..."

apt-get install -y redis-server

systemctl enable redis-server
systemctl start redis-server

# Set maxmemory 512mb & volatile-lru eviction if not set
if ! grep -q "maxmemory 512mb" /etc/redis/redis.conf; then
    echo "maxmemory 512mb" >> /etc/redis/redis.conf
    echo "maxmemory-policy volatile-lru" >> /etc/redis/redis.conf
    systemctl restart redis-server
    log_info "Configured Redis maxmemory 512MB and volatile-lru policy."
fi

log_success "Redis Server active! Ping test:"
redis-cli ping
