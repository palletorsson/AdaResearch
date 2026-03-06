#!/usr/bin/env python3
"""
Batch capture screenshots for all scenes in scene-catalog.json.
Idempotent: skips scenes whose PNG already exists in the target directory.
"""

import json
import os
import shutil
import subprocess
import sys
import time

# ── Paths ─────────────────────────────────────────────────────────────────
GODOT_EXE = r"C:\Users\palle\Desktop\Godot_v4.6-stable_win64_console.exe"
PROJECT_DIR = r"C:\Users\palle\Documents\GitHub\AdaResearch_46"
CATALOG_JSON = r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\scene-catalog\scene-catalog.json"
SCREENSHOT_DIR = r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\scene-catalog"
GODOT_USERDATA = r"C:\Users\palle\AppData\Roaming\Godot\app_userdata\Ada Research Zero One\scene_shots"
CAPTURE_SCRIPT = "res://commons/testing/capture_tscn_shot.gd"
WAIT_SECONDS = "1.5"
TIMEOUT_SECONDS = 45


def main():
    # Sanity checks
    if not os.path.isfile(GODOT_EXE):
        print(f"ERROR: Godot executable not found: {GODOT_EXE}")
        sys.exit(1)
    if not os.path.isfile(CATALOG_JSON):
        print(f"ERROR: Catalog JSON not found: {CATALOG_JSON}")
        sys.exit(1)

    os.makedirs(SCREENSHOT_DIR, exist_ok=True)
    os.makedirs(GODOT_USERDATA, exist_ok=True)

    # Load catalog
    with open(CATALOG_JSON, "r", encoding="utf-8") as f:
        catalog = json.load(f)

    entries = catalog["entries"]
    total = len(entries)

    print(f"=== Batch Scene Capture ===")
    print(f"Total scenes in catalog: {total}")
    print()

    captured = 0
    skipped = 0
    failed = 0
    failed_list = []
    start_time = time.time()

    for i, entry in enumerate(entries):
        scene_path = entry["scenePath"]
        screenshot = entry["screenshot"]
        lookup = entry.get("lookupName") or ""
        png_filename = os.path.basename(screenshot)
        target_png = os.path.join(SCREENSHOT_DIR, png_filename)
        label = lookup or png_filename
        idx = i + 1

        # Skip if already exists
        if os.path.isfile(target_png):
            # Only print every 100th skip to reduce noise
            if idx % 100 == 0 or idx == total:
                print(f"[{idx}/{total}] ... skipping (already captured)")
            skipped += 1
            continue

        # Run Godot capture
        userdata_out = f"user://scene_shots/{png_filename}"
        print(f"[{idx}/{total}] {label} - capturing... ", end="", flush=True)

        cmd = [
            GODOT_EXE,
            "--path", PROJECT_DIR,
            "--xr-mode", "off",
            "--no-window",
            "--script", CAPTURE_SCRIPT,
            "--",
            f"--scene={scene_path}",
            f"--out={userdata_out}",
            f"--wait={WAIT_SECONDS}",
        ]

        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=TIMEOUT_SECONDS,
                cwd=PROJECT_DIR,
            )

            godot_output = os.path.join(GODOT_USERDATA, png_filename)

            if os.path.isfile(godot_output):
                shutil.copy2(godot_output, target_png)
                print("OK")
                captured += 1
            else:
                print("FAIL (no output PNG)")
                failed += 1
                failed_list.append(f"  - {label} ({scene_path})")

        except subprocess.TimeoutExpired:
            print("FAIL (timeout)")
            failed += 1
            failed_list.append(f"  - {label} ({scene_path}) [timeout]")
        except Exception as e:
            print(f"FAIL ({e})")
            failed += 1
            failed_list.append(f"  - {label} ({scene_path}) [{e}]")

        # Print progress every 50 captures
        if captured > 0 and captured % 50 == 0:
            elapsed = time.time() - start_time
            rate = captured / elapsed if elapsed > 0 else 0
            remaining = (total - skipped - captured - failed) / rate if rate > 0 else 0
            print(f"    --- Progress: {captured} captured, {failed} failed, ~{remaining/60:.0f} min remaining ---")

    # ── Update catalog JSON ────────────────────────────────────────────────────
    print()
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

    print(f"Updated {updated} entries to hasScreenshot=true")

    # ── Summary ────────────────────────────────────────────────────────────────
    elapsed = time.time() - start_time
    print()
    print(f"=== Capture Summary ===")
    print(f"  Total:    {total}")
    print(f"  Captured: {captured}")
    print(f"  Skipped:  {skipped} (already existed)")
    print(f"  Failed:   {failed}")
    print(f"  Time:     {elapsed/60:.1f} minutes")

    if failed_list:
        print()
        print("Failed scenes:")
        for line in failed_list:
            print(line)

    print()
    print("Done.")


if __name__ == "__main__":
    main()
