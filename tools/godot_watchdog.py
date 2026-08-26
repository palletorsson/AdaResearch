#!/usr/bin/env python3
"""godot_watchdog.py — no capture may halt the pipeline (Palle's 16-second rule).

Launches a Godot capture (or any producer) and watches its output target.
If no result appears — or output stalls — for longer than the stall window,
the process tree is killed. A hung artifact (boid_flocking-class: simulation
loops that never yield headless) costs 16 seconds, not a session.

Usage:
  python tools/godot_watchdog.py --expect=<file-or-dir> [--grace=45] [--stall=16] -- <exe> <args...>

  --expect  file or directory whose contents prove progress
  --grace   seconds allowed for engine boot + first result (default 45)
  --stall   seconds of NO new output after the first result -> kill (default 16)

Exit: the child's own code if it finishes; 124 if the watchdog killed it.
"""
from __future__ import annotations

import os
import subprocess
import sys
import time


def newest_mtime(target: str) -> float:
    """Latest mtime under target (file or dir, non-recursive), 0.0 if absent."""
    if os.path.isfile(target):
        return os.path.getmtime(target)
    if os.path.isdir(target):
        best = 0.0
        for f in os.listdir(target):
            p = os.path.join(target, f)
            try:
                best = max(best, os.path.getmtime(p))
            except OSError:
                pass
        return best
    return 0.0


def main() -> int:
    args = sys.argv[1:]
    if "--" not in args:
        print(__doc__)
        return 1
    split = args.index("--")
    opts, cmd = args[:split], args[split + 1:]
    expect = next((a.split("=", 1)[1] for a in opts if a.startswith("--expect=")), None)
    grace = float(next((a.split("=", 1)[1] for a in opts if a.startswith("--grace=")), "45"))
    stall = float(next((a.split("=", 1)[1] for a in opts if a.startswith("--stall=")), "16"))
    if not expect or not cmd:
        print(__doc__)
        return 1

    start = time.time()
    baseline = newest_mtime(expect)
    proc = subprocess.Popen(cmd)
    first_result = 0.0
    last_progress = start
    while True:
        code = proc.poll()
        if code is not None:
            print(f"watchdog: child exited {code} after {time.time() - start:.0f}s")
            return code
        now = time.time()
        m = newest_mtime(expect)
        if m > baseline:
            if not first_result:
                first_result = now
                print(f"watchdog: first result after {now - start:.0f}s")
            if m > last_progress:
                last_progress = m
        window = grace if not first_result else stall
        anchor = start if not first_result else max(last_progress, first_result)
        if now - anchor > window:
            why = "no result in grace window" if not first_result else f"output stalled {stall:.0f}s"
            print(f"watchdog: KILL ({why})")
            r = subprocess.run(["taskkill", "/PID", str(proc.pid), "/T", "/F"],
                               capture_output=True, text=True)
            # A KILL THAT DID NOT KILL IS WORSE THAN NO WATCHDOG. taskkill was
            # fired and its result thrown away, so the line above printed
            # whether or not anything died — and a surviving Godot then holds
            # the lock and starves every later run. Measured 2026-08-26: an
            # instance reported KILLed at 22:16 was still up fifteen minutes
            # later, contending with its own replacement, and neither finished.
            for _ in range(20):
                if proc.poll() is not None:
                    break
                time.sleep(0.25)
            if proc.poll() is None:
                print("watchdog: STILL ALIVE after taskkill — pid %d. rc=%s %s"
                      % (proc.pid, r.returncode, (r.stderr or r.stdout or "").strip()[:160]))
                print("watchdog: a surviving Godot holds the lock; kill it before the next run")
                return 125
            return 124
        time.sleep(1.0)


if __name__ == "__main__":
    sys.exit(main())
