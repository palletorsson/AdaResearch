#!/usr/bin/env python3
"""Measure the museum corpus as a KIT: how long are its wall runs, and could a
fixed-size wall MODULE be laid into them?

This is the modularity question, not the white-cube question. white_cube.py asked
"how much is stuck on the wall"; this asks "is there a wall to stick a module ON".

It reuses em_white_cube_measure's occupancy mirror verbatim (map_vestibule,
map_tile, dressed_faces, stretches_of) so the two reports cannot drift apart.
The only new thing is the classification of runs and of 1 m faces.

    python tools/em_module_measure.py                 # corpus table + histogram
    python tools/em_module_measure.py --tile-only     # tiles WITHOUT the shell
    python tools/em_module_measure.py --module=4      # size the module to test
    python tools/em_module_measure.py --json=<path>
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from em_white_cube_measure import (PATTERNS, VESTIBULE_H, dressed_faces,
                                   map_tile, map_vestibule, stretches_of)

WALK = ("1", "1s")


def occupancy(spec, shell=True, prev_w=-1):
    tile = spec["tile"]
    w = int(spec["w"])
    walls, floors = set(), set()
    if shell:
        map_vestibule(walls, floors, w, prev_w)
        map_tile(walls, floors, tile, w)
    else:
        # tile only: no vestibule, no injected x=-1 / x=w side walls
        for y, row in enumerate(tile):
            z = y + VESTIBULE_H
            for x, c in enumerate(row):
                if c == "4":
                    walls.add((x, z))
                elif c in WALK:
                    floors.add((x, z))
    return walls, floors


def classify_stub(cell, nx, nz, walls, floors):
    """A face-run of length 1 metre. WHY is it one metre long?

    PIER      the wall cell is alone on its own axis -- the tile authored a 1 m
              stub. Nothing but a tile edit can lengthen it.
    NO_FLOOR  the wall continues, but the room in front of it does not: the cell
              beside it has no walkable neighbour in the same direction. The wall
              is long; the standing room is short.
    """
    x, z = cell
    # the run axis is perpendicular to the outward normal
    if nz != 0:                      # face looks along z -> run travels in x
        axis = [(1, 0), (-1, 0)]
    else:
        axis = [(0, 1), (0, -1)]
    wall_continues = False
    for dx, dz in axis:
        if (x + dx, z + dz) in walls:
            wall_continues = True
    return "NO_FLOOR" if wall_continues else "PIER"


def measure(key, spec, shell=True, module=4):
    walls, floors = occupancy(spec, shell)
    faces = dressed_faces(walls, floors)
    strs = stretches_of(faces)
    lens = [len(s[1]) for s in strs]
    total = float(sum(lens))

    hist = defaultdict(int)
    for l in lens:
        hist[l] += 1

    ge = {}
    for n in (2, 3, 4, 5, 6, 8, 10):
        ge[n] = 100.0 * sum(l for l in lens if l >= n) / total if total else 0.0

    # how many whole modules of `module` metres fit, laid end to end
    slots = sum(l // module for l in lens)
    slot_cover = 100.0 * slots * module / total if total else 0.0
    hostable = sum(1 for l in lens if l >= module)

    # why are the 1 m faces 1 m?
    stubs = {"PIER": 0, "NO_FLOOR": 0}
    for skey, cells in strs:
        if len(cells) != 1:
            continue
        parts = skey.split("|")
        along_x = parts[0] == "x"
        fixed = float(parts[1])
        nx, nz = float(parts[2]), float(parts[3])
        vary = cells[0]
        if along_x:
            cx, cz = vary - 0.5 - nx * 0.5, fixed - 0.5 - nz * 0.5
        else:
            cx, cz = fixed - 0.5 - nx * 0.5, vary - 0.5 - nz * 0.5
        cell = (int(round(cx)), int(round(cz)))
        stubs[classify_stub(cell, nx, nz, walls, floors)] += 1

    return {
        "key": key, "faces_m": len(faces), "runs": len(lens),
        "mean_m": total / len(lens) if lens else 0.0,
        "max_m": max(lens) if lens else 0,
        "ge4_pct": ge[4], "ge6_pct": ge[6], "ge8_pct": ge[8], "ge10_pct": ge[10],
        "ge2_pct": ge[2], "ge3_pct": ge[3], "ge5_pct": ge[5],
        "runs_ge_mod": hostable, "mod_slots": slots, "mod_cover_pct": slot_cover,
        "one_m_faces": hist[1], "one_m_pct": 100.0 * hist[1] / total if total else 0.0,
        "pier": stubs["PIER"], "no_floor": stubs["NO_FLOOR"],
        "hist": dict(hist),
        "total_m": total,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--module", type=int, default=4)
    ap.add_argument("--tile-only", action="store_true")
    ap.add_argument("--json", default="")
    ap.add_argument("--key", default="")
    args = ap.parse_args()

    pats = json.load(open(PATTERNS, encoding="utf-8"))["patterns"]
    keys = sorted(k for k, v in pats.items()
                  if isinstance(v, dict) and v.get("museum"))
    if args.key:
        keys = [k for k in keys if k.startswith(args.key)]
    shell = not args.tile_only
    rows = [measure(k, pats[k], shell, args.module) for k in keys]

    M = args.module
    print("MODULE = %d m    shell = %s    %d museums" % (M, shell, len(rows)))
    hdr = ("%-38s %5s %5s %6s %5s %7s %7s %7s %7s %6s %6s %6s %6s"
           % ("template", "wall", "runs", "mean", "max", ">=4m%", ">=6m%",
              ">=8m%", ">=10m%", "slots", "cov%", "pier", "nofl"))
    print(hdr)
    print("-" * len(hdr))
    for r in rows:
        print("%-38s %5d %5d %6.1f %5d %7.1f %7.1f %7.1f %7.1f %6d %6.1f %6d %6d"
              % (r["key"][:38], r["faces_m"], r["runs"], r["mean_m"], r["max_m"],
                 r["ge4_pct"], r["ge6_pct"], r["ge8_pct"], r["ge10_pct"],
                 r["mod_slots"], r["mod_cover_pct"], r["pier"], r["no_floor"]))
    print("-" * len(hdr))

    tot = sum(r["total_m"] for r in rows)
    allhist = defaultdict(int)
    for r in rows:
        for l, c in r["hist"].items():
            allhist[int(l)] += c
    def share(pred):
        return 100.0 * sum(l * c for l, c in allhist.items() if pred(l)) / tot

    print("POOLED over %d m of wall run in %d runs:"
          % (tot, sum(r["runs"] for r in rows)))
    for n in (2, 3, 4, 5, 6, 8, 10):
        print("   run length >= %2d m : %5.1f%% of all wall run   (%d runs)"
              % (n, share(lambda l, n=n: l >= n),
                 sum(c for l, c in allhist.items() if l >= n)))
    print("   run length == 1 m  : %5.1f%% of all wall run   (%d runs, %.0f%% of runs)"
          % (share(lambda l: l == 1), allhist[1],
             100.0 * allhist[1] / sum(allhist.values())))
    piers = sum(r["pier"] for r in rows)
    nofl = sum(r["no_floor"] for r in rows)
    print("   of those 1 m runs: %d PIER (tile authored a stub) / %d NO_FLOOR "
          "(wall continues, room does not) = %.0f%% / %.0f%%"
          % (piers, nofl, 100.0 * piers / (piers + nofl),
             100.0 * nofl / (piers + nofl)))
    print()
    print("full run-length histogram (length m: run count, metres, %% of run):")
    for l in sorted(allhist):
        c = allhist[l]
        print("   %3d m  %5d runs  %6d m  %5.1f%%" % (l, c, l * c, 100.0 * l * c / tot))
    print()
    hosts = sum(1 for r in rows if r["runs_ge_mod"] > 0)
    print("museums with >=1 run of %d m or longer: %d of %d" % (M, hosts, len(rows)))
    for n in (4, 6, 8, 10):
        h = sum(1 for r in rows if any(int(l) >= n for l in r["hist"]))
        print("   >=1 run of %2d m+: %2d of %d museums" % (n, h, len(rows)))
    print("whole %d m module slots corpus-wide: %d  (covering %.1f%% of all wall run)"
          % (M, sum(r["mod_slots"] for r in rows),
             100.0 * sum(r["mod_slots"] for r in rows) * M / tot))
    med = sorted(r["runs_ge_mod"] for r in rows)[len(rows) // 2]
    print("median museum has %d runs of %d m+" % (med, M))

    if args.json:
        json.dump(rows, open(args.json, "w", encoding="utf-8"), indent=1)
        print("wrote %s" % args.json)
    return 0


if __name__ == "__main__":
    sys.exit(main())
