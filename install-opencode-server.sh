#!/bin/sh

if ! command -v opencode >/dev/null 2>&1; then
    echo "opencode not installed. Run ./install-opencode.sh first."
    exit 1
fi

if ! systemctl --user is-active --quiet portless-proxy.service 2>/dev/null; then
    echo "Portless proxy not running. Run ./install-portless.sh first."
    exit 1
fi

mkdir -p ~/.local/bin

cat > ~/.local/bin/opencode-serve-portless << 'EOF'
#!/bin/sh
exec opencode serve --hostname 127.0.0.1 --port "${PORT:-4096}"
EOF

chmod +x ~/.local/bin/opencode-serve-portless

mkdir -p ~/.config/systemd/user

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

systemctl --user daemon-reload
systemctl --user enable opencode-server.service
systemctl --user start opencode-server.service

echo "http://opencode.localhost:1355"
