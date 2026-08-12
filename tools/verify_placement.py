#!/usr/bin/env python3
"""Does the museum that got BUILT match the plan that was APPROVED?

Phase 0's keystone gate (doc/plans/artifact_order_to_aaa_environment.md). Every
other check in this repo reasons in 2D cells; the player stands in 3D metres.
Three real faults have already slipped through every 2D check — an artifact
whose mesh sits 4.5 m from its own node origin, a token suffix that silently
switched auto-grounding off, and an 8.1 m artifact in a 4 m room. All three were
caught by squinting at captures, which does not scale past three artifacts.

This drives commons/testing/verify_placement.gd under the 16-second watchdog and
reports per artifact.

    python tools/verify_placement.py --map=Museum_Spatial_Slice
    python tools/verify_placement.py --map=X --tolerance-cells=1

A gate that has never failed has never been tested, so it can prove itself:

    python tools/verify_placement.py --map=X --self-test

`--self-test` copies the map, moves one artifact's token three cells off its
approved plan, and expects the gate to CATCH it. It exits non-zero if the gate
stays quiet — the corrupted map is always removed afterwards.
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
MAPS = REPO / "commons" / "maps"
GD_SCRIPT = "res://commons/testing/verify_placement.gd"
WATCHDOG = REPO / "tools" / "godot_watchdog.py"


def find_godot() -> str:
    if os.environ.get("GODOT_EXE"):
        return os.environ["GODOT_EXE"]
    if os.name != "nt":
        return "godot"
    for c in (r"C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe",
              r"C:/Users/palle/Desktop/Godot_v4.6-stable_win64_console.exe"):
        if Path(c).exists():
            return c
    return r"C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"


def run_probe(map_name: str, tolerance: int, settle: float) -> tuple[int, dict]:
    out_rel = f"res://ada_run/spatial_slice/correspondence_{map_name}.json"
    out_abs = REPO / "ada_run" / "spatial_slice" / f"correspondence_{map_name}.json"
    if out_abs.exists():
        out_abs.unlink()
    cmd = [
        sys.executable, str(WATCHDOG), f"--expect={out_abs}", "--grace=120", "--",
        find_godot(), "--path", str(REPO), "--xr-mode", "off", "--no-window",
        "--script", GD_SCRIPT, "--",
        f"--map={map_name}", f"--out={out_rel}",
        f"--tolerance-cells={tolerance}", f"--settle={settle}",
    ]
    proc = subprocess.run(cmd, cwd=str(REPO), capture_output=True, text=True)
    sys.stdout.write(proc.stdout)
    if proc.returncode not in (0, 1):
        sys.stderr.write(proc.stderr)
    report = {}
    if out_abs.exists():
        try:
            report = json.loads(out_abs.read_text(encoding="utf-8"))
        except Exception:
            pass
    return proc.returncode, report


def corrupt_copy(map_name: str, shift: int = 3) -> str:
    """A deliberately wrong twin: one artifact moved off its approved plan.

    The map metadata keeps the ORIGINAL expected_cells, so the built museum and
    the approved plan genuinely disagree — which is exactly what the gate is
    supposed to notice.
    """
    src = MAPS / map_name / "map_data.json"
    data = json.loads(src.read_text(encoding="utf-8"))
    layer = data["layers"]["interactables"]
    moved = ""
    for z, row in enumerate(layer):
        for x, cell in enumerate(row):
            if not cell:
                continue
            nx = x + shift
            if nx >= len(row) or row[nx]:
                nx = x - shift
            if 0 <= nx < len(row) and not row[nx]:
                row[nx] = cell
                row[x] = ""
                moved = cell.split(":")[0]
                break
        if moved:
            break
    if not moved:
        raise SystemExit("self-test: could not find a movable artifact token")
    name = f"{map_name}_Corrupt"
    data["map_info"]["lookup_name"] = name
    data["map_info"]["name"] = f"{map_name} (deliberately corrupted for the gate self-test)"
    dst = MAPS / name
    dst.mkdir(parents=True, exist_ok=True)
    (dst / "map_data.json").write_text(json.dumps(data, indent=1), encoding="utf-8")
    print(f"  self-test: moved '{moved}' {shift} cells off its approved plan "
          f"-> commons/maps/{name}")
    return name


def summarise(report: dict) -> None:
    if not report:
        print("  (no report written — the probe died before it could speak)")
        return
    if report.get("result") == "ERROR":
        print(f"  ERROR: {report.get('error')}")
        return
    for a in report.get("artifacts", []):
        print(f"  {a['artifact']:<34s} {a['result']}")
        for f in a.get("faults", []):
            print(f"      - {f}")
    print(f"  {report.get('artifacts_planned', 0)} planned, "
          f"{report.get('failures', 0)} failed")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", default="Museum_Spatial_Slice")
    ap.add_argument("--tolerance-cells", type=int, default=0)
    ap.add_argument("--settle", type=float, default=0.6)
    ap.add_argument("--self-test", action="store_true",
                    help="prove the gate can fail, by corrupting a placement")
    args = ap.parse_args()

    print(f"=== correspondence gate: {args.map} ===")
    rc, report = run_probe(args.map, args.tolerance_cells, args.settle)
    summarise(report)
    clean_pass = (rc == 0 and report.get("result") == "PASS")

    if not args.self_test:
        print(f"\nRESULT: {'PASS' if clean_pass else 'FAIL'}")
        return 0 if clean_pass else 1

    print("\n=== self-test: the gate must CATCH a corrupted placement ===")
    if not clean_pass:
        print("  skipped — the clean map does not pass, so a failure here "
              "would prove nothing")
        return 1
    name = corrupt_copy(args.map)
    try:
        rc2, report2 = run_probe(name, args.tolerance_cells, args.settle)
        summarise(report2)
        caught = (rc2 == 1 and report2.get("result") == "FAIL")
    finally:
        shutil.rmtree(MAPS / name, ignore_errors=True)
        print(f"  removed commons/maps/{name}")

    print(f"\nRESULT: clean map {'PASS' if clean_pass else 'FAIL'}; "
          f"corrupted map {'CAUGHT' if caught else 'MISSED'}")
    if not caught:
        print("  The gate did not notice a 3-cell error. It is not a gate yet.")
    return 0 if (clean_pass and caught) else 1


if __name__ == "__main__":
    raise SystemExit(main())
