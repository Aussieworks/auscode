#!/usr/bin/env bash
#
# → Use this on Linux for the FULL install (Steam + dedicated + manager). See repo README "Which install script".
#
# Full bootstrap: fetch auscode, install SteamCMD + Stormworks dedicated server (App 1247090),
# run install_manager.sh (venv + API/CLI only), generate servers.json, optional "press Enter to start".
#
# Prerequisites: bash, curl, python3, git OR unzip; sudo for apt/dnf steamcmd/wine when prompted.
# Linux dedicated server runs the Windows build via Wine (see install_manager.sh).
# Open firewall for the game port your server uses; anonymous Steam login is used for SteamCMD.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Aussieworks/auscode/main/install/bootstrap.sh | bash
#   curl ... | bash -s -- --install-root /opt/aus
#   bash install/bootstrap.sh [--force] [--install-root DIR]
# Python (same steps, stdlib only): bash install/bootstrap.sh --python [--install-root DIR ...]
#   or: python3 install/full_install.py [...]
# Env: AUSCODE_GIT_URL INSTALL_ROOT STEAM_APP_ID DEDICATED_DIR API_PORT API_URL SETUP_WINE
# Non-interactive / no TTY: set AUS_BOOTSTRAP_NONINTERACTIVE=1 or pass --install-root DIR (skips directory prompt).
# Piped curl|bash: clones auscode then runs install_manager.sh from the clone (no local repo needed).
#
set -euo pipefail

# Delegate to Python orchestrator when run from a checkout (full_install.py beside this file).
if [[ "${1:-}" == "--python" ]]; then
  shift
  _bs="${BASH_SOURCE[0]:-}"
  if [[ -z "${_bs}" || "${_bs}" == "-" ]]; then
    echo "error: --python cannot be used with piped curl|bash; save the repo or run: python3 install/full_install.py" >&2
    exit 1
  fi
  _here="$(cd "$(dirname "${_bs}")" && pwd)"
  if [[ ! -f "${_here}/full_install.py" ]]; then
    echo "error: expected ${_here}/full_install.py (clone auscode and run from install/)." >&2
    exit 1
  fi
  exec python3 "${_here}/full_install.py" "$@"
fi

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "error: bootstrap.sh targets Linux (SteamCMD Linux build + Wine for the Windows dedicated server)." >&2
  exit 1
fi

FORCE="${FORCE:-0}"
FLAG_INSTALL_ROOT=0
_ENV_INSTALL_ROOT="${INSTALL_ROOT:-}"
INSTALL_ROOT=""
AUSCODE_GIT_URL="${AUSCODE_GIT_URL:-https://github.com/Aussieworks/auscode.git}"
STEAM_APP_ID="${STEAM_APP_ID:-1247090}"
API_PORT="${API_PORT:-8000}"
API_URL="${API_URL:-http://127.0.0.1:${API_PORT}}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE=1
      shift
      ;;
    --install-root)
      INSTALL_ROOT="$2"
      FLAG_INSTALL_ROOT=1
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

_DEFAULT_IR="${HOME}/.local/opt/aus"
if [[ "${FLAG_INSTALL_ROOT}" -eq 1 ]]; then
  :
elif [[ -t 0 ]] && [[ "${AUS_BOOTSTRAP_NONINTERACTIVE:-}" != "1" ]]; then
  echo "=== Aus full bootstrap ==="
  _prompt_def="${_ENV_INSTALL_ROOT:-${_DEFAULT_IR}}"
  read -r -p "Install directory (venv, Steam dedicated, config) [${_prompt_def}]: " _ir_answer
  INSTALL_ROOT="${_ir_answer:-${_prompt_def}}"
else
  INSTALL_ROOT="${_ENV_INSTALL_ROOT:-${_DEFAULT_IR}}"
fi

INSTALL_ROOT="$(readlink -f -m "${INSTALL_ROOT}")"
DEDICATED_DIR="${DEDICATED_DIR:-${INSTALL_ROOT}/stormworks-dedicated}"
DEDICATED_DIR="$(readlink -f -m "${DEDICATED_DIR}")"
REPO_PARENT="${INSTALL_ROOT}/src"
REPO_ROOT="${REPO_ROOT:-${REPO_PARENT}/auscode}"

echo "=== Aus full bootstrap ==="
echo "INSTALL_ROOT=${INSTALL_ROOT}"
echo "DEDICATED_DIR=${DEDICATED_DIR}"
echo "REPO_ROOT=${REPO_ROOT}"
echo ""

mkdir -p "${REPO_PARENT}" "${DEDICATED_DIR}" "${INSTALL_ROOT}/steamcmd"

# --- Fetch auscode ---
if [[ -d "${REPO_ROOT}/.git" ]] || [[ -f "${REPO_ROOT}/backend/server_manager.py" ]] || [[ -f "${REPO_ROOT}/auscode/auscode/server_manager.py" ]] || [[ -f "${REPO_ROOT}/auscode/server_manager.py" ]]; then
  echo "auscode checkout already present at ${REPO_ROOT}"
else
  if command -v git >/dev/null 2>&1; then
    echo "Cloning ${AUSCODE_GIT_URL} ..."
    git clone --depth 1 "${AUSCODE_GIT_URL}" "${REPO_ROOT}"
  else
    if ! command -v unzip >/dev/null 2>&1; then
      echo "error: install git or unzip to fetch auscode without git." >&2
      exit 1
    fi
    echo "git not found; downloading GitHub archive (main branch)..."
    TMP_ZIP="$(mktemp)"
    curl -fsSL -o "${TMP_ZIP}" "https://github.com/Aussieworks/auscode/archive/refs/heads/main.zip"
    unzip -q -o "${TMP_ZIP}" -d "${REPO_PARENT}"
    rm -f "${TMP_ZIP}"
    if [[ -d "${REPO_PARENT}/auscode-main" ]]; then
      mv "${REPO_PARENT}/auscode-main" "${REPO_ROOT}"
    else
      echo "error: unexpected zip layout under ${REPO_PARENT}" >&2
      exit 1
    fi
  fi
fi

if [[ ! -f "${REPO_ROOT}/backend/server_manager.py" ]] && [[ ! -f "${REPO_ROOT}/auscode/auscode/server_manager.py" ]] && [[ ! -f "${REPO_ROOT}/auscode/server_manager.py" ]]; then
  echo "error: server_manager.py not found under ${REPO_ROOT} (expected backend/, auscode/auscode/, or auscode/)" >&2
  exit 1
fi
if [[ ! -f "${REPO_ROOT}/install/install_manager.sh" ]]; then
  echo "error: ${REPO_ROOT}/install/install_manager.sh missing — use a full auscode tree (includes install/)." >&2
  exit 1
fi

# --- SteamCMD ---
STEAMCMD_BIN=""
if command -v steamcmd >/dev/null 2>&1; then
  STEAMCMD_BIN="steamcmd"
elif [[ -x "${INSTALL_ROOT}/steamcmd/steamcmd.sh" ]]; then
  STEAMCMD_BIN="${INSTALL_ROOT}/steamcmd/steamcmd.sh"
else
  echo "Installing SteamCMD into ${INSTALL_ROOT}/steamcmd ..."
  curl -fsSL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" \
    -o "${INSTALL_ROOT}/steamcmd/steamcmd_linux.tar.gz"
  tar -xzf "${INSTALL_ROOT}/steamcmd/steamcmd_linux.tar.gz" -C "${INSTALL_ROOT}/steamcmd"
  STEAMCMD_BIN="${INSTALL_ROOT}/steamcmd/steamcmd.sh"
fi

echo "Downloading / updating dedicated server (App ${STEAM_APP_ID}) to ${DEDICATED_DIR} ..."
"${STEAMCMD_BIN}" +force_install_dir "${DEDICATED_DIR}" +login anonymous +app_update "${STEAM_APP_ID}" validate +quit

# --- Aus manager (Wine on Linux for Windows exe) ---
export REPO_ROOT
export AUS_NONINTERACTIVE=1
export AUS_SKIP_DEFAULT_SERVERS_JSON=1
export INSTALL_ROOT
export API_URL
export API_PORT
if [[ "$(uname -s)" == "Linux" ]]; then
  export SETUP_WINE="${SETUP_WINE:-yes}"
else
  export SETUP_WINE="${SETUP_WINE:-no}"
fi

echo "Running install_manager.sh ..."
bash "${REPO_ROOT}/install/install_manager.sh"

export FORCE="${FORCE}"
export INSTALL_ROOT
export DEDICATED_DIR
bash "${REPO_ROOT}/install/generate_servers_json.sh"

echo ""
echo "Bootstrap complete."
echo "  start-aus:  ${INSTALL_ROOT}/bin/start-aus"
echo "  stop-aus:   ${INSTALL_ROOT}/bin/stop-aus"
echo ""

if [[ -t 0 ]] && [[ "${AUS_BOOTSTRAP_NO_PAUSE:-}" != "1" ]]; then
  read -r -p "Press Enter to run start-aus now (API + server 1), or Ctrl-C to exit: " _
  exec "${INSTALL_ROOT}/bin/start-aus"
fi
