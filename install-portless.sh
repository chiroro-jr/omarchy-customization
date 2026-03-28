#!/bin/sh

# This script must be run with sudo to create the system service on port 443
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run with sudo to set up portless proxy on port 443"
    echo "Run: sudo ./install-portless.sh"
    exit 1
fi

# Install portless package
yay -S --needed --noconfirm portless-bin

# Create system service for portless proxy on port 443
cat > /etc/systemd/system/portless-proxy.service << 'EOF'
[Unit]
Description=Portless Proxy (HTTPS on port 443)
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/portless proxy start --https --port 443 --foreground
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd daemon
systemctl daemon-reload

# Enable and start the proxy service
systemctl enable portless-proxy.service
systemctl start portless-proxy.service

echo "Portless proxy installed and running on https://*.localhost (port 443)"
echo ""
echo "Manage with:"
echo "  sudo systemctl status portless-proxy.service"
echo "  sudo systemctl stop portless-proxy.service"
echo "  sudo systemctl start portless-proxy.service"
echo ""
echo "Next: Run ./install-opencode-server.sh as your normal user"
