#!/usr/bin/env python3
"""gen_spine_walls.py — generate a curated WALL LAYOUT for each spine map from its SMALL items.

For each spine sequence (in `order`), for each map (in order), collect the map's SMALL
artifacts (unique, registry-known, in grid row-major order) and arrange a curated wall
layout for the Ada Research wall-hangar editor (world metres; the editor's FLOOR_Z = 0.8).

Layout per map:
  - one station_panel on the wall at the start (the map-label slot):
      {token:"station_panel", x:0.0, y:1.8, z:0.06, wall:true}
  - for each small artifact i (x = 1.0 + i*2.0):
      a station_plinth  {token:"station_plinth", x:x, y:0.0, z:0.8, wall:false}
      and the artifact  {token:<lookup>,        x:x, y:1.0, z:0.8, wall:false}
  - if >=2 small items: a station_pillar at each end:
      {token:"station_pillar", x:-1.0, y:0.0, z:0.8, wall:false}
      {token:"station_pillar", x:(1.0+(n-1)*2.0)+2.0, y:0.0, z:0.8, wall:false}

Output: commons/data/spine_walls.json (only maps with >=1 small item).
"""

import json
import math
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPINE_PATH = os.path.join(REPO, "commons", "maps", "curriculum_spine.json")
SEQ_DIR = os.path.join(REPO, "commons", "maps", "sequences")
MAPS_DIR = os.path.join(REPO, "commons", "maps")
REG_DIR = os.path.join(REPO, "commons", "artifacts", "registry")
OUT_DIR = os.path.join(REPO, "commons", "data")
OUT_PATH = os.path.join(OUT_DIR, "spine_walls.json")

FLOOR_Z = 0.8  # editor convention, used as the z for floor-standing pieces


def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def lookup_from_token(token):
    """Strip a token's config suffix: take the part before the first ':' or '#'."""
    s = str(token).strip()
    for sep in (":", "#"):
        idx = s.find(sep)
        if idx != -1:
            s = s[:idx]
    return s.strip()


def is_small_entry(entry):
    """Decide SMALL per the recipe.

    SMALL if:
      - size_group (or parameters.size_group) is "compact" or "small", OR
      - measurements.grid_cells area (ceil(w)*ceil(h)) <= 1, OR
      - spatial_needs.footprint_cells <= 1
    """
    if not isinstance(entry, dict):
        return False

    # size_group (direct or under parameters)
    sg = entry.get("size_group")
    if sg is None:
        params = entry.get("parameters")
        if isinstance(params, dict):
            sg = params.get("size_group")
    if isinstance(sg, str) and sg.strip().lower() in ("compact", "small"):
        return True

    # measurements.grid_cells -> ceil(w)*ceil(h) <= 1
    meas = entry.get("measurements")
    if isinstance(meas, dict):
        gc = meas.get("grid_cells")
        if isinstance(gc, (list, tuple)) and len(gc) >= 2:
            try:
                w = math.ceil(float(gc[0]))
                h = math.ceil(float(gc[1]))
                if w * h <= 1:
                    return True
            except (TypeError, ValueError):
                pass

    # spatial_needs.footprint_cells <= 1
    sn = entry.get("spatial_needs")
    if isinstance(sn, dict):
        fc = sn.get("footprint_cells")
        try:
            if fc is not None and float(fc) <= 1:
                return True
        except (TypeError, ValueError):
            pass

    return False


def build_registry_sets():
    """Scan registry/*.json. Return (small_set, scene_set).

    Entries live under "artifacts" or at the root. An entry is registered (scene_set)
    if it carries a "scene" field. small_set is the subset that passes is_small_entry.
    """
    small = set()
    scenes = set()
    for fn in sorted(os.listdir(REG_DIR)):
        if not fn.endswith(".json"):
            continue
        path = os.path.join(REG_DIR, fn)
        try:
            data = load_json(path)
        except (json.JSONDecodeError, OSError) as e:
            print(f"  WARN: skip registry {fn}: {e}", file=sys.stderr)
            continue
        if not isinstance(data, dict):
            continue
        containers = []
        arts = data.get("artifacts")
        if isinstance(arts, dict):
            containers.append(arts)
        else:
            # entries at root: any value that is a dict and looks like an artifact entry
            containers.append(data)
        for container in containers:
            for key, entry in container.items():
                if not isinstance(entry, dict):
                    continue
                # treat as an artifact entry only if it has a scene or recognizable fields
                has_scene = isinstance(entry.get("scene"), str) and entry["scene"].strip()
                looks_like_entry = has_scene or "lookup_name" in entry or \
                    "size_group" in entry or "measurements" in entry or "spatial_needs" in entry
                if not looks_like_entry:
                    continue
                name = entry.get("lookup_name") or key
                name = str(name).strip()
                if not name:
                    continue
                if has_scene:
                    scenes.add(name)
                if is_small_entry(entry):
                    small.add(name)
    return small, scenes


def collect_map_smalls(map_name, small_set, scene_set):
    """Return unique SMALL lookups for a map, in grid row-major order.

    Only includes lookups that are registry-known (have a scene) AND small.
    """
    mpath = os.path.join(MAPS_DIR, map_name, "map_data.json")
    if not os.path.isfile(mpath):
        return None  # signal: map data missing
    try:
        data = load_json(mpath)
    except (json.JSONDecodeError, OSError) as e:
        print(f"  WARN: cannot read map {map_name}: {e}", file=sys.stderr)
        return []
    layers = data.get("layers", {})
    inter = layers.get("interactables")
    if not isinstance(inter, list):
        return []
    seen = set()
    ordered = []
    for row in inter:
        if not isinstance(row, list):
            continue
        for cell in row:
            if not isinstance(cell, str):
                continue
            cell = cell.strip()
            if not cell:
                continue
            lookup = lookup_from_token(cell)
            if not lookup or lookup in seen:
                continue
            # must be a registered scene (skip utilities/labels/etc.) and small
            if lookup not in scene_set:
                continue
            if lookup not in small_set:
                continue
            seen.add(lookup)
            ordered.append(lookup)
    return ordered


def build_pieces(smalls):
    """Build the curated wall pieces for a list of small lookups (n>=1)."""
    n = len(smalls)
    pieces = []
    # map-label panel on the wall at the start
    pieces.append({"token": "station_panel", "x": 0.0, "y": 1.8, "z": 0.06, "wall": True})
    # plinth + artifact per small item
    for i, lookup in enumerate(smalls):
        x = 1.0 + i * 2.0
        pieces.append({"token": "station_plinth", "x": x, "y": 0.0, "z": FLOOR_Z, "wall": False})
        pieces.append({"token": lookup, "x": x, "y": 1.0, "z": FLOOR_Z, "wall": False})
    # end pillars if >=2 items
    if n >= 2:
        pieces.append({"token": "station_pillar", "x": -1.0, "y": 0.0, "z": FLOOR_Z, "wall": False})
        right_x = (1.0 + (n - 1) * 2.0) + 2.0
        pieces.append({"token": "station_pillar", "x": right_x, "y": 0.0, "z": FLOOR_Z, "wall": False})
    return pieces


def main():
    spine = load_json(SPINE_PATH)
    sequences = spine.get("spine", {}).get("sequences", [])
    # iterate by order
    sequences = sorted(sequences, key=lambda s: s.get("order", 1e9))

    print("Scanning registries for SMALL artifacts ...")
    small_set, scene_set = build_registry_sets()
    print(f"  registry scenes: {len(scene_set)}  |  small artifacts: {len(small_set)}")

    result = {}
    total_small = 0
    maps_with_wall = 0
    missing_maps = 0

    for seq in sequences:
        seq_name = seq.get("name")
        if not seq_name:
            continue
        seq_file = os.path.join(SEQ_DIR, f"{seq_name}.json")
        if not os.path.isfile(seq_file):
            print(f"  WARN: no sequence file for '{seq_name}' (skipping)", file=sys.stderr)
            continue
        try:
            seq_data = load_json(seq_file)
        except (json.JSONDecodeError, OSError) as e:
            print(f"  WARN: cannot read sequence '{seq_name}': {e}", file=sys.stderr)
            continue
        seq_block = seq_data.get("sequences", {}).get(seq_name, {})
        map_names = seq_block.get("maps", [])
        if not isinstance(map_names, list):
            continue
        for map_name in map_names:
            if not isinstance(map_name, str) or not map_name.strip():
                continue
            map_name = map_name.strip()
            smalls = collect_map_smalls(map_name, small_set, scene_set)
            if smalls is None:
                missing_maps += 1
                continue
            if not smalls:
                continue
            pieces = build_pieces(smalls)
            result[map_name] = {
                "sequence": seq_name,
                "small_count": len(smalls),
                "pieces": pieces,
            }
            total_small += len(smalls)
            maps_with_wall += 1

    os.makedirs(OUT_DIR, exist_ok=True)
    with open(OUT_PATH, "w", encoding="utf-8") as f:
        json.dump(result, f, indent=2)

    print()
    print(f"Maps with a wall : {maps_with_wall}")
    print(f"Total small items: {total_small}")
    print(f"Missing map_data : {missing_maps}")
    print(f"Wrote            : {OUT_PATH}")
    return result, maps_with_wall, total_small


if __name__ == "__main__":
    main()
