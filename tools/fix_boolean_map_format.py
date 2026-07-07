"""tools/fix_boolean_map_format.py — fix data-type + teleporter issues in boolean maps.

The first-pass scaffolds had two issues the pathfinder caught:

  1. Structure values are ints (1) but should be strings ("0", "1") to match
     the existing convention.
  2. Teleporter at last-row last-col with structure=1 — pathfinder wants
     teleporter on a void (height "0") cell with a wall row behind it.

Fix per map:
  - Convert all structure values to strings
  - Move teleporter from [9][9] to [8][9]
  - Set structure[8][9] = "0" (void — player falls in)
  - Add a back-wall row at the bottom: structure[9][*] stays walkable but
    just bounds the play space (pathfinder rule 2 wants something behind tp)

Actually simplest pattern: teleporter cell = void; the cell BEHIND it
needs to be void too so the player drops in. Looking at PG_BooleanPatterns:
  - teleporter at [12][9] with structure=0
  - back rows at structure=0 (void)
  - Spawn pad 'sp' at [12][10] adjacent

Run:
  python tools/fix_boolean_map_format.py --apply
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
MAPS_DIR = ROOT / "commons" / "maps"

BOOLEAN_MAPS = [
    "Boolean_Union", "Boolean_Intersection", "Boolean_Difference",
    "Boolean_Compose_Workbench", "Boolean_Architecture_Cavity",
]


def fix_map(map_name: str, apply: bool) -> str:
    md = MAPS_DIR / map_name / "map_data.json"
    if not md.exists():
        return f"  SKIP {map_name}: missing"
    d = json.loads(md.read_text(encoding="utf-8"))
    struct = d["layers"]["structure"]
    util = d["layers"]["utilities"]

    changes: list[str] = []
    rows, cols = len(struct), len(struct[0])

    # 1. Convert all structure cells to strings
    nonstring = 0
    for ri in range(rows):
        for ci in range(cols):
            if not isinstance(struct[ri][ci], str):
                struct[ri][ci] = str(struct[ri][ci])
                nonstring += 1
    if nonstring > 0:
        changes.append(f"converted {nonstring} structure cells int → str")

    # 2. Teleporter placement
    # Current: utilities[9][9] = 't'
    # New: move to [8][9]; set structure[8][9] = "0" (void); leave row 9 walkable as bound
    # Also add 'sp' (spawn pad / arrival) adjacent
    if util[rows - 1][cols - 1] == "t":
        util[rows - 1][cols - 1] = " "
        util[rows - 2][cols - 1] = "t"
        struct[rows - 2][cols - 1] = "0"
        changes.append(f"moved 't' from [{rows-1}][{cols-1}] → [{rows-2}][{cols-1}] (structure now void)")

    # 3. Add a 'sp' adjacent if a spot is open (gives the next-map arrival point)
    if cols - 2 >= 0 and util[rows - 2][cols - 2] == " ":
        # Actually let's leave this alone; the simpler validated pattern is just 't' on void
        pass

    if apply and changes:
        md.write_text(json.dumps(d, indent=2) + "\n", encoding="utf-8")

    return f"  {'OK' if apply else 'WOULD'} {map_name}: " + (" · ".join(changes) if changes else "no changes")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--apply", action="store_true")
    args = p.parse_args()

    print(f"{'WRITING' if args.apply else 'DRY-RUN'} — fixing boolean map data:")
    for m in BOOLEAN_MAPS:
        print(fix_map(m, args.apply))


if __name__ == "__main__":
    main()
