#!/usr/bin/env bash
# ==============================================================================
# ORACLE VPS ZERO-TO-PRODUCTION BOOTSTRAPPER (IaC ENGINE)
# Target: Ubuntu 22.04 LTS (Oracle Cloud ARM64 / x86_64)
# Philosophy: Zero snapshot, Zero manual configuration, 100% reproducible
# Idempotent: Yes
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================================================="
echo "🚀 STARTING ORACLE VPS BOOTSTRAP PROCESS"
echo "=================================================================="

# Step 1: Base Ubuntu & Essentials
echo "==> [1/8] Installing Ubuntu Base & Build Tools..."
bash "${SCRIPT_DIR}/install/ubuntu.sh"

# Step 2: Swap Space
echo "==> [2/8] Configuring 4GB Swap Space..."
bash "${SCRIPT_DIR}/install/swap.sh"

# Step 3: Kernel & Limits Tuning
echo "==> [3/8] Applying Oracle Cloud Limits & Network Tuning..."
bash "${SCRIPT_DIR}/install/oracle.sh"

# Step 4: Node.js & PM2
echo "==> [4/8] Installing Node.js LTS & PM2..."
bash "${SCRIPT_DIR}/install/node.sh"

# Step 5: Python 3 Environment
echo "==> [5/8] Installing Python 3 & Development Environment..."
bash "${SCRIPT_DIR}/install/python.sh"

# Step 6: PostgreSQL & PostGIS
echo "==> [6/8] Installing PostgreSQL & PostGIS Database Server..."
bash "${SCRIPT_DIR}/install/postgres.sh"

# Step 7: Redis Cache & Caddy
echo "==> [7/8] Installing Redis Server & Caddy Web Server..."
bash "${SCRIPT_DIR}/install/redis.sh"
bash "${SCRIPT_DIR}/install/caddy.sh"

# Step 8: Restore System Configurations
echo "==> [8/8] Restoring Firewall, Caddyfile, Cron & PM2..."
bash "${SCRIPT_DIR}/scripts/restore_firewall.sh"
bash "${SCRIPT_DIR}/scripts/restore_caddy.sh"
bash "${SCRIPT_DIR}/scripts/restore_cron.sh"
bash "${SCRIPT_DIR}/scripts/restore_pm2.sh"

echo "=================================================================="
echo "🎯 RUNNING POST-BOOTSTRAP HEALTH CHECK"
echo "=================================================================="

echo "1. PM2 Status:"
su - ubuntu -c "pm2 status"

echo "2. PostgreSQL Status:"
systemctl is-active --quiet postgresql && echo "✅ PostgreSQL: ACTIVE" || echo "❌ PostgreSQL: INACTIVE"

echo "3. Redis Status:"
systemctl is-active --quiet redis-server && echo "✅ Redis: ACTIVE" || echo "❌ Redis: INACTIVE"

echo "4. Caddy Web Server Status:"
systemctl is-active --quiet caddy && echo "✅ Caddy: ACTIVE" || echo "❌ Caddy: INACTIVE"

echo "=================================================================="
echo "🎉 ORACLE VPS BOOTSTRAP COMPLETED SUCCESSFULLY!"
echo "You can now restore any project using: bash restore.sh <project_name>"
echo "=================================================================="
