"""Async Stormworks server process manager with FastAPI control endpoints.

Start injects ``+server_dir <working_directory>`` when not already present so the game
uses the configured data folder (not the API process cwd).

Stop kills the whole managed process group when possible (POSIX ``killpg``; Windows
``taskkill /T``) so Wine and child processes are not left orphaned, then waits with a
timeout so a stuck ``wait()`` cannot block forever.
"""

from __future__ import annotations

import asyncio
import json
import logging
import os
import shlex
import shutil
import signal
import subprocess
from dataclasses import dataclass, field, replace
from pathlib import Path
from typing import Any, Final

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

LOGGER_NAME: Final[str] = "stormworks.server_manager"
POST_KILL_WAIT_TIMEOUT_SEC: Final[float] = 90.0
DEFAULT_EXECUTABLE_PATH: Final[str] = "./server"
DEFAULT_LAUNCH_ARGS_RAW: Final[str] = ""
DEFAULT_WORKING_DIRECTORY: Final[str] = "."
SERVER_DIR_LAUNCH_ARG: Final[str] = "+server_dir"
API_TITLE: Final[str] = "Stormworks Server Manager"
API_VERSION: Final[str] = "2.0.0"
API_HOST: Final[str] = "0.0.0.0"
API_PORT: Final[int] = 8000
DEFAULT_CONFIG_FILENAME: Final[str] = "servers.json"
# Optional game settings beside servers.json; merged into +name, +physics_timestep, etc.
GAME_CONFIG_FILENAMES: Final[tuple[str, ...]] = ("server.config.json", "server.config")
# Emit order for known Stormworks dedicated keys (others follow alphabetically).
GAME_SETTINGS_KEY_ORDER: Final[tuple[str, ...]] = (
    "name",
    "ip_bind",
    "password",
    "max_players",
    "port",
    "physics_timestep",
    "seed",
    "save_name",
)
DEFAULT_WINE_BINARY: Final[str] = "wine64"
WINECONSOLE_BINARY: Final[str] = "wineconsole"
ENV_AUS_WINEPREFIX: Final[str] = "AUS_WINEPREFIX"
ENV_AUS_WINE_WINECONSOLE: Final[str] = "AUS_WINE_WINECONSOLE"

# Log wine64 -> wine fallback at most once per process.
_wine_fallback_logged: set[str] = set()


def _configure_logging() -> logging.Logger:
    """Configure process lifecycle logging for the API service."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
    )
    return logging.getLogger(LOGGER_NAME)


LOGGER = _configure_logging()


def _parse_launch_args(raw: str | list[str] | None) -> list[str]:
    """Parse launch args from string (shell-style) or list."""
    if raw is None:
        return []
    if isinstance(raw, list):
        return [str(x) for x in raw]
    return shlex.split(str(raw).strip()) if str(raw).strip() else []


def _parse_extra_env(obj: object) -> dict[str, str]:
    """Parse optional JSON env object into str->str."""
    if obj is None:
        return {}
    if not isinstance(obj, dict):
        raise ValueError("'env' must be a JSON object of string keys and values.")
    out: dict[str, str] = {}
    for key, value in obj.items():
        out[str(key)] = str(value)
    return out


def _parse_bool(value: object, default: bool = False) -> bool:
    if value is None:
        return default
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return bool(value)
    s = str(value).strip().lower()
    if s in ("1", "true", "yes", "on"):
        return True
    if s in ("0", "false", "no", "off", ""):
        return False
    return default


def _resolve_wine_binary(preferred: str) -> str:
    """Return a wine executable on PATH; fall back wine64 -> wine once with a warning."""
    if shutil.which(preferred):
        return preferred
    if preferred == DEFAULT_WINE_BINARY and shutil.which("wine"):
        key = f"{preferred}->wine"
        if key not in _wine_fallback_logged:
            LOGGER.warning(
                "%s not found on PATH; falling back to wine. Install wine64 for best results.",
                preferred,
            )
            _wine_fallback_logged.add(key)
        return "wine"
    raise RuntimeError(
        f"Wine binary not found: {preferred!r} (install Wine or set wine_binary in servers.json)."
    )


def _launch_args_with_server_dir(launch_args: list[str], workdir: Path) -> list[str]:
    """Append +server_dir WORKDIR if the dedicated server was not given it already."""
    for arg in launch_args:
        key = arg.strip().lower()
        if key == SERVER_DIR_LAUNCH_ARG.lower() or key.startswith(f"{SERVER_DIR_LAUNCH_ARG.lower()}="):
            return list(launch_args)
    out = list(launch_args)
    out.append(SERVER_DIR_LAUNCH_ARG)
    out.append(str(workdir))
    return out


def _resolve_game_config_path(config_dir: Path) -> Path | None:
    """Return the first existing game config file next to servers.json, if any."""
    for name in GAME_CONFIG_FILENAMES:
        p = config_dir / name
        if p.is_file():
            return p
    return None


def _try_load_game_config_root(config_dir: Path) -> dict[str, Any] | None:
    """Load optional server.config.json / server.config; warn and return None on error."""
    path = _resolve_game_config_path(config_dir)
    if path is None:
        return None
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        LOGGER.warning("Ignoring game config %s: %s", path, exc)
        return None
    if not isinstance(raw, dict):
        LOGGER.warning("Ignoring game config %s: root must be a JSON object.", path)
        return None
    return raw


def _collect_plus_arg_keys_from_argv(argv: list[str]) -> set[str]:
    """Return base keys for +foo or +foo=bar tokens (lowercase, without leading +)."""
    keys: set[str] = set()
    for t in argv:
        if not t.startswith("+"):
            continue
        body = t[1:]
        if "=" in body:
            keys.add(body.split("=", 1)[0].strip().lower())
        else:
            keys.add(body.strip().lower())
    return keys


def _game_settings_to_argv(game: dict[str, object]) -> list[str]:
    """Turn {\"name\": \"x\", \"physics_timestep\": 180} into [\"+name\", \"x\", \"+physics_timestep\", \"180\", ...]."""
    keys = [k for k in game if not str(k).startswith("_")]
    ordered: list[str] = []
    for k in GAME_SETTINGS_KEY_ORDER:
        if k in keys:
            ordered.append(k)
    for k in sorted(keys):
        if k not in ordered:
            ordered.append(k)
    out: list[str] = []
    for key in ordered:
        val = game[key]
        if val is None:
            continue
        if isinstance(val, bool):
            s = "true" if val else "false"
        elif isinstance(val, (int, float)):
            s = str(int(val)) if isinstance(val, float) and val == int(val) else str(val)
        else:
            s = str(val).strip()
        if not s and str(key) != "password":
            continue
        out.append(f"+{key}")
        out.append(s)
    return out


def _merge_launch_args_with_game_file(
    cfg: ServerConfig,
    config_dir: Path,
    server_id: int,
) -> ServerConfig:
    """Prepend game settings from server.config.json before servers.json launch_args."""
    root = _try_load_game_config_root(config_dir)
    if not root:
        return cfg

    defaults = root.get("defaults")
    defaults = defaults if isinstance(defaults, dict) else {}
    servers_block = root.get("servers")
    servers_block = servers_block if isinstance(servers_block, dict) else {}
    sid = str(server_id)
    entry = servers_block.get(sid)
    entry = entry if isinstance(entry, dict) else {}

    game: dict[str, object] = {}
    g_def = defaults.get("game")
    if isinstance(g_def, dict):
        game.update({k: v for k, v in g_def.items() if not str(k).startswith("_")})
    g_ent = entry.get("game")
    if isinstance(g_ent, dict):
        game.update({k: v for k, v in g_ent.items() if not str(k).startswith("_")})

    extra_file: list[str] = []
    extra_file.extend(_parse_launch_args(defaults.get("launch_args")))
    extra_file.extend(_parse_launch_args(entry.get("launch_args")))

    user_argv = list(cfg.launch_args)
    overridden = _collect_plus_arg_keys_from_argv(user_argv)
    game_filtered = {
        k: v
        for k, v in game.items()
        if str(k).strip().lower() not in overridden
    }
    merged = _game_settings_to_argv(game_filtered) + extra_file + user_argv
    path = _resolve_game_config_path(config_dir)
    LOGGER.info(
        "Merged game config from %s for server id=%s (+keys from game: %s)",
        path,
        server_id,
        list(game_filtered.keys()),
    )
    return replace(cfg, launch_args=merged)


async def _terminate_managed_process(process: asyncio.subprocess.Process) -> None:
    """Kill the whole process group (Unix) or tree (Windows), then reap with a timeout."""
    pid = process.pid
    if pid is None:
        return

    if os.name == "posix":
        try:
            os.killpg(pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        except (PermissionError, OSError) as exc:
            LOGGER.warning(
                "killpg(pid=%s, SIGKILL) failed (%s); falling back to process.kill().",
                pid,
                exc,
            )
            try:
                process.kill()
            except OSError:
                pass
    else:
        try:
            completed = subprocess.run(
                ["taskkill", "/PID", str(pid), "/T", "/F"],
                capture_output=True,
                timeout=45,
                text=True,
                check=False,
            )
            if completed.returncode != 0:
                err = (completed.stderr or completed.stdout or "").strip()
                if err:
                    LOGGER.debug("taskkill pid=%s rc=%s: %s", pid, completed.returncode, err)
        except (OSError, subprocess.TimeoutExpired) as exc:
            LOGGER.warning("taskkill failed for pid=%s (%s); trying process.kill().", pid, exc)
            try:
                process.kill()
            except OSError:
                pass

    try:
        await asyncio.wait_for(process.wait(), timeout=POST_KILL_WAIT_TIMEOUT_SEC)
    except asyncio.TimeoutError:
        LOGGER.warning(
            "wait() timed out after kill (pid=%s); giving up reap.",
            pid,
        )
    except OSError:
        pass


def _resolve_executable(workdir: Path, executable_path: str) -> Path:
    """Resolve server binary path; relative paths are taken from working_directory."""
    p = Path(executable_path).expanduser()
    if not p.is_absolute():
        p = (workdir / p).resolve()
    else:
        p = p.resolve()
    if not p.is_file():
        raise RuntimeError(f"Server executable not found or not a file: {p}")
    return p


def _merged_subprocess_env(config: ServerConfig) -> dict[str, str]:
    """Copy os.environ, apply WINEPREFIX when configured, and per-server extra env (always used for starts)."""
    merged: dict[str, str] = dict(os.environ)
    prefix = (config.wine_prefix or os.getenv(ENV_AUS_WINEPREFIX, "") or "").strip()
    if prefix:
        merged["WINEPREFIX"] = str(Path(prefix).expanduser().resolve())
    for key, value in config.extra_env.items():
        merged[str(key)] = str(value)
    return merged


@dataclass(slots=True)
class ServerConfig:
    """Runtime configuration for one managed Stormworks process."""

    executable_path: str
    launch_args: list[str]
    working_directory: str
    use_wine: bool = False
    wine_binary: str = DEFAULT_WINE_BINARY
    wine_prefix: str = ""
    wine_console: bool = False
    extra_env: dict[str, str] = field(default_factory=dict)

    @classmethod
    def from_env(cls) -> ServerConfig:
        """Load a single server from environment variables (legacy)."""
        executable_path = os.getenv("STORMWORKS_EXECUTABLE", DEFAULT_EXECUTABLE_PATH)
        raw_args = os.getenv("STORMWORKS_ARGS", DEFAULT_LAUNCH_ARGS_RAW)
        working_directory = os.getenv("STORMWORKS_WORKDIR", DEFAULT_WORKING_DIRECTORY)
        use_wine = _parse_bool(os.getenv("STORMWORKS_USE_WINE"), False)
        wine_binary = os.getenv("STORMWORKS_WINE_BINARY", DEFAULT_WINE_BINARY).strip() or DEFAULT_WINE_BINARY
        wine_prefix = os.getenv("STORMWORKS_WINE_PREFIX", "").strip()
        return cls(
            executable_path=executable_path,
            launch_args=_parse_launch_args(raw_args),
            working_directory=working_directory,
            use_wine=use_wine,
            wine_binary=wine_binary,
            wine_prefix=wine_prefix,
            wine_console=_parse_bool(os.getenv("STORMWORKS_WINE_CONSOLE"), False),
            extra_env={},
        )

    @classmethod
    def from_json_object(cls, obj: object, *, config_dir: Path | None = None) -> ServerConfig:
        """Load from a JSON object (dict).

        Relative ``working_directory`` values are resolved against ``config_dir``
        (the directory containing ``servers.json``), not the process cwd.
        """
        if not isinstance(obj, dict):
            raise ValueError("Server entry must be a JSON object.")
        exe = obj.get("executable_path") or obj.get("executable")
        if not exe:
            raise ValueError("Missing executable_path.")
        wd_raw = obj.get("working_directory") or obj.get("cwd") or DEFAULT_WORKING_DIRECTORY
        wd_path = Path(str(wd_raw)).expanduser()
        if wd_path.is_absolute():
            wd_str = str(wd_path.resolve())
        elif config_dir is not None:
            wd_str = str((config_dir / wd_path).resolve())
        else:
            wd_str = str(wd_path.resolve())
        args_raw = obj.get("launch_args") or obj.get("args") or ""
        use_wine = _parse_bool(obj.get("use_wine"), False)
        wine_binary_raw = obj.get("wine_binary")
        if wine_binary_raw is not None:
            wine_binary = str(wine_binary_raw).strip() or DEFAULT_WINE_BINARY
        else:
            wine_binary = DEFAULT_WINE_BINARY
        wine_prefix_raw = obj.get("wine_prefix")
        wine_prefix = str(wine_prefix_raw).strip() if wine_prefix_raw is not None else ""
        wine_console = _parse_bool(obj.get("wine_console") or obj.get("use_wineconsole"), False)
        extra_env = _parse_extra_env(obj.get("env"))
        return cls(
            executable_path=str(exe),
            launch_args=_parse_launch_args(args_raw),
            working_directory=wd_str,
            use_wine=use_wine,
            wine_binary=wine_binary,
            wine_prefix=wine_prefix,
            wine_console=wine_console,
            extra_env=extra_env,
        )


def _pick_wine_launcher(config: ServerConfig, merged_env: dict[str, str]) -> str:
    """Choose wine64/wine/wineconsole for headless hosts when appropriate."""
    env_console = _parse_bool(os.getenv(ENV_AUS_WINE_WINECONSOLE), False)
    display_set = bool((merged_env.get("DISPLAY") or "").strip())
    use_console = config.wine_console or env_console
    wineconsole_path = shutil.which(WINECONSOLE_BINARY)
    auto_console = (
        not display_set
        and config.wine_binary == DEFAULT_WINE_BINARY
        and bool(wineconsole_path)
    )
    if use_console and not wineconsole_path:
        raise RuntimeError(
            f"{WINECONSOLE_BINARY!r} not found on PATH but console mode was requested "
            f"(set wine_console in servers.json or {ENV_AUS_WINE_WINECONSOLE}=1). "
            "Install a Wine build that provides wineconsole, or clear wine_console / "
            f"{ENV_AUS_WINE_WINECONSOLE} and use wine_binary instead."
        )
    if (use_console or auto_console) and wineconsole_path:
        if auto_console and not use_console:
            LOGGER.info(
                "DISPLAY unset; using %s (headless-friendly). Set DISPLAY, or wine_binary/wine_console in servers.json to override.",
                WINECONSOLE_BINARY,
            )
        return WINECONSOLE_BINARY
    return _resolve_wine_binary(config.wine_binary)


def _default_config_path() -> Path:
    """Resolve servers.json: AUS_SERVERS_CONFIG file, or AUS_CONFIG_DIR/servers.json, or default."""
    explicit = os.getenv("AUS_SERVERS_CONFIG", "").strip()
    if explicit:
        return Path(explicit).expanduser().resolve()
    base = os.getenv("AUS_CONFIG_DIR", "").strip()
    if base:
        return Path(base).expanduser().resolve() / DEFAULT_CONFIG_FILENAME
    return Path.home() / ".config" / "aus" / DEFAULT_CONFIG_FILENAME


def load_registry_from_file(config_path: Path) -> dict[int, ServerManager]:
    """Load server managers from JSON file. Returns empty dict if file missing."""
    if not config_path.is_file():
        return {}

    raw = json.loads(config_path.read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        raise ValueError("Config root must be an object.")
    servers_obj = raw.get("servers", raw)
    if not isinstance(servers_obj, dict):
        raise ValueError("Config must contain a 'servers' object.")

    managers: dict[int, ServerManager] = {}
    for key, value in servers_obj.items():
        try:
            sid = int(key)
        except (TypeError, ValueError) as exc:
            raise ValueError(f"Invalid server id: {key!r}") from exc
        cfg = ServerConfig.from_json_object(value, config_dir=config_path.resolve().parent)
        cfg = _merge_launch_args_with_game_file(cfg, config_path.resolve().parent, sid)
        managers[sid] = ServerManager(config=cfg)
        LOGGER.info(
            "Registered server id=%s executable=%s use_wine=%s",
            sid,
            cfg.executable_path,
            cfg.use_wine,
        )

    return managers


class StatusResponse(BaseModel):
    """API response shape for process status checks."""

    server_id: int = Field(description="Logical server number.")
    running: bool = Field(description="Whether the server process is active.")
    pid: int | None = Field(default=None, description="Active process ID if running.")


class ServerListEntry(BaseModel):
    """One row in the server list."""

    server_id: int
    running: bool
    pid: int | None = None


class ServerListResponse(BaseModel):
    """List of configured servers and running state."""

    servers: list[ServerListEntry]


class ActionResponse(BaseModel):
    """API response shape for lifecycle operation endpoints."""

    success: bool
    message: str
    server_id: int
    running: bool
    pid: int | None = None


class RestartAllResponse(BaseModel):
    """Response for restart-all."""

    success: bool
    message: str
    results: list[ActionResponse]


class ServerManager:
    """Manage one Stormworks dedicated server lifecycle using asyncio subprocesses."""

    def __init__(self, config: ServerConfig) -> None:
        self._config = config
        self._process: asyncio.subprocess.Process | None = None
        self._lock = asyncio.Lock()

    def is_running(self) -> bool:
        """Return True if the managed process is currently active."""
        return self._process is not None and self._process.returncode is None

    async def start_server(self) -> None:
        """Start the server process if it is not already running."""
        async with self._lock:
            if self.is_running():
                LOGGER.info("Start skipped: server already running (pid=%s)", self.pid)
                raise RuntimeError("Server is already running.")
            await self._start_unlocked()

    async def stop_server(self) -> None:
        """Stop the server process immediately (kill, no graceful shutdown)."""
        async with self._lock:
            if not self.is_running():
                LOGGER.info("Stop skipped: server already stopped.")
                return
            await self._stop_unlocked()

    async def restart_server(self) -> None:
        """Restart the server process by stop then start under one lock."""
        async with self._lock:
            LOGGER.info("Restart requested.")
            if self.is_running():
                await self._stop_unlocked()
            await self._start_unlocked()
            LOGGER.info("Restart complete (pid=%s).", self.pid)

    @property
    def pid(self) -> int | None:
        """Return process ID when running."""
        return self._process.pid if self.is_running() and self._process else None

    async def _watch_child_exit(self, proc: asyncio.subprocess.Process) -> None:
        """Log when the child exits (does not touch _process; avoids deadlock with stop)."""
        code = await proc.wait()
        if code == 0:
            LOGGER.info("Managed server process exited normally (pid=%s).", proc.pid)
        else:
            LOGGER.warning(
                "Managed server process exited (pid=%s, returncode=%s). Check Wine/DLL paths and working_directory.",
                proc.pid,
                code,
            )

    def _spawn_exit_watcher(self, proc: asyncio.subprocess.Process) -> None:
        """Schedule exit logging; never swallow task exceptions silently."""

        async def _run() -> None:
            try:
                await self._watch_child_exit(proc)
            except asyncio.CancelledError:
                raise
            except Exception:
                LOGGER.exception(
                    "Managed process exit watcher failed (pid=%s).",
                    getattr(proc, "pid", None),
                )

        asyncio.create_task(_run())

    async def _start_unlocked(self) -> None:
        workdir = Path(self._config.working_directory).expanduser().resolve()
        if not workdir.is_dir():
            raise RuntimeError(f"working_directory is not a directory: {workdir}")
        subprocess_env = _merged_subprocess_env(self._config)
        resolved_exe = _resolve_executable(workdir, self._config.executable_path)
        launch_args = _launch_args_with_server_dir(self._config.launch_args, workdir)

        if self._config.use_wine:
            if "WINEARCH" not in subprocess_env:
                subprocess_env["WINEARCH"] = "win64"
            wine_exe = _pick_wine_launcher(self._config, subprocess_env)
            argv: list[str] = [wine_exe, str(resolved_exe), *launch_args]
            wp = subprocess_env.get("WINEPREFIX")
            if wp:
                LOGGER.info("Wine WINEPREFIX=%s", wp)
            else:
                LOGGER.info(
                    "Wine launch: no WINEPREFIX in merged env (Wine may use ~/.wine or existing env)."
                )
        else:
            argv = [str(resolved_exe), *launch_args]

        LOGGER.info("Starting server: argv=%r cwd=%s", argv, workdir)
        # start_new_session sets a new process group (setsid); not supported on Windows asyncio/Popen.
        sub_kw: dict[str, object] = {"cwd": str(workdir), "env": subprocess_env}
        if os.name == "posix":
            sub_kw["start_new_session"] = True
        self._process = await asyncio.create_subprocess_exec(*argv, **sub_kw)
        LOGGER.info("Server started (pid=%s).", self._process.pid)
        self._spawn_exit_watcher(self._process)

    async def _stop_unlocked(self) -> None:
        if self._process is None or self._process.returncode is not None:
            self._process = None
            return

        proc = self._process
        LOGGER.info("Killing managed server process group (pid=%s).", proc.pid)
        await _terminate_managed_process(proc)
        self._process = None


def _build_registry() -> dict[int, ServerManager]:
    """Load multi-server config, or fall back to env-based single server as id 1."""
    config_path = _default_config_path()
    managers = load_registry_from_file(config_path)
    if managers:
        return managers

    LOGGER.warning(
        "No config at %s; using STORMWORKS_* env vars for server id=1.",
        config_path,
    )
    return {1: ServerManager(config=ServerConfig.from_env())}


REGISTRY: dict[int, ServerManager] = _build_registry()
app = FastAPI(title=API_TITLE, version=API_VERSION)


def _get_manager(server_id: int) -> ServerManager:
    if server_id not in REGISTRY:
        raise HTTPException(status_code=404, detail=f"Unknown server id: {server_id}")
    return REGISTRY[server_id]


def _action_response(server_id: int, manager: ServerManager, message: str) -> ActionResponse:
    return ActionResponse(
        success=True,
        message=message,
        server_id=server_id,
        running=manager.is_running(),
        pid=manager.pid,
    )


@app.get("/servers", response_model=ServerListResponse)
async def list_servers() -> ServerListResponse:
    """List all configured servers and whether each is running."""
    entries = [
        ServerListEntry(
            server_id=sid,
            running=m.is_running(),
            pid=m.pid,
        )
        for sid, m in sorted(REGISTRY.items(), key=lambda x: x[0])
    ]
    return ServerListResponse(servers=entries)


@app.post("/server/{server_id}/start", response_model=ActionResponse)
@app.get("/server/{server_id}/start", response_model=ActionResponse)
async def start_server_id(server_id: int) -> ActionResponse:
    """Start a managed server by id."""
    manager = _get_manager(server_id)
    try:
        await manager.start_server()
    except RuntimeError as exc:
        if "already running" in str(exc).lower():
            raise HTTPException(status_code=409, detail=str(exc)) from exc
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    return _action_response(server_id, manager, "Server started.")


@app.post("/server/{server_id}/stop", response_model=ActionResponse)
@app.get("/server/{server_id}/stop", response_model=ActionResponse)
async def stop_server_id(server_id: int) -> ActionResponse:
    """Stop a managed server by id."""
    manager = _get_manager(server_id)
    await manager.stop_server()
    return _action_response(server_id, manager, "Server stopped.")


@app.post("/server/{server_id}/restart", response_model=ActionResponse)
@app.get("/server/{server_id}/restart", response_model=ActionResponse)
async def restart_server_id(server_id: int) -> ActionResponse:
    """Restart a managed server by id."""
    manager = _get_manager(server_id)
    try:
        await manager.restart_server()
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    return _action_response(server_id, manager, "Server restarted.")


@app.get("/server/{server_id}/status", response_model=StatusResponse)
async def server_status_id(server_id: int) -> StatusResponse:
    """Return running state for one server."""
    manager = _get_manager(server_id)
    return StatusResponse(
        server_id=server_id,
        running=manager.is_running(),
        pid=manager.pid,
    )


@app.post("/server/restart-all", response_model=RestartAllResponse)
@app.get("/server/restart-all", response_model=RestartAllResponse)
async def restart_all_servers() -> RestartAllResponse:
    """Restart every configured server (sequential)."""
    results: list[ActionResponse] = []
    for sid in sorted(REGISTRY.keys()):
        manager = REGISTRY[sid]
        try:
            await manager.restart_server()
        except RuntimeError as exc:
            raise HTTPException(status_code=503, detail=f"server {sid}: {exc}") from exc
        results.append(_action_response(sid, manager, "Server restarted."))
    return RestartAllResponse(
        success=True,
        message=f"Restarted {len(results)} server(s).",
        results=results,
    )


# Legacy aliases (server id 1) for older clients and Lua without id in path
@app.post("/server/start", response_model=ActionResponse)
@app.get("/server/start", response_model=ActionResponse)
async def start_server_legacy() -> ActionResponse:
    """Start server id 1 (legacy)."""
    return await start_server_id(1)


@app.post("/server/stop", response_model=ActionResponse)
@app.get("/server/stop", response_model=ActionResponse)
async def stop_server_legacy() -> ActionResponse:
    """Stop server id 1 (legacy)."""
    return await stop_server_id(1)


@app.post("/server/restart", response_model=ActionResponse)
@app.get("/server/restart", response_model=ActionResponse)
async def restart_server_legacy() -> ActionResponse:
    """Restart server id 1 (legacy)."""
    return await restart_server_id(1)


@app.get("/server/status", response_model=StatusResponse)
async def server_status_legacy() -> StatusResponse:
    """Status for server id 1 (legacy)."""
    return await server_status_id(1)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host=API_HOST, port=API_PORT)
