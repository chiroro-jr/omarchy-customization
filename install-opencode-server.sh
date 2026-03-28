#!/bin/sh

# Install opencode server service with portless

# Check if opencode is installed
if ! command -v opencode >/dev/null 2>&1; then
    echo "opencode not installed. Run ./install-opencode.sh first."
    exit 1
fi

# Check if portless proxy system service is running
if ! systemctl is-active --quiet portless-proxy.service 2>/dev/null; then
    echo "Portless proxy system service is not running."
    echo "Run 'sudo ./install-portless.sh' first."
    exit 1
fi

# Create systemd user directory if needed
mkdir -p ~/.config/systemd/user

# Create the service file - run opencode directly on port 4096
# portless alias will be used to register it with the proxy
cat > ~/.config/systemd/user/opencode-server.service << 'EOF'
[Unit]
Description=OpenCode Server
After=network.target

[Service]
Type=simple
ExecStart=opencode serve --hostname 127.0.0.1 --port 4096
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

# Reload systemd user daemon
systemctl --user daemon-reload

# Enable the service to start on boot
systemctl --user enable opencode-server.service

# Start the service
systemctl --user start opencode-server.service

# Wait a moment for the service to start
sleep 2

# Register with portless proxy using alias
portless alias opencode 4096 --force

echo "OpenCode server service installed and started."
echo "Access at: https://opencode.localhost"
echo ""
echo "Manage with:"
echo "  systemctl --user status opencode-server.service"
echo "  systemctl --user stop opencode-server.service"
echo "  systemctl --user start opencode-server.service"
