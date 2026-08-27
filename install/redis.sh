#!/usr/bin/env bash
# ==============================================================================
# INSTALL: REDIS IN-MEMORY CACHE
# Idempotent: Yes
# ==============================================================================

set -euo pipefail

echo "==> Installing Redis Server..."

apt-get install -y redis-server

systemctl enable redis-server
systemctl start redis-server

# Set maxmemory 512mb & volatile-lru eviction if not set
if ! grep -q "maxmemory 512mb" /etc/redis/redis.conf; then
    echo "maxmemory 512mb" >> /etc/redis/redis.conf
    echo "maxmemory-policy volatile-lru" >> /etc/redis/redis.conf
    systemctl restart redis-server
fi

echo "==> Redis Server active! Ping test:"
redis-cli ping
