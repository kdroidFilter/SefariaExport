#!/usr/bin/env bash
set -euo pipefail

# Use MONGO_HOST from environment (mongodb for Docker, 127.0.0.1 for GitHub Actions)
MONGO_HOST="${MONGO_HOST:-127.0.0.1}"
MONGO_PORT="${MONGO_PORT:-27017}"

echo "🔍 Checking MongoDB at ${MONGO_HOST}:${MONGO_PORT}..."

for i in {1..60}; do
  if nc -z "${MONGO_HOST}" "${MONGO_PORT}"; then
    echo "✅ MongoDB reachable at ${MONGO_HOST}:${MONGO_PORT}"
    exit 0
  fi
  echo "⏳ Waiting for MongoDB... (attempt $i/60)"
  sleep 2
done
echo "❌ MongoDB not reachable in time" >&2
exit 1
