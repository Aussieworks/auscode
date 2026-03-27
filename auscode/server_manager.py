"""Async Stormworks server process manager with FastAPI control endpoints."""

from __future__ import annotations

import asyncio
import json
import logging
import os
import shlex
from dataclasses import dataclass
from pathlib import Path
from typing import Final

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

LOGGER_NAME: Final[str] = "stormworks.server_manager"
DEFAULT_EXECUTABLE_PATH: Final[str] = "./server"
DEFAULT_LAUNCH_ARGS_RAW: Final[str] = ""
DEFAULT_WORKING_DIRECTORY: Final[str] = "."
TERMINATE_TIMEOUT_SECONDS: Final[float] = 10.0
API_TITLE: Final[str] = "Stormworks Server Manager"
API_VERSION: Final[str] = "2.0.0"
API_HOST: Final[str] = "0.0.0.0"
API_PORT: Final[int] = 8000
DEFAULT_CONFIG_FILENAME: Final[str] = "servers.json"


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


@dataclass(slots=True)
class ServerConfig:
    """Runtime configuration for one managed Stormworks process."""

    executable_path: str
    launch_args: list[str]
    working_directory: str

    @classmethod
    def from_env(cls) -> ServerConfig:
        """Load a single server from environment variables (legacy)."""
        executable_path = os.getenv("STORMWORKS_EXECUTABLE", DEFAULT_EXECUTABLE_PATH)
        raw_args = os.getenv("STORMWORKS_ARGS", DEFAULT_LAUNCH_ARGS_RAW)
        working_directory = os.getenv("STORMWORKS_WORKDIR", DEFAULT_WORKING_DIRECTORY)
        return cls(
            executable_path=executable_path,
            launch_args=_parse_launch_args(raw_args),
            working_directory=working_directory,
        )

    @classmethod
    def from_json_object(cls, obj: object) -> ServerConfig:
        """Load from a JSON object (dict)."""
        if not isinstance(obj, dict):
            raise ValueError("Server entry must be a JSON object.")
        exe = obj.get("executable_path") or obj.get("executable")
        if not exe:
            raise ValueError("Missing executable_path.")
        wd = obj.get("working_directory") or obj.get("cwd") or DEFAULT_WORKING_DIRECTORY
        args_raw = obj.get("launch_args") or obj.get("args") or ""
        return cls(
            executable_path=str(exe),
            launch_args=_parse_launch_args(args_raw),
            working_directory=str(wd),
        )


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
        cfg = ServerConfig.from_json_object(value)
        managers[sid] = ServerManager(config=cfg)
        LOGGER.info("Registered server id=%s executable=%s", sid, cfg.executable_path)

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
        """Stop the server process with graceful terminate/kill fallback."""
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

    async def _start_unlocked(self) -> None:
        workdir = Path(self._config.working_directory).expanduser().resolve()
        argv = [self._config.executable_path, *self._config.launch_args]
        command = " ".join(shlex.quote(part) for part in argv)
        LOGGER.info("Starting server: cmd=%s cwd=%s", command, workdir)
        self._process = await asyncio.create_subprocess_shell(command, cwd=str(workdir))
        LOGGER.info("Server started (pid=%s).", self._process.pid)

    async def _stop_unlocked(self) -> None:
        if self._process is None or self._process.returncode is not None:
            self._process = None
            return

        LOGGER.info("Stopping server gracefully (pid=%s).", self._process.pid)
        self._process.terminate()
        try:
            await asyncio.wait_for(
                self._process.wait(),
                timeout=TERMINATE_TIMEOUT_SECONDS,
            )
            LOGGER.info("Server stopped gracefully.")
        except asyncio.TimeoutError:
            LOGGER.warning(
                "Terminate timeout reached (pid=%s), forcing kill.",
                self._process.pid,
            )
            self._process.kill()
            await self._process.wait()
            LOGGER.info("Server killed after timeout.")
        finally:
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
        raise HTTPException(status_code=409, detail=str(exc)) from exc
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
    await manager.restart_server()
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
        await manager.restart_server()
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
