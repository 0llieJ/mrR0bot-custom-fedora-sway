#!/usr/bin/env bash
# Bake the official ProtonVPN CLI into the image.
#
# Why this is non-trivial: proton-vpn-cli pulls proton-vpn-daemon, whose rpm
# scriptlet runs `systemctl` against a live system bus. During an image build
# there's no running systemd, so the scriptlet fails and aborts the whole dnf
# transaction (same failure NetBird's rpm had).
#
# Fix: temporarily stub `systemctl` with a no-op so the scriptlet "succeeds",
# install, then restore the real systemctl and enable the daemon's units the
# offline way (symlink creation works fine at build time). A trap guarantees the
# real systemctl is restored even if the install fails — never ship a stub.
#
# The Proton repo itself is baked separately (files/system/.../protonvpn-stable.repo)
# and uses $releasever, so the CLI always resolves to the latest.
set -uxo pipefail

SYSCTL="/usr/bin/systemctl"
STUBBED=0

restore_systemctl() {
    if [ "$STUBBED" = 1 ] && [ -e "${SYSCTL}.real" ]; then
        mv -f "${SYSCTL}.real" "$SYSCTL"
        STUBBED=0
    fi
}
trap restore_systemctl EXIT

# --- stub systemctl ----------------------------------------------------------
if [ -e "$SYSCTL" ] && [ ! -e "${SYSCTL}.real" ]; then
    mv "$SYSCTL" "${SYSCTL}.real"
    printf '#!/bin/sh\nexit 0\n' > "$SYSCTL"
    chmod +x "$SYSCTL"
    STUBBED=1
fi

# --- install (best-effort; never break the whole build) ----------------------
if ! dnf install -y proton-vpn-cli; then
    echo "WARNING: proton-vpn-cli failed to install — skipping." >&2
    exit 0
fi

# --- restore real systemctl before enabling units ---------------------------
restore_systemctl

# --- enable the daemon's units the offline way -------------------------------
# proton-vpn-daemon ships system services it wants enabled at boot; with the
# stub in place during install those symlinks weren't created, so do it now.
units="$(rpm -ql proton-vpn-daemon 2>/dev/null \
    | grep -E '/lib/systemd/system/[^/]+\.service$' \
    | xargs -r -n1 basename 2>/dev/null || true)"
for u in $units; do
    systemctl enable "$u" 2>/dev/null || true
done

echo "Installed proton-vpn-cli and enabled: ${units:-<none found>}"
