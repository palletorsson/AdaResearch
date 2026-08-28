"""Give a map a margin before its content, so the space in front of it is editable.

Palle, after a day of chasing geometry that only exists at build time: "nothing
before 0,0,0 can be editable ... Just shift the map back so we can edit from
0,0,0 ... or at 2,2,0 so that is ok. The other part of the map becomes the pre
annex."

So: prepend N rows and N columns to every layer. Everything the map already holds
moves by (+N, +N) and keeps its relationships; the new cells are the pre-annex,
plain floor, ready to be dug or walled with the brush like any other cell.

SAFE UNDER A SHIFT, checked rather than assumed:
  · @void / @hold / @look take WIDTH:DEPTH, not coordinates (UtilityRegistry:325)
  · m: computes its target from the cell's own global_position, so it travels
    with the cell it sits on (GridUtilitiesComponent:890)
  · the 19 hand rulings for this pearl are all at negative z — the enter room,
    a different frame, untouched by a map shift
Anything else that indexes this map's cells from outside would need shifting too,
which is why --apply prints what it moved.

    python tools/shift_map_origin.py --map=Point_One --pad=2 [--apply]
"""
import argparse
import json
import os
import pathlib
import sys


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", required=True)
    ap.add_argument("--pad", type=int, default=2)
    ap.add_argument("--fill", default="1", help="structure value for the new cells (1 = floor)")
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()

    path = pathlib.Path("commons/maps") / a.map / "map_data.json"
    if not path.exists():
        print("no such map: %s" % path)
        return 2
    raw = path.read_text(encoding="utf-8")
    doc = json.loads(raw)
    layers = doc.get("layers", {})
    if not layers:
        print("map has no layers")
        return 2

    pad = a.pad
    before = {k: (len(v), len(v[0]) if v else 0) for k, v in layers.items() if isinstance(v, list)}

    for name in ("structure", "utilities", "interactables"):
        grid = layers.get(name)
        if not isinstance(grid, list) or not grid:
            continue
        w = len(grid[0])
        blank = a.fill if name == "structure" else " "
        # columns first, so the new rows are built at the final width
        for row in grid:
            for _ in range(pad):
                row.insert(0, blank)
        new_w = w + pad
        for _ in range(pad):
            grid.insert(0, [blank] * new_w)
        layers[name] = grid

    after = {k: (len(v), len(v[0]) if v else 0) for k, v in layers.items() if isinstance(v, list)}
    print("%s: pad %d" % (a.map, pad))
    for k in sorted(before):
        print("   %-14s %d x %d  ->  %d x %d" % (k, before[k][0], before[k][1], after[k][0], after[k][1]))

    # every placed thing moved by (+pad, +pad) — say so, since that is the part a
    # reader has to trust
    moved = 0
    for name in ("utilities", "interactables"):
        for row in layers.get(name, []):
            moved += sum(1 for c in row if str(c).strip())
    print("   %d placed token(s) moved by (+%d, +%d)" % (moved, pad, pad))

    mi = doc.setdefault("map_info", {})
    # MEASURED off the grid, not incremented. Incrementing gave depth 22 on a map
    # that is 25 rows, because the passage bake had already appended three and the
    # old dimensions never learned about them. The grid is the truth.
    dim = mi.get("dimensions")
    if isinstance(dim, dict):
        rows, cols = after.get("structure", (0, 0))
        if "width" in dim:
            dim["width"] = cols
        if "depth" in dim:
            dim["depth"] = rows
        print("   map_info.dimensions measured off the grid: %s" % json.dumps(dim))

    if not a.apply:
        print("   DRY RUN — pass --apply to write")
        return 0

    tmp = path.with_suffix(".json.tmp")
    text = json.dumps(doc, indent="\t", ensure_ascii=False) + "\n"
    if len(text) < len(raw) * 0.5:
        print("   REFUSED: the new file is less than half the old one")
        return 3
    tmp.write_text(text, encoding="utf-8")
    os.replace(tmp, path)
    print("   WROTE %s — run tools/compact_map_json.py next" % path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
