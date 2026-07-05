#!/usr/bin/env python3
"""dollhouse.py — the map-room composer (R-015: the room is the MAP, not the chapter).

Each map's real artifacts, composed as one contained room — a floating diorama
(height-2 dais, height-0 void surround, the "specimen on a stand" at room scale).
The pilot found composition must branch on the hero:roster ratio; this bakes the
three modes in:

  MONUMENT  one giant hero (>=7 m or >=2.5x the next) -> the hero IS the room,
            centred on a low riser under a tall backwall, 2 context satellites only.
  SPECIMEN  small roster (<=4) -> a tight cluster: hero on a back riser, the rest
            in a shallow front arc, laddered small->large.
  CABINET   many small (>=5, no dominant hero) -> packed shelves, the void killed.

Non-destructive: writes Room_<Map> beside the hand-built maps. A chapter is now a
necklace of these rooms, chained by the teleporters the real maps already carry.

Usage:
  python tools/dollhouse.py --seq=randomness --write          # a whole necklace
  python tools/dollhouse.py --maps=Random_Walk --write        # one room
  python tools/dollhouse.py --maps=Random_Walk --prefix=Dollhouse  # research alias
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
SKIP = {"dark_sphere", "lab_room", "catalyst_pickup"}   # ambient / fillers

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
        return ("station_micropod", {"base_meters": 0.6, "cap_meters": 1.16, "top_height": 1.15})
    if base < 3.0:
        return ("station_plinth", {"width_cells": 1, "depth_cells": 1, "top_height": 1.1, "cap_inset": 0.1})
    return ("station_stage", {"width_cells": min(4, int(math.ceil(base))),
                              "depth_cells": min(4, int(math.ceil(base))), "step_height": 0.18})


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
    arts = [(n, float((sizes.get(n) or {}).get("base_m", 1.0) or 1.0)) for n in seen]
    return arts or None


def pick_mode(hero_b, rest_b):
    # monument only for a genuinely environment-scale hero (measured >= 8 m);
    # the ratio test over-fires on unmeasured (1.0-default) rosters.
    if hero_b >= 8.0:
        return "monument"
    if len(rest_b) + 1 <= 4:
        return "specimen"
    return "cabinet"


def grid(cols, rows):
    gs = [["0"] * cols for _ in range(rows)]
    gu = [[" "] * cols for _ in range(rows)]
    gi = [[" "] * cols for _ in range(rows)]
    return gs, gu, gi


def compose(map_name, arts):
    arts = sorted(arts, key=lambda a: a[1])
    hero = arts[-1]
    rest = arts[:-1]
    mode = pick_mode(hero[1], [b for _, b in rest])
    header = map_name.replace("_", " ").upper()

    def stamp(gi, token, r, c, cfg=None):
        if 0 <= r < len(gi) and 0 <= c < len(gi[0]):
            gi[r][c] = token + ("#" + "#".join(f"{k}:{v}" for k, v in cfg.items()) if cfg else "")

    if mode == "monument":
        span = min(int(math.ceil(hero[1])) + 6, 28)   # cap: true worlds overflow their dais
        cols, rows = span + 4, span + 6
        cx = cols // 2
        gs, gu, gi = grid(cols, rows)
        for r in range(2, rows - 2):
            for c in range(2, cols - 2):
                gs[r][c] = "2"
        for c in (cx - 3, cx, cx + 3):
            stamp(gi, "station_wall", 3, c, {"width_cells": 3})
        stamp(gi, "station_panel", 2, cx, {"width_cells": 5, "header": header,
              "lines": ["This map has one artifact so large it is the room.",
                        "The concept, at architectural scale — walk into it."]})
        hf, hcfg = footing_for(hero[1])
        stamp(gi, hf, rows // 2, cx, hcfg)
        stamp(gi, hero[0], rows // 2, cx)
        # two context satellites at the front corners
        for i, (n, b) in enumerate(rest[:2]):
            f, cfg = footing_for(b); cfg = dict(cfg); cfg["caption_text"] = n.replace("_", " ")
            stamp(gi, f, rows - 4, 4 + i * (cols - 9))
            stamp(gi, n, rows - 4, 4 + i * (cols - 9))

    elif mode == "specimen":
        span = max(7, len(rest) * 2 + 3)
        cols, rows = span + 4, span + 6
        cx = cols // 2
        gs, gu, gi = grid(cols, rows)
        for r in range(2, rows - 2):
            for c in range(2, cols - 2):
                gs[r][c] = "2"
        for c in (cx - 3, cx, cx + 3):
            stamp(gi, "station_wall", 3, c, {"width_cells": 3})
        stamp(gi, "station_panel", 2, cx, {"width_cells": 4, "header": header,
              "lines": ["A few artifacts, held close — one specimen you can read at a glance.",
                        "The map is the room; the room is one thing."]})
        hf, hcfg = footing_for(hero[1]); stamp(gi, hf, 6, cx, hcfg); stamp(gi, hero[0], 6, cx)
        n = len(rest)
        for i, (name, base) in enumerate(rest):
            frac = (i + 0.5) / max(n, 1)
            c = 3 + int(frac * (cols - 6))
            r = rows - 4 - int(abs(frac - 0.5) * 3)
            f, cfg = footing_for(base); cfg = dict(cfg); cfg["caption_text"] = name.replace("_", " ")
            stamp(gi, f, r, c); stamp(gi, name, r, c)

    else:  # cabinet — packed shelves, void killed
        per = 4
        allb = rest + [hero]
        n = len(allb)
        shelf_rows = math.ceil(n / per)
        cols = per * 2 + 4
        rows = shelf_rows * 2 + 6
        cx = cols // 2
        gs, gu, gi = grid(cols, rows)
        for r in range(2, rows - 2):
            for c in range(2, cols - 2):
                gs[r][c] = "2"
        stamp(gi, "station_wall", 3, cx - 2, {"width_cells": 3})
        stamp(gi, "station_wall", 3, cx + 2, {"width_cells": 3})
        stamp(gi, "station_panel", 2, cx, {"width_cells": 5, "header": header,
              "lines": ["Many small artifacts, shelved tight — a cabinet, not a plaza.",
                        "Density is the composition; the void is the enemy here."]})
        # hero gets the top-centre; rest fill the shelves
        order = [hero] + rest
        i = 0
        for sr in range(shelf_rows):
            r = 5 + sr * 2
            for col_i in range(per):
                if i >= len(order):
                    break
                name, base = order[i]; i += 1
                c = 3 + col_i * 2
                f, cfg = footing_for(min(base, 2.9))  # cap footing so shelves stay even
                cfg = dict(cfg); cfg["caption_text"] = name.replace("_", " ")
                stamp(gi, f, r, c); stamp(gi, name, r, c)

    gu[rows - 2][cx] = "sp"
    gu[2][min(cols - 3, cx + 4)] = "t"
    gs[2][min(cols - 3, cx + 4)] = "0"
    return gs, gu, gi, cols, rows, mode, hero[0]


def build_map(map_name, arts, prefix):
    gs, gu, gi, cols, rows, mode, hero = compose(map_name, arts)
    name = f"{prefix}_{map_name}"
    data = {
        "map_info": {"name": name, "lookup_name": name,
                     "title": f"{map_name.replace('_', ' ')} — the room",
                     "description": f"R-015: {map_name} composed as one room ({mode} mode). "
                                    "The room is the map; a chapter is a necklace of these.",
                     "version": "1.0", "format": "json",
                     "dimensions": {"width": cols, "depth": rows, "max_height": 3},
                     "metadata": {"difficulty": "intermediate", "category": "room",
                                  "estimated_time": "2 min",
                                  "learning_objectives": [f"{mode} composition"]}},
        "utility_definitions": {"t": {"type": "teleporter", "name": "Next room",
                                      "description": "next in the necklace",
                                      "properties": {"action": "next_in_sequence"}}},
        "lighting": {"ambient_color": [0.42, 0.42, 0.5], "ambient_energy": 0.7,
                     "directional_light": {"enabled": True, "direction": [-0.4, -0.7, -0.4],
                                           "color": [1.0, 0.96, 0.9], "energy": 1.2}},
        "settings": {"cube_size": 1.0, "gutter": 0.0, "show_grid": True, "enable_physics": True,
                     "background": {"type": "sky", "color": [0.18, 0.16, 0.28]}},
        "layers": {"structure": gs, "utilities": gu, "interactables": gi},
    }
    return data, mode, hero, cols, rows


def seq_maps(seq):
    d = load_json(os.path.join(SEQ_DIR, f"{seq}.json")) or {}
    s = d.get("sequences")
    sd = (s[0] if isinstance(s, list) and s else
          next(iter(s.values())) if isinstance(s, dict) and s else d)
    return sd.get("maps", []) or []


def main():
    args = sys.argv[1:]
    prefix = next((a.split("=", 1)[1] for a in args if a.startswith("--prefix=")), "Room")
    write = "--write" in args
    seq = next((a.split("=", 1)[1] for a in args if a.startswith("--seq=")), "")
    maps_arg = next((a.split("=", 1)[1] for a in args if a.startswith("--maps=")), "")
    maps = seq_maps(seq) if seq else [m.strip() for m in maps_arg.split(",") if m.strip()]
    if not maps:
        print(__doc__)
        return 1
    sizes = (load_json(SIZES) or {}).get("sizes") or {}
    made = []
    modes: dict[str, int] = {}
    for m in maps:
        arts = roster(m, sizes)
        if not arts:
            print(f"  {m}: no artifacts — skipped")
            continue
        data, mode, hero, cols, rows = build_map(m, arts, prefix)
        modes[mode] = modes.get(mode, 0) + 1
        print(f"  {prefix}_{m}: {cols}x{rows}  [{mode}]  hero={hero}")
        if write:
            d = os.path.join(MAPS_DIR, data["map_info"]["name"])
            os.makedirs(d, exist_ok=True)
            with open(os.path.join(d, "map_data.json"), "w", encoding="utf-8") as f:
                json.dump(data, f, indent=1)
            made.append(data["map_info"]["name"])
    print(f"\n{'necklace' if seq else 'rooms'}: {len(made) or len(maps)} — modes {modes}")
    if made:
        sys.path.insert(0, os.path.join(REPO, "tools"))
        from book_log import log_event
        log_event("room", f"{seq or 'maps'} composed as a necklace of {len(made)} rooms (R-015): "
                          f"modes {modes} — the room is the map")
    if not write:
        print("(dry run — pass --write)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
