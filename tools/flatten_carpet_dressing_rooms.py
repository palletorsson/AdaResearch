#!/usr/bin/env python3
"""
Batch-fix the "carpet on a plinth" misuse across surface-class
dressing rooms.

Many dressing-room JSONs use the standard 3x3 footing
[[1,1,1],[1,3,1],[1,1,1]] — value 3 = plinth — even though the
artifact is a floor mosaic / carpet / tiling that should LIE on the
floor, not perch 1.5m up.

This script finds dressing rooms that are clearly meant to be flat
(name contains floor/mosaic/carpet/pattern/tile/rug), then flattens
any plinth tiles (3) to floor (1). Auto-backups each file to .bak
on first write so the change is fully reversible.

False-positive guards:
  - Skip if name matches BLOCKLIST keywords (spawner, plan, demo, etc.)
  - Skip if all tiles are already non-3 (no-op)
  - Print a dry-run summary before any writes by default

Run:
    python tools/flatten_carpet_dressing_rooms.py            # dry-run
    python tools/flatten_carpet_dressing_rooms.py --apply    # actually write
"""
from __future__ import annotations
import argparse
import json
import shutil
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
ROOMS_DIR = REPO / "commons" / "artifacts" / "dressing_rooms"

# Names that match these keywords are presumed flat-staged.
SURFACE_KEYWORDS = ("floor", "mosaic", "carpet", "rug", "tile", "tessell")
# Names that match these are NOT flat-staged even if they contain a surface
# keyword (e.g. "cube_projectile_spawner" has no real surface relevance).
BLOCKLIST_KEYWORDS = (
    # Active machinery / interactive stations — they need a plinth
    "spawner", "controller", "manager", "handler", "compositor",
    "generator", "weaver", "weaver", "machine", "engine",
    "station", "studio", "maker", "mine", "editor", "_vr",
    # 3D objects that LOOK like patterns but are sculptures
    "knot",          # figure_eight_knot, torus_knot, trefoil_knot
    "torus", "cube", "collection", "sculpture",
    # Texture / didactic displays — not actual floor instances
    "_3d", "explained", "preserved",
    # Spaces / plans / containers — not carpets
    "plan_space", "field_space", "_room", "_lab",
    # Wall pieces — different staging (vertical), not floor flatten
    "wall_pattern", "wall_panel",
    # Demos / controllers
    "demo", "_v",  # vr_tile_editor — already caught by _vr
)
# Names that contain these are TYPICAL surface artifacts even though the
# substring isn't in SURFACE_KEYWORDS.
ALSO_SURFACE = (
    "pattern", "checker", "diamond", "weave", "knot", "labyrinth",
    "meander", "compass_rose", "star_rosette", "honeycomb", "spiral_mosaic",
    "pelta_shield", "swastika", "windmill", "tumbling_blocks",
    "interlocking_t", "polka_dot",
)


def is_surface_name(name: str) -> bool:
    n = name.lower()
    if any(b in n for b in BLOCKLIST_KEYWORDS):
        return False
    if any(s in n for s in SURFACE_KEYWORDS):
        return True
    if any(s in n for s in ALSO_SURFACE):
        return True
    return False


def has_plinth(tiles) -> bool:
    if not isinstance(tiles, list):
        return False
    for row in tiles:
        if not isinstance(row, list):
            continue
        for v in row:
            try:
                if int(v) == 3:
                    return True
            except (TypeError, ValueError):
                continue
    return False


def flatten_tiles(tiles):
    """Return a copy with all 3 → 1 (carpets sit on floor, not plinth)."""
    out = []
    for row in tiles:
        if not isinstance(row, list):
            out.append(row)
            continue
        new_row = []
        for v in row:
            try:
                new_row.append(1 if int(v) == 3 else int(v))
            except (TypeError, ValueError):
                new_row.append(v)
        out.append(new_row)
    return out


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--apply", action="store_true",
                   help="Actually write files (default is dry-run).")
    p.add_argument("--no-backup", action="store_true",
                   help="Skip .bak creation (not recommended).")
    args = p.parse_args()

    if not ROOMS_DIR.exists():
        print(f"no dressing rooms dir: {ROOMS_DIR}")
        return 1

    candidates = []
    for jf in sorted(ROOMS_DIR.glob("*.json")):
        if jf.name.endswith(".bak.json") or jf.name.endswith(".bak"):
            continue
        if not is_surface_name(jf.stem):
            continue
        try:
            data = json.loads(jf.read_text(encoding="utf-8"))
        except Exception as e:
            print(f"  skip (parse fail): {jf.name}: {e}")
            continue
        tiles = (data.get("footing") or {}).get("tiles") or []
        if not has_plinth(tiles):
            continue
        candidates.append((jf, data, tiles))

    print(f"Surface-named dressing rooms with a plinth: {len(candidates)}")
    print("-" * 60)
    for jf, _, _ in candidates:
        print(f"  {jf.stem}")
    print("-" * 60)

    if not args.apply:
        print(f"\nDry-run. Re-run with --apply to flatten {len(candidates)} files.")
        return 0

    written = 0
    for jf, data, tiles in candidates:
        new_tiles = flatten_tiles(tiles)
        data["footing"]["tiles"] = new_tiles
        bak = jf.with_suffix(jf.suffix + ".bak")
        if not args.no_backup and not bak.exists():
            shutil.copy2(jf, bak)
        jf.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n",
                       encoding="utf-8")
        written += 1
        print(f"  [ok] {jf.stem}")

    print(f"\nFlattened {written} dressing rooms.")
    print("Reverts available as <name>.json.bak alongside each file.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
