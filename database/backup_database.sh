#!/usr/bin/env bash
# ==============================================================================
# DATABASE ENGINE: BACKUP ALL ROLES, SCHEMAS & DATABASES
# Target: PostgreSQL + PostGIS
# ==============================================================================

set -euo pipefail

BACKUP_DIR="${1:-/home/ubuntu/backups/database}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

mkdir -p "$BACKUP_DIR"

echo "==> [1/3] Backing up PostgreSQL global roles & permissions..."
sudo -u postgres pg_dumpall --globals-only > "${BACKUP_DIR}/globals_${TIMESTAMP}.sql"

echo "==> [2/3] Querying active database list..."
DBS=$(sudo -u postgres psql -t -A -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname != 'postgres';")

for DB in $DBS; do
    echo "==> Backing up database: $DB..."
    sudo -u postgres pg_dump -d "$DB" -F c -b -v -f "${BACKUP_DIR}/${DB}_${TIMESTAMP}.dump"
    # Also keep plain SQL for easy inspection
    sudo -u postgres pg_dump -d "$DB" -F p > "${BACKUP_DIR}/${DB}_${TIMESTAMP}.sql"
done

echo "==> [3/3] Database backup complete! Files saved to $BACKUP_DIR"
ls -lh "$BACKUP_DIR"
