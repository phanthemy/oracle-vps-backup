#!/usr/bin/env bash
# ==============================================================================
# INSTALL: SWAP MEMORY CONFIGURATION
# Size: 4GB Swap Space
# Idempotent: Yes
# ==============================================================================

set -euo pipefail

SWAP_FILE="/swapfile"
SWAP_SIZE="4G"

echo "==> Configuring Swap Memory ($SWAP_SIZE)..."

if [ -f "$SWAP_FILE" ]; then
    echo "==> Swap file already exists at $SWAP_FILE. Skipping creation."
else
    echo "==> Creating $SWAP_SIZE swap file..."
    fallocate -l "$SWAP_SIZE" "$SWAP_FILE" || dd if=/dev/zero of="$SWAP_FILE" bs=1M count=4096
    chmod 600 "$SWAP_FILE"
    mkswap "$SWAP_FILE"
    swapon "$SWAP_FILE"
    echo "==> Swap file activated."
fi

# Add to /etc/fstab if not present
if ! grep -q "$SWAP_FILE" /etc/fstab; then
    echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
    echo "==> Added swap to /etc/fstab"
fi

# Tune swappiness to 10 for low latency database & Node workloads
sysctl vm.swappiness=10
sysctl vm.vfs_cache_pressure=50

if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
fi

echo "==> Swap configuration complete. Current status:"
free -h
