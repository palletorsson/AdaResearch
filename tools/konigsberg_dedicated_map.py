#!/usr/bin/env python3
"""Author/check the compact map shell for the Königsberg dedicated world.

The visible court is one self-sufficient artifact. The JSON grid owns only the
56 x 38 m address space, spawn, exit, and placement of that court. Keeping the
empty layers explicit makes the one-metre contract inspectable while compact
single-line rows keep the file readable.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from compact_map_jsons import format_compact


REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "commons" / "maps" / "World_Konigsberg_Bridge" / "map_data.json"
WIDTH = 56
DEPTH = 38


def blank_layer(fill: str = " ") -> list[list[str]]:
    return [[fill for _ in range(WIDTH)] for _ in range(DEPTH)]


def authored_map() -> dict:
    structure = blank_layer("0")
    utilities = blank_layer()
    interactables = blank_layer()

    # The shell's internal centre offset (-0.5, -0.5) aligns its exact
    # 56 x 38 m envelope with the physical edges of this even-sized grid.
    interactables[19][28] = "konigsberg_observation_court"
    utilities[36][28] = "s:27.5:2.5:36"
    utilities[1][28] = "t:GT_Layout:2.5"

    return {
        "map_info": {
            "name": "Königsberg: The Court Around an Impossible Walk",
            "lookup_name": "World_Konigsberg_Bridge",
            "description": (
                "A 56 x 38 m dedicated observation court that holds the full-scale "
                "Königsberg bridge artifact without scaling or clipping it."
            ),
            "version": "1.0",
            "format": "json",
            "dimensions": {"width": WIDTH, "depth": DEPTH, "max_height": 5},
            "metadata": {
                "difficulty": "advanced",
                "category": "graphtheory",
                "estimated_time": "6-10 minutes",
                "site_id": "world-konigsberg3d-c025c77",
                "site_formula": "perimeter_observation_court",
                "artifact_lookup": "KonigsbergBridge",
                "artifact_order_index": 710,
                "return_artifact_lookup": "force_directed_layout",
                "return_map": "GT_Layout",
                "body_m": [50.0, 32.0, 4.9],
                "site_envelope_m": [56, 38, 5],
                "apron_m": 3,
                "grid_m": 1,
                "body_must_remain_full_scale": True,
                "continuous_player_route_required": True,
                "learning_objectives": [
                    "Read odd vertex degree as a structural obstruction",
                    "Distinguish museum access infrastructure from graph edges",
                    "Try a route, then replace trial-and-error with Euler's parity test",
                ],
            },
        },
        "utility_definitions": {
            "s": {
                "type": "spawn_point",
                "name": "South Court Entry",
                "description": "Enter on the raised observation ring facing the historical graph.",
                "properties": {"player_rotation": 180, "visible_in_game": False},
            },
            "t": {
                "type": "teleporter",
                "name": "Return to artifact order",
                "description": "Continue to force_directed_layout in GT_Layout.",
                "properties": {
                    "action": "load_map",
                    "destination": "GT_Layout",
                    "visual_effect": "exit",
                },
            },
        },
        "lighting": {
            "ambient_color": [0.29, 0.33, 0.39],
            "ambient_energy": 0.68,
            "directional_light": {
                "enabled": True,
                "direction": [-0.42, -0.82, -0.38],
                "color": [1.0, 0.91, 0.78],
                "energy": 1.35,
            },
        },
        "environment": {
            "terrain_mode": "void",
            "vegetation_density": 0.0,
            "ambient_preset": "museum_court",
            "fog_density": 0.004,
        },
        "settings": {
            "cube_size": 1.0,
            "gutter": 0.0,
            "show_grid": False,
            "enable_physics": True,
            "background": {"type": "color", "color": [0.045, 0.06, 0.08]},
        },
        "layers": {
            "structure": structure,
            "utilities": utilities,
            "interactables": interactables,
        },
    }


def rendered() -> str:
    return format_compact(authored_map())


def main() -> int:
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--write", action="store_true")
    group.add_argument("--check", action="store_true")
    args = parser.parse_args()

    expected = rendered()
    if args.write:
        OUT.parent.mkdir(parents=True, exist_ok=True)
        OUT.write_text(expected, encoding="utf-8")
        print(f"wrote {OUT.relative_to(REPO)} ({WIDTH} x {DEPTH})")
        return 0

    if not OUT.exists():
        print(f"FAIL missing {OUT.relative_to(REPO)}")
        return 1
    actual = OUT.read_text(encoding="utf-8")
    if actual != expected:
        print(f"FAIL drift {OUT.relative_to(REPO)}; run --write")
        return 1
    data = json.loads(actual)
    assert len(data["layers"]["structure"]) == DEPTH
    assert all(len(row) == WIDTH for layer in data["layers"].values() for row in layer)
    print("PASS Königsberg dedicated map is compact and deterministic")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
