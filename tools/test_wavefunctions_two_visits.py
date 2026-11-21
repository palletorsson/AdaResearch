"""Live Godot verification for Ghost Student Spine Stop #4 (F62 WaveFunctions_Intro · Two Visits).

Outputs verified receipt & screenshots into:
  doc/book/iterations/2026-11-21-wavefunctions-two-visits/
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "doc/book/iterations/2026-11-21-wavefunctions-two-visits"


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    OUT.mkdir(parents=True, exist_ok=True)
    for stale in ("checks.json", "progress.json", "godot.log"):
        (OUT / stale).unlink(missing_ok=True)

    cmd = [
        sys.executable,
        str(ROOT / "tools/godot_watchdog.py"),
        "--expect=" + str(OUT / "checks.json"),
        "--grace=120",
        "--stall=60",
        "--",
        os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"),
        "--log-file",
        str(OUT / "godot.log"),
        "--path",
        str(ROOT),
        "--xr-mode",
        "off",
        "--resolution",
        "1440x860",
        "--position",
        "3200,3200",
        "--script",
        "res://tools/probes/wavefunctions_two_visits_probe.gd",
        "--",
        "--out=" + OUT.as_posix(),
    ]
    res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", timeout=240)
    log_text = (OUT / "godot.log").read_text(encoding="utf-8", errors="replace") if (OUT / "godot.log").exists() else ""
    report_path = OUT / "checks.json"
    if not report_path.exists() or "SCRIPT ERROR" in log_text or "Parse Error" in log_text:
        print(f"FAILED (exit {res.returncode})")
        print(res.stdout[-1500:])
        print(res.stderr[-1500:])
        print(log_text[-2500:])
        sys.exit(1)

    report = json.loads(report_path.read_text(encoding="utf-8"))
    print(f"F62 WaveFunctions_Intro Two Visits: passed={report['passed']} ({len(report['checks'])} checks, failed={report['failed']})")
    for c in report["checks"]:
        mark = "PASS" if c.get("passed", c.get("ok")) else "FAIL"
        print(f"  [{mark}] {c.get('name', c.get('label', c.get('check', '')))}")
    sys.exit(0 if report["passed"] else 1)


if __name__ == "__main__":
    main()
