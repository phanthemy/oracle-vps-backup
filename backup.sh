#!/usr/bin/env bash
# ==============================================================================
# DISASTER RECOVERY: BACKUP ALL VPS CONFIGURATIONS
# Collects live PM2 dump, Caddyfile, Nginx configs, UFW, Crontab, Sysctl,
# Fstab, Limits, Bashrc, Profile & Databases
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> [1/9] Saving PM2 state..."
mkdir -p "${SCRIPT_DIR}/configs/pm2"
su - ubuntu -c "pm2 save" || true
if [ -f /home/ubuntu/.pm2/dump.pm2 ]; then
    cp /home/ubuntu/.pm2/dump.pm2 "${SCRIPT_DIR}/configs/pm2/dump.pm2"
fi

echo "==> [2/9] Saving Caddyfile..."
mkdir -p "${SCRIPT_DIR}/configs/caddy"
if [ -f /etc/caddy/Caddyfile ]; then
    cp /etc/caddy/Caddyfile "${SCRIPT_DIR}/configs/caddy/Caddyfile"
elif [ -f /home/hung/caddy/conf/Caddyfile ]; then
    cp /home/hung/caddy/conf/Caddyfile "${SCRIPT_DIR}/configs/caddy/Caddyfile"
fi

echo "==> [3/9] Saving Nginx configs..."
mkdir -p "${SCRIPT_DIR}/configs/nginx"
if [ -d /etc/nginx/sites-available ]; then
    cp -r /etc/nginx/sites-available/* "${SCRIPT_DIR}/configs/nginx/" 2>/dev/null || true
fi

echo "==> [4/9] Saving Crontabs..."
mkdir -p "${SCRIPT_DIR}/configs/cron"
crontab -u ubuntu -l > "${SCRIPT_DIR}/configs/cron/crontab.txt" 2>/dev/null || true

echo "==> [5/9] Saving Firewall, Sysctl, Fstab & Limits..."
mkdir -p "${SCRIPT_DIR}/configs/firewall" "${SCRIPT_DIR}/configs/sysctl" "${SCRIPT_DIR}/configs/system"
ufw status verbose > "${SCRIPT_DIR}/configs/firewall/ufw_status.txt" 2>/dev/null || true
iptables-save > "${SCRIPT_DIR}/configs/firewall/iptables.rules" 2>/dev/null || true
cp /etc/sysctl.conf "${SCRIPT_DIR}/configs/sysctl/sysctl.conf" 2>/dev/null || true

# System fstab & security limits (Swap & Oracle tuning)
cp /etc/fstab "${SCRIPT_DIR}/configs/system/fstab" 2>/dev/null || true
cp /etc/security/limits.conf "${SCRIPT_DIR}/configs/system/limits.conf" 2>/dev/null || true
if [ -d /etc/security/limits.d ]; then
    mkdir -p "${SCRIPT_DIR}/configs/system/limits.d"
    cp -r /etc/security/limits.d/* "${SCRIPT_DIR}/configs/system/limits.d/" 2>/dev/null || true
fi

echo "==> [6/9] Saving User Shell Profile (.bashrc, .profile)..."
cp /home/ubuntu/.bashrc "${SCRIPT_DIR}/configs/system/bashrc" 2>/dev/null || true
cp /home/ubuntu/.profile "${SCRIPT_DIR}/configs/system/profile" 2>/dev/null || true

echo "==> [7/9] Saving Installed Packages Selection..."
dpkg --get-selections > "${SCRIPT_DIR}/configs/packages.txt"

echo "==> [8/9] Backing up PostgreSQL Databases..."
bash "${SCRIPT_DIR}/database/backup_database.sh" "${SCRIPT_DIR}/database/dumps" 2>/dev/null || true

echo "==> [9/9] Backup VPS configurations completed successfully!"
