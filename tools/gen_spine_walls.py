#!/usr/bin/env python3
"""gen_spine_walls.py — generate a RICHER wall layout for each spine map from its full
artifact LADDER (small / medium / large / applied), each prop sized to its footprint.

For each spine sequence (in `order`), for each map (in order), collect the map's
registry-known artifacts (unique, in interactables grid row-major order), classify each
into a tier (from the concept maps, falling back to footprint), and lay the tiers out
left -> right along +X with a gap between tier groups. Each artifact stands on a
FOOTPRINT-SIZED prop:

    area <= 1  -> station_plinth  {width_cells:1, depth_cells:1, top_height:1.2}
    area 2-4   -> station_plinth  {width_cells:w, depth_cells:h, top_height:0.9}
    area 5-9   -> station_stage    sized to (w, h), low step
    area > 9   -> station_stage    at a capped large footprint

Per non-empty tier group: a station_panel label slot on the wall above it, and a
station_pillar divider between adjacent tier groups.

World metres; the editor's FLOOR_Z = 0.8. The editor re-seats artifacts to the real
prop-top height on load, so the y here is an approximation.

Output: commons/data/spine_walls.json — every map with >= 1 registry-known artifact.
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
CONCEPT_DIR = os.path.join(REPO, "doc")
OUT_DIR = os.path.join(REPO, "commons", "data")
OUT_PATH = os.path.join(OUT_DIR, "spine_walls.json")

FLOOR_Z = 0.8           # editor convention: z for floor-standing pieces
WALL_Z = 0.06           # z for wall-mounted pieces (panels)
PANEL_Y = 1.9           # height of the label panel above a tier group
PILLAR_GAP = 1.0        # x gap reserved for a divider pillar between tier groups
GROUP_GAP = 2.0         # extra x gap between tier groups (on top of the pillar gap)

TIER_ORDER = ["small", "medium", "large", "applied"]

# Prop sizing constants.
PLINTH_TOP_SMALL = 1.2  # tall narrow podium for a tiny precious thing
PLINTH_TOP_MED = 0.9    # lower broad plinth for a 2-4 cell thing
STAGE_STEP = 0.18       # low step for a staged large item
STAGE_CAP = 4           # capped footprint (cells per side) for >9-area items


def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def lookup_from_token(token):
    """Strip a token's config suffix: the part before the first ':' or '#'."""
    s = str(token).strip()
    for sep in (":", "#"):
        idx = s.find(sep)
        if idx != -1:
            s = s[:idx]
    return s.strip()


# --------------------------------------------------------------------------- #
# Registry: footprint + dims + scene per artifact lookup.
# --------------------------------------------------------------------------- #

def _ceil_pos(v, fallback):
    try:
        c = int(math.ceil(float(v)))
        return c if c >= 1 else fallback
    except (TypeError, ValueError):
        return fallback


def footprint_of(entry):
    """Compute (area, w, h) for one registry entry, per the recipe precedence.

    1. measurements.grid_cells = [w, h]  -> area = ceil(w)*ceil(h), dims = (ceil w, ceil h)
    2. spatial_needs.footprint_cells (area) -> dims = (1, 1) fallback
    3. size_group: compact/small -> 1, medium -> 4, large -> 9, else 1; dims = (1, 1)
    Returns None if no footprint signal at all.
    """
    if not isinstance(entry, dict):
        return None

    # 1. measurements.grid_cells
    meas = entry.get("measurements")
    if isinstance(meas, dict):
        gc = meas.get("grid_cells")
        if isinstance(gc, (list, tuple)) and len(gc) >= 2:
            w = _ceil_pos(gc[0], None)
            h = _ceil_pos(gc[1], None)
            if w is not None and h is not None:
                return (w * h, w, h)

    # 2. spatial_needs.footprint_cells (area only)
    sn = entry.get("spatial_needs")
    if isinstance(sn, dict):
        fc = sn.get("footprint_cells")
        try:
            if fc is not None:
                area = int(math.ceil(float(fc)))
                if area >= 1:
                    return (area, 1, 1)
        except (TypeError, ValueError):
            pass

    # 3. size_group (direct or under parameters)
    sg = entry.get("size_group")
    if sg is None:
        params = entry.get("parameters")
        if isinstance(params, dict):
            sg = params.get("size_group")
    if isinstance(sg, str):
        key = sg.strip().lower()
        area = {"compact": 1, "small": 1, "medium": 4, "large": 9}.get(key, 1)
        return (area, 1, 1)

    return None


def build_registry():
    """Scan registry/*.json. Return lookup -> {area, w, h, scene}.

    Keep ONLY registry-known artifacts that carry a `scene`. Entries live under the
    "artifacts" key OR at the root of the file.
    """
    reg = {}
    for fn in sorted(os.listdir(REG_DIR)):
        if not fn.endswith(".json") or fn.endswith(".bak"):
            continue
        path = os.path.join(REG_DIR, fn)
        try:
            data = load_json(path)
        except (json.JSONDecodeError, OSError) as e:
            print(f"  WARN: skip registry {fn}: {e}", file=sys.stderr)
            continue
        if not isinstance(data, dict):
            continue
        arts = data.get("artifacts")
        container = arts if isinstance(arts, dict) else data
        for key, entry in container.items():
            if not isinstance(entry, dict):
                continue
            scene = entry.get("scene")
            if not (isinstance(scene, str) and scene.strip()):
                continue
            name = entry.get("lookup_name") or key
            name = str(name).strip()
            if not name:
                continue
            fp = footprint_of(entry)
            area, w, h = fp if fp else (1, 1, 1)
            # First registry occurrence wins (deterministic over sorted filenames).
            if name not in reg:
                reg[name] = {"area": area, "w": w, "h": h, "scene": scene.strip()}
    return reg


# --------------------------------------------------------------------------- #
# Concept maps: lookup -> tier.
# --------------------------------------------------------------------------- #

def build_tier_map():
    """Scan doc/*_concept_map.json. Return lookup -> tier (small/medium/large/applied).

    Shape: concept_meta.<Concept>.tiers.{small,medium,large,applied} = [lookup, ...].
    First occurrence wins (deterministic: sorted files, then concept order, then
    TIER_ORDER). An artifact already mapped is not reassigned.
    """
    tiers = {}
    files = sorted(
        f for f in os.listdir(CONCEPT_DIR)
        if f.endswith("_concept_map.json")
    )
    for fn in files:
        path = os.path.join(CONCEPT_DIR, fn)
        try:
            data = load_json(path)
        except (json.JSONDecodeError, OSError) as e:
            print(f"  WARN: skip concept map {fn}: {e}", file=sys.stderr)
            continue
        cm = data.get("concept_meta")
        if not isinstance(cm, dict):
            continue
        for _concept, meta in cm.items():
            if not isinstance(meta, dict):
                continue
            t = meta.get("tiers")
            if not isinstance(t, dict):
                continue
            for tier_name in TIER_ORDER:
                for lookup in (t.get(tier_name) or []):
                    name = str(lookup).strip()
                    if name and name not in tiers:
                        tiers[name] = tier_name
    return tiers


def tier_from_area(area):
    """Footprint fallback when an artifact is in no concept map."""
    if area <= 1:
        return "small"
    if area <= 4:
        return "medium"
    if area <= 9:
        return "large"
    return "applied"


# --------------------------------------------------------------------------- #
# Map -> ordered registry-known artifacts.
# --------------------------------------------------------------------------- #

def collect_map_artifacts(map_name, reg):
    """Return unique registry-known lookups for a map, in grid row-major order.

    Returns None if map_data.json is missing (signal to the caller).
    """
    mpath = os.path.join(MAPS_DIR, map_name, "map_data.json")
    if not os.path.isfile(mpath):
        return None
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
            if lookup not in reg:           # registry-known (has a scene) only
                continue
            seen.add(lookup)
            ordered.append(lookup)
    return ordered


# --------------------------------------------------------------------------- #
# Prop sizing.
# --------------------------------------------------------------------------- #

def prop_for(area, w, h):
    """Return (prop_token, config_dict, top_y) for an artifact's footprint.

    top_y is the approximate height the artifact's base sits at (prop top).
    """
    if area <= 1:
        return ("station_plinth",
                {"width_cells": 1, "depth_cells": 1, "top_height": PLINTH_TOP_SMALL},
                PLINTH_TOP_SMALL)
    if area <= 4:
        return ("station_plinth",
                {"width_cells": int(w), "depth_cells": int(h), "top_height": PLINTH_TOP_MED},
                PLINTH_TOP_MED)
    if area <= 9:
        return ("station_stage",
                {"width_cells": int(w), "depth_cells": int(h), "step_height": STAGE_STEP},
                STAGE_STEP)
    # area > 9 — cap the stage footprint so a huge thing still lands on a sane deck.
    cw = min(int(w), STAGE_CAP)
    ch = min(int(h), STAGE_CAP)
    return ("station_stage",
            {"width_cells": cw, "depth_cells": ch, "step_height": STAGE_STEP},
            STAGE_STEP)


def build_pieces(grouped, reg):
    """Build wall pieces for a map's tier groups.

    grouped: ordered dict-like list of (tier_name, [lookups]) with >= 1 lookup each.
    Lays groups left -> right along +X; within a group, items step by max(2, w+1).
    """
    pieces = []
    x = 0.0
    first_group = True

    for gi, (tier_name, lookups) in enumerate(grouped):
        if not lookups:
            continue
        if not first_group:
            # Divider pillar in the gap between this group and the previous one,
            # then advance past the pillar + the extra group gap.
            pillar_x = x
            pieces.append({"token": "station_pillar", "x": round(pillar_x, 3),
                           "y": 0.0, "z": FLOOR_Z, "wall": False})
            x += PILLAR_GAP + GROUP_GAP
        first_group = False

        group_start_x = x
        for lookup in lookups:
            info = reg[lookup]
            area, w, h = info["area"], info["w"], info["h"]
            prop_token, config, top_y = prop_for(area, w, h)
            # Footprint-sized prop on the floor.
            pieces.append({"token": prop_token, "x": round(x, 3),
                           "y": 0.0, "z": FLOOR_Z, "wall": False,
                           "config": config})
            # The artifact sits on the prop top.
            pieces.append({"token": lookup, "x": round(x, 3),
                           "y": round(top_y, 3), "z": FLOOR_Z, "wall": False})
            # Step to the next item: max(2, w+1) cells.
            x += max(2.0, float(w) + 1.0)

        group_end_x = x  # x has stepped one slot past the last item
        # One label panel on the wall, centred over this tier group.
        label_x = (group_start_x + group_end_x - max(2.0, 1.0)) * 0.5
        pieces.append({"token": "station_panel",
                       "x": round(label_x, 3), "y": PANEL_Y, "z": WALL_Z,
                       "wall": True})

    return pieces


# --------------------------------------------------------------------------- #
# Main.
# --------------------------------------------------------------------------- #

def main():
    spine = load_json(SPINE_PATH)
    sequences = spine.get("spine", {}).get("sequences", [])
    sequences = sorted(sequences, key=lambda s: s.get("order", 1e9))

    print("Building registry (footprint + scene) ...")
    reg = build_registry()
    print(f"  registry artifacts with scene: {len(reg)}")

    print("Building tier map from concept maps ...")
    tier_map = build_tier_map()
    print(f"  artifacts with a concept-map tier: {len(tier_map)}")

    result = {}
    total_artifacts = 0
    tier_totals = {t: 0 for t in TIER_ORDER}
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
            if map_name in result:
                continue  # a map can be listed once; guard against dupes across seqs
            arts = collect_map_artifacts(map_name, reg)
            if arts is None:
                missing_maps += 1
                continue
            if not arts:
                continue

            # Classify each artifact into a tier; group in tier order, preserving
            # grid order within each tier.
            groups = {t: [] for t in TIER_ORDER}
            for lookup in arts:
                tier = tier_map.get(lookup)
                if tier not in TIER_ORDER:
                    tier = tier_from_area(reg[lookup]["area"])
                groups[tier].append(lookup)

            grouped = [(t, groups[t]) for t in TIER_ORDER if groups[t]]
            pieces = build_pieces(grouped, reg)

            counts = {t: len(groups[t]) for t in TIER_ORDER}
            result[map_name] = {
                "sequence": seq_name,
                "counts": counts,
                "pieces": pieces,
            }

            n = len(arts)
            total_artifacts += n
            for t in TIER_ORDER:
                tier_totals[t] += counts[t]
            maps_with_wall += 1

    os.makedirs(OUT_DIR, exist_ok=True)
    with open(OUT_PATH, "w", encoding="utf-8") as f:
        json.dump(result, f, indent=2)

    print()
    print(f"Maps with a wall   : {maps_with_wall}")
    print(f"Total artifacts    : {total_artifacts}")
    print(f"Tier distribution  : " + "  ".join(f"{t}={tier_totals[t]}" for t in TIER_ORDER))
    print(f"Missing map_data   : {missing_maps}")
    print(f"Wrote              : {OUT_PATH}")
    return result, maps_with_wall, total_artifacts, tier_totals


if __name__ == "__main__":
    main()
