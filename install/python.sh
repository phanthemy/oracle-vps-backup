#!/usr/bin/env bash
# ==============================================================================
# INSTALL: PYTHON RUNTIME & ENVIRONMENT (PORTABLE)
# Version: Python 3.10+ with pip & venv
# Idempotent: Yes
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared helpers
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/common.sh"

log_step "Installing Python 3, pip, venv, and development libraries..."

apt-get install -y \
  python3 \
  python3-pip \
  python3-venv \
  python3-dev \
  libpq-dev

log_info "Python version: $(python3 -V)"
log_info "Pip version: $(pip3 -V)"

log_step "Installing common utilities (requests, certbot)..."
pip3 install --upgrade pip requests certbot || true

log_success "Python environment ready!"
