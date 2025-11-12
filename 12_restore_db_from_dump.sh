#!/usr/bin/env bash
set -euo pipefail

# Configurable via env, with sensible defaults
MONGO_HOST=${MONGO_HOST:-127.0.0.1}
MONGO_PORT=${MONGO_PORT:-27017}
MONGO_DB_NAME=${MONGO_DB_NAME:-sefaria}

# How to handle index restoration:
#   all        -> restore all indexes via metadata-only pass
#   skip_links -> restore all indexes EXCEPT for the heavy sefaria.links indexes (default)
#   none       -> do not restore any indexes (data only)
RESTORE_INDEXES_MODE=${RESTORE_INDEXES_MODE:-skip_links}

echo "📦 Preparing to restore MongoDB dump"
echo "   Host: ${MONGO_HOST}:${MONGO_PORT}"
echo "   DB  : ${MONGO_DB_NAME}"
echo "   Index mode: ${RESTORE_INDEXES_MODE} (override with RESTORE_INDEXES_MODE=all|skip_links|none)"

if [ ! -d mongo_dump_pkg/sefaria ]; then
  echo "❌ mongo_dump_pkg/sefaria not found"; exit 1
fi

# Phase 1: Restore DATA ONLY (no indexes) to avoid long-running index builds during import
echo "▶️  Restoring data (no indexes)..."
mongorestore \
  --host "${MONGO_HOST}" \
  --port "${MONGO_PORT}" \
  --drop \
  --db "${MONGO_DB_NAME}" \
  --noIndexRestore \
  "mongo_dump_pkg/sefaria"

echo "✅ Data restore completed."

# Phase 2: Optionally restore metadata (indexes) with exclusions to avoid timeouts on heavy collections
case "${RESTORE_INDEXES_MODE}" in
  all)
    echo "▶️  Restoring metadata (indexes) for all collections..."
    mongorestore \
      --host "${MONGO_HOST}" \
      --port "${MONGO_PORT}" \
      --db "${MONGO_DB_NAME}" \
      --metadataOnly \
      "mongo_dump_pkg/sefaria"
    echo "✅ Index metadata restored for all collections."
    ;;
  skip_links)
    echo "▶️  Restoring metadata (indexes) for all collections EXCEPT '${MONGO_DB_NAME}.links'..."
    mongorestore \
      --host "${MONGO_HOST}" \
      --port "${MONGO_PORT}" \
      --db "${MONGO_DB_NAME}" \
      --metadataOnly \
      --nsExclude "${MONGO_DB_NAME}.links" \
      "mongo_dump_pkg/sefaria"
    echo "✅ Index metadata restored (links collection skipped)."
    ;;
  none)
    echo "⏭️  Skipping index restoration as requested (RESTORE_INDEXES_MODE=none)."
    ;;
  *)
    echo "⚠️  Unknown RESTORE_INDEXES_MODE='${RESTORE_INDEXES_MODE}'. Use one of: all | skip_links | none" >&2
    exit 2
    ;;
esac

# Ensure 'history' collection exists (some exports expect it)
python ./ensure_history_collection.py

echo "✅ Mongo restore complete."
