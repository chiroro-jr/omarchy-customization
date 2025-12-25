#!/bin/sh

# 1. Check if mise is installed
if ! command -v mise >/dev/null 2>&1; then
    echo "Mise not installed. Run ./install-mise.sh first."
    exit 1
fi

# 2. Check if bun is already installed
if command -v bun >/dev/null 2>&1; then
    echo "bun is already installed."
    exit 0
fi

# 'mise use' both installs the version and sets it in the global config
mise use --global bun@latest
