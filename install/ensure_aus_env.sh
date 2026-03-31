#!/usr/bin/env bash
# Write INSTALL_ROOT/aus.env so you can:  source INSTALL_ROOT/aus.env
# Use when you skipped re-running install_manager after aus.env was added, or moved INSTALL_ROOT.
# Usage: bash install/ensure_aus_env.sh [INSTALL_ROOT]
set -euo pipefail
INSTALL_ROOT="${1:-${INSTALL_ROOT:-${HOME}/.local/opt/aus}}"
INSTALL_ROOT="$(readlink -f -m "${INSTALL_ROOT}")"
if [[ ! -d "${INSTALL_ROOT}/bin" ]]; then
  echo "error: ${INSTALL_ROOT}/bin not found — run install_manager.sh first or pass your real INSTALL_ROOT." >&2
  exit 1
fi
cat > "${INSTALL_ROOT}/aus.env" << EOF
# Aus manager — run once per shell:  source ${INSTALL_ROOT}/aus.env
export PATH="${INSTALL_ROOT}/bin:\${PATH}"
EOF
echo "Wrote ${INSTALL_ROOT}/aus.env — run:  source ${INSTALL_ROOT}/aus.env"
