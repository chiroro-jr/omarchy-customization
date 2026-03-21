#!/bin/bash
# Vite+ Uninstaller Script
# Removes vp and related Vite+ data from the machine

set -e

if ! command -v vp &> /dev/null; then
    exit 0
fi

vp implode
