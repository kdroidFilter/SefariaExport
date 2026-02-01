#!/usr/bin/env bash
set -euo pipefail

# Load timestamp
TS_ENV_FILE="${GITHUB_WORKSPACE:-$PWD}/ts_env.sh"
if [ -f "${TS_ENV_FILE}" ]; then
  source "${TS_ENV_FILE}"
fi

# Skip if no GH_TOKEN (optional for local Docker runs)
if [ -z "${GH_TOKEN:-}" ]; then
  echo "⏭️  Skipping GitHub release upload (GH_TOKEN not set)"
  echo "   This is normal for local Docker runs."
  echo "   Your files are available in the releases/ directory."
  exit 0
fi

: "${TS_STAMP:?TS_STAMP not set. Run 01_compute_timestamp.sh first}"
TAG="${TS_STAMP}"
shopt -s nullglob

# Look for files in releases directory
cd releases 2>/dev/null || cd .

# Chercher les fichiers à uploader
FILES=( "sefaria-exports-${TS_STAMP}.tar.zst.part-"* )
if [ "${#FILES[@]}" -eq 0 ]; then
  FILES=( "sefaria-exports-${TS_STAMP}.tar.zst" )
fi

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "❌ No files to upload!"
  exit 1
fi

echo "📤 Found ${#FILES[@]} file(s) to upload"

for f in "${FILES[@]}"; do
  echo "Uploading: $f ($(stat -c%s "$f" | numfmt --to=iec-i --suffix=B))"
  for attempt in {1..5}; do
    if gh release upload "$TAG" "$f" --clobber; then
      echo "✅ Uploaded: $f"
      break
    fi
    sleep $((2**attempt))
    echo "🔄 Retry $attempt for $f..."
    if [[ $attempt -eq 5 ]]; then
      echo "❌ Failed to upload $f after 5 attempts"
      exit 1
    fi
  done
done

echo "✅ All files uploaded successfully"
