#!/usr/bin/env python3
"""
Generate Biome_Kingdom_Matrix — a tiny test map with one painted cell
per (kingdom, intensity) combination. 30 cells total, laid out in a
6×5 grid with 1-cell gaps so each cell's spawned substrate stays
isolated.

Used by commons/testing/biome_kingdom_matrix_lab.gd to capture one
screenshot per cell, feeding the /biome-kingdom-matrix encyclopedia
page (the "auto-research loop" for the dispatcher).

Layout (top-down view, cells at every-other coord):

       c=1   c=3   c=5   c=7   c=9   c=11
r=1    f1    t1    u1    c1    m1    x1
r=3    f2    t2    u2    c2    m2    x2
r=5    f3    t3    u3    c3    m3    x3
r=7    f4    t4    u4    c4    m4    x4
r=9    f5    t5    u5    c5    m5    x5

Map dimensions: 13 wide × 11 deep (extra border for spawn / camera).

Run: python tools/generate_biome_kingdom_matrix_map.py
"""

from __future__ import annotations

import json
import sys
import urllib.request
import urllib.error

API = "http://localhost:3003/api/voxel-editor"
W = 13   # width (cols, the long axis)
D = 11   # depth (rows, the short axis)

# Token kingdoms in column order: flower, tree, fungus, creature, moss, cross.
# Mirrors KINGDOM_KEYWORDS / config order in biome_config.json.
KINGDOMS: list[str] = ["f", "t", "u", "c", "m", "x"]


def base_map(name: str) -> dict:
    structure = [["1"] * W for _ in range(D)]
    utilities = [[" "] * W for _ in range(D)]
    interactables = [[" "] * W for _ in range(D)]
    biome_paint = [[" "] * W for _ in range(D)]
    # Spawn at top-left corner so the player / capture rig has somewhere
    # to start outside the matrix.
    utilities[0][0] = "sp"
    return {
        "map_info": {
            "name": name,
            "lookup_name": name,
            "format": "json",
            "version": "1.0",
            "dimensions": {"width": W, "depth": D, "max_height": 5},
            "metadata": {"source": "biome_kingdom_matrix_generator"},
        },
        "layers": {
            "structure": structure,
            "utilities": utilities,
            "interactables": interactables,
            "biome_paint": biome_paint,
        },
        "settings": {
            "cube_size": 1, "gutter": 0, "show_grid": True,
            "background": {"type": "sky", "color": [0.06, 0.07, 0.13]},
            "grid_animation": {"enabled": False},
            "initial_tile_visibility": "all_visible",
        },
        "utility_definitions": {
            "sp": {"type": "spawn"}, "t": {"type": "teleporter"},
        },
    }


def paint_matrix(m: dict) -> list[dict]:
    """Paint the 6×5 matrix and return cell metadata for the lab."""
    cells: list[dict] = []
    for intensity in range(1, 6):
        row = intensity * 2 - 1  # 1, 3, 5, 7, 9
        for kc, kingdom in enumerate(KINGDOMS):
            col = kc * 2 + 1  # 1, 3, 5, 7, 9, 11
            token = f"{kingdom}{intensity}"
            m["layers"]["biome_paint"][row][col] = token
            cells.append({
                "kingdom": kingdom,
                "intensity": intensity,
                "token": token,
                "row": row,
                "col": col,
            })
    return cells


def post_save(name: str, data: dict) -> bool:
    body = json.dumps({"mapName": name, "data": data}).encode("utf-8")
    req = urllib.request.Request(
        API, data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        resp = urllib.request.urlopen(req, timeout=20)
    except urllib.error.URLError as e:
        print(f"  FAIL: {name} -- {e}")
        return False
    return resp.status == 200


def main() -> int:
    print(f"Generating Biome_Kingdom_Matrix via {API}...")
    m = base_map("Biome_Kingdom_Matrix")
    cells = paint_matrix(m)
    ok = post_save("Biome_Kingdom_Matrix", m)
    print(f"  {'OK' if ok else 'FAIL'}: 30 cells painted ({len(KINGDOMS)} kingdoms x 5 intensities)")
    print()
    print("First few cells (kingdom, intensity, token, row, col):")
    for c in cells[:6]:
        print(f"  {c}")
    print(f"  ... +{len(cells) - 6} more")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
