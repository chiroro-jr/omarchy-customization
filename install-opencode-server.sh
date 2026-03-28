#!/bin/sh

# Install opencode server service with portless

# Check if opencode is installed
if ! command -v opencode >/dev/null 2>&1; then
    echo "opencode not installed. Run ./install-opencode.sh first."
    exit 1
fi

# Check if portless proxy user service is running
if ! systemctl --user is-active --quiet portless-proxy.service 2>/dev/null; then
    echo "Portless proxy user service is not running."
    echo "Run './install-portless.sh' first."
    exit 1
fi

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

# Create the service file - depends on portless-proxy
cat > ~/.config/systemd/user/opencode-server.service << 'EOF'
[Unit]
Description=OpenCode Server
After=network.target portless-proxy.service
Requires=portless-proxy.service

[Service]
Type=simple
ExecStart=/usr/bin/portless opencode %h/.local/bin/opencode-serve-portless
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
echo "Access at: http://opencode.localhost:1355"
echo ""
echo "Manage with:"
echo "  systemctl --user status opencode-server.service"
echo "  systemctl --user stop opencode-server.service"
echo "  systemctl --user start opencode-server.service"
echo ""
echo "Dependencies: portless-proxy.service"
