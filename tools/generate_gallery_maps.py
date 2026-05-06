#!/usr/bin/env python3
"""
Generate gallery maps for unplaced artifacts.

Scans the artifact registry and all existing maps to find artifacts that
are registered but placed in zero maps. Groups them by sequence and
generates a walkable gallery map per sequence at
commons/maps/Gallery_{Seq}/map_data.json.

Usage:
  python tools/generate_gallery_maps.py                          # all
  python tools/generate_gallery_maps.py --sequence randomness    # one
  python tools/generate_gallery_maps.py --dry-run                # preview
  python tools/generate_gallery_maps.py --force                  # overwrite
  python tools/generate_gallery_maps.py --max-per-row 4          # layout
"""

import argparse
import json
import math
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from lib.plan_utils import (
    ROOT,
    MAPS_DIR,
    load_all_registries,
    build_map_placement_index,
)

# Registry file -> sequence name mapping
REG_TO_SEQ = {
    "randomness": "Randomness",
    "arrays": "Arrays",
    "machinelearning": "MachineLearning",
    "cellular_automata": "CellularAutomata",
    "wavefunctions": "WaveFunctions",
    "wavefunctions_extra": "WaveFunctions",
    "datastructures": "DataStructures",
    "physics_simulation": "PhysicsSimulation",
    "soft_bodies": "PhysicsSimulation",
    "shaders": "Shaders",
    "vectors": "Vectors",
    "vectors_demos": "Vectors",
    "transforms": "Transforms",
    "steering": "Steering",
    "swarmintelligence": "SwarmIntelligence",
    "statistics": "Statistics",
    "qfep": "QFEP",
    "parametric": "Parametric",
    "chaos": "Chaos",
    "living_paper": "LivingPaper",
    "mesh_grammar": "MeshGrammar",
    "bar_array": "BarArray",
    "grid2d": "Grid2D",
    "grid3d": "Grid3D",
    "profile": "Profile",
    "hazards": "Hazards",
    "lab": "Laboratory",
    "procgen_extra": "ProceduralGeneration",
    "isosurfaces": "ProceduralGeneration",
    "computational_biology": "ComputationalBiology",
    "speech": "Speech",
    "neuroscience": "Neuroscience",
    "alternative_geometries": "SpaceTopology",
    "primitives": "Primitives",
    "commons_artifacts": "Commons",
    "furniture": "Furniture",
    "algorithms_misc": "Misc",
    "color": "Color",
    "foundations": "Foundations",
    "nature_system": "Nature",
    "quantumalgorithms": "Quantum",
}

MAX_GALLERY_SIZE = 40  # max grid dimension before splitting


def find_unplaced_artifacts(registry: dict, placed: set) -> dict:
    """Group unplaced artifacts by target sequence.

    Returns {seq_name: [list of lookup_names]}.
    """
    by_seq = {}
    for ln, info in registry.items():
        if ln in placed:
            continue

        reg_file = info.get("_registry_file", "").replace(".json", "")
        seq = REG_TO_SEQ.get(reg_file, "")

        if not seq:
            seq = "Unassigned"

        if seq not in by_seq:
            by_seq[seq] = []
        by_seq[seq].append(ln)

    # Sort each list
    for seq in by_seq:
        by_seq[seq].sort()

    return by_seq


def generate_gallery_map_data(seq_name: str, artifacts: list, cols_per_row: int = 4) -> dict:
    """Generate a complete map_data.json dict for a gallery map."""
    n = len(artifacts)
    rows_needed = math.ceil(n / cols_per_row)

    # Grid dimensions: border + (artifact every 2 cells) + walkways
    grid_w = cols_per_row * 2 + 3
    grid_d = rows_needed * 2 + 4  # extra row for spawn and teleporter

    # Cap dimensions
    grid_w = min(grid_w, MAX_GALLERY_SIZE)
    grid_d = min(grid_d, MAX_GALLERY_SIZE)

    lookup_name = f"Gallery_{seq_name}"
    display_name = f"Gallery: {seq_name}"

    # Build structure layer (all floor=1, border=2)
    structure = []
    for row in range(grid_d):
        r = []
        for col in range(grid_w):
            if row == 0 or row == grid_d - 1 or col == 0 or col == grid_w - 1:
                r.append("2")
            else:
                r.append("1")
        structure.append(r)

    # Build utilities layer (spawn top-left corner, teleporter bottom-right)
    utilities = []
    for row in range(grid_d):
        utilities.append([" "] * grid_w)

    # Spawn at row 0, col 1 (inside border)
    utilities[0][1] = "sp"
    # Teleporter near bottom-right — must be on void (height 0)
    t_row = grid_d - 2
    t_col = grid_w - 2
    utilities[t_row][t_col] = "t"
    structure[t_row][t_col] = "0"  # void for teleporter

    # Build interactables layer
    interactables = []
    for row in range(grid_d):
        interactables.append([" "] * grid_w)

    # Place artifacts in a grid pattern
    # Starting at row 2, col 2, spacing every 2 cells
    art_idx = 0
    for art_row in range(rows_needed):
        grid_row = 2 + art_row * 2
        if grid_row >= grid_d - 1:
            break

        for art_col in range(cols_per_row):
            if art_idx >= n:
                break
            grid_col = 2 + art_col * 2
            if grid_col >= grid_w - 1:
                break

            artifact_name = artifacts[art_idx]
            interactables[grid_row][grid_col] = f"{artifact_name}:0:-0.5"

            # Place request_note label one row above with artifact name
            label_row = grid_row - 1
            if label_row >= 1 and interactables[label_row][grid_col] == " ":
                # Truncate long names for label
                short_name = artifact_name.replace("_", " ")
                if len(short_name) > 30:
                    short_name = short_name[:27] + "..."
                interactables[label_row][grid_col] = f"request_note:0:1.5#text:{short_name}"

            art_idx += 1

    return {
        "map_info": {
            "name": display_name,
            "lookup_name": lookup_name,
            "description": f"Showcase of {n} unplaced artifacts from {seq_name}. Walk through to browse available artifacts.",
            "version": "1.0",
            "format": "json",
            "dimensions": {
                "width": grid_w,
                "depth": grid_d,
                "max_height": 2
            },
            "metadata": {
                "difficulty": "gallery",
                "category": "gallery",
                "estimated_time": f"{max(2, n // 3)}-{max(5, n // 2)} minutes",
                "learning_objectives": [
                    f"Browse {n} {seq_name} artifacts",
                    "Identify artifacts for placement in curriculum maps",
                    "Observe artifact visual and interaction patterns"
                ]
            },
            "title": f"{seq_name} Artifact Gallery"
        },
        "utility_definitions": {
            "t": {
                "type": "teleporter",
                "name": "Back",
                "description": "Return to sequence",
                "properties": {
                    "action": "next_in_sequence"
                }
            },
            "s": {
                "type": "spawn",
                "properties": {
                    "height": 1.5
                }
            }
        },
        "settings": {
            "cube_size": 1.0,
            "gutter": 0.0,
            "show_grid": True,
            "enable_physics": True,
            "background": {
                "type": "sky",
                "color": [0.3, 0.3, 0.35]
            }
        },
        "lighting": {
            "ambient_color": [0.5, 0.5, 0.55],
            "ambient_energy": 0.7,
            "directional_light": {
                "enabled": True,
                "direction": [-0.3, -0.8, -0.3],
                "color": [1.0, 0.95, 0.9],
                "energy": 0.8
            }
        },
        "layers": {
            "structure": structure,
            "utilities": utilities,
            "interactables": interactables
        }
    }


def main():
    parser = argparse.ArgumentParser(description="Generate gallery maps for unplaced artifacts")
    parser.add_argument("--sequence", help="Generate for one sequence only")
    parser.add_argument("--force", action="store_true", help="Overwrite existing gallery maps")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be generated")
    parser.add_argument("--max-per-row", type=int, default=4, help="Artifacts per row (default: 4)")
    args = parser.parse_args()

    print("Loading registries...")
    registry = load_all_registries()
    print(f"  {len(registry)} artifacts in registry")

    print("Scanning map placements...")
    map_index = build_map_placement_index()
    placed = set(map_index.keys())
    print(f"  {len(placed)} artifacts placed in maps")

    print("Finding unplaced artifacts...")
    by_seq = find_unplaced_artifacts(registry, placed)
    total_unplaced = sum(len(v) for v in by_seq.values())
    print(f"  {total_unplaced} unplaced across {len(by_seq)} sequences")

    # Filter to requested sequence
    if args.sequence:
        # Find matching sequence (case-insensitive)
        target = None
        for seq_name in by_seq:
            if seq_name.lower() == args.sequence.lower():
                target = seq_name
                break
        if not target:
            print(f"No unplaced artifacts for sequence '{args.sequence}'")
            print(f"Available: {', '.join(sorted(by_seq.keys()))}")
            return
        by_seq = {target: by_seq[target]}

    generated = 0
    skipped = 0

    for seq_name in sorted(by_seq.keys()):
        artifacts = by_seq[seq_name]
        if not artifacts:
            continue

        # Split large collections into multiple galleries
        chunks = []
        if len(artifacts) > 60:
            chunk_size = 30
            for i in range(0, len(artifacts), chunk_size):
                chunk = artifacts[i:i + chunk_size]
                suffix = f"_{i // chunk_size + 1}" if len(artifacts) > chunk_size else ""
                chunks.append((f"{seq_name}{suffix}", chunk))
        else:
            chunks.append((seq_name, artifacts))

        for gallery_name, chunk_artifacts in chunks:
            map_name = f"Gallery_{gallery_name}"
            map_dir = MAPS_DIR / map_name
            map_file = map_dir / "map_data.json"

            if map_file.exists() and not args.force:
                skipped += 1
                continue

            if args.dry_run:
                print(f"  [dry-run] {map_name}: {len(chunk_artifacts)} artifacts ({grid_dims(chunk_artifacts, args.max_per_row)})")
                generated += 1
                continue

            # Generate
            data = generate_gallery_map_data(gallery_name, chunk_artifacts, args.max_per_row)

            map_dir.mkdir(parents=True, exist_ok=True)
            with open(map_file, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2, ensure_ascii=False)

            generated += 1
            print(f"  [{generated}] {map_name}: {len(chunk_artifacts)} artifacts")

    print(f"\nDone. Generated: {generated}, Skipped: {skipped}")
    print(f"Output: {MAPS_DIR}/Gallery_*/map_data.json")


def grid_dims(artifacts, cols_per_row):
    """Calculate grid dimensions for display."""
    n = len(artifacts)
    rows = math.ceil(n / cols_per_row)
    w = cols_per_row * 2 + 3
    d = rows * 2 + 4
    return f"{w}x{d}"


if __name__ == "__main__":
    main()
