#!/usr/bin/env python3
"""
hot_reload.py — the zero-boot loop for artifact work.

cabinet_bench.py still boots Godot once per pass (~18s). hot_reload keeps ONE
window open (commons/testing/HotBench.tscn) and re-renders an artifact the
instant its .gd changes — no reboot. Each reload saves a fresh shot at
ada_run/hot_current.png for an agent to read.

Usage:
  python tools/hot_reload.py --start [artifact]   # launch the window (bg)
  python tools/hot_reload.py <artifact>           # switch/reshoot, wait, report
  python tools/hot_reload.py --shot               # reshoot the current artifact
  python tools/hot_reload.py --stop               # close the window

Typical loop: --start once, then edit a .gd and the window reloads on save;
run `hot_reload.py <artifact>` (or --shot) when you want a fresh PNG to read.
"""
from __future__ import annotations
import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
GODOT = os.environ.get("GODOT_EXE",
                       r"C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
ADARUN = REPO / "ada_run"
CONTROL = ADARUN / "hot_reload.json"
DONE = ADARUN / "hot_reload_done.json"
ALIVE = ADARUN / "hot_reload_alive.txt"
SHOT = ADARUN / "hot_current.png"


def _alive() -> bool:
    """True if the window wrote a heartbeat in the last ~3s."""
    if not ALIVE.exists():
        return False
    try:
        return (time.time() - ALIVE.stat().st_mtime) < 3.0
    except OSError:
        return False


def start(artifact: str) -> None:
    if _alive():
        print("hot bench already running")
        if artifact:
            poke(artifact)
        return
    args = [GODOT, "--path", str(REPO), "--xr-mode", "off",
            "res://commons/testing/HotBench.tscn", "--",
            f"--artifact={artifact or 'galton_board'}"]
    # detached: outlives this process, keeps the window open
    kwargs = {}
    if os.name == "nt":
        kwargs["creationflags"] = 0x00000008  # DETACHED_PROCESS
    subprocess.Popen(args, cwd=str(REPO), stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL, **kwargs)
    print(f"hot bench launching → {artifact or 'galton_board'}")
    print("  (edit the .gd and it reloads on save; `hot_reload.py <name>` for a fresh shot)")


def poke(artifact: str | None) -> int:
    """Bump reload_ts (and optionally switch artifact); wait for the fresh shot."""
    if not _alive():
        print("hot bench is not running — start it with: python tools/hot_reload.py --start")
        return 2
    ts = time.time()
    msg = {"reload_ts": ts}
    if artifact:
        msg["artifact"] = artifact
    ADARUN.mkdir(exist_ok=True)
    CONTROL.write_text(json.dumps(msg), encoding="utf-8")
    # wait for hot_reload_done.json with ts >= ours (bench stamps ticks_msec,
    # so key on the shot file's mtime instead — simpler and reliable)
    deadline = ts + 20.0
    shot_before = SHOT.stat().st_mtime if SHOT.exists() else 0
    while time.time() < deadline:
        if SHOT.exists() and SHOT.stat().st_mtime > shot_before:
            time.sleep(0.2)  # let the png finish writing
            done = _read_done()
            label = artifact or done.get("artifact", "?")
            if done.get("ok", True):
                print(f"reloaded {label} → {SHOT.relative_to(REPO)}")
                return 0
            print(f"reload FAILED for {label}: {done.get('msg', '?')}")
            return 1
        time.sleep(0.25)
    print("timed out waiting for the reload (is the .gd compiling?)")
    return 1


def _read_done() -> dict:
    try:
        return json.loads(DONE.read_text(encoding="utf-8"))
    except Exception:
        return {}


def stop() -> None:
    if os.name == "nt":
        subprocess.run(["taskkill", "/IM", "Godot_v4.6-stable_win64.exe", "/F"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print("hot bench stopped")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("artifact", nargs="?", default=None)
    ap.add_argument("--start", action="store_true")
    ap.add_argument("--shot", action="store_true")
    ap.add_argument("--stop", action="store_true")
    args = ap.parse_args()

    if args.stop:
        stop()
        return 0
    if args.start:
        start(args.artifact or "")
        return 0
    if args.shot:
        return poke(None)
    if args.artifact:
        return poke(args.artifact)
    ap.print_help()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
