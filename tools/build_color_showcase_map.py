#!/usr/bin/env python3
"""
build_color_showcase_map.py
============================

Builds Color_Showcase — a small map placing 5 color-stacks-gallery
findings on the front row and 4 color-furniture-gallery findings on
the back row. All loaded from baked PackedScenes via prebaked_loader.

Walking south to north: complementary pair (red/green) → triadic
primary → value steps → simultaneous contrast → monochrome blue.
Back row: Vignelli coffee table → Coco pendant → Becker wall grid →
warm-glow lamp.

The point: show that the color galleries become inhabitable maps in
one bake-and-place pass.
"""

from __future__ import annotations
import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))
from measure_artifact_aabbs import _find_godot          # noqa: E402
from promote_to_artifact import resolve, make_token     # noqa: E402

ENC = REPO.parent / "ada_encyclopedia"
MAP_NAME = "Color_Showcase"
MAP_DIR = REPO / "commons" / "maps" / MAP_NAME

STACKS = [
    ("color-stacks-gallery", "stack_complementary_red_green",   "Red/Green complement"),
    ("color-stacks-gallery", "stack_triadic_primary",           "Bauhaus triad"),
    ("color-stacks-gallery", "stack_value_steps_warm",          "Warm value scale"),
    ("color-stacks-gallery", "stack_simultaneous_contrast",     "Simultaneous contrast"),
    ("color-stacks-gallery", "stack_monochrome_blue",           "Monochrome blue"),
]

FURNITURE = [
    ("color-furniture-gallery", "furniture_vignelli_metafora_primary",  "Vignelli table"),
    ("color-furniture-gallery", "furniture_coco_pendant_warm",          "Coco pendant"),
    ("color-furniture-gallery", "furniture_becker_utensilo_bauhaus",    "Becker wall grid"),
    ("color-furniture-gallery", "furniture_lamp_warm_glow",             "Warm-glow lamp"),
]


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--no-godot", action="store_true")
    args = ap.parse_args()

    rows, cols = 14, 22
    structure = [["1" for _ in range(cols)] for _ in range(rows)]
    utilities = [[" " for _ in range(cols)] for _ in range(rows)]
    interactables = [[" " for _ in range(cols)] for _ in range(rows)]
    utilities[0][cols // 2] = "sp"
    utilities[rows - 1][cols // 2] = "t"

    # primitive_stack configs use base_scale ~0.25 — too small at map scale.
    # Inflate via prebaked_loader's scale parameter so they read like real
    # furniture/totems instead of tabletop maquettes.
    BIG_SCALE = 5.0

    # Front row: stacks at z=4, columns 2,6,10,14,18
    for i, (gallery, eid, label) in enumerate(STACKS):
        c = 2 + i * 4
        artifact, params, mode = resolve(gallery, eid)
        if artifact == "prebaked_loader":
            params["scale"] = BIG_SCALE
        interactables[4][c] = make_token(artifact, params)
        print(f"  ({4:2d},{c:2d}) {label:30s} -> {mode:10s} via {artifact}  x{BIG_SCALE}")

    # Back row: furniture at z=9, columns 3,8,13,18
    for i, (gallery, eid, label) in enumerate(FURNITURE):
        c = 3 + i * 5
        artifact, params, mode = resolve(gallery, eid)
        if artifact == "prebaked_loader":
            params["scale"] = BIG_SCALE
        interactables[9][c] = make_token(artifact, params)
        print(f"  ({9:2d},{c:2d}) {label:30s} -> {mode:10s} via {artifact}  x{BIG_SCALE}")

    md = {
        "map_info": {
            "name": MAP_NAME, "lookup_name": MAP_NAME,
            "description": (
                "Color_Showcase: 5 stacks + 4 furniture findings from the "
                "color-stacks and color-furniture galleries. Walk south to "
                "north — the front row teaches color principles abstractly "
                "(complementary, triadic, value, simultaneous contrast, "
                "monochrome). The back row teaches the same principles "
                "through furniture forms (Vignelli, Coco, Becker, lamp)."
            ),
            "format": "json", "version": "1.0",
            "dimensions": {"width": cols, "depth": rows, "max_height": 5},
            "metadata": {
                "source": "build_color_showcase_map.py",
                "stack_count": len(STACKS),
                "furniture_count": len(FURNITURE),
            },
        },
        "layers": {"structure": structure, "utilities": utilities, "interactables": interactables},
        "settings": {
            "cube_size": 1, "gutter": 0, "show_grid": True,
            "background": {"type": "sky", "color": [0.07, 0.08, 0.12]},
            "grid_animation": {"enabled": False},
        },
        "utility_definitions": {"sp": {"type": "spawn"}, "t": {"type": "teleporter"}},
    }
    MAP_DIR.mkdir(parents=True, exist_ok=True)
    (MAP_DIR / "map_data.json").write_text(
        json.dumps(md, indent="\t", ensure_ascii=False) + "\n", encoding="utf-8")
    (MAP_DIR / "blurb.md").write_text(
        f"# {MAP_NAME}\n\n9 color findings (5 stacks + 4 furniture) baked "
        f"from /dna and placed via prebaked_loader. Walk the rows.\n",
        encoding="utf-8")
    print(f"\nWrote: commons/maps/{MAP_NAME}/")
    print(f"Three.js: http://localhost:3003/map-3d/{MAP_NAME}")

    if args.no_godot: return
    godot = _find_godot()
    if not godot:
        print("No Godot — skipping render.")
        return

    # Set runtime flags so artifacts spawn (not in clean-grid capture mode).
    flags_path = REPO / "ada_run" / "runtime_flags.json"
    flags_path.parent.mkdir(parents=True, exist_ok=True)
    flags_path.write_text(json.dumps({
        "biome_enabled": False,
        "artifacts_enabled": True,
        "_capture_active": True,
        "_note": "color showcase capture",
    }, indent=2) + "\n", encoding="utf-8")

    cap_out = ENC / "public" / "captures" / "maps"
    cap_out.mkdir(parents=True, exist_ok=True)
    cmd = [
        godot, "--path", str(REPO), "--xr-mode", "off", "--no-window",
        "--script", "res://commons/testing/capture_multi_angle.gd", "--",
        "--mode=map", f"--target={MAP_NAME}",
        f"--out={cap_out.as_posix()}", "--wait=4",
    ]
    print("\nCapturing in Godot...")
    proc = subprocess.run(cmd, cwd=str(REPO), timeout=180, capture_output=True)
    if proc.returncode != 0:
        print(f"FAIL rc={proc.returncode}")
        if proc.stderr:
            print(proc.stderr.decode("utf-8", errors="ignore")[-400:])
        return
    pngs = sorted((cap_out / MAP_NAME).glob("*.png"))
    print(f"\nRendered {len(pngs)} angles:")
    for p in pngs:
        sz = p.stat().st_size
        print(f"  {sz//1024:4d} KB  http://localhost:3003/captures/maps/{MAP_NAME}/{p.name}")


if __name__ == "__main__":
    main()
