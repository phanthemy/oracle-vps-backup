#!/usr/bin/env bash
# ==============================================================================
# DISASTER RECOVERY: RESTORE SPECIFIC PROJECT FROM REGISTRY
# Usage: bash restore.sh <project_name>
# Example: bash restore.sh parking-hcm
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="${1:-}"

if [ -z "$PROJECT_NAME" ]; then
    echo "❌ Usage: $0 <project_name>"
    echo "Available projects in registry:"
    ls -1 "${SCRIPT_DIR}/projects" | sed 's/\.json$//'
    exit 1
fi

REGISTRY_FILE="${SCRIPT_DIR}/projects/${PROJECT_NAME}.json"

if [ ! -f "$REGISTRY_FILE" ]; then
    echo "❌ Error: Project registry '$REGISTRY_FILE' not found!"
    exit 1
fi

echo "=================================================================="
echo "🚀 RESTORING PROJECT: $PROJECT_NAME"
echo "=================================================================="

REPO=$(jq -r '.repository' "$REGISTRY_FILE")
BRANCH=$(jq -r '.branch // "main"' "$REGISTRY_FILE")
ROOT_PATH=$(jq -r '.rootPath' "$REGISTRY_FILE")
PORT=$(jq -r '.pm2.port // "3000"' "$REGISTRY_FILE")
PM2_NAME=$(jq -r '.pm2.name // "'"$PROJECT_NAME"'"' "$REGISTRY_FILE")
CWD_PATH=$(jq -r '.pm2.cwd // "'"$ROOT_PATH"'"' "$REGISTRY_FILE")
BUILD_CMD=$(jq -r '.build.buildCmd // "npm run build"' "$REGISTRY_FILE")
INSTALL_CMD=$(jq -r '.build.installCmd // "npm install --production=false"' "$REGISTRY_FILE")
HEALTH_URL=$(jq -r '.healthCheck.url // "http://localhost:'"$PORT"'"' "$REGISTRY_FILE")
DB_NAME=$(jq -r '.database.name // ""' "$REGISTRY_FILE")

# 1. Sync git source safely (check .git directory & remote origin)
echo "==> [1/6] Syncing source code from $REPO (branch: $BRANCH)..."
if [ -d "$ROOT_PATH/.git" ]; then
    cd "$ROOT_PATH"
    CURRENT_ORIGIN=$(git config --get remote.origin.url || echo "")
    if [ "$CURRENT_ORIGIN" = "$REPO" ]; then
        echo "==> Repository origin matches. Fetching and checking out $BRANCH..."
        git fetch origin
        git checkout "$BRANCH"
        git pull origin "$BRANCH"
    else
        echo "⚠️ Warning: Directory exists but origin mismatch ($CURRENT_ORIGIN != $REPO). Re-cloning..."
        BACKUP_OLD="${ROOT_PATH}_backup_$(date +%Y%m%d_%H%M%S)"
        mv "$ROOT_PATH" "$BACKUP_OLD"
        git clone -b "$BRANCH" "$REPO" "$ROOT_PATH"
    fi
else
    mkdir -p "$(dirname "$ROOT_PATH")"
    git clone -b "$BRANCH" "$REPO" "$ROOT_PATH"
fi

chown -R ubuntu:ubuntu "$ROOT_PATH"

# 2. Setup Database if defined
if [ -n "$DB_NAME" ]; then
    echo "==> [2/6] Ensuring PostgreSQL Database '$DB_NAME' exists..."
    sudo -u postgres psql -c "
    DO \$\$
    BEGIN
      IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '${DB_NAME}') THEN
        CREATE DATABASE \"${DB_NAME}\" OWNER erp;
      END IF;
    END
    \$\$;
    " || true

    # Enable extensions
    sudo -u postgres psql -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS postgis;" || true
    sudo -u postgres psql -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS unaccent;" || true
    sudo -u postgres psql -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;" || true
fi

# 3. Install dependencies
echo "==> [3/6] Installing dependencies in $CWD_PATH..."
cd "$CWD_PATH"
su - ubuntu -c "cd '$CWD_PATH' && $INSTALL_CMD"

# 4. Build application
echo "==> [4/6] Building application ($BUILD_CMD)..."
su - ubuntu -c "cd '$CWD_PATH' && $BUILD_CMD"

# 5. Start / Restart PM2 (Idempotent check via pm2 describe)
echo "==> [5/6] Managing PM2 process '$PM2_NAME' on port $PORT..."
if su - ubuntu -c "pm2 describe '$PM2_NAME' >/dev/null 2>&1"; then
    echo "==> Process '$PM2_NAME' already registered in PM2. Restarting with updated env..."
    su - ubuntu -c "cd '$CWD_PATH' && PORT=$PORT pm2 restart '$PM2_NAME' --update-env"
else
    echo "==> Registering new PM2 process '$PM2_NAME'..."
    su - ubuntu -c "cd '$CWD_PATH' && PORT=$PORT pm2 start npm --name '$PM2_NAME' -- start"
fi
su - ubuntu -c "pm2 save"

# 6. Automated Health Check Verification with Retry Loop (30 retries x 2s = 60s max wait)
echo "==> [6/6] Running Automated Health Check on $HEALTH_URL (Retrying up to 30 times)..."

MAX_RETRIES=30
RETRY_DELAY=2
SUCCESS=false

for ((i=1; i<=MAX_RETRIES; i++)); do
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" 2>/dev/null || echo "000")
    if [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 400 ]; then
        echo "=================================================================="
        echo "✅ HEALTH CHECK PASSED! Project '$PROJECT_NAME' is UP (HTTP $HTTP_STATUS) at attempt $i."
        echo "=================================================================="
        SUCCESS=true
        break
    else
        echo "   [Attempt $i/$MAX_RETRIES] Response: HTTP $HTTP_STATUS. Waiting ${RETRY_DELAY}s..."
        sleep "$RETRY_DELAY"
    fi
done

if [ "$SUCCESS" = false ]; then
    echo "=================================================================="
    echo "❌ HEALTH CHECK TIMEOUT FOR '$PROJECT_NAME' (HTTP $HTTP_STATUS on $HEALTH_URL)"
    echo "=================================================================="
    su - ubuntu -c "pm2 logs '$PM2_NAME' --lines 30 --nostream"
    exit 1
fi
