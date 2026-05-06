#!/usr/bin/env python3
"""
build_turrell_walk_map.py
==========================

Builds Turrell_Walk — four full-scale Turrell rooms placed in a square
plan. The player spawns in the center and walks into each room:
  NW: Afrum (Blue) — saturated cube of light in a dark corner
  NE: Skyspace (Meeting palette) — orange room, blue sky aperture
  SW: Chromatic chamber (red+yellow) — Bridget's Bardo palette
  SE: Aten Reign rotunda — concentric rings overhead

Each room is a baked PackedScene (~20 KB) instantiated via
prebaked_loader. The bake captures full-fidelity geometry so map
opens are instant.

Steps:
  1. Stage the gallery configs into best_of/configs/
  2. Bake each via bake_artifact.gd → PackedScene
  3. Build the map with prebaked_loader tokens at room positions
  4. Capture multi-angle for the encyclopedia
"""

from __future__ import annotations
import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))
from measure_artifact_aabbs import _find_godot          # noqa: E402
from promote_to_artifact import resolve, make_token     # noqa: E402

ENC = REPO.parent / "ada_encyclopedia"
MAP_NAME = "Turrell_Walk"
MAP_DIR = REPO / "commons" / "maps" / MAP_NAME

BEST_OF_CONFIGS = REPO / "commons" / "generated" / "gallery_best_of" / "configs"
BEST_OF_SCENES  = REPO / "commons" / "generated" / "gallery_best_of" / "scenes"
BAKE_GD = "res://commons/testing/bake_artifact.gd"
WRAPPER = "res://commons/artifacts/chromatic_form_artifact/chromatic_form_artifact.tscn"

# Each room: (gallery, entry_id, label, grid_x, grid_z, label_text)
ROOMS = [
    ("turrell-spaces-gallery", "afrum_blue_corner",            "Afrum (Blue)",         5, 5),
    ("turrell-spaces-gallery", "skyspace_meeting_orange_sky",  "Skyspace (Meeting)",  18, 5),
    ("turrell-spaces-gallery", "chamber_red_yellow",           "Chamber (Red/Yellow)", 5, 18),
    ("turrell-spaces-gallery", "aten_reign_full_hsv",          "Aten Reign (HSV)",    18, 18),
]


def stage_configs() -> int:
    BEST_OF_CONFIGS.mkdir(parents=True, exist_ok=True)
    n = 0
    for gallery, entry_id, _, _, _ in ROOMS:
        src = ENC / "public" / gallery / f"{entry_id}.json"
        if not src.exists():
            print(f"  MISSING: {src}")
            continue
        dst = BEST_OF_CONFIGS / f"{gallery}__{entry_id}.json"
        shutil.copy2(src, dst)
        n += 1
    return n


def bake_all(godot: str, force: bool) -> int:
    BEST_OF_SCENES.mkdir(parents=True, exist_ok=True)
    ok = 0
    for gallery, entry_id, _, _, _ in ROOMS:
        out_path = BEST_OF_SCENES / f"{gallery}__{entry_id}.tscn"
        if out_path.exists() and not force:
            ok += 1
            continue
        params = {
            "config_path": f"res://commons/generated/gallery_best_of/configs/{gallery}__{entry_id}.json",
        }
        out_res = f"res://commons/generated/gallery_best_of/scenes/{gallery}__{entry_id}.tscn"
        cmd = [
            godot, "--path", str(REPO), "--xr-mode", "off", "--no-window",
            "--script", BAKE_GD, "--",
            f"--scene={WRAPPER}",
            f"--apply-config={json.dumps(params)}",
            f"--out={out_res}",
            "--wait=3",
        ]
        print(f"  bake  {gallery}__{entry_id} ...", end=" ", flush=True)
        try:
            proc = subprocess.run(cmd, cwd=str(REPO), timeout=120, capture_output=True)
        except subprocess.TimeoutExpired:
            print("TIMEOUT"); continue
        if proc.returncode != 0 or not out_path.exists():
            print(f"FAIL rc={proc.returncode}")
            if proc.stderr:
                print(f"    stderr: {proc.stderr.decode('utf-8', errors='ignore')[-200:]}")
            continue
        print(f"OK ({out_path.stat().st_size//1024} KB)")
        ok += 1
    return ok


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--no-godot", action="store_true")
    ap.add_argument("--no-bake",  action="store_true")
    ap.add_argument("--force",    action="store_true")
    args = ap.parse_args()

    print("Stage configs ...")
    n = stage_configs()
    print(f"  staged {n} configs\n")

    godot = _find_godot()
    if not godot:
        print("No Godot — set GODOT_EXE."); sys.exit(1)

    if not args.no_bake:
        print("Bake configs to .tscn ...")
        ok = bake_all(godot, args.force)
        print(f"  baked {ok}/{n}\n")

    # ── Build map ─────────────────────────────────────────────────
    rows, cols = 26, 26
    structure = [["1" for _ in range(cols)] for _ in range(rows)]
    utilities = [[" " for _ in range(cols)] for _ in range(rows)]
    interactables = [[" " for _ in range(cols)] for _ in range(rows)]

    # Spawn south-center, teleporter north-center
    utilities[0][cols // 2] = "sp"
    utilities[rows - 1][cols // 2] = "t"

    for gallery, entry_id, label, gx, gz in ROOMS:
        artifact, params, mode = resolve(gallery, entry_id)
        # Rooms are already at world scale (~5m) — no scale boost.
        interactables[gz][gx] = make_token(artifact, params)
        print(f"  ({gz:2d},{gx:2d})  {label:24s} -> {mode:8s} via {artifact}")

    md = {
        "map_info": {
            "name": MAP_NAME, "lookup_name": MAP_NAME,
            "description": (
                "Turrell Walk — four full-scale Turrell Boolean spaces in a "
                "square formation. Walk into the Afrum corner (blue cube of "
                "pure light), the Skyspace (orange room with blue sky "
                "aperture), the Chromatic Chamber (Bridget's Bardo palette), "
                "or stand under the Aten Reign rotunda overhead. Each room "
                "is a baked PackedScene; map opens instantly."
            ),
            "format": "json", "version": "1.0",
            "dimensions": {"width": cols, "depth": rows, "max_height": 5},
            "metadata": {"source": "build_turrell_walk_map.py", "rooms": len(ROOMS)},
        },
        "layers": {"structure": structure, "utilities": utilities, "interactables": interactables},
        "settings": {
            "cube_size": 1, "gutter": 0, "show_grid": True,
            "background": {"type": "sky", "color": [0.04, 0.04, 0.06]},
            "grid_animation": {"enabled": False},
        },
        "utility_definitions": {"sp": {"type": "spawn"}, "t": {"type": "teleporter"}},
    }
    MAP_DIR.mkdir(parents=True, exist_ok=True)
    (MAP_DIR / "map_data.json").write_text(
        json.dumps(md, indent="\t", ensure_ascii=False) + "\n", encoding="utf-8")
    (MAP_DIR / "blurb.md").write_text(
        f"# {MAP_NAME}\n\nFour Turrell Boolean spaces — Afrum, Skyspace, "
        f"Chromatic Chamber, Aten Reign — at full scale, baked from "
        f"/dna and placed via prebaked_loader.\n", encoding="utf-8")
    print(f"\nWrote: commons/maps/{MAP_NAME}/")
    print(f"Three.js: http://localhost:3003/map-3d/{MAP_NAME}\n")

    if args.no_godot: return

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
    print("Capturing in Godot ...")
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
