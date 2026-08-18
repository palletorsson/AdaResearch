#!/usr/bin/env python3
"""Bake the endless museum: every placement decision made ONCE, written to a file.

    python tools/em_bake.py            # full bake of ada_run/em_plan.json -> ada_run/em_bake.json
    python tools/em_bake.py --check    # is the bake younger than the plan? (exit 1 if stale/missing)

The runtime used to measure each body's AABB the instant it entered the tree
and decide seals and refusals from that; a physics artifact measured
differently every run, so the same plan built different rooms — and a headset
built fewer and other bodies than the desktop. With em_bake.json present the
museum REPLAYS: baked bodies seal their baked cells, baked refusals are refused
before instantiation, nothing is measured. Re-run this after editing the plan.
"""
from __future__ import annotations
import argparse, json, os, subprocess, sys, time
from pathlib import Path
REPO = Path(__file__).resolve().parent.parent
GODOT = os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
PLAN = REPO / "ada_run" / "em_plan.json"
BAKE = REPO / "ada_run" / "em_bake.json"
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")


def plan_stamp() -> str:
    try:
        return str(json.loads(PLAN.read_text(encoding="utf-8")).get("_spine_run", {}).get("at", ""))
    except Exception:
        return ""


def check() -> int:
    if not BAKE.exists():
        print("EM BAKE: MISSING — python tools/em_bake.py FAIL"); return 1
    b = json.loads(BAKE.read_text(encoding="utf-8"))
    n = len(b.get("segments", {}))
    stale = b.get("plan_at", "") != plan_stamp() or PLAN.stat().st_mtime > BAKE.stat().st_mtime + 1
    print(f"EM BAKE: {n} pearl(s), baked {b.get('at')} from plan {b.get('plan_at')}"
          + (" — STALE (plan edited since; re-bake) FAIL" if stale else " — fresh PASS"))
    return 1 if stale else 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--timeout", type=int, default=1800)
    a = ap.parse_args()
    if a.check:
        return check()
    log = REPO / "ada_run" / "em_bake.log"
    cmd = [GODOT, "--headless", "--path", str(REPO), "--xr-mode", "off",
           "res://commons/scenes/endless_museum.tscn", "--", "--em-bake"]
    t0 = time.time()
    print("baking…", " ".join(cmd[-3:]))
    with open(log, "w", encoding="utf-8", errors="replace") as f:
        try:
            r = subprocess.run(cmd, stdout=f, stderr=subprocess.STDOUT, timeout=a.timeout)
        except subprocess.TimeoutExpired:
            print(f"EM BAKE: TIMEOUT after {a.timeout}s (partial bake may exist; log {log})"); return 1
    dt = time.time() - t0
    if not BAKE.exists():
        print(f"EM BAKE: FAILED — no {BAKE} (log {log}, exit {r.returncode})"); return 1
    b = json.loads(BAKE.read_text(encoding="utf-8"))
    segs = b.get("segments", {})
    placed = sum(len(v.get("placed", [])) for v in segs.values())
    refused = sum(len(v.get("refused", [])) for v in segs.values())
    print(f"EM BAKE: {len(segs)} pearl(s), {placed} placed, {refused} refused, {dt:.0f}s → {BAKE}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
