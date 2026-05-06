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
  - Auto-restarts on crash (some scenes cause Godot segfaults during cleanup)
  - Tracks crashing scenes and creates dummy PNGs so they get skipped on retry
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
MAX_RETRIES = 20  # max Godot restarts before giving up


def main():
    # ── Sanity checks ─────────────────────────────────────────────────────
    if not os.path.isfile(GODOT_EXE):
        print(f"ERROR: Godot executable not found: {GODOT_EXE}")
        sys.exit(1)
    if not os.path.isfile(CATALOG_JSON):
        print(f"ERROR: Catalog JSON not found: {CATALOG_JSON}")
        sys.exit(1)

    os.makedirs(SCREENSHOT_DIR, exist_ok=True)

    skip_flag = "--skip-existing"
    if "--no-skip" in sys.argv:
        skip_flag = "--no-skip"

    # Convert paths to forward slashes for Godot
    catalog_path = CATALOG_JSON.replace("\\", "/")
    output_dir = SCREENSHOT_DIR.replace("\\", "/")

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

    total_start = time.time()
    attempt = 0

    while attempt < MAX_RETRIES:
        # Count remaining
        remaining = _count_remaining()
        if remaining == 0:
            print("All screenshots captured!")
            break

        attempt += 1
        print(f"\n{'='*60}")
        print(f"  Godot run #{attempt}  —  {remaining} scenes remaining")
        print(f"{'='*60}\n")

        before_count = _count_existing()

        try:
            result = subprocess.run(
                cmd,
                cwd=PROJECT_DIR,
                timeout=7200,
            )
            exit_code = result.returncode
        except subprocess.TimeoutExpired:
            print("\nERROR: Godot process timed out after 2 hours")
            exit_code = -1
        except Exception as e:
            print(f"\nERROR: {e}")
            exit_code = -1

        after_count = _count_existing()
        new_captures = after_count - before_count

        if exit_code == 0:
            print(f"\nGodot exited cleanly. Captured {new_captures} new screenshots.")
            break
        else:
            print(f"\nGodot crashed (exit code {exit_code}). Captured {new_captures} new screenshots before crash.")

            if new_captures == 0:
                # Find which scene is next (the one causing the crash)
                crasher = _find_next_uncaptured()
                if crasher:
                    print(f"  Likely crasher: {crasher}")
                    print(f"  Creating empty marker so it gets skipped on retry...")
                    _create_skip_marker(crasher)
                else:
                    print("  Could not identify crashing scene. Stopping.")
                    break

            print(f"  Restarting Godot (attempt {attempt + 1}/{MAX_RETRIES})...")

    # ── Summary ───────────────────────────────────────────────────────────
    total_elapsed = time.time() - total_start
    print(f"\nTotal time: {total_elapsed/60:.1f} minutes across {attempt} Godot run(s)")

    # ── Update catalog JSON ────────────────────────────────────────────────
    with open(CATALOG_JSON, "r", encoding="utf-8") as f:
        catalog = json.load(f)

    _update_catalog(catalog, catalog["entries"])

    # Report skip markers
    markers = [f for f in os.listdir(SCREENSHOT_DIR) if f.endswith(".png") and os.path.getsize(os.path.join(SCREENSHOT_DIR, f)) < 100]
    if markers:
        print(f"\nSkip markers (empty PNGs for crashing scenes): {len(markers)}")
        for m in markers:
            print(f"  - {m}")
        print("These scenes crashed Godot and need manual investigation.")

    print("\nDone.")


def _count_existing():
    """Count how many PNGs exist in the screenshot directory."""
    with open(CATALOG_JSON, "r", encoding="utf-8") as f:
        catalog = json.load(f)
    return sum(
        1 for e in catalog["entries"]
        if os.path.isfile(os.path.join(SCREENSHOT_DIR, os.path.basename(e["screenshot"])))
    )


def _count_remaining():
    """Count how many scenes still need screenshots."""
    with open(CATALOG_JSON, "r", encoding="utf-8") as f:
        catalog = json.load(f)
    return sum(
        1 for e in catalog["entries"]
        if not os.path.isfile(os.path.join(SCREENSHOT_DIR, os.path.basename(e["screenshot"])))
    )


def _find_next_uncaptured():
    """Find the first scene in catalog order that doesn't have a PNG."""
    with open(CATALOG_JSON, "r", encoding="utf-8") as f:
        catalog = json.load(f)
    for e in catalog["entries"]:
        png = os.path.join(SCREENSHOT_DIR, os.path.basename(e["screenshot"]))
        if not os.path.isfile(png):
            return e
    return None


def _create_skip_marker(entry):
    """Create a tiny marker PNG so the crashing scene gets skipped on next run."""
    png_name = os.path.basename(entry["screenshot"])
    marker_path = os.path.join(SCREENSHOT_DIR, png_name)
    # Write a minimal valid file (not a real PNG, but enough for file_exists check)
    with open(marker_path, "wb") as f:
        f.write(b"SKIP")  # tiny marker file


def _update_catalog(catalog, entries):
    """Update hasScreenshot flags in scene-catalog.json."""
    print("=== Updating scene-catalog.json ===")
    updated = 0
    for entry in entries:
        screenshot = entry["screenshot"]
        png_filename = os.path.basename(screenshot)
        full_path = os.path.join(SCREENSHOT_DIR, png_filename)
        had = entry.get("hasScreenshot", False)
        now = os.path.isfile(full_path) and os.path.getsize(full_path) > 100
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
