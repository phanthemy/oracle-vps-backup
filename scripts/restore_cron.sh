#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: RESTORE CRONTAB SCHEDULES (PORTABLE)
# Target: Portable across Oracle Cloud, VMware, Hetzner, Vultr, DigitalOcean
# Idempotent: Yes
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared helpers
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/common.sh"

CRON_FILE="${SCRIPT_DIR}/../configs/cron/crontab.txt"

log_step "Restoring Crontab schedules for user '${APP_USER}'..."

if [ -f "$CRON_FILE" ]; then
    crontab -u "$APP_USER" "$CRON_FILE" || true
    log_success "Crontab restored for user ${APP_USER}."
    crontab -u "$APP_USER" -l
else
    log_info "No crontab.txt found at $CRON_FILE. Skipping."
fi
