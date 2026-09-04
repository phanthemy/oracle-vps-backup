#!/usr/bin/env bash
# ==============================================================================
# LIB: COMMON SYSTEM HELPERS, LOGGING & ERROR HANDLING
# Reusable shared utilities for all bootstrap, backup, restore & doctor scripts
# ==============================================================================

set -euo pipefail

# ANSI Color Codes
CLR_RESET="\033[0m"
CLR_RED="\033[1;31m"
CLR_GREEN="\033[1;32m"
CLR_YELLOW="\033[1;33m"
CLR_BLUE="\033[1;34m"
CLR_CYAN="\033[1;36m"
CLR_BOLD="\033[1m"

log_info() {
    echo -e "${CLR_BLUE}ℹ️  [INFO]${CLR_RESET} $*"
}

log_step() {
    echo -e "\n${CLR_CYAN}==> [STEP]${CLR_RESET} ${CLR_BOLD}$*${CLR_RESET}"
}

log_success() {
    echo -e "${CLR_GREEN}✅ [SUCCESS]${CLR_RESET} $*"
}

log_warn() {
    echo -e "${CLR_YELLOW}⚠️  [WARNING]${CLR_RESET} $*" >&2
}

log_error() {
    echo -e "${CLR_RED}❌ [ERROR]${CLR_RESET} $*" >&2
}

require_root() {
    if [ "$(id -u 2>/dev/null || echo 1)" -ne 0 ]; then
        log_error "This script requires superuser privileges. Please run with sudo or as root."
        exit 1
    fi
}

# Auto-source user detection helpers
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${LIB_DIR}/user.sh" ]; then
    # shellcheck source=/dev/null
    source "${LIB_DIR}/user.sh"
fi

# Detect and export runtime application user & home
DETECTED_USER="$(detect_app_user)"
APP_USER="${APP_USER:-$DETECTED_USER}"
APP_HOME="${APP_HOME:-$(get_app_home "$APP_USER")}"
export APP_USER APP_HOME
