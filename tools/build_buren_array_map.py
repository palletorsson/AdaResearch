#!/usr/bin/env python3
"""
build_buren_array_map.py
=========================

Generates `Array_Buren_Courtyard` — a hero map for the array_tutorial sequence
modelled on Daniel Buren's "Les Deux Plateaux" at Palais-Royal: a regular grid
of striped columns of varying heights set into a walkable courtyard. Same
composition primitive (a vertical stripe stack), indexed across the array,
with variation in height and palette as the array's lesson.

Outputs:
    commons/maps/Array_Buren_Courtyard/
        map_data.json
        configs/buren_col_<r>_<c>.json   (per-column primitive_stack configs)
        blurb.md
        intent.md

Each column slot in the map's interactables layer references a
`composition_artifact` registry entry pointing at one of the configs. The
composition_artifact loader (commons/artifacts/composition_artifact/) calls
primitive_stack.build() to render at runtime.

Run:
    python tools/build_buren_array_map.py            # write to disk
    python tools/build_buren_array_map.py --dry      # print, don't write
"""

from __future__ import annotations
import argparse
import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
MAPS = REPO / "commons" / "maps"
MAP_NAME = "Array_Buren_Courtyard"
MAP_DIR = MAPS / MAP_NAME

# 14×14 grid is comfortable in VR; 14 cells of 1m each = a 14m courtyard.
ROWS = 14
COLS = 14

# Buren's columns sit on a 3-cell grid; cells in between are walkable plaza.
COL_STRIDE = 3            # column at every (r,c) where r%3==1 and c%3==1
PLAZA_HEIGHT = 1          # cube height of the walkable surface

# Black-and-white striped palette (Buren's signature). Two shades close to
# pure black/white but slightly off so emission/shading reads.
STRIPE_BLACK = "#0a0a0a"
STRIPE_WHITE = "#f0f0ec"
PALETTE_NAME = "buren_stripes"

# How many stripes per column — Buren's are tall and finely striped.
STRIPES_PER_COLUMN = 7

# Column heights cycle through 5 values so adjacent columns vary clearly.
HEIGHT_TIERS = [2, 5, 3, 4, 6]   # cube tiers (1 cube ≈ 1m of stripe stack)


def column_config(row: int, col: int) -> dict:
    """A primitive_stack vertical_stack config for one column slot."""
    tier_idx = (row + col) % len(HEIGHT_TIERS)
    tier = HEIGHT_TIERS[tier_idx]
    # Build the stripe stack — alternating black/white slim cuboids.
    sequence = []
    for i in range(STRIPES_PER_COLUMN):
        stripe_color = STRIPE_BLACK if i % 2 == 0 else STRIPE_WHITE
        sequence.append({
            "shape": "cuboid",
            "color": stripe_color,
            "scale": 1.0,
            # The stripe widths are uniform — Buren's stripes are 8.7 cm.
            # We scale the stack vertically by tier, horizontally constant.
        })
    # Height tier scales the whole stack vertically. base_scale stretches.
    return {
        "id": f"buren_col_{row:02d}_{col:02d}",
        "notes": f"Buren-stripe column at ({row},{col}), tier {tier}",
        "layout": "vertical_stack",
        "palette": PALETTE_NAME,
        "base_scale": 0.18 * tier / 3.0,
        "sequence": sequence,
    }


def build_layers():
    """Three-layer structure / utilities / interactables for map_data.json."""
    structure = [["1" for _ in range(COLS)] for _ in range(ROWS)]
    utilities = [[" " for _ in range(COLS)] for _ in range(ROWS)]
    interactables = [[" " for _ in range(COLS)] for _ in range(ROWS)]

    # Spawn at the south edge so you walk INTO the courtyard, like
    # entering Palais-Royal. Teleport at the opposite edge.
    spawn_r, spawn_c = 0, COLS // 2
    tele_r, tele_c = ROWS - 1, COLS // 2
    utilities[spawn_r][spawn_c] = "sp"
    utilities[tele_r][tele_c] = "t"

    # Place a column at every (r,c) where r and c are at COL_STRIDE
    # offsets, but skip any cell that holds spawn or teleport.
    column_cells = []
    for r in range(1, ROWS - 1, COL_STRIDE):
        for c in range(1, COLS - 1, COL_STRIDE):
            if (r, c) in ((spawn_r, spawn_c), (tele_r, tele_c)):
                continue
            lookup = f"buren_col_{r:02d}_{c:02d}"
            interactables[r][c] = f"{lookup}:0:0"
            column_cells.append((r, c))

    return structure, utilities, interactables, column_cells


def build_map_data(column_cells):
    structure, utilities, interactables, _ = build_layers()
    return {
        "map_info": {
            "name": MAP_NAME,
            "lookup_name": MAP_NAME,
            "description": (
                "Buren's striped columns reimagined as the array sequence's "
                "central installation. A 14x14 plaza, every 3rd cell holding "
                "a vertical_stack composition of black-and-white stripes. "
                "Same composition primitive, indexed across the array, "
                "varying in height with (row + col) mod 5. The lesson IS the "
                "variation."
            ),
            "format": "json", "version": "1.0",
            "dimensions": {"width": COLS, "depth": ROWS, "max_height": 6},
            "metadata": {
                "source": "build_buren_array_map.py",
                "n_artifacts": len(column_cells),
                "qfep_connection": (
                    "F_order: an array is a regular indexing of position. The "
                    "same composition placed at every index, with one parameter "
                    "varying by index, makes the indexing visible. Array "
                    "comprehension as embodied walk."
                ),
                "reference": (
                    "Daniel Buren, Les Deux Plateaux (1986), Palais-Royal courtyard."
                ),
            },
        },
        "layers": {
            "structure":     structure,
            "utilities":     utilities,
            "interactables": interactables,
        },
        "settings": {
            "cube_size": 1, "gutter": 0, "show_grid": True,
            "background": {"type": "sky", "color": [0.62, 0.62, 0.65]},
            "grid_animation": {"enabled": False},
            "initial_tile_visibility": "hidden_except_corners",
        },
        "utility_definitions": {
            "sp": {"type": "spawn"},
            "t":  {"type": "teleporter"},
        },
    }


def write_blurb_intent():
    blurb = (
        "# Array_Buren_Courtyard\n\n"
        "Walk through Buren. Forty-nine striped columns set in a 14×14 "
        "plaza, every third cell. Same composition repeated across the "
        "grid; height shifts with `(row + col) % 5`. The variation is "
        "the lesson — an array becomes legible by what changes across "
        "its indices.\n"
    )
    intent = (
        "# Intent — Array_Buren_Courtyard\n\n"
        "## Purpose\n"
        "First map of the array_tutorial sequence's hero arc. Establishes "
        "that an array is not just a row of values — it's a regular "
        "indexing where the *placement* itself carries meaning. Buren's "
        "columns work because the courtyard's grid is the substrate; "
        "stripped of that grid the columns lose their argument.\n\n"
        "## What the player learns\n"
        "- The same composition placed at every grid position becomes a "
        "field of reference points.\n"
        "- Variation across the field (here: height as a function of "
        "row+col) is what makes the array readable.\n"
        "- Indexing is spatial before it is symbolic.\n\n"
        "## Authoring source\n"
        "Generated by `tools/build_buren_array_map.py`. Per-column "
        "configs live in `configs/`. Each config is a primitive_stack "
        "`vertical_stack` of alternating black/white cuboids. Configs "
        "loaded at runtime by `composition_artifact` (calls "
        "`primitive_stack.build`).\n\n"
        "## Reference\n"
        "Daniel Buren, *Les Deux Plateaux* (1986), Palais-Royal "
        "courtyard, Paris.\n"
    )
    return blurb, intent


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dry", action="store_true",
                    help="Print summary, don't write files.")
    args = ap.parse_args()

    _, _, _, column_cells = build_layers()
    print(f"Map:    {MAP_NAME}")
    print(f"Grid:   {ROWS}x{COLS}")
    print(f"Spawn:  (1,1)   Teleport: ({ROWS-2},{COLS-2})")
    print(f"Cols:   {len(column_cells)} striped columns")
    print(f"Out:    {MAP_DIR.relative_to(REPO)}/")

    if args.dry:
        print("\n[dry run — no files written]")
        return

    MAP_DIR.mkdir(parents=True, exist_ok=True)
    cfg_dir = MAP_DIR / "configs"
    cfg_dir.mkdir(exist_ok=True)

    # Per-column configs.
    for r, c in column_cells:
        cfg = column_config(r, c)
        (cfg_dir / f"{cfg['id']}.json").write_text(
            json.dumps(cfg, indent=2) + "\n", encoding="utf-8")

    # Map data.
    md = build_map_data(column_cells)
    (MAP_DIR / "map_data.json").write_text(
        json.dumps(md, indent="\t", ensure_ascii=False) + "\n",
        encoding="utf-8")

    # Documentation.
    blurb, intent = write_blurb_intent()
    (MAP_DIR / "blurb.md").write_text(blurb, encoding="utf-8")
    (MAP_DIR / "intent.md").write_text(intent, encoding="utf-8")

    # Registry entry: one entry per column, all pointing at the same
    # composition_artifact scene with a different config_path.
    registry_entries = {}
    for r, c in column_cells:
        lookup = f"buren_col_{r:02d}_{c:02d}"
        config_res_path = (
            f"res://commons/maps/{MAP_NAME}/configs/{lookup}.json"
        )
        registry_entries[lookup] = {
            "lookup_name": lookup,
            "name": f"Buren Column ({r},{c})",
            "description": (
                f"Striped vertical_stack column at ({r},{c}) in "
                f"{MAP_NAME}. Loaded via composition_artifact + "
                f"primitive_stack.build()."
            ),
            "category": "composition",
            "complexity": "beginner",
            "scene": "res://commons/artifacts/composition_artifact/composition_artifact.tscn",
            "include_in_map_data": True,
            "map_ready": True,
            "map_sequences": ["array_tutorial"],
            "footprint": [1, 1, 6],
            "tags": ["composition", "array", "buren", "stripes",
                     "vertical_stack", "primitive_stack"],
            "qfep_connection": (
                "F_order: a member of a regular array. Its identity "
                "is partly the index (r,c); its appearance differs "
                "from siblings only in tier height."
            ),
            "parameters": {
                "config_path": config_res_path,
                "grammar": "primitive_stack",
                "footprint": [1, 1, 6],
                "size_group": "tall",
            },
            "size_group": "tall",
        }

    reg_path = (REPO / "commons" / "artifacts" / "registry" /
                "buren_columns.json")
    reg_payload = {
        "id": "buren_columns",
        "name": "Buren Columns",
        "description": (
            "Per-cell registry entries for the Array_Buren_Courtyard "
            "hero map. Each entry references the composition_artifact "
            "scene with a per-column primitive_stack config."
        ),
        "category": "composition",
        "theoreticalGrounding": (
            "Buren's Les Deux Plateaux as embodied array — repetition "
            "with parametric variation makes indexing legible."
        ),
        "artifacts": registry_entries,
    }
    reg_path.write_text(
        json.dumps(reg_payload, indent="\t", ensure_ascii=False) + "\n",
        encoding="utf-8")

    print(f"\nWrote:")
    print(f"  {MAP_DIR.relative_to(REPO)}/map_data.json")
    print(f"  {MAP_DIR.relative_to(REPO)}/configs/   ({len(column_cells)} configs)")
    print(f"  {MAP_DIR.relative_to(REPO)}/blurb.md")
    print(f"  {MAP_DIR.relative_to(REPO)}/intent.md")
    print(f"  {reg_path.relative_to(REPO)}   ({len(registry_entries)} artifacts)")
    print()
    print("Next:")
    print(f"  godot --path . --xr-mode off --no-window \\")
    print(f"    --script res://commons/testing/capture_multi_angle.gd -- \\")
    print(f"    --mode=map --target={MAP_NAME}")


if __name__ == "__main__":
    main()
