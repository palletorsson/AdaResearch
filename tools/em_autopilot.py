#!/usr/bin/env python3
"""
em_autopilot.py — the endless museum's walkthrough gate, wrapped.

Runs the scene in --em-autopilot mode under the 16-second watchdog and judges
by the VERDICT FILE, not the exit code. The distinction matters: a successful
walk can still end in a watchdog kill, because by the time the walker crosses
its last threshold the streamer has dealt artifacts from the next chapter, and
some artifact scenes (the GPU marching-cubes class) hang engine teardown on
quit. The verdict is written before quitting, so the file is the truth and the
process's death is an implementation detail.

Usage:
  python tools/em_autopilot.py                      # 3 museums, default order
  python tools/em_autopilot.py --museums=2 --first=chichu-buried-cells
Exit 0 iff the verdict says done && ok.
"""
from __future__ import annotations
import json
import os
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
VERDICT = REPO / "ada_run" / "em_autopilot.json"
GODOT = os.environ.get("GODOT_EXE", r"C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")


def main() -> int:
    museums = "3"
    first = ""
    for a in sys.argv[1:]:
        if a.startswith("--museums="):
            museums = a.split("=", 1)[1]
        elif a.startswith("--first="):
            first = a.split("=", 1)[1]
    if VERDICT.exists():
        VERDICT.unlink()
    cmd = [sys.executable, str(REPO / "tools" / "godot_watchdog.py"),
           f"--expect={VERDICT}", "--stall=20", "--",
           GODOT, "--path", ".", "--xr-mode", "off", "--no-window",
           "res://commons/scenes/endless_museum.tscn", "--",
           f"--em-autopilot={museums}"]
    if first:
        cmd.append(f"--em-first={first}")
    subprocess.run(cmd, cwd=REPO)
    if not VERDICT.exists():
        print("autopilot: NO VERDICT — the scene never got far enough to write one")
        return 1
    v = json.loads(VERDICT.read_text(encoding="utf-8"))
    ok = bool(v.get("done")) and bool(v.get("ok"))
    print(f"autopilot: {'PASS' if ok else 'FAIL'} — {v.get('museums_target')} museums"
          f"{' from ' + first if first else ''}, z={v.get('z'):.1f}/{v.get('goal_z'):.1f},"
          f" {v.get('elapsed_s'):.1f}s walked, {v.get('cells_unlearned', 0)} cells unlearned")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
