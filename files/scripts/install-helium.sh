#!/usr/bin/env bash
# Install the Helium browser (Chromium-based). There is no Fedora rpm, so we
# fetch the official Linux tarball from imputnet/helium-linux and install it
# into /opt with a /usr/bin launcher and a desktop entry.
set -euxo pipefail

case "$(uname -m)" in
  x86_64|amd64) ARCH="x86_64" ;;
  aarch64|arm64) ARCH="aarch64" ;;
  *) echo "Unsupported architecture for Helium: $(uname -m)" >&2; exit 1 ;;
esac

# Pick the latest non-AppImage tarball asset for this architecture.
URL="$(curl -fsSL https://api.github.com/repos/imputnet/helium-linux/releases/latest \
  | grep -Eo 'https://[^"]+\.tar\.(xz|gz)' \
  | grep -i "$ARCH" \
  | grep -vi appimage \
  | head -1)"

if [ -z "$URL" ]; then
  echo "Could not find a Helium ${ARCH} tarball in the latest release" >&2
  exit 1
fi

curl -fsSL "$URL" -o /tmp/helium.tar
rm -rf /opt/helium
mkdir -p /opt/helium
tar -xf /tmp/helium.tar -C /opt/helium
rm -f /tmp/helium.tar

# Find the launcher binary inside whatever directory layout the tarball uses.
BIN="$(find /opt/helium -type f -name helium -perm -u+x | head -1)"
[ -n "$BIN" ] || BIN="$(find /opt/helium -type f -name chrome -perm -u+x | head -1)"
if [ -z "$BIN" ]; then
  echo "Helium binary not found after extraction" >&2
  exit 1
fi
ln -sf "$BIN" /usr/bin/helium

cat >/usr/share/applications/helium.desktop <<EOF
[Desktop Entry]
Name=Helium
Comment=Private, fast, and honest web browser
Exec=/usr/bin/helium %U
Icon=helium
Type=Application
Terminal=false
Categories=Network;WebBrowser;
StartupWMClass=helium
EOF
