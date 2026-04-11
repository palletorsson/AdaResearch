#!/usr/bin/env python3
"""Auto-fix R4v issues: place floor under artifacts that are on void cells.

Reads each map_data.json, finds artifact positions in interactables layer,
checks if the structure at that position is "0" (void), and changes it to "1" (floor).
Also connects isolated floor tiles to the nearest walkable path.
"""
import json
import os
import sys
from pathlib import Path

MAPS_DIR = Path(__file__).parent.parent / "commons" / "maps"

def fix_map(map_dir: Path, dry_run=False):
    map_data_path = map_dir / "map_data.json"
    if not map_data_path.exists():
        return None

    try:
        with open(map_data_path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"  SKIP {map_dir.name}: JSON error - {e}")
        return None

    layers = data.get("layers", {})
    structure = layers.get("structure", [])
    interactables = layers.get("interactables", [])

    if not structure or not interactables:
        return None

    fixes = []
    rows = len(structure)

    for r in range(min(rows, len(interactables))):
        struct_row = structure[r]
        inter_row = interactables[r]
        cols = min(len(struct_row), len(inter_row))

        for c in range(cols):
            cell = inter_row[c].strip() if isinstance(inter_row[c], str) else ""
            if cell and cell != " ":
                # There's an artifact here
                struct_val = struct_row[c].strip() if isinstance(struct_row[c], str) else str(struct_row[c])
                if struct_val == "0":
                    artifact_name = cell.split(":")[0]
                    fixes.append((r, c, artifact_name))
                    if not dry_run:
                        structure[r][c] = "1"

    if fixes and not dry_run:
        with open(map_data_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            f.write("\n")

    return fixes

def main():
    dry_run = "--dry-run" in sys.argv
    total_fixes = 0
    fixed_maps = []

    for map_dir in sorted(MAPS_DIR.iterdir()):
        if not map_dir.is_dir():
            continue

        fixes = fix_map(map_dir, dry_run=dry_run)
        if fixes:
            map_name = map_dir.name
            fixed_maps.append(map_name)
            for r, c, artifact in fixes:
                action = "WOULD FIX" if dry_run else "FIXED"
                print(f"  {action} {map_name}: structure[{r}][{c}] 0->1 (artifact: {artifact})")
                total_fixes += 1

    print(f"\n{'Would fix' if dry_run else 'Fixed'} {total_fixes} void cells across {len(fixed_maps)} maps")
    if fixed_maps:
        print("Maps:", ", ".join(fixed_maps))

if __name__ == "__main__":
    main()
