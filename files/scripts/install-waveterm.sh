#!/usr/bin/env bash
# Install Wave Terminal (block-based terminal w/ AI, workspaces, split panes).
# Not on Flathub; uses the official .rpm from wavetermdev/waveterm releases.
# Best-effort: a bad upstream release won't hard-fail the whole image build.
set -uxo pipefail

case "$(uname -m)" in
  x86_64|amd64) ARCH="x86_64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture for Wave Terminal: $(uname -m)" >&2; exit 0 ;;
esac

URL="$(curl -fsSL https://api.github.com/repos/wavetermdev/waveterm/releases/latest \
  | grep -Eo '"browser_download_url": *"[^"]+\.rpm"' \
  | grep -i "$ARCH" | grep -vi debug \
  | grep -Eo 'https://[^"]+' | head -1)"

if [ -z "$URL" ]; then
  echo "WARNING: no Wave Terminal rpm found for $ARCH — skipping." >&2
  exit 0
fi

curl -fsSL "$URL" -o /tmp/waveterm.rpm
if dnf install -y /tmp/waveterm.rpm; then
  echo "Installed Wave Terminal from $URL"
else
  echo "WARNING: Wave Terminal rpm failed to install — skipping." >&2
fi
rm -f /tmp/waveterm.rpm
exit 0
