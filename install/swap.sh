#!/usr/bin/env bash
# ==============================================================================
# INSTALL: SWAP MEMORY CONFIGURATION (PORTABLE)
# Size: 4GB Swap Space + vm.swappiness=10
# Idempotent: Yes
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared helpers
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/common.sh"

SWAP_FILE="/swapfile"
SWAP_SIZE="4G"

log_step "Configuring Swap Memory ($SWAP_SIZE)..."

if [ -f "$SWAP_FILE" ]; then
    log_info "Swap file already exists at $SWAP_FILE. Skipping creation."
else
    log_info "Creating $SWAP_SIZE swap file..."
    fallocate -l "$SWAP_SIZE" "$SWAP_FILE" || dd if=/dev/zero of="$SWAP_FILE" bs=1M count=4096
    chmod 600 "$SWAP_FILE"
    mkswap "$SWAP_FILE"
    swapon "$SWAP_FILE"
    log_success "Swap file activated."
fi

# Add to /etc/fstab if not present
if ! grep -q "$SWAP_FILE" /etc/fstab; then
    echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
    log_info "Added swap entry to /etc/fstab"
fi

# Tune swappiness to 10 for low latency database & Node workloads
sysctl vm.swappiness=10 || true
sysctl vm.vfs_cache_pressure=50 || true

if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
fi

log_success "Swap configuration complete. Current status:"
free -h
