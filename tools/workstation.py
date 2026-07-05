#!/usr/bin/env python3
"""workstation.py — the cluster unit: a hero staged as a lab workstation.

The right model is a nested hierarchy, not a flat array. The 1D spine is only the
INDEX of heroes; each hero is a mindmap node that expands into a CLUSTER:

  hero (centre apparatus)
   ├─ children   — its concept-ladder: the same idea at small/medium/large/applied
   └─ props      — the lab vernacular that makes it read as a WORKING station
                   (gas cylinder on a cart, crate stack, stool, monitor shelf,
                    task light, extinguisher) — straight from the reference images.

That cluster, staged, is a lab workstation. A map-room is a hall of workstations;
a sequence is a necklace of halls. This builds ONE workstation for a hero so the
unit is concrete.

Usage: python tools/workstation.py --hero=distribution_sampler [--write]
"""
from __future__ import annotations

import json
import os
import sys
import urllib.request

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAPS_DIR = os.path.join(REPO, "commons", "maps")
LADDER = "http://localhost:3003/api/concept-ladder?id="

# the reference workstation's supporting cast (all confirmed in registry)
PROP_KIT = {
    "cylinder": "gas_canister",     # hazmat cylinder on the left
    "crates_a": "tech_crate",
    "crates_b": "cardboard_box",    # stacked boxes on the right
    "stool": "lab_stool",           # in front of the bench
    "shelf": "station_multiscreen", # monitor shelf behind the hero
    "light": "station_luminaire",   # task light over the hero
    "safety": "fire_extinguisher",  # on the wall, corner
}


def fetch_ladder(hero):
    try:
        d = json.load(urllib.request.urlopen(LADDER + hero, timeout=15))
        return d.get("tiers", {}) or {}
    except Exception as e:
        print(f"  (concept-ladder unavailable: {e})")
        return {}


def build(hero):
    tiers = fetch_ladder(hero)
    # children = the ladder minus the hero itself, one representative per tier
    def pick(t):
        xs = [x for x in tiers.get(t, []) if x != hero]
        return xs[0] if xs else None
    small = [x for x in tiers.get("small", []) if x != hero][:2]
    medium = pick("medium")
    large = pick("large")
    applied = pick("applied")

    W, H = 17, 17
    cx = W // 2
    gs = [["0"] * W for _ in range(H)]
    gu = [[" "] * W for _ in range(H)]
    gi = [[" "] * W for _ in range(H)]
    for r in range(2, H - 2):
        for c in range(2, W - 2):
            gs[r][c] = "2"                       # the floating lab-bay dais

    def put(tok, r, c, cfg=None):
        if 0 <= r < H and 0 <= c < W:
            gi[r][c] = tok + ("#" + "#".join(f"{k}:{v}" for k, v in cfg.items()) if cfg else "")

    # backdrop wall + the concept panel
    for c in (cx - 3, cx, cx + 3):
        put("station_wall", 3, c, {"width_cells": 3})
    put("station_panel", 2, cx, {"width_cells": 5, "header": hero.replace("_", " ").upper(),
        "lines": ["One workstation: the central apparatus, its ladder of variants, its lab cast.",
                  "The hero is a mindmap node — children and props are the cluster."]})
    put(PROP_KIT["shelf"], 4, cx + 1)            # monitor shelf behind

    # HERO — centre, on a stage, under the task light
    put("station_stage", 8, cx, {"width_cells": 3, "depth_cells": 3, "step_height": 0.18,
                                 "name_plate": hero.replace("_", " ")})
    put(hero, 8, cx)
    put(PROP_KIT["light"], 6, cx)                # luminaire over the hero

    # CHILDREN — the ladder, ringed around the hero (nearer = tighter kin)
    if medium:  # the bench version, at the hero's flank
        put("station_plinth", 8, cx - 3, {"width_cells": 2, "depth_cells": 1, "top_height": 0.95,
                                          "caption_text": medium.replace("_", " ")})
        put(medium, 8, cx - 3)
    if large:   # the room-scale version, set back
        put("station_stage", 5, cx - 3, {"width_cells": 3, "depth_cells": 3, "step_height": 0.18,
                                         "name_plate": large.replace("_", " ")})
        put(large, 5, cx - 3)
    if applied:  # the applied companion, the other flank
        put("station_plinth", 8, cx + 3, {"width_cells": 1, "depth_cells": 1, "top_height": 1.1,
                                          "cap_inset": 0.1, "caption_text": applied.replace("_", " ")})
        put(applied, 8, cx + 3)
    for i, s in enumerate(small):  # the small variants, micropodded up front
        put("station_micropod", 11, cx - 1 + i * 2,
            {"base_meters": 0.6, "cap_meters": 1.16, "top_height": 1.15,
             "caption_text": s.replace("_", " ")})
        put(s, 11, cx - 1 + i * 2)

    # PROPS — the lab cast that makes it a WORKING station (the reference vocabulary)
    put(PROP_KIT["cylinder"], 12, 3)             # hazmat cylinder-cart, left
    put(PROP_KIT["crates_a"], 12, W - 3)         # crate stack, right
    put(PROP_KIT["crates_b"], 13, W - 4)
    put(PROP_KIT["stool"], 12, cx)               # stool in front of the bench
    put(PROP_KIT["safety"], 4, W - 3)            # extinguisher, corner

    gu[H - 2][cx] = "sp"
    gu[2][W - 3] = "t"
    gs[2][W - 3] = "0"
    kids = [x for x in (medium, large, applied, *small) if x]
    return gs, gu, gi, W, H, kids


def main():
    args = sys.argv[1:]
    hero = next((a.split("=", 1)[1] for a in args if a.startswith("--hero=")), None)
    write = "--write" in args
    if not hero:
        print(__doc__)
        return 1
    gs, gu, gi, W, H, kids = build(hero)
    name = f"Workstation_{hero}"
    print(f"{name}: {W}x{H} — hero={hero}, children={kids}, "
          f"props={list(PROP_KIT.values())}")
    if not write:
        print("(dry run — pass --write)")
        return 0
    data = {"map_info": {"name": name, "lookup_name": name,
                         "title": f"{hero.replace('_', ' ')} — workstation",
                         "description": "The cluster unit: a hero staged as a lab workstation "
                                        "(hero + concept-ladder children + lab props).",
                         "version": "1.0", "format": "json",
                         "dimensions": {"width": W, "depth": H, "max_height": 3},
                         "metadata": {"difficulty": "research", "category": "workstation",
                                      "estimated_time": "1 min", "learning_objectives": ["cluster unit"]}},
            "utility_definitions": {"t": {"type": "teleporter", "name": "Exit", "description": "leave",
                                          "properties": {"action": "next_in_sequence"}}},
            "lighting": {"ambient_color": [0.38, 0.4, 0.48], "ambient_energy": 0.55,
                         "directional_light": {"enabled": True, "direction": [-0.4, -0.7, -0.4],
                                               "color": [0.9, 0.95, 1.0], "energy": 1.1}},
            "settings": {"cube_size": 1.0, "gutter": 0.0, "show_grid": True, "enable_physics": True,
                         "background": {"type": "sky", "color": [0.1, 0.12, 0.16]}},
            "layers": {"structure": gs, "utilities": gu, "interactables": gi}}
    d = os.path.join(MAPS_DIR, name)
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "map_data.json"), "w", encoding="utf-8") as f:
        json.dump(data, f, indent=1)
    print(f"wrote {d}/map_data.json")
    sys.path.insert(0, os.path.join(REPO, "tools"))
    from book_log import log_event
    log_event("room", f"workstation cluster built for {hero}: hero + {len(kids)} ladder children "
                      "+ lab prop cast — the mindmap node made physical")
    return 0


if __name__ == "__main__":
    sys.exit(main())
