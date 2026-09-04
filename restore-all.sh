#!/usr/bin/env bash
# ==============================================================================
# DISASTER RECOVERY: 1-CLICK RESTORE ALL REGISTERED PROJECTS
# Usage: 
#   bash restore-all.sh                # Restores all projects in projects/*.json
#   bash restore-all.sh parking-hcm    # Restores specific project
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared helpers
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/common.sh"

TARGET_PROJECT="${1:-all}"

echo "=================================================================="
echo "🚀 1-CLICK DISASTER RECOVERY RESTORATION"
echo "Target: ${TARGET_PROJECT} | Runtime User: ${APP_USER}"
echo "=================================================================="

if [ "$TARGET_PROJECT" != "all" ]; then
    bash "${SCRIPT_DIR}/restore.sh" "$TARGET_PROJECT"
else
    for REGISTRY in "${SCRIPT_DIR}/projects"/*.json; do
        if [ -f "$REGISTRY" ]; then
            P_NAME=$(jq -r '.name' "$REGISTRY")
            log_step "Restoring project from registry: ${P_NAME}..."
            bash "${SCRIPT_DIR}/restore.sh" "$P_NAME" || {
                log_error "Failed to restore ${P_NAME}, continuing with next project..."
            }
        fi
    done
fi

echo "=================================================================="
echo "🩺 RUNNING POST-RESTORE SYSTEM AUDIT..."
echo "=================================================================="
bash "${SCRIPT_DIR}/doctor.sh" || true

echo "=================================================================="
echo "🎉 RESTORATION PIPELINE COMPLETED!"
echo "=================================================================="
