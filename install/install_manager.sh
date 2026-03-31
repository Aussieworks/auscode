#!/usr/bin/env bash
# → Manager ONLY (venv + API/CLI). Use bootstrap.sh / full_install.py if you need Steam + dedicated too.
# Run from repo root: bash install/install_manager.sh   OR   ./manage_install.sh
# Missing aus.env only:  ./manage_install.sh --aus-env   OR   bash install/ensure_aus_env.sh
# Run from this dir:  bash ./install_manager.sh  (NOT bash install/install_manager.sh)
# See install/README.md "Which script?"
#
# Aus server manager only: Python venv, aus CLI, aus-server wrapper scripts under INSTALL_ROOT.
# Do not install INSTALL_ROOT inside the Steam game folder — use a separate path (e.g. ~/.local/opt/aus)
# and point servers.json at the dedicated server. Wine prefix needs disk space (~1GB+).
#
# Non-interactive: set AUS_NONINTERACTIVE=1 and export INSTALL_ROOT, API_URL, API_PORT,
# SETUP_WINE (yes/no), REPO_ROOT (path to auscode repo root). Optional: AUS_SKIP_DEFAULT_SERVERS_JSON=1
# if bootstrap will run generate_servers_json.sh after.
# Override Steam dedicated location: AUS_STEAM_DEDICATED_DIR, AUS_STEAM_DEDICATED_EXE (default server64.exe).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
# Repo layout: backend/ (current), or auscode/auscode/*.py (nested), or auscode/*.py (flat).
if [[ -f "${REPO_ROOT}/backend/server_manager.py" ]]; then
  SRC_LIB="${REPO_ROOT}/backend"
  SRC_CONFIG_DIR="${REPO_ROOT}/backend/config"
  REQ_FILE="${REPO_ROOT}/backend/requirements.txt"
elif [[ -f "${REPO_ROOT}/auscode/auscode/server_manager.py" ]]; then
  SRC_LIB="${REPO_ROOT}/auscode/auscode"
  SRC_CONFIG_DIR="${REPO_ROOT}/auscode/config"
  REQ_FILE="${REPO_ROOT}/auscode/requirements.txt"
elif [[ -f "${REPO_ROOT}/auscode/server_manager.py" ]]; then
  SRC_LIB="${REPO_ROOT}/auscode"
  SRC_CONFIG_DIR="${REPO_ROOT}/config"
  REQ_FILE="${REPO_ROOT}/requirements.txt"
else
  echo "error: cannot find server_manager.py under ${REPO_ROOT} (expected backend/, auscode/auscode/, or auscode/)." >&2
  exit 1
fi

# Typical Steam Linux library path for Stormworks Dedicated Server (Wine runs server64.exe or server.exe).
AUS_STEAM_DEDICATED_DIR="${AUS_STEAM_DEDICATED_DIR:-${HOME}/.local/share/Steam/steamapps/common/Stormworks Dedicated Server}"
AUS_STEAM_DEDICATED_EXE="${AUS_STEAM_DEDICATED_EXE:-server64.exe}"
if [[ "$(uname -s)" == "Linux" ]]; then
  if [[ -f "${AUS_STEAM_DEDICATED_DIR}/server64.exe" ]]; then
    AUS_STEAM_DEDICATED_EXE=server64.exe
  elif [[ -f "${AUS_STEAM_DEDICATED_DIR}/server.exe" ]]; then
    AUS_STEAM_DEDICATED_EXE=server.exe
  fi
fi

_write_servers_json_steam_linux() {
  local out="$1"
  python3 - "${out}" "${AUS_STEAM_DEDICATED_DIR}" "${AUS_STEAM_DEDICATED_EXE}" << 'PY'
import json, sys

out, wd, exe = sys.argv[1], sys.argv[2], sys.argv[3]
data = {
    "servers": {
        "1": {
            "executable_path": exe,
            "launch_args": "",
            "working_directory": wd,
            "use_wine": True,
        }
    }
}
with open(out, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
}

DEFAULT_INSTALL="${HOME}/.local/opt/aus"
SETUP_WINE="no"
WINE_PREFIX_PATH=""

if [[ "${AUS_NONINTERACTIVE:-}" == "1" ]]; then
  INSTALL_ROOT="${INSTALL_ROOT:-$DEFAULT_INSTALL}"
  INSTALL_ROOT="$(readlink -f -m "${INSTALL_ROOT}")"
  API_URL="${API_URL:-http://127.0.0.1:8000}"
  API_PORT="${API_PORT:-8000}"
  if [[ "$(uname -s)" == "Linux" ]]; then
    SETUP_WINE="${SETUP_WINE:-no}"
    if [[ "${SETUP_WINE}" =~ ^[yY] ]]; then
      SETUP_WINE="yes"
      WINE_PREFIX_PATH="${INSTALL_ROOT}/wine/prefix"
    fi
  fi
  echo "Aus server manager installer (non-interactive) -> ${INSTALL_ROOT}"
else
  echo "Aus server manager installer"
  echo "----------------------------"

  read -r -p "Install directory for Aus (venv, config, bin) [${DEFAULT_INSTALL}]: " INSTALL_ROOT
  INSTALL_ROOT="${INSTALL_ROOT:-$DEFAULT_INSTALL}"
  INSTALL_ROOT="$(readlink -f -m "${INSTALL_ROOT}")"

  read -r -p "API URL for CLI (default http://127.0.0.1:8000): " API_URL
  API_URL="${API_URL:-http://127.0.0.1:8000}"

  read -r -p "HTTP port for API when using aus-server [8000]: " API_PORT
  API_PORT="${API_PORT:-8000}"

  if [[ "$(uname -s)" == "Linux" ]]; then
    read -r -p "Install/configure Wine for Stormworks (Windows server .exe on Linux)? [y/N]: " WINE_ANS
    if [[ "${WINE_ANS:-}" =~ ^[yY]$ ]]; then
      SETUP_WINE="yes"
      WINE_PREFIX_PATH="${INSTALL_ROOT}/wine/prefix"
    fi
  else
    echo "(Wine setup is only offered on Linux; skipped on $(uname -s).)"
  fi
fi

mkdir -p "${INSTALL_ROOT}/lib" "${INSTALL_ROOT}/config" "${INSTALL_ROOT}/bin" "${INSTALL_ROOT}/run"

echo "Installing to: ${INSTALL_ROOT}"
echo "Using REPO_ROOT: ${REPO_ROOT}"

cp "${SRC_LIB}/server_manager.py" "${INSTALL_ROOT}/lib/"
cp "${SRC_LIB}/aus_cli.py" "${INSTALL_ROOT}/lib/"
cp "${REQ_FILE}" "${INSTALL_ROOT}/"

if [[ "${AUS_SKIP_DEFAULT_SERVERS_JSON:-}" == "1" ]]; then
  echo "Skipping default servers.json (bootstrap will generate)."
elif [[ ! -f "${INSTALL_ROOT}/config/servers.json" ]]; then
  if [[ "$(uname -s)" == "Linux" ]] && [[ -f "${AUS_STEAM_DEDICATED_DIR}/${AUS_STEAM_DEDICATED_EXE}" ]]; then
    _write_servers_json_steam_linux "${INSTALL_ROOT}/config/servers.json"
    echo "Created ${INSTALL_ROOT}/config/servers.json for Steam dedicated (${AUS_STEAM_DEDICATED_DIR}/${AUS_STEAM_DEDICATED_EXE}, use_wine=true)."
  elif [[ -f "${SRC_CONFIG_DIR}/servers.json.example" ]]; then
    cp "${SRC_CONFIG_DIR}/servers.json.example" "${INSTALL_ROOT}/config/servers.json"
    echo "Created ${INSTALL_ROOT}/config/servers.json from example — edit executable_path and paths."
  else
    echo '{"servers":{"1":{"executable_path":"./server","launch_args":"","working_directory":"."}}}' > "${INSTALL_ROOT}/config/servers.json"
    echo "Created minimal ${INSTALL_ROOT}/config/servers.json — edit before use."
  fi
else
  echo "Keeping existing ${INSTALL_ROOT}/config/servers.json"
fi

if [[ -f "${SRC_CONFIG_DIR}/server.config.example.json" ]]; then
  cp -n "${SRC_CONFIG_DIR}/server.config.example.json" "${INSTALL_ROOT}/config/server.config.example.json" 2>/dev/null || true
fi

if [[ ! -d "${INSTALL_ROOT}/venv" ]]; then
  python3 -m venv "${INSTALL_ROOT}/venv"
fi

"${INSTALL_ROOT}/venv/bin/pip" install --upgrade pip
"${INSTALL_ROOT}/venv/bin/pip" install -r "${INSTALL_ROOT}/requirements.txt"

if [[ "${SETUP_WINE}" == "yes" ]]; then
  mkdir -p "${WINE_PREFIX_PATH}"
  if ! command -v wine64 >/dev/null 2>&1 && ! command -v wine >/dev/null 2>&1; then
    echo "Wine not found on PATH. Attempting install (needs sudo on most distros)..."
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update
      sudo apt-get install -y wine64 || sudo apt-get install -y wine
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y wine
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -S --noconfirm wine
    else
      echo "Could not detect apt-get, dnf, or pacman. Install Wine manually, then re-run or use your distro's Wine guide." >&2
      exit 1
    fi
  fi
  WINE_CMD="wine64"
  command -v wine64 >/dev/null 2>&1 || WINE_CMD="wine"
  echo "Initializing Wine prefix (non-interactive): ${WINE_PREFIX_PATH}"
  export WINEPREFIX="${WINE_PREFIX_PATH}"
  export WINEARCH="win64"
  _wineboot_log="${INSTALL_ROOT}/run/wineboot-install.log"
  # RpcSs / OLE lines on stderr are common on headless Linux; log them so prompts stay readable.
  if "${WINE_CMD}" wineboot -i >>"${_wineboot_log}" 2>&1; then
    echo "Wine prefix initialized (details: ${_wineboot_log})"
  else
    echo "Wine wineboot exited non-zero (often still usable); see ${_wineboot_log}" >&2
  fi
fi

AUS_WINEPREFIX_LINE="# Optional: export AUS_WINEPREFIX after install_manager.sh Wine setup"
if [[ "${SETUP_WINE}" == "yes" ]]; then
  AUS_WINEPREFIX_LINE="export AUS_WINEPREFIX=\"${WINE_PREFIX_PATH}\""
fi

cat > "${INSTALL_ROOT}/bin/aus" << EOF
#!/usr/bin/env bash
set -e
export AUS_CONFIG_DIR="${INSTALL_ROOT}/config"
export AUS_API_URL="${API_URL}"
${AUS_WINEPREFIX_LINE}
exec "${INSTALL_ROOT}/venv/bin/python" "${INSTALL_ROOT}/lib/aus_cli.py" "\$@"
EOF
chmod +x "${INSTALL_ROOT}/bin/aus"

cat > "${INSTALL_ROOT}/bin/aus-server" << EOF
#!/usr/bin/env bash
set -e
export AUS_CONFIG_DIR="${INSTALL_ROOT}/config"
${AUS_WINEPREFIX_LINE}
export PYTHONPATH="${INSTALL_ROOT}/lib:\${PYTHONPATH:-}"
exec "${INSTALL_ROOT}/venv/bin/uvicorn" server_manager:app --host 0.0.0.0 --port ${API_PORT}
EOF
chmod +x "${INSTALL_ROOT}/bin/aus-server"

cat > "${INSTALL_ROOT}/bin/start-aus" << EOF
#!/usr/bin/env bash
# Start aus-server if needed, then start Stormworks managed server id 1.
set -euo pipefail
export AUS_CONFIG_DIR="${INSTALL_ROOT}/config"
export AUS_API_URL="${API_URL}"
${AUS_WINEPREFIX_LINE}
INSTALL_ROOT="${INSTALL_ROOT}"
API_PORT="${API_PORT}"
PIDFILE="\${INSTALL_ROOT}/run/aus-server.pid"
LOGFILE="\${INSTALL_ROOT}/run/aus-server.log"
STATUS_URL="http://127.0.0.1:\${API_PORT}/server/status"

if command -v curl >/dev/null 2>&1; then
  if curl -sf "\${STATUS_URL}" >/dev/null 2>&1; then
    echo "aus-server already responding on port \${API_PORT}"
  else
    echo "Starting aus-server in background..."
    nohup "\${INSTALL_ROOT}/bin/aus-server" >> "\${LOGFILE}" 2>&1 &
    echo \$! > "\${PIDFILE}"
    sleep 2
  fi
else
  if [[ -f "\${PIDFILE}" ]] && kill -0 "\$(cat "\${PIDFILE}")" 2>/dev/null; then
    echo "aus-server pidfile present and process alive"
  else
    echo "Starting aus-server in background..."
    nohup "\${INSTALL_ROOT}/bin/aus-server" >> "\${LOGFILE}" 2>&1 &
    echo \$! > "\${PIDFILE}"
    sleep 2
  fi
fi
echo "Server starting; API at ${API_URL} — stop: ${INSTALL_ROOT}/bin/stop-aus"
exec "\${INSTALL_ROOT}/bin/aus" start 1
EOF
chmod +x "${INSTALL_ROOT}/bin/start-aus"

cat > "${INSTALL_ROOT}/bin/stop-aus" << EOF
#!/usr/bin/env bash
set -euo pipefail
export AUS_CONFIG_DIR="${INSTALL_ROOT}/config"
export AUS_API_URL="${API_URL}"
${AUS_WINEPREFIX_LINE}
INSTALL_ROOT="${INSTALL_ROOT}"
PIDFILE="\${INSTALL_ROOT}/run/aus-server.pid"
if [[ -f "\${PIDFILE}" ]]; then
  PID="\$(cat "\${PIDFILE}")"
  if kill -0 "\${PID}" 2>/dev/null; then
    kill "\${PID}" 2>/dev/null || true
  fi
  rm -f "\${PIDFILE}"
fi
"\${INSTALL_ROOT}/bin/aus" stop 1 || true
echo "Stopped API (if running) and requested managed server stop."
EOF
chmod +x "${INSTALL_ROOT}/bin/stop-aus"

cat > "${INSTALL_ROOT}/aus.env" << EOF
# Aus manager — run once per shell:  source ${INSTALL_ROOT}/aus.env
export PATH="${INSTALL_ROOT}/bin:\${PATH}"
EOF

echo ""
echo "Done."
echo "  Start API:  ${INSTALL_ROOT}/bin/aus-server"
echo "  One-shot:   ${INSTALL_ROOT}/bin/start-aus   (API + game server id 1)"
echo "  Stop:       ${INSTALL_ROOT}/bin/stop-aus"
echo "  CLI:        ${INSTALL_ROOT}/bin/aus          (interactive if no args)"
echo "  One-shot:   ${INSTALL_ROOT}/bin/aus start 1"
echo "  Config:     ${INSTALL_ROOT}/config/servers.json"
if [[ "${SETUP_WINE}" == "yes" ]]; then
  echo "  Wine:       WINEPREFIX=${WINE_PREFIX_PATH} (exported in aus-server / aus)"
  echo "  For systemd: set Environment=AUS_WINEPREFIX=${WINE_PREFIX_PATH} and a writable HOME."
fi
echo "  Linux+Wine: default is ${AUS_STEAM_DEDICATED_DIR}/${AUS_STEAM_DEDICATED_EXE} when that file exists at install time; else edit servers.json."
echo ""
echo "Use aus / start-aus: put ${INSTALL_ROOT}/bin on PATH."
echo "  Fastest:     source ${INSTALL_ROOT}/aus.env"
echo "  Or:          source ~/.bashrc   (if it exports that PATH)"
echo "  Or full:     ${INSTALL_ROOT}/bin/aus start 1"
echo ""

if [[ "${AUS_NONINTERACTIVE:-}" != "1" ]]; then
  read -r -p "Append ${INSTALL_ROOT}/bin to PATH in ~/.bashrc? [y/N]: " ADD_PATH
  if [[ "${ADD_PATH:-}" =~ ^[yY]$ ]]; then
    if ! grep -Fq "${INSTALL_ROOT}/bin" "${HOME}/.bashrc" 2>/dev/null; then
      {
        echo ""
        echo "# Aus server manager"
        printf 'export PATH="%s/bin:$PATH"\n' "${INSTALL_ROOT}"
      } >> "${HOME}/.bashrc"
      echo "Added to ~/.bashrc — run: source ~/.bashrc   (or open a new terminal)"
    else
      echo "PATH already mentions this bin dir in ~/.bashrc (skipped)."
      echo "Your current shell has not loaded it yet — run: source ~/.bashrc"
    fi
  else
    echo "Skipped ~/.bashrc; use the export PATH= line above in this shell, or full paths."
  fi
fi
