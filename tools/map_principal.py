#!/usr/bin/env python3
"""map_principal.py — THE MAP PRINCIPAL: one finisher, every relevant layer.

Palle: "all these questions are with the goal to create a principal that can
make good maps with all relevant layers." A map STRATEGY (act-halls, sized
rooms, breathing wang-hall, ant-found plates...) only invents the FLOOR IDEA.
This module is the meeting point that turns any layers dict into a complete
Ada map:

  dimensions          load-bearing (absent = no floor in Godot)
  settings            labwall wall_segments + register palettes
                      + proximity_lod (the computation budget)
  spawn/exit          "s" spawn (NOT "sp" — that is score_points) + t:restart
  wall runs           marriage 2 — runs compiled into map data
  wall props          hospitality on the run slots
  mission metadata    strategy facts recorded for the verdict loop

The wang-tile move applied to generators themselves: standardize the meeting
point, keep the strategy wild. Strategies live in their own files
(tools/gen_*.py) and call finish().
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

# the register vocabulary (shared with mission_graph act-halls)
PALETTES = {
    "arrival": {"plain": 5, "glass": 3, "whiteboard": 2, "window": 3,
                "vent": 1, "locker": 1},
    "work":    {"plain": 4, "conduit": 3, "display": 2, "locker": 2,
                "vent": 2, "window": 1, "beam": 1},
    "depth":   {"plain": 3, "hazard": 2, "rib": 3, "beam": 2, "slit": 2,
                "conduit": 2, "vent": 1},
}
ACCENTS = {"arrival": [1.0, 0.62, 0.18], "work": [0.25, 0.85, 1.0],
           "depth": [1.0, 0.25, 0.15]}


def blank_layers(W: int, H: int) -> dict:
    return {"structure": [["0"] * W for _ in range(H)],
            "utilities": [[" "] * W for _ in range(H)],
            "walls": [[""] * W for _ in range(H)],
            "interactables": [[" "] * W for _ in range(H)]}


def wall(layers: dict, r: int, c: int, code: str) -> None:
    if code not in layers["walls"][r][c]:
        layers["walls"][r][c] += code


def palette_bands(bands: list) -> list:
    """bands: [{"rect": [x0,y0,x1,y1], "register": "arrival|work|depth"}]"""
    out = []
    for i, b in enumerate(bands):
        reg = b["register"]
        out.append({"act": i, "name": reg, "rect": b["rect"],
                    "weights": PALETTES[reg], "accent": ACCENTS[reg]})
    return out


def finish(name: str, seq: str, mode: str, layers: dict, mission: dict,
           bands: list, spawn=None, exit_cell=None, lod_radius: float = 14.0) -> dict:
    """the contract. bands feed palette_bands; spawn/exit are (row, col)."""
    H = len(layers["structure"])
    W = len(layers["structure"][0]) if H else 0
    if spawn is not None:
        layers["utilities"][spawn[0]][spawn[1]] = "s"
    if exit_cell is not None:
        er, ec = exit_cell
        layers["utilities"][er][ec] = "t:restart"
        layers["structure"][er][ec] = "0"
    mg_meta = {"seq": seq, "mode": mode}
    mg_meta.update(mission)
    data = {"map_info": {"name": name, "lookup_name": name, "title": name,
                         "dimensions": {"width": W, "depth": H, "max_height": 3},
                         "mission_graph": mg_meta},
            "settings": {"wall_segments": {"style": "labwall", "height": 3.2,
                                           "thickness": 0.16, "door_width": 2.2,
                                           "palettes": palette_bands(bands)},
                         "proximity_lod": {"radius": lod_radius}},
            "layers": layers}
    import wall_runs as _wr
    _wr.annotate(data, name)
    import wall_props as _wp
    _wp.annotate(data, name)
    out = ROOT / "commons" / "maps" / name
    out.mkdir(parents=True, exist_ok=True)
    with open(out / "map_data.json", "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, indent=1)
    print(f"{name}: {mode} {W}x{H} cells -> commons/maps/{name}/")
    return data
