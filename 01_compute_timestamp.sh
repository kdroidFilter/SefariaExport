#!/usr/bin/env bash
set -euo pipefail

# Compute release timestamp
BASE_DIR="${GITHUB_WORKSPACE:-$PWD}"
TS_FILE="${BASE_DIR}/ts.txt"
TS_ENV_FILE="${BASE_DIR}/ts_env.sh"

TZ="${TZ_NAME:-Asia/Jerusalem}" date '+%Y-%m-%d_%H-%M' > "${TS_FILE}"

# Export for Docker environment (not GitHub Actions)
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "stamp=$(cat "${TS_FILE}")" >> "${GITHUB_OUTPUT}"
else
  # For Docker: export to environment file
  echo "export TS_STAMP=$(cat "${TS_FILE}")" > "${TS_ENV_FILE}"
  export TS_STAMP=$(cat "${TS_FILE}")
  echo "✅ Timestamp: ${TS_STAMP}"
fi
