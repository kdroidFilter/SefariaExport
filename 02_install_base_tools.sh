#!/usr/bin/env bash
set -euo pipefail

if command -v apt-get >/dev/null 2>&1; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  elif [ "${EUID:-$(id -u)}" -eq 0 ]; then
    SUDO=""
  else
    echo "❌ sudo is required to install packages" >&2
    exit 1
  fi

  $SUDO apt-get update -y
  $SUDO apt-get install -y --no-install-recommends aria2 ca-certificates tar zstd wget netcat-openbsd
  $SUDO apt-get clean
  $SUDO rm -rf /var/lib/apt/lists/*
fi
python3 -V || true
