#!/usr/bin/env python3
"""Generate the 6 Resource Management spine maps as standard 3-layer grid maps.

Each map is a processional hall (the same grid principle every map uses): border `2` walls,
`1` floor, `s` spawn at top-centre, the hero artifact placed by lookup_name in the interactables
layer, `sub:` truth-beats down the central axis, and a `t:NextMap` teleporter at the foot that
chains the sequence into a loop. NOT bespoke scenes — pure map_data.json the grid system loads via
commons/scenes/grid.tscn.

Run: python tools/build_resourcemanagement_maps.py
Then validate: python tools/map_pathfinder.py check <MapName> --verbose
"""
import json
import os

ROWS, COLS = 22, 14
SPAWN = (1, 7)
INTRO = (3, 7)
ART = (9, 7)
TRUTH = (15, 7)
TELE = (20, 7)

MAPS = [
    {
        "name": "ResourceManagement_Algorithmic_Complexity_Big_O",
        "title": "Algorithmic Complexity",
        "artifact": "big_o_complexity",
        "next": "ResourceManagement_Data_Locality_Caching",
        "desc": "Resource Management I — Big O. A bar per complexity class grows as the input size n sweeps up; at small n they stand level, at large n the quadratic and exponential peg the ceiling. Watch scale decide whether the thing runs at all.",
        "intro": "Same problem, six solutions. Walk to the chart and watch the input size grow — the bars that stay low are the algorithms you can afford.",
        "truth_key": "truth_bigo",
        "truth": "An algorithm is not one thing — it is a curve. Two solutions that agree on every small case can disagree about whether the universe has enough time.",
    },
    {
        "name": "ResourceManagement_Data_Locality_Caching",
        "title": "Data Locality & Caching",
        "artifact": "data_locality_caching",
        "next": "ResourceManagement_Real_time_vs_Offline_Processing",
        "desc": "Resource Management II — caching. A memory ladder stacked by log-latency: registers, L1/L2/L3, RAM, disk. A probe climbs to fetch — a HIT when the data is near, a ruinous MISS when it is far.",
        "intro": "Climb the ladder. The gap from RAM to disk is a chasm because the latency is — where a byte lives is the whole price of using it.",
        "truth_key": "truth_cache",
        "truth": "Where a thing IS costs more than what it is. The same byte is a nanosecond away or ten million — distance is the price, not value.",
    },
    {
        "name": "ResourceManagement_Real_time_vs_Offline_Processing",
        "title": "Real-time vs Offline",
        "artifact": "realtime_vs_offline",
        "next": "ResourceManagement_Version_Control",
        "desc": "Resource Management III — the clock. Twin pipelines: a real-time lane with a frame deadline (finish or drop the frame, red) and an offline lane with no deadline that completes everything at full quality.",
        "intro": "Two lanes, one job. The top lane must beat the clock and drops what it can't finish; the bottom takes its time and keeps everything.",
        "truth_key": "truth_realtime",
        "truth": "The clock changes the algorithm. A deadline is not a constraint on the answer — it is part of the question.",
    },
    {
        "name": "ResourceManagement_Version_Control",
        "title": "Version Control",
        "artifact": "version_control_tree",
        "next": "ResourceManagement_Testing_and_Debugging",
        "desc": "Resource Management IV — history as shape. A commit DAG: a main branch and a feature branch that peels off and merges back, with HEAD advancing commit by commit. Checking out is moving the ring.",
        "intro": "Stand in the history. The line you remember is a story told afterward; the truth is a graph that branches and rejoins.",
        "truth_key": "truth_vcs",
        "truth": "History is not a line. It branches where work diverges and merges where it rejoins — HEAD is your foot on one node of the shape.",
    },
    {
        "name": "ResourceManagement_Testing_and_Debugging",
        "title": "Testing & Debugging",
        "artifact": "test_harness",
        "next": "ResourceManagement_Hardware_Considerations",
        "desc": "Resource Management V — the test board. A grid of cases that pass green or fail red; inject a bug and a band flips red, fix it and they heal left to right. Each cell is a claim about the future.",
        "intro": "Read the board. Every green cell is a promise that this input still gives this answer; watch a bug break the promises, then watch them heal.",
        "truth_key": "truth_test",
        "truth": "A test is a claim about the future — that this input will always give this answer. Green is a promise kept; red is the promise broken, made visible.",
    },
    {
        "name": "ResourceManagement_Hardware_Considerations",
        "title": "Hardware Considerations",
        "artifact": "hardware_cross_section",
        "next": "ResourceManagement_Algorithmic_Complexity_Big_O",
        "desc": "Resource Management VI — the machine. A cutaway of CPU, GPU, RAM, cache and disk on a bus, with data tokens flowing at component-specific throughput. The algorithm runs on a place, not in the abstract.",
        "intro": "Look inside the machine. The components are real, the bus is narrow, and the speed of your code is the speed of the slowest part it has to wait on.",
        "truth_key": "truth_hw",
        "truth": "The algorithm runs on a place, not in the abstract. Cores, buses and distances are the ground the computation stands on — and the ceiling it hits.",
    },
]


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
    return g


def _build(m):
    struct = _structure()
    struct[TELE[0]][TELE[1]] = "0"   # teleporter sits in a void cell (grid convention)
    util = _blank("")
    inter = _blank("")
    util[SPAWN[0]][SPAWN[1]] = "s"
    util[INTRO[0]][INTRO[1]] = "sub:intro"
    util[TRUTH[0]][TRUTH[1]] = "sub:" + m["truth_key"]
    util[TELE[0]][TELE[1]] = "t:" + m["next"]
    inter[ART[0]][ART[1]] = m["artifact"]
    return {
        "map_info": {"name": m["name"], "lookup_name": m["name"], "title": m["title"], "description": m["desc"]},
        "subtitles": {
            "intro": {"text": m["intro"], "speaker": m["title"], "level": 1},
            m["truth_key"]: {"text": m["truth"], "speaker": m["title"], "level": 1},
        },
        "lighting": {},
        "settings": {
            "cube_size": 1, "gutter": 0, "show_grid": True, "enable_physics": True,
            "auto_reveal_on_entry": True, "initial_tile_visibility": "visible",
            "disable_biome": True,   # abstract CS-practice maps: sterile lab, no foliage/creatures
            "background": {"type": "sky", "color": [0.10, 0.11, 0.16]},
        },
        "layers": {"structure": struct, "utilities": util, "interactables": inter},
    }


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    for m in MAPS:
        d = _build(m)
        out_dir = os.path.join(root, "commons", "maps", m["name"])
        os.makedirs(out_dir, exist_ok=True)
        with open(os.path.join(out_dir, "map_data.json"), "w", encoding="utf-8") as f:
            json.dump(d, f, indent=1, ensure_ascii=False)
        print("wrote", m["name"])
    print(f"\n{len(MAPS)} maps written. Compact with: python tools/compact_map_json.py --all")


if __name__ == "__main__":
    main()
