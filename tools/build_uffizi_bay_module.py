#!/usr/bin/env python3
"""Build and validate the certified one-metre Uffizi bay and seam test."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SPEC_PATH = ROOT / "commons/data/museum_module_kit.json"
CLUSTERS = ROOT / "commons/data/curated_walls/clusters"
MAPS = ROOT / "commons/maps"
MODULE = "uffizi_bay_v1"
GODOT_REPORT = ROOT / "ada_run/museum_aaa_pass/uffizi_bay_godot_validation.json"
ISOLATED_CAPTURE = ROOT / "ada_run/museum_aaa_pass/uffizi_bay_certified_capture_v2/Museum_AAA_Uffizi_Bay_V1/capture_report.json"
SEAM_CAPTURE = ROOT / "ada_run/museum_aaa_pass/uffizi_bay_seam_capture/Museum_AAA_Uffizi_Bay_Seam_Test/capture_report.json"


def load_spec() -> dict:
    return json.loads(SPEC_PATH.read_text(encoding="utf-8"))


def certify(spec: dict) -> dict:
    module = spec["modules"][MODULE]
    length, height, depth = module["cells"]
    west = module["sockets"]["west"]
    east = module["sockets"]["east"]
    checks = {
        "grid_is_one_metre": spec["grid_m"] == 1.0,
        "dimensions_are_integer_cells": all(isinstance(v, int) for v in (length, height, depth)),
        "floor_tile_count": module["parts"]["floor_tile"]["count"] == length * depth,
        "wall_cell_count": module["parts"]["wall_cell"]["count"] == length * 2,
        "sockets_are_opposed": west["port"] == east["port"] and west["facing"] != east["facing"],
        "socket_span_matches_module": east["at_m"][0] - west["at_m"][0] == length,
        "feature_field_is_central": module["feature_field"]["keep_clear"] and module["feature_field"]["width_m"] == 4.0,
        "props_are_peripheral": all(abs(sum(zone["x_m"]) / 2.0) >= 2.25 for zone in module["prop_zones"]),
        "budget_declared": set(module["budget"]) == {"mesh_instances_max", "lights_max", "collision_shapes"},
    }
    return {"schema": spec["schema"], "module": MODULE, "passed": all(checks.values()), "checks": checks}


def runtime_evidence() -> dict:
    def report_passed(path: Path) -> bool:
        if not path.exists():
            return False
        try:
            return bool(json.loads(path.read_text(encoding="utf-8")).get("passed"))
        except (OSError, json.JSONDecodeError):
            return False

    def capture_passed(path: Path) -> bool:
        if not path.exists():
            return False
        try:
            report = json.loads(path.read_text(encoding="utf-8"))
            return report.get("saved_count") == 5 and report.get("angles") == 5
        except (OSError, json.JSONDecodeError):
            return False

    checks = {
        "godot_load_and_part_counts": report_passed(GODOT_REPORT),
        "isolated_render_5_of_5": capture_passed(ISOLATED_CAPTURE),
        "two_bay_render_5_of_5": capture_passed(SEAM_CAPTURE),
    }
    return {"passed": all(checks.values()), "checks": checks,
            "godot_report": str(GODOT_REPORT.relative_to(ROOT)).replace("\\", "/"),
            "isolated_capture": str(ISOLATED_CAPTURE.parent.relative_to(ROOT)).replace("\\", "/"),
            "seam_capture": str(SEAM_CAPTURE.parent.relative_to(ROOT)).replace("\\", "/")}


def module_config(spec: dict) -> dict:
    length, height, depth = spec["modules"][MODULE]["cells"]
    return {"length_cells": length, "depth_cells": depth, "wall_height": height,
            "socket_width": 3, "finish": "uffizi_stone", "enable_lights": True}


def cluster_single(spec: dict) -> dict:
    return {
        "name": "uffizi_bay_v1_origin",
        "source": "tools/build_uffizi_bay_module.py",
        "contract": {"grid_m": 1.0, "module": MODULE, "bay_count": 1, "feature_field": "north_central_4m"},
        "pieces": [
            {"token": "museum_uffizi_bay_module", "x": -0.5, "y": 0, "z": -0.5, "wall": True,
             "config": module_config(spec)},
            {"token": "station_plinth", "x": -0.5, "y": 0.08, "z": -1.85, "wall": False,
             "config": {"width_cells": 1, "depth_cells": 1, "top_height": 1.0, "caption_text": "POINT ZERO"}},
            {"token": "origin", "x": -0.5, "y": 1.08, "z": -1.85, "wall": False,
             "config": {"beam_height": 0.6, "octahedron_size": 0.08, "rotation_speed": 0.18}},
            {"token": "exit_sign", "x": 2.75, "y": 3.2, "z": -4.22, "wall": True,
             "config": {"text": "EAST GALLERY", "mounting": "above_threshold"}},
            {"token": "fire_extinguisher", "x": -3.75, "y": 0.08, "z": -4.05, "wall": False,
             "config": {"support": "floor_bracket", "label_text": "FIRE"}},
        ],
    }


def cluster_seam(spec: dict) -> dict:
    length = spec["modules"][MODULE]["cells"][0]
    pieces = []
    for index, x in enumerate((-length / 2 - 0.5, length / 2 - 0.5), start=1):
        config = module_config(spec)
        config["show_socket_markers"] = False
        pieces.append({"token": "museum_uffizi_bay_module", "x": x, "y": 0, "z": -0.5, "wall": True,
                       "config": config})
        pieces.append({"token": "station_floorline", "x": x, "y": 0.09, "z": -0.5, "wall": True,
                       "config": {"length_cells": length, "style": "line", "caption_text": f"BAY {index}"}})
    return {
        "name": "uffizi_bay_v1_seam_pair",
        "source": "tools/build_uffizi_bay_module.py",
        "contract": {"grid_m": 1.0, "module": MODULE, "bay_count": 2, "join_x_m": -0.5,
                     "socket": "gallery_spine_3m", "expected_gap_m": 0},
        "pieces": pieces,
    }


def blank_layer(width: int, depth: int, fill: str = " ") -> list[list[str]]:
    return [[fill for _ in range(width)] for _ in range(depth)]


def build_map(name: str, cluster: str, width: int, depth: int, bay_count: int) -> dict:
    structure = blank_layer(width, depth, "0")
    utilities = blank_layer(width, depth)
    interactables = blank_layer(width, depth)
    for row in range(depth):
        for col in range(width):
            structure[row][col] = "1"
    anchor_row, anchor_col = depth // 2, width // 2
    utilities[1][1] = "s"
    utilities[1][width - 2] = "t"
    structure[1][width - 2] = "0"
    interactables[anchor_row][anchor_col] = f"cluster:{cluster}:0"
    return {
        "map_info": {
            "lookup_name": name, "name": name,
            "description": "Certified one-metre Uffizi bay module." if bay_count == 1 else "Two certified Uffizi bays joined socket-to-socket with zero seam gap.",
            "version": "1.0-module-certification", "format": "ada-3layer-v1+museum-module-contract",
            "dimensions": {"width": width, "depth": depth, "max_height": 6},
            "metadata": {"module_kit": "ada-museum-module-kit-v1", "module": MODULE,
                         "grid_module_m": 1.0, "bay_count": bay_count,
                         "certification_role": "isolated" if bay_count == 1 else "two_bay_seam"},
        },
        "utility_definitions": {
            "s": {"type": "spawn", "properties": {"height": 1.5}},
            "t": {"type": "teleporter", "name": "Next", "description": "Continue", "properties": {"action": "next_in_sequence"}},
        },
        "settings": {"cube_size": 1.0, "gutter": 0.0, "show_grid": False, "enable_physics": True,
                     "disable_biome": True, "background": "dark"},
        "environment": {"background_color": [0.025, 0.028, 0.032], "ambient_color": [0.78, 0.72, 0.62], "ambient_energy": 0.55},
        "lighting": {"ambient_color": [0.78, 0.72, 0.62], "ambient_energy": 0.55,
                     "directional_light": {"enabled": True, "direction": [-0.25, -0.9, -0.2], "color": [1, 0.9, 0.72], "energy": 1.1}},
        "layers": {"structure": structure, "utilities": utilities, "interactables": interactables},
    }


def write_docs(path: Path, seam: bool) -> None:
    title = "Two-Bay Uffizi Seam Test" if seam else "Certified Uffizi Bay v1"
    path.joinpath("blurb.md").write_text(f"# {title}\n\nA finished architectural acceptance room built from a one-metre museum kit.\n", encoding="utf-8")
    path.joinpath("summary.md").write_text(
        "# Summary\n\nThe bay protects a four-metre feature wall, keeps props peripheral, and exposes matching three-metre west/east sockets.\n",
        encoding="utf-8")
    path.joinpath("technical.md").write_text(
        "# Technical\n\nThe contract is `commons/data/museum_module_kit.json`. Floor, wall, beam and skylight counts are derived from integer cells. The seam test places bay centres exactly 8 m apart.\n",
        encoding="utf-8")
    path.joinpath("critical.md").write_text(
        "# Critical\n\nThe module makes the museum's defaults explicit: what receives the centre, what is pushed to the edge, and which dimensions are allowed to repeat. Endlessness is permitted only after the joint is tested.\n",
        encoding="utf-8")


def write_outputs(spec: dict, report: dict) -> None:
    CLUSTERS.mkdir(parents=True, exist_ok=True)
    clusters = [cluster_single(spec), cluster_seam(spec)]
    for cluster in clusters:
        CLUSTERS.joinpath(cluster["name"] + ".json").write_text(json.dumps(cluster, separators=(",", ":")) + "\n", encoding="utf-8")
    targets = [
        ("Museum_AAA_Uffizi_Bay_V1", clusters[0]["name"], 8, 8, 1, False),
        ("Museum_AAA_Uffizi_Bay_Seam_Test", clusters[1]["name"], 16, 8, 2, True),
    ]
    for name, cluster, width, depth, bays, seam in targets:
        path = MAPS / name
        path.mkdir(parents=True, exist_ok=True)
        path.joinpath("map_data.json").write_text(json.dumps(build_map(name, cluster, width, depth, bays), separators=(",", ":")) + "\n", encoding="utf-8")
        write_docs(path, seam)
    report_path = ROOT / "ada_run/museum_aaa_pass/uffizi_bay_module_certification.json"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=1) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    spec = load_spec()
    report = certify(spec)
    report["runtime"] = runtime_evidence()
    report["ready_for_endless"] = report["passed"] and report["runtime"]["passed"]
    print(json.dumps(report, indent=2))
    if args.write and report["passed"]:
        write_outputs(spec, report)
        print("wrote isolated bay + two-bay seam fixtures")
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
