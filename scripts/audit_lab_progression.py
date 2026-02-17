#!/usr/bin/env python3
"""
audit_lab_progression.py — Audit Lab evolution maps for continuity.

Each post-map should be a superset of the previous:
- Structure cells should not disappear (floor->void)
- Teleporters from previous should persist
- New content should only ADD, not remove

Usage:
    python scripts/audit_lab_progression.py
    python scripts/audit_lab_progression.py --diff      # Show cell-by-cell changes
    python scripts/audit_lab_progression.py --visual    # ASCII map comparison
"""

import argparse
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
LAB = REPO / "commons" / "maps" / "Lab"
SPINE = REPO / "commons" / "maps" / "curriculum_spine.json"


def safe_print(text: str):
    try:
        print(text)
    except UnicodeEncodeError:
        print(text.encode("ascii", "replace").decode("ascii"))


def cell_height(val) -> int:
    try:
        return int(val)
    except (ValueError, TypeError):
        return 0


def load_lab_map(filename: str) -> dict | None:
    path = LAB / filename
    if not path.is_file():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


def get_grid(data: dict, layer: str) -> list[list[str]]:
    """Get a layer as normalized grid of strings."""
    raw = data.get("layers", {}).get(layer, [])
    return [[str(c).strip() for c in row] for row in raw]


def cell_at(grid: list, z: int, x: int) -> str:
    if z < len(grid) and x < len(grid[z]):
        return grid[z][x]
    return ""


def find_teleporters(utils: list) -> dict:
    """Return {(x,z): teleporter_value}."""
    tps = {}
    for z, row in enumerate(utils):
        for x, cell in enumerate(row):
            c = str(cell).strip()
            if c == "t" or c.startswith("t:"):
                tps[(x, z)] = c
    return tps


def find_artifacts(inter: list) -> dict:
    """Return {(x,z): artifact_value}."""
    arts = {}
    for z, row in enumerate(inter):
        for x, cell in enumerate(row):
            c = str(cell).strip()
            if c and c != " ":
                arts[(x, z)] = c
    return arts


def compare_stages(prev_data, curr_data, prev_name, curr_name, show_diff=False):
    """Compare two lab stages. Report what changed."""
    issues = []
    changes = []

    prev_struct = get_grid(prev_data, "structure")
    curr_struct = get_grid(curr_data, "structure")
    prev_utils = get_grid(prev_data, "utilities")
    curr_utils = get_grid(curr_data, "utilities")
    prev_inter = get_grid(prev_data, "interactables")
    curr_inter = get_grid(curr_data, "interactables")

    prev_rows = len(prev_struct)
    prev_cols = max(len(r) for r in prev_struct) if prev_struct else 0
    curr_rows = len(curr_struct)
    curr_cols = max(len(r) for r in curr_struct) if curr_struct else 0

    # Check structure continuity — cells in the previous map should not become void
    for z in range(prev_rows):
        for x in range(prev_cols):
            ph = cell_height(cell_at(prev_struct, z, x))
            ch = cell_height(cell_at(curr_struct, z, x))

            if ph > 0 and ch == 0:
                issues.append(f"STRUCTURE LOST: ({x},{z}) was h={ph}, now void")
            elif ph != ch and ph > 0:
                changes.append(f"structure ({x},{z}): h={ph} -> h={ch}")

    # Check teleporter continuity
    prev_tps = find_teleporters(prev_utils)
    curr_tps = find_teleporters(curr_utils)

    for pos, val in prev_tps.items():
        if pos not in curr_tps:
            # Check if it moved nearby
            issues.append(f"TELEPORTER LOST: {val} at {pos}")
        elif curr_tps[pos] != val:
            changes.append(f"teleporter {pos}: '{val}' -> '{curr_tps[pos]}'")

    new_tps = {pos: val for pos, val in curr_tps.items() if pos not in prev_tps}
    for pos, val in new_tps.items():
        changes.append(f"NEW teleporter: {val} at {pos}")

    # Check artifact continuity
    prev_arts = find_artifacts(prev_inter)
    curr_arts = find_artifacts(curr_inter)

    for pos, val in prev_arts.items():
        if pos not in curr_arts:
            name = val.split(":")[0].split("#")[0]
            issues.append(f"ARTIFACT LOST: {name} at {pos}")
        elif curr_arts[pos] != val:
            pname = val.split(":")[0].split("#")[0]
            cname = curr_arts[pos].split(":")[0].split("#")[0]
            if pname != cname:
                issues.append(f"ARTIFACT REPLACED: {pname} -> {cname} at {pos}")
            else:
                changes.append(f"artifact {pos}: config changed")

    new_arts = {pos: val for pos, val in curr_arts.items() if pos not in prev_arts}
    for pos, val in new_arts.items():
        name = val.split(":")[0].split("#")[0]
        changes.append(f"NEW artifact: {name} at {pos}")

    # Check utility continuity (non-teleporter utilities)
    for z in range(prev_rows):
        for x in range(prev_cols):
            pu = cell_at(prev_utils, z, x)
            cu = cell_at(curr_utils, z, x)
            if pu and pu != " " and not pu.startswith("t"):
                if (not cu or cu == " "):
                    issues.append(f"UTILITY LOST: '{pu}' at ({x},{z})")

    return issues, changes


def visual_map(data: dict, label: str, max_width: int = 60):
    """Print ASCII visualization of a lab map."""
    struct = get_grid(data, "structure")
    utils = get_grid(data, "utilities")
    inter = get_grid(data, "interactables")

    safe_print(f"\n  {label}")
    safe_print(f"  {'='*40}")

    height_chars = {0: ".", 1: "_", 2: "=", 3: "#", 4: "|", 5: "|", 6: "|"}

    for z, row in enumerate(struct):
        line = "  "
        for x, cell in enumerate(row):
            h = cell_height(cell)
            u = cell_at(utils, z, x)
            a = cell_at(inter, z, x)

            if u.startswith("t:") or u == "t":
                line += "T"
            elif u.startswith("tc"):
                line += "^"
            elif u.startswith("wp"):
                line += "/"
            elif a and a != " ":
                line += "*"
            else:
                line += height_chars.get(h, str(h))
        safe_print(line)


def main():
    parser = argparse.ArgumentParser(description="Audit Lab progression continuity")
    parser.add_argument("--diff", action="store_true", help="Show all changes")
    parser.add_argument("--visual", action="store_true", help="ASCII map visualization")
    args = parser.parse_args()

    spine = json.loads(SPINE.read_text(encoding="utf-8"))
    progression = spine["lab_evolution"]["actual_progression"]

    safe_print(f"{'='*60}")
    safe_print(f"LAB PROGRESSION AUDIT")
    safe_print(f"{'='*60}")

    total_issues = 0
    prev_data = None
    prev_name = None

    for entry in progression:
        lab_file = entry["lab_file"]
        after = entry.get("after", "none")
        added = entry.get("added", [])

        data = load_lab_map(lab_file)
        if data is None:
            safe_print(f"\n!! MISSING: {lab_file}")
            continue

        struct = get_grid(data, "structure")
        rows = len(struct)
        cols = max(len(r) for r in struct) if struct else 0
        tps = find_teleporters(get_grid(data, "utilities"))

        safe_print(f"\n--- After: {after} ---")
        safe_print(f"  File: {lab_file}")
        safe_print(f"  Size: {rows}x{cols}  Teleporters: {len(tps)}")
        if added:
            safe_print(f"  Adds: {', '.join(added)}")

        # Teleporter destinations
        for pos, val in sorted(tps.items()):
            safe_print(f"    T {pos}: {val}")

        if args.visual:
            visual_map(data, f"After {after}")

        if prev_data is not None:
            issues, changes = compare_stages(prev_data, data, prev_name, lab_file, show_diff=args.diff)

            if issues:
                safe_print(f"\n  ISSUES ({len(issues)}):")
                for issue in issues:
                    safe_print(f"    !! {issue}")
                total_issues += len(issues)

            if args.diff and changes:
                safe_print(f"\n  Changes ({len(changes)}):")
                for change in changes[:20]:
                    safe_print(f"    >> {change}")
                if len(changes) > 20:
                    safe_print(f"    ... +{len(changes)-20} more")

        prev_data = data
        prev_name = lab_file

    safe_print(f"\n{'='*60}")
    if total_issues == 0:
        safe_print("ALL CLEAR: Every stage preserves the previous.")
    else:
        safe_print(f"TOTAL ISSUES: {total_issues} continuity breaks found.")
    safe_print(f"{'='*60}")


if __name__ == "__main__":
    sys.exit(main())
