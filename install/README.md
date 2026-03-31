# Install scripts — which one?

**Path matters:** if your shell is already in **`install/`** (prompt ends with `.../install$`), run **`./install_manager.sh`** or **`bash install_manager.sh`**. Do **not** use `bash install/install_manager.sh` from there (that looks for `install/install/` and fails).

From the **repository root** (`.../auscode$`): **`bash install/install_manager.sh`** or **`./manage_install.sh`** (wrapper; same script).

Full detail: **[../README.md](../README.md)** when present (section **“Which install script should I use?”**).

| Goal | OS | Script |
|------|-----|--------|
| Steam + dedicated + venv + `servers.json` | Linux | **`bootstrap.sh`** (or `full_install.py` / `bootstrap.sh --python`) |
| Venv + API only (game already installed) | Linux | **`install_manager.sh`** |
| Venv + API only | Windows | **`install.bat`** or **`install_manager.ps1`** |
| Write `servers.json` from a dedicated dir | Linux | **`generate_servers_json.sh`** (normally called by bootstrap) |
| Create missing `aus.env` (PATH) without full reinstall | Linux | **`ensure_aus_env.sh`** [INSTALL_ROOT], or repo root **`./manage_install.sh --aus-env`** |
