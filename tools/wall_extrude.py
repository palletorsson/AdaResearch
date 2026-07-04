#!/usr/bin/env python3
"""wall_extrude.py — Fold 3: extrude curated wall segments into a walkable room.

"First we extend the 2d wall out so we can walk among the objects. Now the 3d
grid starts to form — the larger and applied artifacts take place with their
footprint, like the wall segment defining the grid the player can walk."

For a sequence, this takes the chapter's hand-cut walk (tutorial JSON), selects
the curated wall clusters (commons/data/curated_walls/clusters/) that cover the
most walked artifacts, and generates a gallery map:

  - bays: selected wall segments stacked south -> north in walk order
          (placed as `cluster:<name>` tokens, resolved by cluster_resolver.gd)
  - floor citizens: walked artifacts no cluster covers, on the east lane
  - the hero: the largest walked artifact gets the north end zone —
          visible down the corridor from spawn (viewing distance scales with size)
  - empty plinths: one per declared blank (the museum's missing exhibit)
  - spawn at the south, teleporter past the hero

Usage:
  python tools/wall_extrude.py --seq=fractals [--map=Hangar_Fractals] [--write]
Without --write it prints the plan only. Validate after writing:
  python tools/map_pathfinder.py check <Map> --verbose
"""
from __future__ import annotations

import json
import math
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.environ.get("ADA_ENCYCLOPEDIA_PATH", "C:/Users/palle/Documents/GitHub/ada_encyclopedia")
TUTORIAL_DIR = os.path.join(ENC, "public", "tutorial")
CLUSTERS_DIR = os.path.join(REPO, "commons", "data", "curated_walls", "clusters")
SIZES = os.path.join(REPO, "commons", "data", "artifact_sizes.json")
MAPS_DIR = os.path.join(REPO, "commons", "maps")

EAST_LANE_W = 8      # floor-citizen zone east of the bays
PATH_W = 3           # the corridor
BAY_GAP = 2          # empty rows between bays
STATION_TOKENS = ("station_", "science_", "hangar_")

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass


def load_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def walk_of(seq: str) -> tuple[list[str], list[dict], str]:
    t = load_json(os.path.join(TUTORIAL_DIR, f"{seq}.json")) or {}
    walk = []
    for p in t.get("pages", []):
        if p["kind"] == "primitive" and isinstance(p.get("artifact"), dict):
            walk.append(p["artifact"]["name"])
        elif p["kind"] == "walk":
            walk += [a["name"] for a in p.get("artifacts") or []]
    nxt = ""
    for p in t.get("pages", []):
        if p["kind"] == "seed":
            nxt = p.get("next") or ""
    return walk, (t.get("blanks") or []), nxt


def cluster_index() -> dict[str, dict]:
    """cname -> {arts: [artifact tokens], w: cells along x, d: cells along z}."""
    out = {}
    if not os.path.isdir(CLUSTERS_DIR):
        return out
    for f in sorted(os.listdir(CLUSTERS_DIR)):
        if not f.endswith(".json"):
            continue
        d = load_json(os.path.join(CLUSTERS_DIR, f))
        pieces = (d or {}).get("pieces") or []
        if not pieces:
            continue
        arts = [p["token"] for p in pieces
                if not str(p.get("token", "")).startswith(STATION_TOKENS)]
        w = int(math.ceil(max(float(p.get("x", 0)) for p in pieces))) + 2
        dz = int(math.ceil(max(float(p.get("z", 0)) for p in pieces))) + 2
        out[f[:-5]] = {"arts": arts, "w": w, "d": dz}
    return out


def main() -> int:
    args = sys.argv[1:]
    seq = next((a.split("=", 1)[1] for a in args if a.startswith("--seq=")), None)
    if not seq:
        print(__doc__)
        return 1
    map_name = next((a.split("=", 1)[1] for a in args if a.startswith("--map=")),
                    f"Hangar_{seq.capitalize()}")
    write = "--write" in args

    walk, blanks, nxt = walk_of(seq)
    if not walk:
        print(f"!! no walk for {seq}")
        return 1
    sizes = (load_json(SIZES) or {}).get("sizes") or {}
    clusters = cluster_index()

    # greedy cluster selection: maximize walked coverage, penalize freeloaders
    remaining = set(walk)
    chosen: list[tuple[str, dict, int]] = []      # (cname, meta, first walk idx)
    while True:
        best, best_score = None, 0
        for cname, meta in clusters.items():
            cov = [a for a in meta["arts"] if a in remaining]
            extras = [a for a in meta["arts"] if a not in walk]
            score = len(cov) * 2 - len(extras)
            if cov and score > best_score:
                best, best_score = cname, score
        if not best:
            break
        meta = clusters.pop(best)
        cov = [a for a in meta["arts"] if a in remaining]
        remaining -= set(meta["arts"])
        chosen.append((best, meta, min(walk.index(a) for a in cov)))
    chosen.sort(key=lambda c: c[2])

    floor = [a for a in walk if a in remaining]
    hero = max(floor, key=lambda a: (sizes.get(a) or {}).get("base_m") or 0) if floor else None
    hero_cells = int(math.ceil((sizes.get(hero) or {}).get("base_m") or 4)) + 2 if hero else 0
    lane = [a for a in floor if a != hero]

    # dimensions
    bay_w = max((m["w"] for _, m, _ in chosen), default=10)
    cols = 2 + bay_w + PATH_W + EAST_LANE_W
    rows = 2  # north border + teleporter row
    rows += max(hero_cells, 4) + 1
    for _, m, _ in chosen:
        rows += m["d"] + BAY_GAP
    rows += max(len(lane) + len(blanks) - sum(m["d"] + BAY_GAP for _, m, _ in chosen) // 3, 0)
    rows += 3  # entry
    lane_col = 2 + bay_w + PATH_W + 2

    grid_s = [["1"] * cols for _ in range(rows)]
    grid_u = [[" "] * cols for _ in range(rows)]
    grid_i = [[" "] * cols for _ in range(rows)]

    # north end: teleporter ON THE HERO'S AXIS — the exit leg walks through the
    # hero zone, so the ride cannot leave without passing the biggest body.
    hero_col = 2 + bay_w // 2
    grid_u[1][hero_col] = "t"
    grid_s[1][hero_col] = "0"      # teleporter cells are void (pathfinder rule 5)
    r = 2
    if hero:
        grid_i[r + hero_cells // 2][hero_col] = hero
        r += max(hero_cells, 4) + 1

    # bays north -> south in REVERSE walk order so walking north follows the walk
    lane_r = r
    for cname, meta, _ in reversed(chosen):
        grid_i[r][2] = f"cluster:{cname}"
        r += meta["d"] + BAY_GAP

    # east lane: floor citizens + empty plinths, spread along the gallery
    slots = lane + ["__BLANK__"] * len(blanks)
    if slots:
        span = max(r - lane_r, len(slots) * 2)
        for i, a in enumerate(slots):
            rr = min(lane_r + (i * span) // max(len(slots), 1) + 1, rows - 4)
            grid_i[rr][lane_col] = "station_plinth" if a == "__BLANK__" else a
    grid_u[rows - 2][cols // 2] = "sp"

    print(f"{map_name}: {cols} x {rows}")
    print(f"  bays (S->N follows the walk): " +
          ", ".join(f"{c} [{'+'.join(m['arts'])}]" for c, m, _ in chosen))
    print(f"  hero: {hero} ({hero_cells} cells, north zone)")
    print(f"  east lane: {', '.join(lane) or '—'}  · empty plinths: {len(blanks)}")
    uncovered = [a for a in walk if a in remaining and a != hero and a not in lane]
    if uncovered:
        print(f"  !! uncovered: {uncovered}")
    if not write:
        print("(dry run — pass --write to create the map)")
        return 0

    data = {
        "map_info": {
            "name": map_name, "lookup_name": map_name,
            "title": f"{seq.capitalize()} — the wall, extruded",
            "description": f"Fold 3: the {seq} chapter's curated wall segments extruded into a "
                           "walkable gallery. The walk order runs south to north; the wall "
                           "defines the grid.",
            "version": "1.0", "format": "json",
            "dimensions": {"width": cols, "depth": rows, "max_height": 3},
            "metadata": {"difficulty": "intermediate", "category": seq,
                         "estimated_time": "5-6 minutes",
                         "learning_objectives": [f"The {seq} walk, staged",
                                                 "Wall segments as room DNA",
                                                 "Blanks as empty plinths"]},
        },
        "utility_definitions": {
            "t": {"type": "teleporter", "name": f"Next: {nxt or 'exit'}",
                  "description": "Leave the gallery",
                  "properties": {"action": "next_in_sequence"}},
        },
        "lighting": {"ambient_color": [0.4, 0.4, 0.5], "ambient_energy": 0.6,
                     "directional_light": {"enabled": True, "direction": [-0.4, -0.7, -0.4],
                                           "color": [1.0, 0.95, 0.9], "energy": 1.2}},
        "settings": {"cube_size": 1.0, "gutter": 0.0, "show_grid": True,
                     "enable_physics": True,
                     "background": {"type": "sky", "color": [0.2, 0.15, 0.3]}},
        "layers": {"structure": grid_s, "utilities": grid_u, "interactables": grid_i},
    }
    out_dir = os.path.join(MAPS_DIR, map_name)
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, "map_data.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=1)
    print(f"wrote {out}")
    print(f"next: python tools/compact_map_json.py {map_name} && "
          f"python tools/map_pathfinder.py check {map_name} --verbose")
    return 0


if __name__ == "__main__":
    sys.exit(main())
