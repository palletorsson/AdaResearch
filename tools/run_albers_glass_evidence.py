#!/usr/bin/env python3
"""run_albers_glass_evidence.py - every rendered run the albers glass medium needs, one
Godot at a time, each under tools/godot_watchdog.py (doc/colour/albers_glass/SPEC.md §5).

  python tools/run_albers_glass_evidence.py oracles      the pixel oracle runs + negatives
  python tools/run_albers_glass_evidence.py variants     gain-path diagnostics (hdr_2d, root
                                                         window, Compatibility)
  python tools/run_albers_glass_evidence.py pictures     paint / relief / cubes pictures
  python tools/run_albers_glass_evidence.py identity     default wall: HEAD vs working tree
  python tools/run_albers_glass_evidence.py all

Windowed (headless draws no frames). The oracle file ada_run/albers_glass_oracle.json is
written ONLY by the probe; this script never edits it. --fresh moves an existing one aside
to ada_run/albers_glass_oracle.<stamp>.json first, so every run in it is from the current
probe.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
GODOT = "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"
PROBE = "res://commons/testing/probe_albers_glass_render.gd"
RUN_DIR = REPO / "ada_run" / "albers_glass_render"
ORACLE = REPO / "ada_run" / "albers_glass_oracle.json"

# (rendering method, probe args, expected key)
ORACLES = [
    ("mobile", ["--medium=relief"], "mobile_relief"),
    ("mobile", ["--medium=cubes"], "mobile_cubes"),
    ("forward_plus", ["--medium=relief"], "forward_plus_relief"),
    ("forward_plus", ["--medium=cubes"], "forward_plus_cubes"),
    ("mobile", ["--medium=relief", "--canvas=44"], "mobile_relief_c44"),
    ("mobile", ["--medium=cubes", "--canvas=44"], "mobile_cubes_c44"),
    ("forward_plus", ["--medium=relief", "--canvas=44"], "forward_plus_relief_c44"),
    ("forward_plus", ["--medium=cubes", "--canvas=44"], "forward_plus_cubes_c44"),
    # negatives
    ("mobile", ["--medium=cubes", "--force-cull-back"], "mobile_cubes_cullback"),
    ("forward_plus", ["--medium=cubes", "--force-cull-back"], "forward_plus_cubes_cullback"),
    ("mobile", ["--medium=cubes", "--force-cull-back", "--canvas=44"], "mobile_cubes_cullback_c44"),
    ("forward_plus", ["--medium=cubes", "--force-cull-back", "--canvas=44"], "forward_plus_cubes_cullback_c44"),
    ("mobile", ["--medium=relief", "--gain=1"], "mobile_relief_gain1"),
    ("mobile", ["--medium=relief", "--gain=2", "--hdr2d"], "mobile_relief_gain2_hdr2d"),
]

VARIANTS = [
    ("mobile", ["--medium=relief", "--hdr2d"], "mobile_relief_hdr2d"),
    ("forward_plus", ["--medium=relief", "--hdr2d"], "forward_plus_relief_hdr2d"),
    ("mobile", ["--medium=relief", "--root"], "mobile_relief_root"),
    ("gl_compatibility", ["--medium=relief"], "gl_compatibility_relief"),
    ("gl_compatibility", ["--medium=cubes"], "gl_compatibility_cubes"),
]


def run(method: str, extra: list[str], expect: Path, resolution: str = "1000x1000",
        stall: int = 16) -> int:
    cmd = [sys.executable, str(REPO / "tools" / "godot_watchdog.py"), f"--expect={expect}",
           "--grace=120", f"--stall={stall}", "--", GODOT, "--path", str(REPO), "--xr-mode", "off",
           "--rendering-method", method, "--resolution", resolution, "--script", PROBE, "--",
           "--no-bridges", *extra]
    t0 = time.time()
    code = subprocess.call(cmd, cwd=REPO)
    print(f"  [{method}] {' '.join(extra)} -> exit {code} in {time.time() - t0:.0f}s")
    return code


def oracles(rows) -> None:
    for method, args, key in rows:
        out = RUN_DIR / f"{key}.json"
        before = out.stat().st_mtime if out.exists() else 0.0
        run(method, ["--mode=oracle", *args], out)
        if not out.exists() or out.stat().st_mtime <= before:
            print(f"    {key}: NO NEW RESULT")
            continue
        r = json.loads(out.read_text(encoding="utf-8"))
        s = r.get("samples", {})
        print(f"    {key}: pass={r.get('pass')} renderer={r.get('renderer')} "
              f"band vs mesh {s.get('outer_band', {}).get('vs_mesh', {}).get('err_255')} "
              f"vs palette {s.get('outer_band', {}).get('vs_palette_solve', {}).get('err_255')} | "
              f"centre vs mesh {s.get('centre', {}).get('vs_mesh', {}).get('err_255')} "
              f"vs palette {s.get('centre', {}).get('vs_palette_solve', {}).get('err_255')} "
              f"{r.get('error', '')}")


def pictures() -> None:
    for med in ("paint", "relief", "cubes"):
        out = RUN_DIR / f"pictures_{med}.json"
        run("mobile", ["--mode=pictures", f"--medium={med}"], out, resolution="1600x1000")


def identity() -> None:
    # Outside res:// on purpose: a second copy of the script inside the project would be
    # scanned by Godot. The scratch dir is the system temp folder.
    import tempfile
    head = Path(tempfile.gettempdir()) / "albers_wall_gallery.HEAD.gd"
    src = subprocess.check_output(
        ["git", "show", "HEAD:algorithms/primitives/homagetothesquare/albers_wall_gallery.gd"], cwd=REPO)
    head.write_bytes(src)
    out = REPO / "ada_run" / "albers_glass_render" / "identity"
    out.mkdir(parents=True, exist_ok=True)
    run("mobile", ["--mode=identity", f"--head-source={head}"], out, resolution="1600x1000", stall=60)
    subprocess.call([sys.executable, str(REPO / "tools" / "albers_glass_identity_diff.py")], cwd=REPO)


def main() -> int:
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    if "--fresh" in sys.argv and ORACLE.exists():
        aside = ORACLE.with_name(f"albers_glass_oracle.{time.strftime('%Y%m%dT%H%M%S')}.json")
        os.replace(ORACLE, aside)
        print(f"moved the old oracle file aside: {aside.name}")
    RUN_DIR.mkdir(parents=True, exist_ok=True)
    if what in ("oracles", "all"):
        oracles(ORACLES)
    if what in ("variants", "all"):
        oracles(VARIANTS)
    if what in ("pictures", "all"):
        pictures()
    if what in ("identity", "all"):
        identity()
    if ORACLE.exists():
        o = json.loads(ORACLE.read_text(encoding="utf-8"))
        print("verdict:", o.get("verdict"))
        for k, v in o.get("summary", {}).items():
            print(f"  {k}: {v}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
