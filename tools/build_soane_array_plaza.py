#!/usr/bin/env python3
"""
build_soane_array_plaza.py
==========================

Generates `Array_Soane_Plaza` — a Soane-museum plinth field with three
grid2d_substrate stations (disco, slow, random) sitting in the walkable
interspaces. The shell is the array; the substrates are different
cartridges of the same array, walked in curriculum order.

Architecture (matches user's framing):
    - Map shell:   soane_dense plinth pattern (h=3 plinths every 2 cells,
                   h=1 walkable plaza everywhere else).
    - Substrates:  three Grid2DSubstrate placements, each with a different
                   cartridge (disco = fast rhythm, slow = same rule slower,
                   random = E_entropy preview). All three live in the same
                   plaza so the player walks PAST them in sequence.
    - Curriculum:  primitives → arrays (this map) → color → ...
                   Within this map: disco → slow → random as the lesson
                   from F_order rhythm to E_entropy.

Run:
    python tools/build_soane_array_plaza.py
    python tools/build_soane_array_plaza.py --dry
"""

from __future__ import annotations
import argparse
import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
MAPS = REPO / "commons" / "maps"
MAP_NAME = "Array_Soane_Plaza"
MAP_DIR = MAPS / MAP_NAME

# Mirrors mg_soane_collection's footprint — same plinth grammar,
# explicitly playing the role of "shell."
ROWS = 16
COLS = 22

# Plinth layout: every 2 cells, starting at (2,2), like soane_dense.
PLINTH_STRIDE = 2
PLINTH_HEIGHT = 3
PLINTH_INSET = 2   # leave a 2-cell border around the plinth field

# Substrate slots — three open cells along the plaza, evenly spaced
# along the long axis. The substrates sit in the bottom row (open
# walkway, no plinths).
SUBSTRATES = [
    {"cell": (1, 4),  "algorithm": "disco",  "interval": 0.08, "label": "DISCO"},
    {"cell": (1, 11), "algorithm": "slow",   "interval": 0.6,  "label": "SLOW"},
    {"cell": (1, 18), "algorithm": "random", "interval": 0.2,  "label": "RANDOM"},
]


def build_layers():
    structure = [["1" for _ in range(COLS)] for _ in range(ROWS)]
    utilities = [[" " for _ in range(COLS)] for _ in range(ROWS)]
    interactables = [[" " for _ in range(COLS)] for _ in range(ROWS)]

    # Spawn south, teleport north — walk through the plaza along its long axis.
    spawn_r, spawn_c = 0, COLS // 2
    tele_r, tele_c = ROWS - 1, COLS // 2
    utilities[spawn_r][spawn_c] = "sp"
    utilities[tele_r][tele_c] = "t"

    # Plinth field — same pattern as mg_soane_collection.
    plinth_cells = []
    # Plinth band starts a couple rows in (after the substrate row at r=1).
    for r in range(3, ROWS - 2, PLINTH_STRIDE):
        for c in range(PLINTH_INSET, COLS - PLINTH_INSET, PLINTH_STRIDE):
            structure[r][c] = str(PLINTH_HEIGHT)
            plinth_cells.append((r, c))

    # Place substrates. Each lookup name is unique so the registry can
    # carry per-station parameters; all three point at the same scene.
    substrate_placements = []
    for sub in SUBSTRATES:
        r, c = sub["cell"]
        if (r, c) in {(spawn_r, spawn_c), (tele_r, tele_c)}:
            continue
        if (r, c) in set(plinth_cells):
            structure[r][c] = "1"
        lookup = f"array_{sub['algorithm']}_substrate"
        interactables[r][c] = f"{lookup}:0:0"
        substrate_placements.append((sub, lookup))

    return structure, utilities, interactables, plinth_cells, substrate_placements


def build_map_data(plinth_cells, substrate_placements):
    structure, utilities, interactables, _, _ = build_layers()
    return {
        "map_info": {
            "name": MAP_NAME,
            "lookup_name": MAP_NAME,
            "description": (
                "A Soane plinth field with three grid2d substrates "
                "running the same array under three different cartridges: "
                "disco (fast rhythm), slow (same rule, slower tempo), "
                "random (no memory, full entropy). The plaza IS the "
                "array; the cartridges are the lesson. Walk south to "
                "north past disco, slow, random — feel the array's "
                "sameness and the cartridge's difference."
            ),
            "format": "json", "version": "1.0",
            "dimensions": {"width": COLS, "depth": ROWS,
                            "max_height": PLINTH_HEIGHT},
            "metadata": {
                "source": "build_soane_array_plaza.py",
                "n_plinths": len(plinth_cells),
                "n_substrates": len(substrate_placements),
                "qfep_connection": (
                    "An array is a regular substrate. Three cartridges "
                    "(F_order rhythm, slowed F_order, E_entropy fill) "
                    "show that what fills the array is independent of "
                    "what the array IS — substrate + cartridge factoring."
                ),
                "reference": (
                    "Sir John Soane's Museum, London — densely packed "
                    "plinths leaving narrow walkways. The shell idiom."
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
            "background": {"type": "sky", "color": [0.07, 0.08, 0.12]},
            "grid_animation": {"enabled": False},
            "initial_tile_visibility": "hidden_except_corners",
        },
        "utility_definitions": {
            "sp": {"type": "spawn"},
            "t":  {"type": "teleporter"},
        },
    }


def build_registry_entries(substrate_placements):
    """Three artifact entries — one per cartridge — pointing at the
    grid2d_substrate scene with per-station parameters."""
    registry = {}
    for sub, lookup in substrate_placements:
        registry[lookup] = {
            "lookup_name": lookup,
            "name": f"Array {sub['label']} Substrate",
            "description": (
                f"Grid2D substrate running cartridge '{sub['algorithm']}' "
                f"at step interval {sub['interval']}s. One station of the "
                f"Array_Soane_Plaza triptych — same array, different cadence."
            ),
            "category": "substrate",
            "complexity": "beginner",
            "scene": "res://commons/substrates/grid2d/grid2d_substrate.tscn",
            "include_in_map_data": True,
            "map_ready": True,
            "map_sequences": ["array_tutorial"],
            "footprint": [1, 1, 1],
            "tags": ["array", "substrate", "grid2d", sub["algorithm"],
                     "soane", "cartridge"],
            "qfep_connection": (
                "F_order rhythm" if sub["algorithm"] == "disco"
                else "F_order at slower tempo" if sub["algorithm"] == "slow"
                else "E_entropy as cartridge over F_order substrate"
            ),
            "parameters": {
                "algorithm": sub["algorithm"],
                "interval":  sub["interval"],
                "auto_play": "true",
                "footprint": [1, 1, 1],
                "size_group": "compact",
                "label_text": sub["label"],
            },
            "size_group": "compact",
        }
    return registry


def write_blurb_intent():
    blurb = (
        "# Array_Soane_Plaza\n\n"
        "A Soane-museum plinth field in the array_tutorial sequence. "
        "Three grid2d substrates sit in the open plaza, each running "
        "the same array under a different cartridge: disco (fast "
        "rhythm), slow (the same rule slowed down), random (no memory "
        "at all). Walk south to north — disco, slow, random — and "
        "feel the array as a substrate that holds whatever you put in.\n"
    )
    intent = (
        "# Intent — Array_Soane_Plaza\n\n"
        "## Purpose\n"
        "Make the substrate / cartridge distinction visible. The plaza "
        "is the array; what fills it is a choice. Same hardware, three "
        "stories.\n\n"
        "## What the player learns\n"
        "- An array is reusable; what runs on it is configurable.\n"
        "- Tempo is a parameter, not part of the rule (disco vs. slow).\n"
        "- Without history, the same array reads as entropy (random).\n\n"
        "## Pedagogical role\n"
        "Array_tutorial sequence, mid-arc map. Sets up the eventual "
        "transitions: array → color (palette as cartridge), array → "
        "wavefunctions (oscillation as cartridge), array → "
        "randomness/noise (the random preview here is the bridge).\n\n"
        "## Authoring source\n"
        "Generated by `tools/build_soane_array_plaza.py`. The three "
        "cartridges (disco, slow, random) live at "
        "`commons/substrates/grid2d/cartridges/cartridge_<name>.gd`. "
        "Registered in `Grid2DSubstrate.Algorithm` enum. Per-station "
        "parameters in `commons/artifacts/registry/array_substrates.json`.\n\n"
        "## Reference\n"
        "Sir John Soane's Museum, London — the original plinth-field "
        "interior. Daniel Buren's Palais-Royal columns share the "
        "indexing-as-art instinct.\n"
    )
    return blurb, intent


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dry", action="store_true",
                    help="Print summary, don't write files.")
    args = ap.parse_args()

    _, _, _, plinth_cells, substrate_placements = build_layers()
    print(f"Map:          {MAP_NAME}")
    print(f"Grid:         {ROWS}x{COLS}")
    print(f"Plinths:      {len(plinth_cells)} at h={PLINTH_HEIGHT}")
    print(f"Substrates:   {len(substrate_placements)}")
    for sub, lookup in substrate_placements:
        r, c = sub["cell"]
        print(f"  - ({r},{c}) {lookup}  algo={sub['algorithm']}  "
              f"interval={sub['interval']}s")
    print(f"Out:          {MAP_DIR.relative_to(REPO)}/")

    if args.dry:
        print("\n[dry run — no files written]")
        return

    MAP_DIR.mkdir(parents=True, exist_ok=True)

    md = build_map_data(plinth_cells, substrate_placements)
    (MAP_DIR / "map_data.json").write_text(
        json.dumps(md, indent="\t", ensure_ascii=False) + "\n",
        encoding="utf-8")

    blurb, intent = write_blurb_intent()
    (MAP_DIR / "blurb.md").write_text(blurb, encoding="utf-8")
    (MAP_DIR / "intent.md").write_text(intent, encoding="utf-8")

    reg_payload = {
        "id": "array_substrates",
        "name": "Array Substrates",
        "description": (
            "Grid2D substrate stations for the array_tutorial sequence. "
            "Three cartridges (disco, slow, random) demonstrating "
            "substrate ↔ cartridge factoring."
        ),
        "category": "substrate",
        "theoreticalGrounding": (
            "Substrate-cartridge separation: the array is the reusable "
            "object, the cartridge is the algorithm running on it. "
            "Same hardware, many stories."
        ),
        "artifacts": build_registry_entries(substrate_placements),
    }
    reg_path = (REPO / "commons" / "artifacts" / "registry" /
                "array_substrates.json")
    reg_path.write_text(
        json.dumps(reg_payload, indent="\t", ensure_ascii=False) + "\n",
        encoding="utf-8")

    print(f"\nWrote:")
    print(f"  {MAP_DIR.relative_to(REPO)}/map_data.json")
    print(f"  {MAP_DIR.relative_to(REPO)}/blurb.md")
    print(f"  {MAP_DIR.relative_to(REPO)}/intent.md")
    print(f"  {reg_path.relative_to(REPO)}   "
          f"({len(substrate_placements)} substrate artifacts)")
    print()
    print("Next:")
    print(f"  http://localhost:3003/map-3d/{MAP_NAME}   (Three.js skeleton view, no Godot needed)")
    print()
    print("Capture in Godot:")
    print(f"  godot --path . --xr-mode off --no-window \\")
    print(f"    --script res://commons/testing/capture_multi_angle.gd -- \\")
    print(f"    --mode=map --target={MAP_NAME} \\")
    print(f"    --out=C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/captures/maps")


if __name__ == "__main__":
    main()
