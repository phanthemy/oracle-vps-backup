#!/usr/bin/env bash
# ==============================================================================
# INSTALL: SYSTEM BASE PACKAGES & ESSENTIAL BUILD TOOLS
# Target OS: Ubuntu 22.04 / 24.04 LTS (Jammy / Noble) ARM64 / x86_64
# Idempotent: Yes
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared helpers
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/common.sh"

log_step "Updating OS package lists..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

log_step "Installing core system packages & build tools..."
apt-get install -y \
  build-essential \
  ca-certificates \
  curl \
  wget \
  gnupg \
  lsb-release \
  software-properties-common \
  git \
  htop \
  jq \
  unzip \
  zip \
  tar \
  rsync \
  ufw \
  fail2ban \
  net-tools \
  dnsutils \
  procps

log_success "Base system packages installed successfully!"
