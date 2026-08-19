#!/usr/bin/env python3
"""Name where the endless museum's walk map is cut — without booting Godot.

Gate F (three-museum autopilot) answers this question by walking it: 30-50 s of
headless Godot, one process at a time, and it dies on the user:// lock if another
run is live. Five breaths in a row asked it "where is the museum severed" and got
back a COORDINATE (`frontier_z`) with no mechanism, then spent the rest of the
session guessing the mechanism from the coordinate. Four of those guesses were
wrong.

The builder already writes the answer. `ada_run/em_built.json` carries, per
segment, the role of every cell it stamped — the same data the autopilot's BFS
runs over. The museum is a corridor along +z, so every walk must cross every z
row: if row z and row z+1 share no walkable column, the museum is cut there, and
no amount of routing gets past it. That is a one-second read, it needs no Godot,
and it survives a contended tree.

Two readings, because they answer different questions:

  CUT   a pair of adjacent z rows with no walkable column in common. This is the
        MECHANISM — it names the join that failed and the columns on each side.
  FLOOD a 4-connected flood from the spawn end. This is the VERDICT — how far a
        walker gets, which is what gate F reports.

A flood frontier with no cut above it means the walk dies of something this file
cannot see (a collider the cell map does not know about). A cut is proof.

  python tools/check_walk_severance.py
  python tools/check_walk_severance.py --built=ada_run/em_built.json --json

Exit code is the number of cuts, so it gates.
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import deque
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

# From em_built.json's own legend: "#" not floor, "." floor, "b" bench, "p" prop,
# "s" sealed by a body, "x" erased. Only "." is offered to the planner — a bench
# stands ON floor and the cell is still not walkable, which is the whole point of
# recording the roles apart.
WALKABLE = {"."}


def load_segments(built_path: Path) -> list[dict]:
    data = json.loads(built_path.read_text(encoding="utf-8"))
    segs = data.get("segments") or []
    out = []
    for s in segs:
        cells = s.get("cells") or []
        if not cells:
            continue
        out.append(
            {
                "museum": s.get("museum", "?"),
                "index": s.get("segment", len(out)),
                "z0": int(s.get("z0", 0)),
                "x0": int(s.get("cell_x0", 0)),
                "cells": cells,
            }
        )
    return out


def build_world(segs: list[dict]) -> dict[tuple[int, int], bool]:
    """(x, z) -> walkable, in world cell coordinates."""
    world: dict[tuple[int, int], bool] = {}
    for seg in segs:
        for r, row in enumerate(seg["cells"]):
            z = seg["z0"] + r
            for c, ch in enumerate(row):
                x = seg["x0"] + c
                # Later segments never overlap earlier ones in z, but be explicit:
                # a walkable cell is never downgraded by a neighbour's padding.
                if world.get((x, z)):
                    continue
                world[(x, z)] = ch in WALKABLE
    return world


def row_columns(world: dict[tuple[int, int], bool], z: int) -> set[int]:
    return {x for (x, zz), ok in world.items() if zz == z and ok}


def find_cuts(world: dict[tuple[int, int], bool], segs: list[dict]) -> list[dict]:
    """Adjacent z rows that share no walkable column.

    Reported with the segment each row belongs to, so a cut at a seam reads
    differently from a cut inside one museum — the distinction four breaths of
    gate F verdicts could not make.
    """
    zs = sorted({z for (_x, z) in world})
    by_z: dict[int, set[int]] = {}
    for z in zs:
        by_z[z] = set()
    for (x, z), ok in world.items():
        if ok:
            by_z[z].add(x)

    def owner(z: int) -> str:
        for seg in segs:
            if seg["z0"] <= z < seg["z0"] + len(seg["cells"]):
                return f"{seg['index']}:{seg['museum']}"
        return "?"

    cuts = []
    for z in zs:
        nxt = z + 1
        if nxt not in by_z:
            continue
        here, there = by_z[z], by_z[nxt]
        if not here or not there:
            continue  # an empty row is padding, not a cut
        if here & there:
            continue
        cuts.append(
            {
                "z": z,
                "z_next": nxt,
                "open_at_z": sorted(here),
                "open_at_z_next": sorted(there),
                "gap_columns": abs(min(there, default=0) - max(here, default=0)),
                "segment_z": owner(z),
                "segment_z_next": owner(nxt),
                "at_seam": owner(z) != owner(nxt),
            }
        )
    return cuts


def flood(world: dict[tuple[int, int], bool]) -> tuple[int, int, tuple[int, int] | None]:
    """4-connected flood from the shallowest walkable cell. Returns (reached_z,
    max_z, start)."""
    walkable = {k for k, ok in world.items() if ok}
    if not walkable:
        return (-1, -1, None)
    max_z = max(z for (_x, z) in walkable)
    start = min(walkable, key=lambda k: (k[1], k[0]))
    seen = {start}
    q = deque([start])
    best = start[1]
    while q:
        x, z = q.popleft()
        if z > best:
            best = z
        for nb in ((x + 1, z), (x - 1, z), (x, z + 1), (x, z - 1)):
            if nb in walkable and nb not in seen:
                seen.add(nb)
                q.append(nb)
    return (best, max_z, start)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--built", default="ada_run/em_built.json")
    ap.add_argument("--json", action="store_true", help="machine-readable verdict")
    ap.add_argument("--context", type=int, default=2,
                    help="rows of grid to print either side of a cut")
    args = ap.parse_args()

    built = Path(args.built)
    if not built.is_absolute():
        built = REPO / built
    if not built.exists():
        print(f"no built file at {built} — run the autopilot or a bake first")
        return 0

    segs = load_segments(built)
    if not segs:
        print("built file carries no segments with cells")
        return 0

    world = build_world(segs)
    cuts = find_cuts(world, segs)
    reached, max_z, start = flood(world)

    verdict = {
        "built": str(built),
        "segments": [
            {"index": s["index"], "museum": s["museum"], "z0": s["z0"],
             "rows": len(s["cells"])} for s in segs
        ],
        "flood_start": list(start) if start else None,
        "flood_reached_z": reached,
        "max_z": max_z,
        "cuts": cuts,
    }

    if args.json:
        print(json.dumps(verdict, indent=2))
        return len(cuts)

    print("=== WALK SEVERANCE ===")
    print(f"built: {built}")
    for s in segs:
        print(f"  segment {s['index']}  z {s['z0']}..{s['z0'] + len(s['cells']) - 1}"
              f"  {s['museum']}")
    print(f"flood: from {start} reaches z={reached} of {max_z}"
          f"  ({'WHOLE' if reached >= max_z else f'{max_z - reached} rows short'})")
    if not cuts:
        print("cuts: none — every adjacent z row pair shares a walkable column")
        print("      (a short flood with no cut means the walk dies of something")
        print("       the cell map cannot see — look at colliders, not this file)")
        return 0

    print(f"cuts: {len(cuts)}")
    for c in cuts:
        where = "SEAM" if c["at_seam"] else "inside one museum"
        print(f"\n  z={c['z']} -> z={c['z_next']}   [{where}]")
        print(f"    {c['segment_z']}")
        print(f"    open at z={c['z']:<5} x = {c['open_at_z']}")
        print(f"    open at z={c['z_next']:<5} x = {c['open_at_z_next']}")
        print("    the two rows share no column: nothing can step across")
        lo = c["z"] - args.context
        hi = c["z_next"] + args.context
        xs = sorted({x for (x, _z) in world})
        for z in range(lo, hi + 1):
            row = "".join(
                "." if world.get((x, z)) else ("#" if (x, z) in world else " ")
                for x in xs
            )
            mark = "<<" if z in (c["z"], c["z_next"]) else "  "
            print(f"    z={z:<5}{row} {mark}")
    return len(cuts)


if __name__ == "__main__":
    sys.exit(main())
