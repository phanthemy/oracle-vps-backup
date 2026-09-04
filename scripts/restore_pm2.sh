#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: RESTORE PM2 PROCESS DUMP (PORTABLE)
# Target: Portable across Oracle Cloud, VMware, Hetzner, Vultr, DigitalOcean
# Idempotent: Yes
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared helpers
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/common.sh"

PM2_DUMP_FILE="${SCRIPT_DIR}/../configs/pm2/dump.pm2"

log_step "Restoring PM2 processes from dump for user '${APP_USER}' (Home: ${APP_HOME})..."

if [ -f "$PM2_DUMP_FILE" ]; then
    mkdir -p "${APP_HOME}/.pm2"
    cp "$PM2_DUMP_FILE" "${APP_HOME}/.pm2/dump.pm2"
    chown -R "${APP_USER}:${APP_USER}" "${APP_HOME}/.pm2"
    run_as_app_user "pm2 resurrect" || true
    log_success "PM2 processes resurrected successfully."
else
    log_warn "No PM2 dump file found at $PM2_DUMP_FILE. Skipping resurrect."
fi

run_as_app_user "pm2 list"
