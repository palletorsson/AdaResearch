#!/usr/bin/env python3
"""
build_modern_art_gallery.py
============================

Auto-research pass on modern art (1910s–1970s): take 14 movements / artists
whose work reduces visual experience to color + primitive geometry, and
restage each as a primitive_stack composition the existing renderer can
bake. The point isn't to copy paintings — it's to translate each artist's
color-form thesis into a totem the engine already speaks.

Lineage:
  Malevich      — Suprematism: black square + chromatic remainder
  Mondrian      — De Stijl: red/yellow/blue + black bars + white field
  Albers        — "Homage to the Square": nested-value squares, no chroma trick
  Rothko        — chromatic abstraction: stacked color fields, soft warm/cool
  Newman        — zip / vertical bar: one chord cleaving a field
  Klein         — IKB monochrome: one blue, all values
  Kelly         — hard-edge color blocks: discrete saturated planes
  Stella        — concentric stripes: structural color sequence
  Judd          — minimalist stack: identical units, equal intervals
  LeWitt        — open cube modular: form-as-system, neutral tone
  Flavin        — fluorescent: warm-cool light pairs, glow logic
  Riley         — Op art: alternating black/white, perceptual flicker
  Calder        — mobile primaries: red/yellow/black/white discs
  Kandinsky     — Bauhaus triad: circle/triangle/square as primary chord

Each entry is a primitive_stack config the existing renderer bakes; output
goes to ada_encyclopedia/public/modern-art-gallery/.

Run:
    python tools/build_modern_art_gallery.py
    python tools/build_modern_art_gallery.py --dry
    python tools/build_modern_art_gallery.py --force
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
GALLERY_SLUG = "modern-art-gallery"
STAGING_DIR = REPO / "commons" / "primitive_grammar" / "_staging"


MODERN_ART = [
    {
        "id": "malevich_black_square",
        "artist": "Kazimir Malevich",
        "year": 1915,
        "movement": "Suprematism",
        "notes": "Black Square (1915) as totem: one black mass dominates, smaller chromatic remainders cling beneath. The painting's claim — geometry over representation — read vertically.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.30,
        "sequence": [
            {"shape": "cube",   "color": "#0a0a0a", "scale": 1.6},
            {"shape": "cube",   "color": "#cc1f1f", "scale": 0.6},
            {"shape": "cuboid", "color": "#f0c020", "scale": 0.5},
        ],
    },
    {
        "id": "mondrian_de_stijl",
        "artist": "Piet Mondrian",
        "year": 1930,
        "movement": "De Stijl",
        "notes": "Composition with Red, Blue and Yellow (1930). The neoplastic alphabet: white field, black grid, primary triad. Each block its own scale to mark the asymmetry that made the paintings hum.",
        "layout": "vertical_stack",
        "palette": "bauhaus",
        "base_scale": 0.25,
        "sequence": [
            {"shape": "cube",   "color": "#f4f2ec", "scale": 1.5},
            {"shape": "cuboid", "color": "#0a0a0a", "scale": 0.20},
            {"shape": "cube",   "color": "#cc1f1f", "scale": 1.2},
            {"shape": "cuboid", "color": "#0a0a0a", "scale": 0.18},
            {"shape": "cube",   "color": "#1f4ecc", "scale": 0.9},
            {"shape": "cuboid", "color": "#0a0a0a", "scale": 0.15},
            {"shape": "cube",   "color": "#f0c020", "scale": 0.7},
        ],
    },
    {
        "id": "albers_homage_warm",
        "artist": "Josef Albers",
        "year": 1959,
        "movement": "Bauhaus / color theory",
        "notes": "Homage to the Square — nested squares, warm value steps. Albers' demonstration that color is relational: no two adjacent squares look the way they would alone.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.28,
        "sequence": [
            {"shape": "cube", "color": "#3a1808", "scale": 1.6},
            {"shape": "cube", "color": "#7a3a18", "scale": 1.3},
            {"shape": "cube", "color": "#c06840", "scale": 1.0},
            {"shape": "cube", "color": "#e8a878", "scale": 0.7},
        ],
    },
    {
        "id": "rothko_chromatic_field",
        "artist": "Mark Rothko",
        "year": 1957,
        "movement": "Color-field",
        "notes": "Stacked atmospheric color planes — burgundy, ember, ochre — read as light bleeding between zones. Spheres soften the edges where Rothko's brushwork did.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.32,
        "sequence": [
            {"shape": "cuboid", "color": "#3a0808", "scale": 1.5},
            {"shape": "sphere", "color": "#882010", "scale": 0.3},
            {"shape": "cuboid", "color": "#c84818", "scale": 1.4},
            {"shape": "sphere", "color": "#e08840", "scale": 0.3},
            {"shape": "cuboid", "color": "#a86018", "scale": 1.2},
        ],
    },
    {
        "id": "newman_zip",
        "artist": "Barnett Newman",
        "year": 1951,
        "movement": "Color-field",
        "notes": "Vir Heroicus Sublimis — the 'zip': a single vertical line cleaving a field of color. Here a tall narrow column of cadmium splits a maroon mass.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.30,
        "sequence": [
            {"shape": "cube",   "color": "#5a0a0a", "scale": 1.4},
            {"shape": "cuboid", "color": "#f0c020", "scale": 0.18},
            {"shape": "cube",   "color": "#5a0a0a", "scale": 1.4},
        ],
    },
    {
        "id": "klein_ikb_monochrome",
        "artist": "Yves Klein",
        "year": 1957,
        "movement": "Monochrome / Nouveau réalisme",
        "notes": "International Klein Blue: one ultramarine across the entire object, varied only in form and value. Color reduced to substance.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.26,
        "sequence": [
            {"shape": "cube",    "color": "#0a1860", "scale": 1.2},
            {"shape": "sphere",  "color": "#1230a8", "scale": 1.1},
            {"shape": "cuboid",  "color": "#0a1860", "scale": 1.0},
            {"shape": "sphere",  "color": "#1230a8", "scale": 0.9},
            {"shape": "cube",    "color": "#0a1860", "scale": 0.8},
        ],
    },
    {
        "id": "kelly_hard_edge",
        "artist": "Ellsworth Kelly",
        "year": 1966,
        "movement": "Hard-edge / Color-field",
        "notes": "Discrete saturated planes, no transitions. Each color is a fact. Five panels; no two share family.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.26,
        "sequence": [
            {"shape": "cuboid", "color": "#1a8848", "scale": 1.0},
            {"shape": "cuboid", "color": "#cc1818", "scale": 1.0},
            {"shape": "cuboid", "color": "#f0c020", "scale": 1.0},
            {"shape": "cuboid", "color": "#1844a0", "scale": 1.0},
            {"shape": "cuboid", "color": "#1a1a1a", "scale": 1.0},
        ],
    },
    {
        "id": "stella_concentric_stripes",
        "artist": "Frank Stella",
        "year": 1967,
        "movement": "Hard-edge / Minimalism",
        "notes": "Protractor Series: nested stripes as structural color sequence. Hue order is the composition.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.20,
        "sequence": [
            {"shape": "cuboid", "color": "#a02020", "scale": 1.4},
            {"shape": "cuboid", "color": "#e87018", "scale": 1.3},
            {"shape": "cuboid", "color": "#f0c020", "scale": 1.2},
            {"shape": "cuboid", "color": "#3aa060", "scale": 1.1},
            {"shape": "cuboid", "color": "#1844a0", "scale": 1.0},
            {"shape": "cuboid", "color": "#6a30a0", "scale": 0.9},
        ],
    },
    {
        "id": "judd_minimalist_stack",
        "artist": "Donald Judd",
        "year": 1968,
        "movement": "Minimalism",
        "notes": "Untitled (Stack): identical metal units at equal vertical intervals. Repetition without hierarchy — the wall is the composition.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.28,
        "sequence": [
            {"shape": "cuboid", "color": "#888888", "scale": 1.0},
            {"shape": "cuboid", "color": "#888888", "scale": 1.0},
            {"shape": "cuboid", "color": "#888888", "scale": 1.0},
            {"shape": "cuboid", "color": "#888888", "scale": 1.0},
            {"shape": "cuboid", "color": "#888888", "scale": 1.0},
        ],
    },
    {
        "id": "lewitt_modular_cube",
        "artist": "Sol LeWitt",
        "year": 1969,
        "movement": "Conceptual / Minimalism",
        "notes": "Open Modular Cube: form as system. Neutral white frame stacked — the rule is the artwork; color withdraws.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.30,
        "sequence": [
            {"shape": "cube", "color": "#f4f2ec", "scale": 1.0},
            {"shape": "cube", "color": "#f4f2ec", "scale": 1.0},
            {"shape": "cube", "color": "#f4f2ec", "scale": 1.0},
        ],
    },
    {
        "id": "flavin_fluorescent_pair",
        "artist": "Dan Flavin",
        "year": 1964,
        "movement": "Minimalism / light art",
        "notes": "Fluorescent tubes: warm/cool light pairs that color the wall around them. A pink core flanked by daylight white — glow as composition.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.18,
        "sequence": [
            {"shape": "cuboid", "color": "#f8e8d8", "scale": 0.6},
            {"shape": "cuboid", "color": "#ff60b0", "scale": 1.4},
            {"shape": "cuboid", "color": "#f8e8d8", "scale": 0.6},
            {"shape": "cuboid", "color": "#60b8ff", "scale": 1.4},
            {"shape": "cuboid", "color": "#f8e8d8", "scale": 0.6},
        ],
    },
    {
        "id": "riley_op_alternation",
        "artist": "Bridget Riley",
        "year": 1962,
        "movement": "Op art",
        "notes": "Movement in Squares: black/white alternation engineered for retinal flicker. The composition shimmers without ever moving.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.18,
        "sequence": [
            {"shape": "cube", "color": "#0a0a0a", "scale": 1.0},
            {"shape": "cube", "color": "#f4f2ec", "scale": 1.0},
            {"shape": "cube", "color": "#0a0a0a", "scale": 1.0},
            {"shape": "cube", "color": "#f4f2ec", "scale": 1.0},
            {"shape": "cube", "color": "#0a0a0a", "scale": 1.0},
            {"shape": "cube", "color": "#f4f2ec", "scale": 1.0},
            {"shape": "cube", "color": "#0a0a0a", "scale": 1.0},
        ],
    },
    {
        "id": "calder_mobile_primaries",
        "artist": "Alexander Calder",
        "year": 1939,
        "movement": "Kinetic sculpture",
        "notes": "Mobile palette — red, yellow, black, white discs hung from steel arms. The four-color chord that makes a Calder unmistakable, totem-form.",
        "layout": "vertical_stack",
        "palette": "bauhaus",
        "base_scale": 0.24,
        "sequence": [
            {"shape": "sphere", "color": "#cc1f1f", "scale": 1.2},
            {"shape": "cuboid", "color": "#0a0a0a", "scale": 0.15},
            {"shape": "sphere", "color": "#f0c020", "scale": 1.0},
            {"shape": "cuboid", "color": "#0a0a0a", "scale": 0.15},
            {"shape": "sphere", "color": "#f4f2ec", "scale": 0.9},
            {"shape": "cuboid", "color": "#0a0a0a", "scale": 0.15},
            {"shape": "sphere", "color": "#0a0a0a", "scale": 1.1},
        ],
    },
    {
        "id": "kandinsky_bauhaus_triad",
        "artist": "Wassily Kandinsky",
        "year": 1923,
        "movement": "Bauhaus",
        "notes": "The 1923 questionnaire: yellow=triangle, red=square, blue=circle. Each shape is its color and no other. The taxonomy that founded a school's color pedagogy.",
        "layout": "vertical_stack",
        "palette": "bauhaus",
        "base_scale": 0.28,
        "sequence": [
            {"shape": "cube",   "color": "#cc1f1f", "scale": 1.2},
            {"shape": "sphere", "color": "#1f4ecc", "scale": 1.2},
            {"shape": "wedge",  "color": "#f0c020", "scale": 1.4},
        ],
    },
]


# ── Render execution ─────────────────────────────────────────────

def render_one(godot: str, config: dict, force: bool) -> bool:
    cid = config["id"]
    out_dir = ENC / "public" / GALLERY_SLUG
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


def write_manifest(configs: list[dict]) -> None:
    out_dir = ENC / "public" / GALLERY_SLUG
    entries = []
    for c in configs:
        entries.append({
            "id": c["id"],
            "artist": c.get("artist", ""),
            "year": c.get("year", 0),
            "movement": c.get("movement", ""),
            "notes": c["notes"],
            "layout": c["layout"],
            "image": f"/{GALLERY_SLUG}/{c['id']}.png",
            "config": f"/{GALLERY_SLUG}/{c['id']}.json",
        })
    manifest = {
        "schema_version": 1,
        "version": 1,
        "description": (
            "Modern art (1915–1969) restaged as primitive_stack totems. "
            "14 artists / movements where color + primitive geometry IS the work: "
            "Suprematism, De Stijl, Bauhaus pedagogy, color-field, hard-edge, "
            "minimalism, kinetic, Op art, fluorescent light. Each entry "
            "translates one artist's color-form thesis into a stack the engine "
            "can bake."
        ),
        "entries": entries,
    }
    (out_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    evals = out_dir / "evals.json"
    if not evals.exists():
        evals.write_text("{}\n", encoding="utf-8")


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dry", action="store_true")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    print(f"modern-art-gallery: {len(MODERN_ART)} entries")
    for c in MODERN_ART:
        print(f"  {c['id']:36s} {c['artist']:22s} ({c.get('year','')}) {c.get('movement','')}")
    print()

    if args.dry:
        return

    godot = _find_godot()
    if not godot:
        print("No Godot found. Set GODOT_EXE.")
        sys.exit(1)

    for c in MODERN_ART:
        render_one(godot, c, args.force)
    write_manifest(MODERN_ART)
    print(f"\nWrote: ada_encyclopedia/public/{GALLERY_SLUG}/")
    print(f"View:  http://localhost:3003/{GALLERY_SLUG}/<id>.png")


if __name__ == "__main__":
    main()
