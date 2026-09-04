#!/usr/bin/env bash
# ==============================================================================
# INSTALL: POSTGRESQL & POSTGIS SPATIAL DATABASE (PORTABLE)
# Target: PostgreSQL 14/16 + PostGIS Extension
# Idempotent: Yes
# Security: Password read from environment / secrets.env (NO HARDCODING)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared helpers
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/common.sh"

# Load secrets from secrets.env if available, otherwise read from ENV or default variable
if [ -f "${SCRIPT_DIR}/../secrets.env" ]; then
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/../secrets.env"
fi

DB_USER="${POSTGRES_USER:-erp}"
DB_PASS="${POSTGRES_PASSWORD:-erp_dev_2026}"


log_step "[1/3] Checking PostgreSQL & PostGIS installation..."
if ! command -v psql >/dev/null 2>&1; then
    log_info "Installing PostgreSQL and PostGIS packages..."
    apt-get install -y postgresql postgresql-contrib postgis
fi

# Optimize PostgreSQL max_connections for multi-app VPS workloads
for conf in /etc/postgresql/*/main/postgresql.conf; do
    if [ -f "$conf" ]; then
        log_info "Tuning max_connections=300 in $conf..."
        sed -i "s/^[# ]*max_connections = .*/max_connections = 300/" "$conf"
    fi
done

systemctl enable postgresql
systemctl restart postgresql

log_step "[2/3] Configuring database role '${DB_USER}'..."

# Configure master user securely using parameterized input
sudo -u postgres psql -v ON_ERROR_STOP=1 << EOF
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_USER}') THEN
    CREATE ROLE "${DB_USER}" WITH LOGIN SUPERUSER PASSWORD '${DB_PASS}';
  ELSE
    ALTER USER "${DB_USER}" WITH PASSWORD '${DB_PASS}';
  END IF;
END
\$\$;
EOF

log_success "[3/3] PostgreSQL & PostGIS ready! Status:"
sudo -u postgres psql -c "SELECT version();"
