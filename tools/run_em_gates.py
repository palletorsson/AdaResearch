#!/usr/bin/env python3
"""Run the endless-museum gates and RECORD their verdicts.

The gates print PASS/FAIL to a console and are forgotten; nothing could say
"what is green right now". This runs each one, reads its verdict line, and
writes ada_run/gates.json — one row per gate with ok / verdict / when / HEAD.
/museum-pipeline reads that file for its Gates column.

    python tools/run_em_gates.py            # all gates, ~15 min (one Godot at a time)
    python tools/run_em_gates.py --quick    # python gates only (seconds)
    python tools/run_em_gates.py --only editor,bays

Rules honoured: ONE Godot at a time (each gate is run to completion before
the next); editor trials use their PRIVATE overrides path (they never touch
the hand's file); a gate that hangs is killed at its timeout and recorded as
a failure, never left to block the rest.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "ada_run" / "gates.json"
GODOT = "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"

# name -> (kind, argv-or-script, verdict regex, timeout s)
GATES: dict[str, tuple[str, str, str, int]] = {
    "contract":      ("py", "tools/test_spatial_contract.py",          r"^OK\b|^FAILED", 300),
    "plan_chapters": ("py", "tools/test_em_plan_chapters.py",           r"^OK\b|^FAILED|PASS|FAIL", 120),
    "world_register":("py", "tools/test_dedicated_world_register.py",   r"^OK\b|^FAILED", 120),
    "editor":        ("gd", "res://commons/testing/test_em_editor.gd",  r"EDITOR TRIAL: (PASS|FAIL)", 500),
    "furniture":     ("gd", "res://commons/testing/test_em_furniture.gd", r"FURNITURE RULINGS: (PASS|FAIL)", 600),
    "prop_insitu":   ("gd", "res://commons/testing/test_em_prop_insitu.gd", r"PROP IN SITU: (PASS|FAIL)", 500),
    "prop_wall":     ("gd", "res://commons/testing/test_prop_wall_rules.gd", r"PROP WALL RULES: (PASS|FAIL)", 400),
    "bays":          ("gd", "res://commons/testing/test_em_bays.gd",    r"EM BAYS: (PASS|FAIL)", 300),
    "vr_floor":      ("gd", "res://commons/testing/test_em_vr_floor.gd", r"VR FLOOR: (PASS|FAIL)", 400),
    "bounds":        ("gd", "res://commons/testing/test_em_bounds.gd",  r"EM BOUNDS: (PASS|FAIL)", 300),
    "desktop_hand":  ("gd", "res://commons/testing/test_em_desktop_hand.gd", r"DESKTOP HAND: (PASS|FAIL)", 300),
    "bridge_courts": ("gd", "res://commons/testing/test_em_bridge_courts.gd", r"(PASS|FAIL)", 400),
    "side_room":     ("gd", "res://commons/testing/test_em_side_room.gd", r"SIDE ROOM: (PASS|FAIL)", 500),
    "pearls":        ("gd", "res://commons/testing/test_em_pearls.gd", r"EM PEARLS: (PASS|FAIL|SKIP)", 500),
    "jump":          ("gd", "res://commons/testing/test_em_jump.gd", r"EM JUMP: (PASS|FAIL|SKIP)", 300),
    "live_footprint":("gd", "res://commons/testing/test_em_live_footprint.gd", r"LIVE FOOTPRINT \(museum\): (PASS|FAIL)", 300),
    "live_contract": ("py", "tools/test_live_footprint.py", r"LIVE FOOTPRINT: (PASS|FAIL)", 60),
    "balcony_ask":   ("py", "tools/test_balcony_ask.py", r"BALCONY ASK: (PASS|FAIL)", 120),
    "hall":          ("gd", "res://commons/testing/test_em_hall.gd", r"EM HALL: (PASS|FAIL)", 500),
    "threshold_gate":("gd", "res://commons/testing/test_em_gate.gd", r"EM GATE: (PASS|FAIL)", 400),
    "autosave":      ("gd", "res://commons/testing/test_em_autosave.gd", r"EM AUTOSAVE: (PASS|FAIL|SKIP)", 400),
    "stream":        ("gd", "res://commons/testing/test_em_stream.gd", r"EM STREAM: (PASS|FAIL|SKIP)", 500),
    "config_edit":   ("gd", "res://commons/testing/test_em_config_edit.gd", r"EM CONFIG: (PASS|FAIL|SKIP)", 400),
    "plan_default":  ("gd", "res://commons/testing/test_em_plan_default.gd", r"EM PLAN DEFAULT: (PASS|FAIL)", 300),
    "suspend":       ("gd", "res://commons/testing/test_em_suspend.gd", r"EM SUSPEND: (PASS|FAIL|SKIP)", 300),
    "vr_parity":     ("gd", "res://commons/testing/test_em_vr_parity.gd", r"EM VR PARITY: (PASS|FAIL)", 400),
    "vr_eye":        ("gd", "res://commons/testing/test_em_vr_eye.gd", r"EM VR EYE: (PASS|FAIL)", 400),
    "mode_forks":    ("py", "tools/test_em_mode_forks.py", r"MODE FORKS: (PASS|FAIL)", 30),
    "built":         ("gd", "res://commons/testing/test_em_built.gd", r"EM BUILT: (PASS|FAIL)", 400),
    "plain_hands":   ("gd", "res://commons/testing/test_em_plain_hands.gd", r"EM PLAIN HANDS: (PASS|FAIL)", 400),
}


def head() -> str:
    try:
        return subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=REPO,
                              capture_output=True, text=True, timeout=10).stdout.strip()
    except Exception:
        return "?"


def run_gate(name: str, kind: str, target: str, pat: str, timeout: int) -> dict:
    if kind == "py":
        argv = [sys.executable, str(REPO / target)]
    else:
        argv = [GODOT, "--headless", "--path", str(REPO), "--xr-mode", "off", "--script", target]
    t0 = time.time()
    try:
        cp = subprocess.run(argv, cwd=REPO, capture_output=True, text=True,
                            timeout=timeout, errors="replace")
        text = (cp.stdout or "") + "\n" + (cp.stderr or "")
        killed = False
    except subprocess.TimeoutExpired as e:
        text = ((e.stdout or b"").decode(errors="replace") if isinstance(e.stdout, bytes) else (e.stdout or "")) \
            + "\n" + ((e.stderr or b"").decode(errors="replace") if isinstance(e.stderr, bytes) else (e.stderr or ""))
        killed = True
    verdict = ""
    for line in text.splitlines():
        if re.search(pat, line):
            verdict = line.strip()
    ok = (not killed) and bool(verdict) and ("PASS" in verdict or verdict.startswith("OK"))
    return {"ok": ok, "verdict": verdict or ("TIMEOUT" if killed else "no verdict line"),
            "seconds": round(time.time() - t0, 1), "at": datetime.now().isoformat(timespec="seconds")}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--quick", action="store_true", help="python gates only")
    ap.add_argument("--only", default="", help="comma list of gate names")
    a = ap.parse_args()
    names = list(GATES)
    if a.only:
        names = [n for n in a.only.split(",") if n in GATES]
    if a.quick:
        names = [n for n in names if GATES[n][0] == "py"]
    prev = json.loads(OUT.read_text(encoding="utf-8")) if OUT.exists() else {"runs": {}}
    runs: dict = prev.get("runs", {})
    h = head()
    for n in names:
        kind, target, pat, to = GATES[n]
        print(f"  {n:15s} ...", end="", flush=True)
        r = run_gate(n, kind, target, pat, to)
        r["head"] = h
        runs[n] = r
        print(f" {'PASS' if r['ok'] else 'FAIL'}  {r['seconds']}s  {r['verdict'][:70]}")
        OUT.write_text(json.dumps({"schema": "adaresearch.gates.v1",
                                   "_readme": "Recorded gate verdicts, written by tools/run_em_gates.py; read by /museum-pipeline. A row's `head` says which commit it proved.",
                                   "runs": runs}, indent=1), encoding="utf-8")
    green = sum(1 for n in names if runs[n]["ok"])
    print(f"\n{green}/{len(names)} green -> {OUT.relative_to(REPO)}")
    return 0 if green == len(names) else 1


if __name__ == "__main__":
    sys.exit(main())
