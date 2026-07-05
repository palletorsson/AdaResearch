#!/usr/bin/env python3
"""hall.py — the fused room composer: a map-room as a HALL OF WORKSTATIONS (R-016).

Fuses the three tools:
  dollhouse   the room is the MAP (R-015)
  workstation the hero is a CLUSTER — children + lab-prop cast
  rigger      the relations run UNDER the floor (run after, separately)

A map's roster is grouped into workstations; each is staged as a tight lab bench
(hero centre on a stage under a task light, children on flanking plinths, the lab
cast — cylinder, crates, stool, monitor shelf, extinguisher — packed around). The
workstations flank a central aisle you walk. Floor stays height 1 (a walkable
hall, no dais-ramp problem); heroes rise on their own stage props.

Usage:
  python tools/hall.py --seq=randomness --write        # every map -> a hall
  python tools/hall.py --maps=Random_Cubes --write
Then wire the glue:  python tools/rigger.py --map=Hall_<Map> --seq=<seq> --write
"""
from __future__ import annotations

import json
import math
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SIZES = os.path.join(REPO, "commons", "data", "artifact_sizes.json")
MAPS_DIR = os.path.join(REPO, "commons", "maps")
SEQ_DIR = os.path.join(REPO, "commons", "maps", "sequences")
SKIP = {"dark_sphere", "lab_room", "catalyst_pickup"}
PROPS = {"cyl": "gas_canister", "crate": "tech_crate", "box": "cardboard_box",
         "stool": "lab_stool", "shelf": "station_multiscreen",
         "light": "station_luminaire", "safety": "fire_extinguisher"}

WS_W, WS_D = 9, 7          # a workstation's footprint (cols x rows)
AISLE = 3

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass


def load_json(p):
    try:
        with open(p, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def roster(map_name, sizes):
    md = load_json(os.path.join(MAPS_DIR, map_name, "map_data.json"))
    if not md:
        return None
    seen = []
    for row in md["layers"]["interactables"]:
        for c in row:
            n = str(c).split("#")[0].split(":")[0].strip()
            if n and n not in ("", " ", "0") and n not in SKIP and n not in seen:
                seen.append(n)
    return [(n, float((sizes.get(n) or {}).get("base_m", 1.0) or 1.0)) for n in seen] or None


def group_workstations(arts):
    """Chunk the roster into workstations; hero = biggest in each chunk."""
    arts = sorted(arts, key=lambda a: -a[1])
    n_ws = max(1, math.ceil(len(arts) / 6))
    chunks = [[] for _ in range(n_ws)]
    for i, a in enumerate(arts):          # deal round-robin so heroes spread
        chunks[i % n_ws].append(a)
    return [(c[0][0], [x[0] for x in c[1:]]) for c in chunks if c]


def stamp_workstation(gi, r0, c0, hero, children, header):
    """Stamp one tight lab bench into gi with top-left at (r0,c0)."""
    cw = c0 + WS_W // 2

    def put(tok, r, c, cfg=None):
        if 0 <= r < len(gi) and 0 <= c < len(gi[0]) and str(gi[r][c]).strip() in ("", " "):
            gi[r][c] = tok + ("#" + "#".join(f"{k}:{v}" for k, v in cfg.items()) if cfg else "")

    # back: wall + concept panel + monitor shelf
    put("station_wall", r0, cw, {"width_cells": 3})
    put("station_panel", r0, cw - 1, {"width_cells": 3, "header": header,
        "lines": ["The central apparatus, its ladder of variants, its lab cast.",
                  "One workstation — a node of the research made physical."]})
    put(PROPS["shelf"], r0 + 1, cw + 2)
    put(PROPS["safety"], r0, c0 + WS_W - 1)
    # hero centre on a stage, under the task light
    put(PROPS["light"], r0 + 2, cw)
    put("station_stage", r0 + 3, cw, {"width_cells": 2, "depth_cells": 2, "step_height": 0.18,
                                      "name_plate": hero.replace("_", " ")})
    put(hero, r0 + 3, cw)
    # children flanking (plinths near, micropods for the little ones)
    slots = [(r0 + 3, cw - 2, "plinth"), (r0 + 3, cw + 2, "plinth"),
             (r0 + 1, cw - 2, "micropod"), (r0 + 5, cw - 1, "micropod"),
             (r0 + 5, cw + 1, "micropod")]
    for i, ch in enumerate(children[:5]):
        r, c, kind = slots[i]
        if kind == "plinth":
            put("station_plinth", r, c, {"width_cells": 1, "depth_cells": 1, "top_height": 1.05,
                                         "cap_inset": 0.1, "caption_text": ch.replace("_", " ")})
        else:
            put("station_micropod", r, c, {"base_meters": 0.6, "cap_meters": 1.16,
                                           "top_height": 1.15, "caption_text": ch.replace("_", " ")})
        put(ch, r, c)
    # the lab cast, packed at the edges
    put(PROPS["cyl"], r0 + 5, c0)
    put(PROPS["crate"], r0 + 5, c0 + WS_W - 1)
    put(PROPS["box"], r0 + 6, c0 + WS_W - 2)
    put(PROPS["stool"], r0 + 6, cw)


def build(map_name, sizes):
    arts = roster(map_name, sizes)
    if not arts:
        return None
    ws = group_workstations(arts)
    per_side = math.ceil(len(ws) / 2)
    cols = WS_W + 1 + AISLE + 1 + WS_W + 4
    rows = per_side * (WS_D + 2) + 6
    aisle_c = 2 + WS_W + 1 + AISLE // 2
    gs = [["1"] * cols for _ in range(rows)]      # walkable floor, height 1
    gu = [[" "] * cols for _ in range(rows)]
    gi = [[" "] * cols for _ in range(rows)]

    for i, (hero, children) in enumerate(ws):
        side = i % 2
        row_i = i // 2
        r0 = 3 + row_i * (WS_D + 2)
        c0 = 2 if side == 0 else aisle_c + AISLE // 2 + 1
        stamp_workstation(gi, r0, c0, hero, children, map_name.replace("_", " ").upper())

    gu[rows - 2][aisle_c] = "sp"
    gu[1][aisle_c] = "t"
    gs[1][aisle_c] = "0"
    return {
        "map_info": {"name": f"Hall_{map_name}", "lookup_name": f"Hall_{map_name}",
                     "title": f"{map_name.replace('_', ' ')} — hall of workstations",
                     "description": f"R-016: {map_name} as a hall of {len(ws)} workstation(s) — "
                                    "each hero a cluster of children + lab props, along a walked aisle.",
                     "version": "1.0", "format": "json",
                     "dimensions": {"width": cols, "depth": rows, "max_height": 3},
                     "metadata": {"difficulty": "intermediate", "category": "hall",
                                  "estimated_time": "3 min",
                                  "learning_objectives": ["hall of workstations"]}},
        "utility_definitions": {"t": {"type": "teleporter", "name": "Next", "description": "next room",
                                      "properties": {"action": "next_in_sequence"}}},
        "lighting": {"ambient_color": [0.36, 0.39, 0.46], "ambient_energy": 0.5,
                     "directional_light": {"enabled": True, "direction": [-0.4, -0.7, -0.4],
                                           "color": [0.88, 0.94, 1.0], "energy": 1.1}},
        "settings": {"cube_size": 1.0, "gutter": 0.0, "show_grid": True, "enable_physics": True,
                     "background": {"type": "sky", "color": [0.09, 0.11, 0.15]}},
        "layers": {"structure": gs, "utilities": gu, "interactables": gi},
    }, len(ws)


def seq_maps(seq):
    d = load_json(os.path.join(SEQ_DIR, f"{seq}.json")) or {}
    s = d.get("sequences")
    sd = (s[0] if isinstance(s, list) and s else
          next(iter(s.values())) if isinstance(s, dict) and s else d)
    return sd.get("maps", []) or []


def main():
    args = sys.argv[1:]
    write = "--write" in args
    seq = next((a.split("=", 1)[1] for a in args if a.startswith("--seq=")), "")
    maps_arg = next((a.split("=", 1)[1] for a in args if a.startswith("--maps=")), "")
    maps = seq_maps(seq) if seq else [m.strip() for m in maps_arg.split(",") if m.strip()]
    if not maps:
        print(__doc__)
        return 1
    sizes = (load_json(SIZES) or {}).get("sizes") or {}
    made = []
    for m in maps:
        r = build(m, sizes)
        if not r:
            print(f"  {m}: no artifacts — skipped")
            continue
        data, nws = r
        print(f"  Hall_{m}: {data['map_info']['dimensions']['width']}x"
              f"{data['map_info']['dimensions']['depth']}  {nws} workstation(s)")
        if write:
            d = os.path.join(MAPS_DIR, data["map_info"]["name"])
            os.makedirs(d, exist_ok=True)
            with open(os.path.join(d, "map_data.json"), "w", encoding="utf-8") as f:
                json.dump(data, f, indent=1)
            made.append(data["map_info"]["name"])
    if made:
        sys.path.insert(0, os.path.join(REPO, "tools"))
        from book_log import log_event
        log_event("room", f"{seq or 'maps'} composed as halls of workstations (R-016): "
                          f"{len(made)} rooms — dollhouse+workstation+rigger fused")
    if not write:
        print("(dry run — pass --write)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
