#!/usr/bin/env bash
set -euo pipefail

# Load timestamp
TS_ENV_FILE="${GITHUB_WORKSPACE:-$PWD}/ts_env.sh"
if [ -f "${TS_ENV_FILE}" ]; then
  source "${TS_ENV_FILE}"
fi

: "${TS_STAMP:?TS_STAMP not set. Run 01_compute_timestamp.sh first}"
COMBINED="releases/sefaria-exports-${TS_STAMP}.tar.zst"

if [ ! -f "${COMBINED}" ]; then
  echo "❌ Archive not found: ${COMBINED}"
  exit 1
fi

FILE_SIZE=$(stat -c%s "${COMBINED}")
echo "📊 Archive size: ${FILE_SIZE} bytes ($(numfmt --to=iec-i --suffix=B ${FILE_SIZE}))"

# Si < 1.9GB, pas besoin de split
if [ "${FILE_SIZE}" -lt 1900000000 ]; then
  echo "✅ File is small enough, no splitting needed"
else
  echo "✂️  Splitting into parts..."
  split -b 1900m -d -a 2 "${COMBINED}" "${COMBINED}.part-"
  rm "${COMBINED}"  # Supprimer l'original après split
  ls -lh "${COMBINED}".part-*
fi
