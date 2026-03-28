#!/bin/sh

# Install opencode server service with portless

# Check if opencode is installed
if ! command -v opencode >/dev/null 2>&1; then
    echo "opencode not installed. Run ./install-opencode.sh first."
    exit 1
fi

# Check if portless is installed
if ! command -v portless >/dev/null 2>&1; then
    echo "portless not installed. Run ./install-portless.sh first."
    exit 1
fi

# Enable HTTPS proxy (one-time setup)
portless proxy start --https 2>/dev/null || true

# Create bin directory if needed
mkdir -p ~/.local/bin

# Create wrapper script that uses PORT env var
cat > ~/.local/bin/opencode-serve-portless << 'EOF'
#!/bin/sh
exec opencode serve --hostname 127.0.0.1 --port "${PORT:-4096}"
EOF

chmod +x ~/.local/bin/opencode-serve-portless

# Create systemd user directory if needed
mkdir -p ~/.config/systemd/user

# Create the service file
cat > ~/.config/systemd/user/opencode-server.service << 'EOF'
[Unit]
Description=OpenCode Server with Portless
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/portless opencode /home/dennis/.local/bin/opencode-serve-portless
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

# Reload systemd user daemon
systemctl --user daemon-reload

# Enable the service to start on boot
systemctl --user enable opencode-server.service

# Start the service now
systemctl --user start opencode-server.service

echo "OpenCode server service installed and started."
echo "Access at: https://opencode.localhost"
echo ""
echo "Manage with:"
echo "  systemctl --user status opencode-server.service"
echo "  systemctl --user stop opencode-server.service"
echo "  systemctl --user start opencode-server.service"
