#!/usr/bin/env python3
"""Build Curation_Bay_Demo — proves the curation station integrates into the grid.

A single `curation_station` interactables token stages 5 Resource Management artifacts as a whole
bay (stage + plinths + tiling wall + pillars + barrier), inside a standard 3-layer map_data.json
loaded by grid.tscn — NOT a bespoke launcher scene. The composer measures + assembles at _ready;
the author just leaves the bay cells token-empty (the runtime placer is token-driven, so empty
cells = a clear bay). Requires `auto_ground:false` on curation_station in registry/station.json.

Run: python tools/build_curation_bay_demo.py
Then: python tools/map_pathfinder.py check Curation_Bay_Demo --verbose
"""
import json
import os

ROWS, COLS = 18, 38
ANCHOR = (7, 19)   # the single composer token; the bay expands centred on this cell
SPAWN = (14, 19)   # in front of the bay (toward the barrier side)
TELE = (16, 19)
NAME = "Curation_Bay_Demo"

# One flat token -> a whole bay. Comma-list of children survives parsing (non-numeric values
# never hit the rotation-shorthand branch); bool toggles need no whitelist edit.
TOKEN = (
    "curation_station"
    "#artifacts:big_o_complexity,data_locality_caching,realtime_vs_offline,version_control_tree,test_harness"
    "#with_wall:true#with_pillars:true#with_barrier:true"
)


def _blank(fill):
    return [[fill for _ in range(COLS)] for _ in range(ROWS)]


def _structure():
    g = _blank("1")
    for x in range(COLS):
        g[0][x] = "2"
        g[ROWS - 1][x] = "2"
    for z in range(ROWS):
        g[z][0] = "2"
        g[z][COLS - 1] = "2"
    g[TELE[0]][TELE[1]] = "0"   # teleporter sits on a void cell (grid convention)
    return g


def _build():
    struct = _structure()
    util = _blank("")
    inter = _blank("")
    util[SPAWN[0]][SPAWN[1]] = "s"
    util[TELE[0]][TELE[1]] = "t:" + NAME   # loop to self (standalone demo)
    inter[ANCHOR[0]][ANCHOR[1]] = TOKEN
    return {
        "map_info": {
            "name": NAME, "lookup_name": NAME, "title": "Curation Bay (demo)",
            "description": "Proof that the curation station lives in the grid: one curation_station "
                           "token stages five Resource Management artifacts as a whole bay, inside a "
                           "standard map_data.json loaded by grid.tscn — no bespoke launcher scene.",
            "dimensions": {"width": COLS, "depth": ROWS, "max_height": 2},
        },
        "subtitles": {},
        "lighting": {},
        "settings": {
            "cube_size": 1, "gutter": 0, "show_grid": True, "enable_physics": True,
            "auto_reveal_on_entry": True, "initial_tile_visibility": "visible",
            "disable_biome": True,   # the bay IS the content — sterile grid, no foliage
            "background": {"type": "sky", "color": [0.10, 0.11, 0.16]},
        },
        "layers": {"structure": struct, "utilities": util, "interactables": inter},
    }


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(root, "commons", "maps", NAME)
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, "map_data.json"), "w", encoding="utf-8") as f:
        json.dump(_build(), f, indent=1, ensure_ascii=False)
    print("wrote", NAME, "(%dx%d, bay anchor at %s)" % (COLS, ROWS, ANCHOR))


if __name__ == "__main__":
    main()
