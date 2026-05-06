#!/usr/bin/env python3
"""
claude_http_server.py - tiny LAN HTTP wrapper around `claude -p`.

Endpoints:
  GET  /status   -> basic health/config
  POST /ask      -> {"question": "..."} => {"answer": "..."}

Auth:
  Authorization: Bearer <token>

Designed for local-network use on helper machines that already have:
  - a local clone of this repo
  - Claude Code installed and authenticated
  - Python 3 available
"""
from __future__ import annotations

import argparse
import json
import os
import secrets
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from secrets import compare_digest

REPO = Path(__file__).resolve().parent.parent
READ_ONLY_TOOLS = ["Read", "Glob", "Grep", "WebFetch", "WebSearch"]
READ_ONLY_APPEND_SYSTEM_PROMPT = (
    "This server is running in read-only mode. "
    "Do not modify files, run shell commands, or attempt side effects. "
    "Answer using inspection, search, and retrieval only."
)
_CLAUDE_BINARY: str | None = None


@dataclass
class ServerConfig:
    host: str
    port: int
    token: str
    repo_root: Path
    model: str
    mode: str
    timeout_s: int
    max_question_chars: int
    max_context_chars: int
    permission_mode: str
    add_dir: list[str]
    no_session_persistence: bool
    context_file: Path
    allow_request_add_dirs: bool
    allow_request_system_prompt: bool


CONFIG: ServerConfig | None = None


def require_config() -> ServerConfig:
    if CONFIG is None:
        raise RuntimeError("Server config not initialized")
    return CONFIG


def read_json_file(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def write_json_file(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(data, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def get_saved_context_record() -> dict[str, Any]:
    cfg = require_config()
    data = read_json_file(cfg.context_file)
    if not isinstance(data, dict):
        return {}
    return data


def get_saved_context() -> Any:
    return get_saved_context_record().get("context")


def set_saved_context(context: Any, source: str | None = None) -> dict[str, Any]:
    cfg = require_config()
    record = {
        "updated_at": int(time.time()),
        "source": source or "api",
        "context": context,
    }
    write_json_file(cfg.context_file, record)
    return record


def clear_saved_context() -> None:
    cfg = require_config()
    if cfg.context_file.exists():
        cfg.context_file.unlink()


def resolve_token(cli_token: str | None) -> str:
    token = cli_token or os.environ.get("CLAUDE_HTTP_TOKEN")
    if token:
        return token
    token = secrets.token_hex(32)
    print("No token supplied. Generated one for this process only:", file=sys.stderr)
    print(token, file=sys.stderr)
    return token


def claude_binary() -> str:
    global _CLAUDE_BINARY
    if _CLAUDE_BINARY:
        return _CLAUDE_BINARY
    path = shutil.which("claude")
    if not path:
        print("ERROR: `claude` not found on PATH.", file=sys.stderr)
        sys.exit(1)
    _CLAUDE_BINARY = path
    return path


def normalize_context(context: Any) -> str:
    if context is None:
        return ""
    if isinstance(context, str):
        return context.strip()
    if isinstance(context, list):
        parts = [normalize_context(item) for item in context]
        return "\n\n".join(part for part in parts if part)
    if isinstance(context, dict):
        return json.dumps(context, indent=2, ensure_ascii=False)
    return str(context).strip()


def compose_context(saved_context: Any, request_context: Any) -> Any:
    if saved_context is None and request_context is None:
        return None
    if saved_context is None:
        return request_context
    if request_context is None:
        return saved_context
    return [
        {"saved_context": saved_context},
        {"request_context": request_context},
    ]


def build_prompt(question: str, context: Any = None) -> str:
    context_text = normalize_context(context)
    if not context_text:
        return question
    return (
        "# Context\n\n"
        f"{context_text}\n\n"
        "---\n\n"
        "# Question\n\n"
        f"{question}"
    )


def build_command(
    prompt: str,
    model: str | None = None,
    system_prompt: str | None = None,
    add_dirs: list[str] | None = None,
) -> list[str]:
    cfg = require_config()
    cmd = [
        claude_binary(),
        "-p",
        "--output-format", "text",
    ]
    if cfg.mode == "readonly":
        cmd.extend(["--permission-mode", "plan"])
        cmd.extend(["--tools", ",".join(READ_ONLY_TOOLS)])
        cmd.extend(["--append-system-prompt", READ_ONLY_APPEND_SYSTEM_PROMPT])
    else:
        cmd.extend(["--permission-mode", cfg.permission_mode])
    if cfg.no_session_persistence:
        cmd.append("--no-session-persistence")
    chosen_model = model or cfg.model
    if chosen_model:
        cmd.extend(["--model", chosen_model])
    if system_prompt:
        cmd.extend(["--system-prompt", system_prompt])
    effective_dirs = add_dirs or cfg.add_dir
    for add_dir in effective_dirs:
        cmd.extend(["--add-dir", add_dir])
    cmd.extend(["--", prompt])
    return cmd


def resolve_allowed_dirs(extra_dirs: Any = None) -> list[str]:
    cfg = require_config()
    dirs = list(cfg.add_dir)
    if not extra_dirs:
        return dirs
    if not cfg.allow_request_add_dirs:
        raise ValueError("request add_dirs are disabled for this server")
    if not isinstance(extra_dirs, list):
        raise ValueError("add_dirs must be a list of paths")
    for item in extra_dirs:
        resolved = str(Path(str(item)).resolve())
        if resolved not in dirs:
            dirs.append(resolved)
    return dirs


def resolve_cwd(cwd: str | None, allowed_dirs: list[str]) -> Path:
    cfg = require_config()
    if not cwd:
        return cfg.repo_root
    resolved = Path(cwd).resolve()
    resolved_str = str(resolved)
    for base in allowed_dirs:
        try:
            resolved.relative_to(Path(base))
            return resolved
        except ValueError:
            continue
    raise ValueError("cwd must be inside one of the allowed directories")


def ask_claude(
    question: str,
    model: str | None = None,
    context: Any = None,
    system_prompt: str | None = None,
    cwd: str | None = None,
    add_dirs: Any = None,
) -> dict[str, Any]:
    cfg = require_config()
    if system_prompt and not cfg.allow_request_system_prompt:
        raise ValueError("request system_prompt is disabled for this server")
    prompt = build_prompt(question, context=context)
    allowed_dirs = resolve_allowed_dirs(add_dirs)
    run_cwd = resolve_cwd(cwd, allowed_dirs)
    cmd = build_command(
        prompt,
        model=model,
        system_prompt=system_prompt,
        add_dirs=allowed_dirs,
    )
    t0 = time.time()
    try:
        proc = subprocess.run(
            cmd,
            cwd=str(run_cwd),
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=cfg.timeout_s,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return {"ok": False, "error": f"timeout after {cfg.timeout_s}s"}
    except Exception as e:
        return {"ok": False, "error": f"spawn_error: {type(e).__name__}: {str(e)[:200]}"}

    elapsed = round(time.time() - t0, 1)
    stdout = proc.stdout.replace("\r\n", "\n").strip()
    stderr = proc.stderr.replace("\r\n", "\n").strip()
    if proc.returncode != 0:
        return {
            "ok": False,
            "error": f"claude exit {proc.returncode}",
            "stderr": stderr[:500],
            "stdout": stdout[:500],
            "elapsed_s": elapsed,
        }
    return {
        "ok": True,
        "answer": stdout,
        "elapsed_s": elapsed,
        "model": model or cfg.model,
        "cwd": str(run_cwd),
    }


class ClaudeHttpHandler(BaseHTTPRequestHandler):
    server_version = "ClaudeHTTP/0.1"

    def do_GET(self) -> None:
        cfg = require_config()
        if self.path != "/status":
            if self.path == "/context":
                if not self._authorized():
                    self._respond(401, {"ok": False, "error": "unauthorized"})
                    return
                record = get_saved_context_record()
                self._respond(200, {
                    "ok": True,
                    "has_context": bool(record.get("context")),
                    "record": record,
                })
                return
            self._respond(404, {"ok": False, "error": "not found"})
            return
        record = get_saved_context_record()
        self._respond(200, {
            "ok": True,
            "status": "running",
            "host": cfg.host,
            "port": cfg.port,
            "repo_root": str(cfg.repo_root),
            "model": cfg.model,
            "mode": cfg.mode,
            "permission_mode": "plan" if cfg.mode == "readonly" else cfg.permission_mode,
            "tools": READ_ONLY_TOOLS if cfg.mode == "readonly" else "default",
            "machine": os.environ.get("COMPUTERNAME") or os.uname().nodename,
            "has_saved_context": bool(record.get("context")),
            "context_updated_at": record.get("updated_at"),
            "allow_request_add_dirs": cfg.allow_request_add_dirs,
            "allow_request_system_prompt": cfg.allow_request_system_prompt,
        })

    def do_POST(self) -> None:
        if self.path not in ("/ask", "/context"):
            self._respond(404, {"ok": False, "error": "not found"})
            return
        if not self._authorized():
            self._respond(401, {"ok": False, "error": "unauthorized"})
            return

        body = self._read_json()
        if isinstance(body, dict) and "_error" in body:
            self._respond(400, {"ok": False, "error": body["_error"]})
            return

        cfg = require_config()
        if self.path == "/context":
            context = body.get("context") if isinstance(body, dict) else None
            source = body.get("source") if isinstance(body, dict) else None
            context_text = normalize_context(context)
            if not context_text:
                self._respond(400, {"ok": False, "error": "context is required"})
                return
            if len(context_text) > cfg.max_context_chars:
                self._respond(400, {
                    "ok": False,
                    "error": f"context exceeds {cfg.max_context_chars} chars",
                })
                return
            record = set_saved_context(context, source=source)
            self._respond(200, {
                "ok": True,
                "saved": True,
                "record": record,
            })
            return

        question = (body.get("question") or "").strip() if isinstance(body, dict) else ""
        if not question:
            self._respond(400, {"ok": False, "error": "question is required"})
            return

        if len(question) > cfg.max_question_chars:
            self._respond(400, {
                "ok": False,
                "error": f"question exceeds {cfg.max_question_chars} chars",
            })
            return

        request_context = body.get("context") if isinstance(body, dict) else None
        use_saved_context = True
        if isinstance(body, dict) and body.get("use_saved_context") is False:
            use_saved_context = False
        saved_context = get_saved_context() if use_saved_context else None
        context = compose_context(saved_context, request_context)
        context_text = normalize_context(context)
        if len(context_text) > cfg.max_context_chars:
            self._respond(400, {
                "ok": False,
                "error": f"context exceeds {cfg.max_context_chars} chars",
            })
            return

        model = body.get("model") if isinstance(body, dict) else None
        system_prompt = body.get("system_prompt") if isinstance(body, dict) else None
        cwd = body.get("cwd") if isinstance(body, dict) else None
        add_dirs = body.get("add_dirs") if isinstance(body, dict) else None
        try:
            result = ask_claude(
                question,
                model=model,
                context=context,
                system_prompt=system_prompt,
                cwd=cwd,
                add_dirs=add_dirs,
            )
        except ValueError as e:
            self._respond(400, {"ok": False, "error": str(e)})
            return
        code = 200 if result.get("ok") else 500
        self._respond(code, result)

    def do_DELETE(self) -> None:
        if self.path != "/context":
            self._respond(404, {"ok": False, "error": "not found"})
            return
        if not self._authorized():
            self._respond(401, {"ok": False, "error": "unauthorized"})
            return
        clear_saved_context()
        self._respond(200, {"ok": True, "cleared": True})

    def _authorized(self) -> bool:
        cfg = require_config()
        auth = self.headers.get("Authorization", "")
        prefix = "Bearer "
        return auth.startswith(prefix) and compare_digest(auth[len(prefix):], cfg.token)

    def _read_json(self) -> dict[str, Any]:
        length = int(self.headers.get("Content-Length", "0") or 0)
        raw = self.rfile.read(length).decode("utf-8") if length else ""
        if not raw:
            return {}
        try:
            return json.loads(raw)
        except json.JSONDecodeError as e:
            return {"_error": f"invalid json: {str(e)}"}

    def _respond(self, code: int, data: dict[str, Any]) -> None:
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format: str, *args: Any) -> None:
        return


def parse_args() -> argparse.Namespace:
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="0.0.0.0",
                    help="Bind host (default 0.0.0.0)")
    ap.add_argument("--port", type=int, default=8766,
                    help="Bind port (default 8766)")
    ap.add_argument("--token",
                    help="Bearer token; falls back to CLAUDE_HTTP_TOKEN env")
    ap.add_argument("--repo-root", default=str(REPO),
                    help="Repo root / working directory for claude")
    ap.add_argument("--model", default="sonnet",
                    help="Default Claude model (default sonnet)")
    ap.add_argument("--mode", choices=["readonly", "full"], default="readonly",
                    help="Server safety mode (default readonly)")
    ap.add_argument("--timeout-s", type=int, default=900,
                    help="Per-request Claude timeout in seconds")
    ap.add_argument("--max-question-chars", type=int, default=20000,
                    help="Reject larger prompts")
    ap.add_argument("--max-context-chars", type=int, default=40000,
                    help="Reject larger serialized context payloads")
    ap.add_argument("--permission-mode", default="bypassPermissions",
                    help="Claude permission mode for --mode full (default bypassPermissions)")
    ap.add_argument("--add-dir", action="append", default=[],
                    help="Extra directories to grant Claude access to")
    ap.add_argument("--allow-session-persistence", action="store_true",
                    help="Do not pass --no-session-persistence")
    ap.add_argument("--context-file",
                    help="Path to saved context JSON file")
    ap.add_argument("--allow-request-add-dirs", action="store_true",
                    help="Allow callers to extend add_dirs per request (disabled by default)")
    ap.add_argument("--allow-request-system-prompt", action="store_true",
                    help="Allow callers to set system_prompt per request (disabled by default)")
    return ap.parse_args()


def main() -> int:
    global CONFIG
    args = parse_args()
    token = resolve_token(args.token)
    repo_root = Path(args.repo_root).resolve()
    add_dir = [str(repo_root)]
    for item in args.add_dir:
        resolved = str(Path(item).resolve())
        if resolved not in add_dir:
            add_dir.append(resolved)
    context_file = Path(args.context_file).resolve() if args.context_file else (
        repo_root / "tools" / "claude_http_context.json"
    )
    CONFIG = ServerConfig(
        host=args.host,
        port=args.port,
        token=token,
        repo_root=repo_root,
        model=args.model,
        mode=args.mode,
        timeout_s=args.timeout_s,
        max_question_chars=args.max_question_chars,
        max_context_chars=args.max_context_chars,
        permission_mode=args.permission_mode,
        add_dir=add_dir,
        no_session_persistence=not args.allow_session_persistence,
        context_file=context_file,
        allow_request_add_dirs=args.allow_request_add_dirs,
        allow_request_system_prompt=args.allow_request_system_prompt,
    )

    server = ThreadingHTTPServer((args.host, args.port), ClaudeHttpHandler)
    print("=== Claude HTTP Server ===")
    print(f"  Listening on http://{args.host}:{args.port}")
    print("  Endpoints:")
    print("    GET  /status")
    print("    POST /ask")
    print("    GET  /context")
    print("    POST /context")
    print("    DELETE /context")
    print(f"  Repo:   {repo_root}")
    print(f"  Model:  {args.model}")
    print(f"  Mode:   {args.mode}")
    if args.mode == "readonly":
        print(f"  Tools:  {', '.join(READ_ONLY_TOOLS)}")
    else:
        print(f"  Permission mode: {args.permission_mode}")
    print(
        "  Token:  "
        + (
            "[generated; see stderr]"
            if not args.token and not os.environ.get("CLAUDE_HTTP_TOKEN")
            else "[configured]"
        )
    )
    print(f"  Context file: {context_file}")
    print("")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[claude_http_server] shutting down.")
        server.server_close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
