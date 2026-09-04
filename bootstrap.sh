#!/usr/bin/env bash
# ==============================================================================
# VPS ZERO-TO-PRODUCTION BOOTSTRAPPER (PORTABLE IaC ENGINE)
# Target: Ubuntu 22.04 / 24.04 LTS (ARM64 & x86_64)
# Compatible with: Oracle Cloud, VMware, Hetzner, Vultr, DigitalOcean, Baremetal
# Philosophy: Zero snapshot, Zero manual configuration, 100% reproducible
# Idempotent: Yes
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared helpers
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/common.sh"

require_root

echo "=================================================================="
echo "🚀 STARTING VPS ZERO-TO-PRODUCTION BOOTSTRAP"
echo "Target User: ${APP_USER} (Home: ${APP_HOME})"
echo "Architecture: $(uname -m) | Host: $(hostname)"
echo "=================================================================="

# Step 1: Base Packages & Essentials
log_step "[1/8] Installing Base Packages & Build Tools..."
bash "${SCRIPT_DIR}/install/ubuntu.sh"

# Step 2: Swap Space
log_step "[2/8] Configuring 4GB Swap Space..."
bash "${SCRIPT_DIR}/install/swap.sh"

# Step 3: Kernel & Limits Tuning
log_step "[3/8] Applying High-Concurrency Limits & Network Tuning..."
bash "${SCRIPT_DIR}/install/oracle.sh"

# Step 4: Node.js & PM2
log_step "[4/8] Installing Node.js LTS & PM2 Process Manager..."
bash "${SCRIPT_DIR}/install/node.sh"

# Step 5: Python 3 Environment
log_step "[5/8] Installing Python 3 & Development Environment..."
bash "${SCRIPT_DIR}/install/python.sh"

# Step 6: PostgreSQL & PostGIS
log_step "[6/8] Installing PostgreSQL & PostGIS Database Server..."
bash "${SCRIPT_DIR}/install/postgres.sh"

# Step 7: Redis Cache & Caddy Web Server
log_step "[7/8] Installing Redis Server & Caddy Web Server..."
bash "${SCRIPT_DIR}/install/redis.sh"
bash "${SCRIPT_DIR}/install/caddy.sh"

# Step 8: Restore System Configurations
log_step "[8/8] Restoring Firewall, Caddyfile, Cron & PM2 Processes..."
bash "${SCRIPT_DIR}/scripts/restore_firewall.sh"
bash "${SCRIPT_DIR}/scripts/restore_caddy.sh"
bash "${SCRIPT_DIR}/scripts/restore_cron.sh"
bash "${SCRIPT_DIR}/scripts/restore_pm2.sh"

echo "=================================================================="
echo "🎯 RUNNING POST-BOOTSTRAP HEALTH CHECK"
echo "=================================================================="

echo "1. PM2 Status (User: ${APP_USER}):"
run_as_app_user "pm2 status" || true

echo -e "\n2. PostgreSQL Status:"
systemctl is-active --quiet postgresql && log_success "PostgreSQL: ACTIVE" || log_error "PostgreSQL: INACTIVE"

echo -e "\n3. Redis Status:"
systemctl is-active --quiet redis-server && log_success "Redis: ACTIVE" || log_error "Redis: INACTIVE"

echo -e "\n4. Caddy Web Server Status:"
systemctl is-active --quiet caddy && log_success "Caddy: ACTIVE" || log_error "Caddy: INACTIVE"

echo "=================================================================="
echo "🎉 VPS BOOTSTRAP COMPLETED SUCCESSFULLY!"
echo "You can now restore any project using: bash restore.sh <project_name>"
echo "=================================================================="
