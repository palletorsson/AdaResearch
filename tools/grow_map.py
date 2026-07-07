"""tools/grow_map.py — create a new map by walking + laying floor.

Inverts the placement loop. Instead of taking a fixed room and placing
artifacts INTO it, this tool:
  1. Takes a list of artifact lookup_names (their spatial_needs are read
     from the registry)
  2. Configures a max-size bounding box (default 15×10×3)
  3. Runs strategy_grow_walker, which walks empty space laying floor +
     tables as it goes, places artifacts with clearance, ends with the
     teleporter at the final position
  4. Reads the trace to assemble a complete map_data.json:
       - structure layer: laid cells = "2" (height 1), table cells = "3" (height 2)
       - utilities layer: spawn + teleporter
       - interactables layer: placed artifacts
  5. Writes commons/maps/Grown_<name>/{map_data.json, intent.md, blurb.md}

Run:
  python tools/grow_map.py --name=MyTestRoom --artifacts=astar,point,xyz_slider_plate
  python tools/grow_map.py --name=GrownPrimitives --from-map=Point_Tests
  python tools/grow_map.py --name=Showcase --artifacts=GaussianBlurCircle,FlowFieldMain \
                            --max-width=20 --max-depth=15

Then capture:
  godot_console --path . --xr-mode off --no-window \
    --script res://commons/testing/capture_multi_angle.gd -- --mode=map --target=Grown_MyTestRoom
"""
from __future__ import annotations

import argparse
import json
import random
import sys
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
MAPS_DIR = ROOT / "commons" / "maps"

sys.path.insert(0, str(ROOT / "tools"))
from placement_research import (    # type: ignore
    Room, Artifact, Placement, strategy_grow_walker, score_placement, render_ascii,
)
from place_artifacts import (
    artifact_from_registry, existing_placements, room_from_map, parse_lookup_name,
)


def lookup_artifacts(names: list[str]) -> list[Artifact]:
    """Resolve lookup_names → Artifact objects from registry. Skip unknown."""
    out: list[Artifact] = []
    for name in names:
        a = artifact_from_registry(name.strip())
        if a is None:
            print(f"  WARN: artifact '{name}' not in registry (skipping)")
            continue
        out.append(a)
    return out


def grow_map(name: str, artifacts: list[Artifact],
             max_width: int = 15, max_depth: int = 10, max_height: int = 3,
             seed: int = 0) -> dict:
    """Run grow_walker, assemble complete map_data.json. Returns the result dict."""
    # Max-bounds room — agent walks within it but doesn't fill it
    room = Room(width=max_width, depth=max_depth,
                spawn_row=max_depth - 1, spawn_col=max_width // 2,
                teleporter_row=0, teleporter_col=max_width // 2)

    trace: list = []
    rng = random.Random(seed)
    placements = strategy_grow_walker(room, list(artifacts), rng, trace=trace)

    # Extract the laid cells + tables + teleporter position from trace
    laid_cells: set[tuple[int, int]] = set()
    tables: set[tuple[int, int]] = set()
    teleporter_pos = (0, max_width // 2)
    for ev in trace:
        kind, payload, _, _ = ev
        if kind == "__laid_cells__":
            laid_cells = set(tuple(p) for p in payload)
        elif kind == "__tables__":
            tables = set(tuple(p) for p in payload)
        elif kind == "__teleporter_pos__":
            teleporter_pos = tuple(payload)

    # Update room teleporter to the actual end position
    room.teleporter_row, room.teleporter_col = teleporter_pos

    # Build the three layers
    structure = [[" " for _ in range(max_width)] for _ in range(max_depth)]
    utilities = [[" " for _ in range(max_width)] for _ in range(max_depth)]
    interactables = [[" " for _ in range(max_width)] for _ in range(max_depth)]

    # Structure: laid cells = "2" (height 1), tables = "3" (height 2)
    for (r, c) in laid_cells:
        if 0 <= r < max_depth and 0 <= c < max_width:
            structure[r][c] = "2"
    for (r, c) in tables:
        if 0 <= r < max_depth and 0 <= c < max_width:
            structure[r][c] = "3"   # height 2 = table

    # Utilities: spawn + teleporter
    utilities[room.spawn_row][room.spawn_col] = "sp"
    utilities[teleporter_pos[0]][teleporter_pos[1]] = "t"

    # Interactables: placed artifacts (use lookup_name as token)
    for p in placements:
        if 0 <= p.row < max_depth and 0 <= p.col < max_width:
            interactables[p.row][p.col] = f"{p.artifact.lookup_name}:180:0.0"

    # Score the resulting placement (for diagnostic info)
    constraint_score = score_placement(room, placements)

    # ── Trim outer empty rows/columns to keep the map compact ──
    # Find bounding box of laid cells
    if laid_cells:
        min_r = min(r for (r, _) in laid_cells)
        max_r = max(r for (r, _) in laid_cells)
        min_c = min(c for (_, c) in laid_cells)
        max_c = max(c for (_, c) in laid_cells)
        # Pad by 1 cell on each side for breathing room
        min_r = max(0, min_r - 1); max_r = min(max_depth - 1, max_r + 1)
        min_c = max(0, min_c - 1); max_c = min(max_width - 1, max_c + 1)
        # Crop layers
        structure = [row[min_c:max_c + 1] for row in structure[min_r:max_r + 1]]
        utilities = [row[min_c:max_c + 1] for row in utilities[min_r:max_r + 1]]
        interactables = [row[min_c:max_c + 1] for row in interactables[min_r:max_r + 1]]
        new_depth = max_r - min_r + 1
        new_width = max_c - min_c + 1
    else:
        new_depth = max_depth; new_width = max_width

    # Replace any remaining " " in structure with "0" (void)
    for row in structure:
        for i, cell in enumerate(row):
            if cell == " ":
                row[i] = "0"

    # Build map_data
    map_data = {
        "map_info": {
            "name":         f"Grown_{name}",
            "lookup_name":  f"Grown_{name}",
            "description":  (
                f"A map grown by the walker laying floor as it placed artifacts. "
                f"Started at spawn with no structure; the floor and tables emerged "
                f"as a byproduct of the walk. Constraint score: {constraint_score['total']:.3f}, "
                f"placed: {len(placements)}/{len(artifacts)} artifacts, "
                f"laid: {len(laid_cells)} floor cells + {len(tables)} table cells."
            ),
            "version":      "grown-0.1",
            "format":       "json",
            "created_from": "tools/grow_map.py 2026-05-15",
            "dimensions":   {"width": new_width, "depth": new_depth, "max_height": max_height},
            "metadata":     {
                "category": "grown_map",
                "estimated_time": "1 minute",
                "auto_research_strategy": "grow_walker",
                "artifacts_placed": [p.artifact.lookup_name for p in placements],
                "laid_floor_cells": len(laid_cells),
                "table_cells":      len(tables),
                "constraint_score": round(constraint_score["total"], 3),
            },
            "title":        f"Grown: {name}"
        },
        "utility_definitions": {
            "sp": {"name": "Spawn", "description": "Player spawn point", "type": "spawn"},
            "t":  {"name": "Exit Portal",
                   "description": "Step here to leave",
                   "type": "teleporter",
                   "properties": {"action": "next_in_sequence"}}
        },
        "documentation": {
            "summary":     f"Grown_{name} — map emerged from walker's path",
            "layout":      (
                f"{new_width}×{new_depth} bounding box. The walker entered at spawn "
                f"and laid {len(laid_cells)} floor cells + {len(tables)} table cells "
                f"as it placed {len(placements)} artifacts. The teleporter is where the "
                f"walk ended."
            ),
            "objective":   "Walk the map. The map IS the walk's record.",
            "key_elements": [
                f"Spawn at ({room.spawn_row - (min_r if laid_cells else 0)},"
                f" {room.spawn_col - (min_c if laid_cells else 0)})",
                f"Teleporter at ({teleporter_pos[0] - (min_r if laid_cells else 0)},"
                f" {teleporter_pos[1] - (min_c if laid_cells else 0)})",
                *[f"{p.artifact.lookup_name} at "
                  f"({p.row - (min_r if laid_cells else 0)},"
                  f" {p.col - (min_c if laid_cells else 0)})"
                  for p in placements],
            ]
        },
        "lighting": {
            "ambient_color": [0.32, 0.34, 0.40],
            "ambient_energy": 0.9,
            "directional_light": {
                "enabled": True,
                "direction": [-0.3, -1.0, -0.2],
                "energy": 0.7
            }
        },
        "settings": {
            "player_spawn_height": 0.5,
            "floor_tile_size": 1.0
        },
        "layers": {
            "structure":      structure,
            "utilities":      utilities,
            "interactables":  interactables,
        },
    }

    return {
        "map_data":         map_data,
        "placements":       placements,
        "laid_cells":       len(laid_cells),
        "table_cells":      len(tables),
        "constraint_score": constraint_score["total"],
        "trace":            trace,
    }


def write_map(name: str, result: dict) -> Path:
    out_dir = MAPS_DIR / f"Grown_{name}"
    out_dir.mkdir(exist_ok=True)
    map_path = out_dir / "map_data.json"
    with open(map_path, "w", encoding="utf-8") as f:
        json.dump(result["map_data"], f, indent="\t")

    # intent.md
    placements = result["placements"]
    intent_lines = []
    intent_lines.append(f"Concept: A grown map. The walker entered an empty bounding box, laid {result['laid_cells']} floor cells as it walked, placed {len(placements)} artifacts with clearance (and {result['table_cells']} of them on tables for eye-level reading), and ended at the teleporter. The map is the record of the walk.")
    intent_lines.append("")
    intent_lines.append("Actualizes: The inverse-placement principle — instead of placing artifacts INTO a pre-defined room, the room is what the placement leaves behind. The map's shape is the artifact set's necessary geometry, nothing more.")
    intent_lines.append("")
    intent_lines.append(f"Sequence role: Demonstration map for the grow_walker strategy from placement_research. Generated 2026-05-15 by tools/grow_map.py.")
    intent_lines.append("")
    intent_lines.append("Technical angle: Each artifact's `spatial_needs` (footprint_cells, clearance, isolation, wall_backing, preferred_zone, cluster_with) drives the floor-laying decision. Tables are emitted for small displays (footprint ≤ 2 cells, not wall-backed). The bounding box is then cropped to the laid cells + 1-cell margin.")
    intent_lines.append("")
    intent_lines.append("Critical angle: This strategy produces the minimum walkable surface that satisfies the artifact set's constraints — no wasted floor, no empty back-fill. The shape of the map is an honest signature of which artifacts were given and what they needed from each other.")
    intent_lines.append("")
    intent_lines.append("Key artifacts:")
    for p in placements:
        intent_lines.append(f"- {p.artifact.lookup_name}")
    intent_lines.append("")
    intent_lines.append("Gap: Tables don't (yet) emit a proper visible table prop — they're encoded as height-2 floor cells in the structure layer. Visible table primitives could be added by routing the table cells through a placement_rules action.")
    (out_dir / "intent.md").write_text("\n".join(intent_lines), encoding="utf-8")

    # blurb.md
    blurb = (
        f"A map grown by the walker. Step onto the spawn, look around: every cell of floor exists because the walker needed it to place one of the {len(placements)} artifacts you'll meet. "
        f"There is no excess floor. The walls are where the walker stopped extending.\n\n"
        f"Small artifacts sit on tables ({result['table_cells']} of them) — height-2 cubes that put the display at eye level. Larger artifacts sit on the floor with the cleared cells around them.\n\n"
        f"The teleporter is at the end of the walk, not at a pre-chosen corner. When you reach it, you've walked the same path the placer walked. The map is the walk's signature.\n"
    )
    (out_dir / "blurb.md").write_text(blurb, encoding="utf-8")

    return map_path


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--name", type=str, required=True, help="map name (will be prefixed with 'Grown_')")
    p.add_argument("--artifacts", type=str, help="comma-separated lookup_names")
    p.add_argument("--from-map", type=str, help="copy artifact list from existing map")
    p.add_argument("--max-width", type=int, default=15)
    p.add_argument("--max-depth", type=int, default=10)
    p.add_argument("--seed", type=int, default=0)
    args = p.parse_args()

    if args.artifacts:
        names = [s.strip() for s in args.artifacts.split(",")]
        artifacts = lookup_artifacts(names)
    elif args.from_map:
        src = MAPS_DIR / args.from_map / "map_data.json"
        with open(src, "r", encoding="utf-8") as f:
            existing = json.load(f)
        room, _, _ = room_from_map(existing)
        old_p = existing_placements(existing, room)
        artifacts = [pl.artifact for pl in old_p]
        print(f"loaded {len(artifacts)} artifacts from {args.from_map}")
    else:
        p.error("specify --artifacts or --from-map")

    if not artifacts:
        print("no artifacts to place")
        return

    print(f"growing map '{args.name}' with {len(artifacts)} artifacts ({args.max_width}×{args.max_depth} max)")
    result = grow_map(args.name, artifacts,
                       max_width=args.max_width, max_depth=args.max_depth,
                       seed=args.seed)
    map_path = write_map(args.name, result)

    # Print stats
    print()
    md = result["map_data"]
    dims = md["map_info"]["dimensions"]
    print(f"  cropped to: {dims['width']}×{dims['depth']}")
    print(f"  laid:       {result['laid_cells']} floor cells")
    print(f"  tables:     {result['table_cells']} elevated cells")
    print(f"  placed:     {len(result['placements'])}/{len(artifacts)} artifacts")
    print(f"  score:      {result['constraint_score']:.3f}")
    print()
    print(f"  wrote {map_path.relative_to(ROOT)}")
    print(f"  capture: godot_console --path . --xr-mode off --no-window \\")
    print(f"             --script res://commons/testing/capture_multi_angle.gd -- \\")
    print(f"             --mode=map --target=Grown_{args.name}")


if __name__ == "__main__":
    main()
