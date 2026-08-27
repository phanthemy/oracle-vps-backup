#!/usr/bin/env bash
# ==============================================================================
# INSTALL: PYTHON RUNTIME & ENVIRONMENT
# Version: Python 3.10+ with pip & venv
# Idempotent: Yes
# ==============================================================================

set -euo pipefail

echo "==> Installing Python 3, pip, venv, and development libraries..."

apt-get install -y \
  python3 \
  python3-pip \
  python3-venv \
  python3-dev \
  libpq-dev

echo "==> Python version: $(python3 -V)"
echo "==> Pip version: $(pip3 -V)"

echo "==> Installing common utilities (requests, certbot)..."
pip3 install --upgrade pip requests certbot || true

echo "==> Python environment ready!"
