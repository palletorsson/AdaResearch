#!/usr/bin/env python3
"""Build the architecture-first Uffizi footprint pilot.

The order is deliberate:
1. Reconstruct the canonical `uffizi-spine-ordered` circulation pattern.
2. Declare its invariant corridor, door, enfilade, and end-stop rules.
3. Offer its side-room bays to artifact dressing-room contracts.
4. Expand only the room side of the plan; never consume the clear spine.
5. Stamp accepted footprint overlays and artifact anchors.

This is the inverse of composing dressing rooms in a row and wrapping a shell
around them. The museum pattern is the substrate; artifacts negotiate onto it.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


REPO = Path(__file__).resolve().parent.parent
MAPS_DIR = REPO / "commons" / "maps"

WIDTH = 21
DEPTH = 30
MAX_HEIGHT = 11

# The original 15 m template dedicates 8 m to side rooms, 1 m to the inner
# wall/display line, 3 m to the clear walking lane, and the remainder to walls.
# The derived plan grows only westward from the spine so the neural-network
# contract can receive a 14 m room without weakening circulation.
ROOM_X0 = 1
ROOM_X1 = 14
INNER_WALL_X = 15
DISPLAY_BAND_X = 16
CLEAR_SPINE_X0 = 17
CLEAR_SPINE_X1 = 19
OUTER_WALL_X = 20

PARTITION_ROWS = (8, 17, 25)
SPINE_DOORS = ((5, 6), (13, 14), (21, 22))
ENFILADE_DOOR_X = (2, 3)

ASSIGNMENTS = [
    {
        "artifact": "shannon_entropy_meter",
        "display_name": "Shannon Entropy Meter",
        "bay": "north_room",
        "token": "shannon_entropy_meter:0:0",
        "anchor": [12, 2],
        "rect": [11, 1, 13, 3],
        "request_m": [3, 3, 3],
        "original_offer_m": [8, 7, 4],
        "derived_offer_m": [14, 7, 4],
        "result": "fit_without_architectural_change",
        "rule_trace": [
            "Use the north wall as the required support.",
            "Reserve the 3 m frontal reading bay inside the room.",
            "Do not place the instrument or its readers in the spine.",
        ],
    },
    {
        "artifact": "pattern_loom",
        "display_name": "Pattern Loom",
        "bay": "middle_room",
        "token": "pattern_loom:0:0",
        "anchor": [7, 11],
        "rect": [5, 9, 9, 16],
        "request_m": [5, 8, 3],
        "original_offer_m": [8, 7, 4],
        "derived_offer_m": [14, 8, 4],
        "result": "partition_moved_one_metre",
        "rule_trace": [
            "Keep the loom freestanding and preserve its south-facing output runway.",
            "Move the second cross-wall from row 16 to row 17 to gain 1 m depth.",
            "Keep both the spine lane and aligned side-room doorway unchanged.",
        ],
    },
    {
        "artifact": "neural_network_visualization",
        "display_name": "Neural Network Visualization",
        "bay": "south_room",
        "token": "neural_network_visualization:0:0#presentation:museum",
        "anchor": [3, 21],
        "rect": [1, 18, 14, 23],
        "request_m": [14, 6, 11],
        "original_offer_m": [8, 7, 4],
        "derived_offer_m": [14, 7, 11],
        "result": "room_expanded_outward_six_metres",
        "rule_trace": [
            "Expand the room away from the spine until the 14 m width fits.",
            "Raise the vertical envelope to 11 m without changing the floor route.",
            "Protect two-sided reading and exclude neighboring artifacts from the room.",
        ],
    },
]


def blank_layer(fill: str) -> list[list[str]]:
    return [[fill for _ in range(WIDTH)] for _ in range(DEPTH)]


def build_architecture() -> list[list[str]]:
    """Return the Uffizi-derived structure before any artifact is placed."""
    structure = blank_layer("0")

    # Three ordered side rooms and the east spine.
    for z in range(0, 26):
        structure[z][0] = "4"
        structure[z][OUTER_WALL_X] = "4"
        for x in range(ROOM_X0, ROOM_X1 + 1):
            structure[z][x] = "1"
        structure[z][INNER_WALL_X] = "4"
        structure[z][DISPLAY_BAND_X] = "1"
        for x in range(CLEAR_SPINE_X0, CLEAR_SPINE_X1 + 1):
            structure[z][x] = "1"

    # The head of the U: rooms are closed while the spine remains the entrance.
    for x in range(0, INNER_WALL_X + 1):
        structure[0][x] = "4"

    # Door bands from the spine into each side room.
    for door_rows in SPINE_DOORS:
        for z in door_rows:
            structure[z][INNER_WALL_X] = "1"

    # Cross-walls retain the secondary north/south enfilade at x=2..3.
    for z in PARTITION_ROWS:
        for x in range(0, INNER_WALL_X + 1):
            structure[z][x] = "4"
        for x in ENFILADE_DOOR_X:
            structure[z][x] = "1"

    # Statue/podium rhythm: outside the 3 m clear walking lane.
    for z in (4, 12, 20):
        structure[z][DISPLAY_BAND_X] = "2"

    # South crossbar completes the U and turns the visitor toward the exit.
    for z in range(26, 29):
        structure[z][0] = "4"
        structure[z][OUTER_WALL_X] = "4"
        for x in range(1, OUTER_WALL_X):
            structure[z][x] = "1"

    # Axial end-stop and exit threshold.
    structure[27][18] = "3"
    for x in range(WIDTH):
        structure[29][x] = "4"
    for x in (2, 3, 4):
        structure[29][x] = "1"

    return structure


def stamp_footprints() -> list[list[str]]:
    overlay = blank_layer("")
    for assignment in ASSIGNMENTS:
        x0, z0, x1, z1 = assignment["rect"]
        for z in range(z0, z1 + 1):
            for x in range(x0, x1 + 1):
                overlay[z][x] = assignment["artifact"]
    return overlay


def build_map(map_name: str) -> dict:
    structure = build_architecture()
    structure[28][3] = "0"
    utilities = blank_layer(" ")
    interactables = blank_layer(" ")
    footprints = stamp_footprints()

    utilities[1][18] = "s"
    # Put the exit one cell before the threshold so row 29 remains a safe
    # landing/catch strip instead of asking the teleporter to sit on the edge.
    utilities[28][3] = "t"

    for assignment in ASSIGNMENTS:
        x, z = assignment["anchor"]
        interactables[z][x] = assignment["token"]

    # The inherited Uffizi end-stop remains a small axial marker. It is not a
    # negotiated room artifact and therefore does not appear in the overlay.
    interactables[27][18] = "origin"

    return {
        "map_info": {
            "lookup_name": map_name,
            "name": map_name,
            "title": "Uffizi Footprint Pilot",
            "description": (
                "Architecture-first museum pilot: the ordered Uffizi spine is built "
                "before three artifact dressing-room contracts negotiate onto its bays."
            ),
            "version": "1.0-architecture-first",
            "format": "ada-3layer-v1+footprint-overlay",
            "dimensions": {"width": WIDTH, "depth": DEPTH, "max_height": MAX_HEIGHT},
            "metadata": {
                "category": "museum",
                "difficulty": "beginner",
                "estimated_time": "5-8 minutes",
                "learning_objectives": [
                    "Read the Uffizi spine as the primary circulation contract",
                    "See artifact footprints negotiate within architectural bays",
                    "Distinguish invariant routes from expandable exhibition rooms",
                ],
                "architecture_contract": {
                    "source_template": "uffizi-spine-ordered",
                    "source_museum": "Uffizi Gallery, Florence (edited project formula)",
                    "original_dimensions_m": [15, 30],
                    "derived_dimensions_m": [WIDTH, DEPTH],
                    "invariants": [
                        "3 m clear east spine",
                        "1 m statue and podium display band",
                        "aligned spine-to-room door bands",
                        "aligned side-room enfilade doors",
                        "south U-turn and westward exit",
                        "axial end-stop visible from the entrance spine",
                    ],
                    "expandable": [
                        "side-room width away from the spine",
                        "cross-wall position when doorway order remains intact",
                        "vertical envelope per artifact contract",
                    ],
                    "forbidden": [
                        "narrowing the 3 m clear spine",
                        "blocking an aligned doorway",
                        "placing artifact body or preferred clearance in the spine",
                    ],
                },
                "placement_overlay": ASSIGNMENTS,
            },
        },
        "utility_definitions": {
            "s": {"type": "spawn", "properties": {"height": 1.5}},
            "t": {
                "type": "teleporter",
                "name": "Exit the Uffizi pilot",
                "properties": {"action": "next_in_sequence"},
            },
        },
        "settings": {
            "cube_size": 1.0,
            "gutter": 0.0,
            "show_grid": True,
            "enable_physics": True,
            "auto_reveal_on_entry": False,
            "initial_tile_visibility": "all",
            "disable_biome": True,
            "background": "dark",
            "color_overrides": {
                "model_color": "0.31, 0.30, 0.28, 1.0",
                "wireframe_color": "0.66, 0.61, 0.52, 1.0",
                "emission_color": "0.12, 0.10, 0.08, 1.0",
                "emission_strength": 0.08,
                "wireframe_opacity": 0.18,
            },
        },
        "lighting": {
            "ambient_color": [0.68, 0.65, 0.60],
            "ambient_energy": 0.52,
            "directional_light": {
                "enabled": True,
                "direction": [-0.2, -0.9, -0.25],
                "color": [1.0, 0.94, 0.84],
                "energy": 1.1,
            },
        },
        "layers": {
            "structure": structure,
            "utilities": utilities,
            "interactables": interactables,
            # Non-runtime evidence layer. GridSystem ignores unknown layers; the
            # plan renderer and negotiation UI use this one to show reserved space.
            "footprints": footprints,
        },
    }


def validate_contracts(map_data: dict) -> None:
    """Fail generation if either architecture or footprint rules are weakened."""
    layers = map_data["layers"]
    for layer_name in ("structure", "utilities", "interactables", "footprints"):
        layer = layers[layer_name]
        if len(layer) != DEPTH or any(len(row) != WIDTH for row in layer):
            raise ValueError(f"{layer_name} is not {WIDTH}x{DEPTH}")

    structure = layers["structure"]
    footprints = layers["footprints"]

    # The clear spine is an invariant route, including the entrance and U-turn.
    for z in range(0, 26):
        for x in range(CLEAR_SPINE_X0, CLEAR_SPINE_X1 + 1):
            if structure[z][x] != "1":
                raise ValueError(f"clear spine blocked at ({x},{z})")
            if footprints[z][x]:
                raise ValueError(f"artifact footprint entered spine at ({x},{z})")

    # Both doorway systems must remain aligned and open.
    for door_rows in SPINE_DOORS:
        for z in door_rows:
            if structure[z][INNER_WALL_X] != "1":
                raise ValueError(f"spine door blocked at ({INNER_WALL_X},{z})")
    for z in PARTITION_ROWS:
        for x in ENFILADE_DOOR_X:
            if structure[z][x] != "1":
                raise ValueError(f"enfilade door blocked at ({x},{z})")

    occupied: dict[tuple[int, int], str] = {}
    for assignment in ASSIGNMENTS:
        x0, z0, x1, z1 = assignment["rect"]
        ax, az = assignment["anchor"]
        if not (x0 <= ax <= x1 and z0 <= az <= z1):
            raise ValueError(f"{assignment['artifact']} anchor is outside its footprint")
        for z in range(z0, z1 + 1):
            for x in range(x0, x1 + 1):
                if structure[z][x] != "1":
                    raise ValueError(
                        f"{assignment['artifact']} footprint hits non-floor at ({x},{z})"
                    )
                if (x, z) in occupied:
                    raise ValueError(
                        f"footprint overlap at ({x},{z}): "
                        f"{occupied[(x, z)]} / {assignment['artifact']}"
                    )
                occupied[(x, z)] = assignment["artifact"]
                if footprints[z][x] != assignment["artifact"]:
                    raise ValueError(f"footprint evidence mismatch at ({x},{z})")


def render_plan(map_data: dict, out_path: Path) -> None:
    cell = 28
    margin = 70
    width_px = WIDTH * cell + margin * 2
    height_px = DEPTH * cell + margin * 2
    image = Image.new("RGB", (width_px, height_px), "#10141c")
    draw = ImageDraw.Draw(image, "RGBA")
    font = ImageFont.load_default()

    structure = map_data["layers"]["structure"]
    overlays = map_data["layers"]["footprints"]
    colors = {
        "shannon_entropy_meter": "#36c6d9",
        "pattern_loom": "#f0a43a",
        "neural_network_visualization": "#df4fd4",
    }

    for z, row in enumerate(structure):
        for x, value in enumerate(row):
            px = margin + x * cell
            py = margin + z * cell
            if value == "0":
                fill = "#10141c"
            elif value == "4":
                fill = "#d6c7aa"
            elif value in ("2", "3"):
                fill = "#aa7d47"
            else:
                fill = "#3b4655"
            draw.rectangle((px, py, px + cell - 1, py + cell - 1), fill=fill)
            if value != "0":
                draw.rectangle((px, py, px + cell - 1, py + cell - 1), outline="#606a78", width=1)

            artifact = overlays[z][x]
            if artifact:
                draw.rectangle(
                    (px + 2, py + 2, px + cell - 3, py + cell - 3),
                    fill=colors[artifact] + "88",
                    outline=colors[artifact],
                    width=2,
                )

    # Mark the invariant clear spine distinctly.
    sx0 = margin + CLEAR_SPINE_X0 * cell
    sx1 = margin + (CLEAR_SPINE_X1 + 1) * cell
    sy0 = margin
    sy1 = margin + 26 * cell
    draw.rectangle((sx0, sy0, sx1, sy1), outline="#73e0a8", width=4)

    draw.text((margin, 22), "UFFIZI PATTERN FIRST  /  ARTIFACT FOOTPRINTS SECOND", fill="#f2eadc", font=font)
    legend_y = height_px - 42
    legend = [
        ("#36c6d9", "Shannon 3x3"),
        ("#f0a43a", "Pattern Loom 5x8"),
        ("#df4fd4", "Neural Network 14x6"),
        ("#73e0a8", "3 m clear spine"),
    ]
    x_cursor = margin
    for color, label in legend:
        draw.rectangle((x_cursor, legend_y, x_cursor + 14, legend_y + 14), fill=color)
        draw.text((x_cursor + 20, legend_y + 1), label, fill="#dbe1e9", font=font)
        x_cursor += 145

    out_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(out_path)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--name", default="Museum_AAA_Uffizi_Footprint_Pilot")
    args = parser.parse_args()

    map_data = build_map(args.name)
    validate_contracts(map_data)
    out_dir = MAPS_DIR / args.name
    out_dir.mkdir(parents=True, exist_ok=True)
    map_path = out_dir / "map_data.json"
    plan_path = out_dir / "footprint_plan.png"
    map_path.write_text(json.dumps(map_data, indent=2), encoding="utf-8")
    render_plan(map_data, plan_path)
    print(f"wrote {map_path.relative_to(REPO)}")
    print(f"wrote {plan_path.relative_to(REPO)}")
    print("contracts: architecture invariants PASS; footprint overlays PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
