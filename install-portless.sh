#!/bin/sh

yay -S --needed --noconfirm portless-bin

mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/portless-proxy.service << 'EOF'
[Unit]
Description=Portless Proxy
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/portless proxy start --foreground
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable portless-proxy.service
systemctl --user start portless-proxy.service
