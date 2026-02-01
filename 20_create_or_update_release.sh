#!/usr/bin/env bash
set -euo pipefail

# Load timestamp
TS_ENV_FILE="${GITHUB_WORKSPACE:-$PWD}/ts_env.sh"
if [ -f "${TS_ENV_FILE}" ]; then
  source "${TS_ENV_FILE}"
fi

# Skip if no GH_TOKEN (optional for local Docker runs)
if [ -z "${GH_TOKEN:-}" ]; then
  echo "⏭️  Skipping GitHub release creation (GH_TOKEN not set)"
  echo "   This is normal for local Docker runs."
  exit 0
fi

: "${TS_STAMP:?TS_STAMP not set. Run 01_compute_timestamp.sh first}"
TAG="${TS_STAMP}"
TITLE="Sefaria Export ${TS_STAMP}"
NOTES=$(cat <<EOF
Combined Sefaria exports (zstd --ultra -22 -T0).

Restore:
  # if split into parts
  cat sefaria-exports-${TS_STAMP}.tar.zst.part-* > combined.tar.zst && tar --zstd -xf combined.tar.zst
  # if single file
  tar --zstd -xf sefaria-exports-${TS_STAMP}.tar.zst
EOF
)

# Create the release if it does not exist
if ! gh release view "$TAG" >/dev/null 2>&1; then
  gh release create "$TAG" -t "$TITLE" -n "$NOTES"
fi
