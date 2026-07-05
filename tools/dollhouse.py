#!/usr/bin/env python3
"""dollhouse.py — research mode: free-assemble each map's artifacts as a contained
vitrine-object (the /surreal-lab-gallery pattern, at room scale).

Production (creator_walk) makes ONE canonical room per chapter by rules. This is
the opposite: many small doll houses — one per MAP — freely composed, so we can
put them side by side, rate them, and DISTILL what coheres back into the rules.
The unit is a raised dais (a floating diorama), the map's real artifacts arranged
as a specimen composition: hero on a back riser, the rest laddered small->large
in a front arc, each on scale-matched footing, a short curved backwall as vitrine.

The learning is the comparison, not any single house. Rate them, distill the
grammar, feed it to creator_walk.

Usage:
  python tools/dollhouse.py --maps=Random_Walk,Random_Gaussian,Random_Definition --write
Output: Dollhouse_<Map> maps + book-log entry.
"""
from __future__ import annotations

import json
import math
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SIZES = os.path.join(REPO, "commons", "data", "artifact_sizes.json")
MAPS_DIR = os.path.join(REPO, "commons", "maps")
# ambient/props to drop from the composition (qfep_signal ambient set + fillers)
SKIP = {"dark_sphere", "lab_room", "catalyst_pickup", "science_screen"}

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


def footing_for(base):
    if base < 1.0:
        return ("station_micropod", 1.15, {"base_meters": 0.6, "cap_meters": 1.16, "top_height": 1.15})
    if base < 3.0:
        return ("station_plinth", 1.1, {"width_cells": 1, "depth_cells": 1, "top_height": 1.1, "cap_inset": 0.1})
    return ("station_stage", 0.18, {"width_cells": min(4, int(math.ceil(base))),
                                    "depth_cells": min(4, int(math.ceil(base))), "step_height": 0.18})


def build(map_name, sizes):
    md = load_json(os.path.join(MAPS_DIR, map_name, "map_data.json"))
    if not md:
        return None
    seen = []
    for row in md["layers"]["interactables"]:
        for c in row:
            n = str(c).split("#")[0].split(":")[0].strip()
            if n and n not in ("", " ", "0") and n not in SKIP and n not in seen:
                seen.append(n)
    arts = [(n, float((sizes.get(n) or {}).get("base_m", 1.0) or 1.0)) for n in seen]
    if not arts:
        return None
    hero = max(arts, key=lambda a: a[1])
    rest = sorted([a for a in arts if a != hero], key=lambda a: a[1])   # small -> large

    # a compact square dais sized to the roster
    span = max(7, len(rest) * 2 + 1, int(math.ceil(hero[1])) + 4)
    cols = span + 4
    rows = span + 6
    cx = cols // 2
    gs = [["0"] * cols for _ in range(rows)]     # void surround — the diorama floats
    gu = [[" "] * cols for _ in range(rows)]
    gi = [[" "] * cols for _ in range(rows)]
    # raise the dais (height 2) as a bordered platform
    for r in range(2, rows - 2):
        for c in range(2, cols - 2):
            gs[r][c] = "2"

    def place(token, r, c, cfg=None):
        if 0 <= r < rows and 0 <= c < cols:
            gi[r][c] = token + ("#" + "#".join(f"{k}:{v}" for k, v in cfg.items()) if cfg else "")

    # curved backwall: three station_wall segments across the back
    back_r = 3
    for c in (cx - 3, cx, cx + 3):
        place("station_wall", back_r, c, {"width_cells": 3})
    place("station_panel", back_r - 1 if back_r > 0 else back_r, cx,
          {"width_cells": 4, "header": map_name.replace("_", " ").upper(),
           "lines": ["A doll house: this map's artifacts, freely re-assembled as one specimen.",
                     "Rate it against its siblings; distil what coheres."]})

    # hero on a back riser, center
    hf, hy, hcfg = footing_for(hero[1])
    hr = back_r + 3
    place(hf, hr, cx, hcfg)
    place(hero[0], hr, cx)

    # the rest laddered small->large in a front arc
    n = len(rest)
    arc_r = rows - 4
    for i, (name, base) in enumerate(rest):
        frac = (i + 0.5) / n
        c = 3 + int(frac * (cols - 6))
        r = arc_r - int(abs(frac - 0.5) * 4)          # gentle arc, ends pulled back
        f, y, cfg = footing_for(base)
        cap = dict(cfg); cap["caption_text"] = name.replace("_", " ")
        place(f, r, c, cap)
        place(name, r, c)

    gu[rows - 2][cx] = "sp"
    gu[2][cx + (cols // 2 - 3)] = "t"
    gs[2][cx + (cols // 2 - 3)] = "0"

    return {
        "map_info": {"name": f"Dollhouse_{map_name}", "lookup_name": f"Dollhouse_{map_name}",
                     "title": f"Doll house — {map_name.replace('_', ' ')}",
                     "description": f"Research: {map_name}'s artifacts freely re-assembled as a "
                                    "contained vitrine specimen. Rate against siblings; distil.",
                     "version": "1.0", "format": "json",
                     "dimensions": {"width": cols, "depth": rows, "max_height": 3},
                     "metadata": {"difficulty": "research", "category": "dollhouse",
                                  "estimated_time": "1 min", "learning_objectives": ["composition grammar"]}},
        "utility_definitions": {"t": {"type": "teleporter", "name": "Exit", "description": "leave",
                                      "properties": {"action": "next_in_sequence"}}},
        "lighting": {"ambient_color": [0.42, 0.42, 0.5], "ambient_energy": 0.7,
                     "directional_light": {"enabled": True, "direction": [-0.4, -0.7, -0.4],
                                           "color": [1.0, 0.96, 0.9], "energy": 1.2}},
        "settings": {"cube_size": 1.0, "gutter": 0.0, "show_grid": True, "enable_physics": True,
                     "background": {"type": "sky", "color": [0.18, 0.16, 0.28]}},
        "layers": {"structure": gs, "utilities": gu, "interactables": gi},
    }, hero[0], len(rest) + 1


def main():
    args = sys.argv[1:]
    maps = next((a.split("=", 1)[1] for a in args if a.startswith("--maps=")), "")
    write = "--write" in args
    if not maps:
        print(__doc__)
        return 1
    sizes = (load_json(SIZES) or {}).get("sizes") or {}
    made = []
    for m in [x.strip() for x in maps.split(",") if x.strip()]:
        r = build(m, sizes)
        if not r:
            print(f"!! {m}: no artifacts")
            continue
        data, hero, n = r
        name = data["map_info"]["name"]
        print(f"{name}: {data['map_info']['dimensions']['width']}x"
              f"{data['map_info']['dimensions']['depth']}, {n} exhibits, hero={hero}")
        if write:
            d = os.path.join(MAPS_DIR, name)
            os.makedirs(d, exist_ok=True)
            with open(os.path.join(d, "map_data.json"), "w", encoding="utf-8") as f:
                json.dump(data, f, indent=1)
            made.append(name)
    if made:
        sys.path.insert(0, os.path.join(REPO, "tools"))
        from book_log import log_event
        log_event("stage", f"doll houses generated (research): {', '.join(made)} — each map's "
                           "artifacts freely re-assembled as a vitrine specimen for comparison")
    if not write:
        print("(dry run — pass --write)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
