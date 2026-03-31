#!/usr/bin/env bash
# Usually run by bootstrap.sh; standalone if you set paths yourself. See README "Which install script".
#
# Write $INSTALL_ROOT/config/servers.json for Stormworks dedicated (server id 1).
# Usage: INSTALL_ROOT=... DEDICATED_DIR=... [FORCE=1] bash generate_servers_json.sh
# Linux: use_wine true. Non-Linux: use_wine false.
set -euo pipefail

INSTALL_ROOT="${INSTALL_ROOT:?set INSTALL_ROOT}"
DEDICATED_DIR="${DEDICATED_DIR:?set DEDICATED_DIR}"
DEDICATED_DIR="$(readlink -f -m "${DEDICATED_DIR}")"
OUT="${INSTALL_ROOT}/config/servers.json"

if [[ ! -d "${DEDICATED_DIR}" ]]; then
  echo "error: dedicated dir not found: ${DEDICATED_DIR}" >&2
  exit 1
fi

if [[ -f "${OUT}" ]] && [[ "${FORCE:-0}" != "1" ]]; then
  echo "Keeping existing ${OUT} (set FORCE=1 to overwrite)."
  exit 0
fi

if [[ -f "${OUT}" ]] && [[ "${FORCE:-0}" == "1" ]]; then
  cp -a "${OUT}" "${OUT}.bak.$(date +%Y%m%d%H%M%S)"
fi

FOUND=""
while IFS= read -r f; do
  FOUND="${f}"
  break
# Steam Linux often ships server64.exe / server.exe / server32.exe (not Stormworks_Server*.exe).
done < <(find "${DEDICATED_DIR}" -maxdepth 6 -type f \( -iname 'Stormworks_Server*.exe' -o -iname '*Stormworks*Server*.exe' -o -iname 'server64.exe' -o -iname 'server.exe' -o -iname 'server32.exe' \) 2>/dev/null | head -1)

if [[ -z "${FOUND}" ]]; then
  echo "error: could not find Stormworks dedicated server .exe under ${DEDICATED_DIR}" >&2
  exit 1
fi

UNAME_S="$(uname -s)"
USE_WINE="false"
if [[ "${UNAME_S}" == "Linux" ]]; then
  USE_WINE="true"
fi

mkdir -p "$(dirname "${OUT}")"

python3 - "${OUT}" "${DEDICATED_DIR}" "${FOUND}" "${USE_WINE}" << 'PY'
import json, os, sys
out, wd, full, uw = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
exe_rel = os.path.relpath(full, start=wd)
use_wine = uw == "true"
data = {
    "servers": {
        "1": {
            "executable_path": exe_rel.replace("\\", "/"),
            "launch_args": "",
            "working_directory": wd,
            "use_wine": use_wine,
        }
    }
}
with open(out, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY

echo "Wrote ${OUT} (use_wine=${USE_WINE}, exe=${FOUND})"
