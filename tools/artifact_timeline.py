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
    form         (optional, on main and environment rows - Palle, 2026-11-07: "differentiate between artifacts and
                 collections ... understand what artifacts are associative children of a base artifact ... children
                 share base number") {"kind": "base"|"child"|"collection", "of": <the base's key, a child>,
                 "term": <its commons/modular/terms.json term>, "op": array|times|assemblage|collation|set (a
                 collection), "algorithmic": true when the collection IS the algorithm (main track) - false: an
                 environment collection, "guessed": true until confirmed on the page}. A child whose base is a numbered
                 main row shares the base's number: #0412.a, .b ... in its order on the track.

DERIVED (rebuilt, never edit):  ada_run/artifact_timeline_view.json  - what the page reads.
    For each row: where it stands in the tower (floor, placement id, the nearest stop of that
    floor's walking route and how far), whether it is on the construction path
    (commons/data/construction_path.json) with that path's annotation, registry title/scene.
    Plus: tower artifacts filed nowhere (UNFILED), and the catalogue to add from.

    python tools/artifact_timeline.py seed [--force]   # first version from the tower as it stands
    python tools/artifact_timeline.py view             # rebuild the derived view
    python tools/artifact_timeline.py check [--markdown]
    python tools/artifact_timeline.py forms [--refresh]   # guess the missing forms (--refresh: re-guess the guessed)

CARDS (transitions - Palle, 2026-11-08: "transition cards between artifacts in the timeline. The motivation for the
transition. The point is genesis ... line = distance(point, point), extension(line) = plank ... a short sentence and the
formula"; "extension is body, association is name"). A card lives on its TERM in commons/modular/terms.json:
card {formula, motive, op, said}. The view puts it once: before the main row that names it in "cards" (written by
hand - where the tower stages a step with no work of that form), else before the first main work MADE of that form
(its form term is the term, or a child of it, or a term whose grammar `from` holds it). A card no work carries yet is
listed as unplaced.
    The op words are the operations of commons/modular/grammar.json (one vocabulary, 2026-11-09); a card also carries
    `axes` (the axis level it raises) and may carry `with` (a second operation it introduces). place_cards() is the one
    placement rule; tools/grammar.py checks the cards against the tower (earned order, axis levels, a root per sequence).
    python tools/artifact_timeline.py cards              # every card, where it falls in the time
    python tools/artifact_timeline.py card <term>        # {formula, motive, op} on stdin -> written on the term

THREADS (comments and instructions in the time - Palle, 2026-11-07: "comment and add artifacts in the time by
instruction prompt, so we can prompt in the context of the time"): commons/data/artifact_timeline_threads.json
    python tools/artifact_timeline.py thread list | add | set <id>     # the page's /api/artifact-timeline/instruct
    python tools/artifact_timeline.py prompt <id>       # the instruction with its context, as a model reads it
    python tools/artifact_timeline.py instructions      # the queued ones (no model reached), for an agent session
    python tools/artifact_timeline.py answer <id>       # an agent's {"reply", "operations"} on stdin -> proposed
    An answer only PROPOSES: the page applies its operations to the unsaved timeline; the person saves.
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
import os


def _write(path: Path, text: str) -> None:
    """Write through a temp file and swap it in. A plain open(path, "w") on Windows sometimes fails with EINVAL
    (Errno 22) on a file another process holds open (an editor, the dev server reading it): measured 2026-11-09 on
    artifact_timeline_walk.json, where `check` crashed before writing anything."""
    tmp = path.with_name(path.name + ".tmp")
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    os.replace(tmp, path)

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
                term = None
                if "modular/composite.tscn" in str(v.get("scene", "")):
                    term = (v.get("default_params") or {}).get("term") or k.removeprefix("mod_")
                out[k] = {"title": v.get("name") or k, "scene": v.get("scene", ""), "category": v.get("category"),
                          "file": p.name, "description": v.get("description", ""), "term": term}
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
    _write(AUTHORED, "\n".join(lines) + "\n")


# ---- forms: base, child, collection (Palle, 2026-11-07) -------------------------------------------------------
TERMS = ROOT / "commons/modular/terms.json"
FORM_KINDS = ("base", "child", "collection")
COLLECTION_OPS = ("array", "times", "assemblage", "collation", "set")
# words in a key that name a collection of things (a guess, confirmed on the page); "room", "wall", "table" are not:
# they are as often one work
COLLECTION_WORDS = {"collection", "gallery", "array", "row", "rows", "stack", "shelf", "forest", "garden", "pile", "cluster"}
ALGORITHMIC_CHAPTERS = {"array", "randomness", "noise", "tiling", "fractals", "lsystems", "swarms", "automata", "graphs"}


def terms() -> dict:
    try:
        return read(TERMS).get("terms", {})
    except (OSError, ValueError):
        return {}


def guess_form(key: str, floor, keys_on: dict, reg: dict, tm: dict) -> dict | None:
    """a first form for a row, marked guessed. keys_on: floor -> main keys numbered there, in timeline order."""
    term = (reg.get(key) or {}).get("term") or (key if key in tm else None)
    if term and term in tm:
        t = tm[term]
        expr, op = str(t.get("expr", "")), str((t.get("build") or {}).get("op", ""))
        if expr.startswith("association("):
            base_term = (t.get("from") or [None])[0]
            form = {"kind": "child", "term": term, "guessed": True}
            if base_term:
                cands = [k for k in keys_on.get(floor, []) if k != key and not k.startswith("mod_")
                         and base_term in k.lower().split("_")]
                exact = [k for k in cands if k == base_term or k.endswith("_" + base_term) or "primitive_" + base_term in k]
                if exact or cands:
                    form["of"] = (exact or cands)[0]
                form["of_form"] = base_term
            return form
        if op in ("times", "array", "assemblage") or expr.split("(")[0] in ("array", "times"):
            return {"kind": "collection", "term": term, "op": op if op in COLLECTION_OPS else "array",
                    "algorithmic": t.get("chapter") in ALGORITHMIC_CHAPTERS, "guessed": True}
        return {"kind": "base", "term": term, "guessed": True}
    if COLLECTION_WORDS & set(key.lower().replace("prop:", "").split("_")):
        return {"kind": "collection", "op": "set", "guessed": True}
    return None


def forms(refresh: bool) -> int:
    doc, reg, tm = read(AUTHORED), registry(), terms()
    keys_on = defaultdict(list)
    for r in doc.get("main", []):
        keys_on[r.get("floor")].append(r["key"])
    changed = 0
    for track in ("main", "environment"):
        for r in doc.get(track, []):
            if r.get("form") and not (refresh and r["form"].get("guessed")):
                continue
            g = guess_form(r["key"], r.get("floor"), keys_on, reg, tm)
            if track == "environment" and g and g.get("kind") == "collection":
                g["algorithmic"] = False
            if track == "main" and g and g.get("kind") == "collection" and g.get("op") == "set":
                g["algorithmic"] = True   # on the main track now: it stays there until the page says otherwise
            if g and g != r.get("form"):
                r["form"] = g
                changed += 1
    if changed:
        write_authored(doc)
    print(f"forms: {changed} rows given a guessed form")
    return 0


def numbering(main_rows: list) -> dict:
    """key -> {"n": int|None, "label": "#0412" | "#0412.a", "base": key|None, "sort": float}. A child shares its base's
    number when its base is a numbered main row (not itself a child); otherwise it keeps a number of its own."""
    by_key = {r["key"]: r for r in main_rows}

    def child_of(r):
        f = r.get("form") or {}
        if f.get("kind") != "child" or f.get("of") not in by_key or f.get("of") == r["key"]:
            return None
        base = by_key[f["of"]]
        bf = base.get("form") or {}
        if bf.get("kind") == "child" and bf.get("of") in by_key:
            return None   # a child of a child keeps its own number
        return f["of"]
    out, n = {}, 0
    for r in main_rows:
        if child_of(r) is None:
            n += 1
            out[r["key"]] = {"n": n, "label": f"#{n:04d}", "base": None, "sort": float(n)}
    letters = defaultdict(int)
    for r in main_rows:
        if r["key"] in out:
            continue
        of = child_of(r)
        b = out[of]
        i = letters[of]
        letters[of] += 1
        tag = chr(ord("a") + i) if i < 26 else f"z{i - 25}"
        out[r["key"]] = {"n": None, "label": f"{b['label']}.{tag}", "base": of, "sort": b["n"] + (i + 1) / 100.0}
    return out


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
    num = numbering(doc.get("main", []))
    for row in doc.get("main", []):
        if row.get("floor") is not None:
            numbered[row["floor"]].append((num[row["key"]]["sort"], row["key"]))
    for f in numbered:
        numbered[f].sort()
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
            stops.append({"n": n, "label": num[key]["label"], "key": key, "id": here.get("id"), "title": title[:60], "at": [at[0], at[1]],
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
        _write(WALK, text)
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
    num = numbering(doc.get("main", []))
    tm = terms()
    has_card = {t for t, v in tm.items() if isinstance(v.get("card"), dict)}
    carded, cards_before, track_at = place_cards(doc, tm)
    made_of = {}   # the page places cards itself as rows move: it needs what each formed term is made of
    for row in doc.get("main", []):
        ft = (row.get("form") or {}).get("term")
        if ft in tm:
            made_of[ft] = [x for x in (tm[ft].get("from") or []) if x in has_card]
    children = defaultdict(list)
    for row in doc.get("main", []):
        if num[row["key"]]["base"]:
            children[num[row["key"]]["base"]].append(row["key"])
    for row in doc.get("main", []):
        nb = num[row["key"]]
        n = nb["label"]
        e = {**describe(row["key"]), "n": nb["n"], "label": nb["label"], "base": nb["base"], "children": children.get(row["key"], []),
             "form": row.get("form"), "floor": row.get("floor"), "note": row.get("note", "")}
        flags = []
        form = row.get("form") or {}
        if form.get("kind") == "child" and not nb["base"]:
            flags.append(f"its base ({form.get('of') or form.get('of_form') or '?'}) is not a numbered main work")
        if form.get("guessed"):
            flags.append("form guessed")
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
        if row.get("cards"):
            e["cards_by_hand"] = list(row["cards"])   # the authored list: the page must send it back on Save
        if cards_before.get(row["key"]):
            e["cards"] = [card_of(t, tm) for t in cards_before[row["key"]]]
        e["flags"] = flags
        for f in flags:
            gaps[f.split(",")[0] if f.startswith("numbered") else ("its base is not a numbered main work" if f.startswith("its base") else f)].append(n)
        main.append(e)
    env = [{**describe(r["key"]), "why": r.get("why", ""), "form": r.get("form"),
            "lane": "collections" if (r.get("form") or {}).get("kind") == "collection" else "works"} for r in doc.get("environment", [])]
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
    pos = {r["key"]: i for i, r in enumerate(doc.get("main", []))}
    card_list = sorted(({**card_of(t, tm), "at": carded.get(t)} for t, v in tm.items() if isinstance(v.get("card"), dict)),
                       key=lambda c: (pos.get(c["at"], 10 ** 6), (cards_before.get(c["at"]) or [c["term"]]).index(c["term"])))
    counts = {"main": len(main), "cards": len(card_list), "cards_unplaced": sum(1 for c in card_list if not c["at"]), "numbered": sum(1 for e in main if e["n"] is not None),
              "children": sum(1 for e in main if e["base"]),
              "main_collections": sum(1 for e in main if (e["form"] or {}).get("kind") == "collection"),
              "environment": len(env), "environment_collections": sum(1 for e in env if e["lane"] == "collections"),
              "forms_guessed": sum(1 for e in main + env if (e.get("form") or {}).get("guessed")),
              "removed": len(removed), "unfiled": len(unfiled),
              "removed_still_standing": len(standing), "duplicates": len(dup),
              "tower_works": len(tw), "catalogue": len(catalogue),
              **{"gap: " + k: len(v) for k, v in sorted(gaps.items())}}
    return {"_doc": "DERIVED by tools/artifact_timeline.py view - never edit; the authored file is commons/data/artifact_timeline.json",
            "generated_at": now(), "edited_at": doc.get("edited_at"), "base": doc.get("edited_at") or doc.get("seeded_at"), "counts": counts, "floors": floors,
            "main": main, "environment": env, "removed": removed, "unfiled": unfiled, "duplicates": dup,
            "gaps": {k: v for k, v in gaps.items()}, "catalogue": catalogue, "cards": card_list, "made_of": made_of,
            "card_ops": list(CARD_OPS)}


def place_cards(doc: dict, tm: dict) -> tuple:
    """where each card falls: {term: key of the main work it stands before}, {key: [terms in reading order]}, track
    index. The rule (one implementation - tools/grammar.py and the page mirror it): a row's "cards" (written by hand)
    first, else the first main work MADE of the form (its form term, a child's of_form, a term in its term's `from`).
    Several cards on one work read in the hand-written order, then the track's, then the grammar file's."""
    carded: dict = {}
    hand_at: dict = {}
    has_card = {t for t, v in tm.items() if isinstance(v.get("card"), dict)}
    for row in doc.get("main", []):   # placed by hand: a row's "cards"
        for i, t in enumerate(row.get("cards") or []):
            if t in has_card and t not in carded:
                carded[t] = row["key"]
                hand_at[t] = i
    for row in doc.get("main", []):   # else the first work made of the form
        f = row.get("form") or {}
        made_of = {f.get("term"), f.get("of_form") if f.get("kind") == "child" else None,
                   *((tm.get(f.get("term")) or {}).get("from") or [])}
        for t in sorted(made_of & has_card, key=lambda x: 0 if x == f.get("term") else 1):
            if t not in carded:
                carded[t] = row["key"]
    try:
        track_at = {st["term"]: i for i, st in enumerate(read(TERMS).get("track", []))}
    except (OSError, ValueError):
        track_at = {}
    grammar_at = {t: i for i, t in enumerate(tm)}
    cards_before = defaultdict(list)
    for t in sorted(carded, key=lambda x: (hand_at.get(x, 999), track_at.get(x, 999), grammar_at[x])):
        cards_before[carded[t]].append(t)
    return carded, cards_before, track_at


def card_of(term: str, tm: dict) -> dict:
    t = tm.get(term) or {}
    c = t.get("card") or {}
    axes = c.get("axes") or ([c["axis"]] if c.get("axis") else [])
    return {"term": term, "label": t.get("label", term), "formula": c.get("formula", ""), "motive": c.get("motive", ""),
            "op": c.get("op", ""), "with": c.get("with", []), "axes": axes, "from": t.get("from", []), "said": c.get("said", "")}


GRAMMAR = ROOT / "commons/modular/grammar.json"   # the one vocabulary of operations (Palle, 2026-11-09)


def card_ops() -> tuple:
    try:
        return tuple(read(GRAMMAR)["operations"])
    except (OSError, ValueError, KeyError):
        return ("genesis", "distance", "extension", "association")


CARD_OPS = card_ops()


def set_card(term: str, body: dict) -> dict:
    """write card {formula, motive, op} on a term of terms.json - a JSON round trip that is byte-identical except for
    the card (the file is indent 2; checked before writing). An empty formula and motive removes the card."""
    raw = TERMS.read_bytes()
    g = json.loads(raw.decode("utf-8"))
    if (json.dumps(g, indent=2, ensure_ascii=False) + "\n").encode("utf-8") != raw:
        return {"error": "terms.json is not in its indent-2 form; not writing (open it, it was reformatted)"}
    if term not in g.get("terms", {}):
        return {"error": f"no term {term!r} in terms.json"}
    formula, motive = str(body.get("formula", "")).strip(), str(body.get("motive", "")).strip()
    op = str(body.get("op", "")).strip()
    if op and op not in CARD_OPS:
        return {"error": f"op {op!r}: one of {', '.join(CARD_OPS)}"}
    if len(motive) > 120:
        return {"error": "a card is one short sentence (120 characters at most)"}
    t = g["terms"][term]
    if not formula and not motive:
        t.pop("card", None)
    else:
        old = t.get("card") or {}
        t["card"] = {**old, "formula": formula, "motive": motive, "op": op or old.get("op", ""),   # keeps with / axes
                     "said": str(body.get("said") or old.get("said") or "").strip()}
    TERMS.write_bytes((json.dumps(g, indent=2, ensure_ascii=False) + "\n").encode("utf-8"))
    return {"ok": True, "term": term, "card": t.get("card")}


def write_view() -> dict:
    v = build_view()
    VIEW.parent.mkdir(parents=True, exist_ok=True)
    _write(VIEW, json.dumps(v, ensure_ascii=False, separators=(",", ":")))
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

    def clean_form(f):
        if not isinstance(f, dict) or f.get("kind") not in FORM_KINDS:
            return None
        out = {"kind": f["kind"]}
        for k in ("of", "term", "of_form"):
            if isinstance(f.get(k), str) and f[k].strip():
                out[k] = f[k].strip()
        if f["kind"] == "collection":
            out["op"] = f.get("op") if f.get("op") in COLLECTION_OPS else "set"
            out["algorithmic"] = bool(f.get("algorithmic"))
        if f.get("guessed"):
            out["guessed"] = True
        return out

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
                    elif f == "cards":
                        if isinstance(v, list) and any(isinstance(t, str) and t.strip() for t in v):
                            row[f] = [t.strip() for t in v if isinstance(t, str) and t.strip()]
                    elif f == "form":
                        cf = clean_form(v)
                        if cf:
                            row[f] = cf
                    elif f != "floor" and isinstance(v, str) and v.strip():
                        row[f] = v.strip()
                out.append(row)
        return out

    main_rows = clean(body.get("main"), ["floor", "note", "form", "cards"])
    env_rows = clean(body.get("environment"), ["why", "form"])
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


# ---- threads: comments and instructions in the time (Palle, 2026-11-07) ---------------------------------------
THREADS = ROOT / "commons/data/artifact_timeline_threads.json"
OPS = ("add", "move", "remove", "form", "note", "to_environment", "to_main")


def read_threads() -> dict:
    try:
        return read(THREADS)
    except (OSError, ValueError):
        return {"_doc": "AUTHORED by the page /artifact-timeline (and agents answering instructions) - comments and "
                        "instructions anchored at a timeline work, with the agent's answer: a reply and proposed "
                        "operations, applied by the person on the page. tools/artifact_timeline.py thread|answer.",
                "entries": []}


def write_threads(doc: dict) -> None:
    lines = ["{", f'  "_doc": {json.dumps(doc["_doc"])},', '  "entries": [']
    for i, e in enumerate(doc["entries"]):
        lines.append("    " + json.dumps(e, ensure_ascii=False) + ("," if i < len(doc["entries"]) - 1 else ""))
    lines += ["  ]", "}"]
    _write(THREADS, "\n".join(lines) + "\n")


def _view() -> dict:
    try:
        v = read(VIEW)
        if v.get("base") == (read(AUTHORED).get("edited_at") or read(AUTHORED).get("seeded_at")):
            return v
    except (OSError, ValueError):
        pass
    return write_view()


def context(anchor: str, span: int = 8) -> dict:
    """what a model needs to answer an instruction at `anchor`: the anchor, its neighbours on the track, the works on
    its floor, its children, its grammar term"""
    v, tm = _view(), terms()
    main = v["main"]

    def brief(e):
        f = e.get("form") or {}
        return {"label": e.get("label"), "key": e["key"], "title": e["title"], "floor": e.get("floor"),
                **({"form": f} if f else {}), **({"note": e["note"]} if e.get("note") else {}),
                **({"flags": e["flags"]} if e.get("flags") else {})}
    i = next((n for n, e in enumerate(main) if e["key"] == anchor), None)
    env = next((e for e in v["environment"] if e["key"] == anchor), None)
    out = {"anchor": anchor, "track": "main" if i is not None else ("environment" if env else "unfiled/catalogue")}
    if i is not None:
        a = main[i]
        out["work"] = {**brief(a), "places": [{"floor": p["floor"], "map": p["map"], "id": p["id"]} for p in a["places"]],
                       "construction_path": a.get("path"), "children": a.get("children", [])}
        out["before"] = [brief(e) for e in main[max(0, i - span):i]]
        out["after"] = [brief(e) for e in main[i + 1:i + 1 + span]]
        if a.get("floor") is not None:
            out["floor"] = {"floor": a["floor"], "map": next((f["map"] for f in v["floors"] if f["floor"] == a["floor"]), ""),
                            "title": next((f["title"] for f in v["floors"] if f["floor"] == a["floor"]), ""),
                            "works": [brief(e) for e in main if e.get("floor") == a["floor"]],
                            "environment": [e["key"] for e in v["environment"] if any(p["floor"] == a["floor"] for p in e["places"])]}
    elif env:
        out["work"] = {"key": env["key"], "title": env["title"], "why": env.get("why"), "form": env.get("form"),
                       "places": [{"floor": p["floor"], "map": p["map"], "id": p["id"]} for p in env["places"]]}
    reg = registry().get(anchor) or {}
    term = reg.get("term") or (anchor if anchor in tm else None)
    if term and term in tm:
        t = tm[term]
        out["grammar"] = {"term": term, "expr": t.get("expr"), "from": t.get("from"), "chapter": t.get("chapter"),
                          "children_terms": sorted(k for k, x in tm.items() if term in (x.get("from") or []))[:30]}
    out["counts"] = {k: n for k, n in v["counts"].items() if not k.startswith("gap")}
    return out


PROMPT = """You are helping Palle curate the artifact timeline of Ada Research (a VR museum that teaches algorithms,
built as the Void tower: one numbered main track of works, an environment track of works that make the space).
Palle wrote an INSTRUCTION at one point of the timeline. Answer it in the context of that point.

THE MODEL OF THE TIMELINE
- main: the numbered track. A work's form: base (one work) | child (an associative child of a base: association(config(
  base)) - it SHARES its base's number, #0095.a) | collection (op array|times|assemblage|collation|set; algorithmic
  true = the collection IS the algorithm and stays on the main track; false = an example, it belongs on the
  environment collections lane).
- environment: works that make the space (barriers, lights, plinths, props); an environment collection has its own lane.
- The grammar (commons/modular/terms.json) writes things as expressions over primitives: association(config(form)),
  times, array, assemblage. A child is its base plus a configuration; a collection is an operator over a base.
- You may READ the repository to check keys and context: commons/data/artifact_timeline.json (the timeline),
  commons/modular/terms.json, commons/artifacts/registry/*.json (every registered work: its key, name, description),
  commons/void/rooms.json (the tower), commons/data/construction_path.json. You cannot write; you only propose.

ANSWER WITH ONE JSON OBJECT AND NOTHING ELSE:
{"reply": "<a short answer to Palle in plain words: what you propose and why, or your comment>",
 "operations": [ ... zero or more of:
   {"op": "add", "key": "<registry key>", "after": "<main key it follows>", "floor": <int, optional>,
    "form": {...optional}, "note": "<optional annotation>"},
   {"op": "move", "key": "<main key>", "after": "<main key>" | null (null = first)},
   {"op": "remove", "key": "<key>", "reason": "<why it leaves the path>"},
   {"op": "form", "key": "<key>", "form": {"kind": "base"|"child"|"collection", "of": "<base key>", "op": "...", "algorithmic": true|false}},
   {"op": "note", "key": "<main key>", "note": "<annotation>"},
   {"op": "to_environment", "key": "<main key>", "why": "<why>"},
   {"op": "to_main", "key": "<environment key>", "after": "<main key>"} ]}
Use only keys that exist (check the registry for a work to add). If the instruction is a question or a comment, answer
in "reply" with no operations. Keep the reply under 120 words.

THE INSTRUCTION (at {anchor}):
{text}

THE CONTEXT (derived from the timeline now):
{context}
"""


def make_prompt(entry: dict) -> str:
    ctx = context(entry["anchor"])
    return (PROMPT.replace("{anchor}", f'{entry.get("label_at") or ""} {entry["anchor"]}'.strip())
            .replace("{text}", entry["text"]).replace("{context}", json.dumps(ctx, ensure_ascii=False, indent=1)))


def check_ops(ops) -> list:
    """each operation with valid true/false and why: keys must exist where the operation needs them"""
    doc, reg = read(AUTHORED), registry()
    main_keys = [r["key"] for r in doc.get("main", [])]
    env_keys = {r["key"] for r in doc.get("environment", [])}
    filed = set(main_keys) | env_keys | {r["key"] for r in doc.get("removed", [])}
    placeable = set(_validator().available_artifacts())
    out = []
    for o in ops if isinstance(ops, list) else []:
        if not isinstance(o, dict) or o.get("op") not in OPS or not isinstance(o.get("key"), str):
            out.append({**(o if isinstance(o, dict) else {"raw": o}), "valid": False, "why": "not an operation"})
            continue
        k, op, why = o["key"], o["op"], ""
        after = o.get("after")
        if op == "add":
            if k in main_keys or k in env_keys:
                why = f"{k} is already on the timeline"
            elif k not in reg and k not in placeable:
                why = f"{k} is not a registered work"
            elif k not in placeable and k not in tower():
                why = f"{k} has no scene the tower can build"
        elif op in ("move", "note", "to_environment") and k not in main_keys:
            why = f"{k} is not on the main track"
        elif op == "to_main" and k not in env_keys:
            why = f"{k} is not on the environment track"
        elif op in ("remove", "form") and k not in filed:
            why = f"{k} is not on the timeline"
        if not why and op in ("add", "move", "to_main") and after is not None and after not in main_keys:
            why = f"after: {after} is not on the main track"
        if not why and op == "form":
            f = o.get("form")
            if not isinstance(f, dict) or f.get("kind") not in FORM_KINDS:
                why = "the form needs a kind: base, child or collection"
            elif f["kind"] == "child" and f.get("of") and f["of"] not in main_keys:
                why = f"of: {f['of']} is not on the main track"
        out.append({**o, "valid": not why, **({"why": why} if why else {})})
    return out


def thread(cmd: str, arg: str | None, text: str) -> int:
    doc = read_threads()
    if cmd == "list":
        sys.stdout.buffer.write(json.dumps(doc["entries"], ensure_ascii=False).encode("utf-8"))
        return 0
    body = json.loads(text) if text.strip() else {}
    if cmd == "add":
        if body.get("kind") not in ("comment", "instruction") or not str(body.get("text", "")).strip() or not body.get("anchor"):
            print(json.dumps({"error": "a thread entry needs an anchor, a kind (comment|instruction) and text"}))
            return 3
        num = numbering(read(AUTHORED).get("main", []))
        e = {"id": "t" + datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S%f")[:-3], "anchor": body["anchor"],
             "label_at": (num.get(body["anchor"]) or {}).get("label"), "at": now(), "kind": body["kind"],
             "text": str(body["text"]).strip(), "status": "note" if body["kind"] == "comment" else "asked"}
        doc["entries"].append(e)
        write_threads(doc)
        sys.stdout.buffer.write(json.dumps(e, ensure_ascii=False).encode("utf-8"))
        return 0
    e = next((x for x in doc["entries"] if x["id"] == arg), None)
    if e is None:
        print(json.dumps({"error": f"no thread entry {arg}"}))
        return 3
    if cmd == "set":
        for k in ("status", "error"):
            if k in body:
                e[k] = body[k]
        if body.get("answer") is not None:
            a = body["answer"]
            e["answer"] = {"reply": str(a.get("reply", "")).strip(), "operations": check_ops(a.get("operations", [])),
                           "by": a.get("by", "agent"), "at": now()}
            e["status"] = "proposed"
            e.pop("error", None)
        write_threads(doc)
        sys.stdout.buffer.write(json.dumps(e, ensure_ascii=False).encode("utf-8"))
        return 0
    print(json.dumps({"error": f"unknown thread command {cmd}"}))
    return 2


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
    if cmd == "forms":
        forms("--refresh" in argv)
        write_view()
        return 0
    if cmd == "cards":
        v = write_view()
        for c in v["cards"]:
            at = c["at"] or "(no work of this form yet)"
            sys.stdout.buffer.write(f"{c['formula']:<36} {c['motive']}\n{'':36}   before {at}\n".encode("utf-8"))
        print(f"{len(v['cards'])} cards, {v['counts']['cards_unplaced']} unplaced")
        return 0
    if cmd == "card":
        r = set_card(argv[2], json.loads(sys.stdin.buffer.read().decode("utf-8") or "{}"))
        if r.get("ok"):
            write_view()
        sys.stdout.buffer.write(json.dumps(r, ensure_ascii=False).encode("utf-8"))
        return 0 if r.get("ok") else 3
    if cmd == "thread":
        return thread(argv[2] if len(argv) > 2 else "list", argv[3] if len(argv) > 3 else None,
                      sys.stdin.buffer.read().decode("utf-8") if len(argv) > 2 and argv[2] in ("add", "set") else "")
    if cmd == "prompt":
        e = next((x for x in read_threads()["entries"] if x["id"] == argv[2]), None)
        if e is None:
            print(f"no thread entry {argv[2]}")
            return 3
        sys.stdout.buffer.write(make_prompt(e).encode("utf-8"))
        return 0
    if cmd == "instructions":
        waiting = [e for e in read_threads()["entries"] if e["kind"] == "instruction" and e["status"] in ("asked", "queued")]
        for e in waiting:
            print(f"{e['id']}  {e.get('label_at') or ''} {e['anchor']}  ({e['status']}{', ' + e['error'] if e.get('error') else ''})")
            print(f"    {e['text']}")
        print(f"{len(waiting)} waiting. Read one with: prompt <id>; answer with: answer <id>  ({{\"reply\", \"operations\"}} on stdin)")
        return 0
    if cmd == "answer":
        a = json.loads(sys.stdin.buffer.read().decode("utf-8"))
        return thread("set", argv[2], json.dumps({"answer": {**a, "by": a.get("by", "agent session")}}))
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
