#!/usr/bin/env bash
# Install Nerd Fonts system-wide from the official ryanoasis/nerd-fonts releases.
# Fedora doesn't package a 'nerd-fonts' meta, so we pull the specific archives.
# Edit FONTS to change which families are baked into the image.
set -euxo pipefail

FONTS=(
  FiraCode
  JetBrainsMono
  NerdFontsSymbolsOnly
)

DEST="/usr/share/fonts/nerd-fonts"
mkdir -p "$DEST"

VERSION="$(curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest \
  | grep -Eo '"tag_name":\s*"[^"]+"' | head -1 | grep -Eo 'v[0-9.]+')"
echo "Nerd Fonts version: ${VERSION}"

for font in "${FONTS[@]}"; do
  url="https://github.com/ryanoasis/nerd-fonts/releases/download/${VERSION}/${font}.tar.xz"
  echo "Fetching ${font} ..."
  curl -fsSL "$url" -o "/tmp/${font}.tar.xz"
  mkdir -p "$DEST/${font}"
  tar -xf "/tmp/${font}.tar.xz" -C "$DEST/${font}"
  rm -f "/tmp/${font}.tar.xz"
done

# Refresh the font cache so the glyphs are available at runtime.
fc-cache -f "$DEST" || true
