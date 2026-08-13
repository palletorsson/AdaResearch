#!/usr/bin/env python3
"""Compile artifact-aware wall props into the Uffizi footprint cohort.

The source cohort owns architecture and artifact footprints.  This pass treats
each selected north wall as a two-dimensional surface (u, v), negotiates prop
requests against feature fields, side rails, reach heights, and artifact claims,
then compiles only accepted requests into runtime ``cluster:`` tokens.
"""

from __future__ import annotations

import argparse
import copy
import json
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont

import compact_map_json


REPO = Path(__file__).resolve().parent.parent
MAPS_DIR = REPO / "commons" / "maps"
CLUSTERS_DIR = REPO / "commons" / "data" / "curated_walls" / "clusters"
BASE_MAP = MAPS_DIR / "Museum_AAA_Uffizi_Cohort_10" / "map_data.json"
MUSEUM_CONTRACT = REPO / "commons" / "data" / "museum_contract_pilot.json"
PROP_RULES = REPO / "commons" / "data" / "museum_prop_placement_rules.json"
DEFAULT_NAME = "Museum_AAA_Uffizi_Prop_Pilot"
CLUSTER_ANCHOR_X = 16


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def rounded(value: float) -> float:
    return round(float(value), 3)


def rect_overlap(a: list[float], b: list[float]) -> bool:
    return a[0] < b[2] and a[2] > b[0] and a[1] < b[3] and a[3] > b[1]


def rect_inside(inner: list[float], outer: list[float], tolerance: float = 0.001) -> bool:
    return (
        inner[0] >= outer[0] - tolerance
        and inner[1] >= outer[1] - tolerance
        and inner[2] <= outer[2] + tolerance
        and inner[3] <= outer[3] + tolerance
    )


def centered_rect(u: float, v: float, width: float, height: float) -> list[float]:
    return [
        rounded(u - width * 0.5),
        rounded(v - height * 0.5),
        rounded(u + width * 0.5),
        rounded(v + height * 0.5),
    ]


def bottom_rect(u: float, v: float, width: float, height: float) -> list[float]:
    return [rounded(u - width * 0.5), rounded(v), rounded(u + width * 0.5), rounded(v + height)]


def find_assignment(map_data: dict[str, Any], artifact: str) -> dict[str, Any]:
    for assignment in map_data["map_info"]["metadata"]["placement_overlay"]:
        if assignment["artifact"] == artifact:
            return assignment
    raise ValueError(f"missing footprint assignment for {artifact}")


def make_surface(
    assignment: dict[str, Any],
    wall_system: dict[str, Any],
    disposition: str,
    archetype: str,
) -> dict[str, Any]:
    width = float(assignment["derived_offer_m"][0])
    room_x0 = 15 - int(width)
    wall_z = int(assignment["bay_rows"][0]) - 1
    wall_height = 4.0
    feature_pct = wall_system["feature_field"]["horizontal_percent"]
    feature_vertical = wall_system["feature_field"]["vertical_m"]
    rail_pct = wall_system["prop_rails"]["horizontal_percent"]
    rail_vertical = wall_system["prop_rails"]["vertical_m"]
    feature = [
        rounded(width * feature_pct[0] / 100.0),
        float(feature_vertical[0]),
        rounded(width * feature_pct[1] / 100.0),
        float(feature_vertical[1]),
    ]
    rails = [
        [0.0, float(rail_vertical[0]), rounded(width * rail_pct[0][1] / 100.0), float(rail_vertical[1])],
        [rounded(width * rail_pct[1][0] / 100.0), float(rail_vertical[0]), width, float(rail_vertical[1])],
    ]
    surface: dict[str, Any] = {
        "bay": assignment["bay"],
        "artifact": assignment["artifact"],
        "display_name": assignment["display_name"],
        "wall": "north",
        "coordinate_system": {
            "surface_axes": ["u", "v"],
            "u": "west-to-east",
            "v": "floor-to-ceiling",
            "world_axes": ["x", "y"],
            "normal_axis": "z",
            "grid_m": 1,
        },
        "dimensions_m": [width, wall_height],
        "index": int(assignment["index"]),
        "preferred_mode": assignment["preferred_mode"],
        "required_support": assignment["required_support"],
        "placement_intent": assignment["placement_intent"],
        "world_origin_m": [room_x0 - 0.5, 0.0, wall_z + 0.5],
        "normal": [0, 0, 1],
        "feature_field_uv_m": feature,
        "prop_rails_uv_m": rails,
        "interactive_height_m": [0.75, 1.35],
        "disposition": disposition,
        "principal_wall_archetype": archetype,
        "semantic_anchors_uv_m": {
            "left_corner": [0.0, 0.0],
            "right_corner": [width, 0.0],
            "entrance_exit": [width, 0.0],
            "feature_center": [rounded(width * 0.5), rounded((feature[1] + feature[3]) * 0.5)],
        },
        "accepted": [],
        "rejected": [],
    }
    if assignment["preferred_mode"] == "against_wall":
        # Wall artifacts receive the same explicit 3 x 3 m protected claim.
        # Lambda established the rule; Shannon proves that it generalizes.
        anchor_x = float(assignment["anchor"][0])
        hero_u = anchor_x - float(surface["world_origin_m"][0])
        surface["artifact_wall_claim_uv_m"] = [
            rounded(hero_u - 1.5),
            0.5,
            rounded(hero_u + 1.5),
            3.5,
        ]
    return surface


def candidate(
    *,
    request_id: str,
    token: str,
    role: str,
    band: str,
    rect: list[float],
    origin_uv: list[float],
    config: dict[str, Any],
    interactive: bool = False,
    mounting: str = "wall",
    priority: str = "decoration",
    anchor_kind: str | None = None,
    anchor_id: str | None = None,
    max_horizontal_distance_m: float | None = None,
    depth_from_wall_m: float = 0.0,
) -> dict[str, Any]:
    return {
        "request_id": request_id,
        "token": token,
        "role": role,
        "requested_band": band,
        "rect_uv_m": rect,
        "origin_uv_m": [rounded(origin_uv[0]), rounded(origin_uv[1])],
        "interactive": interactive,
        "mounting": mounting,
        "priority": priority,
        "anchor_kind": anchor_kind,
        "anchor_id": anchor_id,
        "max_horizontal_distance_m": max_horizontal_distance_m,
        "depth_from_wall_m": depth_from_wall_m,
        "config": config,
    }


def prop_requests(surface: dict[str, Any], rules: dict[str, Any]) -> list[dict[str, Any]]:
    width = float(surface["dimensions_m"][0])
    left, right = surface["prop_rails_uv_m"]
    feature = surface["feature_field_uv_m"]
    artifact = surface["artifact"]

    def ruled(
        request_id: str,
        token: str,
        band: str,
        u: float,
        v: float,
        anchor_id: str,
        config: dict[str, Any] | None = None,
        size_m: list[float] | None = None,
        depth_from_wall_m: float = 0.0,
    ) -> dict[str, Any]:
        rule = rules["prop_types"][token]
        width_m, height_m = size_m or rule["size_m"]
        mounting = rule["mounting"]
        rect = (
            bottom_rect(u, v, width_m, height_m)
            if mounting == "floor_against_wall"
            else centered_rect(u, v, width_m, height_m)
        )
        return candidate(
            request_id=request_id,
            token=token,
            role=rule["role"],
            band=band,
            rect=rect,
            origin_uv=[u, v],
            config=config or {},
            interactive=bool(rule.get("interactive", False)),
            mounting=mounting,
            priority=rule["priority"],
            anchor_kind=rule["anchor_kind"],
            anchor_id=anchor_id,
            max_horizontal_distance_m=rule.get("max_horizontal_distance_m"),
            depth_from_wall_m=depth_from_wall_m,
        )

    safety = [
        ruled(
            "exit_wayfinding",
            "exit_sign",
            "upper_side",
            width - 0.65,
            3.15,
            "entrance_exit",
            {"text": "EXIT", "mounting": "above_threshold"},
        ),
        ruled(
            "fire_point",
            "fire_extinguisher",
            "low_side",
            width - 0.45,
            0.0,
            "entrance_exit",
            {"support": "floor_bracket", "statute": "issue", "label_text": "FIRE"},
            depth_from_wall_m=0.2,
        ),
    ]
    if artifact == "lambda_slider":
        lu = (left[0] + left[2]) * 0.5
        ru = (right[0] + right[2]) * 0.5
        return [
            ruled(
                "lambda_interrupt",
                "emergency_button",
                "left_rail",
                lu,
                1.05,
                "left_corner",
                {
                    "mounting": "wall",
                    "label_text": "STOP",
                    "plate_width": 0.22,
                    "plate_height": 0.22,
                },
            ),
            ruled(
                "lambda_status",
                "station_panel",
                "right_rail",
                ru,
                1.85,
                "entrance_exit",
                {
                    "width_cells": 1,
                    "height": 0.6,
                    "header": "LAMBDA",
                    "lines": ["ORDER <-> CHAOS", "CALIBRATION LIVE"],
                    "accent_color": "0.28,0.74,0.96,1",
                },
                size_m=[0.9, 0.6],
            ),
            *safety,
        ]
    if surface["principal_wall_archetype"] == "feature_wall":
        fu = (feature[0] + feature[2]) * 0.5
        header = str(surface["display_name"]).upper()
        feature_requests = [
            ruled(
                f"{artifact}_feature_caption",
                "station_panel",
                "feature_field",
                fu,
                1.9,
                "feature_center",
                {
                    "width_cells": 4,
                    "height": 0.8,
                    "header": header,
                    "lines": ["CURRENT MAP / BOOK MONITOR", surface["preferred_mode"].replace("_", " ").upper()],
                    "accent_color": "0.72,0.32,0.66,1",
                },
            ),
        ]
        if artifact == "platonicsolids":
            feature_requests.append(ruled(
                "material_corner_stack",
                "station_crates",
                "floor_corner",
                0.5,
                0.0,
                "left_corner",
                {"stack": "two_high", "contents": "exhibition_material"},
                depth_from_wall_m=0.45,
            ))
        return [*feature_requests, *safety]
    if surface["principal_wall_archetype"] == "protected_artifact":
        fu = (feature[0] + feature[2]) * 0.5
        return [
            ruled(
                f"{artifact}_feature_caption",
                "station_panel",
                "feature_field",
                fu,
                1.9,
                "feature_center",
                {
                    "width_cells": 4,
                    "height": 0.8,
                    "header": str(surface["display_name"]).upper(),
                    "lines": ["REQUESTED MAP MONITOR"],
                },
            ),
            *safety,
        ]
    return safety


def negotiate_surface(surface: dict[str, Any], rules: dict[str, Any]) -> None:
    accepted: list[dict[str, Any]] = surface["accepted"]
    for request in prop_requests(surface, rules):
        reasons: list[str] = []
        rect = request["rect_uv_m"]
        wall_rect = [0.0, 0.0, *surface["dimensions_m"]]
        if not rect_inside(rect, wall_rect):
            reasons.append("outside_wall_surface")
        if surface["disposition"] == "protected_environment" and request["priority"] != "life_safety":
            reasons.append("artifact_contract_protects_the_full_environment")

        band = request["requested_band"]
        if band == "feature_field" and not rect_inside(rect, surface["feature_field_uv_m"]):
            reasons.append("outside_feature_field")
        if band == "left_rail" and not rect_inside(rect, surface["prop_rails_uv_m"][0]):
            reasons.append("outside_left_prop_rail")
        if band == "right_rail" and not rect_inside(rect, surface["prop_rails_uv_m"][1]):
            reasons.append("outside_right_prop_rail")
        if band in ("upper_side", "low_side"):
            vertical = rules["bands"]["upper" if band == "upper_side" else "low"]["vertical_m"]
            side_rects = [
                [rail[0], float(vertical[0]), rail[2], float(vertical[1])]
                for rail in surface["prop_rails_uv_m"]
            ]
            if not any(rect_inside(rect, side) for side in side_rects):
                reasons.append(f"outside_{band}")
        if band == "floor_corner":
            if abs(float(rect[1])) > 0.001:
                reasons.append("floor_prop_does_not_touch_floor")
            if not rect_inside(rect, [0.0, 0.0, surface["prop_rails_uv_m"][0][2], 1.1]):
                reasons.append("outside_floor_corner")

        if band != "feature_field" and rect_overlap(rect, surface["feature_field_uv_m"]):
            reasons.append("support_prop_enters_feature_field")

        claim = surface.get("artifact_wall_claim_uv_m")
        if claim and rect_overlap(rect, claim):
            reasons.append("overlaps_artifact_wall_claim")
        if request["interactive"]:
            center_v = float(request["origin_uv_m"][1])
            reach = surface["interactive_height_m"]
            if not reach[0] <= center_v <= reach[1]:
                reasons.append("interactive_control_outside_reach_band")
        anchor_id = request.get("anchor_id")
        if request.get("anchor_kind") and anchor_id not in surface["semantic_anchors_uv_m"]:
            reasons.append("missing_semantic_anchor")
        elif anchor_id and request.get("max_horizontal_distance_m") is not None:
            anchor_u = float(surface["semantic_anchors_uv_m"][anchor_id][0])
            distance = abs(float(request["origin_uv_m"][0]) - anchor_u)
            request["anchor_distance_m"] = rounded(distance)
            if distance > float(request["max_horizontal_distance_m"]):
                reasons.append("too_far_from_semantic_anchor")
        if request["mounting"] == "floor_against_wall" and abs(float(rect[1])) > 0.001:
            reasons.append("floor_prop_is_not_grounded")
        if any(rect_overlap(rect, item["rect_uv_m"]) for item in accepted):
            reasons.append("overlaps_accepted_prop")

        request["decision"] = "rejected" if reasons else "accepted"
        request["reasons"] = reasons or ["all_hard_rules_pass"]
        if reasons:
            surface["rejected"].append(request)
        else:
            accepted.append(request)


def compile_cluster(surface: dict[str, Any]) -> tuple[str | None, dict[str, Any] | None]:
    if not surface["accepted"]:
        return None, None
    cluster_name = f"uffizi_props_{surface['bay']}_{surface['artifact']}"
    anchor_z = int(surface["world_origin_m"][2] + 0.5)
    pieces = []
    for item in surface["accepted"]:
        u, v = item["origin_uv_m"]
        world_x = float(surface["world_origin_m"][0]) + float(u)
        wall_mounted = item["mounting"] == "wall"
        pieces.append(
            {
                "token": item["token"],
                "x": rounded(world_x - CLUSTER_ANCHOR_X),
                "y": rounded(v if wall_mounted else 0.0),
                "z": rounded(-0.5 if wall_mounted else item["depth_from_wall_m"]),
                "wall": wall_mounted,
                "config": item["config"],
            }
        )
    cluster = {
        "name": cluster_name,
        "source": "tools/build_uffizi_prop_placement_pilot.py",
        "contract": {
            "bay": surface["bay"],
            "artifact": surface["artifact"],
            "anchor_cell": [CLUSTER_ANCHOR_X, anchor_z],
            "wall": "north",
        },
        "pieces": pieces,
    }
    return cluster_name, cluster


def build_map(map_name: str = DEFAULT_NAME) -> tuple[dict[str, Any], dict[str, dict[str, Any]]]:
    base = read_json(BASE_MAP)
    map_data = copy.deepcopy(base)
    contract = read_json(MUSEUM_CONTRACT)
    prop_rules = read_json(PROP_RULES)
    wall_system = contract["wall_system"]
    specs = [
        ("origin", "freestanding_hero_with_feature_field", "feature_wall"),
        ("lambda_slider", "wall_hero_with_side_rails", "entrance_safety"),
        ("phi_slider", "host_mounted_with_feature_field", "feature_wall"),
        ("platonicsolids", "freestanding_hero_with_feature_field", "feature_wall"),
        ("random_walk_leash", "freestanding_hero_with_feature_field", "feature_wall"),
        ("shannon_entropy_meter", "wall_hero_with_side_rails", "entrance_safety"),
        ("harmonic_distance_table", "host_mounted_with_feature_field", "feature_wall"),
        ("pattern_loom", "freestanding_hero_with_feature_field", "feature_wall"),
        ("gradient_descent_visualization", "protected_environment", "protected_artifact"),
        ("neural_network_visualization", "protected_environment", "protected_artifact"),
    ]
    surfaces = []
    clusters: dict[str, dict[str, Any]] = {}
    interactables = map_data["layers"]["interactables"]
    for artifact, disposition, archetype in specs:
        assignment = find_assignment(map_data, artifact)
        surface = make_surface(assignment, wall_system, disposition, archetype)
        negotiate_surface(surface, prop_rules)
        cluster_name, cluster = compile_cluster(surface)
        anchor_z = int(assignment["bay_rows"][0])
        surface["runtime_anchor_cell"] = [CLUSTER_ANCHOR_X, anchor_z]
        surface["cluster"] = cluster_name
        if cluster_name and cluster:
            if str(interactables[anchor_z][CLUSTER_ANCHOR_X]).strip():
                raise ValueError(f"cluster anchor occupied at ({CLUSTER_ANCHOR_X},{anchor_z})")
            interactables[anchor_z][CLUSTER_ANCHOR_X] = f"cluster:{cluster_name}:0"
            clusters[cluster_name] = cluster
        surfaces.append(surface)

    info = map_data["map_info"]
    info["lookup_name"] = map_name
    info["name"] = map_name
    info["title"] = "Uffizi Principal-Wall Prop Pilot"
    info["description"] = (
        "Ten principal Uffizi walls place exit, fire-safety, corner-storage, and book-monitor "
        "props on a one-metre u-v grid while protecting the exhibition centre."
    )
    info["version"] = "5.0-ten-bay-principal-wall-contract"
    info["format"] = "ada-3layer-v1+footprint-overlay+semantic-wall-surface-contracts"
    metadata = info["metadata"]
    metadata["source_map"] = "Museum_AAA_Uffizi_Cohort_10"
    metadata["wall_surface_contracts"] = surfaces
    metadata["prop_rule_source"] = "res://commons/data/museum_prop_placement_rules.json"
    metadata["ideal_prop_context"] = {
        "bay": "bay_04",
        "artifact": "platonicsolids",
        "reason": "Shows a feature monitor, high exit sign, low extinguisher, and grounded corner stack together without entering the central walking orbit.",
    }
    metadata["prop_placement_summary"] = {
        "pilot_bays": len(surfaces),
        "accepted_props": sum(len(surface["accepted"]) for surface in surfaces),
        "rejected_props": sum(len(surface["rejected"]) for surface in surfaces),
        "runtime_clusters": len(clusters),
        "solver_version": "uffizi-semantic-wall-negotiator-v2",
        "priority": prop_rules["priority"],
        "hard_rules": prop_rules["hard_rules"],
        "principal_wall_archetypes": list(prop_rules["principal_wall_archetypes"]),
    }
    metadata["learning_objectives"] = [
        "Read wall placement as an orientation-independent u-v grid rather than decoration",
        "Place safety and operations props by semantic anchors such as exits and corners",
        "Keep the central artifact and book-monitor field free of support props",
        "Recognize a refused prop placement as a successful negotiation outcome",
    ]
    return map_data, clusters


def validate(map_data: dict[str, Any], clusters: dict[str, dict[str, Any]]) -> None:
    info = map_data["map_info"]
    width = int(info["dimensions"]["width"])
    depth = int(info["dimensions"]["depth"])
    layers = map_data["layers"]
    for name in ("structure", "utilities", "interactables", "footprints"):
        if len(layers[name]) != depth or any(len(row) != width for row in layers[name]):
            raise ValueError(f"{name} is not {width}x{depth}")

    surfaces = info["metadata"]["wall_surface_contracts"]
    expected_order = [assignment["artifact"] for assignment in info["metadata"]["placement_overlay"]]
    if [surface["artifact"] for surface in surfaces] != expected_order:
        raise ValueError("unexpected pilot surface order")
    for surface in surfaces:
        wall = [0.0, 0.0, *surface["dimensions_m"]]
        claim = surface.get("artifact_wall_claim_uv_m")
        accepted = surface["accepted"]
        for item in accepted:
            rect = item["rect_uv_m"]
            if not rect_inside(rect, wall):
                raise ValueError(f"{item['request_id']} leaves its wall")
            if claim and rect_overlap(rect, claim):
                raise ValueError(f"{item['request_id']} overlaps artifact wall claim")
            for other in accepted:
                if other is not item and rect_overlap(rect, other["rect_uv_m"]):
                    raise ValueError(f"accepted props overlap in {surface['bay']}")
            if item["interactive"]:
                v = item["origin_uv_m"][1]
                if not 0.75 <= v <= 1.35:
                    raise ValueError(f"{item['request_id']} is unreachable")

        ax, az = surface["runtime_anchor_cell"]
        token = str(layers["interactables"][az][ax])
        if accepted:
            if not token.startswith(f"cluster:{surface['cluster']}:0"):
                raise ValueError(f"missing cluster token for {surface['bay']}")
            if layers["structure"][az][ax] not in ("1", "2"):
                raise ValueError(f"cluster anchor lacks floor in {surface['bay']}")
        elif token.strip():
            raise ValueError(f"rejected surface emitted a runtime token in {surface['bay']}")

    protected = [s for s in surfaces if s["principal_wall_archetype"] == "protected_artifact"]
    for surface in protected:
        rejected_monitor = any(
            item["role"] == "map_monitor"
            and "artifact_contract_protects_the_full_environment" in item["reasons"]
            for item in surface["rejected"]
        )
        if not rejected_monitor:
            raise ValueError(f"{surface['bay']} must explicitly reject its requested monitor")
    if len(clusters) != len(surfaces):
        raise ValueError("every principal wall should compile a runtime cluster")

    for surface in surfaces:
        accepted_tokens = {item["token"] for item in surface["accepted"]}
        if not {"exit_sign", "fire_extinguisher"}.issubset(accepted_tokens):
            raise ValueError(f"{surface['bay']} lacks its entrance safety pair")
        for item in surface["accepted"]:
            if item["requested_band"] != "feature_field" and rect_overlap(
                item["rect_uv_m"], surface["feature_field_uv_m"]
            ):
                raise ValueError(f"support prop entered feature field in {surface['bay']}")
            if item["mounting"] == "floor_against_wall" and item["rect_uv_m"][1] != 0.0:
                raise ValueError(f"floor prop floats in {surface['bay']}")

    # The three-metre public spine remains a hard architectural invariant.
    assignments = info["metadata"]["placement_overlay"]
    last_partition = int(assignments[-1]["bay_rows"][1]) + 1
    for z in range(last_partition + 1):
        for x in range(17, 20):
            if layers["structure"][z][x] != "1":
                raise ValueError(f"clear spine blocked at ({x},{z})")
            if str(layers["interactables"][z][x]).strip():
                raise ValueError(f"prop entered clear spine at ({x},{z})")


def render_wall_elevations(map_data: dict[str, Any], out_path: Path) -> None:
    surfaces = map_data["map_info"]["metadata"]["wall_surface_contracts"]
    scale = 76
    margin = 52
    panel_h = 410
    columns = 2 if len(surfaces) > 3 else 1
    cell_w = max(int(surface["dimensions_m"][0] * scale) for surface in surfaces) + 2 * margin + 280
    rows = (len(surfaces) + columns - 1) // columns
    canvas_w = cell_w * columns
    image = Image.new("RGB", (canvas_w, panel_h * rows + 40), "#10141c")
    draw = ImageDraw.Draw(image, "RGBA")
    font = ImageFont.load_default()
    colors = {
        "feature": "#31506b",
        "rail": "#624b2e",
        "claim": "#983f68",
        "accepted": "#54c992",
        "rejected": "#ef6b5d",
    }

    def box(rect: list[float], x0: int, floor_y: int) -> tuple[int, int, int, int]:
        return (
            int(x0 + rect[0] * scale),
            int(floor_y - rect[3] * scale),
            int(x0 + rect[2] * scale),
            int(floor_y - rect[1] * scale),
        )

    for index, surface in enumerate(surfaces):
        row = index // columns
        column = index % columns
        top = 36 + row * panel_h
        x0 = column * cell_w + margin
        floor_y = top + 332
        width_m, height_m = surface["dimensions_m"]
        wall_box = (x0, floor_y - int(height_m * scale), x0 + int(width_m * scale), floor_y)
        draw.rectangle(wall_box, fill="#d9d0bd", outline="#f2eadc", width=2)
        for grid_u in range(int(width_m) + 1):
            gx = x0 + grid_u * scale
            draw.line((gx, wall_box[1], gx, wall_box[3]), fill="#736f68" + "55", width=1)
        for grid_v in range(int(height_m) + 1):
            gy = floor_y - grid_v * scale
            draw.line((wall_box[0], gy, wall_box[2], gy), fill="#736f68" + "55", width=1)
        draw.rectangle(box(surface["feature_field_uv_m"], x0, floor_y), fill=colors["feature"] + "5a", outline=colors["feature"], width=2)
        for rail in surface["prop_rails_uv_m"]:
            draw.rectangle(box(rail, x0, floor_y), fill=colors["rail"] + "62", outline=colors["rail"], width=2)
        if surface.get("artifact_wall_claim_uv_m"):
            draw.rectangle(box(surface["artifact_wall_claim_uv_m"], x0, floor_y), fill=colors["claim"] + "78", outline=colors["claim"], width=3)
        for item in surface["accepted"]:
            b = box(item["rect_uv_m"], x0, floor_y)
            draw.rectangle(b, fill=colors["accepted"] + "b8", outline="#d9ffe9", width=2)
            draw.text((b[0] + 4, b[1] + 4), item["token"], fill="#08150f", font=font)
        for item in surface["rejected"]:
            b = box(item["rect_uv_m"], x0, floor_y)
            draw.rectangle(b, outline=colors["rejected"], width=3)
            draw.line((b[0], b[1], b[2], b[3]), fill=colors["rejected"], width=2)
            draw.line((b[0], b[3], b[2], b[1]), fill=colors["rejected"], width=2)

        for anchor_name, anchor in surface["semantic_anchors_uv_m"].items():
            ax = int(x0 + float(anchor[0]) * scale)
            ay = int(floor_y - float(anchor[1]) * scale)
            draw.ellipse((ax - 4, ay - 4, ax + 4, ay + 4), fill="#f6c453", outline="#181818")
            if anchor_name in ("entrance_exit", "left_corner"):
                label_x = min(max(ax + 6, wall_box[0] + 4), wall_box[2] - 88)
                draw.text((label_x, ay - 14), anchor_name.replace("_", " "), fill="#5b4410", font=font)

        draw.text((x0, top - 18), f"{surface['bay'].upper()} / {surface['display_name'].upper()}", fill="#f2eadc", font=font)
        draw.text((x0, floor_y + 12), f"{int(width_m)} m wall / 1 m u-v grid / yellow = semantic anchor", fill="#aeb8c5", font=font)
        panel_x = x0 + int(width_m * scale) + 24
        draw.text((panel_x, top), surface["disposition"].replace("_", " ").upper(), fill="#f2eadc", font=font)
        draw.text((panel_x, top + 28), f"accepted: {len(surface['accepted'])}", fill=colors["accepted"], font=font)
        draw.text((panel_x, top + 46), f"rejected: {len(surface['rejected'])}", fill=colors["rejected"], font=font)
        y = top + 78
        for item in surface["accepted"]:
            draw.text((panel_x, y), f"+ {item['request_id']}", fill="#dbe1e9", font=font)
            y += 18
        for item in surface["rejected"]:
            draw.text((panel_x, y), f"- {item['request_id']}", fill="#dbe1e9", font=font)
            y += 18
            for reason in item["reasons"]:
                draw.text((panel_x + 12, y), reason.replace("_", " "), fill="#aeb8c5", font=font)
                y += 18
    out_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(out_path)


def write_docs(out_dir: Path, map_data: dict[str, Any]) -> None:
    metadata = map_data["map_info"]["metadata"]
    surfaces = metadata["wall_surface_contracts"]
    rows = []
    for surface in surfaces:
        accepted = ", ".join(item["token"] for item in surface["accepted"]) or "none"
        rejected = "; ".join(
            f"{item['token']} ({', '.join(item['reasons'])})" for item in surface["rejected"]
        ) or "none"
        rows.append(
            f"| {surface['bay']} | `{surface['artifact']}` | {surface['disposition']} | {accepted} | {rejected} |"
        )
    table = "\n".join(rows)
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "blurb.md").write_text(
        "I entered ten rooms and noticed that the safety objects knew the exits, the boxes knew the corners, "
        "and the middle of each wall waited for the exhibition rather than begging to be filled.\n",
        encoding="utf-8",
    )
    (out_dir / "summary.md").write_text(
        f"""# Uffizi Principal-Wall Prop Pilot

This pass keeps the 21 x 92 m Uffizi cohort and all ten artifact footprints unchanged. It applies a self-sufficient semantic wall contract to every bay and compiles accepted placements into ordinary runtime clusters.

| Bay | Artifact | Wall disposition | Accepted | Rejected |
|---|---|---|---|---|
{table}

Feature walls reserve their centres for the current map's book monitor. Lambda Slider and Shannon Entropy Meter own 3 x 3 m central wall claims, so support and safety remain on their rails. Platonic Solids is the ideal complete context: a book monitor occupies the centre, material crates sit in the left floor corner, and the exit sign and extinguisher share the right threshold without overlapping. Gradient Descent and Neural Network are environmental: their requested monitors are refused, but mandatory life-safety props remain at the entrance edge.
""",
        encoding="utf-8",
    )
    (out_dir / "technical.md").write_text(
        """# Prop Placement Technical Contract

The compiler models every principal wall with orientation-independent `u` and `v`: `u` runs horizontally along the wall and maps to world x or z; `v` always maps to world y from floor to ceiling. The reusable prop catalogue and semantic rules live in `commons/data/museum_prop_placement_rules.json`.

Hard gates run in this order: wall bounds, artifact/environment ownership, requested wall band, central feature-field protection, artifact wall-claim overlap, interactive reach height, semantic-anchor distance, grounding, and prop-to-prop overlap. Life safety is allowed at entrance side rails even when the artifact protects the central field. Accepted placements compile to `commons/data/curated_walls/clusters/*.json`; rejected placements remain evidence in map metadata and never become runtime tokens.

Cluster anchors sit on x=16, the existing one-metre display band. Wall pieces use exact local metre offsets and the `wall` flag, so the runtime resolver preserves their height and does not auto-ground them. The x=17..19 public spine remains empty.

```powershell
python tools\build_uffizi_prop_placement_pilot.py
python tools\map_pathfinder.py check Museum_AAA_Uffizi_Prop_Pilot
```
""",
        encoding="utf-8",
    )
    (out_dir / "critical.md").write_text(
        """# A Wall Is Not Spare Space

The middle of a museum wall is often treated as neutral territory. Here it is an explicitly owned field. Sometimes the current artifact claims it; sometimes it becomes the book's monitor; sometimes an environmental work makes the distinction between object and wall collapse.

The rejected Neural Network caption is therefore not missing content. It is the solver recognizing that another label would reduce the work to an object inside a room when the contract says the room is already part of the work. Restraint is represented as data, rendered in the elevation, and enforced at runtime by emitting nothing.
""",
        encoding="utf-8",
    )
    (out_dir / "prop_negotiation_report.md").write_text(
        f"""# Principal-Wall Prop Negotiation Report

## Rules used

- Wall centre: 20-80% width, reserved for artifact claims or book/feature content.
- Side rails: 0-18% and 82-100% width; support props live here.
- Exit signs: upper side rail, within 1.25 m horizontally of an entrance/exit anchor.
- Fire extinguishers: grounded in the low side rail, within 1.25 m of an exit.
- Material boxes: grounded in a corner, within 0.75 m of its corner anchor.
- Interactive controls: centre height 0.75-1.35 m.
- Accepted rectangles may not overlap one another.

## Decisions

| Bay | Artifact | Disposition | Accepted | Rejected |
|---|---|---|---|---|
{table}

## Runtime result

- Accepted props: {metadata['prop_placement_summary']['accepted_props']}
- Rejected requests: {metadata['prop_placement_summary']['rejected_props']}
- Compiled clusters: {metadata['prop_placement_summary']['runtime_clusters']}
- New floor area: 0 m2
- Public spine consumed: 0 m
""",
        encoding="utf-8",
    )


def write_sequence(map_name: str) -> None:
    sequence = {
        "sequences": {
            "museum_aaa_uffizi_prop_pilot": {
                "name": "Museum AAA: Uffizi Principal-Wall Prop Pilot",
                "truth": "A wall is a negotiated surface, not spare space.",
                "qfep_term": "F<->E",
                "qfep_connection": "Prop density becomes a constrained response to artifact and architectural claims.",
                "description": "Ten principal walls apply semantic exit, corner, feature, wall-hero, and refusal rules.",
                "layer": "integration",
                "prerequisites": [],
                "unlocks": [],
                "difficulty": "intermediate",
                "estimated_time": "12-18 minutes",
                "learning_objectives": [
                    "Read wall surfaces as one-metre u-v contracts",
                    "Place props by semantic exit and corner anchors",
                    "Distinguish a protected feature field from support rails",
                    "Treat refusal as a valid placement result",
                ],
                "content": [f"{map_name}: ten-bay artifact-aware wall prop negotiation"],
                "maps": [map_name],
                "return_to": "lab",
            }
        }
    }
    path = MAPS_DIR / "sequences" / "museum_aaa_uffizi_prop_pilot.json"
    path.write_text(compact_map_json._ser(sequence, 0) + "\n", encoding="utf-8")


def write_outputs(map_name: str, map_data: dict[str, Any], clusters: dict[str, dict[str, Any]]) -> Path:
    out_dir = MAPS_DIR / map_name
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "map_data.json").write_text(
        compact_map_json._ser(map_data, 0) + "\n", encoding="utf-8"
    )
    plan = {
        "schema": "adaresearch.wall_placement_plan.v1",
        "map": map_name,
        "rules": read_json(PROP_RULES),
        "ideal_context": map_data["map_info"]["metadata"]["ideal_prop_context"],
        "principal_walls": map_data["map_info"]["metadata"]["wall_surface_contracts"],
    }
    (out_dir / "wall_placement_plan.json").write_text(
        compact_map_json._ser(plan, 0) + "\n", encoding="utf-8"
    )
    CLUSTERS_DIR.mkdir(parents=True, exist_ok=True)
    for name, cluster in clusters.items():
        (CLUSTERS_DIR / f"{name}.json").write_text(
            compact_map_json._ser(cluster, 0) + "\n", encoding="utf-8"
        )
    render_wall_elevations(map_data, out_dir / "wall_elevation_plan.png")
    write_docs(out_dir, map_data)
    write_sequence(map_name)
    return out_dir


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--name", default=DEFAULT_NAME)
    args = parser.parse_args()
    map_data, clusters = build_map(args.name)
    validate(map_data, clusters)
    out_dir = write_outputs(args.name, map_data, clusters)
    summary = map_data["map_info"]["metadata"]["prop_placement_summary"]
    print(f"wrote {out_dir.relative_to(REPO)}")
    print(f"accepted props: {summary['accepted_props']}")
    print(f"rejected requests: {summary['rejected_props']}")
    print(f"runtime clusters: {summary['runtime_clusters']}")
    print("public spine: unchanged")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
