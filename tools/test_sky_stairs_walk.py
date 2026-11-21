"""Run F71 Wavefunctions_Sky_Stairs live desktop walk test in Godot 4.6."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "doc/book/iterations/2026-11-21-sky-stairs-walk"
GODOT = Path("C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    checks_path = OUT / "checks.json"
    if checks_path.exists():
        checks_path.unlink()
    cmd = [
        sys.executable,
        str(ROOT / "tools/godot_watchdog.py"),
        f"--expect={checks_path}",
        "--grace=120",
        "--stall=60",
        "--",
        str(GODOT),
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
        "res://tools/probes/sky_stairs_walk_probe.gd",
        "--",
        f"--out={OUT.as_posix()}",
    ]
    res = subprocess.run(cmd, cwd=str(ROOT))
    if not checks_path.exists():
        print(f"ERROR: {checks_path} not written (exit {res.returncode})")
        return 1
    data = json.loads(checks_path.read_text(encoding="utf-8"))
    passed = bool(data.get("passed", False))
    checks = data.get("checks", [])
    print(f"F71 Sky Stairs Walk: passed={passed} ({len(checks)} checks, failed={data.get('failed', '?')})")
    for c in checks:
        mark = "PASS" if c.get("passed") else "FAIL"
        print(f"  [{mark}] {c.get('name')}")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
