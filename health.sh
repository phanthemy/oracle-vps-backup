#!/usr/bin/env bash
# ==============================================================================
# GET /health — Lightweight health endpoint
# Returns JSON: {"status":"ok","time":"ISO8601"}
# Usage: bash health.sh
# Can be served via: curl localhost:PORT/health or as CGI endpoint
# ==============================================================================

set -euo pipefail

echo '{"status":"ok","time":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"}'
