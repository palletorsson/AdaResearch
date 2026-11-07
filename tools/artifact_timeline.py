#!/usr/bin/env python3
"""The artifact timeline: every main artifact numbered once, with a place in the Void tower.

Palle, 2026-11-07: "Lets give every main artifact a place in the annotated path, the artifact
timeline and in space ... remove some artifacts that do not add to the path ... add new ones and
move artifacts in the timeline. All artifacts in the void tower should be accounted for ... the
artifacts that are part of the environment, recurring to create space, ... on a separate track
in the timeline but smaller. Number the artifact by the timeline."

AUTHORED (edit here or in /artifact-timeline):  commons/data/artifact_timeline.json
    main         the numbered track, in order. Number = position + 1. Each row:
                 {"key", "floor"  (the storey the timeline puts it on), "note"  (optional)}
    environment  the recurring works that make space (barriers, lights, screens, plinths, props).
                 Not numbered; shown smaller. Props are keyed "prop:<kind>".
    removed      taken off the path: {"key", "reason", "at"}. The tower is NOT edited by this
                 tool; a removed work still standing in the tower is reported until it is taken out.

DERIVED (rebuilt, never edit):  ada_run/artifact_timeline_view.json  - what the page reads.
    For each row: where it stands in the tower (floor, placement id, the nearest stop of that
    floor's walking route and how far), whether it is on the construction path
    (commons/data/construction_path.json) with that path's annotation, registry title/scene.
    Plus: tower artifacts filed nowhere (UNFILED), and the catalogue to add from.

    python tools/artifact_timeline.py seed [--force]   # first version from the tower as it stands
    python tools/artifact_timeline.py view             # rebuild the derived view
    python tools/artifact_timeline.py check [--markdown]
        exit code = unfiled tower works + main works with no place in the tower
                    + removed works still standing (the three accounting failures)
"""
from __future__ import annotations

import json
import math
import re
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUTHORED = ROOT / "commons/data/artifact_timeline.json"
VIEW = ROOT / "ada_run/artifact_timeline_view.json"
ROOMS = ROOT / "commons/void/rooms.json"
CATALOG = ROOT / "commons/void/catalog.json"
CPATH = ROOT / "commons/data/construction_path.json"
INDEX = ROOT / "doc/artifact-timeline/index.json"
REGISTRY = ROOT / "commons/artifacts/registry"

OFF_ROUTE_M = 5.0        # further than this from every stop of its floor's route = off the route
RECURS_ON_FLOORS = 5     # standing on this many floors or more = a recurring environment work
# the LAST word of a key that names furniture of the building ("traffic_cone", "pyramid_blocker");
# only the last word: "mass_spring_bench" and "iso_cave_console" are exhibits
ENV_LAST_WORDS = {"barrier", "barricade", "cone", "sconce", "blocker", "tarp", "crate", "pallet", "fence",
                  "railing", "vent", "glassrack"}
ENV_KEYS = {"city_bench", "street_sign"}
ENV_CATEGORIES = {"utilities", "museum_architecture", "architecture", "furniture", "signage", "lighting"}


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def read(p: Path):
    return json.loads(p.read_text(encoding="utf-8-sig"))


def registry() -> dict:
    """lookup name -> {title, scene, category, file}; registry files first, the Void catalogue fills gaps"""
    out: dict = {}
    for p in sorted(REGISTRY.glob("*.json")):
        try:
            data = read(p)
        except (ValueError, UnicodeError):
            continue
        arts = data.get("artifacts", data) if isinstance(data, dict) else {}
        if not isinstance(arts, dict):
            continue
        for k, v in arts.items():
            if isinstance(v, dict) and k not in out:
                out[k] = {"title": v.get("name") or k, "scene": v.get("scene", ""), "category": v.get("category"),
                          "file": p.name, "description": v.get("description", "")}
    cat = read(CATALOG)
    for k, v in cat.get("artifacts", {}).items():
        if k not in out:
            out[k] = {"title": v.get("name") or k, "scene": v.get("scene", ""), "category": v.get("category"),
                      "file": "void/catalog.json", "description": v.get("description", "")}
    for k, v in cat.get("props", {}).items():
        out["prop:" + k] = {"title": v.get("label") or k, "scene": v.get("scene", ""), "category": v.get("group"),
                            "file": "void/catalog.json (prop)", "description": ""}
    return out


def tower() -> dict:
    """key -> list of placements {floor, map, id, position, route_stop, route_label, route_m, copy}"""
    rooms = read(ROOMS)
    out: dict = defaultdict(list)
    for floor, f in enumerate(rooms["floors"]):
        route = [r for r in (f.get("route") or []) if isinstance(r.get("position"), list) and len(r["position"]) >= 2]

        def stop(pos):
            if not route or not isinstance(pos, list) or len(pos) < 2:
                return None, "", None
            best = min(range(len(route)), key=lambda i: math.dist(route[i]["position"][:2], pos[:2]))
            return best, route[best].get("label", ""), round(math.dist(route[best]["position"][:2], pos[:2]), 2)

        rows = [(a, False) for a in f.get("artifacts", [])] + [(a, True) for a in f.get("copies", [])]
        rows += [({"artifact": "prop:" + p.get("kind", ""), "id": p.get("id"), "position": p.get("position")}, False)
                 for p in f.get("props", []) if p.get("kind")]
        for a, copy in rows:
            k = a.get("artifact")
            if not k:
                continue
            i, label, d = stop(a.get("position"))
            out[k].append({"floor": floor, "map": f.get("map", ""), "id": a.get("id"), "position": a.get("position"),
                           "route_stop": i, "route_label": label, "route_m": d, "copy": copy})
    return out


def floor_titles() -> list:
    return [{"floor": i, "map": f.get("map", ""), "title": f.get("title", "")} for i, f in enumerate(read(ROOMS)["floors"])]


def construction_path() -> dict:
    """artifact key -> {step, lane, why, adds, map, seq} for every artifact/void step of the construction path"""
    try:
        cp = read(CPATH)
    except (OSError, ValueError):
        return {}
    pos = {iid: n for n, iid in enumerate(cp.get("order", []))}
    out = {}
    for iid, it in cp.get("items", {}).items():
        if it.get("kind") in ("artifact", "void"):
            out[it["id"]] = {"step": pos.get(iid), "lane": it.get("lane"), "why": it.get("why") or "",
                             "adds": it.get("adds") or "", "map": it.get("map") or "", "seq": it.get("seq") or ""}
    return out


def environment_reason(key: str, places: list, reg: dict) -> str:
    if key.startswith("prop:"):
        return "a prop of the building"
    floors = {p["floor"] for p in places}
    if len(floors) >= RECURS_ON_FLOORS:
        return f"recurs on {len(floors)} floors"
    last = key.lower().split("_")[-1]
    if last in ENV_LAST_WORDS or key in ENV_KEYS:
        return f"names furniture ({last})"
    cat = (reg.get(key) or {}).get("category")
    if cat in ENV_CATEGORIES:
        return f"registry category {cat}"
    return ""


def _tour(keys: list, pos: dict, start: tuple) -> list:
    """an open walk through the points: nearest neighbour from `start`, then 2-opt until no swap shortens it"""
    left, order, here = list(keys), [], start
    while left:
        k = min(left, key=lambda k: (math.dist(pos[k], here), k))
        order.append(k); left.remove(k); here = pos[k]

    def length(o):
        return math.dist(start, pos[o[0]]) + sum(math.dist(pos[a], pos[b]) for a, b in zip(o, o[1:]))
    best, better = length(order), True
    while better:
        better = False
        for i in range(len(order) - 1):
            for j in range(i + 1, len(order)):
                cand = order[:i] + order[i:j + 1][::-1] + order[j + 1:]
                cl = length(cand)
                if cl < best - 1e-9:
                    order, best, better = cand, cl, True
    return order


def seed(force: bool) -> None:
    if AUTHORED.exists() and not force:
        sys.exit(f"{AUTHORED.relative_to(ROOT)} exists: it is authored now. Pass --force to start it again from the tower.")
    reg, tw = registry(), tower()
    main, env = [], []
    for key, places in tw.items():
        why = environment_reason(key, places, reg)
        first = min(places, key=lambda p: (p["floor"], p["route_stop"] if p["route_stop"] is not None else 999))
        sort = (first["floor"], first["route_stop"] if first["route_stop"] is not None else 999, key)
        if why:
            env.append((sort, {"key": key, "why": why}))
        else:
            main.append((sort, {"key": key, "floor": first["floor"]}))
    main = sorted(main, key=lambda x: x[0])
    # a floor with no hand-made route: number its works as a short walk from where the visitor lands (the arrival
    # shaft), not by name - the numbers become the walk drawn in the game (2026-11-07, "the number becomes the walk")
    rooms, frame = read(ROOMS), read(ROOT / "commons/void/layout.json")
    descent, shafts = frame.get("descent", {}), {s["name"]: s["x"] for s in frame["shafts"]}
    by_floor = defaultdict(list)
    for item in main:
        by_floor[item[1]["floor"]].append(item)
    ordered = []
    for f in sorted(by_floor):
        block = by_floor[f]
        if not rooms["floors"][f].get("route"):
            pos = {}
            for _, r in block:
                p = next((x for x in tw[r["key"]] if x["floor"] == f and isinstance(x.get("position"), list)), None)
                pos[r["key"]] = tuple(p["position"][:2]) if p else (0.0, 0.0)
            start = (shafts.get(str(descent.get("pad_shafts", {}).get(str(f), descent.get("pad_shaft", "B"))), 0.0), 0.0)
            keys = _tour([r["key"] for _, r in block], pos, start)
            row = {r["key"]: (k, r) for k, r in block}
            block = [row[k] for k in keys]
        ordered += block
    main = ordered
    doc = {
        "_doc": "AUTHORED - the artifact timeline (tools/artifact_timeline.py, /artifact-timeline). main = the numbered "
                "track in order (number = position + 1), each with the floor the timeline puts it on; environment = "
                "the recurring works that make space, shown smaller; removed = taken off the path, with the reason. "
                "Seeded from the tower: floor, then the nearest stop of that floor's hand-made route, or on a floor "
                "without one a short walk from the arrival shaft.",
        "version": 1, "seeded_at": now(), "edited_at": None,
        "main": [r for _, r in main],
        "environment": [r for _, r in sorted(env, key=lambda x: x[0])],
        "removed": [],
    }
    write_authored(doc)
    print(f"seeded {AUTHORED.relative_to(ROOT)}: main {len(doc['main'])}, environment {len(doc['environment'])}")


def write_authored(doc: dict) -> None:
    """compact rows: one entry per line, so a move is a one-line diff"""
    lines = ["{"]
    keys = list(doc)
    for n, k in enumerate(keys):
        end = "," if n < len(keys) - 1 else ""
        v = doc[k]
        if isinstance(v, list):
            if not v:
                lines.append(f'  {json.dumps(k)}: []{end}')
                continue
            lines.append(f'  {json.dumps(k)}: [')
            for i, row in enumerate(v):
                lines.append("    " + json.dumps(row, ensure_ascii=False) + ("," if i < len(v) - 1 else ""))
            lines.append(f"  ]{end}")
        else:
            lines.append(f"  {json.dumps(k)}: {json.dumps(v, ensure_ascii=False)}{end}")
    lines.append("}")
    AUTHORED.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")


def exports_count() -> dict:
    try:
        idx = read(INDEX)
    except (OSError, ValueError):
        return {}
    return {e["key"]: len(e.get("exports", [])) for e in idx.get("entries", [])}


# ---- the walk (Palle, 2026-11-07: "yes 1 and 3" - let the number become the walk; show the number in the game) ---
# DERIVED, tracked, read by the game (commons/void/floor_content.gd): commons/data/artifact_timeline_walk.json.
# Per floor, every main work numbered on that floor AND standing there, in number order, with a STAND point (where a
# visitor stands to meet it, on a free spot 1.2-2.6 m from it, nearest the previous stand) and its number caption.
# A floor whose rooms.json `route` is empty walks the numbers: an A* path on a 0.5 m grid joins the stands around
# shafts, columns, low walls, props and the other works' access squares. A floor with a hand-made route keeps it;
# it gets the numbers only. A stand the path cannot reach is listed in `unreached`.
WALK = ROOT / "commons/data/artifact_timeline_walk.json"
OCCUPANCY = ROOT / "commons/data/void_floor_occupancy.json"   # measured in the built tower: tools/measure_void_occupancy.py


def _floor_hash(record: dict) -> str:   # the same as tools/measure_void_occupancy.py floor_hash
    import hashlib
    return hashlib.sha1(json.dumps(record, sort_keys=True, ensure_ascii=False).encode("utf-8")).hexdigest()[:16]
GRID = 0.5
CLEAR = 0.3   # a walker's half-width around every obstacle


def _walk_obstacles(floor: dict, frame: dict, catalog: dict, v, measured: bool = True) -> list:
    rect = v.rect
    obs = [rect(s["x"], 0, frame["shaft_width"], frame["shaft_depth"]) for s in frame["shafts"]]
    obs += [rect(x, z, frame["column_width"], frame["column_width"]) for x in frame["column_x"] for z in frame["column_z"]]
    for a in floor.get("artifacts", []) + floor.get("copies", []):
        if float(a.get("height", 0) or 0) > 2.0:
            continue   # overhead: walk under it
        x, z = a.get("position") or catalog["stations"][a["station"]]
        # the catalogue's measured footprint where it has one (a playground box is 6.6 x 10.9 m), else the access square
        fp = catalog["artifacts"].get(a.get("artifact"), {}).get("footprint") if measured else None
        if isinstance(fp, dict):
            fp = [fp.get("width", ACCESS), fp.get("height", 1), fp.get("depth", ACCESS)]
        sc = float(a.get("scale", 1) or 1)
        w, d = (float(fp[0]) * sc, float(fp[2]) * sc) if isinstance(fp, list) and len(fp) >= 3 else (ACCESS, ACCESS)
        if int(a.get("facing", 0) or 0) % 180 == 90:
            w, d = d, w
        obs.append(rect(x, z, max(w, ACCESS), max(d, ACCESS)))
    for p in floor.get("props", []):
        size = catalog["props"].get(p.get("kind"), {}).get("size", [1, 1, 1])
        w, _, d = [s * p.get("scale", 1) for s in size]
        if p.get("facing") in (90, 270):
            w, d = d, w
        obs.append(rect(p["position"][0], p["position"][1], w, d))
    for wall in floor.get("walls", []):
        if float(wall.get("base", 0) or 0) >= 2.3:
            continue   # a beam overhead
        (x1, z1), (x2, z2) = wall["from"], wall["to"]
        obs.append((min(x1, x2) - .09, min(z1, z2) - .09, max(x1, x2) + .09, max(z1, z2) + .09))
    for x, z, w, d in floor.get("basin", {}).get("rects", []):
        obs.append((x, z, x + w, z + d))
    return [(a - CLEAR, b - CLEAR, c + CLEAR, d + CLEAR) for a, b, c, d in obs]


class _Grid:
    """the slab as 84 x 36 cells of 0.5 m, centred like the measurement (tools/measure_void_occupancy.py).
    From obstacles (rectangles, cells whose centre lies inside are blocked) and/or a MEASURED floor: a cell whose
    first surface is more than STEP_CM above the slab, or nothing, is blocked, and so are its four neighbours
    (a walker is ~0.3 m wide)."""
    NX, NZ, X0, Z0 = 84, 36, -20.75, -8.75
    STEP_CM = 6   # a 2 cm mat and the Vectors floors' 5 cm field plates are floor; a 7.5 cm bar stops the walker

    def __init__(self, frame: dict, obs: list, measured: dict | None = None):
        self.nx, self.nz = self.NX, self.NZ
        self.block, self.surface = set(), {}
        lim_x, lim_z = frame["width"] / 2 - CLEAR, frame["depth"] / 2 - CLEAR
        for i in range(self.nx):
            for k in range(self.nz):
                x, z = self.pos((i, k))
                if abs(x) > lim_x or abs(z) > lim_z:
                    self.block.add((i, k))
        for o in obs:
            i0, i1 = math.ceil((o[0] - self.X0) / GRID - 1e-9), math.floor((o[2] - self.X0) / GRID + 1e-9)
            k0, k1 = math.ceil((o[1] - self.Z0) / GRID - 1e-9), math.floor((o[3] - self.Z0) / GRID + 1e-9)
            for i in range(max(0, i0), min(self.nx - 1, i1) + 1):
                for k in range(max(0, k0), min(self.nz - 1, k1) + 1):
                    self.block.add((i, k))
        if measured:
            rle, cells = measured["rle"], []
            for j in range(0, len(rle), 2):
                cells += [rle[j]] * rle[j + 1]
            high = set()
            for n, val in enumerate(cells):
                c = (n % self.nx, n // self.nx)
                if val > self.STEP_CM:
                    high.add(c)
                else:
                    self.surface[c] = val / 100.0
            for i, k in high:
                for c in ((i, k), (i + 1, k), (i - 1, k), (i, k + 1), (i, k - 1)):
                    self.block.add(c)

    def merged(self, other: "_Grid") -> "_Grid":
        g = object.__new__(_Grid)
        g.nx, g.nz, g.surface = self.nx, self.nz, self.surface
        g.block = self.block | other.block
        return g

    def pos(self, c):
        return (round(self.X0 + c[0] * GRID, 2), round(self.Z0 + c[1] * GRID, 2))

    def cell(self, p):
        return (max(0, min(self.nx - 1, round((p[0] - self.X0) / GRID))), max(0, min(self.nz - 1, round((p[1] - self.Z0) / GRID))))

    def free(self, p) -> bool:
        return self.cell(p) not in self.block

    def height(self, p) -> float:
        return self.surface.get(self.cell(p), 0.0)

    def line_free(self, a, b) -> bool:
        n = max(1, int(math.dist(a, b) / (GRID / 2)))
        return all(self.cell((a[0] + (b[0] - a[0]) * t / n, a[1] + (b[1] - a[1]) * t / n)) not in self.block for t in range(n + 1))

    def path(self, a, b):
        import heapq
        s, g = self.cell(a), self.cell(b)
        if s in self.block or g in self.block:
            return None
        came, cost, todo = {s: None}, {s: 0.0}, [(0.0, s)]
        steps = [(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)]
        while todo:
            _, c = heapq.heappop(todo)
            if c == g:
                break
            for dx, dz in steps:
                nb = (c[0] + dx, c[1] + dz)
                if not (0 <= nb[0] < self.nx and 0 <= nb[1] < self.nz) or nb in self.block:
                    continue
                if dx and dz and ((c[0] + dx, c[1]) in self.block or (c[0], c[1] + dz) in self.block):
                    continue   # no corner cutting
                nc = cost[c] + math.hypot(dx, dz)
                if nc < cost.get(nb, 1e18):
                    cost[nb], came[nb] = nc, c
                    heapq.heappush(todo, (nc + math.dist(nb, g), nb))
        if g not in came:
            return None
        cells, c = [], g
        while c is not None:
            cells.append(c)
            c = came[c]
        pts = [self.pos(c) for c in reversed(cells)]
        out = [pts[0]]   # string pulling: keep a point only where a straight line would cross an obstacle
        i = 0
        while i < len(pts) - 1:
            j = len(pts) - 1
            while j > i + 1 and not self.line_free(pts[i], pts[j]):
                j -= 1
            out.append(pts[j])
            i = j
        return out


def build_walk(doc: dict, reg: dict) -> dict:
    v = _validator()
    rooms = read(ROOMS)
    frame = read(ROOT / "commons/void/layout.json")
    catalog = read(CATALOG)
    numbered = defaultdict(list)
    for n, row in enumerate(doc.get("main", []), start=1):
        if row.get("floor") is not None:
            numbered[row["floor"]].append((n, row["key"]))
    floors, stale = {}, []
    try:
        occupancy = read(OCCUPANCY).get("floors", {})
    except (OSError, ValueError):
        occupancy = {}
    for f, rows in sorted(numbered.items()):
        if not (0 <= f < len(rooms["floors"])):
            continue
        floor = rooms["floors"][f]
        authored = bool(floor.get("route"))
        meas = occupancy.get(str(f))
        if meas and meas.get("hash") != _floor_hash(floor):
            stale.append(f)
            meas = None
        if meas:
            # MEASURED in the built tower: the walk goes where a body can stand; a stand also keeps off the
            # other works' access squares, so a caption never lies inside a work that has no collision
            walkgrid = _Grid(frame, [], meas)
            standgrid = walkgrid.merged(_Grid(frame, _walk_obstacles(floor, frame, catalog, v, measured=False)))
            grids = [standgrid, walkgrid]
        else:
            # not measured (or stale): STRICT keeps clear of every catalogue footprint, LOOSE only of the access
            # squares, for rooms you walk into. Strict first, loose if there is no way.
            walkgrid = _Grid(frame, _walk_obstacles(floor, frame, catalog, v))
            grids = [walkgrid, _Grid(frame, _walk_obstacles(floor, frame, catalog, v, measured=False))]
        stops, prev, used = [], None, []
        for n, key in rows:
            here = next((a for a in floor.get("artifacts", []) + floor.get("copies", [])
                         if a.get("artifact") == key), None)
            if here is None:
                continue
            at = here.get("position") or catalog["stations"][here["station"]]
            # on the grid, 1.2-3.5 m from the work, free, and not on another work's stand (captions must not overlap)
            # cell centres 1.2-3.5 m from it; a work you walk INTO (a raised room) may need 3.5-6 m
            ci, ck = walkgrid.cell(at)
            cells = [walkgrid.pos((i, k)) for i in range(max(0, ci - 12), min(walkgrid.nx, ci + 13))
                     for k in range(max(0, ck - 12), min(walkgrid.nz, ck + 13))]
            ring = []
            for lo, hi in ((1.2, 3.5), (3.5, 6.0)):
                spaced = [p for p in cells if lo <= math.dist(p, at) <= hi and all(math.dist(p, u) >= 1.6 for u in used)]
                ring = next(([p for p in spaced if g.free(p)] for g in grids if any(g.free(p) for p in spaced)), [])
                if ring:
                    break
            far = False
            if not ring:
                # a work beyond the slab (an annex) or inside a closed room: the nearest free cell of the slab, from
                # where it is seen - the caption points out at it
                every = [walkgrid.pos((i, k)) for i in range(walkgrid.nx) for k in range(walkgrid.nz)]
                spaced = [p for p in every if all(math.dist(p, u) >= 1.6 for u in used)]
                free = next(([p for p in spaced if g.free(p)] for g in grids if any(g.free(p) for p in spaced)), [])
                ring, far = sorted(free, key=lambda p: math.dist(p, at))[:1], True
            towards = prev or (0.0, 0.0)
            stand = min(ring, key=lambda p: math.dist(p, towards) + .5 * math.dist(p, at)) if ring else None
            title = (reg.get(key) or {}).get("title", key)
            stops.append({"n": n, "key": key, "id": here.get("id"), "title": title[:60], "at": [at[0], at[1]],
                          "stand": list(stand) if stand else [at[0], at[1]],
                          "y": walkgrid.height(stand) if stand else 0.0, "free": stand is not None,
                          **({"far": round(math.dist(stand, at), 1)} if far and stand else {})})
            if stand:
                prev = stand
                used.append(stand)
        entry = {"route": "authored" if authored else "timeline", "stops": stops}
        if not authored:
            path, unreached = [], []
            for a, b in zip(stops, stops[1:]):
                if not (a["free"] and b["free"]):
                    unreached.append(b["n"])
                    path.append(None)
                    continue
                seg = walkgrid.path(a["stand"], b["stand"]) if meas else (grids[0].path(a["stand"], b["stand"]) or grids[1].path(a["stand"], b["stand"]))
                if seg is None:
                    unreached.append(b["n"])
                    path.append(None)   # a break in the line
                    continue
                if path and path[-1] is not None and path[-1][:2] == list(seg[0]):
                    seg = seg[1:]
                path += [[p[0], p[1], walkgrid.height(p)] for p in seg]   # x, z, the surface it lies on
            # a None marks a break; store the walk as a list of polylines
            lines, cur = [], []
            for p in path:
                if p is None:
                    if len(cur) > 1:
                        lines.append(cur)
                    cur = []
                else:
                    cur.append(p)
            if len(cur) > 1:
                lines.append(cur)
            entry["lines"] = lines
            entry["unreached"] = unreached + [s["n"] for s in stops if not s["free"] and s["n"] not in unreached]
        entry["measured"] = bool(meas)
        floors[str(f)] = entry
    return {"_doc": "DERIVED by tools/artifact_timeline.py from commons/data/artifact_timeline.json + commons/void/rooms.json - "
                    "never edit. Read by commons/void/floor_content.gd: number captions at each main work's stand, and on "
                    "floors without a hand-made route the walk in number order (lines).", "stale_occupancy": stale, "floors": floors}


def write_walk(doc: dict, reg: dict) -> dict:
    w = build_walk(doc, reg)
    lines = ["{", f'  "_doc": {json.dumps(w["_doc"])},', f'  "stale_occupancy": {json.dumps(w.get("stale_occupancy", []))},', '  "floors": {']
    keys = list(w["floors"])
    for i, k in enumerate(keys):
        lines.append(f"    {json.dumps(k)}: " + json.dumps(w["floors"][k], ensure_ascii=False, separators=(",", ":"))
                     + ("," if i < len(keys) - 1 else ""))
    lines += ["  }", "}"]
    text = "\n".join(lines) + "\n"
    if not WALK.exists() or WALK.read_text(encoding="utf-8") != text:   # tracked: write only on change
        WALK.write_text(text, encoding="utf-8", newline="\n")
    return w


def build_view() -> dict:
    doc = read(AUTHORED)
    reg, tw, cp, ex = registry(), tower(), construction_path(), exports_count()
    floors = floor_titles()
    walk = write_walk(doc, reg)["floors"]
    on_walk = {(int(f), s["key"]): (w["route"], s["n"] in w.get("unreached", [])) for f, w in walk.items() for s in w["stops"]}

    def describe(key: str) -> dict:
        r = reg.get(key) or {}
        places = tw.get(key, [])
        return {"key": key, "title": r.get("title", key), "scene": r.get("scene", ""), "category": r.get("category"),
                "registered": key in reg, "places": places, "path": cp.get(key), "exports": ex.get(key, 0)}

    main, gaps = [], defaultdict(list)
    for n, row in enumerate(doc.get("main", []), start=1):
        e = {**describe(row["key"]), "n": n, "floor": row.get("floor"), "note": row.get("note", "")}
        flags = []
        if not e["places"]:
            flags.append("not in the tower")
        else:
            floors_here = {p["floor"] for p in e["places"]}
            if e["floor"] is not None and e["floor"] not in floors_here:
                flags.append(f"numbered on floor {e['floor']}, stands on {', '.join(map(str, sorted(floors_here)))}")
            on = [p for p in e["places"] if e["floor"] is None or p["floor"] == e["floor"]] or e["places"]
            mode, stuck = on_walk.get((e["floor"], e["key"]), (None, False))
            if mode == "timeline" and stuck:
                flags.append("the walk cannot reach it")
            elif mode == "authored" and all(p["route_m"] is None or p["route_m"] > OFF_ROUTE_M for p in on):
                flags.append("off the hand-made route")
        if not e["path"]:
            flags.append("not on the construction path")
        if not e["registered"]:
            flags.append("no registry entry")
        e["flags"] = flags
        for f in flags:
            gaps[f.split(",")[0] if f.startswith("numbered") else f].append(n)
        main.append(e)
    env = [{**describe(r["key"]), "why": r.get("why", "")} for r in doc.get("environment", [])]
    removed = [{**describe(r["key"]), "reason": r.get("reason", ""), "at": r.get("at")} for r in doc.get("removed", [])]
    filed = {r["key"] for r in doc.get("main", []) + doc.get("environment", []) + doc.get("removed", [])}
    unfiled = [describe(k) for k in sorted(tw, key=lambda k: (min(p["floor"] for p in tw[k]), k)) if k not in filed]
    standing = [r for r in removed if r["places"]]
    dup = sorted({k for k in filed if sum(1 for r in doc.get("main", []) + doc.get("environment", []) + doc.get("removed", [])
                                          if r["key"] == k) > 1})
    catalogue_keys = set(reg) | set(ex)
    placeable = set(_validator().available_artifacts())
    catalogue = sorted(({"key": k, "title": (reg.get(k) or {}).get("title", k), "in_tower": k in tw, "filed": k in filed,
                         "placeable": k in placeable}
                        for k in catalogue_keys), key=lambda c: c["key"])
    counts = {"main": len(main), "environment": len(env), "removed": len(removed), "unfiled": len(unfiled),
              "removed_still_standing": len(standing), "duplicates": len(dup),
              "tower_works": len(tw), "catalogue": len(catalogue),
              **{"gap: " + k: len(v) for k, v in sorted(gaps.items())}}
    return {"_doc": "DERIVED by tools/artifact_timeline.py view - never edit; the authored file is commons/data/artifact_timeline.json",
            "generated_at": now(), "edited_at": doc.get("edited_at"), "base": doc.get("edited_at") or doc.get("seeded_at"), "counts": counts, "floors": floors,
            "main": main, "environment": env, "removed": removed, "unfiled": unfiled, "duplicates": dup,
            "gaps": {k: v for k, v in gaps.items()}, "catalogue": catalogue}


def write_view() -> dict:
    v = build_view()
    VIEW.parent.mkdir(parents=True, exist_ok=True)
    VIEW.write_text(json.dumps(v, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    return v


def check(markdown: bool) -> int:
    v = write_view()
    c = v["counts"]
    failures = c["unfiled"] + c["removed_still_standing"] + c.get("gap: not in the tower", 0) + c["duplicates"]
    if markdown:
        print("# Artifact timeline check\n")
        print("| | |\n|---|---|")
        for k, n in c.items():
            print(f"| {k} | {n} |")
        if v["unfiled"]:
            print("\n## Unfiled tower works\n")
            for u in v["unfiled"]:
                print(f"- `{u['key']}` floor {min(p['floor'] for p in u['places'])}")
        if c["removed_still_standing"]:
            print("\n## Removed, still standing\n")
            for r in v["removed"]:
                if r["places"]:
                    print(f"- `{r['key']}`: " + ", ".join(f"floor {p['floor']} `{p['id']}`" for p in r["places"]))
    else:
        for k, n in c.items():
            print(f"{k:34} {n}")
        for u in v["unfiled"][:20]:
            print("  UNFILED", u["key"], "floor", min(p["floor"] for p in u["places"]))
        for d in v["duplicates"]:
            print("  FILED TWICE", d)
    print(f"accounting failures: {failures}", file=sys.stderr)
    return failures


# ---- the tower follows the timeline (Palle, 2026-11-07: "if I remove or add it in the timeline it should be
# removed in the void tower") -----------------------------------------------------------------------------
# State-based, so a save that was refused can simply be saved again:
#   a REMOVED key that still stands      -> every placement (artifacts, copies, props) leaves rooms.json and is
#                                           kept on its removed row as `placements`, so a restore puts it back
#   a MAIN/ENVIRONMENT key not in the tower with kept placements -> they go back where they stood
#   a MAIN key not in the tower, nothing kept -> placed new on its timeline floor, on the nearest free 1.3 m
#                                           access square to the work numbered before it on that floor
# The new rooms.json is judged by tools/validate_void_rooms.py (the Void editor's own validator); errors
# that were already there before do not block, new ones do. The page writes rooms.json through the Void
# editor's save (backup, Desktop copy, revision check, live update), not this tool.

ACCESS = 1.3   # the validator's minimum access footprint of an artifact


def _validator():
    sys.path.insert(0, str(ROOT / "tools"))
    import validate_void_rooms as v   # noqa: E402
    return v


def _obstacles(floor: dict, frame: dict, catalog: dict, v) -> list:
    rect = v.rect
    W, D = frame["width"], frame["depth"]
    obs = [rect(s["x"], 0, frame["shaft_width"], frame["shaft_depth"]) for s in frame["shafts"]]
    obs += [rect(x, z, frame["column_width"], frame["column_width"]) for x in frame["column_x"] for z in frame["column_z"]]
    obs.append(rect(-6, 4.5, 1.2, 1.2))
    if floor.get("origin"):
        obs.append(rect(0, 0, 1.6, 1.6))
    obs += [rect(x + .5, z + .5, 1, 1) for x, z in floor.get("impact_cells", [])]
    for a in floor.get("artifacts", []) + floor.get("copies", []):
        x, z = a.get("position") or catalog["stations"][a["station"]]
        obs.append(rect(x, z, ACCESS, ACCESS))
    for p in floor.get("props", []):
        size = catalog["props"].get(p.get("kind"), {}).get("size", [1, 1, 1])
        w, _, d = [s * p.get("scale", 1) for s in size]
        if p.get("facing") in (90, 270):
            w, d = d, w
        obs.append(rect(p["position"][0], p["position"][1], w, d))
    for wall in floor.get("walls", []):
        (x1, z1), (x2, z2) = wall["from"], wall["to"]
        obs.append((min(x1, x2) - .09, min(z1, z2) - .09, max(x1, x2) + .09, max(z1, z2) + .09))
    for x, z, w, d in floor.get("basin", {}).get("rects", []):
        obs.append((x, z, x + w, z + d))
    return obs


def _free_spot(floor: dict, frame: dict, catalog: dict, v, near: list) -> list | None:
    obs = _obstacles(floor, frame, catalog, v)
    hw, hd = frame["width"] / 2 - ACCESS / 2, frame["depth"] / 2 - ACCESS / 2
    cands = [(x / 2, z / 2) for x in range(int(-hw * 2), int(hw * 2) + 1) for z in range(int(-hd * 2), int(hd * 2) + 1)]
    cands.sort(key=lambda c: math.dist(c, near))
    for x, z in cands:
        b = v.rect(x, z, ACCESS, ACCESS)
        if not any(v.overlaps(b, o) for o in obs):
            return [x, z]
    return None


def plan(body: dict) -> dict:
    """the timeline edit -> the tower edit. Returns {rooms|None, revision, body (removed rows carry placements),
    changes, warnings} or {error}."""
    import hashlib
    v = _validator()
    cur = read(AUTHORED)
    if body.get("base") != (cur.get("edited_at") or cur.get("seeded_at")):
        return {"error": "the timeline was saved elsewhere since this page loaded it - reload, then redo the edit", "conflict": True}
    text = ROOMS.read_text(encoding="utf-8")
    rooms = json.loads(text)
    frame = read(ROOT / "commons/void/layout.json")
    catalog = read(CATALOG)
    placeable = v.available_artifacts()
    kept = {r["key"]: r.get("placements", []) for r in cur.get("removed", []) if r.get("placements")}
    for r in body.get("removed", []) or []:
        if isinstance(r, dict) and r.get("placements"):
            kept[r["key"]] = r["placements"]
    changes, warnings = [], []
    floors = rooms["floors"]

    def standing(key: str) -> bool:
        if key.startswith("prop:"):
            return any(p.get("kind") == key[5:] for f in floors for p in f.get("props", []))
        return any(a.get("artifact") == key for f in floors for a in f.get("artifacts", []) + f.get("copies", []))

    # 1. take out what was removed
    removed_rows = []
    for r in body.get("removed", []) or []:
        key = r["key"]
        taken = []
        for i, f in enumerate(floors):
            for lst in ("artifacts", "copies", "props"):
                keep_rows = []
                for idx, row in enumerate(f.get(lst, [])):
                    hit = (row.get("kind") == key[5:]) if (lst == "props" and key.startswith("prop:")) else \
                          (lst != "props" and row.get("artifact") == key)
                    (taken if hit else keep_rows).append({"floor": i, "list": lst, "index": idx, "row": row} if hit else row)
                if lst in f:
                    f[lst] = keep_rows
        if taken:
            changes.append(f"took {key} out of the tower: " + ", ".join(f"floor {t['floor']} {t['row'].get('id')}" for t in taken))
        r = {**r, "placements": kept.get(key, []) + taken}
        if not r["placements"]:
            r.pop("placements")
        removed_rows.append(r)

    # 2. put back what was restored, place what is new
    main_rows = body.get("main", []) or []
    for track, rows in (("main", main_rows), ("environment", body.get("environment", []) or [])):
        for n, r in enumerate(rows):
            key = r["key"]
            if standing(key):
                continue
            if kept.get(key):
                for t in sorted(kept[key], key=lambda t: (t["floor"], t["list"], t.get("index", 1 << 30))):
                    f = floors[t["floor"]]
                    ids = {x.get("id") for lst in ("artifacts", "copies", "props") for x in f.get(lst, [])}
                    row = dict(t["row"])
                    while row.get("id") in ids:
                        row["id"] = f"{row['id']}-back"
                    lst = f.setdefault(t["list"], [])
                    lst.insert(min(t.get("index", len(lst)), len(lst)), row)   # back in its old place in the list
                changes.append(f"put {key} back where it stood: " + ", ".join(f"floor {t['floor']}" for t in kept[key]))
                continue
            if track != "main":
                warnings.append(f"{key} is on the environment track but stands nowhere in the tower")
                continue
            if key.startswith("prop:"):
                return {"error": f"{key} is a prop: place props in the Void editor"}
            if key not in placeable:
                return {"error": f"{key} cannot stand in the tower: it has no registered scene on disk (add it to the registry or the Void catalogue first)"}
            fl = r.get("floor")
            if fl is None:
                fl = next((main_rows[j].get("floor") for j in range(n - 1, -1, -1) if main_rows[j].get("floor") is not None), None)
            if fl is None or not (0 <= fl < len(floors)):
                return {"error": f"{key} needs a floor before it can be placed in the tower"}
            f = floors[fl]
            near = None   # the work numbered before it on the same floor
            for j in range(n - 1, -1, -1):
                if main_rows[j].get("floor") != fl:
                    break
                prev = next((a for a in f.get("artifacts", []) if a.get("artifact") == main_rows[j]["key"] and a.get("position")), None)
                if prev:
                    near = prev["position"]
                    break
            if near is None:
                route = [s["position"] for s in f.get("route") or [] if isinstance(s.get("position"), list)]
                near = route[0] if route else [0, 0]
            spot = _free_spot(f, frame, catalog, v, near)
            if spot is None:
                return {"error": f"floor {fl} has no free 1.3 m square left for {key}"}
            ids = {x.get("id") for lst in ("artifacts", "copies", "props") for x in f.get(lst, [])}
            base_id = re.sub(r"[^A-Za-z0-9_-]", "-", key)[:48] or "work"
            aid, k = base_id, 2
            while aid in ids:
                aid, k = f"{base_id}-{k}", k + 1
            station = min(catalog["stations"], key=lambda s: math.dist(catalog["stations"][s], spot))
            title = placeable[key].get("label") or placeable[key].get("name") or key
            f.setdefault("artifacts", []).append({"id": aid, "artifact": key, "station": station, "facing": 0, "height": 0,
                                                  "scale": 1, "position": spot,
                                                  "config": {"editor_label": f"{title} / placed from the artifact timeline"}})
            r["floor"] = fl
            changes.append(f"placed {key} on floor {fl} at ({spot[0]}, {spot[1]}) as {aid}")

    out_body = {**body, "removed": removed_rows}
    if not changes:
        return {"rooms": None, "body": out_body, "changes": [], "warnings": warnings}
    before = v.editor_validation(json.loads(text))
    after = v.editor_validation(rooms)
    new_errors = [e for e in after["errors"] if e not in before["errors"]]
    if new_errors:
        return {"error": "the tower edit would not validate: " + "; ".join(new_errors[:5])}
    warnings += [w for w in after["warnings"] if w not in before["warnings"]]
    return {"rooms": rooms, "revision": hashlib.sha256(text.encode("utf-8")).hexdigest(), "body": out_body,
            "changes": changes, "warnings": warnings}


def save(text: str) -> int:
    """the page's Save: {"base": <edited_at or seeded_at the page loaded>, "main", "environment", "removed"} on stdin.
    Refuses a stale base (someone saved in between) and a key filed twice. Prints the new view's counts."""
    try:
        body = json.loads(text)
    except ValueError as e:
        print(json.dumps({"error": f"not JSON: {e}"}))
        return 3
    cur = read(AUTHORED)
    if body.get("base") != (cur.get("edited_at") or cur.get("seeded_at")):
        print(json.dumps({"error": "the timeline was saved elsewhere since this page loaded it - reload, then redo the edit",
                          "conflict": True, "current": cur.get("edited_at") or cur.get("seeded_at")}))
        return 4

    def clean(rows, fields):
        out = []
        for r in rows if isinstance(rows, list) else []:
            if isinstance(r, dict) and isinstance(r.get("key"), str) and r["key"].strip():
                row = {"key": r["key"].strip()}
                for f in fields:
                    v = r.get(f)
                    if f == "placements":
                        if isinstance(v, list) and v:
                            row[f] = v
                    elif f == "floor" and (isinstance(v, int) or v is None):
                        row[f] = v
                    elif f != "floor" and isinstance(v, str) and v.strip():
                        row[f] = v.strip()
                out.append(row)
        return out

    main_rows = clean(body.get("main"), ["floor", "note"])
    env_rows = clean(body.get("environment"), ["why"])
    rem_rows = clean(body.get("removed"), ["reason", "at", "placements"])
    keys = [r["key"] for r in main_rows + env_rows + rem_rows]
    twice = sorted({k for k in keys if keys.count(k) > 1})
    if twice:
        print(json.dumps({"error": "filed twice: " + ", ".join(twice[:10])}))
        return 5
    cur.update({"edited_at": now(), "main": main_rows, "environment": env_rows, "removed": rem_rows})
    write_authored(cur)
    v = write_view()
    print(json.dumps({"ok": True, "edited_at": cur["edited_at"], "counts": v["counts"]}))
    return 0


def main(argv: list) -> int:
    cmd = argv[1] if len(argv) > 1 else "check"
    if cmd == "seed":
        seed("--force" in argv)
        write_view()
        return 0
    if cmd == "view":
        v = write_view()
        print(json.dumps(v["counts"]))
        return 0
    if cmd == "check":
        return min(check("--markdown" in argv), 255)
    if cmd == "plan":
        # bytes, never print(): Windows stdout is cp1252 and would re-encode every non-ASCII label in rooms.json
        sys.stdout.buffer.write(json.dumps(plan(json.loads(sys.stdin.buffer.read().decode("utf-8"))), ensure_ascii=False).encode("utf-8"))
        return 0
    if cmd == "save":
        return save(sys.stdin.buffer.read().decode("utf-8"))
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
