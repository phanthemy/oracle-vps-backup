#!/usr/bin/env bash
# ==============================================================================
# INSTALL: UBUNTU SYSTEM BASE & ESSENTIALS
# Target OS: Ubuntu 22.04 LTS (Jammy) ARM64 / x86_64
# Idempotent: Yes
# ==============================================================================

set -euo pipefail

echo "==> [1/8] Updating Ubuntu package lists..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

echo "==> [2/8] Installing core system packages & build tools..."
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

echo "==> [3/8] Base system packages installed successfully!"
