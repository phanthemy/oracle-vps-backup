#!/usr/bin/env bash
# ==============================================================================
# DISASTER RECOVERY: BACKUP ALL VPS CONFIGURATIONS
# Target: Portable across Oracle Cloud, VMware, Hetzner, Vultr, DigitalOcean
# Collects live PM2 dump, Caddyfile, Nginx configs, UFW, Crontab, Sysctl,
# Fstab, Limits, Bashrc, Profile & Databases
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared helpers
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/common.sh"

log_info "Detected Application User: ${CLR_BOLD}${APP_USER}${CLR_RESET} (Home: ${APP_HOME})"

log_step "[1/9] Saving PM2 state..."
mkdir -p "${SCRIPT_DIR}/configs/pm2"
run_as_app_user "pm2 save" || true
if [ -f "${APP_HOME}/.pm2/dump.pm2" ]; then
    cp "${APP_HOME}/.pm2/dump.pm2" "${SCRIPT_DIR}/configs/pm2/dump.pm2"
    log_success "PM2 dump copied from ${APP_HOME}/.pm2/dump.pm2"
fi

log_step "[2/9] Saving Caddyfile..."
mkdir -p "${SCRIPT_DIR}/configs/caddy"
if [ -f /etc/caddy/Caddyfile ]; then
    cp /etc/caddy/Caddyfile "${SCRIPT_DIR}/configs/caddy/Caddyfile"
    log_success "Caddyfile saved from /etc/caddy/Caddyfile"
elif [ -f "${APP_HOME}/caddy/conf/Caddyfile" ]; then
    cp "${APP_HOME}/caddy/conf/Caddyfile" "${SCRIPT_DIR}/configs/caddy/Caddyfile"
    log_success "Caddyfile saved from ${APP_HOME}/caddy/conf/Caddyfile"
fi

log_step "[3/9] Saving Nginx configs..."
mkdir -p "${SCRIPT_DIR}/configs/nginx"
if [ -d /etc/nginx/sites-available ]; then
    cp -r /etc/nginx/sites-available/* "${SCRIPT_DIR}/configs/nginx/" 2>/dev/null || true
    log_success "Nginx configurations saved"
fi

log_step "[4/9] Saving Crontabs for user ${APP_USER}..."
mkdir -p "${SCRIPT_DIR}/configs/cron"
crontab -u "$APP_USER" -l > "${SCRIPT_DIR}/configs/cron/crontab.txt" 2>/dev/null || true
log_success "Crontab saved"

log_step "[5/9] Saving Firewall, Sysctl, Fstab & Security Limits..."
mkdir -p "${SCRIPT_DIR}/configs/firewall" "${SCRIPT_DIR}/configs/sysctl" "${SCRIPT_DIR}/configs/system"
ufw status verbose > "${SCRIPT_DIR}/configs/firewall/ufw_status.txt" 2>/dev/null || true
iptables-save > "${SCRIPT_DIR}/configs/firewall/iptables.rules" 2>/dev/null || true
cp /etc/sysctl.conf "${SCRIPT_DIR}/configs/sysctl/sysctl.conf" 2>/dev/null || true

# System fstab & security limits (Swap & kernel tuning)
cp /etc/fstab "${SCRIPT_DIR}/configs/system/fstab" 2>/dev/null || true
cp /etc/security/limits.conf "${SCRIPT_DIR}/configs/system/limits.conf" 2>/dev/null || true
if [ -d /etc/security/limits.d ]; then
    mkdir -p "${SCRIPT_DIR}/configs/system/limits.d"
    cp -r /etc/security/limits.d/* "${SCRIPT_DIR}/configs/system/limits.d/" 2>/dev/null || true
fi
log_success "System firewall and tuning parameters saved"

log_step "[6/9] Saving User Shell Profile (.bashrc, .profile)..."
if [ -f "${APP_HOME}/.bashrc" ]; then
    cp "${APP_HOME}/.bashrc" "${SCRIPT_DIR}/configs/system/bashrc" 2>/dev/null || true
fi
if [ -f "${APP_HOME}/.profile" ]; then
    cp "${APP_HOME}/.profile" "${SCRIPT_DIR}/configs/system/profile" 2>/dev/null || true
fi
log_success "User profile saved from ${APP_HOME}"

log_step "[7/9] Saving Installed Packages Selection..."
dpkg --get-selections > "${SCRIPT_DIR}/configs/packages.txt" 2>/dev/null || true
log_success "Package list saved"

log_step "[8/9] Backing up PostgreSQL Databases..."
bash "${SCRIPT_DIR}/database/backup_database.sh" "${SCRIPT_DIR}/database/dumps" 2>/dev/null || true

log_step "[9/9] Backup VPS configurations completed successfully!"
