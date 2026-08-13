#!/usr/bin/env python3
"""Build a ten-artifact, architecture-first Uffizi cohort.

The generator deliberately has two passes:

1. Draw ten identical Uffizi side-bay offers without consulting artifacts.
2. Load artifact dressing-room contracts and negotiate those offers.

Negotiation may widen the side-room field away from the main spine or lengthen
an individual bay along the spine. It may never narrow the three-metre spine,
block an aligned doorway, or place an artifact footprint in that route.
"""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont

import compact_map_json


REPO = Path(__file__).resolve().parent.parent
MAPS_DIR = REPO / "commons" / "maps"
CONTRACT_DIR = REPO / "commons" / "artifacts" / "dressing_rooms"

BASE_ROOM_WIDTH = 8
BASE_BAY_DEPTH = 7
BASE_HEIGHT = 4
CLEAR_SPINE_WIDTH = 3

COHORT = [
    {
        "artifact": "origin",
        "display_name": "Point Zero",
        "token": "origin:90:0#beam_height:0.6#octahedron_size:0.08#rotation_speed:0.18",
    },
    {
        "artifact": "lambda_slider",
        "display_name": "Lambda Slider",
        "token": "lambda_slider:0:0#calibration:dispute",
    },
    {
        "artifact": "phi_slider",
        "display_name": "Phi Slider",
        "token": "phi_slider:0:0",
    },
    {
        "artifact": "platonicsolids",
        "display_name": "Platonic Solids",
        "token": "platonicsolids:180:0#palette:trans#staging:bare",
    },
    {
        "artifact": "random_walk_leash",
        "display_name": "Random Walk Leash",
        "token": "random_walk_leash:180:0",
    },
    {
        "artifact": "shannon_entropy_meter",
        "display_name": "Shannon Entropy Meter",
        "token": "shannon_entropy_meter:0:0",
    },
    {
        "artifact": "harmonic_distance_table",
        "display_name": "Harmonic Distance Table",
        "token": "harmonic_distance_table:90:0",
    },
    {
        "artifact": "pattern_loom",
        "display_name": "Pattern Loom",
        "token": "pattern_loom:180:0",
    },
    {
        "artifact": "gradient_descent_visualization",
        "display_name": "Gradient Descent Visualization",
        "token": "gradient_descent_visualization:90:0",
    },
    {
        "artifact": "neural_network_visualization",
        "display_name": "Neural Network Visualization",
        "token": "neural_network_visualization:180:0#presentation:museum",
    },
]

PALETTE = [
    "#4cc9f0",
    "#4895ef",
    "#4361ee",
    "#7251b5",
    "#b5179e",
    "#f72585",
    "#f77f00",
    "#fcbf49",
    "#80b918",
    "#2ec4b6",
]


def blank_layer(width: int, depth: int, fill: str) -> list[list[str]]:
    return [[fill for _ in range(width)] for _ in range(depth)]


def load_contracts() -> list[dict[str, Any]]:
    assignments: list[dict[str, Any]] = []
    for index, entry in enumerate(COHORT):
        path = CONTRACT_DIR / f"{entry['artifact']}.json"
        if not path.exists():
            raise FileNotFoundError(f"missing dressing-room contract: {path}")
        contract = json.loads(path.read_text(encoding="utf-8"))
        if contract.get("lookup_name") != entry["artifact"]:
            raise ValueError(f"contract identity mismatch in {path}")

        placement = contract.get("placement_contract", {})
        clearance = contract.get("clearance") or placement.get("preferred_zone_m")
        if not clearance or len(clearance) != 3:
            raise ValueError(f"{entry['artifact']} has no three-axis clearance")
        request = [max(1, int(math.ceil(float(value)))) for value in clearance]
        assignment = {
            **entry,
            "index": index + 1,
            "contract_path": str(path.relative_to(REPO)).replace("\\", "/"),
            "request_m": request,
            "physical_footprint_m": contract.get("footprint"),
            "posture": contract.get("posture", "floor"),
            "preferred_mode": placement.get("preferred_mode", "freestanding"),
            "allowed_modes": placement.get("allowed_modes", []),
            "required_support": placement.get("required_support", "floor"),
            "interaction_faces": placement.get("interaction_faces", []),
            "circulation": placement.get("circulation", "unspecified"),
            "minimum_route_width_m": placement.get("minimum_route_width_m", 0.9),
            "neighbor_policy": placement.get("neighbor_policy", "unspecified"),
            "placement_intent": contract.get("placement_intent", ""),
            "color": PALETTE[index],
        }
        assignments.append(assignment)
    return assignments


def plan_geometry(
    room_width: int,
    bay_depths: list[int],
    bay_widths: list[int] | None = None,
) -> dict[str, Any]:
    if bay_widths is None:
        bay_widths = [room_width] * len(bay_depths)
    if len(bay_widths) != len(bay_depths):
        raise ValueError("bay widths and depths must have the same length")
    inner_wall_x = room_width + 1
    display_band_x = room_width + 2
    clear_spine_x0 = room_width + 3
    clear_spine_x1 = clear_spine_x0 + CLEAR_SPINE_WIDTH - 1
    outer_wall_x = clear_spine_x1 + 1
    width = outer_wall_x + 1

    bays = []
    cursor = 0
    enfilade_x0 = inner_wall_x - BASE_ROOM_WIDTH + 1
    enfilade_x1 = enfilade_x0 + 1
    for index, (bay_depth, bay_width) in enumerate(zip(bay_depths, bay_widths, strict=True), start=1):
        start = cursor + 1
        end = start + bay_depth - 1
        partition = end + 1
        door_a = start + max(1, (bay_depth - 2) // 2)
        door_b = min(end, door_a + 1)
        bays.append(
            {
                "index": index,
                "start": start,
                "end": end,
                "partition": partition,
                "door_rows": [door_a, door_b],
                "depth": bay_depth,
                "room_width": bay_width,
                "room_x0": inner_wall_x - bay_width,
                "outer_wall_x": inner_wall_x - bay_width - 1,
            }
        )
        cursor = partition

    crossbar_rows = [cursor + 1, cursor + 2, cursor + 3]
    catch_row = cursor + 4
    depth = catch_row + 1
    return {
        "room_width": room_width,
        "inner_wall_x": inner_wall_x,
        "display_band_x": display_band_x,
        "clear_spine_x0": clear_spine_x0,
        "clear_spine_x1": clear_spine_x1,
        "outer_wall_x": outer_wall_x,
        "enfilade_x0": enfilade_x0,
        "enfilade_x1": enfilade_x1,
        "width": width,
        "depth": depth,
        "bays": bays,
        "crossbar_rows": crossbar_rows,
        "catch_row": catch_row,
    }


def build_architecture(geometry: dict[str, Any]) -> list[list[str]]:
    width = geometry["width"]
    depth = geometry["depth"]
    inner_wall_x = geometry["inner_wall_x"]
    display_band_x = geometry["display_band_x"]
    spine_x0 = geometry["clear_spine_x0"]
    spine_x1 = geometry["clear_spine_x1"]
    outer_wall_x = geometry["outer_wall_x"]
    last_partition = geometry["bays"][-1]["partition"]
    structure = blank_layer(width, depth, "0")

    # The invariant east side: inner wall, display band, clear spine, outer wall.
    for z in range(last_partition + 1):
        structure[z][outer_wall_x] = "4"
        structure[z][inner_wall_x] = "4"
        structure[z][display_band_x] = "1"
        for x in range(spine_x0, spine_x1 + 1):
            structure[z][x] = "1"

    # Each bay starts from the canonical eight-metre offer and steps its west
    # wall outward only when its own contract asks for more width.
    for bay in geometry["bays"]:
        for z in range(bay["start"], bay["end"] + 1):
            structure[z][bay["outer_wall_x"]] = "4"
            for x in range(bay["room_x0"], inner_wall_x):
                structure[z][x] = "1"

    # Close the room head while leaving the public spine open.
    first_bay = geometry["bays"][0]
    for x in range(first_bay["outer_wall_x"], inner_wall_x + 1):
        structure[0][x] = "4"

    # Cross partitions keep one global enfilade threshold aligned even where
    # the west facade steps outward between differently sized rooms.
    for bay_index, bay in enumerate(geometry["bays"]):
        z = bay["partition"]
        next_outer = (
            geometry["bays"][bay_index + 1]["outer_wall_x"]
            if bay_index + 1 < len(geometry["bays"])
            else bay["outer_wall_x"]
        )
        for x in range(min(bay["outer_wall_x"], next_outer), inner_wall_x + 1):
            structure[z][x] = "4"
        for x in range(geometry["enfilade_x0"], geometry["enfilade_x1"] + 1):
            structure[z][x] = "1"

        for door_z in bay["door_rows"]:
            structure[door_z][inner_wall_x] = "1"

        # A display-band punctuation never consumes the clear spine.
        display_z = max(bay["start"], bay["door_rows"][0] - 1)
        structure[display_z][display_band_x] = "2"

    # South crossbar completes the ordered turn toward the westward exit.
    final_outer = geometry["bays"][-1]["outer_wall_x"]
    for z in geometry["crossbar_rows"]:
        structure[z][final_outer] = "4"
        structure[z][outer_wall_x] = "4"
        for x in range(final_outer + 1, outer_wall_x):
            structure[z][x] = "1"

    axial_x = spine_x0 + 1
    axial_z = geometry["crossbar_rows"][1]
    structure[axial_z][axial_x] = "3"

    catch_z = geometry["catch_row"]
    for x in range(final_outer, width):
        structure[catch_z][x] = "4"
    exit_center = final_outer + 3
    for x in range(exit_center - 1, exit_center + 2):
        structure[catch_z][x] = "1"
    return structure


def negotiate(assignments: list[dict[str, Any]]) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    room_width = max(BASE_ROOM_WIDTH, max(a["request_m"][0] for a in assignments))
    bay_widths = [max(BASE_ROOM_WIDTH, a["request_m"][0]) for a in assignments]
    bay_depths = [max(BASE_BAY_DEPTH, a["request_m"][1]) for a in assignments]
    geometry = plan_geometry(room_width, bay_depths, bay_widths)

    for assignment, bay in zip(assignments, geometry["bays"], strict=True):
        request_w, request_d, request_h = assignment["request_m"]
        x0 = bay["room_x0"] + (bay["room_width"] - request_w) // 2
        x1 = x0 + request_w - 1
        if assignment["preferred_mode"] == "against_wall":
            z0 = bay["start"]
        else:
            z0 = bay["start"] + (bay["depth"] - request_d) // 2
        z1 = z0 + request_d - 1
        anchor = [(x0 + x1) // 2, (z0 + z1) // 2]
        if assignment["preferred_mode"] == "against_wall":
            anchor[1] = z0

        changes = []
        if bay["room_width"] > BASE_ROOM_WIDTH:
            changes.append(f"bay widened {bay['room_width'] - BASE_ROOM_WIDTH} m away from spine")
        if bay["depth"] > BASE_BAY_DEPTH:
            changes.append(f"bay lengthened {bay['depth'] - BASE_BAY_DEPTH} m along spine")
        if not changes:
            changes.append("accepted by canonical 8 x 7 m bay")

        assignment.update(
            {
                "bay": f"bay_{assignment['index']:02d}",
                "base_offer_m": [BASE_ROOM_WIDTH, BASE_BAY_DEPTH, BASE_HEIGHT],
                "derived_offer_m": [bay["room_width"], bay["depth"], max(BASE_HEIGHT, request_h)],
                "bay_rows": [bay["start"], bay["end"]],
                "door_rows": bay["door_rows"],
                "rect": [x0, z0, x1, z1],
                "anchor": anchor,
                "negotiation": changes,
            }
        )
    return geometry, assignments


def stamp_footprints(
    width: int, depth: int, assignments: list[dict[str, Any]]
) -> list[list[str]]:
    footprints = blank_layer(width, depth, "")
    for assignment in assignments:
        x0, z0, x1, z1 = assignment["rect"]
        for z in range(z0, z1 + 1):
            for x in range(x0, x1 + 1):
                footprints[z][x] = assignment["artifact"]
    return footprints


def build_map(map_name: str) -> tuple[dict[str, Any], dict[str, Any]]:
    assignments = load_contracts()
    base_geometry = plan_geometry(BASE_ROOM_WIDTH, [BASE_BAY_DEPTH] * len(assignments))
    base_structure = build_architecture(base_geometry)
    geometry, assignments = negotiate(assignments)
    structure = build_architecture(geometry)
    width, depth = geometry["width"], geometry["depth"]
    utilities = blank_layer(width, depth, " ")
    interactables = blank_layer(width, depth, " ")
    footprints = stamp_footprints(width, depth, assignments)

    spawn_x = geometry["clear_spine_x0"] + 1
    utilities[1][spawn_x] = "s"
    exit_x = geometry["bays"][-1]["outer_wall_x"] + 3
    exit_z = geometry["crossbar_rows"][-1]
    structure[exit_z][exit_x] = "0"
    utilities[exit_z][exit_x] = "t"

    raised_supports = {"table", "pedestal", "plinth", "platform"}
    for assignment in assignments:
        x, z = assignment["anchor"]
        interactables[z][x] = assignment["token"]
        if assignment["required_support"] in raised_supports:
            structure[z][x] = "2"

    max_height = max(BASE_HEIGHT, max(a["request_m"][2] for a in assignments))
    architecture_contract = {
        "source_template": "uffizi-spine-ordered",
        "base_offer_dimensions_m": [base_geometry["width"], base_geometry["depth"]],
        "derived_dimensions_m": [width, depth],
        "canonical_bay_offer_m": [BASE_ROOM_WIDTH, BASE_BAY_DEPTH, BASE_HEIGHT],
        "bay_count": len(assignments),
        "invariants": [
            "3 m clear east spine",
            "1 m display and podium band outside the clear route",
            "one aligned two-cell spine doorway per bay",
            "aligned x=2..3 side-room enfilade thresholds",
            "south U-turn and westward exit",
            "axial end-stop visible down the entrance spine",
        ],
        "negotiable": [
            "side-room width may grow only away from the spine",
            "individual bay depth may grow along the spine",
            "vertical envelope follows the artifact contract",
            "support tile may rise to one metre for table, plinth, pedestal, or platform contracts",
        ],
        "forbidden": [
            "narrowing the 3 m clear spine",
            "blocking an aligned spine doorway or enfilade threshold",
            "placing an artifact anchor or preferred footprint in the spine",
            "placing two artifact footprints in the same bay",
        ],
    }

    map_data = {
        "map_info": {
            "lookup_name": map_name,
            "name": map_name,
            "title": "Uffizi Footprint Cohort: Ten Contracts",
            "description": (
                "Ten canonical Uffizi side-bay offers are drawn first; ten artifact "
                "contracts then negotiate onto them without weakening the public spine."
            ),
            "version": "2.0-architecture-first-cohort",
            "format": "ada-3layer-v1+footprint-overlay",
            "dimensions": {"width": width, "depth": depth, "max_height": max_height},
            "metadata": {
                "category": "museum",
                "difficulty": "intermediate",
                "estimated_time": "12-18 minutes",
                "room_sequence": [a["artifact"] for a in assignments],
                "learning_objectives": [
                    "Read the Uffizi route before reading its contents",
                    "Compare ten explicit placement contracts against identical bay offers",
                    "Distinguish invariant circulation from negotiated exhibition space",
                ],
                "architecture_contract": architecture_contract,
                "placement_overlay": assignments,
            },
        },
        "utility_definitions": {
            "s": {"type": "spawn", "properties": {"height": 1.5}},
            "t": {
                "type": "teleporter",
                "name": "Exit the Uffizi cohort",
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
            "footprints": footprints,
        },
    }
    base_offer = {
        "geometry": base_geometry,
        "structure": base_structure,
        "assignments": assignments,
    }
    return map_data, base_offer


def validate_contracts(map_data: dict[str, Any]) -> None:
    info = map_data["map_info"]
    width = info["dimensions"]["width"]
    depth = info["dimensions"]["depth"]
    assignments = info["metadata"]["placement_overlay"]
    geometry = plan_geometry(
        info["metadata"]["architecture_contract"]["derived_dimensions_m"][0] - 7,
        [a["derived_offer_m"][1] for a in assignments],
        [a["derived_offer_m"][0] for a in assignments],
    )
    layers = map_data["layers"]
    for layer_name in ("structure", "utilities", "interactables", "footprints"):
        layer = layers[layer_name]
        if len(layer) != depth or any(len(row) != width for row in layer):
            raise ValueError(f"{layer_name} is not {width}x{depth}")

    structure = layers["structure"]
    footprints = layers["footprints"]
    interactables = layers["interactables"]
    for z in range(geometry["bays"][-1]["partition"] + 1):
        for x in range(geometry["clear_spine_x0"], geometry["clear_spine_x1"] + 1):
            if structure[z][x] != "1":
                raise ValueError(f"clear spine blocked at ({x},{z})")
            if footprints[z][x] or interactables[z][x].strip():
                raise ValueError(f"artifact entered clear spine at ({x},{z})")

    for bay in geometry["bays"]:
        for z in bay["door_rows"]:
            if structure[z][geometry["inner_wall_x"]] != "1":
                raise ValueError(f"spine doorway blocked at ({geometry['inner_wall_x']},{z})")
        for x in range(geometry["enfilade_x0"], geometry["enfilade_x1"] + 1):
            if structure[bay["partition"]][x] != "1":
                raise ValueError(f"enfilade threshold blocked at ({x},{bay['partition']})")

    occupied: dict[tuple[int, int], str] = {}
    raised_supports = {"table", "pedestal", "plinth", "platform"}
    for assignment in assignments:
        x0, z0, x1, z1 = assignment["rect"]
        ax, az = assignment["anchor"]
        if not (x0 <= ax <= x1 and z0 <= az <= z1):
            raise ValueError(f"{assignment['artifact']} anchor outside preferred footprint")
        if not interactables[az][ax].startswith(assignment["artifact"]):
            raise ValueError(f"{assignment['artifact']} anchor token mismatch")
        if assignment["required_support"] in raised_supports and structure[az][ax] != "2":
            raise ValueError(f"{assignment['artifact']} missing one-metre support")
        if assignment["preferred_mode"] == "against_wall":
            if structure[z0 - 1][ax] != "4":
                raise ValueError(f"{assignment['artifact']} has no north wall support")

        for z in range(z0, z1 + 1):
            for x in range(x0, x1 + 1):
                if structure[z][x] not in ("1", "2"):
                    raise ValueError(f"{assignment['artifact']} footprint hits non-floor at ({x},{z})")
                if (x, z) in occupied:
                    raise ValueError(
                        f"footprint overlap at ({x},{z}): {occupied[(x, z)]} / {assignment['artifact']}"
                    )
                occupied[(x, z)] = assignment["artifact"]
                if footprints[z][x] != assignment["artifact"]:
                    raise ValueError(f"footprint evidence mismatch at ({x},{z})")


def draw_structure(
    draw: ImageDraw.ImageDraw,
    structure: list[list[str]],
    cell: int,
    margin: int,
) -> None:
    for z, row in enumerate(structure):
        for x, value in enumerate(row):
            px, py = margin + x * cell, margin + z * cell
            fill = {
                "0": "#10141c",
                "1": "#3b4655",
                "2": "#aa7d47",
                "3": "#8f6136",
                "4": "#d6c7aa",
            }.get(value, "#10141c")
            draw.rectangle((px, py, px + cell - 1, py + cell - 1), fill=fill)
            if value != "0":
                draw.rectangle((px, py, px + cell - 1, py + cell - 1), outline="#606a78", width=1)


def render_architecture_offer(base_offer: dict[str, Any], out_path: Path) -> None:
    geometry = base_offer["geometry"]
    cell, margin, side = 12, 60, 250
    image = Image.new(
        "RGB",
        (geometry["width"] * cell + margin * 2 + side, geometry["depth"] * cell + margin * 2),
        "#10141c",
    )
    draw = ImageDraw.Draw(image, "RGBA")
    font = ImageFont.load_default()
    draw_structure(draw, base_offer["structure"], cell, margin)

    sx0 = margin + geometry["clear_spine_x0"] * cell
    sx1 = margin + (geometry["clear_spine_x1"] + 1) * cell
    sy1 = margin + (geometry["bays"][-1]["partition"] + 1) * cell
    draw.rectangle((sx0, margin, sx1, sy1), outline="#73e0a8", width=3)
    for bay in geometry["bays"]:
        y = margin + ((bay["start"] + bay["end"]) // 2) * cell
        draw.text((margin + 14, y), f"BAY {bay['index']:02d}  8 x 7 m", fill="#18202b", font=font)

    panel_x = margin + geometry["width"] * cell + 30
    draw.text((margin, 22), "PASS 1 / UFFIZI ARCHITECTURE OFFER", fill="#f2eadc", font=font)
    lines = [
        "Artifact-independent base pattern",
        "",
        "10 identical side bays",
        "8 x 7 x 4 m each",
        "3 m invariant public spine",
        "1 m display band",
        "aligned spine doors",
        "aligned enfilade thresholds",
        "south turn + west exit",
        "",
        "No artifact has been consulted yet.",
    ]
    for index, line in enumerate(lines):
        draw.text((panel_x, margin + index * 18), line, fill="#dbe1e9", font=font)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(out_path)


def render_footprint_plan(map_data: dict[str, Any], out_path: Path) -> None:
    info = map_data["map_info"]
    assignments = info["metadata"]["placement_overlay"]
    width = info["dimensions"]["width"]
    depth = info["dimensions"]["depth"]
    room_width = width - 7
    geometry = plan_geometry(
        room_width,
        [a["derived_offer_m"][1] for a in assignments],
        [a["derived_offer_m"][0] for a in assignments],
    )
    cell, margin, side = 12, 60, 355
    image = Image.new("RGB", (width * cell + margin * 2 + side, depth * cell + margin * 2), "#10141c")
    draw = ImageDraw.Draw(image, "RGBA")
    font = ImageFont.load_default()
    draw_structure(draw, map_data["layers"]["structure"], cell, margin)

    for assignment in assignments:
        x0, z0, x1, z1 = assignment["rect"]
        color = assignment["color"]
        box = (
            margin + x0 * cell + 1,
            margin + z0 * cell + 1,
            margin + (x1 + 1) * cell - 2,
            margin + (z1 + 1) * cell - 2,
        )
        draw.rectangle(box, fill=color + "77", outline=color, width=2)
        label = f"{assignment['index']:02d}"
        draw.text((box[0] + 3, box[1] + 3), label, fill="#ffffff", font=font)

    sx0 = margin + geometry["clear_spine_x0"] * cell
    sx1 = margin + (geometry["clear_spine_x1"] + 1) * cell
    sy1 = margin + (geometry["bays"][-1]["partition"] + 1) * cell
    draw.rectangle((sx0, margin, sx1, sy1), outline="#73e0a8", width=3)
    draw.text((margin, 22), "PASS 2 / ACCEPTED ARTIFACT FOOTPRINTS", fill="#f2eadc", font=font)

    panel_x = margin + width * cell + 28
    draw.text((panel_x, margin), "NEGOTIATED COHORT", fill="#f2eadc", font=font)
    for index, assignment in enumerate(assignments):
        y = margin + 30 + index * 62
        req = " x ".join(str(v) for v in assignment["request_m"])
        draw.rectangle((panel_x, y, panel_x + 12, y + 12), fill=assignment["color"])
        draw.text((panel_x + 18, y), f"{assignment['index']:02d} {assignment['display_name']}", fill="#dbe1e9", font=font)
        draw.text((panel_x + 18, y + 16), f"preferred zone: {req} m", fill="#aeb8c5", font=font)
        draw.text((panel_x + 18, y + 32), f"{assignment['preferred_mode']} / {assignment['required_support']}", fill="#aeb8c5", font=font)
    draw.rectangle((panel_x, margin + 670, panel_x + 12, margin + 682), outline="#73e0a8", width=2)
    draw.text((panel_x + 18, margin + 670), "3 m spine remains untouched", fill="#73e0a8", font=font)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(out_path)


def write_docs(map_name: str, out_dir: Path, map_data: dict[str, Any]) -> None:
    assignments = map_data["map_info"]["metadata"]["placement_overlay"]
    dimensions = map_data["map_info"]["dimensions"]
    rows = []
    for assignment in assignments:
        request = " x ".join(str(v) for v in assignment["request_m"])
        result = "; ".join(assignment["negotiation"])
        rows.append(
            f"| {assignment['index']:02d} | `{assignment['artifact']}` | {request} m | "
            f"{assignment['preferred_mode']} / {assignment['required_support']} | {result} |"
        )
    table = "\n".join(rows)

    (out_dir / "blurb.md").write_text(
        "The corridor is drawn before the collection arrives. Each object may ask the museum to breathe, "
        "but none may erase the route that lets strangers encounter one another.\n",
        encoding="utf-8",
    )
    (out_dir / "summary.md").write_text(
        f"""# Uffizi Footprint Cohort: Ten Contracts

## Overview

This {dimensions['width']} × {dimensions['depth']} m map scales the architecture-first pilot to ten artifacts. The generator first creates ten identical 8 × 7 × 4 m Uffizi side-bay offers. Only then are dressing-room contracts loaded and negotiated.

## Invariant architecture

- Three-metre clear east spine.
- One-metre display band outside that route.
- One aligned spine doorway and one aligned enfilade threshold per bay.
- South turn, axial end-stop, and westward exit.

## Negotiation results

| Bay | Artifact | Preferred zone | Mode / support | Accepted change |
|---:|---|---:|---|---|
{table}

The widest request expands the side-room field six metres away from the spine. Pattern Loom lengthens its bay one metre; Gradient Descent lengthens its bay six metres. The other eight artifacts accept the canonical seven-metre bay depth.

## Visitor sequence

The order moves from intimate featured objects through wall and host-mounted controls into increasingly environmental fields. The architecture remains legible as one repeated public system even as the rooms change scale.
""",
        encoding="utf-8",
    )
    (out_dir / "technical.md").write_text(
        f"""# Uffizi Footprint Cohort — Technical Contract

The source of truth is `tools/build_uffizi_footprint_cohort.py`. It performs two explicit passes:

1. `plan_geometry(8, [7] * 10)` creates the artifact-independent Uffizi offer.
2. `load_contracts()` reads each artifact's dressing-room JSON and `negotiate()` derives accepted bays.

The runtime uses the standard `structure`, `utilities`, and `interactables` layers. A fourth `footprints` evidence layer records every reserved preferred zone; GridSystem safely ignores that non-runtime layer.

Support is part of placement. `table`, `pedestal`, `plinth`, and `platform` contracts receive one raised 1 × 1 m structure tile beneath their artifact anchor. Against-wall artifacts are anchored against the north partition of their bay. All other artifacts receive a centered preferred zone.

Generation fails if a footprint overlaps another, enters the clear spine, touches non-floor space, loses required wall/support geometry, or if any doorway invariant is broken. Run:

```powershell
python tools\build_uffizi_footprint_cohort.py
python tools\map_pathfinder.py check {map_name}
```
""",
        encoding="utf-8",
    )
    (out_dir / "critical.md").write_text(
        """# Uffizi Footprint Cohort — Critical Reflection

## The contract and the institution

Architecture-first curation admits that the museum is never neutral. A corridor decides what can be approached, what becomes peripheral, and which bodies can pass one another. Here the spine is protected as shared infrastructure, while rooms are allowed to change in response to their contents.

## Negotiation rather than sovereignty

An artifact does not become sovereign merely because it is large. The Neural Network may widen the room away from the public path; Gradient Descent may lengthen a bay; neither may annex circulation. Conversely, the museum cannot force every object into the same white cube without falsifying how that object wants to be read.

The resulting rule set is deliberately incomplete but inspectable: invariant public access, explicit object claims, and a recorded settlement between them. The political question moves from “does it fit?” to “whose needs were allowed to redefine the room, and whose remained non-negotiable?”
""",
        encoding="utf-8",
    )
    (out_dir / "negotiation_report.md").write_text(
        f"""# Negotiation Report

## Base offer

- Pattern: `uffizi-spine-ordered`
- Bays: 10 identical 8 × 7 × 4 m side rooms
- Base plan: 15 × 85 m
- Public invariant: 3 m clear spine

## Accepted cohort

| Bay | Artifact | Preferred zone | Mode / support | Settlement |
|---:|---|---:|---|---|
{table}

## Derived plan

- Size: {dimensions['width']} × {dimensions['depth']} × {dimensions['max_height']} m
- Side-room expansion: westward only
- Spine width after negotiation: 3 m
- Footprint overlaps: forbidden
- Artifact count per bay: exactly one
""",
        encoding="utf-8",
    )

    sequence = {
        "sequences": {
            "museum_aaa_uffizi_cohort_10": {
                "name": "Museum AAA: Uffizi Footprint Cohort",
                "truth": "The building offers; the artifacts negotiate.",
                "qfep_term": "F↔E",
                "qfep_connection": "Architectural order remains legible while heterogeneous artifact needs perturb it.",
                "description": "Ten artifact placement contracts tested against a repeated Uffizi spine.",
                "layer": "integration",
                "prerequisites": [],
                "unlocks": [],
                "difficulty": "intermediate",
                "estimated_time": "12-18 minutes",
                "learning_objectives": map_data["map_info"]["metadata"]["learning_objectives"],
                "content": [f"{map_name}: ten architecture-first placement negotiations"],
                "maps": [map_name],
                "return_to": "lab",
            }
        }
    }
    sequence_path = MAPS_DIR / "sequences" / "museum_aaa_uffizi_cohort_10.json"
    sequence_path.write_text(compact_map_json._ser(sequence, 0) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--name", default="Museum_AAA_Uffizi_Cohort_10")
    args = parser.parse_args()

    map_data, base_offer = build_map(args.name)
    validate_contracts(map_data)
    out_dir = MAPS_DIR / args.name
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "map_data.json").write_text(
        compact_map_json._ser(map_data, 0) + "\n", encoding="utf-8"
    )
    render_architecture_offer(base_offer, out_dir / "architecture_offer.png")
    render_footprint_plan(map_data, out_dir / "footprint_plan.png")
    write_docs(args.name, out_dir, map_data)

    print(f"wrote {out_dir.relative_to(REPO)}")
    print("pass 1: artifact-independent Uffizi offer PASS")
    print("pass 2: ten footprint negotiations PASS")
    print("contracts: architecture invariants PASS; support and overlap rules PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
