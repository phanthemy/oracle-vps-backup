#!/usr/bin/env bash
# ==============================================================================
# INSTALL: NODE.JS RUNTIME & PM2 PROCESS MANAGER
# Version: Node.js v20 LTS / v22 LTS & PM2
# Idempotent: Yes (Skips if already installed with target version)
# ==============================================================================

set -euo pipefail

NODE_MAJOR=20

echo "==> Checking current Node.js installation..."

if command -v node >/dev/null 2>&1; then
    CURRENT_VERSION=$(node -v | sed 's/^v//' | cut -d'.' -f1)
    if [ "$CURRENT_VERSION" = "$NODE_MAJOR" ]; then
        echo "✅ Node.js v$(node -v) is already installed. Skipping NodeSource apt setup."
    else
        echo "==> Current Node.js is v$(node -v), upgrading to v${NODE_MAJOR}.x LTS..."
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg --yes
        echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
        apt-get update -y
        apt-get install -y nodejs
    fi
else
    echo "==> Installing Node.js v${NODE_MAJOR}.x LTS from NodeSource..."
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg --yes
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
    apt-get update -y
    apt-get install -y nodejs
fi

echo "==> Node.js version: $(node -v)"
echo "==> npm version: $(npm -v)"

echo "==> Ensuring global production tools: pm2, pnpm, yarn, tsx..."
if ! command -v pm2 >/dev/null 2>&1; then
    npm install -g pm2 pnpm yarn tsx typescript
else
    echo "✅ PM2 is already installed ($(pm2 -v))."
fi

# Ensure PM2 startup hook for user ubuntu
pm2 startup systemd -u ubuntu --hp /home/ubuntu || true

echo "==> Node.js & PM2 runtime setup complete!"
