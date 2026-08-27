#!/usr/bin/env bash
# ==============================================================================
# INSTALL: ORACLE CLOUD LINUX KERNEL & LIMITS TUNING
# Idempotent: Yes
# ==============================================================================

set -euo pipefail

echo "==> Applying Oracle Cloud high-concurrency limits..."

cat << 'EOF' > /etc/security/limits.d/99-oracle-limits.conf
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535
root soft nofile 65535
root hard nofile 65535
EOF

cat << 'EOF' > /etc/sysctl.d/99-network-tuning.conf
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
fs.file-max = 2097152
EOF

sysctl --system || true

echo "==> Oracle Linux kernel tuning applied successfully!"
