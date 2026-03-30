#!/usr/bin/env python3
"""Interactive CLI for the Aus server manager API (start/stop/restart by server id)."""

from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request
from typing import Final

DEFAULT_API_URL: Final[str] = "http://127.0.0.1:8000"
REQUEST_TIMEOUT_SEC: Final[float] = 120.0
PROMPT: Final[str] = "aus> "


def _api_base() -> str:
    return os.environ.get("AUS_API_URL", DEFAULT_API_URL).rstrip("/")


def _http_request(method: str, path: str) -> tuple[int, str]:
    """Return (status_code, body text)."""
    url = _api_base() + path
    req = urllib.request.Request(url, method=method.upper(), data=b"")
    try:
        with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT_SEC) as resp:
            return resp.getcode(), resp.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        return exc.code, body
    except OSError as exc:
        return -1, str(exc)


def _print_json(body: str) -> None:
    try:
        data = json.loads(body)
        print(json.dumps(data, indent=2))
    except json.JSONDecodeError:
        print(body)


def cmd_help() -> None:
    """Print command help."""
    print(
        "\n".join(
            [
                "Commands (API: " + _api_base() + "):",
                "  start <n>       — start server number n",
                "  stop <n>        — stop server number n",
                "  restart <n>     — restart server number n",
                "  restart all     — restart every configured server",
                "  status          — list all servers",
                "  status <n>      — status for server n",
                "  help            — this text",
                "  quit | exit     — leave the shell",
                "",
            ]
        )
    )


def cmd_start(server_id: int) -> None:
    code, body = _http_request("POST", f"/server/{server_id}/start")
    if code == 200:
        _print_json(body)
    else:
        print(f"Error {code}: {body}", file=sys.stderr)


def cmd_stop(server_id: int) -> None:
    code, body = _http_request("POST", f"/server/{server_id}/stop")
    if code == 200:
        _print_json(body)
    else:
        print(f"Error {code}: {body}", file=sys.stderr)


def cmd_restart(server_id: int) -> None:
    code, body = _http_request("POST", f"/server/{server_id}/restart")
    if code == 200:
        _print_json(body)
    else:
        print(f"Error {code}: {body}", file=sys.stderr)


def cmd_restart_all() -> None:
    code, body = _http_request("POST", "/server/restart-all")
    if code == 200:
        _print_json(body)
    else:
        print(f"Error {code}: {body}", file=sys.stderr)


def cmd_status_all() -> None:
    code, body = _http_request("GET", "/servers")
    if code == 200:
        _print_json(body)
    else:
        print(f"Error {code}: {body}", file=sys.stderr)


def cmd_status_one(server_id: int) -> None:
    code, body = _http_request("GET", f"/server/{server_id}/status")
    if code == 200:
        _print_json(body)
    else:
        print(f"Error {code}: {body}", file=sys.stderr)


def _parse_tokens(tokens: list[str]) -> tuple[str | None, list[str]]:
    """Return command name and remaining args; None means empty line."""
    if not tokens:
        return None, []
    cmd = tokens[0].lower()
    rest = tokens[1:]
    if cmd == "restart" and rest and rest[0].lower() == "all":
        return "restart_all", []
    return cmd, rest


def run_tokens(tokens: list[str]) -> bool:
    """
    Execute one command from token list.
    Returns False if the shell should exit (quit/exit).
    """
    cmd, rest = _parse_tokens(tokens)
    if cmd is None:
        return True

    if cmd in ("quit", "exit"):
        return False

    if cmd in ("help", "?", "h"):
        cmd_help()
        return True

    if cmd == "status":
        if not rest:
            cmd_status_all()
        else:
            try:
                cmd_status_one(int(rest[0]))
            except ValueError:
                print("Usage: status [<n>]", file=sys.stderr)
        return True

    if cmd == "start":
        if len(rest) != 1:
            print("Usage: start <n>", file=sys.stderr)
            return True
        try:
            cmd_start(int(rest[0]))
        except ValueError:
            print("Server id must be a number.", file=sys.stderr)
        return True

    if cmd == "stop":
        if len(rest) != 1:
            print("Usage: stop <n>", file=sys.stderr)
            return True
        try:
            cmd_stop(int(rest[0]))
        except ValueError:
            print("Server id must be a number.", file=sys.stderr)
        return True

    if cmd == "restart_all":
        cmd_restart_all()
        return True

    if cmd == "restart":
        if len(rest) != 1:
            print("Usage: restart <n>  or  restart all", file=sys.stderr)
            return True
        try:
            cmd_restart(int(rest[0]))
        except ValueError:
            print("Server id must be a number.", file=sys.stderr)
        return True

    print(f"Unknown command: {cmd}. Type 'help'.", file=sys.stderr)
    return True


def repl() -> None:
    """Interactive typing area until quit/exit."""
    print("Aus server control. Type 'help' for commands. API:", _api_base())
    while True:
        try:
            line = input(PROMPT)
        except (EOFError, KeyboardInterrupt):
            print()
            break
        tokens = line.strip().split()
        if not tokens:
            continue
        if not run_tokens(tokens):
            break


def main() -> None:
    argv = sys.argv[1:]
    if argv:
        if not run_tokens(argv):
            raise SystemExit(0)
        return
    repl()


if __name__ == "__main__":
    main()
