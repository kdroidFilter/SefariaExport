#!/usr/bin/env bash
set -euo pipefail

# Load timestamp
TS_ENV_FILE="${GITHUB_WORKSPACE:-$PWD}/ts_env.sh"
if [ -f "${TS_ENV_FILE}" ]; then
  source "${TS_ENV_FILE}"
fi

cd "${GITHUB_WORKSPACE:-$PWD}"

# Create releases directory if it doesn't exist
mkdir -p releases

: "${TS_STAMP:?TS_STAMP not set. Run 01_compute_timestamp.sh first}"
COMBINED="releases/sefaria-exports-${TS_STAMP}.tar.zst"

# Verify that the exports directory contains files
FILE_COUNT=$(find exports -type f 2>/dev/null | wc -l)
echo "📊 Found ${FILE_COUNT} files in exports/"

if [ "${FILE_COUNT}" -eq 0 ]; then
  echo "❌ No files found in exports directory!"
  exit 1
fi

# Archive all the contents of the exports directory
echo "📦 Creating archive from exports/ directory..."
tar -cf - -C exports . | zstd --ultra -22 -T0 -o "${COMBINED}"

ls -lh "${COMBINED}"
echo "✅ Archive created: ${COMBINED}"
