#!/usr/bin/env python3
"""
Batch capture screenshots for all scenes in scene-catalog.json.

Uses batch_capture_inline.gd to run ALL captures in a single Godot process
(no restart per scene — much faster than the old per-scene approach).

The GDScript handles:
  - Reading the catalog JSON
  - Skipping scenes whose PNG already exists (idempotent)
  - Building environment scaffold once, reusing for all scenes
  - Capturing screenshots and saving directly to the output directory

This Python wrapper:
  - Validates paths and launches the single Godot process
  - Updates scene-catalog.json hasScreenshot flags afterwards
"""

import json
import os
import subprocess
import sys
import time

# ── Paths ─────────────────────────────────────────────────────────────────
GODOT_EXE = r"C:\Users\palle\Desktop\Godot_v4.6-stable_win64_console.exe"
PROJECT_DIR = r"C:\Users\palle\Documents\GitHub\AdaResearch_46"
CATALOG_JSON = r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\scene-catalog\scene-catalog.json"
SCREENSHOT_DIR = r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\scene-catalog"
BATCH_SCRIPT = "res://commons/testing/batch_capture_inline.gd"
WAIT_SECONDS = "1.0"


def main():
    # ── Sanity checks ─────────────────────────────────────────────────────
    if not os.path.isfile(GODOT_EXE):
        print(f"ERROR: Godot executable not found: {GODOT_EXE}")
        sys.exit(1)
    if not os.path.isfile(CATALOG_JSON):
        print(f"ERROR: Catalog JSON not found: {CATALOG_JSON}")
        sys.exit(1)

    os.makedirs(SCREENSHOT_DIR, exist_ok=True)

    # Count how many need capturing vs already exist
    with open(CATALOG_JSON, "r", encoding="utf-8") as f:
        catalog = json.load(f)

    entries = catalog["entries"]
    total = len(entries)
    existing = sum(
        1 for e in entries
        if os.path.isfile(os.path.join(SCREENSHOT_DIR, os.path.basename(e["screenshot"])))
    )

    print(f"=== Batch Scene Capture (single-process) ===")
    print(f"Total scenes in catalog: {total}")
    print(f"Already captured:        {existing}")
    print(f"To capture:              {total - existing}")
    print()

    if existing == total:
        print("All screenshots already exist. Use --no-skip to recapture.")
        print("To recapture, delete the PNGs first or pass --no-skip.")
        # Still update catalog
        _update_catalog(catalog, entries)
        return

    # ── Run single Godot process with batch_capture_inline.gd ─────────────
    # Convert paths to forward slashes for Godot
    catalog_path = CATALOG_JSON.replace("\\", "/")
    output_dir = SCREENSHOT_DIR.replace("\\", "/")

    skip_flag = "--skip-existing"
    if "--no-skip" in sys.argv:
        skip_flag = "--no-skip"

    cmd = [
        GODOT_EXE,
        "--path", PROJECT_DIR,
        "--xr-mode", "off",
        "--no-window",
        "--script", BATCH_SCRIPT,
        "--",
        f"--catalog={catalog_path}",
        f"--outdir={output_dir}",
        f"--wait={WAIT_SECONDS}",
        skip_flag,
    ]

    print("Running Godot batch capture (single process, all scenes)...")
    print(f"  Command: {' '.join(cmd[:7])} -- ...")
    print()

    start_time = time.time()

    try:
        # No timeout — the batch captures hundreds of scenes in one process
        # and handles its own timing internally
        result = subprocess.run(
            cmd,
            cwd=PROJECT_DIR,
            timeout=7200,  # 2 hour safety timeout
        )
        print()
        print(f"Godot process exited with code: {result.returncode}")

    except subprocess.TimeoutExpired:
        print("\nERROR: Godot process timed out after 2 hours")
        sys.exit(1)
    except Exception as e:
        print(f"\nERROR: {e}")
        sys.exit(1)

    elapsed = time.time() - start_time
    print(f"Total Godot time: {elapsed/60:.1f} minutes")
    print()

    # ── Update catalog JSON ────────────────────────────────────────────────
    # Re-read catalog in case it changed
    with open(CATALOG_JSON, "r", encoding="utf-8") as f:
        catalog = json.load(f)

    _update_catalog(catalog, catalog["entries"])

    print()
    print("Done.")


def _update_catalog(catalog, entries):
    """Update hasScreenshot flags in scene-catalog.json."""
    print("=== Updating scene-catalog.json ===")
    updated = 0
    for entry in entries:
        screenshot = entry["screenshot"]
        png_filename = os.path.basename(screenshot)
        full_path = os.path.join(SCREENSHOT_DIR, png_filename)
        had = entry.get("hasScreenshot", False)
        now = os.path.isfile(full_path)
        entry["hasScreenshot"] = now
        if now and not had:
            updated += 1

    with open(CATALOG_JSON, "w", encoding="utf-8") as f:
        json.dump(catalog, f, indent=2, ensure_ascii=False)
        f.write("\n")

    total_with = sum(1 for e in entries if e.get("hasScreenshot"))
    print(f"Updated {updated} entries to hasScreenshot=true")
    print(f"Total with screenshots: {total_with}/{len(entries)}")


if __name__ == "__main__":
    main()
