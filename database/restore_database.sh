#!/usr/bin/env bash
# ==============================================================================
# DATABASE ENGINE: RESTORE ROLES & SPECIFIC DATABASE
# Usage: bash database/restore_database.sh <db_name> <sql_or_dump_file>
# ==============================================================================

set -euo pipefail

DB_NAME="${1:-}"
FILE_PATH="${2:-}"

if [ -z "$DB_NAME" ] || [ -z "$FILE_PATH" ]; then
    echo "Usage: $0 <db_name> <sql_or_dump_file>"
    exit 1
fi

echo "==> Restoring database: $DB_NAME from $FILE_PATH..."

# Create database if not exists
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'" 2>/dev/null | grep -q 1; then
    sudo -u postgres psql -c "CREATE DATABASE \"${DB_NAME}\" OWNER erp;"
fi

# Enable essential extensions
sudo -u postgres psql -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS postgis;" || true
sudo -u postgres psql -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS unaccent;" || true
sudo -u postgres psql -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;" || true

# Restore file
if [[ "$FILE_PATH" == *.dump ]]; then
    sudo -u postgres pg_restore -d "$DB_NAME" --no-owner --role=erp -v "$FILE_PATH" || true
else
    sudo -u postgres psql -d "$DB_NAME" < "$FILE_PATH"
fi

echo "==> Database $DB_NAME restored successfully!"
