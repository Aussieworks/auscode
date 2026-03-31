#!/usr/bin/env python3
"""Stdlib-only full Linux bootstrap (clone, SteamCMD, dedicated, install_manager, servers.json).

Same end result as ``bash install/bootstrap.sh`` — see repo README "Which install script".
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import urllib.request
from pathlib import Path

DEFAULT_GIT_URL = "https://github.com/Aussieworks/auscode.git"
STEAM_APP_ID = "1247090"
STEAMCMD_TGZ = "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"


def _repo_has_server_manager(repo_root: Path) -> bool:
    """True if checkout has server_manager (backend/, nested auscode, or flat auscode)."""
    return (
        (repo_root / "backend" / "server_manager.py").is_file()
        or (repo_root / "auscode" / "auscode" / "server_manager.py").is_file()
        or (repo_root / "auscode" / "server_manager.py").is_file()
    )


def run(cmd: list[str], **kwargs: object) -> None:
    print("+", " ".join(cmd), flush=True)
    subprocess.run(cmd, check=True, **kwargs)


def main() -> None:
    if not sys.platform.startswith("linux"):
        print("error: full_install.py targets Linux (SteamCMD Linux + Wine for the Windows dedicated server).", file=sys.stderr)
        sys.exit(1)

    parser = argparse.ArgumentParser(description="Aus full install (auscode + Steam dedicated + Aus manager)")
    parser.add_argument(
        "--install-root",
        default=None,
        metavar="DIR",
        help="Where to install venv, Steam dedicated files, and config (default: prompt if TTY, else ~/.local/opt/aus)",
    )
    parser.add_argument(
        "-y",
        "--non-interactive",
        action="store_true",
        help="No prompts (use defaults; set INSTALL_ROOT env or --install-root if needed)",
    )
    parser.add_argument("--force", action="store_true", help="Overwrite servers.json")
    parser.add_argument("--git-url", default=os.environ.get("AUSCODE_GIT_URL", DEFAULT_GIT_URL))
    parser.add_argument("--steam-app", default=os.environ.get("STEAM_APP_ID", STEAM_APP_ID))
    parser.add_argument("--no-start-prompt", action="store_true")
    args = parser.parse_args()

    default_ir = Path.home() / ".local/opt/aus"
    env_ir = os.environ.get("INSTALL_ROOT", "").strip()
    if args.install_root:
        install_root = Path(args.install_root).expanduser().resolve()
    elif args.non_interactive or not sys.stdin.isatty():
        install_root = Path(env_ir or default_ir).expanduser().resolve()
    else:
        prompt_default = Path(env_ir).expanduser() if env_ir else default_ir
        raw = input(f"Install directory (venv, Steam dedicated, config) [{prompt_default}]: ").strip()
        install_root = Path(raw or prompt_default).expanduser().resolve()
    dedicated_dir = Path(os.environ.get("DEDICATED_DIR", install_root / "stormworks-dedicated")).resolve()
    repo_parent = install_root / "src"
    repo_root = Path(os.environ.get("REPO_ROOT", repo_parent / "auscode")).resolve()
    api_port = os.environ.get("API_PORT", "8000")
    api_url = os.environ.get("API_URL", f"http://127.0.0.1:{api_port}")

    install_root.mkdir(parents=True, exist_ok=True)
    dedicated_dir.mkdir(parents=True, exist_ok=True)
    repo_parent.mkdir(parents=True, exist_ok=True)

    # Clone or download
    if not _repo_has_server_manager(repo_root):
        if shutil.which("git"):
            if repo_root.exists():
                shutil.rmtree(repo_root)
            run(["git", "clone", "--depth", "1", args.git_url, str(repo_root)])
        else:
            g = args.git_url.strip().replace("https://github.com/", "").replace("http://github.com/", "")
            if g.endswith(".git"):
                g = g[: -len(".git")]
            g = g.strip("/")
            parts = g.split("/")
            if len(parts) != 2:
                print("error: could not parse GitHub URL for zip fallback", file=sys.stderr)
                sys.exit(1)
            owner, repo_name = parts[0], parts[1]
            archive = f"https://github.com/{owner}/{repo_name}/archive/refs/heads/main.zip"
            import tempfile
            import zipfile

            with tempfile.NamedTemporaryFile(suffix=".zip", delete=False) as zf:
                zpath = Path(zf.name)
            try:
                urllib.request.urlretrieve(archive, zpath)
                with zipfile.ZipFile(zpath, "r") as z:
                    z.extractall(repo_parent)
                extracted = repo_parent / f"{repo_name}-main"
                if extracted.is_dir():
                    if repo_root.exists():
                        shutil.rmtree(repo_root)
                    extracted.rename(repo_root)
                else:
                    print("error: unexpected zip layout", file=sys.stderr)
                    sys.exit(1)
            finally:
                zpath.unlink(missing_ok=True)

    inst = repo_root / "install" / "install_manager.sh"
    if not inst.is_file():
        print(f"error: missing {inst} — clone a full auscode tree (includes install/).", file=sys.stderr)
        sys.exit(1)

    # SteamCMD: distro package if present, else Valve tarball under INSTALL_ROOT/steamcmd
    steamcmd_dir = install_root / "steamcmd"
    steamcmd_dir.mkdir(parents=True, exist_ok=True)
    steamcmd_sh = steamcmd_dir / "steamcmd.sh"
    if shutil.which("steamcmd"):
        steamcmd_bin = "steamcmd"
    else:
        if not steamcmd_sh.is_file():
            tgz = steamcmd_dir / "steamcmd_linux.tar.gz"
            urllib.request.urlretrieve(STEAMCMD_TGZ, tgz)
            run(["tar", "-xzf", str(tgz), "-C", str(steamcmd_dir)])
        steamcmd_bin = str(steamcmd_sh)
    run(
        [
            steamcmd_bin,
            f"+force_install_dir",
            str(dedicated_dir),
            "+login",
            "anonymous",
            "+app_update",
            str(args.steam_app),
            "validate",
            "+quit",
        ]
    )

    env = os.environ.copy()
    env["REPO_ROOT"] = str(repo_root)
    env["AUS_NONINTERACTIVE"] = "1"
    env["AUS_SKIP_DEFAULT_SERVERS_JSON"] = "1"
    env["INSTALL_ROOT"] = str(install_root)
    env["API_URL"] = api_url
    env["API_PORT"] = api_port
    env["SETUP_WINE"] = "yes" if sys.platform.startswith("linux") else os.environ.get("SETUP_WINE", "no")
    run(["bash", str(repo_root / "install" / "install_manager.sh")], env=env)

    genv = env.copy()
    genv["INSTALL_ROOT"] = str(install_root)
    genv["DEDICATED_DIR"] = str(dedicated_dir)
    genv["FORCE"] = "1" if args.force else os.environ.get("FORCE", "0")
    run(["bash", str(repo_root / "install" / "generate_servers_json.sh")], env=genv)

    start_aus = install_root / "bin" / "start-aus"
    print("Bootstrap complete.", flush=True)
    print(f"  {start_aus}", flush=True)
    if not args.no_start_prompt and sys.stdin.isatty():
        input("Press Enter to run start-aus, or Ctrl-C to exit: ")
        run([str(start_aus)], env=env)


if __name__ == "__main__":
    main()
