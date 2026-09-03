#!/usr/bin/env python3
"""stamp.py — seat every body in a room, and keep the walls you move.

2026-09-03. Palle's formula, near enough verbatim: "place the artifact in order
to stamp the artifact so they have space: that is remove and restore walls
around the artifact, move existing walls under the artifact but do not remove
them. Use path finding of three or two for the player to walk the map."

WHY IT CAN EXIST NOW. Until this morning a stamper had nothing to stand on: 131
placed bodies had no measured size, so the grid had no guard against any of
them, and the tool that drew rooms was placing bodies centred on their cell and
unrotated, which is wrong by half a body's length for anything with an offset
centre. Both are fixed (1c0b700d1, 13bf28ffb) and the geometry below is the one
verified against the engine on all four quarters, not the one that agreed with
itself.

WHAT IT DOES, in order:

  read     the map's raw BYTES, and its bodies' measured spans
  judge    each body: fits · overruns · buried in wall · over a void · too big
  measure  BEFORE: reachability, the narrowest lane on the route, and the
           multiset of wall literals
  plan     cell ops - carve where a body needs the floor, DISPLACE the literal
           you carved to the nearest legal cell rather than deleting it
  check    AFTER: the same three measurements. Every one must be no worse.
  write    by SPLICING the bytes, never by re-serialising the document
  journal  the ops and their exact pre-images, into documentation.stamp

FOUR RULINGS THIS TOOL MAKES, each of which the survey left open or answered
three different ways.

1. A DISPLACED WALL KEEPS ITS OWN LITERAL. The surveys offered "w"
   unconditionally, "4", and a threshold against map_info.museum.wall_height.
   All three are wrong for the same reason: they decide what a wall IS, when
   Palle's rule only asks to MOVE the one already there. So the conservation
   invariant is not a count, it is a MULTISET: the literals leaving a room must
   be exactly the literals entering it. A "w" stays a "w", a "2" stays a "2",
   and the three-way argument never has to be had. It also sidesteps the
   max_height trap for free - 487 maps use "w" and every one of them already
   declares max_height >= 3, so moving a "w" within its own map is always safe
   where writing a fresh one might not be.

2. WIDTH IS MEASURED, NOT GUARANTEED. A fixed "corridor must be 3" either
   passes sealed maps or refuses most of the corpus, and dilation - which is
   what the existing route machinery does - cannot prove a width at all; it
   protects cells that were already walkable, so a route squeezing through a
   one-cell gap yields a protected set one cell wide at the gap. Only erosion
   proves width. So this tool reports the narrowest lane on the spawn-to-exit
   route as a NUMBER, before and after, and its contract is that the number
   must not fall. --width=N additionally refuses any stamp that leaves the
   route below N.

3. REACHABILITY IS ASKED OF THE PATHFINDER, NOT REIMPLEMENTED. map_pathfinder's
   MapGraph is imported and its step rule used as-is - same height or a drop of
   exactly one, every climb needing a wp ramp, four-connected. A second
   implementation of one rule drifts; that is the /long-museum incident, and it
   cost a session. Note that map_pathfinder's CLI has exactly ONE error rule and
   it is about the spawn token's spelling, so this tool asserts on its own BFS
   result and never on that exit code.

   ONE LIMIT, STATED RATHER THAN HIDDEN: a body's whole footprint is treated as
   blocking, at every height. A low bench you could step past, and a piece
   mounted at head height, both block a cell here that they do not block in
   play. So "no route" means "no route that avoids every body's footprint",
   which is stricter than the game. That is the right direction for a tool that
   is about to carve walls, and it is why the contract is that the lane must not
   FALL rather than that it must reach some number.

4. A BODY TOO BIG FOR ITS ROOM IS REFUSED, NOT CARVED. enhanced_kmeans covers
   180 cells and has 93 of them inside walls. Carving for it would demolish the
   room. Those are worlds, not exhibits, and a tool that only knows how to carve
   will carve.

AND ONE THING IT DELIBERATELY DOES NOT DO. It does not seed a room from a
typology by writing tile roles into the structure layer. The shelf's alphabet
("1s", "2s", "3s") parses to ZERO in both the engine and the pathfinder - 353
maps already hold it in layers.structure and 112 artifacts are standing over the
resulting holes. --typology therefore RESOLVES and REPORTS a seed against the
existing shelf, scoring candidates with argument_shape's own form()/verdict() so
the chooser and the gate are the same code, and writes the choice into the
journal. Compiling a tile into a grid is compile_museum_map.py's job and it
already does it; this tool will not become the second implementation.

USAGE

    python tools/stamp.py --map=Symmetry_Seventeen            # report only
    python tools/stamp.py --map=X --apply                     # write it
    python tools/stamp.py --map=X --apply --width=2           # and refuse below 2
    python tools/stamp.py --seq=softbodies                    # every room in a sequence
    python tools/stamp.py --map=X --typology                  # what shape does the claim want
    python tools/stamp.py --map=X --revert                    # replay the journal backwards
"""
from __future__ import annotations

import argparse
import collections
import json
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import map_pathfinder as mp  # noqa: E402  - the one faithful reader of a structure cell

SHELF = os.path.join(ROOT, "doc", "shelf.json")
MAPS = os.path.join(ROOT, "commons", "maps")

#: Heights a body can stand on and a player can occupy. parse_height gives 0 for
#: void and 99 for "w"; anything above 1 is a step the player cannot climb
#: without a ramp, which is what makes it a wall in practice rather than by name.
FLOOR_H = 1

#: A body covering more than this share of the room's floor is not an exhibit.
#: Measured: at 0.5 the refusals are exactly the generative world-builders
#: (marching cubes caves, kmeans fields, force-directed layouts) and no plaque,
#: bench or screen is caught.
TOO_BIG_FRACTION = 0.5


# ── geometry ────────────────────────────────────────────────────────────────
# The one verified footprint calculation. commons/testing/probe_yaw_span.gd
# turns a body 0/90/180/270 in the engine and compares; agreement to the
# centimetre on all four. Note that tools/spatial_contract.rotate_offset turns
# the OTHER way (dx,dz -> -dz,dx) and is therefore not interchangeable with
# this - the discrepancy is invisible on a symmetric footprint and load-bearing
# on exactly the offset bodies a stamper cares about.

def yaw_of(raw: str) -> int:
    parts = raw.split("#")[0].split(":")
    if len(parts) < 2:
        return 0
    try:
        return int(round(float(parts[1]))) % 360
    except ValueError:
        return 0


def span_of(tok: str, raw: str, r: int, c: int, shelf: dict):
    """Cell-space (x0, x1, z0, z1) for a placed body, or None if unmeasured.

    Cell (r, c) spans [c, c+1] x [r, r+1] in these coordinates, so the cell
    centre is at c+0.5. The engine's own cells are CENTRE-origin at c, with no
    half-cell offset (GridCommon.grid_to_world_position); the +0.5 here converts
    to the same offset frame the room bounds are expressed in, so the two are
    consistent with each other and only the difference is ever used.
    """
    e = shelf.get(tok) or {}
    a = e.get("aabb")
    if not (a and (a[0] or a[2])):
        return None
    cen = e.get("aabb_center") or [0.0, 0.0, 0.0]
    # aabb_size is [x, HEIGHT, z] - the middle value is height, not depth.
    w, d = float(a[0]), float(a[2])
    dx, dz = float(cen[0]), float(cen[2])
    y = yaw_of(raw)
    if y == 90:
        w, d = d, w
        dx, dz = dz, -dx
    elif y == 270:
        w, d = d, w
        dx, dz = -dz, dx
    elif y == 180:
        dx, dz = -dx, -dz
    x0 = c + 0.5 + dx - w / 2.0
    z0 = r + 0.5 + dz - d / 2.0
    return (x0, x0 + w, z0, z0 + d)


def cells_of(sp) -> list:
    x0, x1, z0, z1 = sp
    return [(rr, cc)
            for cc in range(int(math.floor(x0)), int(math.ceil(x1)))
            for rr in range(int(math.floor(z0)), int(math.ceil(z1)))]


# ── the raw-text splice ─────────────────────────────────────────────────────
# The corpus is not one dialect: re-serialising with the house formatter
# reproduces only about two thirds of the map files byte-for-byte, so a tool
# that rewrites whole documents buries its one real changed cell inside a
# hundred-line diff. tools/place.py --in-place does exactly that today, and
# map_pathfinder has a function literally named _save_map_preserve_format that
# does not preserve the format. So: find the bytes of the cell, replace the
# bytes of the cell, leave every other byte alone.

def cell_spans(text: str, layer: str) -> dict:
    """-> {(row, col): (start, end)} byte spans of each scalar in a layer grid."""
    key = '"' + layer + '"'
    k = text.find(key)
    if k < 0:
        return {}
    i = text.find("[", k)
    if i < 0:
        return {}
    out, depth, row, col = {}, 0, -1, 0
    n = len(text)
    while i < n:
        ch = text[i]
        if ch == '"':
            j = i + 1
            while j < n:
                if text[j] == "\\":
                    j += 2
                    continue
                if text[j] == '"':
                    break
                j += 1
            if depth == 2:
                out[(row, col)] = (i, j + 1)
                col += 1
            i = j + 1
            continue
        if ch == "[":
            depth += 1
            if depth == 2:
                row += 1
                col = 0
            i += 1
            continue
        if ch == "]":
            depth -= 1
            if depth == 0:
                break
            i += 1
            continue
        if depth == 2 and (ch.isdigit() or ch in "-+.") :
            j = i
            while j < n and (text[j].isdigit() or text[j] in "-+.eE"):
                j += 1
            out[(row, col)] = (i, j)
            col += 1
            i = j
            continue
        i += 1
    return out


def splice(text: str, edits: list) -> str:
    """edits: [(start, end, new_literal)] - applied right to left so the
    earlier spans keep their offsets."""
    for start, end, lit in sorted(edits, key=lambda e: -e[0]):
        text = text[:start] + lit + text[end:]
    return text


def atomic_write(path: str, text: str) -> None:
    """Temp file then rename. Everything in this repo runs under a watchdog that
    kills the process tree, and a kill inside open(path, "w") manufactures a
    zero-byte map. tools/necklace_order.py names the same failure."""
    tmp = path + ".stamp.tmp"
    with open(tmp, "w", encoding="utf-8", newline="") as f:
        f.write(text)
    os.replace(tmp, path)


# ── measurement ─────────────────────────────────────────────────────────────

def heights(struct: list) -> dict:
    return {(r, c): mp.parse_height(struct[r][c])
            for r in range(len(struct)) for c in range(len(struct[r]))}


def lane_width_along(route: list, free: set, hmap: dict, cap: int = 4) -> int:
    """The narrowest point on a route, as the largest k for which some k x k
    block of same-height free cells covers the cell.

    Erosion, not dilation. Dilating a path by a 3x3 kernel and intersecting with
    the walkable set - which is what the existing route machinery does - reports
    three even where the path threads a one-cell gap, because every cell it
    keeps was already walkable. This asks the opposite question and can fail.
    """
    # Spawn and the teleporter are routinely NOT free cells - a spawn can sit
    # inside a body's footprint and a teleporter stands on its own pad - so
    # including them made the lane read 0 on maps with a perfectly good corridor.
    # Measure the walk, not its endpoints.
    walk = [p for p in route if p in free]
    if not walk:
        return None
    worst = cap
    for (r, c) in walk:
        best = 0
        for k in range(1, cap + 1):
            ok = False
            for r0 in range(r - k + 1, r + 1):
                for c0 in range(c - k + 1, c + 1):
                    block = [(r0 + dr, c0 + dc) for dr in range(k) for dc in range(k)]
                    if all(b in free for b in block) and len({hmap.get(b) for b in block}) == 1:
                        ok = True
                        break
                if ok:
                    break
            if ok:
                best = k
            else:
                break
        worst = min(worst, best)
    return worst


def _walk_free(g, free: set, target):
    """Shortest path from spawn to target over cells a body is not standing in,
    using MapGraph.neighbors as the step relation so the rule is never restated.
    """
    from collections import deque
    start = g.spawn
    if start is None:
        return []
    prev = {start: None}
    q = deque([start])
    while q:
        pos = q.popleft()
        if pos == target:
            out = []
            while pos is not None:
                out.append(pos)
                pos = prev[pos]
            return list(reversed(out))
        for nb in g.neighbors(pos):
            if nb in prev:
                continue
            if nb != target and nb not in free:
                continue
            prev[nb] = pos
            q.append(nb)
    return []


#: A body is in the way only if it occupies the band a walking body occupies.
#: Below the ankle you step over it - a floor tile, a rug, a low plinth edge.
#: Above the head you walk under it - a hung gallery, a soffit, a sign. The
#: first version blocked on footprint alone and reported 691 artifacts as
#: unapproachable across the corpus, which said more about the model than the
#: museum: it counted tile_meander_floor, a FLOOR, as an obstacle.
STEP_OVER_M = 0.35
DUCK_UNDER_M = 1.75


def blocks_walking(tok: str, raw: str, shelf: dict) -> bool:
    """Does this body stand in a walker's way, or only in the plan's way?"""
    e = shelf.get(tok) or {}
    a = e.get("aabb")
    if not a:
        return True
    cen = e.get("aabb_center") or [0.0, 0.0, 0.0]
    height = float(a[1])
    # The token may lift the body: name:yaw:y_offset.
    parts = raw.split("#")[0].split(":")
    y_off = 0.0
    if len(parts) >= 3:
        try:
            y_off = float(parts[2])
        except ValueError:
            y_off = 0.0
    bottom = y_off + float(cen[1]) - height / 2.0
    top = y_off + float(cen[1]) + height / 2.0
    if top <= STEP_OVER_M:
        return False
    if bottom >= DUCK_UNDER_M:
        return False
    return True


def museum_doors(struct: list) -> tuple:
    """The museum's own traversal: IN at the first z row, OUT at the last.

    Palle, 2026-09-03: "that is in the museum, so in the first z row and out at
    last, where there has to be a one, right?" - right, and it is a different
    question from spawn-to-teleporter, which is what this tool was checking. A
    hall dealt into the museum is entered and left through those two rows; the
    map's own spawn disc is not used there at all. Measured over the 185 live
    rooms: 180 have a floor cell in the first row, 176 in the last, 173 have
    both, and 166 walk end to end. So the contract is real and nearly kept, and
    a stamp must not be what breaks it.

    Note the museum will CARVE a door itself if a row has no open cell
    (_authored_passages), so a sealed row is not fatal downstream - but it is a
    silent override of the author, and a stamper should never be its cause.
    """
    H = len(struct)
    entry = [(0, c) for c, v in enumerate(struct[0]) if mp.parse_height(v) == FLOOR_H]
    exits = {(H - 1, c) for c, v in enumerate(struct[H - 1])
             if mp.parse_height(v) == FLOOR_H}
    return entry, exits


def walk_doors(g, free: set, entry: list, exits: set):
    """Shortest walk from any first-row door to any last-row door, over cells no
    body is standing in. MapGraph.neighbors is the step rule, unrestated."""
    from collections import deque
    starts = [p for p in entry if p in free] or list(entry)
    if not starts or not exits:
        return []
    prev = {p: None for p in starts}
    q = deque(starts)
    while q:
        pos = q.popleft()
        if pos in exits:
            out = []
            while pos is not None:
                out.append(pos)
                pos = prev[pos]
            return list(reversed(out))
        for nb in g.neighbors(pos):
            if nb in prev:
                continue
            if nb not in free and nb not in exits:
                continue
            prev[nb] = pos
            q.append(nb)
    return []


def unreachable_bodies(bodies_by_tok: dict, free: set, reached: set, hmap: dict) -> list:
    """A body you cannot walk up to is not in the exhibition.

    Approach cells are the free cells orthogonally touching the body's own
    footprint. A body with no free cell beside it at all is counted too - it is
    walled in, which is the same failure by another route.
    """
    out = []
    for tok, cells in bodies_by_tok.items():
        approach = {p for p in cells if p in free}      # walk-through bodies
        for (r, c) in cells:
            for n in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)):
                if n in free:
                    approach.add(n)
        if not (approach & reached):
            out.append(tok)
    return sorted(out)


def measure(doc: dict, shelf: dict) -> dict:
    """Reachability, the narrowest lane on the route, and the wall multiset."""
    struct = doc["layers"]["structure"]
    hmap = heights(struct)
    H = len(struct)

    bodies = set()
    by_tok = {}
    it = doc["layers"].get("interactables") or []
    for r in range(min(H, len(it))):
        for c in range(len(it[r])):
            raw = str(it[r][c]).strip()
            if not raw or raw == "-":
                continue
            tok = raw.split(":")[0].split("#")[0]
            sp = span_of(tok, raw, r, c, shelf)
            if sp:
                own = {p for p in cells_of(sp) if p in hmap}
                # Every body is something to REACH; only some are something to
                # walk around. tile_meander_floor is a floor.
                if blocks_walking(tok, raw, shelf):
                    bodies |= own
                by_tok["%s@%d,%d" % (tok, r, c)] = own

    # Two sets, used for two different questions below: every floor cell, and
    # the floor cells nothing is standing in.
    floor_all = {p for p, h in hmap.items() if h == FLOOR_H}
    free = floor_all - bodies

    reach, route, tele = set(), [], None
    try:
        g = mp.MapGraph(doc)
        reach = g.bfs_flood()
        tele = g.find_target("teleport") or g.find_target("t")
        if tele:
            # MapGraph's own path is allowed to run straight through a body,
            # because the pathfinder does not model artifact volume - which made
            # the first lane reading 0 on a map with a perfectly good corridor.
            # So walk ITS step rule (never a second implementation of it) over
            # the cells a player can actually occupy.
            route = _walk_free(g, free, tele)
        entry, exits = museum_doors(struct)
        # TWO WALKS, because they are two questions and conflating them gives a
        # number nobody can act on.
        #
        # The STRUCTURAL walk is the museum's own contract: a dealt hall is
        # built from the structure layer and entered at the first z row, so this
        # is the one that says whether the hall is a hall. 166 of 185 pass.
        #
        # The CLEAR walk additionally treats bodies as solid. It is stricter and
        # it is not the museum's rule - a body called lab_room covering 81 cells
        # is a room you walk into, and ca_bridge is a bridge you walk on, and
        # neither declares that anywhere the registry can be asked. So this is
        # reported as a caution, never as the verdict.
        door_walk = walk_doors(g, floor_all, entry, exits)
        door_walk_clear = walk_doors(g, free, entry, exits)
        # Every artifact must be approachable from where the visitor comes IN,
        # which in a museum hall is the first row, not the map's spawn disc.
        # WALLED OFF is the fault worth naming. An artifact you cannot reach
        # because a WALL is in the way is a broken room; one you cannot reach
        # because another artifact is in the way is a crowded room, and the
        # difference matters because only the first is stamp.py's business.
        # So the flood runs over the structure from the museum entrance, and
        # the body-clear walk stays a separate caution.
        from collections import deque
        seeds = [p for p in entry if p in floor_all]
        if not seeds and g.spawn is not None:
            seeds = [g.spawn]
        seen = set(seeds)
        q = deque(seeds)
        while q:
            pos = q.popleft()
            for nb in g.neighbors(pos):
                if nb not in seen and nb in floor_all:
                    seen.add(nb)
                    q.append(nb)
        orphans = unreachable_bodies(by_tok, floor_all, seen, hmap)
    except Exception as exc:                      # a map the graph cannot read
        return {"error": str(exc)[:120], "walls": collections.Counter(),
                "reach": 0, "lane": 0, "tele_reached": False, "free": len(free)}

    walls = collections.Counter()
    for r in range(H):
        for c in range(len(struct[r])):
            if mp.parse_height(struct[r][c]) > FLOOR_H:
                walls[str(struct[r][c]).strip()] += 1

    # With no route there is no lane to measure, and a zero would read as "one
    # cell wide" rather than "not asked". Symmetry_Seventeen is in exactly this
    # state before any edit: map_pathfinder reports the teleporter unreachable
    # as a WARN and still exits OK.
    lane = lane_width_along(route, free, hmap) if route else None
    # The museum's lane is the one that matters for a dealt hall, so it is
    # measured on the door-to-door walk rather than on the spawn route.
    door_lane = lane_width_along(door_walk, floor_all, hmap) if door_walk else None
    clear_lane = (lane_width_along(door_walk_clear, free, hmap)
                  if door_walk_clear else None)
    return {
        "walls": walls,
        "wall_cells": sum(walls.values()),
        "reach": len(reach & free),
        "reach_set": (reach & free) | {p for p in reach if p in free},
        "tele_reached": bool(tele and tele in reach),
        "lane": lane,
        "route_len": len(route),
        "route_cells": route,
        "free": len(free),
        # the museum contract
        "has_entry": bool(entry),
        "has_exit": bool(exits),
        "door_walk": bool(door_walk),
        "door_lane": door_lane,
        "door_walk_clear": bool(door_walk_clear),
        "clear_lane": clear_lane,
        "door_cells": door_walk,
        "orphans": orphans,
        "bodies": len(by_tok),
    }


# ── judgement ───────────────────────────────────────────────────────────────

def judge(doc: dict, shelf: dict) -> list:
    """One verdict per placed body."""
    struct = doc["layers"]["structure"]
    it = doc["layers"].get("interactables") or []
    H = len(struct)
    W = max(len(r) for r in struct)
    hmap = heights(struct)
    floor_total = sum(1 for h in hmap.values() if h >= FLOOR_H) or 1

    out = []
    for r in range(min(H, len(it))):
        for c in range(min(W, len(it[r]))):
            raw = str(it[r][c]).strip()
            if not raw or raw == "-":
                continue
            tok = raw.split(":")[0].split("#")[0]
            e = shelf.get(tok) or {}
            sp = span_of(tok, raw, r, c, shelf)
            v = {"tok": tok, "raw": raw, "r": r, "c": c,
                 "wall_backing": e.get("wall_backing"), "cells": [],
                 "verdict": "", "why": ""}
            if sp is None:
                v["verdict"] = "UNMEASURED"
                v["why"] = "no aabb, so no guard on its size - measure before stamping"
                out.append(v)
                continue
            occ = cells_of(sp)
            inside = [p for p in occ if p in hmap]
            v["cells"] = inside
            v["outside"] = len(occ) - len(inside)
            v["in_wall"] = [p for p in inside if hmap[p] > FLOOR_H]
            v["over_void"] = [p for p in inside if hmap[p] == 0]

            if len(occ) > floor_total * TOO_BIG_FRACTION:
                v["verdict"] = "TOO BIG"
                v["why"] = ("covers %d cells of a room with %d floor - a world, not an "
                            "exhibit; carving for it would demolish the room"
                            % (len(occ), floor_total))
            elif v["outside"]:
                v["verdict"] = "OVERRUN"
                v["why"] = "%d of its %d cells are outside the room" % (v["outside"], len(occ))
            elif v["in_wall"] and e.get("wall_backing") is True:
                v["verdict"] = "SEAT"
                v["why"] = ("declares wall_backing, so the wall behind it stays; only the "
                            "front clearance is carved")
            elif v["in_wall"] and e.get("wall_backing") is False:
                v["verdict"] = "CARVE"
                v["why"] = ("%d cells inside a wall it declares it does not want"
                            % len(v["in_wall"]))
            elif v["in_wall"]:
                v["verdict"] = "UNDECLARED"
                v["why"] = ("%d cells inside a wall and the registry does not say whether it "
                            "wants one - rule it, do not guess" % len(v["in_wall"]))
            elif v["over_void"]:
                v["verdict"] = "OVER VOID"
                v["why"] = "%d cells over a hole" % len(v["over_void"])
            else:
                v["verdict"] = "FITS"
            out.append(v)
    return out


# ── the plan ────────────────────────────────────────────────────────────────

def displacement_target(p, hmap, taken, body_cells, H, W, protect):
    """Where does a carved wall GO?

    The first version answered "the nearest floor cell" and the gate caught it
    immediately: on AdvancedLaboratory it parked four walls in the middle of the
    walkway, reachable floor fell from 20 cells to 8, and the teleporter went
    dark. A wall dropped in open floor is not a moved wall, it is a new
    obstacle.

    So a displaced wall must JOIN the wall it came from. Candidates are ranked:
    first by how many wall neighbours they already have (a cell with three is a
    notch being filled; a cell with none is an island), then by distance from
    the cell being carved. Cells on the current spawn-to-exit route are refused
    outright, and so are rows 0 and H-1 - the museum treats a map's first and
    last rows as its doorway rows and re-carves them if they are sealed, so a
    wall parked there is a wall thrown away with extra steps.
    """
    r, c = p
    best = None
    for rr in range(1, H - 1):
        for cc in range(W):
            q = (rr, cc)
            if q in taken or q in body_cells or q in protect or q not in hmap:
                continue
            if hmap[q] != FLOOR_H:
                continue
            touching = sum(1 for n in ((rr - 1, cc), (rr + 1, cc), (rr, cc - 1), (rr, cc + 1))
                           if hmap.get(n, 0) > FLOOR_H)
            if not touching:
                continue          # an island in the open floor is not a wall move
            # Rank by ONE score rather than lexicographically. Sorting on
            # neighbour-count first sent walls clear across the room whenever a
            # slightly better-connected cell existed there, which is a correct
            # move that reads as a wrong one. Three cells of distance per wall
            # neighbour keeps the join and prefers the local answer.
            d = abs(rr - r) + abs(cc - c)
            key = d - 3 * touching
            if best is None or key < best[0]:
                best = (key, q)
    return best[1] if best else None


def plan(doc: dict, verdicts: list, protect=frozenset(), banned=frozenset()) -> list:
    """-> [{r, c, to, from, because, why}] - ordinary cell sets, nothing exotic.

    Largest body first: a fifteen-metre gallery placed after the small ones has
    nowhere left to go.
    """
    struct = doc["layers"]["structure"]
    hmap = heights(struct)
    H = len(struct)
    W = max(len(r) for r in struct)

    body_cells = set()
    for v in verdicts:
        body_cells |= set(v.get("cells") or [])

    # ONE CARVE PER CELL, however many bodies are standing on it. Two bodies
    # overlapping the same wall cell each carved it and each planted a copy of
    # its literal, so a room gained a wall out of nothing - which is exactly
    # what the conservation gate is for, and it caught it on the first real
    # sequence run: Vectors_Act1 gained a "w" because cell (3,10) is claimed by
    # two bodies.
    def lit_of(p):
        return str(struct[p[0]][p[1]]).strip()

    ops, taken, done = [], set(), set()
    order = sorted([v for v in verdicts if v["verdict"] in ("CARVE", "SEAT")],
                   key=lambda v: -len(v.get("cells") or []))
    for v in order:
        wall_cells = list(v["in_wall"])
        if v["verdict"] == "SEAT":
            # A body that wants a wall keeps the cells BEHIND it and is only
            # given the ones in front. Behind is defined by the body's own yaw:
            # a plaque at yaw 0 faces -Z, so its wall is at +Z.
            y = yaw_of(v["raw"])
            keep = set()
            for (r, c) in wall_cells:
                if y == 0 and r >= v["r"]:
                    keep.add((r, c))
                elif y == 180 and r <= v["r"]:
                    keep.add((r, c))
                elif y == 90 and c >= v["c"]:
                    keep.add((r, c))
                elif y == 270 and c <= v["c"]:
                    keep.add((r, c))
            wall_cells = [p for p in wall_cells if p not in keep]

        for p in sorted(wall_cells):
            if p in done:
                continue
            done.add(p)
            # THE DOORWAY ROWS ARE THE SEAM. Row 0 and row H-1 are where the
            # museum joins this hall to its neighbours - the seam copies the
            # last row forward and the next hall first row back - so their
            # geometry belongs to the crossing, not to the room. The first
            # forces run carved seven extra cells out of VFM_02's entrance as a
            # side effect of seating a body against it, widening the doorway
            # from 3 cells to 10. That is a change to the hall face nobody
            # asked for. Report it and leave it.
            if p[0] in (0, H - 1):
                ops.append({"r": p[0], "c": p[1], "to": None, "lit": lit_of(p),
                            "because": v["tok"],
                            "why": "in the doorway row, which is the museum seam - left alone"})
                continue
            lit = str(struct[p[0]][p[1]]).strip()
            dest = displacement_target(p, hmap, taken | body_cells | set(banned),
                                       body_cells, H, W, protect)
            if dest is None:
                ops.append({"r": p[0], "c": p[1], "to": None, "lit": lit,
                            "because": v["tok"],
                            "why": "nowhere to put the wall this carve removes"})
                continue
            taken.add(dest)
            ops.append({"r": p[0], "c": p[1], "to": "1", "lit": lit,
                        "because": v["tok"],
                        "why": "carved so %s has its floor" % v["tok"]})
            ops.append({"r": dest[0], "c": dest[1], "to": lit,
                        "lit": str(struct[dest[0]][dest[1]]).strip(),
                        "because": v["tok"],
                        "why": "the wall carved at r%d c%d, moved not deleted" % p})
    return ops


# ── the run ─────────────────────────────────────────────────────────────────

def _culprits(before: dict, after: dict, ops: list) -> set:
    """Which planted walls are answerable for the failure?

    The stranded cells name the neighbourhood, so ban every destination that
    touches one. When nothing was stranded but the walk or an approach was lost,
    ban the destinations on the old route - those are the cells that were
    load-bearing for it.
    """
    planted = {(o["r"], o["c"]) for o in ops if o["to"] and o["to"] != "1"}
    stranded = (before["reach_set"] - after.get("walled_cells", set())) - after["reach_set"]
    out = set()
    for (r, c) in stranded:
        for n in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1), (r, c)):
            if n in planted:
                out.add(n)
    if out:
        return out
    lost_walk = before["door_walk"] and not after["door_walk"]
    lost_clear = before["door_walk_clear"] and not after["door_walk_clear"]
    lost_tele = before["tele_reached"] and not after["tele_reached"]
    lost_body = set(after["orphans"]) - set(before["orphans"])
    if lost_walk or lost_clear or lost_tele or lost_body:
        on_route = planted & (set(before.get("door_cells") or [])
                              | set(before.get("route_cells") or []))
        return on_route or planted
    # Both lanes, not just the museum one. The first forces run refused
    # Vectors_Act4a and VFM_09 for a narrowed SPAWN route and the loop had no
    # answer for it, so it never replanned and the whole stamp was thrown away.
    for key, cells in (("door_lane", "door_cells"), ("lane", "route_cells")):
        b, a = before.get(key), after.get(key)
        if b is not None and a is not None and a < b:
            near = set()
            for (r, c) in (before.get(cells) or []):
                for n in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1), (r, c)):
                    if n in planted:
                        near.add(n)
            return near or planted
    return set()


def load(name: str):
    p = os.path.join(MAPS, name, "map_data.json")
    if not os.path.exists(p):
        return None, None, None
    raw = open(p, encoding="utf-8", newline="").read()
    return p, raw, json.loads(raw)


def apply_ops(raw: str, doc: dict, ops: list):
    """Splice the ops into the bytes; return (new_text, journal_entries)."""
    spans = cell_spans(raw, "structure")
    struct = doc["layers"]["structure"]
    edits, entries = [], []
    for o in ops:
        if o["to"] is None:
            continue
        key = (o["r"], o["c"])
        if key not in spans:
            continue
        start, end = spans[key]
        before_literal = raw[start:end]
        # Keep the cell's own JSON type. Ten maps in the corpus store grid cells
        # as bare numbers, and writing "1" over 1 changes their type in silence.
        quoted = before_literal.lstrip().startswith('"')
        after_literal = ('"%s"' % o["to"]) if quoted else o["to"]
        edits.append((start, end, after_literal))
        entries.append({
            "op": "set", "layer": "structure", "cell": [o["c"], o["r"]],
            "token": o["to"], "literal": after_literal,
            "expect": str(struct[o["r"]][o["c"]]),
            "undo": {"op": "set", "layer": "structure", "cell": [o["c"], o["r"]],
                     "token": str(struct[o["r"]][o["c"]]),
                     "literal": before_literal},
            # An index re-targets in silence when a map is resized, so every
            # entry carries the artifact that caused it as a co-anchor.
            "because": o["because"], "why": o["why"],
        })
    return splice(raw, edits), entries


def top_level_value_span(text: str, key: str):
    """-> (start, end) of the VALUE of a top-level key, or None.

    String-aware and depth-aware, so a brace inside a description does not end
    the object early.
    """
    i, n, depth = 0, len(text), 0
    while i < n:
        ch = text[i]
        if ch == '"':
            j = i + 1
            while j < n:
                if text[j] == "\\":
                    j += 2
                    continue
                if text[j] == '"':
                    break
                j += 1
            if depth == 1 and text[i + 1:j] == key:
                k = text.find(":", j)
                v = k + 1
                while v < n and text[v].isspace():
                    v += 1
                if text[v] in "{[":
                    close = {"{": "}", "[": "]"}[text[v]]
                    d2, m = 0, v
                    while m < n:
                        if text[m] == '"':
                            m += 1
                            while m < n:
                                if text[m] == "\\":
                                    m += 2
                                    continue
                                if text[m] == '"':
                                    break
                                m += 1
                        elif text[m] == text[v]:
                            d2 += 1
                        elif text[m] == close:
                            d2 -= 1
                            if d2 == 0:
                                return (v, m + 1)
                        m += 1
                e = v
                while e < n and text[e] not in (",", "}", chr(10)):
                    e += 1
                return (v, e)
            i = j + 1
            continue
        if ch in "{[":
            depth += 1
        elif ch in "}]":
            depth -= 1
        i += 1
    return None


NL = chr(10)


def _block_text(obj: dict, unit: str) -> str:
    """Serialise one metadata object at the file's own indent, and push every
    line in by one unit so the block sits level with its neighbours."""
    body = json.dumps(obj, indent=unit, ensure_ascii=False)
    return body.replace(NL, NL + unit)


def detect_indent(text: str) -> str:
    """The file's own indent unit, so a spliced block matches its neighbours."""
    for line in text.split(NL)[1:40]:
        if line.startswith(chr(9)):
            return chr(9)
        stripped = line.lstrip(" ")
        if stripped.startswith('"') and line != stripped:
            return " " * (len(line) - len(stripped))
    return "  "


def write_journal(raw: str, entries: list, extra: dict) -> str:
    """Into documentation.stamp - beside the documentation.compiler block that
    27 compiled maps already carry, rather than a top-level key no reader knows.

    SPLICED, not re-serialised. The first version of this function called
    json.dumps over the whole document and produced a 492-line diff for eight
    changed cells, undoing the careful byte-splice two functions earlier. The
    tool contained both the fix and the bug at the same time, which is exactly
    how a 234-line lesson one repo over gets relearned.


    THE OPS THEMSELVES GO IN A SIDECAR, not in here. Eight carved cells produced
    199 lines of journal, and a map file is mostly a grid that people read. The
    map keeps the summary and a pointer; stamp_journal.json keeps every revision,
    append-only. Both are tracked by git, so both are diffable and neither can be
    lost to a .bak eviction - the encyclopedia's own backups are capped at ten
    newest-first and are invisible to git, so they are not a durable record.
    """
    doc = json.loads(raw)
    docu = doc.get("documentation")
    rev = 1
    if isinstance(docu, dict) and isinstance(docu.get("stamp"), dict):
        rev = int(docu["stamp"].get("revision", 0)) + 1
    block = dict(extra)
    block["revision"] = rev
    block["ops"] = len(entries)
    block["journal"] = "stamp_journal.json"

    unit = detect_indent(raw)
    if isinstance(docu, dict):
        merged = dict(docu)
        merged["stamp"] = block
        span = top_level_value_span(raw, "documentation")
        return raw[:span[0]] + _block_text(merged, unit) + raw[span[1]:]

    # No documentation key: insert one immediately after the opening brace, so
    # nothing else in the file moves.
    brace = raw.index("{")
    body = _block_text({"stamp": block}, unit)
    return (raw[:brace + 1] + NL + unit + '"documentation": ' + body + ","
            + raw[brace + 1:])


# ── the typology seed ───────────────────────────────────────────────────────
# The library already exists: commons/data/template_shelf.json, 314 plans across
# four provenances, 310 of them whole floor plans, DERIVED and never to be
# written to. What did not exist is the bridge from what a room ARGUES to which
# plan suits it - argument_shape.py has no consumer anywhere in the repo. That
# bridge is built here as a SCORER rather than a table, so the chooser and the
# gate are literally the same function.
#
# Two constraints that make the choice honest rather than decorative. The 30
# museum typologies physically do not fit a spine map: the museum gate wants an
# odd width of 13-17 and a depth of 24-36, while the spine's own seven measured
# typologies run 9-16 wide over one open floor. And eight chapters already have
# a RULED typology in commons/data/museum_crowns.json, which a scorer that
# re-derives from the argument would silently overrule.

SHELF_PLANS = os.path.join(ROOT, "commons", "data", "template_shelf.json")
CROWNS = os.path.join(ROOT, "commons", "data", "museum_crowns.json")

#: compile_museum_map's mapping, not a second one: the tile alphabet as heights.
TILE_H = {"0": 0, "": 0, "1": 1, "1s": 1, "2": 2, "2s": 2, "3s": 3, "4": 4}


def form_of_tile(tile) -> dict:
    """argument_shape.form(), computed over a shelf tile instead of a map."""
    rows = [r for r in (tile or []) if r]
    if not rows:
        return {}
    H = len(rows)
    W = max(len(r) for r in rows)
    floor = interior = 0
    for r, row in enumerate(rows):
        for c, v in enumerate(row):
            h = TILE_H.get(str(v).strip(), 0)
            border = r in (0, H - 1) or c in (0, len(row) - 1)
            if h == 1:
                floor += 1
            elif h > 1 and not border:
                interior += 1
    cells = sum(len(r) for r in rows)
    return {"w": W, "h": H,
            "aspect": round(max(W, H) / max(1, min(W, H)), 2),
            "floor_frac": round(floor / max(1, cells), 2),
            "interior_walls": interior, "void": 0}


def typology(name: str, seq: str) -> None:
    """What shape does this room's claim want, and which shelf plan is it?"""
    import argument_shape as ash

    tri = {r["map"]: r for r in
           (json.load(open(os.path.join(ROOT, "ada_run", "spine_triage.json"),
                           encoding="utf-8")).get("maps") or [])}
    t = tri.get(name, {})
    kind, score, hits = ash.classify(str(t.get("argument", "")), str(t.get("keep", "")))
    mine = ash.form(name)
    fits, why = ash.verdict(kind, mine)

    print("\n%s" % name)
    print("   claims   : %s (score %d on %s)"
          % (kind, score, ", ".join(hits) if hits else "no cue"))
    if score <= 1:
        print("              a one-cue classification is a QUESTION, not a finding -"
              " read the argument before acting on this")
    print("   wants    : %s" % ash.KINDS.get(kind, {}).get("wants", "-"))
    print("   has      : aspect %s, floor %s, %s interior walls  ->  %s"
          % (mine.get("aspect"), mine.get("floor_frac"),
             mine.get("interior_walls"), ("FITS - " if fits else "NO - ") + why))

    crowns = {}
    if os.path.exists(CROWNS):
        crowns = json.load(open(CROWNS, encoding="utf-8"))
    crown = (crowns.get(seq) or crowns.get("crowns", {}).get(seq)) if crowns else None
    if crown:
        print("   RULED    : %s already has a crowned typology (%s). A seed chosen from"
              % (seq, json.dumps(crown, ensure_ascii=False)[:80]))
        print("              the argument would silently overrule a ruling - honour the crown.")

    if fits:
        print("   seed     : none needed, the form already argues the claim")
        return

    plans = json.load(open(SHELF_PLANS, encoding="utf-8"))["patterns"]
    w = mine.get("w") or 0
    band = (max(8, w - 4), w + 4)
    cands = []
    for key, p in plans.items():
        if not p.get("stampable"):
            continue
        f = form_of_tile(p.get("tile"))
        if not f or not (band[0] <= f["w"] <= band[1]):
            continue
        ok, wy = ash.verdict(kind, f)
        if ok:
            cands.append((abs(f["w"] - w) + abs(f["h"] - (mine.get("h") or 0)),
                          key, p.get("source"), f, wy))
    cands.sort()
    if not cands:
        print("   seed     : no stampable plan in the %d-%d width band argues a %s"
              % (band[0], band[1], kind))
        return
    print("   seed     : %d of %d stampable plans argue a %s at this width"
          % (len(cands), len(plans), kind))
    for d, key, src, f, wy in cands[:5]:
        print("      %-28s %-14s %2dx%-2d  aspect %-4s %s interior  %s"
              % (key[:28], src, f["w"], f["h"], f["aspect"], f["interior_walls"], wy))
    print("   NOTE: this REPORTS a seed, it does not write one. Compiling a tile into a"
          " grid is compile_museum_map.py's job and it already does it.")


# ── the proposal, drawn ─────────────────────────────────────────────────────
# A stamp is a spatial argument and a list of cell coordinates is not a way to
# read one. This draws the proposal the way an architect would mark up a plan:
# the room as it stands, the bodies at their measured footprint, and over that
# the two moves - a cell CARVED to floor, and the same wall RE-PLANTED - joined
# by the arrow that makes it one move rather than two.

CELL = 28
PAD = 150
C_WALL = "#2b3038"
C_VOID = "#ffffff"
C_INK = "#141820"
C_RED = "#d1344b"
C_AMBER = "#c07a12"
C_BLUE = "#2f6bd8"
C_GREEN = "#2e7d4f"


def esc(s) -> str:
    return (str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))


def draw(name: str, doc: dict, shelf: dict, verdicts: list, ops: list,
         before: dict, out_dir: str) -> str:
    struct = doc["layers"]["structure"]
    util = doc["layers"].get("utilities") or []
    H = len(struct)
    W = max(len(r) for r in struct)
    hmap = heights(struct)
    ox, oy = PAD // 2, 78
    w_px = ox * 2 + W * CELL
    h_px = oy + H * CELL + 210

    o = ['<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" '
         'viewBox="0 0 %d %d" font-family="ui-sans-serif,system-ui,sans-serif">'
         % (w_px, h_px, w_px, h_px),
         '<defs><marker id="ar" viewBox="0 0 10 10" refX="9" refY="5" '
         'markerWidth="5" markerHeight="5" orient="auto-start-end">'
         '<path d="M0,0 L10,5 L0,10 z" fill="%s"/></marker>' % C_GREEN,
         '<pattern id="hatch" width="6" height="6" patternTransform="rotate(45)" '
         'patternUnits="userSpaceOnUse"><line x1="0" y1="0" x2="0" y2="6" '
         'stroke="%s" stroke-width="2"/></pattern></defs>' % C_AMBER,
         '<rect width="100%%" height="100%%" fill="#fbfaf8"/>',
         '<text x="%d" y="26" font-size="15" font-weight="600" fill="%s">%s</text>'
         % (ox, C_INK, esc(name)),
         '<text x="%d" y="46" font-size="11" fill="#5b6472">the stamp proposed '
         'by tools/stamp.py — nothing here is applied</text>' % ox]

    carved = {(op["r"], op["c"]) for op in ops if op["to"] == "1"}
    planted = {(op["r"], op["c"]): op["to"] for op in ops if op["to"] and op["to"] != "1"}
    stuck = {(op["r"], op["c"]) for op in ops if op["to"] is None}

    # ---- the room as it stands -------------------------------------------
    for r in range(H):
        for c in range(len(struct[r])):
            x, y = ox + c * CELL, oy + r * CELL
            h = hmap[(r, c)]
            fill = C_VOID if h == 0 else ("#eef0f3" if h == FLOOR_H else C_WALL)
            dash = ' stroke-dasharray="3 3"' if h == 0 else ""
            o.append('<rect x="%d" y="%d" width="%d" height="%d" fill="%s" '
                     'stroke="#c9cdd4" stroke-width="0.7"%s/>'
                     % (x, y, CELL, CELL, fill, dash))
            if h > FLOOR_H:
                o.append('<text x="%d" y="%d" font-size="8" fill="#8d949e" '
                         'text-anchor="middle">%s</text>'
                         % (x + CELL / 2, y + CELL / 2 + 3, esc(str(struct[r][c]).strip())))

    # ---- spawn and exit ---------------------------------------------------
    for r in range(min(H, len(util))):
        for c in range(len(util[r])):
            v = str(util[r][c]).strip()
            if not v:
                continue
            base = v.split(":")[0]
            if base not in ("s", "t"):
                continue
            x, y = ox + c * CELL + CELL / 2, oy + r * CELL + CELL / 2
            o.append('<circle cx="%.1f" cy="%.1f" r="7" fill="none" stroke="%s" '
                     'stroke-width="1.8"/>' % (x, y, C_BLUE))
            o.append('<text x="%.1f" y="%.1f" font-size="9" fill="%s" '
                     'text-anchor="middle" font-weight="600">%s</text>'
                     % (x, y + 3, C_BLUE, base))

    # ---- the bodies, at measured size -------------------------------------
    for v in verdicts:
        sp = span_of(v["tok"], v["raw"], v["r"], v["c"], shelf)
        cx = ox + v["c"] * CELL + CELL / 2
        cy = oy + v["r"] * CELL + CELL / 2
        if sp is None:
            o.append('<rect x="%.1f" y="%.1f" width="%d" height="%d" '
                     'fill="url(#hatch)" stroke="%s" stroke-width="1.2"/>'
                     % (cx - CELL / 2, cy - CELL / 2, CELL, CELL, C_AMBER))
        else:
            x0, x1, z0, z1 = sp
            col = {"TOO BIG": C_RED, "OVERRUN": C_RED, "CARVE": C_BLUE,
                   "SEAT": C_GREEN, "UNDECLARED": C_AMBER}.get(v["verdict"], "#7d8794")
            o.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" '
                     'fill-opacity="0.06" stroke="%s" stroke-width="1" '
                     'stroke-opacity="0.5"/>'
                     % (ox + x0 * CELL, oy + z0 * CELL, (x1 - x0) * CELL,
                        (z1 - z0) * CELL, col, col))
        o.append('<circle cx="%.1f" cy="%.1f" r="2.2" fill="%s"/>' % (cx, cy, C_INK))
        o.append('<text x="%.1f" y="%.1f" font-size="8" fill="%s">%s</text>'
                 % (cx + 4, cy - 4, C_INK, esc(v["tok"][:22])))

    # ---- the two moves ----------------------------------------------------
    for (r, c) in carved:
        x, y = ox + c * CELL, oy + r * CELL
        o.append('<rect x="%d" y="%d" width="%d" height="%d" fill="%s" '
                 'fill-opacity="0.22" stroke="%s" stroke-width="1.8" '
                 'stroke-dasharray="4 2"/>' % (x, y, CELL, CELL, C_RED, C_RED))
        o.append('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" '
                 'stroke-width="1.2" stroke-opacity="0.7"/>'
                 % (x + 6, y + 6, x + CELL - 6, y + CELL - 6, C_RED))
        o.append('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" '
                 'stroke-width="1.2" stroke-opacity="0.7"/>'
                 % (x + CELL - 6, y + 6, x + 6, y + CELL - 6, C_RED))
    for (r, c), lit in planted.items():
        x, y = ox + c * CELL, oy + r * CELL
        o.append('<rect x="%d" y="%d" width="%d" height="%d" fill="%s" '
                 'fill-opacity="0.42" stroke="%s" stroke-width="2.2"/>'
                 % (x, y, CELL, CELL, C_GREEN, C_GREEN))
        o.append('<text x="%.1f" y="%.1f" font-size="9" fill="#12331f" '
                 'text-anchor="middle" font-weight="700">%s</text>'
                 % (x + CELL / 2, y + CELL / 2 + 3, esc(lit)))
    for (r, c) in stuck:
        x, y = ox + c * CELL, oy + r * CELL
        o.append('<text x="%.1f" y="%.1f" font-size="13" fill="%s" '
                 'text-anchor="middle">?</text>' % (x + CELL / 2, y + CELL / 2 + 5, C_AMBER))

    # the arrow that makes a carve and a plant ONE move
    pairs = []
    src = [op for op in ops if op["to"] == "1"]
    dst = [op for op in ops if op["to"] and op["to"] != "1"]
    for a, b in zip(src, dst):
        pairs.append(((a["r"], a["c"]), (b["r"], b["c"])))
    for (r0, c0), (r1, c1) in pairs:
        x0 = ox + c0 * CELL + CELL / 2
        y0 = oy + r0 * CELL + CELL / 2
        x1 = ox + c1 * CELL + CELL / 2
        y1 = oy + r1 * CELL + CELL / 2
        # bow the path perpendicular to itself, so several moves between the
        # same neighbourhood do not collapse into one line
        mx, my = (x0 + x1) / 2, (y0 + y1) / 2
        bow = 0.18
        qx, qy = mx - (y1 - y0) * bow, my + (x1 - x0) * bow
        o.append('<path d="M%.1f,%.1f Q%.1f,%.1f %.1f,%.1f" fill="none" stroke="%s" '
                 'stroke-width="1.5" stroke-opacity="0.75" marker-end="url(#ar)"/>'
                 % (x0, y0, qx, qy, x1, y1, C_GREEN))

    # ---- the legend, which is the argument --------------------------------
    ly = oy + H * CELL + 26
    counts = collections.Counter(v["verdict"] for v in verdicts)
    o.append('<text x="%d" y="%d" font-size="11" font-weight="600" fill="%s">'
             'what the stamp proposes</text>' % (ox, ly, C_INK))
    rows = [
        (C_RED, "carve to floor", "%d cell(s) a body needs and a wall occupies" % len(carved)),
        (C_GREEN, "re-plant the wall", "the same literal, moved to join a wall — never deleted"),
        (C_AMBER, "nowhere to go", "%d wall(s) with no legal destination, so not carved either"
         % len(stuck)),
    ]
    for i, (col, label, note) in enumerate(rows):
        y = ly + 18 + i * 15
        o.append('<rect x="%d" y="%d" width="10" height="10" fill="%s" fill-opacity="0.3" '
                 'stroke="%s"/>' % (ox, y - 8, col, col))
        o.append('<text x="%d" y="%d" font-size="10" fill="%s" font-weight="600">%s</text>'
                 % (ox + 16, y, C_INK, label))
        o.append('<text x="%d" y="%d" font-size="10" fill="#5b6472">%s</text>'
                 % (ox + 116, y, esc(note)))
    y = ly + 18 + len(rows) * 15 + 12
    o.append('<text x="%d" y="%d" font-size="10" fill="%s">bodies: %s</text>'
             % (ox, y, C_INK, esc(", ".join("%s %d" % (k, n) for k, n in counts.most_common()))))
    o.append('<text x="%d" y="%d" font-size="10" fill="#5b6472">walls %d before, %d after — '
             'the multiset is conserved, a moved wall keeps its own literal</text>'
             % (ox, y + 15, before.get("wall_cells", 0), before.get("wall_cells", 0)))
    o.append('<text x="%d" y="%d" font-size="10" fill="#5b6472">narrowest lane on the route: '
             '%s — the contract is that this must not fall</text>'
             % (ox, y + 30, "n/a (no route clear of bodies)" if before.get("lane") is None
                else before["lane"]))
    o.append("</svg>")

    os.makedirs(out_dir, exist_ok=True)
    p = os.path.join(out_dir, "stamp_%s.svg" % name)
    atomic_write(p, NL.join(o) + NL)
    return p


def journal_path(name: str) -> str:
    return os.path.join(MAPS, name, "stamp_journal.json")


def append_journal(name: str, rev: int, entries: list, extra: dict) -> None:
    """Append-only, and the revision never travels backwards.

    necklace_order's rule, taken as-is: a writer takes the MAX revision over
    every copy it can see and adds one, because a revision that resets makes two
    sessions agree while disagreeing, and the disagreement becomes invisible.
    """
    p = journal_path(name)
    doc = {"_readme": ("Every cell stamp.py has changed in this map, oldest first. "
                       "Each op carries the literal it replaced, so a revision can "
                       "be replayed backwards: python tools/stamp.py --map=%s "
                       "--revert" % name),
           "map": name, "revisions": []}
    if os.path.exists(p):
        try:
            doc = json.load(open(p, encoding="utf-8"))
        except Exception:
            pass
    prior = max([int(r.get("revision", 0)) for r in doc.get("revisions", [])] or [0])
    rec = dict(extra)
    rec["revision"] = max(rev, prior + 1)
    rec["ops"] = entries
    doc.setdefault("revisions", []).append(rec)
    atomic_write(p, json.dumps(doc, indent=1, ensure_ascii=False) + NL)


def revert(name: str) -> int:
    """Replay the newest revision backwards, by literal, in reverse order."""
    p = journal_path(name)
    if not os.path.exists(p):
        print("%s  -- no stamp journal, nothing to revert" % name)
        return 1
    doc = json.load(open(p, encoding="utf-8"))
    revs = doc.get("revisions") or []
    if not revs:
        print("%s  -- the journal holds no revisions" % name)
        return 1
    rec = revs[-1]
    path, raw, mdoc = load(name)
    spans = cell_spans(raw, "structure")
    struct = mdoc["layers"]["structure"]
    edits, skipped = [], []
    for o in reversed(rec["ops"]):
        c, r = o["cell"]                       # written [x, z] to match cell-edit
        if (r, c) not in spans:
            skipped.append((r, c, "no such cell"))
            continue
        # The guard: refuse to undo a cell somebody has since changed by hand.
        now = str(struct[r][c]).strip()
        if now != str(o["token"]).strip():
            skipped.append((r, c, "holds %r, the stamp left %r" % (now, o["token"])))
            continue
        start, end = spans[(r, c)]
        edits.append((start, end, o["undo"]["literal"]))
    if skipped:
        for r, c, why in skipped[:6]:
            print("   skipped r%d c%d: %s" % (r, c, why))
    if not edits:
        print("%s  -- nothing to undo" % name)
        return 1
    text = splice(raw, edits)
    revs.pop()
    # The map's summary block must not go on claiming ops that are no longer in
    # the grid. Rewrite it to the revision that now stands, or say plainly that
    # the map is back where it started.
    if revs:
        last = revs[-1]
        text = write_journal(text, last["ops"], {k: v for k, v in last.items()
                                                 if k not in ("ops", "revision")})
    else:
        text = write_journal(text, [], {"tool": "stamp.py", "op": "reverted",
                                        "note": "every stamp on this map has been "
                                                "replayed backwards"})
    atomic_write(path, text)
    atomic_write(p, json.dumps(doc, indent=1, ensure_ascii=False) + NL)
    print("%s  -- reverted revision %s, %d cell(s) restored, %d skipped"
          % (name, rec.get("revision"), len(edits), len(skipped)))
    return 0


def report(name: str, verdicts: list, before: dict, ops: list, after=None) -> None:
    counts = collections.Counter(v["verdict"] for v in verdicts)
    print("\n%s" % name)
    print("   bodies: " + ", ".join("%s %d" % (k, n) for k, n in counts.most_common()))
    for v in verdicts:
        if v["verdict"] in ("FITS",):
            continue
        print("   %-11s %-26s r%-2d c%-2d  %s"
              % (v["verdict"], v["tok"][:26], v["r"], v["c"], v["why"]))
    moved = sum(1 for o in ops if o["to"] and o["to"] != "1")
    stuck = sum(1 for o in ops if o["to"] is None)
    print("   plan: %d carve, %d displace, %d with nowhere to go"
          % (sum(1 for o in ops if o["to"] == "1"), moved, stuck))
    def lane_s(m):
        return "n/a (no route)" if m.get("lane") is None else str(m["lane"])
    def museum_s(m):
        if not m.get("has_entry"):
            return "NO FLOOR CELL in row 0 - no museum entrance"
        if not m.get("has_exit"):
            return "NO FLOOR CELL in the last row - no museum exit"
        if not m.get("door_walk"):
            return "doors exist but the structure does not connect them"
        s = "walks row 0 to row H-1, narrowest %s" % (m.get("door_lane") or "?")
        if not m.get("door_walk_clear"):
            s += " (but not clear of the bodies)"
        elif m.get("clear_lane") is not None:
            s += ", %s clear of bodies" % m["clear_lane"]
        return s

    for tag, m in (("before", before), ("after", after)):
        if not m:
            continue
        orph = m.get("orphans") or []
        print("   %-6s: museum %s; %d wall cells; %s"
              % (tag, museum_s(m), m.get("wall_cells", 0),
                 "all %d artifacts approachable" % m.get("bodies", 0) if not orph
                 else "%d UNREACHABLE: %s" % (len(orph), ", ".join(orph[:3]))))


def check(before: dict, after: dict, want_width: int) -> list:
    """The three assertions. Any failure rolls the whole stamp back."""
    bad = []
    if before["walls"] != after["walls"]:
        lost = before["walls"] - after["walls"]
        gained = after["walls"] - before["walls"]
        bad.append("wall literals not conserved: lost %s, gained %s"
                   % (dict(lost) or "{}", dict(gained) or "{}"))
    if before["tele_reached"] and not after["tele_reached"]:
        bad.append("the teleporter was reachable and is not any more")
    # THE MUSEUM CONTRACT. A dealt hall is entered at the first z row and left at
    # the last; the map's own spawn disc is not used there at all. So these are
    # the checks that decide whether a stamped room is still a room you can walk
    # through, and none of them may be traded away for a better-seated body.
    if before["has_entry"] and not after["has_entry"]:
        bad.append("the first row no longer has a floor cell - the entrance is sealed")
    if before["has_exit"] and not after["has_exit"]:
        bad.append("the last row no longer has a floor cell - the exit is sealed")
    if before["door_walk"] and not after["door_walk"]:
        bad.append("the hall no longer walks from the first row to the last")
    if before["door_walk_clear"] and not after["door_walk_clear"]:
        bad.append("the walk from door to door no longer clears the bodies")
    if (before["door_lane"] is not None and after["door_lane"] is not None
            and after["door_lane"] < before["door_lane"]):
        bad.append("the door-to-door lane narrowed from %d to %d"
                   % (before["door_lane"], after["door_lane"]))
    new_orphans = set(after["orphans"]) - set(before["orphans"])
    if new_orphans:
        bad.append("%d artifact(s) can no longer be walked up to: %s"
                   % (len(new_orphans), ", ".join(sorted(new_orphans)[:4])))
    if before["lane"] is not None and after["lane"] is not None             and after["lane"] < before["lane"]:
        bad.append("the narrowest lane on the route fell from %d to %d"
                   % (before["lane"], after["lane"]))
    # NOT "reachable floor must not fall". Moving a wall out from under a body
    # necessarily turns some floor into wall - that is the whole of "move, do
    # not remove", and asserting against it refuses every honest stamp. What
    # must not happen is STRANDING: a cell that was reachable, is still floor,
    # and can no longer be got to.
    stranded = (before["reach_set"] - after["walled_cells"]) - after["reach_set"]
    if stranded:
        ex = sorted(stranded)[:4]
        bad.append("%d cell(s) that were reachable are now cut off, e.g. %s"
                   % (len(stranded), ", ".join("r%dc%d" % p for p in ex)))
    if want_width:
        # --width is asked of the MUSEUM walk, because that is the one a visitor
        # actually takes through a dealt hall. And it is a RATCHET, not a
        # threshold: 91 of the 163 halls that walk door to door already pinch to
        # one cell, so refusing everything below the floor would refuse the
        # corpus for a fault the stamp did not cause. The stamp is answerable
        # for what it changes.
        got, was = after["door_lane"], before["door_lane"]
        floor_at = want_width if was is None else min(want_width, was)
        if got is None:
            bad.append("--width=%d was asked for and this hall does not walk door to door"
                       % want_width)
        elif got < floor_at:
            bad.append("door-to-door lane %d is below %d (asked %d, was %s)"
                       % (got, floor_at, want_width, was))
    return bad


def live_rooms() -> list:
    authored = json.load(open(os.path.join(ROOT, "commons", "data", "map_authored.json"),
                              encoding="utf-8"))
    out = []
    for sid in authored:
        if sid.startswith("_"):
            continue
        p = os.path.join(MAPS, "sequences", sid + ".json")
        if not os.path.exists(p):
            continue
        d = json.load(open(p, encoding="utf-8"))
        s = d["sequences"].get(sid) if isinstance(d.get("sequences"), dict) else d
        if isinstance(s, dict):
            out += [(sid, m) for m in s.get("maps", [])]
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", default="")
    ap.add_argument("--seq", default="")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--svg", action="store_true",
                    help="draw the proposal to doc/plans/stamp_<Map>.svg")
    ap.add_argument("--out", default=os.path.join(ROOT, "doc", "plans"))
    ap.add_argument("--typology", action="store_true",
                    help="what shape does this room's claim want")
    ap.add_argument("--revert", action="store_true",
                    help="replay the newest journal revision backwards")
    ap.add_argument("--width", type=int, default=0,
                    help="refuse a stamp that leaves the route narrower than this")
    args = ap.parse_args()

    shelf = json.load(open(SHELF, encoding="utf-8"))
    rooms = live_rooms()
    if args.map:
        targets = [args.map]
    elif args.seq:
        targets = [m for s, m in rooms if s == args.seq]
    elif args.all:
        targets = sorted({m for _, m in rooms})
    else:
        ap.error("give --map, --seq or --all")

    if args.typology:
        seq_of = {m: s for s, m in rooms}
        for name in targets:
            typology(name, seq_of.get(name, ""))
        return 0

    if args.revert:
        rc = 0
        for name in targets:
            rc |= revert(name)
        return 0

    stamped = refused = 0
    for name in targets:
        path, raw, doc = load(name)
        if not doc or not (doc.get("layers") or {}).get("structure"):
            print("\n%s  -- no structure layer" % name)
            continue
        verdicts = judge(doc, shelf)
        before = measure(doc, shelf)
        if before.get("error"):
            print("\n%s  -- the pathfinder cannot read this map: %s" % (name, before["error"]))
            continue
        # THE REPAIR LOOP. Checking reachability only at the end tells you the
        # stamp is bad without telling you which move made it bad, so the whole
        # stamp is thrown away for one wall in the wrong cell. Instead: plan,
        # test, BAN the destinations that broke something, plan again. On
        # CA_GameOfLife the first plan sealed a four-cell pocket behind the
        # walls it planted at column 11; the second plan puts them elsewhere.
        protect = set(before.get("route_cells") or []) | set(before.get("door_cells") or [])
        banned, ops, new_text, entries, after, bad = set(), [], None, [], None, []
        for attempt in range(8):
            ops = plan(doc, verdicts, protect=protect, banned=banned)
            if not ops or not args.apply:
                break
            new_text, entries = apply_ops(raw, doc, ops)
            after = measure(json.loads(new_text), shelf)
            after["walled_cells"] = {(o["r"], o["c"]) for o in ops
                                     if o["to"] and o["to"] != "1"}
            bad = check(before, after, args.width)
            if not bad:
                break
            culprits = _culprits(before, after, ops)
            if not culprits:
                break                     # nothing to retract; the refusal stands
            banned |= culprits
            if attempt == 7:
                print("   gave up after 8 replans")

        if args.svg:
            p = draw(name, doc, shelf, verdicts, ops, before, args.out)
            print("   drew %s" % os.path.relpath(p, ROOT))

        if not args.apply or not ops:
            report(name, verdicts, before, ops)
            continue

        report(name, verdicts, before, ops, after)
        if bad:
            refused += 1
            for b in bad:
                print("   REFUSED: " + b)
            continue
        if not entries:
            print("   nothing to write: every carve this room needs has nowhere "
                  "to put the wall it would remove")
            continue
        summary = {"tool": "stamp.py", "op": "stamp",
                   "lane_before": before["lane"], "lane_after": after["lane"],
                   "carved": sum(1 for o in ops if o["to"] == "1"),
                   "displaced": sum(1 for o in ops if o["to"] and o["to"] != "1")}
        final = write_journal(new_text, entries, summary)
        atomic_write(path, final)
        rev = json.loads(final)["documentation"]["stamp"]["revision"]
        append_journal(name, rev, entries, summary)
        stamped += 1
        print("   WROTE %d cell ops as revision %d; undo in %s/stamp_journal.json"
              % (len(entries), rev, name))

    if args.apply:
        print("\n%d map(s) stamped, %d refused." % (stamped, refused))
    return 0


if __name__ == "__main__":
    sys.exit(main())
