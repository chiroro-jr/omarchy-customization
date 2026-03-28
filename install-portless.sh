#!/bin/sh

yay -S --needed --noconfirm portless-bin

# Enable HTTPS proxy (one-time setup)
portless proxy start --https 2>/dev/null || true
