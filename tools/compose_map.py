#!/usr/bin/env python3
"""
Compose a map from a narrative grammar.

Takes a list of artifacts and a grammar preset (florence, vatican, zelda,
halflife, metropolitan, venice, linear), composes a boundary plan, generates
the spatial structure, and writes map_data.json.

Usage:
  python tools/compose_map.py --grammar florence --artifacts coin_toss entropy_jar galton_board --preview
  python tools/compose_map.py --grammar vatican --sequence randomness --map Composed_Randomness
  python tools/compose_map.py --grammar zelda --artifacts a b c d e f --width 15 --preview
  python tools/compose_map.py --list-grammars
"""

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from lib.spatial_grammar import (
    GRAMMAR_PRESETS,
    VOCABULARY,
    BOUNDARIES,
    compose_boundary_plan,
    generate_narrative_structure,
    validate_boundary_plan,
    ascii_preview,
)
from lib.plan_utils import ROOT, MAPS_DIR, scan_all_sequences


def list_grammars():
    print("Available narrative grammars:\n")
    for key, preset in GRAMMAR_PRESETS.items():
        pattern_str = " -> ".join(preset["pattern"])
        print(f"  {key:15s} {preset['name']}")
        print(f"  {'':15s} {preset['description']}")
        print(f"  {'':15s} Pattern: {pattern_str}")
        print()

    print("Vocabulary (10 spatial transition tools):\n")
    for key, tool in VOCABULARY.items():
        print(f"  {key:15s} {tool.description}")

    print("\nBoundary types (5 conjunctions):\n")
    for key, btype in BOUNDARIES.items():
        print(f"  {key:15s} \"{btype.conjunction}\" — {btype.description}")


def collect_sequence_artifacts(seq_id: str) -> list:
    """Get artifact names from a sequence's artifact_groups."""
    sequences = scan_all_sequences()
    seq = sequences.get(seq_id)
    if not seq:
        for sid, s in sequences.items():
            if sid.lower() == seq_id.lower():
                seq = s
                break
    if not seq:
        return []

    artifacts = []
    for group in seq.get("artifact_groups", []):
        if not isinstance(group, dict):
            continue
        for art in group.get("artifacts", []):
            name = art if isinstance(art, str) else art.get("name", "")
            clean = name.split(":")[0].split("#")[0].strip()
            if clean and clean not in artifacts:
                artifacts.append(clean)
    return artifacts


def build_map_data(result: dict, map_name: str, grammar: str, sections: list) -> dict:
    """Build a complete map_data.json from the narrative structure result."""
    grid = result["structure"]
    depth = result["grid_depth"]
    width = result["grid_width"]
    spawn = result["spawn"]
    teleporter = result["teleporter"]
    art_positions = result["artifact_positions"]

    # Build utilities layer
    utilities = []
    for r in range(depth):
        utilities.append([" "] * width)
    utilities[spawn[0]][spawn[1]] = "sp"
    if teleporter[0] < depth and teleporter[1] < width:
        utilities[teleporter[0]][teleporter[1]] = "t"

    # Build interactables layer
    interactables = []
    for r in range(depth):
        interactables.append([" "] * width)
    for r, c, name in art_positions:
        if r < depth and c < width:
            interactables[r][c] = f"{name}:0:-0.5"

    # Build boundary plan for metadata
    boundary_plan = []
    for sec in sections:
        boundary_plan.append({
            "artifact": sec.get("artifact"),
            "boundary": sec["boundary"],
            "transitions": sec["transitions"],
        })

    preset = GRAMMAR_PRESETS.get(grammar, {})

    return {
        "map_info": {
            "name": f"Composed: {preset.get('name', grammar)}",
            "lookup_name": map_name,
            "description": preset.get("description", f"Narrative map composed with {grammar} grammar."),
            "version": "1.0",
            "format": "json",
            "dimensions": {
                "width": width,
                "depth": depth,
                "max_height": 2,
            },
            "metadata": {
                "difficulty": "composed",
                "category": "narrative",
                "grammar": grammar,
                "learning_objectives": [
                    f"Experience {grammar} spatial narrative",
                    f"Encounter {len(art_positions)} artifacts in composed sequence",
                ],
            },
            "title": preset.get("name", grammar),
        },
        "spacer": {
            "grammar": grammar,
            "boundary_plan": boundary_plan,
        },
        "utility_definitions": {
            "t": {
                "type": "teleporter",
                "name": "Exit",
                "properties": {"action": "next_in_sequence"},
            },
            "s": {
                "type": "spawn",
                "properties": {"height": 1.5},
            },
        },
        "settings": {
            "cube_size": 1.0,
            "gutter": 0.0,
            "show_grid": True,
            "enable_physics": True,
            "background": {"type": "sky", "color": [0.25, 0.25, 0.3]},
        },
        "lighting": {
            "ambient_color": [0.45, 0.45, 0.5],
            "ambient_energy": 0.6,
            "directional_light": {
                "enabled": True,
                "direction": [-0.3, -0.8, -0.3],
                "color": [1.0, 0.95, 0.9],
                "energy": 0.8,
            },
        },
        "layers": {
            "structure": grid,
            "utilities": utilities,
            "interactables": interactables,
        },
    }


def main():
    parser = argparse.ArgumentParser(description="Compose a map from narrative grammar")
    parser.add_argument("--grammar", default="linear",
                        help=f"Grammar preset: {', '.join(GRAMMAR_PRESETS.keys())}")
    parser.add_argument("--artifacts", nargs="+", help="Artifact lookup names")
    parser.add_argument("--sequence", help="Pull artifacts from a sequence")
    parser.add_argument("--map", help="Output map name (default: Composed_<Grammar>)")
    parser.add_argument("--width", type=int, default=13, help="Grid width (default: 13)")
    parser.add_argument("--layout", default="packed", choices=["packed", "linear", "astar"],
                        help="Layout mode: packed (beehive), linear (timeline), astar (force fields)")
    parser.add_argument("--temperature", type=float, default=0.3,
                        help="A* temperature: 0=deterministic, 0.5=warm, 1.0=hot (default: 0.3)")
    parser.add_argument("--seed", type=int, default=-1,
                        help="Random seed for reproducible generation (-1=random)")
    parser.add_argument("--depth", type=int, default=15,
                        help="Grid depth for astar layout (default: 15)")
    parser.add_argument("--preview", action="store_true", help="ASCII preview, don't write")
    parser.add_argument("--list-grammars", action="store_true", help="Show available grammars")
    parser.add_argument("--validate-only", action="store_true", help="Validate boundary plan only")
    args = parser.parse_args()

    if args.list_grammars:
        list_grammars()
        return

    # Collect artifacts
    artifacts = []
    if args.artifacts:
        artifacts = args.artifacts
    elif args.sequence:
        artifacts = collect_sequence_artifacts(args.sequence)
        print(f"Found {len(artifacts)} artifacts in sequence '{args.sequence}'")
    else:
        print("Specify --artifacts or --sequence (or --list-grammars)")
        return

    if not artifacts:
        print("No artifacts found")
        return

    map_name = args.map or f"Composed_{args.grammar.title()}"

    # Compose boundary plan
    print(f"\nGrammar: {args.grammar}")
    print(f"Artifacts: {len(artifacts)}")
    sections = compose_boundary_plan(artifacts, grammar=args.grammar)
    print(f"Sections: {len(sections)}")

    # Validate
    violations = validate_boundary_plan(sections)
    if violations:
        print(f"\nBoundary plan violations:")
        for v in violations:
            print(f"  - {v}")
        if args.validate_only:
            return

    # Print boundary plan
    print(f"\nBoundary plan:")
    for sec in sections:
        art = sec.get("artifact") or "(breathing)"
        boundary = sec["boundary"]
        trans = ", ".join(sec["transitions"]) or "-"
        conj = BOUNDARIES.get(boundary, {})
        conj_str = conj.conjunction if isinstance(conj, object) and hasattr(conj, 'conjunction') else ""
        print(f"  [{boundary:13s}] \"{conj_str}\" {art:30s} transitions: {trans}")

    if args.validate_only:
        return

    # Generate structure
    if args.layout == "astar":
        from lib.astar_composer import compose_astar_map, ascii_preview_astar
        result = compose_astar_map(
            sections,
            grid_width=args.width,
            grid_depth=args.depth,
            temperature=args.temperature,
            seed=args.seed,
        )
    else:
        result = generate_narrative_structure(
            sections,
            grid_width=args.width,
            layout=args.layout,
        )

    print(f"\nGrid: {result['grid_depth']}x{result['grid_width']}")
    print(f"Artifacts placed: {len(result['artifact_positions'])}")

    # Preview
    print(f"\n{ascii_preview(result)}")

    if args.preview:
        return

    # Write map
    data = build_map_data(result, map_name, args.grammar, sections)
    out_dir = MAPS_DIR / map_name
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / "map_data.json"
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"\nWritten: {out_file}")


if __name__ == "__main__":
    main()
