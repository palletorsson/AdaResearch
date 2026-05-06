#!/usr/bin/env python3
"""
Fix EXIT PATTERN failures: teleporter cell → h=0, surrounding 8 cells → h=1.
Also fixes SPAWN SAFETY (2×2 at [0,0] → h=1) and ENCODING ("0" → " " in utils/ints).

Skips maps in early sequences (up to and including noise/fractals).

Usage:
  python fix_exit_pattern.py --dry-run     # show what would change
  python fix_exit_pattern.py               # apply fixes
  python fix_exit_pattern.py --only-exit   # only fix exit pattern
"""

import json, os, sys, copy
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
MAPS_DIR = PROJECT / "commons" / "maps"
SEQ_DIR = MAPS_DIR / "sequences"

# ─── Sequences to skip (up to and including noise/fractals) ───
EXCLUDE_SEQUENCES = {
    'primitives', 'transformation', 'color', 'array_tutorial',
    'forces', 'wavefunctions', 'noise', 'fractals',
    'randomness', 'joints', 'particles',
}

DRY_RUN = '--dry-run' in sys.argv
ONLY_EXIT = '--only-exit' in sys.argv


def get_excluded_maps():
    """Get set of map names in excluded sequences."""
    excluded = set()
    for f in SEQ_DIR.iterdir():
        if not f.suffix == '.json' or f.name == 'sequence_index.json':
            continue
        seq_id = f.stem
        if seq_id not in EXCLUDE_SEQUENCES:
            continue
        try:
            d = json.loads(f.read_text(encoding='utf-8-sig'))
            seqs = d.get('sequences', d)
            if isinstance(seqs, dict):
                for s in seqs.values():
                    if isinstance(s, dict):
                        excluded.update(s.get('maps', []))
        except:
            pass
    return excluded


def get_curriculum_maps():
    """Get all maps in any sequence."""
    maps = set()
    for f in SEQ_DIR.iterdir():
        if not f.suffix == '.json' or f.name == 'sequence_index.json':
            continue
        try:
            d = json.loads(f.read_text(encoding='utf-8-sig'))
            seqs = d.get('sequences', d)
            if isinstance(seqs, dict):
                for s in seqs.values():
                    if isinstance(s, dict):
                        maps.update(s.get('maps', []))
        except:
            pass
    return maps


def compact_json(data):
    """Serialize with compact rows."""
    raw = json.dumps(data, indent="\t", ensure_ascii=False)
    lines = raw.split("\n")
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        if stripped == "[" and i + 1 < len(lines):
            indent = line[:len(line) - len(line.lstrip())]
            j = i + 1
            row_items = []
            is_simple_row = True
            while j < len(lines):
                inner = lines[j].strip()
                if inner == "]" or inner == "],":
                    break
                if inner.startswith("{") or inner.startswith("["):
                    is_simple_row = False
                    break
                item = inner.rstrip(",").strip()
                row_items.append(item)
                j += 1
            if is_simple_row and row_items and j < len(lines):
                closing = lines[j].strip()
                compact_row = indent + "[" + ", ".join(row_items) + "]"
                if closing.endswith(","):
                    compact_row += ","
                result.append(compact_row)
                i = j + 1
                continue
        result.append(line)
        i += 1
    return "\n".join(result)


def fix_map(map_name, map_path):
    """Fix exit pattern, spawn safety, and encoding for a single map."""
    try:
        data = json.loads(map_path.read_text(encoding='utf-8-sig'))
    except Exception as e:
        return None, f"JSON error: {e}"

    original = json.dumps(data)
    layers = data.get('layers', {})
    struct = layers.get('structure', [])
    utils = layers.get('utilities', [])
    ints = layers.get('interactables', [])

    if not struct:
        return None, "No structure"

    rows = len(struct)
    cols = max(len(r) for r in struct) if struct else 0
    changes = []

    def h(r, c):
        if r < len(struct) and c < len(struct[r]):
            try: return int(str(struct[r][c]).strip())
            except: return 0
        return 0

    def set_h(r, c, val):
        if r < len(struct) and c < len(struct[r]):
            struct[r][c] = str(val)

    # ─── FIX 1: ENCODING — "0" → " " in utils/ints ───
    if not ONLY_EXIT:
        encoding_fixes = 0
        for r in range(len(utils)):
            for c in range(len(utils[r])):
                if str(utils[r][c]).strip() == '0':
                    utils[r][c] = ' '
                    encoding_fixes += 1
        for r in range(len(ints)):
            for c in range(len(ints[r])):
                if str(ints[r][c]).strip() == '0':
                    ints[r][c] = ' '
                    encoding_fixes += 1
        if encoding_fixes:
            changes.append(f"encoding: {encoding_fixes} cells '0'->' '")

    # ─── FIX 2: SPAWN SAFETY — [0,0]-[1,1] → h=1 ───
    if not ONLY_EXIT:
        spawn_fixes = 0
        for r in range(min(2, rows)):
            for c in range(min(2, cols)):
                if h(r, c) != 1:
                    old = h(r, c)
                    set_h(r, c, 1)
                    spawn_fixes += 1
        if spawn_fixes:
            changes.append(f"spawn: {spawn_fixes} cells->h=1")

    # ─── FIX 3: EXIT PATTERN — teleporter on h=0, ring of h=1 ───
    tele_pos = None
    for r in range(rows):
        for c in range(cols):
            if r < len(utils) and c < len(utils[r]):
                u = str(utils[r][c]).strip()
                if u.startswith('t:') or u.startswith('t3:') or u == 't':
                    tele_pos = (r, c)
                    break
        if tele_pos:
            break

    if tele_pos:
        tr, tc = tele_pos
        exit_fixes = []

        # Check if teleporter is too close to edge (need 1 cell margin)
        if tr < 1 or tr >= rows - 1 or tc < 1 or tc >= cols - 1:
            # Can't fix — teleporter is on the edge
            changes.append(f"EXIT: teleporter at ({tc},{tr}) too close to edge, SKIPPED")
        else:
            # Center → h=0
            if h(tr, tc) != 0:
                old = h(tr, tc)
                set_h(tr, tc, 0)
                exit_fixes.append(f"center ({tc},{tr}) h={old}->0")

            # Ring → h=1
            for dr in [-1, 0, 1]:
                for dc in [-1, 0, 1]:
                    if dr == 0 and dc == 0:
                        continue
                    nr, nc = tr + dr, tc + dc
                    if 0 <= nr < rows and 0 <= nc < cols:
                        ch = h(nr, nc)
                        if ch != 1:
                            set_h(nr, nc, 1)
                            exit_fixes.append(f"ring ({nc},{nr}) h={ch}->1")

            if exit_fixes:
                changes.append(f"exit: {len(exit_fixes)} cells fixed")

    if not changes:
        return None, "no changes needed"

    # Check if data actually changed
    if json.dumps(data) == original:
        return None, "no changes needed"

    if DRY_RUN:
        return changes, "DRY RUN"

    # Write back
    map_path.write_text(compact_json(data), encoding='utf-8')
    return changes, "FIXED"


def main():
    excluded = get_excluded_maps()
    curriculum = get_curriculum_maps()
    eligible = curriculum - excluded

    print(f"Curriculum: {len(curriculum)} maps")
    print(f"Excluded (<=noise/fractals): {len(excluded)} maps")
    print(f"Eligible: {len(eligible)} maps")
    print(f"Mode: {'DRY RUN' if DRY_RUN else 'APPLY'}")
    if ONLY_EXIT:
        print("Only fixing: exit pattern")
    else:
        print("Fixing: exit pattern + spawn safety + encoding")
    print()

    fixed = 0
    skipped = 0
    errors = 0

    for map_name in sorted(eligible):
        map_path = MAPS_DIR / map_name / "map_data.json"
        if not map_path.exists():
            continue

        changes, status = fix_map(map_name, map_path)
        if changes:
            print(f"  {'[DRY]' if DRY_RUN else '[FIX]'} {map_name}: {', '.join(changes)}")
            fixed += 1
        elif "error" in status.lower():
            print(f"  [ERR] {map_name}: {status}")
            errors += 1
        else:
            skipped += 1

    print(f"\n{'Would fix' if DRY_RUN else 'Fixed'}: {fixed} | Skipped: {skipped} | Errors: {errors}")


if __name__ == '__main__':
    main()
