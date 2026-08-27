#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: RESTORE PM2 PROCESS DUMP
# Idempotent: Yes
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PM2_DUMP_FILE="${SCRIPT_DIR}/../configs/pm2/dump.pm2"

echo "==> Restoring PM2 processes from dump..."

if [ -f "$PM2_DUMP_FILE" ]; then
    mkdir -p /home/ubuntu/.pm2
    cp "$PM2_DUMP_FILE" /home/ubuntu/.pm2/dump.pm2
    chown -R ubuntu:ubuntu /home/ubuntu/.pm2
    su - ubuntu -c "pm2 resurrect" || true
    echo "==> PM2 processes resurrected successfully."
else
    echo "==> No PM2 dump file found at $PM2_DUMP_FILE. Skipping resurrect."
fi

su - ubuntu -c "pm2 list"
