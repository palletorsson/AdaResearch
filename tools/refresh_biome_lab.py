#!/usr/bin/env python3
"""
Refresh the entire biome lab in one command.

Five steps:

  1. Regenerate Biome_Zoo + Biome_Spine maps from SPINE_STAGES /
     ZOO_ZONES (calls generate_biome_lab_maps.py)
  2. Capture top-down hero shots via capture_multi_angle.gd (the
     "view from above" image — both maps, all angles)
  3. Walk each corridor in Godot via biome_corridor_capture.gd
     and snap a drone-shot photo at every zone centre
  4. Copy all PNGs + walk reports into the encyclopedia public dir
  5. Save a dated copy of the spine top-down hero into biome-history/
     for visual-diff regression checks down the line

Single command. After it finishes, the entire /biome-spine and
/biome-zoo encyclopedia surface is regenerated from the current
SPINE_STAGES + ZOO_ZONES + KINGDOM_COLORS.

Run:
  python tools/refresh_biome_lab.py
  python tools/refresh_biome_lab.py --skip-walk    # faster, skip per-zone
  python tools/refresh_biome_lab.py --skip-generate --skip-top-down  # only walk + copy

Override paths via env vars if your setup differs:
  GODOT_EXE              path to Godot executable
  ADA_ENCYCLOPEDIA_PATH  path to ada_encyclopedia repo
  GODOT_USER_DATA        path to Godot's user:// directory for this project
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import time
import json
from datetime import datetime
from pathlib import Path


# ────────────────────────────────────────────────────────────────────
# Configuration
# ────────────────────────────────────────────────────────────────────
GODOT_EXE = Path(os.environ.get(
    "GODOT_EXE",
    r"C:\Users\palle\Desktop\Godot_v4.6-stable_win64.exe",
))
PROJECT_ROOT = Path(__file__).resolve().parent.parent
ENCYCLOPEDIA = Path(os.environ.get(
    "ADA_ENCYCLOPEDIA_PATH",
    r"C:\Users\palle\Documents\GitHub\ada_encyclopedia",
))
GODOT_USER_DATA = Path(os.environ.get(
    "GODOT_USER_DATA",
    r"C:\Users\palle\AppData\Roaming\Godot\app_userdata\Ada Research Zero One",
))

# Maps to refresh. Each entry pairs the Godot map name with its slug
# in the encyclopedia public dir.
MAPS: list[tuple[str, str]] = [
    ("Biome_Spine", "spine"),
    ("Biome_Zoo",   "zoo"),
]
ZONE_WIDTH = 4


# ────────────────────────────────────────────────────────────────────
# Run helpers
# ────────────────────────────────────────────────────────────────────
def banner(title: str) -> None:
    line = "=" * 64
    print(f"\n{line}\n  {title}\n{line}")


def run(cmd: list, label: str = "", cwd: Path | None = None) -> int:
    """Run a subprocess streaming output. Returns exit code."""
    if label:
        print(f"\n  > {label}")
    print(f"    $ {' '.join(str(c) for c in cmd)}")
    t0 = time.time()
    try:
        result = subprocess.run(
            [str(c) for c in cmd],
            cwd=str(cwd or PROJECT_ROOT),
            check=False,
        )
        elapsed = time.time() - t0
        print(f"    -> exit {result.returncode}  ({elapsed:.1f}s)")
        return result.returncode
    except FileNotFoundError as e:
        print(f"    FAIL: {e}")
        return 127


def godot_run(script: str, extra_args: list[str], label: str) -> int:
    """Run a Godot script in headless / no-window mode."""
    cmd = [
        GODOT_EXE,
        "--path", PROJECT_ROOT,
        "--xr-mode", "off",
        "--no-window",
        "--script", script,
        "--",
        *extra_args,
    ]
    return run(cmd, label=label)


# ────────────────────────────────────────────────────────────────────
# Steps
# ────────────────────────────────────────────────────────────────────
def step_generate() -> bool:
    banner("STEP 1 * Regenerating maps from SPINE_STAGES / ZOO_ZONES")
    rc = run(
        [sys.executable, "tools/generate_biome_lab_maps.py"],
        label="generate_biome_lab_maps.py",
    )
    return rc == 0


def step_top_down() -> bool:
    banner("STEP 2 * Capturing top-down hero shots")
    ok = True
    for map_name, _slug in MAPS:
        rc = godot_run(
            "res://commons/testing/capture_multi_angle.gd",
            [
                "--mode=map",
                f"--target={map_name}",
                "--out=user://biome_lab_shots",
            ],
            label=f"top-down: {map_name}",
        )
        if rc != 0:
            print(f"    WARN: capture_multi_angle returned {rc} for {map_name}")
            ok = False
    return ok


def step_walk() -> bool:
    banner("STEP 3 * Walking corridors (drone-shot per zone)")
    ok = True
    for map_name, _slug in MAPS:
        rc = godot_run(
            "res://commons/testing/biome_corridor_capture.gd",
            [
                f"--target={map_name}",
                f"--zone-width={ZONE_WIDTH}",
                "--out=user://biome_corridor",
            ],
            label=f"corridor walk: {map_name}",
        )
        if rc != 0:
            print(f"    WARN: biome_corridor_capture returned {rc} for {map_name}")
            ok = False
    return ok


def step_copy() -> bool:
    banner("STEP 4 * Copying captures into encyclopedia")
    public = ENCYCLOPEDIA / "public"
    if not public.exists():
        print(f"  FAIL: encyclopedia public dir missing - {public}")
        return False

    biome_lab = public / "biome-lab"
    biome_lab.mkdir(parents=True, exist_ok=True)

    # Top-down hero shots — copy with <slug>_<angle>.png so the page can
    # reference them by mode (e.g. /biome-lab/spine_top.png).
    for map_name, slug in MAPS:
        src_dir = GODOT_USER_DATA / "biome_lab_shots" / map_name
        if not src_dir.exists():
            print(f"  * skip top-down: {src_dir} missing")
            continue
        n = 0
        for png in src_dir.glob("*.png"):
            dst = biome_lab / f"{slug}_{png.name}"
            shutil.copy2(png, dst)
            n += 1
        print(f"  * copied {n} top-down PNGs for {map_name} -> biome-lab/{slug}_*.png")

    # Per-zone corridor walks — into biome-corridor/<slug>/
    for map_name, slug in MAPS:
        src_dir = GODOT_USER_DATA / "biome_corridor" / map_name
        if not src_dir.exists():
            print(f"  * skip walk: {src_dir} missing")
            continue
        dst_dir = public / "biome-corridor" / slug
        dst_dir.mkdir(parents=True, exist_ok=True)
        n = 0
        for f in src_dir.iterdir():
            if f.suffix in {".png", ".json"}:
                shutil.copy2(f, dst_dir / f.name)
                n += 1
        print(f"  * copied {n} files for {map_name} -> biome-corridor/{slug}/")

    return True


def step_history() -> bool:
    """Archive a timestamped copy of the spine top-down for visual-diff
    regression. Each run gets a unique filename (ISO timestamp), so re-running
    the pipeline multiple times in one day produces multiple snapshots — that's
    what makes the /biome-history page useful: you can pick any two and diff
    them. Also writes a manifest.json so the page can enumerate snapshots
    without server-side filesystem access.
    """
    banner("STEP 5 * Archiving dated history copy")
    history = ENCYCLOPEDIA / "public" / "biome-history"
    history.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    saved: list[str] = []
    # Spine top-down is the canonical regression target.
    src = ENCYCLOPEDIA / "public" / "biome-lab" / "spine_top.png"
    if not src.exists():
        print(f"  * skip: {src} missing - run step 4 first")
        return False
    dst = history / f"spine_top_{stamp}.png"
    shutil.copy2(src, dst)
    saved.append(dst.name)
    # iso_perfect reads better as the hero — keep both available.
    iso = ENCYCLOPEDIA / "public" / "biome-lab" / "spine_iso_perfect.png"
    if iso.exists():
        dst_iso = history / f"spine_iso_perfect_{stamp}.png"
        shutil.copy2(iso, dst_iso)
        saved.append(dst_iso.name)

    # Rebuild manifest.json from the directory contents. Always read
    # everything so manually-added snapshots show up too.
    manifest: list[dict] = []
    for png in sorted(history.glob("spine_top_*.png")):
        # Filename pattern: spine_top_YYYYMMDD_HHMMSS.png
        name_stamp = png.stem.replace("spine_top_", "")
        iso_path = history / f"spine_iso_perfect_{name_stamp}.png"
        manifest.append({
            "stamp": name_stamp,
            "top": f"/biome-history/{png.name}",
            "iso": f"/biome-history/{iso_path.name}" if iso_path.exists() else None,
            "size_kb": round(png.stat().st_size / 1024, 1),
        })
    # Newest first.
    manifest.sort(key=lambda e: e["stamp"], reverse=True)
    manifest_path = history / "manifest.json"
    manifest_path.write_text(
        json.dumps({"snapshots": manifest}, indent=2),
        encoding="utf-8",
    )

    print(f"  * saved {len(saved)} timestamped copies to biome-history/")
    for n in saved:
        print(f"      {n}")
    print(f"  * manifest now lists {len(manifest)} snapshot(s)")
    return True


# ────────────────────────────────────────────────────────────────────
# Entry
# ────────────────────────────────────────────────────────────────────
def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__.split("\n\n")[0],
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("--skip-generate",  action="store_true",
                    help="step 1: skip map regeneration")
    ap.add_argument("--skip-top-down",  action="store_true",
                    help="step 2: skip top-down hero captures")
    ap.add_argument("--skip-walk",      action="store_true",
                    help="step 3: skip per-zone corridor walks")
    ap.add_argument("--skip-copy",      action="store_true",
                    help="step 4: skip copying captures to encyclopedia")
    ap.add_argument("--skip-history",   action="store_true",
                    help="step 5: skip saving dated history copy")
    args = ap.parse_args()

    print(f"GODOT_EXE     = {GODOT_EXE}")
    print(f"PROJECT_ROOT  = {PROJECT_ROOT}")
    print(f"ENCYCLOPEDIA  = {ENCYCLOPEDIA}")
    print(f"USER_DATA     = {GODOT_USER_DATA}")

    if not GODOT_EXE.exists():
        print(f"\nFATAL: Godot executable not found at {GODOT_EXE}")
        print("  Set GODOT_EXE env var to override.")
        return 2

    results: list[tuple[str, bool]] = []
    t0 = time.time()
    if not args.skip_generate:  results.append(("generate", step_generate()))
    if not args.skip_top_down:  results.append(("top-down", step_top_down()))
    if not args.skip_walk:      results.append(("walk",     step_walk()))
    if not args.skip_copy:      results.append(("copy",     step_copy()))
    if not args.skip_history:   results.append(("history",  step_history()))
    elapsed = time.time() - t0

    banner("Summary")
    for name, ok in results:
        marker = "OK  " if ok else "FAIL"
        print(f"  {marker}  {name}")
    print(f"\n  total: {elapsed:.1f}s")

    print("\n  -> reload http://localhost:3003/biome-spine")
    print("  -> reload http://localhost:3003/biome-zoo\n")

    return 0 if all(ok for _, ok in results) else 1


if __name__ == "__main__":
    sys.exit(main())
