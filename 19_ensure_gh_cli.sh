#!/usr/bin/env bash
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    if command -v sudo >/dev/null 2>&1; then
      SUDO="sudo"
    elif [ "${EUID:-$(id -u)}" -eq 0 ]; then
      SUDO=""
    else
      echo "❌ sudo is required to install gh CLI" >&2
      exit 1
    fi

    $SUDO apt-get update -y
    $SUDO apt-get install -y gh
  else
    echo "❌ gh CLI not found and apt-get unavailable" >&2
    exit 1
  fi
fi
gh --version
