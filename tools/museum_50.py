#!/usr/bin/env python3
"""FIFTY MUSEUMS, AND WHERE A THING COULD STAND IN EACH.

2026-08-25, Palle: "make 50 museums from the one we have and from the
templates... Then look at each museum and define a good spot for potential
artifacts, different footprints, space, nice setups, different variants for
every museum."

The material already exists and nobody had walked it: commons/data/
template_patterns.json holds 182 patterns, 31 of them whole museum plans
drawn from real buildings — Uffizi, Guggenheim, Mezquita, Caracalla, Le
Thoronet, Katsura, Soane, Labrouste. This pairs each plan with a VARIANT that
decides what kind of room it wants to be, and then measures where an artifact
could actually stand.

    python tools/museum_50.py                 # writes commons/data/museum_50.json
    python tools/museum_50.py --list          # the roster, no write

SLOTS ARE MEASURED, NOT PLACED. For every free cell the tool asks four
questions the corpus's own spatial_needs vocabulary already asks — how much
clear square fits here, is there a wall behind it, is it enclosed on three
sides, is it isolated — and answers with a kind and a footprint:

  hero    the largest clear square in the room, 3x3 or better
  plinth  an island: clear on all four sides, so it is walked AROUND
  alcove  walls on three sides — a niche, which wants a made thing not a demo
  wall    a wall behind it, which is what a hung or framed piece needs
  pair    two cells flanking the walk line, for a thing that argues with itself
  field   open floor with room, the rest

The VARIANT then decides which of those a museum publishes. A cabinet museum
keeps its alcoves and ignores its field; a free-plan hall keeps one hero and
its islands and refuses the walls. That is what makes fifty rooms fifty
different offers rather than one algorithm run fifty times.

NOTHING HERE PLACES AN ARTIFACT. It says where one COULD go and how big it
may be — the placing is a design act, and a tool that did it automatically
would be answering a question nobody asked.
"""
from __future__ import annotations

import argparse
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# what a variant keeps, and what it is for. Fifty museums need more than one
# idea of what a room offers, and these are the seven the plans support.
VARIANTS = {
    "enfilade":  {"keep": ["hero", "wall", "pair"], "max": 14,
                  "why": "a walk down a spine: one hero at the end of the vista, the rest hung on the walls you pass"},
    "cabinet":   {"keep": ["alcove", "wall"], "max": 18,
                  "why": "Soane's answer — every niche holds one made thing, and nothing stands in the middle"},
    "free_plan": {"keep": ["hero", "plinth"], "max": 9,
                  "why": "Mies: the floor is continuous, so a thing is an island you walk around, never a picture on a wall"},
    "field":     {"keep": ["plinth", "field"], "max": 24,
                  "why": "Dia:Beacon — many equal things across an open floor, no hierarchy and no centre"},
    "hypostyle": {"keep": ["pair", "field"], "max": 20,
                  "why": "the Mezquita: the columns make the rhythm, so things come in pairs between them"},
    "crypt":     {"keep": ["alcove", "pair"], "max": 12,
                  "why": "a narrow run where the walls close in — what you meet, you meet at arm's length"},
    "drum":      {"keep": ["hero"], "max": 3,
                  "why": "the panorama: ONE thing, and the room is the frame around it"},
}

WALL = ("4", "w")
HOLE = ("0",)


def kind_of(v):
    s = str(v).strip()
    if s == "" or s in HOLE:
        return "hole"
    if s in WALL or s.startswith("4"):
        return "wall"
    if s.startswith("p") or s.startswith("2") or s.startswith("3"):
        return "podium"
    return "floor"


def free_square(grid, x, z, cap=5):
    """The largest clear square with its near corner at (x, z)."""
    h = len(grid)
    w = len(grid[0]) if h else 0
    best = 0
    for n in range(1, cap + 1):
        if x + n > w or z + n > h:
            break
        ok = True
        for dz in range(n):
            for dx in range(n):
                if grid[z + dz][x + dx] != "floor":
                    ok = False
                    break
            if not ok:
                break
        if not ok:
            break
        best = n
    return best


def pack(x0, z0, n, k, gap=1):
    """Where k-sized things sit inside an n-square, with `gap` cells between
    them so they read as separate objects rather than one lump. Centred, so a
    subdivision sits in the middle of the space it was given."""
    step = k + gap
    count = (n + gap) // step
    if count < 1 or k > n:
        return []
    used = count * step - gap
    off = (n - used) // 2
    return [(x0 + off + i * step, z0 + off + j * step)
            for j in range(count) for i in range(count)]


def capacity(x, z, n):
    """WHAT ELSE FITS IN HERE (2026-08-25, Palle: "can we have some system
    where we know if there is 5 there can be room for at least 2 other
    artifacts inside?").

    A footprint is not one offer, it is a menu. A 5x5 is one 5x5 thing, OR
    four 2x2 things with a walking gap, OR nine 1x1 — and, most usefully, a
    3x3 with four 1x1 attendants in its corners. Answering by construction
    beats answering by eye: every option below is a real list of cells, so a
    placer can take one and a person can see it."""
    holds = {}
    for k in range(1, n + 1):
        cells = pack(x, z, n, k)
        if cells:
            holds[str(k)] = len(cells)
    comps = []
    if n >= 1:
        comps.append({"name": "one", "items": [{"x": x, "z": z, "fp": n}]})
    for k in range(n - 1, 0, -1):
        cells = pack(x, z, n, k)
        if len(cells) >= 2:
            comps.append({"name": "%d x %dx%d" % (len(cells), k, k),
                          "items": [{"x": cx, "z": cz, "fp": k} for cx, cz in cells]})
            break
    # HERO AND ATTENDANTS: the big one in the middle, small ones in the corners
    # of the ring it leaves. Only when the ring is a full cell wide, otherwise
    # the attendants are touching the hero and it reads as one object.
    if n >= 4:
        inner = n - 2
        items = [{"x": x + 1, "z": z + 1, "fp": inner}]
        for cx, cz in [(x, z), (x + n - 1, z), (x, z + n - 1), (x + n - 1, z + n - 1)]:
            items.append({"x": cx, "z": cz, "fp": 1})
        comps.append({"name": "hero %dx%d + 4 attendants" % (inner, inner), "items": items})
    best_other = max([c for k, c in holds.items() if int(k) < n] or [0])
    return {"holds": holds, "compositions": comps, "also_holds": best_other}


def capacity_run(n, gap=1):
    """A run is a menu too, in one dimension. A 9-long wall takes one 9-long
    frieze, or three 2-long pieces with a walking gap between them."""
    holds, comps = {}, [{"name": "one %d-long" % n, "items": [{"off": 0, "len": n}]}]
    for k in range(1, n + 1):
        step = k + gap
        c = (n + gap) // step
        if c >= 1:
            holds[str(k)] = c
    for k in range(n - 1, 0, -1):
        step = k + gap
        c = (n + gap) // step
        if c >= 2:
            used = c * step - gap
            off = (n - used) // 2
            comps.append({"name": "%d x %d-long" % (c, k),
                          "items": [{"off": off + i * step, "len": k} for i in range(c)]})
            break
    return holds, comps


def runs_for(grid):
    """CONTIGUOUS FLOOR ALONG A WALL — the other currency (2026-08-25). 23% of
    the corpus is oblong and those pieces are RUNS, things that lie along a
    wall: 1x2, 1x6, 1x9. A square finder reads a 1x6 frieze as six separate
    1x1 slots, which is the wrong unit and hides what the room can take.

    depth is how far the free floor reaches back from the wall, so a run
    carries both numbers a piece needs: how long it may be, how deep it may sit."""
    h = len(grid)
    w = len(grid[0]) if h else 0
    out = []

    def depth_at(x, z, dx, dz):
        n = 0
        cx, cz = x + dx, z + dz
        while 0 <= cx < w and 0 <= cz < h and grid[cz][cx] == "floor" and n < 5:
            n += 1
            cx += dx
            cz += dz
        return max(1, n)

    for z in range(1, h - 1):
        for side in (-1, 1):
            run = []
            for x in range(1, w):
                ok = (x < w - 1 and grid[z][x] == "floor" and grid[z + side][x] == "wall")
                if ok:
                    run.append(x)
                    continue
                if len(run) >= 2:
                    out.append({"kind": "run", "x": run[0], "z": z, "dir": "x",
                                "len": len(run), "depth": min(depth_at(cx0, z, 0, -side)
                                                              for cx0 in run)})
                run = []
    for x in range(1, w - 1):
        for side in (-1, 1):
            run = []
            for z in range(1, h):
                ok = (z < h - 1 and grid[z][x] == "floor" and grid[z][x + side] == "wall")
                if ok:
                    run.append(z)
                    continue
                if len(run) >= 2:
                    out.append({"kind": "run", "x": x, "z": run[0], "dir": "z",
                                "len": len(run), "depth": min(depth_at(x, cz0, -side, 0)
                                                              for cz0 in run)})
                run = []
    for r in out:
        holds, comps = capacity_run(r["len"])
        r["holds"] = holds
        r["compositions"] = comps
        r["also_holds"] = max([c for k, c in holds.items() if int(k) < r["len"]] or [0])
        r["fp"] = r["depth"]
    return out


def slots_for(tile):
    """Every place a thing could stand, with a kind and a footprint."""
    grid = [[kind_of(c) for c in row] for row in tile]
    h = len(grid)
    w = len(grid[0]) if h else 0
    mid = (w - 1) / 2.0
    out = []
    hero_best = (0, None)
    for z in range(1, h - 1):
        for x in range(1, w - 1):
            if grid[z][x] != "floor":
                continue
            n4 = [grid[z - 1][x], grid[z + 1][x], grid[z][x - 1], grid[z][x + 1]]
            walls = sum(1 for v in n4 if v == "wall")
            floors = sum(1 for v in n4 if v == "floor")
            fp = free_square(grid, x, z)
            kind = "field"
            if walls >= 3:
                kind = "alcove"
            elif walls >= 1:
                kind = "wall"
            elif floors == 4 and free_square(grid, x - 1, z - 1) >= 3:
                kind = "plinth"
            if kind == "field" and abs(x - mid) <= 1.5 and fp >= 2:
                kind = "pair"
            slot = {"x": x, "z": z, "kind": kind, "fp": fp, "wall_backing": walls >= 1}
            slot.update(capacity(x, z, fp))
            out.append(slot)
            if fp > hero_best[0]:
                hero_best = (fp, (x, z))
    if hero_best[1] is not None and hero_best[0] >= 3:
        hx, hz = hero_best[1]
        for s in out:
            if s["x"] == hx and s["z"] == hz:
                s["kind"] = "hero"
    return out, grid


def box_of(s):
    """Every slot as a rectangle, so a run and a square can be compared."""
    if s["kind"] == "run":
        if s["dir"] == "x":
            return (s["x"], s["z"], s["len"], 1)
        return (s["x"], s["z"], 1, s["len"])
    return (s["x"], s["z"], s["fp"], s["fp"])


def hits(a, b):
    ax, az, aw, ad = a
    bx, bz, bw, bd = b
    return not (ax + aw <= bx or bx + bw <= ax or az + ad <= bz or bz + bd <= az)


def thin(slots, runs, variant):
    """Publish only what this variant is interested in, spread out so two slots
    never sit on top of each other. A variant that keeps `wall` gets RUNS
    instead of per-cell wall slots — a 1x6 frieze is one offer, not six."""
    spec = VARIANTS[variant]
    pool = [s for s in slots if s["kind"] in spec["keep"] and s["kind"] != "wall"]
    if "wall" in spec["keep"]:
        pool += runs
    pool.sort(key=lambda s: (-{"hero": 6, "run": 5, "alcove": 4, "plinth": 3,
                               "pair": 2}.get(s["kind"], 0),
                             -(s.get("len", 0)), -s["fp"], s["z"], s["x"]))
    taken, boxes = [], []
    for s in pool:
        if len(taken) >= spec["max"]:
            break
        b = box_of(s)
        if any(hits(b, t) for t in boxes):
            continue
        taken.append(s)
        boxes.append(b)
    return taken


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--out", default="commons/data/museum_50.json")
    ap.add_argument("--svg", default="ada_run/museum_50.svg",
                    help="a contact sheet of all fifty, slots drawn at their footprint")
    args = ap.parse_args()

    pats = json.load(open(os.path.join(ROOT, "commons", "data", "template_patterns.json"),
                          encoding="utf-8"))["patterns"]
    # the whole plans, biggest first — the bays and lattices are ingredients,
    # not museums, so they are only drawn on when the named plans run out
    plans = [(k, v) for k, v in pats.items()
             if v.get("mode") == "stamp" and not k.startswith(("lattice:", "beat:"))]
    named = [(k, v) for k, v in plans if not k.startswith("bay:")]
    bays = [(k, v) for k, v in plans if k.startswith("bay:")]
    named.sort(key=lambda t: -(t[1].get("w", 0) * t[1].get("h", 0)))
    bays.sort(key=lambda t: -(t[1].get("w", 0) * t[1].get("h", 0)))
    roster = named + bays

    order = list(VARIANTS.keys())
    museums = []
    for i, (key, pat) in enumerate(roster):
        if len(museums) >= 50:
            break
        tile = pat.get("tile") or []
        if not tile or len(tile) < 6:
            continue
        variant = order[i % len(order)]
        slots, grid = slots_for(tile)
        runs = runs_for(grid)
        pub = thin(slots, runs, variant)
        if not pub:
            continue
        floor = sum(1 for r in grid for c in r if c == "floor")
        museums.append({
            "id": "m%02d" % (len(museums) + 1),
            "pattern": key,
            "label": pat.get("label", key),
            "variant": variant,
            "why": VARIANTS[variant]["why"],
            "w": len(tile[0]), "h": len(tile),
            "floor": floor,
            "tile": tile,
            "slots": pub,
            "footprints": sorted({s["fp"] for s in pub}, reverse=True),
            "biggest": max((s["fp"] for s in pub), default=0),
            "longest_run": max((s.get("len", 0) for s in pub), default=0),
            "runs": sum(1 for s in pub if s["kind"] == "run"),
            "divisible": sum(1 for s in pub if s.get("also_holds", 0) >= 2),
            "counts": {k: sum(1 for s in pub if s["kind"] == k)
                       for k in ("hero", "run", "alcove", "plinth", "pair", "wall", "field")
                       if any(s["kind"] == k for s in pub)},
        })

    print("FIFTY MUSEUMS — %d built from %d named plans + %d bays\n" % (
        len(museums), len(named), len(bays)))
    for m in museums:
        print("  %-4s %-38s %-10s %2dx%-3d %2d slot(s) to %dx%d  %2d divisible  %s" % (
            m["id"], m["pattern"][:38], m["variant"], m["w"], m["h"],
            len(m["slots"]), m["biggest"], m["biggest"], m["divisible"],
            " ".join("%s:%d" % (k, v) for k, v in m["counts"].items())))
    if not args.list:
        dest = os.path.join(ROOT, args.out)
        with open(dest, "w", encoding="utf-8") as fh:
            json.dump({"_readme": "Fifty museums with measured artifact slots. "
                       "Written by tools/museum_50.py from commons/data/template_patterns.json. "
                       "A slot says where a thing COULD stand and how big it may be; it places nothing.",
                       "variants": VARIANTS, "museums": museums}, fh, indent=1)
        print("\n  -> %s (%d museums, %d slots)" % (
            args.out, len(museums), sum(len(m["slots"]) for m in museums)))
        if args.svg:
            _sheet(museums, os.path.join(ROOT, args.svg))
            print("  -> %s" % args.svg)
    return 0


KIND_COLOR = {"hero": "#fbbf24", "run": "#f472b6", "alcove": "#c084fc",
              "plinth": "#34d399", "pair": "#38bdf8", "wall": "#f472b6",
              "field": "#94a3b8"}


def _fill(v):
    s = str(v).strip()
    if s == "" or s == "0":
        return "#0b0b0f"
    if s.startswith("4") or s == "w":
        return "#3b3b45"
    if s.startswith("p") or s.startswith("2") or s.startswith("3"):
        return "#8a7f6a"
    return "#d8d4cc"


def _sheet(museums, dest, cell=5, cols=10):
    """All fifty on one page. A slot is drawn AT ITS FOOTPRINT, so the picture
    answers the question that was actually asked — how much room is on offer —
    and not merely where a dot goes."""
    colw = 17 * cell + 24
    rowh = max(m["h"] for m in museums) * cell + 42
    W = cols * colw + 24
    H = ((len(museums) + cols - 1) // cols) * rowh + 96
    out = ['<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">'
           % (W, H, W, H),
           '<rect width="100%" height="100%" fill="#101014"/>',
           '<text x="14" y="26" fill="#e8e6e1" font-family="ui-monospace,monospace" font-size="16">'
           'fifty museums &#183; %d measured slots &#183; each slot drawn at its FOOTPRINT</text>'
           % sum(len(m["slots"]) for m in museums)]
    lx = 14
    for k, c in KIND_COLOR.items():
        out.append('<rect x="%d" y="38" width="9" height="9" fill="%s" fill-opacity="0.22" stroke="%s"/>'
                   % (lx, c, c))
        out.append('<text x="%d" y="47" fill="%s" font-family="ui-monospace,monospace" '
                   'font-size="10">%s</text>' % (lx + 13, c, k))
        lx += 26 + len(k) * 6
    for i, m in enumerate(museums):
        ox = 14 + (i % cols) * colw
        oy = 66 + (i // cols) * rowh
        out.append('<text x="%d" y="%d" fill="#cfcfd6" font-family="ui-monospace,monospace" '
                   'font-size="9">%s %s</text>'
                   % (ox, oy, m["id"], m["pattern"].replace("bay:", "")[:24]))
        out.append('<text x="%d" y="%d" fill="#7dd3fc" font-family="ui-monospace,monospace" '
                   'font-size="8">%s &#183; %dx%d &#183; %d slots to %dx%d</text>'
                   % (ox, oy + 10, m["variant"], m["w"], m["h"], len(m["slots"]),
                      m["biggest"], m["biggest"]))
        top = oy + 16
        for z, row in enumerate(m["tile"]):
            for x, v in enumerate(row):
                out.append('<rect x="%d" y="%d" width="%d" height="%d" fill="%s"/>'
                           % (ox + x * cell, top + z * cell, cell, cell, _fill(v)))
        for s in m["slots"]:
            c = KIND_COLOR.get(s["kind"], "#94a3b8")
            run = s["kind"] == "run"
            if run:
                bw = (s["len"] if s["dir"] == "x" else 1) * cell
                bh = (1 if s["dir"] == "x" else s["len"]) * cell
            else:
                bw = bh = max(1, int(s["fp"])) * cell
            out.append('<rect x="%d" y="%d" width="%d" height="%d" fill="%s" fill-opacity="0.22" '
                       'stroke="%s" stroke-width="0.8"/>'
                       % (ox + s["x"] * cell, top + s["z"] * cell, bw, bh, c, c))
            # WHAT ELSE FITS: the last composition drawn as inner outlines, so a
            # big slot shows on the sheet that it is also two or four smaller
            # offers and not only one large one
            comps = s.get("compositions") or []
            if s.get("also_holds", 0) >= 2 and len(comps) > 1:
                for it in comps[-1]["items"]:
                    if run:
                        # a run's items are an OFFSET and a LENGTH along it
                        if s["dir"] == "x":
                            ix, iz = s["x"] + int(it["off"]), s["z"]
                            iw, ih = int(it["len"]) * cell, cell
                        else:
                            ix, iz = s["x"], s["z"] + int(it["off"])
                            iw, ih = cell, int(it["len"]) * cell
                    else:
                        ix, iz = it["x"], it["z"]
                        iw = ih = max(1, int(it["fp"])) * cell
                    out.append('<rect x="%d" y="%d" width="%d" height="%d" fill="none" '
                               'stroke="%s" stroke-width="0.5" stroke-opacity="0.85"/>'
                               % (ox + ix * cell, top + iz * cell, iw, ih, c))
    out.append("</svg>")
    with open(dest, "w", encoding="utf-8") as fh:
        fh.write("\n".join(out))


if __name__ == "__main__":
    sys.exit(main())
