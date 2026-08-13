#!/usr/bin/env python3
"""Compile the Endless Museum contract pilot into a map and visual proof files."""

from __future__ import annotations

import argparse
import html
import json
import math
import shutil
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
CONFIG_PATH = ROOT / "commons" / "data" / "museum_contract_pilot.json"
MAP_PATH = ROOT / "commons" / "maps" / "Museum_Contract_Pilot" / "map_data.json"
RUN_DIR = ROOT / "ada_run" / "museum_contract_pilot"
SOLVER_VERSION = "1.0.0"


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def odd_ceiling(value: float) -> int:
    result = int(math.ceil(value))
    return result if result % 2 else result + 1


def validate_config(config: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    artifacts = config.get("artifacts", [])
    names = [item.get("lookup_name") for item in artifacts]
    indices = [item.get("order", {}).get("index") for item in artifacts]
    if config.get("grid", {}).get("tile_m") != 1:
        errors.append("The pilot requires a one-metre tile grid.")
    if len(names) != len(set(names)):
        errors.append("Artifact lookup names must be unique.")
    if len(indices) != len(set(indices)):
        errors.append("Main order indices must be unique.")
    seen: set[str] = set()
    for artifact in sorted(artifacts, key=lambda item: item["order"]["index"]):
        name = artifact["lookup_name"]
        relation = artifact["order"].get("relation_to")
        if relation and relation not in seen:
            errors.append(f"{name}: relation target {relation} must appear earlier in the order.")
        seen.add(name)
        body = artifact.get("body_envelope_m", [])
        sweep = artifact.get("sweep_envelope_m", [])
        if len(body) != 3 or any(float(value) <= 0 for value in body):
            errors.append(f"{name}: body_envelope_m must contain three positive dimensions.")
        if len(sweep) != 3 or any(float(value) <= 0 for value in sweep):
            errors.append(f"{name}: sweep_envelope_m must contain three positive dimensions.")
        preferred = artifact.get("preferred_posture")
        if not artifact.get("placements", {}).get(preferred, {}).get("allowed", False):
            errors.append(f"{name}: preferred posture {preferred!r} is not allowed.")
        clearance = artifact.get("interaction", {}).get("clearance_m", {})
        if set(clearance) != {"front", "back", "left", "right"}:
            errors.append(f"{name}: all four directional clearances are required.")
    return errors


def choose_posture(artifact: dict[str, Any]) -> tuple[str, str]:
    preferred = artifact["preferred_posture"]
    placements = artifact["placements"]
    if placements.get(preferred, {}).get("allowed"):
        return preferred, "preferred posture accepted"
    for posture in ("wall", "island"):
        if placements.get(posture, {}).get("allowed"):
            return posture, f"preferred posture rejected; changed to allowed {posture} posture"
    raise ValueError(f"{artifact['lookup_name']} has no placeable posture")


def bay_width(artifact: dict[str, Any], posture: str) -> float:
    body_w, body_d, _ = [float(value) for value in artifact["body_envelope_m"]]
    sweep_w, sweep_d, _ = [float(value) for value in artifact["sweep_envelope_m"]]
    clearance = artifact["interaction"]["clearance_m"]
    if posture == "wall":
        overlap = float(artifact["placements"]["wall"].get("rear_overlap_m", 0))
        return max(sweep_d - overlap, body_d - overlap + float(clearance["front"]))
    return max(sweep_w, body_w + float(clearance["left"]) + float(clearance["right"]))


def section_depth(artifact: dict[str, Any], posture: str) -> float:
    body_w, body_d, _ = [float(value) for value in artifact["body_envelope_m"]]
    sweep_w, sweep_d, _ = [float(value) for value in artifact["sweep_envelope_m"]]
    clearance = artifact["interaction"]["clearance_m"]
    if posture == "wall":
        return max(sweep_w, body_w + float(clearance["left"]) + float(clearance["right"]))
    return max(sweep_d, body_d + float(clearance["front"]) + float(clearance["back"]))


def rect_overlap(a: dict[str, float], b: dict[str, float]) -> bool:
    return not (a["x1"] <= b["x0"] or a["x0"] >= b["x1"] or a["z1"] <= b["z0"] or a["z0"] >= b["z1"])


def solve(config: dict[str, Any]) -> dict[str, Any]:
    grid = config["grid"]
    ordered = sorted(config["artifacts"], key=lambda item: item["order"]["index"])
    posture_choices = [(artifact, *choose_posture(artifact)) for artifact in ordered]
    max_bay = max(bay_width(artifact, posture) for artifact, posture, _ in posture_choices)
    width = max(int(grid["base_width_cells"]), odd_ceiling(max_bay + grid["minimum_through_route_cells"] + 2))
    if width > int(grid["maximum_width_cells"]):
        raise ValueError(f"Required width {width} exceeds the configured maximum {grid['maximum_width_cells']}")

    placements: list[dict[str, Any]] = []
    route_rects: list[dict[str, float]] = []
    z_cursor = 2
    route_width = int(grid["minimum_through_route_cells"])
    gap = int(grid["section_gap_cells"])

    for index, (artifact, posture, reason) in enumerate(posture_choices):
        side = "left" if index % 2 == 0 else "right"
        depth = odd_ceiling(section_depth(artifact, posture))
        section_start = z_cursor
        section_end = section_start + depth + gap
        clear_z0 = section_start + gap / 2
        clear_z1 = clear_z0 + depth
        body_w, body_d, body_h = [float(value) for value in artifact["body_envelope_m"]]
        clearance = artifact["interaction"]["clearance_m"]
        available_bay = width - route_width - 2

        if posture == "wall":
            overlap = float(artifact["placements"]["wall"].get("rear_overlap_m", 0))
            projection = max(0.5, body_d - overlap)
            body_z0 = clear_z0 + float(clearance["left"])
            body_z1 = body_z0 + body_w
            if side == "left":
                body_rect = {"x0": 1.0, "x1": 1.0 + projection, "z0": body_z0, "z1": body_z1}
                clearance_rect = {"x0": 1.0, "x1": 1.0 + bay_width(artifact, posture), "z0": clear_z0, "z1": clear_z1}
                anchor_x, rotation = 1, 270
            else:
                body_rect = {"x0": width - 1.0 - projection, "x1": width - 1.0, "z0": body_z0, "z1": body_z1}
                clearance_rect = {"x0": width - 1.0 - bay_width(artifact, posture), "x1": width - 1.0, "z0": clear_z0, "z1": clear_z1}
                anchor_x, rotation = width - 2, 90
            anchor_z = int(round((body_z0 + body_z1) / 2))
        else:
            total_w = bay_width(artifact, posture)
            if side == "left":
                clear_x0 = 1.0
                body_x0 = clear_x0 + float(clearance["left"])
                rotation = 0
            else:
                clear_x0 = width - 1.0 - total_w
                body_x0 = clear_x0 + float(clearance["left"])
                rotation = 180
            body_z0 = clear_z0 + float(clearance["back"])
            body_rect = {"x0": body_x0, "x1": body_x0 + body_w, "z0": body_z0, "z1": body_z0 + body_d}
            clearance_rect = {"x0": clear_x0, "x1": clear_x0 + total_w, "z0": clear_z0, "z1": clear_z1}
            anchor_x = int(round((body_rect["x0"] + body_rect["x1"]) / 2))
            anchor_z = int(round((body_rect["z0"] + body_rect["z1"]) / 2))

        if side == "left":
            route = {"x0": float(width - 1 - route_width), "x1": float(width - 1), "z0": float(section_start), "z1": float(section_end)}
        else:
            route = {"x0": 1.0, "x1": float(1 + route_width), "z0": float(section_start), "z1": float(section_end)}
        route_rects.append(route)
        fits_bay = bay_width(artifact, posture) <= available_bay
        route_clear = not rect_overlap(clearance_rect, route)
        placements.append({
            "lookup_name": artifact["lookup_name"],
            "display_name": artifact["display_name"],
            "artifact_class": artifact["artifact_class"],
            "order": artifact["order"],
            "dna": artifact["dna"],
            "posture": posture,
            "side": side,
            "rotation_degrees": rotation,
            "anchor_cell": [anchor_x, anchor_z],
            "body_height_m": body_h,
            "body_rect": body_rect,
            "clearance_rect": clearance_rect,
            "route_rect": route,
            "section": {"z0": section_start, "z1": section_end},
            "decision": reason,
            "preferred_view_distance_m": artifact["view"]["preferred_distance_m"],
            "gates": {
                "posture_allowed": bool(artifact["placements"][posture]["allowed"]),
                "fits_negotiated_bay": fits_bay,
                "clearance_avoids_route": route_clear,
                "rotation_allowed": rotation in artifact["rotations"]
            }
        })
        z_cursor = section_end

    height = z_cursor + 2
    controls_payload = load_json(ROOT / "commons" / "data" / "artifact_controls.json")
    elements_payload = load_json(ROOT / "commons" / "data" / "artifact_elements.json")
    registry = dict(elements_payload.get("artifacts", elements_payload))
    registry.update(controls_payload.get("artifacts", controls_payload))
    registry_gates = {placement["lookup_name"]: placement["lookup_name"] in registry for placement in placements}
    all_local_gates = all(all(item["gates"].values()) for item in placements)
    width_changed = width != int(grid["base_width_cells"])
    negotiations = [{
        "layer": "floorplan ↔ artifact",
        "decision": f"Expanded width from {grid['base_width_cells']} m to {width} m.",
        "because": f"The largest accepted bay needs {max_bay:g} m beside a {route_width} m through-route.",
        "status": "accepted"
    }] if width_changed else [{
        "layer": "floorplan ↔ artifact",
        "decision": f"Kept the base width of {width} m.",
        "because": "All accepted envelopes fit without narrowing the through-route.",
        "status": "accepted"
    }]
    negotiations.extend({
        "layer": "artifact ↔ floorplan",
        "artifact": placement["display_name"],
        "decision": f"Placed {placement['posture']} on the {placement['side']}.",
        "because": placement["decision"],
        "status": "accepted" if all(placement["gates"].values()) else "failed"
    } for placement in placements)

    return {
        "schema": "adaresearch.museum_contract_pilot.report.v1",
        "solver_version": SOLVER_VERSION,
        "source": str(CONFIG_PATH.relative_to(ROOT)).replace("\\", "/"),
        "summary": {
            "artifact_count": len(placements),
            "contract_layers": len(config["layer_contracts"]),
            "width_cells": width,
            "base_width_cells": int(grid["base_width_cells"]),
            "depth_cells": height,
            "route_width_cells": route_width,
            "width_expanded": width_changed,
            "hard_gates_passed": all_local_gates and all(registry_gates.values()),
            "placement_modes": {
                "wall": sum(item["posture"] == "wall" for item in placements),
                "island": sum(item["posture"] == "island" for item in placements)
            }
        },
        "rule_priority": config["negotiation"]["priority"],
        "layers": config["layer_contracts"],
        "wall_system": config["wall_system"],
        "placements": placements,
        "route_rects": route_rects,
        "negotiations": negotiations,
        "global_gates": {
            "contract_schema_valid": True,
            "unique_main_order": len({item["order"]["index"] for item in placements}) == len(placements),
            "lineage_points_backward": True,
            "one_metre_module": grid["tile_m"] == 1,
            "minimum_route_preserved": route_width >= 3,
            "all_artifacts_registered": all(registry_gates.values()),
            "all_placement_gates_pass": all_local_gates
        },
        "registry_gates": registry_gates,
        "book_excerpt": "I entered on the line marked zero. Each room made a proposition, then stepped aside far enough for my body to answer. The walls carried the argument; the objects kept the space around them. By the pendulum, the exhibition was no longer a row of things but a sequence of permissions."
    }


def make_grid(height: int, width: int, fill: str = " ") -> list[list[str]]:
    return [[fill for _ in range(width)] for _ in range(height)]


def compile_map(config: dict[str, Any], report: dict[str, Any]) -> dict[str, Any]:
    width = report["summary"]["width_cells"]
    height = report["summary"]["depth_cells"]
    structure = make_grid(height, width, "1")
    utilities = make_grid(height, width)
    interactables = make_grid(height, width)
    for z in range(height):
        structure[z][0] = "4"
        structure[z][-1] = "4"
    for x in range(width):
        structure[0][x] = "4"
        structure[-1][x] = "4"

    spawn_x = width // 2
    utilities[1][spawn_x] = "s"
    utilities[-2][spawn_x] = "t"
    structure[-2][spawn_x] = "0"
    for placement in report["placements"]:
        x, z = placement["anchor_cell"]
        x = max(1, min(width - 2, int(x)))
        z = max(1, min(height - 2, int(z)))
        interactables[z][x] = f"{placement['lookup_name']}:{placement['rotation_degrees']}:0.0"

    chapter_order = [item["display_name"] for item in report["placements"]]
    return {
        "map_info": {
            "name": "Museum Contract Pilot — Twelve Negotiated Artifacts",
            "lookup_name": "Museum_Contract_Pilot",
            "description": "A one-metre modular museum segment compiled from explicit artifact, order, floorplan, wall, museum, and book contracts.",
            "version": "1.0.0",
            "format": "json",
            "dimensions": {"width": width, "depth": height, "max_height": 4},
            "metadata": {
                "category": "museum-pilot",
                "difficulty": "exhibition",
                "estimated_time": "12–18 minutes",
                "learning_objectives": [
                    "Read artifact lineage as a spatial sequence",
                    "Compare wall-backed and island placement contracts",
                    "See how the floorplan expands without sacrificing the through-route"
                ],
                "contract_source": "res://commons/data/museum_contract_pilot.json",
                "solver_version": SOLVER_VERSION,
                "chapter_order": chapter_order
            }
        },
        "utility_definitions": {
            "t": {"type": "teleporter", "name": "Continue", "description": "Leave the pilot segment", "properties": {"action": "next_in_sequence"}}
        },
        "spawn_points": {
            "default": {"position": [spawn_x + 0.5, 1.8, 1.5], "rotation": [0.0, 180.0, 0.0], "description": "Aligned to the three-metre through-route"}
        },
        "documentation": {
            "contract_layers": list(config["layer_contracts"].keys()),
            "rule_priority": report["rule_priority"],
            "book_excerpt": report["book_excerpt"],
            "hard_gates": report["global_gates"]
        },
        "lighting": {
            "ambient_color": [0.78, 0.8, 0.86],
            "ambient_energy": 0.55,
            "directional_light": {"enabled": True, "direction": [-0.3, -0.8, -0.2], "color": [1.0, 0.96, 0.9], "energy": 0.85}
        },
        "settings": {"cube_size": 1.0, "gutter": 0.0, "show_grid": True, "enable_physics": True, "background": {"type": "sky", "color": [0.035, 0.045, 0.07]}},
        "layers": {"structure": structure, "utilities": utilities, "interactables": interactables}
    }


def svg_escape(value: Any) -> str:
    return html.escape(str(value), quote=True)


def floor_svg(report: dict[str, Any]) -> str:
    width = report["summary"]["width_cells"]
    depth = report["summary"]["depth_cells"]
    cell = 7
    gx, gy = 42, 54
    canvas_w = 860
    canvas_h = gy + depth * cell + 50
    pieces = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {canvas_w} {canvas_h}" role="img" aria-labelledby="title desc">',
        '<title id="title">Negotiated one-metre museum floor plan</title>',
        '<desc id="desc">Twelve artifact bodies, their clearance envelopes, and the continuous three-metre route.</desc>',
        '<rect width="100%" height="100%" fill="#07111f"/>',
        '<style>text{font-family:ui-monospace,SFMono-Regular,Consolas,monospace}.label{font-size:12px;fill:#d8e5f2}.small{font-size:10px;fill:#8fa6ba}.body{fill:#f6b94a;stroke:#ffe2a6;stroke-width:1}.clear{fill:#f6b94a;fill-opacity:.16;stroke:#f6b94a;stroke-dasharray:3 2}.route{fill:#48b6d9;fill-opacity:.34}.wall{fill:#23364a}</style>',
        '<text x="42" y="25" class="label">FLOOR CONTRACT · 1 CELL = 1 METRE</text>',
        f'<text x="42" y="42" class="small">{width} m × {depth} m · bodies amber · clearance dashed · through-route cyan</text>',
        f'<rect x="{gx}" y="{gy}" width="{width*cell}" height="{depth*cell}" fill="#0d1c2b" stroke="#395069"/>',
    ]
    for route in report["route_rects"]:
        pieces.append(f'<rect class="route" x="{gx+route["x0"]*cell:.1f}" y="{gy+route["z0"]*cell:.1f}" width="{(route["x1"]-route["x0"])*cell:.1f}" height="{(route["z1"]-route["z0"])*cell:.1f}"/>')
    for x in range(width + 1):
        pieces.append(f'<line x1="{gx+x*cell}" y1="{gy}" x2="{gx+x*cell}" y2="{gy+depth*cell}" stroke="#193047" stroke-width=".45"/>')
    for z in range(depth + 1):
        pieces.append(f'<line x1="{gx}" y1="{gy+z*cell}" x2="{gx+width*cell}" y2="{gy+z*cell}" stroke="#193047" stroke-width=".45"/>')
    pieces.extend([
        f'<rect class="wall" x="{gx}" y="{gy}" width="{cell}" height="{depth*cell}"/>',
        f'<rect class="wall" x="{gx+(width-1)*cell}" y="{gy}" width="{cell}" height="{depth*cell}"/>'
    ])
    label_x = gx + width * cell + 28
    for placement in report["placements"]:
        clear = placement["clearance_rect"]
        body = placement["body_rect"]
        cy = gy + ((placement["section"]["z0"] + placement["section"]["z1"]) / 2) * cell
        pieces.append(f'<rect class="clear" x="{gx+clear["x0"]*cell:.1f}" y="{gy+clear["z0"]*cell:.1f}" width="{(clear["x1"]-clear["x0"])*cell:.1f}" height="{(clear["z1"]-clear["z0"])*cell:.1f}" rx="2"/>')
        pieces.append(f'<rect class="body" x="{gx+body["x0"]*cell:.1f}" y="{gy+body["z0"]*cell:.1f}" width="{max(2,(body["x1"]-body["x0"])*cell):.1f}" height="{max(2,(body["z1"]-body["z0"])*cell):.1f}" rx="1"/>')
        pieces.append(f'<line x1="{gx+width*cell}" y1="{cy:.1f}" x2="{label_x-7}" y2="{cy:.1f}" stroke="#314a61"/>')
        pieces.append(f'<text x="{label_x}" y="{cy-2:.1f}" class="label">{placement["order"]["index"]:02d} {svg_escape(placement["display_name"])}</text>')
        pieces.append(f'<text x="{label_x}" y="{cy+11:.1f}" class="small">{placement["posture"]} · {placement["side"]} · {svg_escape(" / ".join(placement["dna"]))}</text>')
    pieces.append('</svg>')
    return "\n".join(pieces)


def wall_svg(config: dict[str, Any], report: dict[str, Any]) -> str:
    wall_items = [item for item in report["placements"] if item["posture"] == "wall"]
    width, height = 1200, 520
    wall_x, wall_y, wall_w, wall_h = 70, 90, 1060, 330
    pieces = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">',
        '<title id="title">Wall placement contract</title>',
        '<desc id="desc">Feature field, prop rails, height bands, and accepted wall artifacts.</desc>',
        '<rect width="100%" height="100%" fill="#07111f"/>',
        '<style>text{font-family:ui-monospace,SFMono-Regular,Consolas,monospace}.label{font-size:14px;fill:#d8e5f2}.small{font-size:11px;fill:#8fa6ba}.artifact{fill:#f6b94a;stroke:#ffe2a6}.field{fill:#48b6d9;fill-opacity:.12;stroke:#48b6d9;stroke-dasharray:7 5}.rail{fill:#b77cff;fill-opacity:.14;stroke:#b77cff;stroke-dasharray:4 3}</style>',
        '<text x="70" y="34" class="label">WALL CONTRACT · FEATURE CENTRE + PROP RAILS</text>',
        '<text x="70" y="57" class="small">The map text/painting field stays central; support props occupy the side rails and controlled height bands.</text>',
        f'<rect x="{wall_x}" y="{wall_y}" width="{wall_w}" height="{wall_h}" fill="#0d1c2b" stroke="#395069"/>',
    ]
    for metre in range(5):
        y = wall_y + wall_h - (metre / 4) * wall_h
        pieces.append(f'<line x1="{wall_x}" y1="{y:.1f}" x2="{wall_x+wall_w}" y2="{y:.1f}" stroke="#193047"/>')
        pieces.append(f'<text x="25" y="{y+4:.1f}" class="small">{metre} m</text>')
    fx = wall_x + wall_w * 0.20
    fw = wall_w * 0.60
    fy = wall_y + wall_h - (2.7 / 4) * wall_h
    fh = ((2.7 - 1.1) / 4) * wall_h
    pieces.append(f'<rect class="field" x="{fx}" y="{fy}" width="{fw}" height="{fh}" rx="6"/>')
    pieces.append(f'<text x="{fx+fw/2}" y="{fy+fh/2}" text-anchor="middle" class="label">RESERVED FEATURE FIELD · MAP TEXT / BOOK MONITOR</text>')
    rail_w = wall_w * 0.18
    rail_y = wall_y + wall_h - (2.3 / 4) * wall_h
    rail_h = ((2.3 - 0.75) / 4) * wall_h
    pieces.append(f'<rect class="rail" x="{wall_x}" y="{rail_y}" width="{rail_w}" height="{rail_h}"/>')
    pieces.append(f'<rect class="rail" x="{wall_x+wall_w-rail_w}" y="{rail_y}" width="{rail_w}" height="{rail_h}"/>')
    for index, item in enumerate(wall_items[:5]):
        side_left = index % 2 == 0
        item_w = min(150, rail_w - 20)
        item_h = min(105, item["body_height_m"] / 4 * wall_h)
        x = wall_x + 10 if side_left else wall_x + wall_w - rail_w + 10
        y = wall_y + wall_h - (0.9 / 4 * wall_h) - item_h
        pieces.append(f'<rect class="artifact" x="{x}" y="{y}" width="{item_w}" height="{item_h}" rx="4"/>')
        pieces.append(f'<text x="{x+item_w/2}" y="{y+item_h/2}" text-anchor="middle" class="small">{svg_escape(item["display_name"])}</text>')
    pieces.append(f'<text x="{wall_x}" y="{wall_y+wall_h+34}" class="small">interactive controls: 0.75–1.35 m · eye band: 1.1–2.3 m · wall height: 4 m</text>')
    pieces.append('</svg>')
    return "\n".join(pieces)


def sync_web_assets(web_root: Path) -> None:
    target = web_root / "museum-contract-pilot"
    target.mkdir(parents=True, exist_ok=True)
    for name in ("report.json", "floor_plan.svg", "wall_elevation.svg"):
        shutil.copy2(RUN_DIR / name, target / name)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--web-root", type=Path, help="Optional encyclopedia public directory to receive proof assets")
    parser.add_argument("--check", action="store_true", help="Validate and solve without writing files")
    args = parser.parse_args()

    config = load_json(CONFIG_PATH)
    errors = validate_config(config)
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    report = solve(config)
    failed = [name for name, passed in report["global_gates"].items() if not passed]
    if failed:
        print("FAILED GATES: " + ", ".join(failed))
        return 1
    if not args.check:
        RUN_DIR.mkdir(parents=True, exist_ok=True)
        write_json(RUN_DIR / "report.json", report)
        (RUN_DIR / "floor_plan.svg").write_text(floor_svg(report), encoding="utf-8")
        (RUN_DIR / "wall_elevation.svg").write_text(wall_svg(config, report), encoding="utf-8")
        write_json(MAP_PATH, compile_map(config, report))
        if args.web_root:
            sync_web_assets(args.web_root.resolve())
    summary = report["summary"]
    print(f"PASS: {summary['artifact_count']} artifacts, {summary['width_cells']}×{summary['depth_cells']} cells, {summary['route_width_cells']} m route")
    print(f"PASS: {sum(report['global_gates'].values())}/{len(report['global_gates'])} global gates")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
