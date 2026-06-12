#!/usr/bin/env bash
# Bake the unix_setup repo (immutable branch) into the image at build time so the
# user-layer bootstrap is fully self-contained: no runtime git clone, and no
# drift between the image and a moving branch — the build freezes one commit.
#
# mrrobot-setup runs this baked copy. Override the source/ref if needed:
#   UNIX_SETUP_REPO, UNIX_SETUP_REF
set -euxo pipefail

REPO="${UNIX_SETUP_REPO:-https://github.com/0llieJ/unix_setup.git}"
REF="${UNIX_SETUP_REF:-immutable}"
DEST="/usr/share/mrrobot/unix_setup"

mkdir -p /usr/share/mrrobot
rm -rf "$DEST"
git clone --branch "$REF" --depth 1 "$REPO" "$DEST"

# Record the exact commit baked into the image for reproducibility/debugging.
git -C "$DEST" rev-parse HEAD > /usr/share/mrrobot/unix_setup.commit

# Drop version-control metadata to keep the image lean.
rm -rf "$DEST/.git"
