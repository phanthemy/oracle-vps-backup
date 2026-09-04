#!/usr/bin/env bash
# ==============================================================================
# INSTALL: NODE.JS RUNTIME & PM2 PROCESS MANAGER
# Target: Portable across Oracle Cloud, VMware, Hetzner, Vultr, DigitalOcean
# Version: Node.js v20 LTS / v22 LTS & PM2
# Idempotent: Yes (Skips if already installed with target version)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared helpers
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/common.sh"

NODE_MAJOR=20

log_step "Checking current Node.js installation..."

if command -v node >/dev/null 2>&1; then
    CURRENT_VERSION=$(node -v | sed 's/^v//' | cut -d'.' -f1)
    if [ "$CURRENT_VERSION" = "$NODE_MAJOR" ]; then
        log_success "Node.js v$(node -v) is already installed. Skipping NodeSource apt setup."
    else
        log_info "Current Node.js is v$(node -v), upgrading to v${NODE_MAJOR}.x LTS..."
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg --yes
        echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
        apt-get update -y
        apt-get install -y nodejs
    fi
else
    log_info "Installing Node.js v${NODE_MAJOR}.x LTS from NodeSource..."
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg --yes
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
    apt-get update -y
    apt-get install -y nodejs
fi

log_info "Node.js version: $(node -v)"
log_info "npm version: $(npm -v)"

log_step "Ensuring global production tools: pm2, pnpm, yarn, tsx..."
if ! command -v pm2 >/dev/null 2>&1; then
    npm install -g pm2 pnpm yarn tsx typescript
else
    log_success "PM2 is already installed ($(pm2 -v))."
fi

# Ensure PM2 startup hook for target application user
log_step "Configuring PM2 systemd startup for user '${APP_USER}' (Home: ${APP_HOME})..."
pm2 startup systemd -u "$APP_USER" --hp "$APP_HOME" || true

log_success "Node.js & PM2 runtime setup complete!"
