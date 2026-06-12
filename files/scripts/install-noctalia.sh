#!/usr/bin/env bash
# Install the Noctalia desktop shell (provides the noctalia-qs runtime).
# Tried as a script rather than in the dnf module so a packaging change upstream
# can't hard-fail the whole image build. Tries Terra first, then the community
# COPR, and warns (without failing) if neither has it.
set -uxo pipefail

if rpm -q noctalia-shell >/dev/null 2>&1; then
  echo "noctalia-shell already present"
  exit 0
fi

# Terra is already enabled by terra-release (installed in the dnf module).
if dnf install -y noctalia-shell; then
  echo "Installed noctalia-shell from Terra"
  exit 0
fi

echo "noctalia-shell not in Terra — trying the community COPR"
dnf install -y dnf-plugins-core || true
if dnf copr enable -y zhangyi6324/noctalia-shell && dnf install -y noctalia-shell; then
  echo "Installed noctalia-shell from COPR"
  exit 0
fi

echo "WARNING: could not install noctalia-shell from Terra or COPR — skipping." >&2
echo "         Image build continues; install Noctalia manually if needed." >&2
exit 0
