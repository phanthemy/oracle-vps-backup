#!/usr/bin/env bash
# ==============================================================================
# LIB: USER DETECTION & EXECUTION HELPERS (PORTABLE & ZERO HARDCODING)
# Architecture: Auto-detects runtime application user across Cloud / VM / Baremetal
# Compatible with: Oracle Cloud, VMware, Hetzner, Vultr, DigitalOcean, etc.
# ==============================================================================

# Detect the non-root application user
detect_app_user() {
    # 1. Explicitly passed via APP_USER env variable
    if [ -n "${APP_USER:-}" ]; then
        echo "$APP_USER"
        return 0
    fi

    # 2. Inherited from SUDO_USER (if running with sudo and not root/nobody)
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ] && [ "$SUDO_USER" != "nobody" ]; then
        echo "$SUDO_USER"
        return 0
    fi

    # 3. First non-system user with UID >= 1000 from /etc/passwd (excluding nobody)
    local first_regular_user
    first_regular_user=$(getent passwd 2>/dev/null | awk -F: '$3 >= 1000 && $1 != "nobody" {print $1; exit}' || true)
    if [ -n "$first_regular_user" ]; then
        echo "$first_regular_user"
        return 0
    fi

    # 4. Fallback to current user or root if no regular user found
    local current_user
    current_user=$(id -un 2>/dev/null || whoami 2>/dev/null || echo "root")
    echo "$current_user"
}

# Resolve HOME directory for a given user safely
get_app_home() {
    local target_user="${1:-$(detect_app_user)}"
    local home_dir
    home_dir=$(getent passwd "$target_user" 2>/dev/null | cut -d: -f6)
    if [ -z "$home_dir" ]; then
        if [ "$target_user" = "root" ]; then
            home_dir="/root"
        else
            home_dir="/home/${target_user}"
        fi
    fi
    echo "$home_dir"
}

# Run a command as the detected application user
run_as_app_user() {
    local target_user="${APP_USER:-$(detect_app_user)}"
    local cmd="$*"

    # If already running as target user, execute directly
    local current_running_user
    current_running_user=$(id -un 2>/dev/null || whoami 2>/dev/null || echo "")

    if [ "$current_running_user" = "$target_user" ]; then
        bash -c "$cmd"
    elif [ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]; then
        # Running as root: switch to target user with clean login environment
        su - "$target_user" -c "$cmd"
    else
        # Running as a different non-root user: attempt sudo
        sudo -u "$target_user" -H bash -c "$cmd"
    fi
}
