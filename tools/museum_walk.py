#!/usr/bin/env python3
"""museum_walk.py — the ONE implementation of how a visitor crosses a hall.

2026-09-03. Extracted from tools/stamp.py after a review found the traversal
written twice and computed differently in each place:

  * tools/stamp.py grew `walk_doors`, which is the museum's own rule: in at the
    FIRST z row, out at the LAST. That is how a dealt hall is entered and left;
    the map's own spawn disc is not used there at all.
  * tools/walk_evaluator.py models spawn-to-teleporter, which is a different
    journey, and separately loads the placement it is given and then DISCARDS
    it in favour of scoring hypothetical strategies.

Two implementations of one rule drift. That is the /long-museum incident in
CLAUDE.md, and it cost a session: a Python re-derivation of the museum's own
geometry gave every hall h20 where the engine builds h23, and the --check was
green because it compared the strip against the wrong thing. So this module is
the home, and both tools import from it.

WHAT IS IN HERE, and what each is for:

    heights(struct)              every cell's height, via map_pathfinder's
                                 parser - the one Python reader faithful to
                                 the engine about "w"
    museum_doors(struct)         the entry and exit cells: floor in row 0,
                                 floor in row H-1
    walk_doors(g, free, e, x)    the shortest walk between them, using
                                 MapGraph.neighbors as the step relation so
                                 the rule is never restated
    disjoint_ways(struct)        Menger: how many vertex-disjoint routes, and
                                 which cells limit them
    lane_width_along(...)        the narrowest point on a route, by EROSION -
                                 dilation cannot prove a width

A NOTE ON WHAT THIS MODULE CANNOT TELL YOU. Every function here reads the MAP.
The museum builds a dealt hall through its own copies of the grid's rules and
those copies drift: _widen_doors opens every one-cell door, _authored_passages
carves rows 0 and H-1 when they are sealed, and UTIL_ALLOWED is six codes so
sub, an and t are dropped entirely. So a number from here is a fact about the
map and is not known to hold in the museum for the 152 dealt halls. Retiring
that doubt needs a parity probe per utility code, which does not exist yet
beyond commons/testing/probe_transport_cube_parity.gd.
"""
from __future__ import annotations

import collections
import os
import sys
from collections import deque

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import map_pathfinder as mp  # noqa: E402

#: A cell a body can stand on. parse_height gives 0 for void and 99 for "w";
#: anything above 1 is a step the player cannot climb without a ramp, which is
#: what makes it a wall in practice rather than by name.
FLOOR_H = 1


def heights(struct: list) -> dict:
    return {(r, c): mp.parse_height(struct[r][c])
            for r in range(len(struct)) for c in range(len(struct[r]))}


def museum_doors(struct: list) -> tuple:
    """The museum's own traversal: IN at the first z row, OUT at the last.

    Palle, 2026-09-03: "that is in the museum, so in the first z row and out at
    last, where there has to be a one, right?" Right, and it is a different
    question from spawn-to-teleporter. Measured over the 185 live halls: 180
    have a floor cell in the first row, 176 in the last, 163 walk end to end.
    """
    H = len(struct)
    entry = [(0, c) for c, v in enumerate(struct[0]) if mp.parse_height(v) == FLOOR_H]
    exits = {(H - 1, c) for c, v in enumerate(struct[H - 1])
             if mp.parse_height(v) == FLOOR_H}
    return entry, exits


def walk_doors(g, free: set, entry: list, exits: set) -> list:
    """Shortest walk from any first-row door to any last-row door, over cells no
    body is standing in. MapGraph.neighbors is the step relation, unrestated."""
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


def walk_between(g, free: set, target) -> list:
    """Shortest path from the map's own spawn to a target, over free cells.

    Kept beside walk_doors rather than merged with it, because they answer
    different questions and merging them is how the two got confused: this is
    the SPAWN journey a player takes in the standalone map, walk_doors is the
    journey a visitor takes through a dealt hall.
    """
    start = getattr(g, "spawn", None)
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


def lane_width_along(route: list, free: set, hmap: dict, cap: int = 4):
    """The narrowest point on a route: the largest k for which some k x k block
    of same-height free cells covers the cell.

    EROSION, not dilation. Dilating a path by a 3x3 kernel and intersecting with
    the walkable set reports three even where the path threads a one-cell gap,
    because every cell it keeps was already walkable. This asks the opposite
    question and can fail.

    Spawn and exit cells are skipped: a spawn routinely sits inside a body's
    footprint and a teleporter stands on its own pad, and including them made
    the reading 0 on halls with a perfectly good corridor.
    """
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


def disjoint_ways(struct: list) -> tuple:
    """Menger: the number of vertex-disjoint routes from the first z row to the
    last equals the minimum vertex cut. -> (ways, cut_cells, verdict).

    Split every floor cell into in -> out with capacity one; that is the trick
    that makes a cut fall on a CELL rather than on a gap between two.
    Edmonds-Karp suffices because the flow is bounded by the doorway width.
    Stdlib only: no tool in this repo imports networkx or scipy.

    A MINIMUM CUT IS NOT UNIQUE, so the verdict never depends on which one was
    found. Checked against networkx.minimum_cut on eleven halls: the flow VALUE
    agreed 11 of 11, the cut CELLS agreed on none. The hall is "door" limited
    when it admits as many ways as its narrower doorway allows and "interior"
    when it admits fewer; the cut cells are returned as ONE place the pinch can
    be relieved, not as the answer.
    """
    H = len(struct)
    floor = {(r, c) for r in range(H) for c in range(len(struct[r]))
             if mp.parse_height(struct[r][c]) == FLOOR_H}
    entry = [p for p in floor if p[0] == 0]
    exits = [p for p in floor if p[0] == H - 1]
    if not entry or not exits:
        return 0, [], "no door"

    SRC, SNK = ("SRC",), ("SNK",)
    cap, adj = {}, collections.defaultdict(set)

    def edge(u, v, c):
        cap[(u, v)] = cap.get((u, v), 0) + c
        cap.setdefault((v, u), 0)
        adj[u].add(v)
        adj[v].add(u)

    BIG = 1 << 20
    for p in floor:
        edge(("i", p), ("o", p), 1)
        for n in ((p[0] - 1, p[1]), (p[0] + 1, p[1]),
                  (p[0], p[1] - 1), (p[0], p[1] + 1)):
            if n in floor:
                edge(("o", p), ("i", n), BIG)
    for p in entry:
        edge(SRC, ("i", p), BIG)
    for p in exits:
        edge(("o", p), SNK, BIG)

    ways = 0
    while True:
        prev = {SRC: None}
        q = deque([SRC])
        while q and SNK not in prev:
            u = q.popleft()
            for v in adj[u]:
                if v not in prev and cap.get((u, v), 0) > 0:
                    prev[v] = u
                    q.append(v)
        if SNK not in prev:
            break
        path, v = [], SNK
        while v != SRC:
            u = prev[v]
            path.append((u, v))
            v = u
        push = min(cap[e] for e in path)
        for (u, v) in path:
            cap[(u, v)] -= push
            cap[(v, u)] = cap.get((v, u), 0) + push
        ways += push

    seen = {SRC}
    q = deque([SRC])
    while q:
        u = q.popleft()
        for v in adj[u]:
            if v not in seen and cap.get((u, v), 0) > 0:
                seen.add(v)
                q.append(v)
    cut = sorted(p for p in floor if ("i", p) in seen and ("o", p) not in seen)
    doors = min(len(entry), len(exits))
    return ways, cut, ("door" if ways >= doors else "interior")


def evaluate(doc: dict, body_cells: set = frozenset()) -> dict:
    """Everything above, for one map, in one call. The shared entry point.

    body_cells lets a caller say which cells are occupied; pass the empty set
    for the STRUCTURAL walk, which is the museum's own contract, and the real
    footprints for the CLEAR walk, which is stricter and is a caution rather
    than a verdict.
    """
    struct = doc["layers"]["structure"]
    hmap = heights(struct)
    floor_all = {p for p, h in hmap.items() if h == FLOOR_H}
    free = floor_all - set(body_cells)
    entry, exits = museum_doors(struct)
    try:
        g = mp.MapGraph(doc)
    except Exception as exc:
        return {"error": str(exc)[:120]}
    route = walk_doors(g, free, entry, exits)
    ways, cut, where = disjoint_ways(struct)
    return {
        "has_entry": bool(entry), "has_exit": bool(exits),
        "doors": min(len(entry), len(exits)),
        "walks": bool(route), "route": route,
        "lane": lane_width_along(route, free, hmap),
        "ways": ways, "cut": cut, "cut_where": where,
        "floor": len(floor_all), "free": len(free),
    }


if __name__ == "__main__":
    import argparse
    import json

    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("maps", nargs="*")
    a = ap.parse_args()
    for name in a.maps:
        p = os.path.join(ROOT, "commons", "maps", name, "map_data.json")
        if not os.path.exists(p):
            print("%-34s no such map" % name[:34])
            continue
        r = evaluate(json.load(open(p, encoding="utf-8")))
        if r.get("error"):
            print("%-34s %s" % (name[:34], r["error"]))
            continue
        print("%-34s %d way(s) vs %d door cells, %s; walks %s, lane %s"
              % (name[:34], r["ways"], r["doors"], r["cut_where"],
                 "yes" if r["walks"] else "NO", r["lane"]))
