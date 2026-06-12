#!/usr/bin/env bash
# Bake the unix_setup repo into the image at build time so the user-layer
# bootstrap is fully self-contained: no runtime git clone, and the build freezes
# one commit. Atomic-specific behaviour is runtime-guarded in unix_setup, so the
# single main branch works on the image.
#
# mrrobot-setup runs this baked copy. Override the source/ref if needed:
#   UNIX_SETUP_REPO, UNIX_SETUP_REF
set -euxo pipefail

REPO="${UNIX_SETUP_REPO:-https://github.com/0llieJ/unix_setup.git}"
# Single branch now: atomic-specific behaviour is runtime-guarded in unix_setup,
# so main works on the image. Pin to a tag here for full reproducibility if wanted.
REF="${UNIX_SETUP_REF:-main}"
DEST="/usr/share/mrrobot/unix_setup"

mkdir -p /usr/share/mrrobot
rm -rf "$DEST"
git clone --branch "$REF" --depth 1 "$REPO" "$DEST"

# Record the exact commit baked into the image for reproducibility/debugging.
git -C "$DEST" rev-parse HEAD > /usr/share/mrrobot/unix_setup.commit

# Drop version-control metadata to keep the image lean.
rm -rf "$DEST/.git"
