#!/usr/bin/env bash
# ==============================================================================
# DISASTER RECOVERY: RESTORE SPECIFIC PROJECT FROM REGISTRY
# Target: Portable across Oracle Cloud, VMware, Hetzner, Vultr, DigitalOcean
# Usage: bash restore.sh <project_name>
# Example: bash restore.sh parking-hcm
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared helpers
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/common.sh"

# Load secrets from all standard locations if present
for sec in "${SCRIPT_DIR}/secrets.env" "${SCRIPT_DIR}/../secrets.env" /etc/secrets.env "${APP_HOME}/.secrets.env" "${HOME}/.secrets.env"; do
    if [ -f "$sec" ]; then
        # shellcheck disable=SC1090
        source "$sec"
    fi
done

PROJECT_NAME="${1:-}"

if [ -z "$PROJECT_NAME" ]; then
    log_error "Usage: $0 <project_name>"
    echo "Available projects in registry:"
    ls -1 "${SCRIPT_DIR}/projects" | sed 's/\.json$//'
    exit 1
fi

REGISTRY_FILE="${SCRIPT_DIR}/projects/${PROJECT_NAME}.json"

if [ ! -f "$REGISTRY_FILE" ]; then
    log_error "Project registry '$REGISTRY_FILE' not found!"
    exit 1
fi

echo "=================================================================="
echo "🚀 RESTORING PROJECT: $PROJECT_NAME (Target User: $APP_USER)"
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

# Enable passwordless SSH clone if SSH key is available
export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"

# Convert HTTPS to SSH URL format
SSH_REPO_URL=$(echo "$REPO" | sed -E 's|^https://github.com/|git@github.com:|')

# Check if SSH key exists in common locations (root, current user or app user)
HAS_SSH_KEY=false
for key in /root/.ssh/id_rsa /root/.ssh/id_ed25519 "${APP_HOME}/.ssh/id_rsa" "${APP_HOME}/.ssh/id_ed25519" "${HOME}/.ssh/id_rsa" "${HOME}/.ssh/id_ed25519"; do
    if [ -f "$key" ]; then
        HAS_SSH_KEY=true
        break
    fi
done

GH_AUTH_TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"

if [ "$HAS_SSH_KEY" = true ]; then
    CLONE_URL="$SSH_REPO_URL"
    log_info "SSH Key detected. Using SSH clone: $CLONE_URL"
elif [ -n "$GH_AUTH_TOKEN" ]; then
    git config --global url."https://${GH_AUTH_TOKEN}@github.com/".insteadOf "https://github.com/" || true
    CLONE_URL="https://${GH_AUTH_TOKEN}@github.com/${REPO#https://github.com/}"
    log_info "GitHub Token configured. Using automated authenticated clone."
else
    CLONE_URL="$REPO"
fi

# 1. Sync git source safely (check .git directory & remote origin)
log_step "[1/6] Syncing source code (branch: $BRANCH)..."
if [ -d "$ROOT_PATH/.git" ]; then
    cd "$ROOT_PATH"
    git remote set-url origin "$CLONE_URL" 2>/dev/null || true
    git fetch origin
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
else
    mkdir -p "$(dirname "$ROOT_PATH")"
    if ! git clone -b "$BRANCH" "$CLONE_URL" "$ROOT_PATH"; then
        if [ "$CLONE_URL" != "$SSH_REPO_URL" ]; then
            log_warn "HTTPS clone failed, attempting SSH fallback ($SSH_REPO_URL)..."
            git clone -b "$BRANCH" "$SSH_REPO_URL" "$ROOT_PATH"
        fi
    fi
fi

chown -R "${APP_USER}:${APP_USER}" "$ROOT_PATH"

# 2. Setup Database & Environment Variables
if [ -n "$DB_NAME" ]; then
    log_step "[2/6] Ensuring PostgreSQL Database '$DB_NAME' exists..."
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

    # Ensure default .env exists with DATABASE_URL in ROOT_PATH and CWD_PATH
    for env_target in "${ROOT_PATH}/.env" "${CWD_PATH}/.env"; do
        if [ ! -f "$env_target" ]; then
            log_info "Creating production environment file ($env_target)..."
            cat << EOF > "$env_target"
DATABASE_URL="postgresql://erp:erp_dev_2026@localhost:5432/${DB_NAME}"
SPATIAL_DATABASE_URL="postgresql://erp:erp_dev_2026@localhost:5432/${DB_NAME}"
JWT_SECRET="${PROJECT_NAME}-secret-key-2026"
NEXT_PUBLIC_APP_URL="http://localhost:${PORT}"
NODE_ENV="production"
PORT=${PORT}
EOF
            chown "${APP_USER}:${APP_USER}" "$env_target"
        fi
    done
fi

# 3. Install dependencies (Root + CWD)
if [ "$ROOT_PATH" != "$CWD_PATH" ] && [ -f "${ROOT_PATH}/package.json" ]; then
    log_step "[3/6] Installing Monorepo root dependencies in $ROOT_PATH..."
    run_as_app_user "cd '$ROOT_PATH' && npm install --production=false" || true
fi

log_step "[3/6] Installing dependencies in $CWD_PATH..."
cd "$CWD_PATH"
run_as_app_user "cd '$CWD_PATH' && $INSTALL_CMD"

# 3.1 Database schema synchronization (Prisma ORM & PostgreSQL Init)
find "$ROOT_PATH" -name "schema.prisma" 2>/dev/null | while read -r p_schema; do
    p_dir="$(dirname "$(dirname "$p_schema")")"
    log_info "Synchronizing Prisma schema in $p_dir..."
    run_as_app_user "cd '$p_dir' && npx prisma db push --accept-data-loss" 2>/dev/null || true
    run_as_app_user "cd '$p_dir' && npx prisma generate" 2>/dev/null || true
    run_as_app_user "cd '$p_dir' && npx prisma db seed" 2>/dev/null || true
done

# Run quick seed scripts if present
for seed_script in seed-quick.js seed.js prisma/seed.js; do
    if [ -f "${CWD_PATH}/${seed_script}" ]; then
        log_info "Running seed script: ${seed_script}..."
        run_as_app_user "cd '$CWD_PATH' && node '${seed_script}'" 2>/dev/null || true
    fi
done

# 4. Build application (check if build script exists)
if [ "$BUILD_CMD" != "none" ] && [ -n "$BUILD_CMD" ]; then
    HAS_BUILD_SCRIPT=true
    if [ "$BUILD_CMD" = "npm run build" ]; then
        if [ -f "${CWD_PATH}/package.json" ] && ! jq -e '.scripts.build' "${CWD_PATH}/package.json" >/dev/null 2>&1; then
            HAS_BUILD_SCRIPT=false
        fi
    fi

    if [ "$HAS_BUILD_SCRIPT" = true ]; then
        log_step "[4/6] Building application ($BUILD_CMD)..."
        run_as_app_user "cd '$CWD_PATH' && DATABASE_URL='postgresql://erp:erp_dev_2026@localhost:5432/${DB_NAME}' SPATIAL_DATABASE_URL='postgresql://erp:erp_dev_2026@localhost:5432/${DB_NAME}' NODE_ENV=production $BUILD_CMD" || {
            log_warn "Build returned exit code, continuing to start..."
        }
    else
        log_info "No build script in package.json, skipping build step..."
    fi
fi

# 5. Start / Restart PM2 (Idempotent check via pm2 describe)
log_step "[5/6] Managing PM2 process '$PM2_NAME' on port $PORT..."
if run_as_app_user "pm2 describe '$PM2_NAME' >/dev/null 2>&1"; then
    log_info "Process '$PM2_NAME' already registered in PM2. Restarting with updated env..."
    run_as_app_user "cd '$CWD_PATH' && PORT=$PORT pm2 restart '$PM2_NAME' --update-env"
else
    log_info "Registering new PM2 process '$PM2_NAME'..."
    run_as_app_user "cd '$CWD_PATH' && PORT=$PORT pm2 start npm --name '$PM2_NAME' -- start"
fi
run_as_app_user "pm2 save"

# 6. Automated Health Check Verification with Retry Loop (30 retries x 2s = 60s max wait)
log_step "[6/6] Running Automated Health Check on $HEALTH_URL (Retrying up to 30 times)..."

MAX_RETRIES=30
RETRY_DELAY=2
SUCCESS=false

for ((i=1; i<=MAX_RETRIES; i++)); do
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" 2>/dev/null || echo "000")
    if [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 400 ]; then
        echo "=================================================================="
        log_success "HEALTH CHECK PASSED! Project '$PROJECT_NAME' is UP (HTTP $HTTP_STATUS) at attempt $i."
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
    log_error "HEALTH CHECK TIMEOUT FOR '$PROJECT_NAME' (HTTP $HTTP_STATUS on $HEALTH_URL)"
    echo "=================================================================="
    run_as_app_user "pm2 logs '$PM2_NAME' --lines 30 --nostream"
    exit 1
fi
