#!/usr/bin/env python3
"""What each authored museum slot can actually hold.

The 30 museum templates already carry 475 hand-authored placement slots — the
positions that encode sightlines, pacing and hero placement. Nothing has ever
recorded what SIZE of artifact each one can take, so placement has had to solve
from scratch and discard that authorship.

This computes it once, statically, per template: for every slot, the largest
footprint it holds at each cardinal rotation, whether it backs onto a wall, and
which slots form a SERIES — adjacent runs of like slots that a DNA family or a
related-artifact collation can claim together.

Placement then becomes a LOOKUP rather than a search:

    artifact needs 3x2 with front access
    -> slot uffizi-spine-enfilade/10,4 offers 4x6, wall-backed W, series of 5

Capacity is measured with the SAME anchoring rule the negotiator uses
(tools/spatial_contract.masks centres a footprint on its anchor cell;
spatial_negotiation pushes a wall-backed body flush). Measuring it any other way
would produce a table describing a placement nobody will make — an earlier pass
allowed the body to sit anywhere containing the slot and reported 6x6 almost
everywhere, because the body had drifted off the slot entirely.

Usage:
    python tools/slot_capacity.py                       # all 30 museums
    python tools/slot_capacity.py --museum=uffizi-spine-enfilade --print
    python tools/slot_capacity.py --max-probe=10
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parent.parent
PATTERNS = REPO / "commons" / "data" / "template_patterns.json"
OUT = REPO / "commons" / "data" / "slot_capacity.json"

#: Cell roles an artifact body may stand on. '2' is a platform — raised, and the
#: templates use it as scenery rather than as standing room, so it is excluded.
OCCUPIABLE = {"1", "1s", "2s", "3s"}
#: Cells a visitor can stand in to approach. Podium cells are furniture.
STANDABLE = {"1", "1s"}
WALL = "4"
SLOT_ROLES = {"1s": "floor", "2s": "podium", "3s": "high_podium"}
#: Which way each rotation faces, from artifact_spatial_contracts.json
#: rotation_semantics: 0 south, 90 west, 180 north, 270 east.
FACING = {0: (0, 1), 90: (-1, 0), 180: (0, -1), 270: (1, 0)}


def load_museums(only: str = "") -> dict[str, dict[str, Any]]:
    data = json.loads(PATTERNS.read_text(encoding="utf-8"))["patterns"]
    out = {k: v for k, v in data.items() if v.get("museum")}
    if only:
        out = {k: v for k, v in out.items() if k == only}
    return out


class Tile:
    def __init__(self, rows: list[list[str]]):
        self.rows = rows
        self.h = len(rows)
        self.w = len(rows[0]) if rows else 0

    def at(self, x: int, z: int) -> str:
        if 0 <= x < self.w and 0 <= z < self.h:
            return str(self.rows[z][x])
        return WALL                      # outside the tile is solid

    def occupiable(self, x: int, z: int) -> bool:
        return self.at(x, z) in OCCUPIABLE

    def standable(self, x: int, z: int) -> bool:
        return self.at(x, z) in STANDABLE


def wall_sides(tile: Tile, x: int, z: int) -> list[str]:
    """Which compass sides of this cell are wall. Named for the direction the
    wall lies IN, so a slot with 'west' has a wall to its west."""
    out = []
    for name, (dx, dz) in (("west", (-1, 0)), ("east", (1, 0)),
                           ("north", (0, -1)), ("south", (0, 1))):
        if tile.at(x + dx, z + dz) == WALL:
            out.append(name)
    return out


def body_cells(sx: int, sz: int, w: int, d: int,
               flush: tuple[int, int] | None) -> list[tuple[int, int]]:
    """The cells a w x d body covers when placed at a slot.

    Centred on the slot cell — the same rule spatial_contract.masks uses, so
    this table describes the placement the negotiator will actually make. A
    wall-backed body is pushed flush along the wall normal instead, which is
    what spatial_negotiation.origin_for does.
    """
    bx, bz = -(w // 2), -(d // 2)
    cells = [(sx + bx + i, sz + bz + j) for i in range(w) for j in range(d)]
    if flush is None:
        return cells
    nx, nz = flush                        # inward normal of the wall
    xs = [c[0] for c in cells]
    zs = [c[1] for c in cells]
    dx = dz = 0
    if nx > 0:
        dx = sx - min(xs)
    elif nx < 0:
        dx = sx - max(xs)
    if nz > 0:
        dz = sz - min(zs)
    elif nz < 0:
        dz = sz - max(zs)
    return [(x + dx, z + dz) for x, z in cells]


def fits(tile: Tile, cells: list[tuple[int, int]], rotation: int,
         require_access: bool) -> bool:
    """Body inside the room, and reachable from its front if required."""
    for x, z in cells:
        if not tile.occupiable(x, z):
            return False
    if not require_access:
        return True
    fx, fz = FACING[rotation]
    body = set(cells)
    xs = [c[0] for c in cells]
    zs = [c[1] for c in cells]
    if fz > 0:
        band = [(x, max(zs) + 1) for x in xs]
    elif fz < 0:
        band = [(x, min(zs) - 1) for x in xs]
    elif fx > 0:
        band = [(max(xs) + 1, z) for z in zs]
    else:
        band = [(min(xs) - 1, z) for z in zs]
    # The project's own rule, from the template editor's walk check: a slot is
    # met from an adjacent standable cell OR one standable cell beyond a single
    # podium — "you see over a 0.6 m plinth, not over a 3 m wall". Requiring the
    # immediately adjacent cell to be floor called five hero slots unreachable
    # when a visitor can plainly stand one plinth back and look.
    for x, z in band:
        if (x, z) in body:
            continue
        if tile.standable(x, z):
            return True
        if tile.at(x, z) in {"2", "2s"} and tile.standable(x + fx, z + fz):
            return True
    return False


def capacity(tile: Tile, sx: int, sz: int, walls: list[str],
             max_probe: int) -> dict[str, Any]:
    """Largest footprint this slot holds, per rotation."""
    normals = {"west": (1, 0), "east": (-1, 0), "north": (0, 1), "south": (0, -1)}
    per_rot: dict[str, Any] = {}
    for rot in (0, 90, 180, 270):
        # A wall-backed placement needs the body's back against that wall, and
        # the back is the opposite of the facing.
        fx, fz = FACING[rot]
        back = (-fx, -fz)
        flush = None
        for side in walls:
            if normals[side] == (-back[0], -back[1]):
                flush = normals[side]
                break
        best = (0, 0, 0)
        for w in range(1, max_probe + 1):
            for d in range(1, max_probe + 1):
                cells = body_cells(sx, sz, w, d, flush)
                if fits(tile, cells, rot, require_access=True):
                    if w * d > best[0]:
                        best = (w * d, w, d)
        per_rot[str(rot)] = {
            "max_w": best[1], "max_d": best[2], "max_area": best[0],
            "wall_backed": flush is not None,
        }
    areas = [v["max_area"] for v in per_rot.values()]
    # A slot that hits the probe ceiling has not been measured, it has been
    # truncated — an open hall does not stop at 8 m. Say so rather than let a
    # ceiling read as a capacity.
    clipped = any(v["max_w"] >= max_probe or v["max_d"] >= max_probe
                  for v in per_rot.values())
    return {
        "per_rotation": per_rot,
        "best_area": max(areas) if areas else 0,
        "any_rotation_fits": max(areas) > 0 if areas else False,
        "clipped_by_probe": clipped,
    }


def find_series(slots: list[dict[str, Any]], gap: int = 5,
                minimum: int = 3) -> list[dict[str, Any]]:
    """Runs of like slots a DNA family or collation can claim together.

    A series is >= `minimum` slots of the same role, colinear, each within
    `gap` cells of the next. This is the field template_museum_unification.md
    specified for typed slots and that never landed.
    """
    out: list[dict[str, Any]] = []
    by_role: dict[str, list[dict[str, Any]]] = {}
    for s in slots:
        by_role.setdefault(s["role"], []).append(s)

    for role, group in by_role.items():
        for axis, fixed, moving in (("column", 0, 1), ("row", 1, 0)):
            lanes: dict[int, list[dict[str, Any]]] = {}
            for s in group:
                lanes.setdefault(s["cell"][fixed], []).append(s)
            for lane_key, lane in lanes.items():
                lane = sorted(lane, key=lambda s: s["cell"][moving])
                run = [lane[0]]
                for prev, cur in zip(lane, lane[1:]):
                    if cur["cell"][moving] - prev["cell"][moving] <= gap:
                        run.append(cur)
                    else:
                        if len(run) >= minimum:
                            out.append({"axis": axis, "role": role,
                                        "lane": lane_key,
                                        "slots": [s["id"] for s in run],
                                        "length": len(run)})
                        run = [cur]
                if len(run) >= minimum:
                    out.append({"axis": axis, "role": role, "lane": lane_key,
                                "slots": [s["id"] for s in run],
                                "length": len(run)})
    # A slot can appear in a row-series and a column-series; keep the longest
    # runs first so a claimant takes the most coherent one available.
    out.sort(key=lambda r: -r["length"])
    return out


def analyse(key: str, pattern: dict[str, Any], max_probe: int) -> dict[str, Any]:
    tile = Tile(pattern["tile"])
    slots: list[dict[str, Any]] = []
    for z in range(tile.h):
        for x in range(tile.w):
            role_token = tile.at(x, z)
            if role_token not in SLOT_ROLES:
                continue
            walls = wall_sides(tile, x, z)
            slots.append({
                "id": f"{x},{z}",
                "cell": [x, z],
                "token": role_token,
                "role": SLOT_ROLES[role_token],
                "wall_sides": walls,
                "capacity": capacity(tile, x, z, walls, max_probe),
            })
    return {
        "museum": pattern.get("museum", key),
        "label": pattern.get("label", key),
        "size": [tile.w, tile.h],
        "slots": slots,
        "series": find_series(slots),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--museum", default="", help="limit to one template key")
    ap.add_argument("--max-probe", type=int, default=8,
                    help="largest footprint edge to test, in cells")
    ap.add_argument("--print", dest="show", action="store_true")
    args = ap.parse_args()

    museums = load_museums(args.museum)
    if not museums:
        print("no museum patterns matched"); return 1

    result: dict[str, Any] = {}
    for key, pattern in sorted(museums.items()):
        result[key] = analyse(key, pattern, args.max_probe)

    total_slots = sum(len(v["slots"]) for v in result.values())
    total_series = sum(len(v["series"]) for v in result.values())
    dead = sum(1 for v in result.values() for s in v["slots"]
               if not s["capacity"]["any_rotation_fits"])

    payload = {
        "_readme": (
            "What each authored museum slot can hold. Derived from "
            "commons/data/template_patterns.json — regenerate with "
            "tools/slot_capacity.py after any tile change. Capacity uses the "
            "same centring and wall-flush rules as tools/spatial_contract.masks "
            "and tools/spatial_negotiation.origin_for, so a slot's advertised "
            "size is the size the negotiator will actually place there. "
            "`series` groups adjacent like slots a DNA family or a related-"
            "artifact collation can claim together."),
        "generated_from": "commons/data/template_patterns.json",
        "max_probe_cells": args.max_probe,
        "counts": {"museums": len(result), "slots": total_slots,
                   "series": total_series, "slots_with_no_fit": dead},
        "museums": result,
    }
    OUT.write_text(json.dumps(payload, indent=1), encoding="utf-8")

    print(f"{len(result)} museums, {total_slots} slots, {total_series} series "
          f"-> {OUT.relative_to(REPO)}")
    if dead:
        print(f"  {dead} slot(s) cannot host even a 1x1 body with front access")

    if args.show:
        for key, v in result.items():
            print(f"\n=== {v['label']}  ({v['size'][0]}x{v['size'][1]})")
            print(f"{'slot':>8s} {'role':>11s} {'walls':>16s}  best  per-rotation w x d")
            for s in v["slots"]:
                per = s["capacity"]["per_rotation"]
                cells = "  ".join(
                    f"{r}:{per[r]['max_w']}x{per[r]['max_d']}" for r in ("0", "90", "180", "270"))
                print(f"{s['id']:>8s} {s['role']:>11s} {','.join(s['wall_sides']) or '-':>16s}"
                      f"  {s['capacity']['best_area']:>4d}  {cells}")
            for ser in v["series"][:6]:
                print(f"    series {ser['axis']:>6s} {ser['role']:<11s} "
                      f"x{ser['length']}  {ser['slots']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
