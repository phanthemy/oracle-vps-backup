#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: RESTORE CRONTAB SCHEDULES
# Idempotent: Yes
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRON_FILE="${SCRIPT_DIR}/../configs/cron/crontab.txt"

echo "==> Restoring Crontab schedules..."

if [ -f "$CRON_FILE" ]; then
    crontab -u ubuntu "$CRON_FILE" || true
    echo "==> Crontab restored for user ubuntu."
    crontab -u ubuntu -l
else
    echo "==> No crontab.txt found at $CRON_FILE. Skipping."
fi
