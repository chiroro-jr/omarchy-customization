#!/bin/sh

if ! command -v pnpm >/dev/null 2>&1; then
    echo "pnpm not installed. Run ./install-pnpm.sh first."
    exit 1
fi

pnpm install -g @mariozechner/pi-coding-agent
