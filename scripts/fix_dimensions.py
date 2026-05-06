#!/usr/bin/env python3
"""
fix_dimensions.py — Fix layer dimension mismatches in map_data.json files.

Structure is the ground truth. Utilities and interactables get padded or
trimmed to match.

- Short layers: pad with " " rows/cells
- Extra rows with only " " cells: trimmed
- Extra rows with content: kept (structure extended with 0-height row) + warning

Usage:
    python scripts/fix_dimensions.py --dry-run          # Preview
    python scripts/fix_dimensions.py                    # Fix all mismatched
    python scripts/fix_dimensions.py path/to/file       # Fix one file
"""

import argparse
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
MAPS_DIR = REPO / "commons" / "maps"

# Intentional mismatches — skip these
EXCEPTIONS = {"Noise_Voxel", "Random_Definition"}


def safe_print(text: str):
    try:
        print(text)
    except UnicodeEncodeError:
        print(text.encode("ascii", "replace").decode("ascii"))


def row_is_empty(row: list) -> bool:
    """Check if a row contains only whitespace/empty cells."""
    return all(str(c).strip() == "" for c in row)


def fix_map(path: Path, dry_run: bool = False) -> dict:
    """Fix dimension mismatches. Returns {status, changes}."""
    map_name = path.parent.name
    if map_name in EXCEPTIONS:
        return {"status": "skipped", "reason": "exception list"}

    try:
        raw = path.read_text(encoding="utf-8")
        data = json.loads(raw)
    except Exception as e:
        return {"status": "error", "reason": f"JSON parse: {e}"}

    layers = data.get("layers", {})
    structure = layers.get("structure")
    if not structure:
        return {"status": "error", "reason": "no structure layer"}

    utilities = layers.get("utilities", [])
    interactables = layers.get("interactables", [])

    s_rows = len(structure)
    s_cols = [len(r) for r in structure]
    max_cols = max(s_cols) if s_cols else 0

    changes = []
    modified = False

    # Fix structure rows that are short on columns
    for i, row in enumerate(structure):
        if len(row) < max_cols:
            pad = max_cols - len(row)
            structure[i] = row + [0] * pad
            changes.append(f"structure row {i}: padded {pad} cols with 0")
            modified = True

    # Fix utilities
    if utilities:
        u_rows = len(utilities)

        # Extra rows
        if u_rows > s_rows:
            extra = utilities[s_rows:]
            non_empty_extra = [i for i, r in enumerate(extra) if not row_is_empty(r)]
            if non_empty_extra:
                # Extra rows have content — extend structure with void rows
                for idx in non_empty_extra:
                    changes.append(f"utilities extra row {s_rows + idx} has content: {extra[idx]}")
                # Extend structure to match
                while len(structure) < u_rows:
                    structure.append([0] * max_cols)
                    changes.append(f"structure: added void row {len(structure)-1} to accommodate utilities")
                s_rows = len(structure)
                modified = True
            else:
                # Extra rows are empty — trim
                utilities = utilities[:s_rows]
                changes.append(f"utilities: trimmed {u_rows - s_rows} empty rows")
                modified = True

        # Short rows
        if len(utilities) < s_rows:
            pad = s_rows - len(utilities)
            for _ in range(pad):
                utilities.append([" "] * max_cols)
            changes.append(f"utilities: padded {pad} rows")
            modified = True

        # Fix column counts per row
        for i, row in enumerate(utilities):
            if len(row) < max_cols:
                pad = max_cols - len(row)
                utilities[i] = row + [" "] * pad
                changes.append(f"utilities row {i}: padded {pad} cols")
                modified = True
            elif len(row) > max_cols:
                extra_cells = row[max_cols:]
                if all(str(c).strip() == "" for c in extra_cells):
                    utilities[i] = row[:max_cols]
                    changes.append(f"utilities row {i}: trimmed {len(extra_cells)} empty cols")
                    modified = True
                else:
                    changes.append(f"utilities row {i}: {len(row)} cols > structure {max_cols} (has content, kept)")

    # Fix interactables
    if interactables:
        i_rows = len(interactables)

        # Extra rows
        if i_rows > s_rows:
            extra = interactables[s_rows:]
            non_empty_extra = [i for i, r in enumerate(extra) if not row_is_empty(r)]
            if non_empty_extra:
                for idx in non_empty_extra:
                    changes.append(f"interactables extra row {s_rows + idx} has content: {extra[idx]}")
                while len(structure) < i_rows:
                    structure.append([0] * max_cols)
                    changes.append(f"structure: added void row {len(structure)-1} to accommodate interactables")
                s_rows = len(structure)
                # Also extend utilities if needed
                while len(utilities) < s_rows:
                    utilities.append([" "] * max_cols)
                    changes.append(f"utilities: added empty row to match extended structure")
                modified = True
            else:
                interactables = interactables[:s_rows]
                changes.append(f"interactables: trimmed {i_rows - s_rows} empty rows")
                modified = True

        # Short rows
        if len(interactables) < s_rows:
            pad = s_rows - len(interactables)
            for _ in range(pad):
                interactables.append([" "] * max_cols)
            changes.append(f"interactables: padded {pad} rows")
            modified = True

        # Fix column counts per row
        for i, row in enumerate(interactables):
            if len(row) < max_cols:
                pad = max_cols - len(row)
                interactables[i] = row + [" "] * pad
                changes.append(f"interactables row {i}: padded {pad} cols")
                modified = True
            elif len(row) > max_cols:
                extra_cells = row[max_cols:]
                if all(str(c).strip() == "" for c in extra_cells):
                    interactables[i] = row[:max_cols]
                    changes.append(f"interactables row {i}: trimmed {len(extra_cells)} empty cols")
                    modified = True
                else:
                    changes.append(f"interactables row {i}: {len(row)} cols > structure {max_cols} (has content, kept)")

    if not modified:
        return {"status": "ok", "changes": []}

    # Write back
    layers["structure"] = structure
    if utilities:
        layers["utilities"] = utilities
    if interactables:
        layers["interactables"] = interactables

    if not dry_run:
        # Use compact row format
        sys.path.insert(0, str(REPO / "scripts"))
        from format_map_json import compact_json
        output = compact_json(data)
        path.write_text(output, encoding="utf-8")

    return {"status": "fixed" if not dry_run else "would_fix", "changes": changes}


def find_mismatched_maps() -> list[Path]:
    """Find maps with dimension mismatches."""
    maps = []
    for md in sorted(MAPS_DIR.rglob("map_data*.json")):
        if "sequences" in str(md) or "Structure_Examples" in str(md):
            continue
        try:
            data = json.loads(md.read_text(encoding="utf-8"))
        except Exception:
            continue

        layers = data.get("layers", {})
        structure = layers.get("structure", [])
        utilities = layers.get("utilities", [])
        interactables = layers.get("interactables", [])

        if not structure:
            continue

        s_rows = len(structure)
        s_cols = max(len(r) for r in structure) if structure else 0

        mismatch = False
        if utilities and len(utilities) != s_rows:
            mismatch = True
        if interactables and len(interactables) != s_rows:
            mismatch = True

        # Check column mismatches
        for layer in [utilities, interactables]:
            for row in layer:
                if len(row) != s_cols:
                    mismatch = True
                    break

        if mismatch:
            maps.append(md)

    return maps


def main():
    parser = argparse.ArgumentParser(description="Fix layer dimension mismatches")
    parser.add_argument("path", nargs="?", help="Single file to fix")
    parser.add_argument("--dry-run", action="store_true", help="Preview only")
    args = parser.parse_args()

    if args.path:
        targets = [Path(args.path)]
    else:
        targets = find_mismatched_maps()

    if not targets:
        print("No dimension mismatches found.")
        return 0

    fixed = 0
    skipped = 0
    errors = 0

    for p in targets:
        rel = p.relative_to(REPO)
        result = fix_map(p, dry_run=args.dry_run)

        if result["status"] in ("fixed", "would_fix"):
            label = "WOULD FIX" if args.dry_run else "FIXED"
            safe_print(f"  [{label}] {rel}")
            for c in result.get("changes", []):
                safe_print(f"      {c}")
            fixed += 1
        elif result["status"] == "skipped":
            safe_print(f"  [SKIP] {rel} ({result['reason']})")
            skipped += 1
        elif result["status"] == "error":
            safe_print(f"  [ERR]  {rel} ({result['reason']})")
            errors += 1

    safe_print(f"\n{'Would fix' if args.dry_run else 'Fixed'}: {fixed}  Skipped: {skipped}  Errors: {errors}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
