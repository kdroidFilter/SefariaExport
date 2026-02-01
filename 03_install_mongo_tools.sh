#!/usr/bin/env bash
set -euo pipefail

TOOLS_VER="100.9.4"
if command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
elif [ "${EUID:-$(id -u)}" -eq 0 ]; then
  SUDO=""
else
  echo "❌ sudo is required to install MongoDB tools" >&2
  exit 1
fi
if ! command -v mongorestore >/dev/null 2>&1; then
  wget -q "https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu2204-x86_64-${TOOLS_VER}.tgz"
  tar -xzf "mongodb-database-tools-ubuntu2204-x86_64-${TOOLS_VER}.tgz"
  $SUDO mv "mongodb-database-tools-ubuntu2204-x86_64-${TOOLS_VER}/bin"/* /usr/local/bin/
fi
mongorestore --version
