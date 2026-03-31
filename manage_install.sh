#!/usr/bin/env bash
# Aus manager install helper (repo root).
#   ./manage_install.sh              → full install (install/install_manager.sh)
#   ./manage_install.sh --aus-env    → only write INSTALL_ROOT/aus.env (default ~/.local/opt/aus)
#   ./manage_install.sh --aus-env /path/to/aus
set -euo pipefail
_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "${1:-}" == "--aus-env" ]] || [[ "${1:-}" == "--env-only" ]]; then
  shift
  exec bash "${_REPO_ROOT}/install/ensure_aus_env.sh" "$@"
fi
exec bash "${_REPO_ROOT}/install/install_manager.sh" "$@"
