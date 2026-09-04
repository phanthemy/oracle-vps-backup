#!/usr/bin/env bash
# ==============================================================================
# 1-CLICK ALL-IN-ONE DISASTER RECOVERY RESTORATION SCRIPT
# Target: Any fresh Ubuntu 22.04 / 24.04 LTS VPS (Oracle Cloud, VMware, Hetzner, Vultr, DO)
# Usage:
#   curl -sSL https://raw.githubusercontent.com/phanthemy/oracle-vps-backup/main/restore-vps.sh | bash
#   OR:
#   bash restore-vps.sh
# ==============================================================================

set -euo pipefail

# 1. Require root privileges
if [ "$(id -u 2>/dev/null || echo 1)" -ne 0 ]; then
    echo "❌ Error: This script must be run as root."
    echo "Please execute: sudo -i (or login as root) then re-run."
    exit 1
fi

echo "=================================================================="
echo "🚀 1-CLICK ZERO-TO-PRODUCTION VPS DISASTER RECOVERY"
echo "Host: $(hostname) | Date: $(date)"
echo "=================================================================="

# 2. Install bootstrap prerequisites non-interactively
export DEBIAN_FRONTEND=noninteractive
echo "==> [1/4] Preparing minimal tools (git, jq, curl, ca-certificates)..."
apt-get update -qq >/dev/null 2>&1 || apt-get update -y
apt-get install -y -qq git jq curl ca-certificates tar gzip >/dev/null 2>&1

# 3. Setup workspace repository
TARGET_DIR="/tmp/oracle-vps-backup"
if [ ! -d "${TARGET_DIR}/.git" ]; then
    echo "==> [2/4] Downloading latest recovery framework from GitHub..."
    rm -rf "$TARGET_DIR"
    git clone --depth=1 https://github.com/phanthemy/oracle-vps-backup.git "$TARGET_DIR"
else
    echo "==> [2/4] Updating recovery framework in ${TARGET_DIR}..."
    cd "$TARGET_DIR"
    git pull origin main >/dev/null 2>&1 || true
fi

cd "$TARGET_DIR"

# 4. Run System Bootstrap (Base packages, Swap, Node.js, PM2, Python, PostgreSQL, Redis, Caddy)
echo "==> [3/4] Running VPS System Infrastructure Bootstrap..."
bash "${TARGET_DIR}/bootstrap.sh"

# 5. Run Application & Database Restores
echo "==> [4/4] Restoring all registered applications & databases..."
bash "${TARGET_DIR}/restore-all.sh"

echo "=================================================================="
echo "🎉 VPS RESTORATION COMPLETED SUCCESSFULLY!"
echo "All services, databases, PM2 processes, and Caddy reverse proxies are UP."
echo "=================================================================="