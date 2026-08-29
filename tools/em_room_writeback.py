#!/usr/bin/env python3
"""What it would cost to make each template hall's MAP be the room the museum builds.

2026-08-29, Palle: "can we make the move more natural somehow?" — the move being
from the layered deal to commons/maps/<Map>/map_data.json as the one truth.

THE MOVE IS NATURAL BECAUSE ITS TWO HALVES ARE INDEPENDENT.

    writing the room into a map        changes what the EDITORS show
    flipping the chapter to authored   changes what the MUSEUM builds

endless_museum.gd:6598 reads a map only for a plan row carrying authored == "map",
and 143 of 196 rows do not. So every room can be written back today and the museum
is untouched — the stubs simply stop being stubs on /map-builder, /map-studio and
/long-museum. The flip is then a separate per-chapter decision with its own bill,
and this prints that bill instead of guessing at it.

WHERE THE ROOM IS IN THE RECORD, and three ways to get it wrong. The engine writes
ada_run/em_layout_walk.json as it builds. Each hall's `cells` is the whole segment:

    rows  0 .. vestibule                 the vestibule (4)
    rows  vestibule .. +h-passage        THE ROOM  <- this is what a map owns
    rows  ... +passage                   the crossing, appended by _authored_passages
    rows  ... +porch, +court             the forecourt and the courtyard
    cols  0                              the skin column (cell_x0 == -1)
    cols  1 .. 1+w                       THE ROOM
    cols  1+w ..                         the gallery

  1. THE SKIN COLUMN. cell_x0 is -1 on 198 of 198 halls and every row is w+13 wide.
     Slicing cols [0, w) reproduces the engine's own `first_row` on ZERO halls;
     cols [1, 1+w) reproduces it on 143 of 143 templates.
  2. THE PASSAGE. `h` is the tile AFTER _authored_passages appended the crossing, so
     9 of a 30-row hall are passage. Writing all 30 bakes the crossing into the
     lesson map — the exact mistake Point_One made and had to have undone on
     2026-08-28, because a baked crossing cannot seam against the next hall.
  3. THE CELLS THAT NO LONGER EXIST. A stub map's own tokens were placed in a
     10x10 room. In the real room 18% of them land on a wall. Those are reported
     per hall, not silently dropped, because they are the hand's work.

This tool WRITES NOTHING it is not asked to. --audit produces one report file.

    python tools/em_room_writeback.py --audit
    python tools/em_room_writeback.py --audit --chapter=boolean_surfaces
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WALK = os.path.join(ROOT, "ada_run", "em_layout_walk.json")
PLAN = os.path.join(ROOT, "ada_run", "em_plan.json")
MAPS = os.path.join(ROOT, "commons", "maps")
OUT = os.path.join(ROOT, "doc", "reports", "em_room_writeback.json")

#: walk-grid cell -> is it floor. "#" is not-floor; ".", and the marks the engine
#: writes for a body standing there, are.
def is_floor(ch: str) -> bool:
    return ch != "#"


def load(p):
    with open(p, encoding="utf-8") as fh:
        return json.load(fh)


def room_of(rec: dict):
    """The hall's own rows and columns, cut out of the as-built segment grid."""
    cells = rec.get("cells") or []
    if not cells:
        return None
    vest = int(rec.get("vestibule", 4))
    passage = int(rec.get("passage") or 0)
    h = int(rec.get("h") or 0)
    w = int(rec.get("w") or 0)
    skin = -int(rec.get("cell_x0", -1))            # 1
    rows = [str(r) for r in cells[vest:vest + max(0, h - passage)]]
    if not rows or w <= 0:
        return None
    return [r[skin:skin + w] for r in rows]


def map_layers(name: str):
    p = os.path.join(MAPS, name, "map_data.json")
    if not os.path.exists(p):
        return None
    try:
        d = load(p)
    except Exception:
        return None
    return (d.get("layers") or {}), d


def main() -> int:
    ap = argparse.ArgumentParser(description="the bill for making a map be its room")
    ap.add_argument("--audit", action="store_true", help="measure and write the report")
    ap.add_argument("--chapter", default="", help="limit to one chapter")
    a = ap.parse_args()

    walk = load(WALK).get("halls", {})
    plan = load(PLAN).get("plans", [])
    by_map = {}
    for r in walk.values():
        m = str(r.get("map") or "")
        if m:
            by_map[m] = r

    halls = []
    for row in plan:
        seq = str(row.get("sequence") or "")
        name = str(row.get("map") or "")
        if not name or (a.chapter and seq != a.chapter):
            continue
        authored = str(row.get("authored") or "") == "map"
        rec = by_map.get(name)
        room = room_of(rec) if rec else None
        layers, doc = (map_layers(name) or ({}, {}))
        st = layers.get("structure") or []
        inter = layers.get("interactables") or []
        util = layers.get("utilities") or []
        map_cells = sum(len(r) for r in st)

        entry = {
            "chapter": seq, "map": name, "pearl": str(row.get("pearl") or ""),
            "authored": authored,
            "map_rows": len(st), "map_cols": (len(st[0]) if st else 0), "map_cells": map_cells,
            "walked": rec is not None,
        }
        if room:
            rw, rh = len(room[0]), len(room)
            entry.update({"room_rows": rh, "room_cols": rw, "room_cells": rw * rh,
                          "passage_rows": int(rec.get("passage") or 0),
                          "court": int(rec.get("court") or 0),
                          "porch": int(rec.get("porch") or 0),
                          "built_at": str(rec.get("built_at") or "")})
            # THE HAND'S WORK, checked against the room it would land in. A token
            # on a cell that is wall in the real room is not a detail — it is a
            # placement somebody made that this move would silently invalidate.
            lost_i, lost_u = [], []
            for z, r in enumerate(inter):
                for x, c in enumerate(r):
                    if not str(c).strip():
                        continue
                    if z >= rh or x >= rw or not is_floor(room[z][x]):
                        lost_i.append({"cell": [x, z], "token": str(c)[:40]})
            for z, r in enumerate(util):
                for x, c in enumerate(r):
                    if not str(c).strip():
                        continue
                    if z >= rh or x >= rw or not is_floor(room[z][x]):
                        lost_u.append({"cell": [x, z], "token": str(c)[:24]})
            entry["interactables"] = sum(1 for r in inter for c in r if str(c).strip())
            entry["utilities"] = sum(1 for r in util for c in r if str(c).strip())
            entry["interactables_on_a_wall"] = len(lost_i)
            entry["utilities_on_a_wall"] = len(lost_u)
            entry["lost_examples"] = (lost_i[:3] + lost_u[:3])
        halls.append(entry)

    tmpl = [h for h in halls if not h["authored"]]
    walked = [h for h in tmpl if h.get("walked") and h.get("room_cells")]
    unwalked = [h for h in tmpl if not (h.get("walked") and h.get("room_cells"))]

    print("THE BILL — writing each template hall's room into its own map\n")
    print("  halls in scope        : %d template (%d authored already, left alone)"
          % (len(tmpl), sum(1 for h in halls if h["authored"])))
    print("  the engine has walked : %d   (the other %d have no room to copy)"
          % (len(walked), len(unwalked)))
    if walked:
        grow = sum(h["room_cells"] - h["map_cells"] for h in walked)
        print("  cells the maps gain   : %d  (median map %d -> room %d)"
              % (grow,
                 sorted(h["map_cells"] for h in walked)[len(walked) // 2],
                 sorted(h["room_cells"] for h in walked)[len(walked) // 2]))
        li = sum(h.get("interactables_on_a_wall", 0) for h in walked)
        ti = sum(h.get("interactables", 0) for h in walked)
        lu = sum(h.get("utilities_on_a_wall", 0) for h in walked)
        tu = sum(h.get("utilities", 0) for h in walked)
        print("  hand tokens at risk   : %d of %d interactables (%.0f%%), %d of %d utilities (%.0f%%)"
              % (li, ti, 100.0 * li / max(1, ti), lu, tu, 100.0 * lu / max(1, tu)))
        print("                          (they sit where the real room has a wall)")
        print("  passage rows excluded : %d  (baking a crossing into a lesson map is"
              % sum(h.get("passage_rows", 0) for h in walked))
        print("                          the Point_One mistake, undone 2026-08-28)")

    print("\n  BY CHAPTER — cheapest first, by what a later flip would cost\n")
    print("  %-24s %5s %7s %7s %6s %6s" % ("chapter", "halls", "gain", "at-risk", "court", "walked"))
    per = {}
    for h in tmpl:
        c = per.setdefault(h["chapter"], {"n": 0, "gain": 0, "risk": 0, "court": 0, "walked": 0})
        c["n"] += 1
        if h.get("room_cells"):
            c["walked"] += 1
            c["gain"] += h["room_cells"] - h["map_cells"]
            c["risk"] += h.get("interactables_on_a_wall", 0) + h.get("utilities_on_a_wall", 0)
            c["court"] += h.get("court", 0)
    for name, c in sorted(per.items(), key=lambda kv: (kv[1]["court"], kv[1]["risk"])):
        print("  %-24s %5d %7d %7d %6d %6d" % (name, c["n"], c["gain"], c["risk"], c["court"], c["walked"]))

    print("\n  The museum does not change when these maps are written. endless_museum.gd:6598")
    print("  reads a map only for a plan row carrying authored == \"map\", and none of these")
    print("  carry it. The editors change; the built museum does not, until a chapter flips.")

    if a.audit:
        os.makedirs(os.path.dirname(OUT), exist_ok=True)
        with open(OUT, "w", encoding="utf-8") as fh:
            json.dump({"schema": "em_room_writeback/1", "halls": halls,
                       "by_chapter": per}, fh, indent=2)
            fh.write("\n")
        print("\n  wrote %s" % os.path.relpath(OUT, ROOT))
    else:
        print("\n  (pass --audit to write the per-hall report)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
