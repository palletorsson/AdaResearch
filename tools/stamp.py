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
# THE TRAVERSAL LIVES IN ONE PLACE. These were written here first, and a review
# then found the same rule written differently in tools/walk_evaluator.py. Two
# implementations of one rule drift - that is the /long-museum incident, which
# cost a session. tools/museum_walk.py is the home; this imports from it.
from museum_walk import (  # noqa: E402
    FLOOR_H, heights, museum_doors, walk_doors, lane_width_along, disjoint_ways,
    walk_between as _walk_free,
)

SHELF = os.path.join(ROOT, "doc", "shelf.json")
MAPS = os.path.join(ROOT, "commons", "maps")


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


def scale_of(raw: str) -> float:
    """The uniform scale a placement applies, from either spelling."""
    head = raw.split("#")[0].split(":")
    if len(head) >= 4:
        try:
            v = float(head[3])
            if v > 0.0:
                return v
        except ValueError:
            pass
    for part in raw.split("#")[1:]:
        if part.startswith("scale:"):
            try:
                v = float(part.split(":", 1)[1].split("#")[0])
                if v > 0.0:
                    return v
            except ValueError:
                pass
    return 1.0


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
    # A PLACEMENT MAY SCALE THE BODY, and ignoring that reports a footprint the
    # room does not contain. Two spellings: the fourth part of a token
    # (name:rot:y:scale) and the config key #scale:S. free_vector went into
    # Act5 at 0.7 because nothing fits there at 1.0, and this function called it
    # twelve cells deep in a wall until it learned to read the number.
    sc = scale_of(raw)
    if sc != 1.0:
        w, d = w * sc, d * sc
        dx, dz = dx * sc, dz * sc
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


# -- how many ways through, and which cells decide it ------------------------
# The lane measure erodes ONE route and reports its worst point, which cannot
# tell a hall that is as wide as its own doorway - the museum's 3-cell
# convention, and correct - from a hall that chokes to a single cell in the
# middle, which is a fault. Both read as "lane 1".
#
# Menger's theorem answers the exact question instead: the number of
# VERTEX-DISJOINT routes from the first z row to the last equals the minimum
# vertex cut. So the same computation counts the ways AND names the cells that
# limit them, which turns a complaint into an instruction.
#
# Split every floor cell into in -> out with capacity one; that is what makes
# the cut fall on a CELL rather than on a gap between two. Edmonds-Karp is
# ample here: the flow value is bounded by the doorway width, so it terminates
# in a handful of augmentations on any real hall. Stdlib only, deliberately -
# no tool in this repo imports networkx or scipy and stamp.py is not going to
# be the first.







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
    ways, cut, cut_where = disjoint_ways(struct)
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
        "ways": ways,
        "cut": cut,
        "cut_where": cut_where,
        "doors": min(len(entry), len(exits)),
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

# -- the displacement is an ASSIGNMENT problem -------------------------------
# Every carved wall needs a destination and no two may share one. That is the
# textbook assignment problem, and the tool was solving it GREEDILY: bodies in
# size order, each wall in turn grabbing the best cell still free. Greedy is
# order-dependent, which is why the repair loop had to exist, and why 44 wall
# cells across six forces halls ended up with "nowhere to go" - not because the
# room was full, but because earlier walls had taken the cells they needed.
#
# Hungarian solves the whole thing at once and optimally, in O(n^3). This is the
# shortest-augmenting-path formulation, stdlib, for the same reason the max-flow
# is stdlib: no tool in this repo imports scipy and stamp.py is not going to be
# the first. It is cross-checked against scipy.optimize.linear_sum_assignment
# by tools/test_stamp_hungarian.py wherever scipy happens to be installed.

def hungarian(cost: list) -> list:
    """Min-cost assignment over a rectangular matrix. -> [(row, col), ...].

    Rows are the things that must be placed, columns the places. Requires
    rows <= cols; the caller pads. Cost may contain INF for a forbidden pair -
    a pairing that keeps one is dropped from the result rather than returned,
    because assigning a wall to an illegal cell is worse than not placing it.
    """
    n, m = len(cost), len(cost[0]) if cost else 0
    if not n or n > m:
        return []
    INF = float("inf")
    u = [0.0] * (n + 1)
    v = [0.0] * (m + 1)
    p = [0] * (m + 1)          # p[j] = row assigned to column j
    way = [0] * (m + 1)
    for i in range(1, n + 1):
        p[0] = i
        j0 = 0
        minv = [INF] * (m + 1)
        used = [False] * (m + 1)
        while True:
            used[j0] = True
            i0, delta, j1 = p[j0], INF, -1
            for j in range(1, m + 1):
                if used[j]:
                    continue
                cur = cost[i0 - 1][j - 1] - u[i0] - v[j]
                if cur < minv[j]:
                    minv[j], way[j] = cur, j0
                if minv[j] < delta:
                    delta, j1 = minv[j], j
            if j1 < 0:
                break                      # no column left: leave i unassigned
            for j in range(m + 1):
                if used[j]:
                    u[p[j]] += delta
                    v[j] -= delta
                else:
                    minv[j] -= delta
            j0 = j1
            if p[j0] == 0:
                break
        if j1 < 0:
            continue
        while j0:
            j1 = way[j0]
            p[j0] = p[j1]
            j0 = j1
    return [(p[j] - 1, j - 1) for j in range(1, m + 1)
            if p[j] and cost[p[j] - 1][j - 1] < INF]


def placement_cost(src, dest, hmap, cut, protect) -> float:
    """What it costs to put the wall carved at src into dest.

    Distance, less three cells per wall neighbour the destination already has -
    filling a notch beats making an island, and three was measured: at one the
    walls scatter, at five they pile into the nearest corner. A destination the
    hall cannot spare is not merely expensive, it is forbidden.
    """
    if dest in protect or dest in cut:
        return float("inf")
    r, c = dest
    touching = sum(1 for n in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1))
                   if hmap.get(n, 0) > FLOOR_H)
    if not touching:
        return float("inf")
    return abs(r - src[0]) + abs(c - src[1]) - 3.0 * touching


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


def plan(doc: dict, verdicts: list, protect=frozenset(), banned=frozenset(),
         cut=frozenset()) -> list:
    """-> [{r, c, to, from, because, why}] - ordinary cell sets, nothing exotic.

    Two passes. First decide WHICH cells must be carved, which is per-body and
    settled by each body's wall_backing. Then place every carved wall at once,
    by min-cost assignment, because deciding them one at a time is what left 44
    of them homeless in a museum with plenty of room.
    """
    struct = doc["layers"]["structure"]
    hmap = heights(struct)
    H = len(struct)
    W = max(len(r) for r in struct)

    body_cells = set()
    for v in verdicts:
        body_cells |= set(v.get("cells") or [])

    def lit_of(p):
        return str(struct[p[0]][p[1]]).strip()

    # ---- pass 1: which cells does a body need cleared? --------------------
    ops, carve, done = [], [], set()
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
            # museum joins this hall to its neighbours, so their geometry
            # belongs to the crossing and not to the room.
            if p[0] in (0, H - 1):
                ops.append({"r": p[0], "c": p[1], "to": None, "lit": lit_of(p),
                            "because": v["tok"],
                            "why": "in the doorway row, which is the museum seam - left alone"})
                continue
            carve.append((p, v["tok"]))

    if not carve:
        return ops

    # ---- pass 2: where do all those walls go? one assignment --------------
    forbidden = set(protect) | set(banned) | body_cells | set(done)
    dests = [q for q in hmap
             if hmap[q] == FLOOR_H and q not in forbidden
             and q[0] not in (0, H - 1)]
    cost = [[placement_cost(p, q, hmap, cut, forbidden) for q in dests]
            for (p, _tok) in carve]
    # Hungarian needs at least as many columns as rows; when there are fewer
    # legal destinations than walls, some walls simply have nowhere to go and
    # saying so is the honest output.
    pairs = dict(hungarian(cost)) if dests and len(carve) <= len(dests) else {}
    if not pairs and dests and len(carve) > len(dests):
        pairs = dict(hungarian(cost[:len(dests)]))

    for i, (p, tok) in enumerate(carve):
        j = pairs.get(i)
        if j is None or cost[i][j] == float("inf"):
            ops.append({"r": p[0], "c": p[1], "to": None, "lit": lit_of(p),
                        "because": tok,
                        "why": "nowhere to put the wall this carve removes"})
            continue
        dest = dests[j]
        ops.append({"r": p[0], "c": p[1], "to": "1", "lit": lit_of(p),
                    "because": tok, "why": "carved so %s has its floor" % tok})
        ops.append({"r": dest[0], "c": dest[1], "to": lit_of(p), "lit": lit_of(dest),
                    "because": tok,
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
    if after["ways"] < before["ways"]:
        near = set()
        for (r, c) in after["cut"]:
            for n in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1), (r, c)):
                if n in planted:
                    near.add(n)
        if near:
            return near
        return planted
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

    # ---- the minimum cut: the cells the hall cannot spare -----------------
    # Drawn last so it sits over everything, because it is the constraint the
    # rest of the drawing has to respect. A cut cell is not a fault in itself:
    # if the hall admits as many ways as its doorway is wide, the doorway is
    # simply the limit and the cut lands there. It is a fault when the count is
    # lower, which is the INTERIOR PINCH case, and then this is the cell to
    # widen.
    cut = before.get("cut") or []
    pinched = before.get("cut_where") == "interior"
    cutcol = C_RED if pinched else C_BLUE
    for (r, c) in cut:
        x, y = ox + c * CELL, oy + r * CELL
        o.append('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="none" '
                 'stroke="%s" stroke-width="2.6" stroke-dasharray="2 2"/>'
                 % (x + 1.5, y + 1.5, CELL - 3, CELL - 3, cutcol))
        o.append('<circle cx="%.1f" cy="%.1f" r="3.4" fill="%s"/>'
                 % (x + CELL / 2, y + CELL / 2, cutcol))

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
        (cutcol, "the minimum cut",
         ("%d cell(s) - the hall admits %d way(s) through against %d door cells, so this "
          "is an INTERIOR PINCH and these are where to widen it"
          if pinched else
          "%d cell(s) - the hall admits %d way(s) through against %d door cells, so it is "
          "as wide as its own doorway")
         % (len(cut), before.get("ways", 0), before.get("doors", 0))),
    ]
    for i, (col, label, note) in enumerate(rows):
        y = ly + 18 + i * 15
        o.append('<rect x="%d" y="%d" width="10" height="10" fill="%s" fill-opacity="0.3" '
                 'stroke="%s"/>' % (ox, y - 8, col, col))
        o.append('<text x="%d" y="%d" font-size="10" fill="%s" font-weight="600">%s</text>'
                 % (ox + 16, y, C_INK, label))
        o.append('<text x="%d" y="%d" font-size="9.5" fill="#5b6472">%s</text>'
                 % (ox + 118, y, esc(note)))
    y = ly + 18 + len(rows) * 15 + 12
    o.append('<text x="%d" y="%d" font-size="10" fill="%s">bodies: %s</text>'
             % (ox, y, C_INK, esc(", ".join("%s %d" % (k, n) for k, n in counts.most_common()))))
    o.append('<text x="%d" y="%d" font-size="10" fill="#5b6472">walls %d before, %d after — '
             'the multiset is conserved, a moved wall keeps its own literal</text>'
             % (ox, y + 15, before.get("wall_cells", 0), before.get("wall_cells", 0)))
    o.append('<text x="%d" y="%d" font-size="10" fill="#5b6472">museum traversal: in at row 0, '
             'out at row %d - %s</text>'
             % (ox, y + 30, H - 1,
                "walks" if before.get("door_walk") else "DOES NOT WALK"))
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
    # TWO reasons a carve does not happen, and collapsing them hid the answer to
    # whether the Hungarian pass helped: 44 forces cells were reported as having
    # "nowhere to go" when every one of them was a doorway cell the tool refuses
    # to touch on purpose.
    seam = sum(1 for o in ops if o["to"] is None and "seam" in o.get("why", ""))
    stuck = sum(1 for o in ops if o["to"] is None) - seam
    print("   plan: %d carve, %d displace, %d with nowhere to go, %d in the seam"
          % (sum(1 for o in ops if o["to"] == "1"), moved, stuck, seam))
    def lane_s(m):
        return "n/a (no route)" if m.get("lane") is None else str(m["lane"])
    def museum_s(m):
        if not m.get("has_entry"):
            return "NO FLOOR CELL in row 0 - no museum entrance"
        if not m.get("has_exit"):
            return "NO FLOOR CELL in the last row - no museum exit"
        if not m.get("door_walk"):
            return "doors exist but the structure does not connect them"
        s = "%d way(s) through vs %d door cells - %s%s" % (
            m.get("ways", 0), m.get("doors", 0),
            ("limited by its doorways" if m.get("cut_where") == "door"
             else "INTERIOR PINCH"),
            "" if m.get("cut_where") == "door"
            else " at " + (", ".join("r%dc%d" % p for p in (m.get("cut") or [])[:3]) or "?"))
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
    # MENGER. The count of vertex-disjoint routes is the honest width of a hall,
    # and unlike the lane it cannot be argued with: it is the size of the
    # minimum cut. A stamp may not reduce it.
    if after["ways"] < before["ways"]:
        bad.append("the hall admitted %d disjoint way(s) through and now admits %d; "
                   "the cut is %s"
                   % (before["ways"], after["ways"],
                      ", ".join("r%dc%d" % p for p in after["cut"][:5]) or "empty"))
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
        # The min cut IS the list of cells the hall cannot spare. Protecting
        # them stops a narrowing happening rather than detecting it afterwards,
        # which is the difference between a plan that works first time and a
        # plan that has to be retracted.
        protect = (set(before.get("route_cells") or [])
                   | set(before.get("door_cells") or [])
                   | set(before.get("cut") or []))
        banned, ops, new_text, entries, after, bad = set(), [], None, [], None, []
        for attempt in range(8):
            ops = plan(doc, verdicts, protect=protect, banned=banned,
                       cut=set(before.get("cut") or []))
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
