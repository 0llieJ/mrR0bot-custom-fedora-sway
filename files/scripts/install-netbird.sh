#!/usr/bin/env bash
set -euxo pipefail

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

VERSION="$(curl -fsSL https://pkgs.netbird.io/releases/latest \
  | grep -Eo '"tag_name":\s*"v[0-9]+\.[0-9]+\.[0-9]+"' \
  | grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+')"

VERSION_NO_V="${VERSION#v}"

curl -L \
  "https://github.com/netbirdio/netbird/releases/download/${VERSION}/netbird_${VERSION_NO_V}_linux_${ARCH}.tar.gz" \
  -o /tmp/netbird.tar.gz

mkdir -p /tmp/netbird
tar -xzf /tmp/netbird.tar.gz -C /tmp/netbird

install -Dm0755 /tmp/netbird/netbird /usr/bin/netbird

cat >/usr/lib/systemd/system/netbird.service <<'EOF'
[Unit]
Description=NetBird client
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/netbird service run
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl enable netbird.service
