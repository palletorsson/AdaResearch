#!/usr/bin/env python3
"""WHAT SHAPE IS AN ARTIFACT, IN GRID CELLS.

2026-08-25, Palle: "measure the oblong footprints from spatial_needs. do you
think this can work?"

It can, but not on either field alone, and finding out why is the point:

  footprint [x, y, z]        has SHAPE and is the world AABB — uncapped, so
                             noiselayers declares 220 x 83 x 200
  spatial_needs.footprint_cells  is GRID TRUTH and capped, but a single
                             number — it has no shape at all, so it cannot
                             tell a 1x6 frieze from a 2x3 table

Measured: 186 of the 196 artifacts declaring a footprint 15 cells or longer
ALSO declare footprint_cells of 9 or less. The two fields contradict each
other across the whole tail, and each is right about the half the other
cannot see.

So: AREA from footprint_cells, PROPORTION from the AABB. Together they give a
rectangle in grid cells, which is the currency a slot can actually match.
2342 artifacts get one — up from the 1482 that declare a raw footprint — and
the longest side in the corpus becomes 14 cells instead of 220.

    python tools/artifact_shapes.py            # writes commons/data/artifact_shapes.json
    python tools/artifact_shapes.py --top=20   # the shapes, most common first
"""
from __future__ import annotations

import argparse
import collections
import glob
import json
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def registry():
    reg = {}
    for p in glob.glob(os.path.join(ROOT, "commons", "artifacts", "registry", "*.json")):
        try:
            with open(p, encoding="utf-8") as fh:
                doc = json.load(fh)
        except Exception:
            continue
        arts = doc.get("artifacts") if isinstance(doc.get("artifacts"), dict) else doc
        if not isinstance(arts, dict):
            continue
        for tok, e in arts.items():
            if isinstance(e, dict) and tok not in reg:
                reg[tok] = e
    return reg


def grid_shape(entry):
    """(w, d) in cells, or None when the artifact declares no area."""
    sn = entry.get("spatial_needs") or {}
    cells = sn.get("footprint_cells")
    if not isinstance(cells, (int, float)) or cells <= 0:
        return None
    fp = entry.get("footprint") or (entry.get("parameters") or {}).get("footprint")
    ratio = 1.0
    if isinstance(fp, list) and len(fp) == 3:
        try:
            x, z = float(fp[0]), float(fp[2])
            if x > 0 and z > 0:
                ratio = x / z
        except Exception:
            pass
    area = float(cells)
    w = max(1, int(round(math.sqrt(area * ratio))))
    d = max(1, int(round(area / w)))
    return (w, d)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--top", type=int, default=16)
    ap.add_argument("--out", default="commons/data/artifact_shapes.json")
    args = ap.parse_args()

    reg = registry()
    shapes, counts = {}, collections.Counter()
    for tok, e in reg.items():
        s = grid_shape(e)
        if not s:
            continue
        shapes[tok] = {"w": s[0], "d": s[1], "long": max(s), "short": min(s),
                       "square": s[0] == s[1],
                       "wall_backing": bool((e.get("spatial_needs") or {}).get("wall_backing"))}
        counts[s] += 1

    sq = sum(n for (w, d), n in counts.items() if w == d)
    tot = sum(counts.values())
    print("ARTIFACT SHAPES — area from footprint_cells, proportion from the AABB\n")
    print("  %d of %d artifacts get a grid shape" % (tot, len(reg)))
    print("  square %d (%.0f%%) · oblong %d (%.0f%%) · longest side %d cells\n"
          % (sq, 100.0 * sq / tot, tot - sq, 100.0 * (tot - sq) / tot,
             max(max(k) for k in counts)))
    for (w, d), n in counts.most_common(args.top):
        print("     %2d x %-2d %5d  %s" % (w, d, n, "square" if w == d else "OBLONG"))
    runs = collections.Counter()
    for s in shapes.values():
        if not s["square"]:
            runs[s["long"]] += 1
    print("\n  oblong pieces by LONG side (what a wall run has to be able to take):")
    for L in sorted(runs):
        print("     %2d long  %4d" % (L, runs[L]))
    dest = os.path.join(ROOT, args.out)
    with open(dest, "w", encoding="utf-8") as fh:
        json.dump({"_readme": "Grid-cell shape per artifact. AREA from spatial_needs."
                   "footprint_cells (grid truth, capped); PROPORTION from footprint [x,y,z] "
                   "(shape truth, uncapped). Neither field can answer alone — 186 of 196 long "
                   "artifacts have the two disagreeing. Written by tools/artifact_shapes.py.",
                   "shapes": shapes}, fh, indent=1)
    print("\n  -> %s" % args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
