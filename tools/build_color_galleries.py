#!/usr/bin/env python3
"""
build_color_galleries.py
=========================

Generates two color-curriculum galleries by writing curated primitive_stack
configs and invoking the existing render pipeline:

  color-stacks-gallery    — vertical_stack totems tuned for the color
                            sequence's perception lessons. Hue-relationship
                            pairs, complementary contrasts, value studies.

  color-furniture-gallery — under_plate, pendant_thread, wall_grid
                            compositions reading as functional objects.
                            Vignelli coffee tables, Coco pendants, Becker
                            wall grids, Bauspiel-as-furniture.

Both galleries draw from the existing primitive_stack grammar; what's
curated is the SET of configs, not the renderer. Each entry gets:

  /<gallery>/<id>.json    config (DNA)
  /<gallery>/<id>.png     real Godot render
  /<gallery>/manifest.json roster
  /<gallery>/evals.json    empty starting curation file

Run:
    python tools/build_color_galleries.py             # render both
    python tools/build_color_galleries.py --dry       # show plan only
    python tools/build_color_galleries.py --gallery color-stacks-gallery
"""

from __future__ import annotations
import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))
from measure_artifact_aabbs import _find_godot          # noqa: E402

ENC = REPO.parent / "ada_encyclopedia"
RENDER_GD = "res://commons/testing/render_primitive_stack.gd"
STAGING_DIR = REPO / "commons" / "primitive_grammar" / "_staging"


# ── color-stacks-gallery ─────────────────────────────────────────
# Vertical totems exploring color principles: complementary pairs,
# triadic harmony, value steps, simultaneous contrast.

COLOR_STACKS = [
    {
        "id": "stack_complementary_red_green",
        "notes": "Itten complementary: Red <-> Green totem. Adjacent extremes intensify each other.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.25,
        "sequence": [
            {"shape": "cube",    "color": "#a02020", "scale": 1.4},
            {"shape": "sphere",  "color": "#2aa040", "scale": 1.2},
            {"shape": "cube",    "color": "#a02020", "scale": 1.0},
            {"shape": "sphere",  "color": "#2aa040", "scale": 0.8},
        ],
    },
    {
        "id": "stack_complementary_blue_orange",
        "notes": "Blue <-> Orange complementary. Color-temperature opposition: cool/warm at maximum.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.25,
        "sequence": [
            {"shape": "cuboid",  "color": "#1844a0", "scale": 1.3},
            {"shape": "cube",    "color": "#e87018", "scale": 1.1},
            {"shape": "cuboid",  "color": "#1844a0", "scale": 0.9},
        ],
    },
    {
        "id": "stack_complementary_yellow_violet",
        "notes": "Yellow <-> Violet — strongest value contrast, weakest hue-opposition. Light vs. heavy.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.25,
        "sequence": [
            {"shape": "sphere",  "color": "#6a30a0", "scale": 1.2},
            {"shape": "cube",    "color": "#f0d020", "scale": 1.4},
            {"shape": "sphere",  "color": "#6a30a0", "scale": 0.9},
        ],
    },
    {
        "id": "stack_triadic_primary",
        "notes": "Triadic harmony: red-yellow-blue at equal intervals on the wheel. Bauhaus primary.",
        "layout": "vertical_stack",
        "palette": "bauhaus",
        "base_scale": 0.25,
        "sequence": [
            {"shape": "cube",    "color": "#cc1f1f", "scale": 1.2},
            {"shape": "sphere",  "color": "#f0c020", "scale": 1.0},
            {"shape": "cuboid",  "color": "#1f4ecc", "scale": 1.3},
        ],
    },
    {
        "id": "stack_triadic_secondary",
        "notes": "Secondary triad: orange-green-violet. Same triadic spacing, calmer overall key.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.25,
        "sequence": [
            {"shape": "sphere",  "color": "#e87018", "scale": 1.2},
            {"shape": "cube",    "color": "#3aa060", "scale": 1.0},
            {"shape": "cuboid",  "color": "#6a30a0", "scale": 1.3},
        ],
    },
    {
        "id": "stack_value_steps_warm",
        "notes": "Five-step value scale, warm hue. Constant chroma, only value changes — the brightness ladder isolated.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.22,
        "sequence": [
            {"shape": "cube",    "color": "#3a1808", "scale": 1.1},
            {"shape": "cube",    "color": "#7a3a18", "scale": 1.0},
            {"shape": "cube",    "color": "#c06840", "scale": 0.9},
            {"shape": "cube",    "color": "#e8a878", "scale": 0.8},
            {"shape": "cube",    "color": "#f8d8b8", "scale": 0.7},
        ],
    },
    {
        "id": "stack_value_steps_cool",
        "notes": "Five-step value scale, cool hue. Mirror of the warm scale — pair them to feel temperature.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.22,
        "sequence": [
            {"shape": "cuboid",  "color": "#0a1830", "scale": 1.1},
            {"shape": "cuboid",  "color": "#1c3868", "scale": 1.0},
            {"shape": "cuboid",  "color": "#4070a8", "scale": 0.9},
            {"shape": "cuboid",  "color": "#80a8d0", "scale": 0.8},
            {"shape": "cuboid",  "color": "#c0d8ec", "scale": 0.7},
        ],
    },
    {
        "id": "stack_simultaneous_contrast",
        "notes": "Simultaneous contrast study: same gray sphere reads warm/cool against different surrounds. Three identical neutral cores in red/blue/yellow contexts.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.20,
        "sequence": [
            {"shape": "cube",    "color": "#a02020", "scale": 1.3},
            {"shape": "sphere",  "color": "#888888", "scale": 0.6},
            {"shape": "cube",    "color": "#1844a0", "scale": 1.3},
            {"shape": "sphere",  "color": "#888888", "scale": 0.6},
            {"shape": "cube",    "color": "#f0c020", "scale": 1.3},
            {"shape": "sphere",  "color": "#888888", "scale": 0.6},
        ],
    },
    {
        "id": "stack_analogous_warm",
        "notes": "Analogous warm: red, red-orange, orange, yellow-orange. Hues that sit next to each other on the wheel — quiet, not conflicting.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.25,
        "sequence": [
            {"shape": "cube",    "color": "#a02020", "scale": 1.2},
            {"shape": "sphere",  "color": "#c84020", "scale": 1.0},
            {"shape": "cuboid",  "color": "#e87018", "scale": 1.0},
            {"shape": "sphere",  "color": "#f0a830", "scale": 0.8},
        ],
    },
    {
        "id": "stack_monochrome_blue",
        "notes": "Monochrome study: one hue (blue) across many values. Tonal study isolated from hue/chroma.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.22,
        "sequence": [
            {"shape": "cube",    "color": "#0a1830", "scale": 1.0},
            {"shape": "sphere",  "color": "#1c3868", "scale": 0.9},
            {"shape": "cube",    "color": "#3060a0", "scale": 1.0},
            {"shape": "sphere",  "color": "#5088c0", "scale": 0.9},
            {"shape": "cube",    "color": "#80b0e0", "scale": 1.0},
        ],
    },
]


# ── color-furniture-gallery ──────────────────────────────────────
# Furniture-like compositions: things that read as functional objects.
# Vignelli coffee tables, Coco pendants, Becker wall grids, lamp-stacks.

COLOR_FURNITURE = [
    {
        "id": "furniture_vignelli_metafora_primary",
        "notes": "Vignelli Metafora coffee table — sphere/cylinder/cube/wedge legs in Bauhaus primaries under a white plate. The original (1979) used neutral wood; here we treat the legs as a color-theory wheel.",
        "layout": "under_plate",
        "palette": "bauhaus",
        "leg_size": 0.24,
        "plate_radius": 0.75,
        "plate_color": [0.95, 0.95, 0.93],
        "legs": [
            {"shape": "sphere",   "color": "#cc1f1f"},
            {"shape": "cylinder", "color": "#f0c020"},
            {"shape": "cube",     "color": "#1f4ecc"},
            {"shape": "wedge",    "color": "#1a1a1a"},
        ],
    },
    {
        "id": "furniture_vignelli_complementary",
        "notes": "Coffee table with complementary leg pairs: red+green opposite, yellow+violet opposite. Each pair forms a diagonal — color tension across the plate.",
        "layout": "under_plate",
        "palette": "color_pedagogy",
        "leg_size": 0.22,
        "plate_radius": 0.75,
        "plate_color": [0.92, 0.90, 0.86],
        "legs": [
            {"shape": "cube",    "color": "#a02020"},
            {"shape": "sphere",  "color": "#f0c020"},
            {"shape": "cube",    "color": "#2aa040"},
            {"shape": "sphere",  "color": "#6a30a0"},
        ],
    },
    {
        "id": "furniture_coco_pendant_warm",
        "notes": "Coco Reynolds pendant light, warm palette. Threaded wooden beads — color descends down the cord like a tonal scale.",
        "layout": "pendant_thread",
        "palette": "color_pedagogy",
        "base_scale": 0.18,
        "sequence": [
            {"shape": "sphere",  "color": "#3a1808", "scale": 0.7},
            {"shape": "sphere",  "color": "#7a3a18", "scale": 0.9},
            {"shape": "sphere",  "color": "#c06840", "scale": 1.1},
            {"shape": "sphere",  "color": "#e8a878", "scale": 1.3},
            {"shape": "sphere",  "color": "#f8d8b8", "scale": 1.5},
            {"shape": "sphere",  "color": "#f0c020", "scale": 0.9},
        ],
    },
    {
        "id": "furniture_coco_pendant_complementary",
        "notes": "Pendant in alternating complementaries — every bead opposes the one above and below. Vibrating chord of color.",
        "layout": "pendant_thread",
        "palette": "color_pedagogy",
        "base_scale": 0.18,
        "sequence": [
            {"shape": "sphere",  "color": "#a02020", "scale": 1.0},
            {"shape": "sphere",  "color": "#2aa040", "scale": 1.1},
            {"shape": "sphere",  "color": "#1844a0", "scale": 1.2},
            {"shape": "sphere",  "color": "#e87018", "scale": 1.0},
            {"shape": "sphere",  "color": "#6a30a0", "scale": 1.1},
            {"shape": "sphere",  "color": "#f0c020", "scale": 1.2},
        ],
    },
    {
        "id": "furniture_becker_utensilo_bauhaus",
        "notes": "Dorothee Becker Uten.Silo (1969) wall grid in Bauhaus primaries — every container is a different color/shape. Color-organized storage as pedagogy.",
        "layout": "wall_grid",
        "palette": "bauhaus",
        "cell_size": 0.35,
        "rows": 3,
        "cols": 4,
        "background_color": [0.95, 0.95, 0.93],
        "cells": [
            {"shape": "cube",     "color": "#cc1f1f"},
            {"shape": "sphere",   "color": "#f0c020"},
            {"shape": "cylinder", "color": "#1f4ecc"},
            {"shape": "cube",     "color": "#1a1a1a"},
            {"shape": "sphere",   "color": "#1f4ecc"},
            {"shape": "cube",     "color": "#cc1f1f"},
            {"shape": "cuboid",   "color": "#f0c020"},
            {"shape": "sphere",   "color": "#1a1a1a"},
            {"shape": "cylinder", "color": "#f0c020"},
            {"shape": "cube",     "color": "#1f4ecc"},
            {"shape": "sphere",   "color": "#cc1f1f"},
            {"shape": "cube",     "color": "#1a1a1a"},
        ],
    },
    {
        "id": "furniture_becker_utensilo_value",
        "notes": "Wall grid as pure value study — twelve grays from black to white, no chroma. Storage as Albers exercise.",
        "layout": "wall_grid",
        "palette": "color_pedagogy",
        "cell_size": 0.35,
        "rows": 3,
        "cols": 4,
        "background_color": [0.88, 0.86, 0.83],
        "cells": [
            {"shape": "cube",   "color": "#0a0a0a"},
            {"shape": "sphere", "color": "#1c1c1c"},
            {"shape": "cube",   "color": "#2e2e2e"},
            {"shape": "sphere", "color": "#404040"},
            {"shape": "cube",   "color": "#525252"},
            {"shape": "sphere", "color": "#646464"},
            {"shape": "cube",   "color": "#767676"},
            {"shape": "sphere", "color": "#888888"},
            {"shape": "cube",   "color": "#9a9a9a"},
            {"shape": "sphere", "color": "#acacac"},
            {"shape": "cube",   "color": "#bebebe"},
            {"shape": "sphere", "color": "#d0d0d0"},
        ],
    },
    {
        "id": "furniture_lamp_warm_glow",
        "notes": "Lamp-form: pyramid base + sphere shade. Warm core (yellow) inside cool shell (blue) — light through complementary contrast.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.30,
        "sequence": [
            {"shape": "cube",    "color": "#1a1a1a", "scale": 1.4},
            {"shape": "cuboid",  "color": "#1c3868", "scale": 0.6},
            {"shape": "sphere",  "color": "#f0d030", "scale": 1.4},
        ],
    },
    {
        "id": "furniture_lamp_pair",
        "notes": "Twin-lamp study: identical forms, complementary palettes. Same shape; only color changes.",
        "layout": "pendant_thread",
        "palette": "color_pedagogy",
        "base_scale": 0.20,
        "sequence": [
            {"shape": "cube",    "color": "#1a1a1a", "scale": 0.6},
            {"shape": "sphere",  "color": "#a02020", "scale": 1.4},
            {"shape": "cube",    "color": "#1a1a1a", "scale": 0.4},
            {"shape": "sphere",  "color": "#2aa040", "scale": 1.4},
        ],
    },
]


# ── Render execution ─────────────────────────────────────────────

def render_one(godot: str, gallery_slug: str, config: dict, force: bool) -> bool:
    cid = config["id"]
    out_dir = ENC / "public" / gallery_slug
    out_dir.mkdir(parents=True, exist_ok=True)
    out_png = out_dir / f"{cid}.png"
    out_cfg = out_dir / f"{cid}.json"
    if out_png.exists() and out_cfg.exists() and not force:
        print(f"    skip   {cid}")
        return True

    out_cfg.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")

    STAGING_DIR.mkdir(parents=True, exist_ok=True)
    cfg_staging = STAGING_DIR / f"{cid}.json"
    cfg_staging.write_text(json.dumps(config, indent=2), encoding="utf-8")
    user_out = f"user://ps_gallery/{cid}.png"
    res_cfg = f"res://commons/primitive_grammar/_staging/{cid}.json"
    cmd = [
        godot, "--path", str(REPO), "--xr-mode", "off", "--no-window",
        "--script", "res://commons/testing/render_primitive_stack.gd", "--",
        f"--config={res_cfg}", f"--out={user_out}", "--size=640",
    ]
    print(f"    render {cid} ...", end=" ", flush=True)
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        print("TIMEOUT")
        return False
    if proc.returncode != 0:
        print(f"FAIL rc={proc.returncode}")
        if proc.stderr:
            print(f"      stderr: {proc.stderr[-300:]}")
        return False

    # The render script writes to user://ps_gallery; find and copy to public.
    appdata = os.environ.get("APPDATA", "")
    if not appdata:
        print("no APPDATA")
        return False
    ud = Path(appdata) / "Godot" / "app_userdata"
    src = None
    if ud.exists():
        for d in ud.iterdir():
            cand = d / "ps_gallery" / f"{cid}.png"
            if cand.exists():
                src = cand
                break
    if src is None:
        print("no PNG produced")
        return False
    shutil.copy2(src, out_png)
    print(f"OK ({src.stat().st_size // 1024} KB)")
    return True


def write_manifest(gallery_slug: str, configs: list[dict], description: str) -> None:
    out_dir = ENC / "public" / gallery_slug
    entries = []
    for c in configs:
        entries.append({
            "id": c["id"],
            "notes": c["notes"],
            "layout": c["layout"],
            "image": f"/{gallery_slug}/{c['id']}.png",
            "config": f"/{gallery_slug}/{c['id']}.json",
        })
    manifest = {
        "schema_version": 1,
        "version": 1,
        "description": description,
        "entries": entries,
    }
    (out_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    evals = out_dir / "evals.json"
    if not evals.exists():
        evals.write_text("{}\n", encoding="utf-8")


# ── Main ─────────────────────────────────────────────────────────

GALLERIES = {
    "color-stacks-gallery": (
        COLOR_STACKS,
        "Color sequence — vertical_stack totems. Curated subset of primitive-stack-gallery focused on color principles: complementary pairs, triadic harmonies, value steps, simultaneous contrast, monochrome studies, analogous palettes."
    ),
    "color-furniture-gallery": (
        COLOR_FURNITURE,
        "Color sequence — furniture-like primitive_stack compositions. Vignelli coffee tables, Coco pendants, Becker wall grids, lamp forms. Color theory taught through everyday functional shapes."
    ),
}


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dry", action="store_true", help="Plan only.")
    ap.add_argument("--force", action="store_true", help="Re-render existing PNGs.")
    ap.add_argument("--gallery", help="Only this slug")
    args = ap.parse_args()

    selected = {k: v for k, v in GALLERIES.items()
                if not args.gallery or k == args.gallery}
    print(f"Galleries: {list(selected.keys())}")
    total = sum(len(cfg) for cfg, _ in selected.values())
    print(f"Total entries: {total}")
    for slug, (cfgs, _) in selected.items():
        print(f"  {slug}: {len(cfgs)} entries")
    print()

    if args.dry:
        for slug, (cfgs, _) in selected.items():
            print(f"  {slug}:")
            for c in cfgs:
                print(f"    - {c['id']:50s} layout={c['layout']}")
        return

    godot = _find_godot()
    if not godot:
        print("No Godot found. Set GODOT_EXE.")
        sys.exit(1)

    for slug, (cfgs, desc) in selected.items():
        print(f"  {slug}:")
        for c in cfgs:
            render_one(godot, slug, c, args.force)
        write_manifest(slug, cfgs, desc)
        print(f"    manifest written")
        print()


if __name__ == "__main__":
    main()
