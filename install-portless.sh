#!/bin/sh

yay -S --needed --noconfirm portless-bin

# Create systemd user directory if needed
mkdir -p ~/.config/systemd/user

# Create portless proxy user service
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

# Reload systemd user daemon
systemctl --user daemon-reload

# Enable and start the proxy service
systemctl --user enable portless-proxy.service
systemctl --user start portless-proxy.service

echo "Portless proxy installed and started."
echo "Running on http://localhost:1355"
echo ""
echo "Manage with:"
echo "  systemctl --user status portless-proxy.service"
echo "  systemctl --user stop portless-proxy.service"
echo "  systemctl --user start portless-proxy.service"
