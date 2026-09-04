#!/usr/bin/env bash
# ==============================================================================
# VPS DOCTOR: COMPREHENSIVE PRODUCTION HEALTH & DIAGNOSTIC SUITE
# Target: Portable across Oracle Cloud, VMware, Hetzner, Vultr, DigitalOcean
# Checks Swap, RAM, Disk, Limits, Services, Ports, PM2, DB, Redis, Endpoints
# Output: Detailed audit report + PASS/FAIL verdict
# ==============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared helpers
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/common.sh"

PASSED_CHECKS=0
FAILED_CHECKS=0
TOTAL_CHECKS=0

check_result() {
    local name="$1"
    local status="$2"
    local detail="$3"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [ "$status" = "PASS" ]; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        printf "  %-35s [\033[32mPASS\033[0m] %s\n" "$name" "$detail"
    else
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        printf "  %-35s [\033[31mFAIL\033[0m] %s\n" "$name" "$detail"
    fi
}

echo "=================================================================="
echo "🩺 VPS SYSTEM DOCTOR & PRODUCTION DIAGNOSTICS"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "Host: $(hostname) ($(uname -m)) | Target User: ${APP_USER}"
echo "=================================================================="

# 1. Swap Memory
SWAP_TOTAL_MB=$(free -m | awk '/Swap:/ {print $2}')
if [ -n "$SWAP_TOTAL_MB" ] && [ "$SWAP_TOTAL_MB" -ge 3500 ]; then
    check_result "Swap Memory" "PASS" "${SWAP_TOTAL_MB} MB configured"
else
    check_result "Swap Memory" "FAIL" "Only ${SWAP_TOTAL_MB:-0} MB (Expected ≥ 4096 MB)"
fi

# 2. RAM Available
MEM_AVAIL_MB=$(free -m | awk '/Mem:/ {print $7}')
if [ -n "$MEM_AVAIL_MB" ] && [ "$MEM_AVAIL_MB" -ge 400 ]; then
    check_result "RAM Available" "PASS" "${MEM_AVAIL_MB} MB available"
else
    check_result "RAM Available" "FAIL" "Low memory: ${MEM_AVAIL_MB:-0} MB available"
fi

# 3. Disk Space Usage
DISK_USAGE_PCT=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
if [ -n "$DISK_USAGE_PCT" ] && [ "$DISK_USAGE_PCT" -lt 95 ]; then
    check_result "Root Disk Space" "PASS" "${DISK_USAGE_PCT}% used"
else
    check_result "Root Disk Space" "FAIL" "High disk usage: ${DISK_USAGE_PCT:-100}% used"
fi

# 4. System Security Limits (nofile)
ulimit -n 65535 2>/dev/null || true
NOFILE_LIMIT=$(ulimit -n)
if [ "$NOFILE_LIMIT" -ge 1024 ]; then
    check_result "File Descriptors Limit" "PASS" "nofile = ${NOFILE_LIMIT}"
else
    check_result "File Descriptors Limit" "FAIL" "nofile = ${NOFILE_LIMIT} (Expected ≥ 1024)"
fi

# 5. UFW Firewall
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
    check_result "UFW Firewall" "PASS" "Active & filtering traffic"
else
    check_result "UFW Firewall" "FAIL" "UFW is inactive or disabled"
fi

# 6. PostgreSQL Service & Connection
if systemctl is-active --quiet postgresql; then
    if sudo -u postgres psql -c "SELECT 1;" >/dev/null 2>&1; then
        PG_VER=$(sudo -u postgres psql -t -A -c "SHOW server_version;" 2>/dev/null || echo "Unknown")
        check_result "PostgreSQL Service" "PASS" "Active (v${PG_VER}) & responding"
    else
        check_result "PostgreSQL Service" "FAIL" "Service active but SQL connection failed"
    fi
else
    check_result "PostgreSQL Service" "FAIL" "PostgreSQL daemon is not running"
fi

# 7. Redis Cache
if systemctl is-active --quiet redis-server; then
    if command -v redis-cli >/dev/null 2>&1 && [ "$(redis-cli ping 2>/dev/null)" = "PONG" ]; then
        check_result "Redis Cache" "PASS" "Active & PONG response verified"
    else
        check_result "Redis Cache" "FAIL" "Service running but ping failed"
    fi
else
    check_result "Redis Cache" "FAIL" "Redis server daemon is not running"
fi

# 8. Web Server (Caddy / Nginx)
if systemctl is-active --quiet caddy; then
    check_result "Web Server (Caddy)" "PASS" "Caddy daemon active & running"
elif systemctl is-active --quiet nginx; then
    check_result "Web Server (Nginx)" "PASS" "Nginx daemon active & running"
else
    check_result "Web Server" "FAIL" "Neither Caddy nor Nginx is active"
fi

# 9. PM2 Process Manager
if command -v pm2 >/dev/null 2>&1; then
    PM2_JSON=$(run_as_app_user "pm2 jlist" 2>/dev/null || echo "[]")
    ONLINE_COUNT=$(echo "$PM2_JSON" | jq '[.[] | select(.pm2_env.status == "online")] | length' 2>/dev/null || echo "0")
    TOTAL_PM2=$(echo "$PM2_JSON" | jq 'length' 2>/dev/null || echo "0")
    if [ "$ONLINE_COUNT" -gt 0 ]; then
        check_result "PM2 Processes" "PASS" "${ONLINE_COUNT}/${TOTAL_PM2} apps online (User: ${APP_USER})"
    else
        check_result "PM2 Processes" "FAIL" "0 apps running in PM2 (User: ${APP_USER})"
    fi
else
    check_result "PM2 Processes" "FAIL" "PM2 command not found"
fi

# 10. Project Registry Health Endpoints
echo "------------------------------------------------------------------"
echo "🌐 AUDITING PROJECT REGISTRY ENDPOINTS:"

if [ -d "${SCRIPT_DIR}/projects" ]; then
    for REGISTRY in "${SCRIPT_DIR}/projects"/*.json; do
        if [ -f "$REGISTRY" ]; then
            P_NAME=$(jq -r '.name' "$REGISTRY")
            P_URL=$(jq -r '.healthCheck.url' "$REGISTRY")
            EXP_STATUS=$(jq -r '.healthCheck.expectedStatus // 200' "$REGISTRY")
            
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$P_URL" 2>/dev/null || echo "000")
            if [ "$HTTP_CODE" -eq "$EXP_STATUS" ] || ([ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 400 ]); then
                check_result "Project: ${P_NAME}" "PASS" "HTTP ${HTTP_CODE} on ${P_URL}"
            else
                check_result "Project: ${P_NAME}" "FAIL" "HTTP ${HTTP_CODE} (Expected ${EXP_STATUS}) on ${P_URL}"
            fi
        fi
    done
fi

echo "=================================================================="
echo "📊 DOCTOR AUDIT SUMMARY: ${PASSED_CHECKS}/${TOTAL_CHECKS} CHECKS PASSED"

if [ "$FAILED_CHECKS" -eq 0 ]; then
    echo -e "🎉 \033[32mOVERALL HEALTH STATUS: 100% HEALTHY (PRODUCTION READY)\033[0m"
    exit 0
else
    echo -e "⚠️ \033[31mOVERALL HEALTH STATUS: ${FAILED_CHECKS} CHECKS FAILED (ATTENTION REQUIRED)\033[0m"
    exit 1
fi
