#!/usr/bin/env python3
"""
build_canon_conveyor_map.py
============================

Showcase map for the upgraded conveyor belt: three conveyor stations,
each pre-loaded with a different modern-canon composition.
  Front  : Mondrian (De Stijl)
  Middle : Rietveld Red/Blue Chair
  Back   : Mies Barcelona Pavilion

Walk up to a station, watch the colored ghost stack, grab the matching
piece off the input belt, snap it into its slot. When all slots fill,
the assembled totem rolls down the output belt.
"""

from __future__ import annotations
import argparse
import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))
from measure_artifact_aabbs import _find_godot          # noqa: E402
from promote_to_artifact import make_token              # noqa: E402

ENC = REPO.parent / "ada_encyclopedia"
MAP_NAME = "Canon_Conveyor_Showcase"
MAP_DIR = REPO / "commons" / "maps" / MAP_NAME

STATIONS = [
    # (z, palette_source, label) — three sandbox conveyors drawing primitives
    # from different palettes. The player composes freely from each stream.
    (3,  "compositions",         "Sandbox · all canon"),
    (7,  "compositions",         "Sandbox · all canon"),
    (11, "rainbow",              "Sandbox · rainbow"),
]


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--no-godot", action="store_true")
    args = ap.parse_args()

    rows, cols = 14, 16
    structure = [["1" for _ in range(cols)] for _ in range(rows)]
    utilities = [[" " for _ in range(cols)] for _ in range(rows)]
    interactables = [[" " for _ in range(cols)] for _ in range(rows)]
    utilities[0][cols // 2] = "sp"
    utilities[rows - 1][cols // 2] = "t"

    for z, palette, label in STATIONS:
        c = cols // 2
        token = make_token("assembly_line_puzzle", {
            "sandbox": True,
            "palette": palette,
        })
        interactables[z][c] = token
        print(f"  z={z:2d} c={c:2d}  {label:24s} -> assembly_line_puzzle sandbox palette={palette}")

        # Drop a composition_platform two cells west of each conveyor so the
        # player can stack pieces on it and press the button to save the
        # arrangement back into the gallery pipeline.
        platform_token = make_token("composition_platform", {
            "label_prefix": f"Capture · {palette}",
        })
        interactables[z][c - 3] = platform_token
        print(f"  z={z:2d} c={c-3:2d}  Capture platform        -> composition_platform")

    md = {
        "map_info": {
            "name": MAP_NAME, "lookup_name": MAP_NAME,
            "description": (
                "Canon Conveyor Showcase — three conveyor belts, each "
                "configured to build a different modern-canon totem from "
                "primitive_stack pieces. Mondrian / Rietveld / Mies. Snap "
                "each colored primitive into its ghosted slot."
            ),
            "format": "json", "version": "1.0",
            "dimensions": {"width": cols, "depth": rows, "max_height": 5},
            "metadata": {"source": "build_canon_conveyor_map.py", "stations": len(STATIONS)},
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
        f"# {MAP_NAME}\n\nThree upgraded conveyors, each building a "
        f"different modern-canon totem.\n", encoding="utf-8")
    print(f"\nWrote: commons/maps/{MAP_NAME}/")
    print(f"Three.js: http://localhost:3003/map-3d/{MAP_NAME}\n")

    if args.no_godot: return

    godot = _find_godot()
    if not godot:
        print("No Godot — skipping render.")
        return

    flags_path = REPO / "ada_run" / "runtime_flags.json"
    flags_path.parent.mkdir(parents=True, exist_ok=True)
    flags_path.write_text(json.dumps({
        "biome_enabled": False,
        "artifacts_enabled": True,
        "_capture_active": True,
    }, indent=2) + "\n", encoding="utf-8")

    cap_out = ENC / "public" / "captures" / "maps"
    cap_out.mkdir(parents=True, exist_ok=True)
    cmd = [
        godot, "--path", str(REPO), "--xr-mode", "off", "--no-window",
        "--script", "res://commons/testing/capture_multi_angle.gd", "--",
        "--mode=map", f"--target={MAP_NAME}",
        f"--out={cap_out.as_posix()}", "--wait=6",
    ]
    print("Capturing in Godot...")
    proc = subprocess.run(cmd, cwd=str(REPO), timeout=240, capture_output=True)
    if proc.returncode != 0:
        print(f"FAIL rc={proc.returncode}")
        if proc.stderr: print(proc.stderr.decode("utf-8", errors="ignore")[-400:])
        return
    pngs = sorted((cap_out / MAP_NAME).glob("*.png"))
    print(f"\nRendered {len(pngs)} angles:")
    for p in pngs:
        print(f"  {p.stat().st_size//1024:5d} KB  http://localhost:3003/captures/maps/{MAP_NAME}/{p.name}")


if __name__ == "__main__":
    main()
