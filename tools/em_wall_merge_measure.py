#!/usr/bin/env python3
"""How many BOXES does a museum's wall cost, per cell versus merged into runs?

endless_museum.gd:_build_segment stamps one BoxMesh(1, 3, 1) and one BoxShape3D
per wall cell. A 27 m enfilade wall is therefore twenty-seven separate objects
with twenty-seven separate draw nodes and no name.

This counts what a greedy maximal-run merge would cost instead. It is a pure
measurement -- it stamps nothing and changes no file. The merge rule mirrored
here is the one em_wall_runs() implements in endless_museum.gd:

    while cells remain:
        for every remaining cell, measure its horizontal and vertical run
        take the LONGEST run anywhere, emit it as one box, remove its cells

which is greedy-longest-first, deterministic (ties break on (z, x, axis)), and
never emits a box over a cell that is not a wall.

    python tools/em_wall_merge_measure.py
    python tools/em_wall_merge_measure.py --key=uffizi
"""
from __future__ import annotations

import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from em_white_cube_measure import PATTERNS, VESTIBULE_H, LOBBY_W


def wall_cells(spec, prev_w=-1):
    """Exactly the cells endless_museum.gd:_build_segment stamps a wall box on."""
    tile = spec["tile"]
    w = int(spec["w"])
    pw = prev_w if prev_w > 0 else 1
    cells = set()
    for zr in range(VESTIBULE_H):                       # lobby side columns
        cells.add((0, zr))
        cells.add((LOBBY_W - 1, zr))
    for x in range(pw - 1, LOBBY_W):                    # seal behind
        cells.add((x, 0))
    for x in range(w - 1, LOBBY_W):                     # seal in front
        cells.add((x, VESTIBULE_H - 1))
    for y in range(len(tile)):                          # outer skin
        z = y + VESTIBULE_H
        cells.add((-1, z))
        cells.add((w, z))
    for y, row in enumerate(tile):                      # the tile itself
        z = y + VESTIBULE_H
        for x, c in enumerate(row):
            if str(c) == "4":
                cells.add((x, z))
    return cells


def merge_runs(cells):
    """Greedy longest-run-first. Returns a list of (x, z, len, axis)."""
    left = set(cells)
    out = []
    while left:
        best = None
        for (x, z) in sorted(left, key=lambda c: (c[1], c[0])):
            for axis, (dx, dz) in (("x", (1, 0)), ("z", (0, 1))):
                if (x - dx, z - dz) in left:
                    continue                    # not the start of its run
                n = 0
                while (x + dx * n, z + dz * n) in left:
                    n += 1
                if best is None or n > best[2]:
                    best = (x, z, n, axis)
        x, z, n, axis = best
        dx, dz = (1, 0) if axis == "x" else (0, 1)
        for i in range(n):
            left.discard((x + dx * i, z + dz * i))
        out.append(best)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--key", default="")
    ap.add_argument("--json", default="")
    args = ap.parse_args()
    pats = json.load(open(PATTERNS, encoding="utf-8"))["patterns"]
    keys = sorted(k for k, v in pats.items()
                  if isinstance(v, dict) and v.get("museum"))
    if args.key:
        keys = [k for k in keys if k.startswith(args.key)]

    hdr = "%-38s %7s %7s %6s %7s %7s" % ("template", "cells", "boxes", "ratio",
                                         "mean_m", "max_m")
    print(hdr)
    print("-" * len(hdr))
    tc = tb = 0
    rows = []
    for k in keys:
        cells = wall_cells(pats[k])
        runs = merge_runs(cells)
        lens = [r[2] for r in runs]
        row = {"key": k, "cells": len(cells), "boxes": len(runs),
               "ratio": len(cells) / float(len(runs)),
               "mean_m": sum(lens) / float(len(lens)), "max_m": max(lens)}
        rows.append(row)
        tc += len(cells)
        tb += len(runs)
        print("%-38s %7d %7d %6.2f %7.1f %7d"
              % (k[:38], row["cells"], row["boxes"], row["ratio"],
                 row["mean_m"], row["max_m"]))
    print("-" * len(hdr))
    print("%-38s %7d %7d %6.2f" % ("CORPUS (30 museums)", tc, tb, tc / float(tb)))
    print()
    print("per SEGMENT mean: %.0f wall boxes -> %.0f  (%.0f fewer draw nodes, %.0f%%)"
          % (tc / len(rows), tb / len(rows), (tc - tb) / len(rows),
             100.0 * (tc - tb) / tc))
    if args.json:
        json.dump(rows, open(args.json, "w", encoding="utf-8"), indent=1)
        print("wrote %s" % args.json)
    return 0


if __name__ == "__main__":
    sys.exit(main())
