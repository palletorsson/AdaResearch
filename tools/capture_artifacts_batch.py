#!/usr/bin/env python
"""
capture_artifacts_batch.py — run capture_multi_angle.gd across many artifacts.

Drives Godot in headless mode, per-token, and (optionally) syncs the results
to the encyclopedia's public directory as a final step.

Picks artifacts from any of:
  --token <t>          one artifact
  --sequence <id>      all artifacts whose registry `map_sequences` contains this ID
  --registry <name>    every artifact in <name>.json (e.g. primitives, arrays)
  --all                every artifact across every registry (slow)

Usage::

    # Capture the primitives sequence (typically ~60 artifacts, ~25-40 min)
    python tools/capture_artifacts_batch.py --sequence primitives

    # Capture just one for testing
    python tools/capture_artifacts_batch.py --token origin

    # Capture a whole registry file, then sync to the web
    python tools/capture_artifacts_batch.py --registry primitives --sync

The Godot exe path can be overridden via --godot or the GODOT_EXE env var.
Default matches the path from CLAUDE.md.

Each token invocation is ~15-40 seconds (Godot boot + 4 angle settles).
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

REPO = Path(__file__).resolve().parent.parent
# Prefer the console variant (shows logs) but fall back to the windowed exe
# if only that is present. Override with --godot or GODOT_EXE.
def _resolve_default_godot() -> str:
    override = os.environ.get("GODOT_EXE")
    if override:
        return override
    candidates = [
        r"C:/Users/palle/Desktop/Godot_v4.6-stable_win64_console.exe",
        r"C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe",
    ]
    for c in candidates:
        if Path(c).exists():
            return c
    return candidates[0]

DEFAULT_GODOT = _resolve_default_godot()
CAPTURE_SCRIPT = "res://commons/testing/capture_multi_angle.gd"
REGISTRY_DIR = REPO / "commons" / "artifacts" / "registry"


def _loose_json(path: Path) -> dict:
    txt = path.read_text(encoding="utf-8")
    return json.loads(re.sub(r",\s*([\]}])", r"\1", txt))


def tokens_from_registry(name: str) -> list[str]:
    p = REGISTRY_DIR / f"{name}.json"
    if not p.exists():
        raise SystemExit(f"[ERR] registry not found: {p}")
    data = _loose_json(p)
    arts = data.get("artifacts") or {}
    return sorted(arts.keys())


def tokens_from_sequence(seq_id: str) -> list[str]:
    out: list[str] = []
    for p in sorted(REGISTRY_DIR.glob("*.json")):
        if p.name.endswith(".deprecated"):
            continue
        try:
            data = _loose_json(p)
        except Exception:
            continue
        arts = data.get("artifacts") or {}
        for token, entry in arts.items():
            if seq_id in (entry.get("map_sequences") or []):
                out.append(token)
    return sorted(set(out))


def all_tokens() -> list[str]:
    out: list[str] = []
    for p in sorted(REGISTRY_DIR.glob("*.json")):
        if p.name.endswith(".deprecated"):
            continue
        try:
            data = _loose_json(p)
        except Exception:
            continue
        out.extend((data.get("artifacts") or {}).keys())
    return sorted(set(out))


def capture(godot: str, token: str, timeout: int) -> tuple[bool, float, str]:
    """Run Godot once for one token. Returns (ok, elapsed_s, tail).
    `--no-bridges` is a user-arg the autoloaded OversightVoiceBridge /
    ClaudeBridge honor to stay silent during captures — no audio input,
    no HTTP chatter, no stale mic warnings."""
    cmd = [
        godot, "--path", str(REPO), "--xr-mode", "off", "--no-window",
        "--script", CAPTURE_SCRIPT, "--",
        "--mode=artifact", f"--target={token}", "--no-bridges",
    ]
    t0 = time.time()
    try:
        proc = subprocess.run(
            cmd, capture_output=True, text=True, timeout=timeout,
            encoding="utf-8", errors="replace",
        )
        elapsed = time.time() - t0
        ok = proc.returncode == 0
        tail_lines = (proc.stdout + proc.stderr).strip().splitlines()[-3:]
        tail = " | ".join(tail_lines)[:200]
        return ok, elapsed, tail
    except subprocess.TimeoutExpired:
        return False, float(timeout), "TIMEOUT"
    except FileNotFoundError:
        return False, 0.0, f"Godot not found at {godot}"


def main() -> int:
    ap = argparse.ArgumentParser()
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--token", help="one artifact")
    src.add_argument("--sequence", help="sequence ID, e.g. primitives")
    src.add_argument("--registry", help="registry file name without .json")
    src.add_argument("--all", action="store_true")
    ap.add_argument("--godot", default=DEFAULT_GODOT, help="Godot exe path")
    ap.add_argument("--timeout", type=int, default=90, help="per-token seconds")
    ap.add_argument("--limit", type=int, default=0, help="cap count (0 = no cap)")
    ap.add_argument("--sync", action="store_true",
                    help="run sync_artifact_captures.py at the end")
    ap.add_argument("--skip-existing", action="store_true",
                    help="skip tokens already present in public/artifact-gallery/captures/")
    args = ap.parse_args()

    if args.token:
        tokens = [args.token]
    elif args.sequence:
        tokens = tokens_from_sequence(args.sequence)
    elif args.registry:
        tokens = tokens_from_registry(args.registry)
    else:
        tokens = all_tokens()

    if args.skip_existing:
        existing_root = REPO.parent / "ada_encyclopedia" / "public" / "artifact-gallery" / "captures"
        before = len(tokens)
        tokens = [t for t in tokens if not (existing_root / t / "front.png").exists()]
        print(f"Skip-existing: {before - len(tokens)} already captured, {len(tokens)} remain.")

    if args.limit and len(tokens) > args.limit:
        tokens = tokens[:args.limit]

    print(f"Capturing {len(tokens)} artifact(s) with:")
    print(f"  godot: {args.godot}")
    print(f"  per-token timeout: {args.timeout}s")
    print()

    t_start = time.time()
    ok_n, fail_n = 0, 0
    for i, token in enumerate(tokens, 1):
        ok, elapsed, tail = capture(args.godot, token, args.timeout)
        status = "OK " if ok else "FAIL"
        print(f"  [{i:3d}/{len(tokens)}] {status} {elapsed:5.1f}s  {token}", flush=True)
        if not ok:
            print(f"          {tail}")
            fail_n += 1
        else:
            ok_n += 1

    total = time.time() - t_start
    print()
    print(f"Done. {ok_n} ok, {fail_n} fail, {total:.1f}s total "
          f"({total/max(1,len(tokens)):.1f}s/artifact avg)")

    if args.sync:
        print()
        print("Running sync_artifact_captures.py ...")
        sync_script = REPO / "tools" / "sync_artifact_captures.py"
        subprocess.run([sys.executable, str(sync_script)], check=False)

    return 0 if fail_n == 0 else 2


if __name__ == "__main__":
    sys.exit(main())
