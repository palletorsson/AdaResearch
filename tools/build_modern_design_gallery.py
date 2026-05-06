#!/usr/bin/env python3
"""
build_modern_design_gallery.py
==============================

Companion to build_modern_art_gallery.py. Modern art reduced painting
to color + primitive form; modern design did the same to objects. This
gallery restages 14 design icons (1925–1985) as primitive_stack totems —
the chair, the lamp, the radio, the coffee table — in the same color
+ shape vocabulary the engine speaks.

Lineage:
  Breuer        — Wassily Chair (B3): tubular steel + leather slabs
  Le Corbusier  — LC4 Chaise: black hide curve on chrome cradle
  Aalto         — Paimio 41: bent birch ribbon
  Saarinen      — Tulip pedestal: white stem + saucer + cushion
  Eames         — LCW: warm plywood seat / back / legs
  Bertoia       — Diamond Chair: chrome wire bowl on cushion
  Panton        — Stacking Chair: single S-curve in saturated color
  Castiglioni   — Arco lamp: marble base + steel arc + dome
  Sapper/Castig — Tizio: counterweight task lamp
  Sottsass      — Carlton (Memphis): black/yellow/red/teal grid
  Sottsass      — Olivetti Valentine: portable red typewriter
  Wegner        — Round Chair: warm wood + woven cane
  Rietveld      — Red/Blue Chair: De Stijl as furniture
  Joe Colombo   — Boby trolley: stacked plastic cylinders

Each entry is a primitive_stack config the existing renderer bakes.
Output: ada_encyclopedia/public/modern-design-gallery/.
Also appended into /primitive-stack-gallery/ so the master grid carries
art + design + color + furniture as one searchable surface.

Run:
    python tools/build_modern_design_gallery.py
    python tools/build_modern_design_gallery.py --dry
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
GALLERY_SLUG = "modern-design-gallery"
PS_GALLERY = "primitive-stack-gallery"
STAGING_DIR = REPO / "commons" / "primitive_grammar" / "_staging"


MODERN_DESIGN = [
    {
        "id": "breuer_wassily_b3",
        "designer": "Marcel Breuer",
        "year": 1925,
        "movement": "Bauhaus",
        "notes": "Wassily Chair (B3): tubular steel skeleton + black leather slabs. Frame disappears, hide and air remain. Stack reads as cushion / sling / back / cradle.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.26,
        "sequence": [
            {"shape": "cuboid", "color": "#888888", "scale": 1.4},
            {"shape": "cuboid", "color": "#1a1a1a", "scale": 1.2},
            {"shape": "cuboid", "color": "#888888", "scale": 1.0},
            {"shape": "cuboid", "color": "#1a1a1a", "scale": 1.1},
        ],
    },
    {
        "id": "lecorbusier_lc4_chaise",
        "designer": "Le Corbusier / Perriand / Jeanneret",
        "year": 1928,
        "movement": "Modernism",
        "notes": "LC4 Chaise: black pony hide as a single arc cradled on chromed steel. The body's curve, structuralized.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.24,
        "sequence": [
            {"shape": "cuboid", "color": "#2a2a2a", "scale": 0.8},
            {"shape": "cuboid", "color": "#bcbcbc", "scale": 1.2},
            {"shape": "cylinder", "color": "#1a1a1a", "scale": 1.5},
            {"shape": "sphere",  "color": "#1a1a1a", "scale": 0.6},
        ],
    },
    {
        "id": "aalto_paimio_41",
        "designer": "Alvar Aalto",
        "year": 1932,
        "movement": "Nordic modernism",
        "notes": "Paimio 41: bent laminated birch as a single ribbon. The wood remembers the steam-bend. Warm tones, soft S-curve.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.26,
        "sequence": [
            {"shape": "cuboid",  "color": "#d8a868", "scale": 1.3},
            {"shape": "cylinder","color": "#a87838", "scale": 0.4},
            {"shape": "cuboid",  "color": "#d8a868", "scale": 1.4},
            {"shape": "cylinder","color": "#a87838", "scale": 0.4},
            {"shape": "cuboid",  "color": "#d8a868", "scale": 1.2},
        ],
    },
    {
        "id": "saarinen_tulip_pedestal",
        "designer": "Eero Saarinen",
        "year": 1957,
        "movement": "Mid-century modernism",
        "notes": "Tulip Chair: aluminum stem rising into a fiberglass saucer + red cushion. Saarinen wanted to clear the 'slum of legs' — one column, one bowl.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.28,
        "sequence": [
            {"shape": "cylinder", "color": "#f4f2ec", "scale": 0.5},
            {"shape": "cylinder", "color": "#f4f2ec", "scale": 0.35},
            {"shape": "sphere",   "color": "#f4f2ec", "scale": 1.4},
            {"shape": "cube",     "color": "#cc1f1f", "scale": 1.2},
        ],
    },
    {
        "id": "eames_lcw_plywood",
        "designer": "Charles & Ray Eames",
        "year": 1946,
        "movement": "Mid-century modernism",
        "notes": "LCW (Lounge Chair Wood): three molded plywood shells — back, seat, legs — connected by rubber shock mounts. Warm walnut throughout.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.24,
        "sequence": [
            {"shape": "cylinder", "color": "#5a3018", "scale": 0.4},
            {"shape": "cuboid",   "color": "#8a4818", "scale": 1.3},
            {"shape": "cylinder", "color": "#5a3018", "scale": 0.3},
            {"shape": "cuboid",   "color": "#a86028", "scale": 1.1},
            {"shape": "cylinder", "color": "#5a3018", "scale": 0.3},
            {"shape": "cuboid",   "color": "#8a4818", "scale": 0.9},
        ],
    },
    {
        "id": "bertoia_diamond",
        "designer": "Harry Bertoia",
        "year": 1952,
        "movement": "Mid-century modernism",
        "notes": "Diamond Chair: chrome wire-grid bowl on a cantilevered base, soft cushion floating inside. 'Mostly air,' Bertoia said. Mesh + cushion + frame.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.25,
        "sequence": [
            {"shape": "cuboid",   "color": "#c8c8c8", "scale": 1.0},
            {"shape": "sphere",   "color": "#cc4040", "scale": 0.8},
            {"shape": "cylinder", "color": "#bcbcbc", "scale": 1.4},
            {"shape": "cuboid",   "color": "#888888", "scale": 0.4},
        ],
    },
    {
        "id": "panton_s_curve",
        "designer": "Verner Panton",
        "year": 1967,
        "movement": "Pop / Space-age",
        "notes": "Panton Chair: a single saturated S-curve in moulded plastic, the first one-piece cantilever. Color and form fused — no joints, no breaks.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.26,
        "sequence": [
            {"shape": "cuboid", "color": "#e02828", "scale": 1.3},
            {"shape": "cuboid", "color": "#e02828", "scale": 0.9},
            {"shape": "cuboid", "color": "#e02828", "scale": 1.2},
            {"shape": "cuboid", "color": "#e02828", "scale": 0.8},
        ],
    },
    {
        "id": "castiglioni_arco",
        "designer": "Achille & Pier Giacomo Castiglioni",
        "year": 1962,
        "movement": "Italian modernism",
        "notes": "Arco lamp: white Carrara marble cube + chromed steel arc + perforated aluminum dome. Floor lamp that reaches across a room.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.28,
        "sequence": [
            {"shape": "cube",     "color": "#f4f2ec", "scale": 1.4},
            {"shape": "cylinder", "color": "#bcbcbc", "scale": 0.3},
            {"shape": "cylinder", "color": "#bcbcbc", "scale": 0.3},
            {"shape": "cylinder", "color": "#bcbcbc", "scale": 0.3},
            {"shape": "sphere",   "color": "#cccccc", "scale": 1.2},
        ],
    },
    {
        "id": "sapper_tizio",
        "designer": "Richard Sapper",
        "year": 1972,
        "movement": "Italian modernism / Artemide",
        "notes": "Tizio task lamp: black metal rods balanced by counterweights, halogen head at the tip. No springs — pure geometry.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.20,
        "sequence": [
            {"shape": "cylinder", "color": "#1a1a1a", "scale": 1.2},
            {"shape": "cylinder", "color": "#1a1a1a", "scale": 0.25},
            {"shape": "cuboid",   "color": "#1a1a1a", "scale": 1.6},
            {"shape": "sphere",   "color": "#3a3a3a", "scale": 0.4},
            {"shape": "cuboid",   "color": "#1a1a1a", "scale": 1.4},
            {"shape": "cuboid",   "color": "#1a1a1a", "scale": 0.5},
        ],
    },
    {
        "id": "sottsass_carlton_memphis",
        "designer": "Ettore Sottsass",
        "year": 1981,
        "movement": "Memphis Group",
        "notes": "Carlton room divider: laminated plastic in screaming primaries + black/white grid + pink. The Memphis manifesto — clear color, comic-book joy, anti-good-taste.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.22,
        "sequence": [
            {"shape": "cuboid", "color": "#f0c020", "scale": 1.4},
            {"shape": "cuboid", "color": "#0a0a0a", "scale": 0.3},
            {"shape": "cube",   "color": "#cc1f1f", "scale": 1.0},
            {"shape": "cube",   "color": "#1a8888", "scale": 1.0},
            {"shape": "cuboid", "color": "#f4f2ec", "scale": 0.3},
            {"shape": "cube",   "color": "#ff60b0", "scale": 1.2},
            {"shape": "cuboid", "color": "#0a0a0a", "scale": 0.3},
        ],
    },
    {
        "id": "sottsass_valentine_typewriter",
        "designer": "Ettore Sottsass + Perry King",
        "year": 1969,
        "movement": "Italian design / Olivetti",
        "notes": "Valentine: portable typewriter in fire-engine red ABS with two orange spool knobs. 'Anti-machine, anti-office' — typing in the park.",
        "layout": "under_plate",
        "palette": "color_pedagogy",
        "leg_size": 0.18,
        "plate_radius": 0.50,
        "plate_color": [0.85, 0.18, 0.14],
        "legs": [
            {"shape": "cylinder", "color": "#e85020"},
            {"shape": "cylinder", "color": "#e85020"},
            {"shape": "cube",     "color": "#cc1f1f"},
            {"shape": "cube",     "color": "#cc1f1f"},
        ],
    },
    {
        "id": "wegner_round_chair",
        "designer": "Hans Wegner",
        "year": 1949,
        "movement": "Danish modern",
        "notes": "PP501 'The Chair': curved teak frame, woven cane seat. JFK chose it for the Nixon debate. Warm wood + pale weave + wood again.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.26,
        "sequence": [
            {"shape": "cylinder", "color": "#8a4818", "scale": 0.3},
            {"shape": "cuboid",   "color": "#a86028", "scale": 1.4},
            {"shape": "cuboid",   "color": "#e8c890", "scale": 1.1},
            {"shape": "cuboid",   "color": "#a86028", "scale": 0.9},
        ],
    },
    {
        "id": "rietveld_red_blue_chair",
        "designer": "Gerrit Rietveld",
        "year": 1923,
        "movement": "De Stijl",
        "notes": "Red and Blue Chair: De Stijl as furniture. Black frame, primary planes — Mondrian made sittable. Red back, blue seat, yellow tips.",
        "layout": "vertical_stack",
        "palette": "bauhaus",
        "base_scale": 0.26,
        "sequence": [
            {"shape": "cuboid", "color": "#0a0a0a", "scale": 1.0},
            {"shape": "cube",   "color": "#cc1f1f", "scale": 1.3},
            {"shape": "cuboid", "color": "#0a0a0a", "scale": 0.25},
            {"shape": "cube",   "color": "#1f4ecc", "scale": 1.2},
            {"shape": "cuboid", "color": "#f0c020", "scale": 0.3},
        ],
    },
    {
        "id": "colombo_boby_trolley",
        "designer": "Joe Colombo",
        "year": 1970,
        "movement": "Italian / space-age",
        "notes": "Boby Trolley: stacking ABS modules on castors — drawers + shelves + cylinders in saturated single-color plastic. Workshop-on-wheels.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.24,
        "sequence": [
            {"shape": "sphere",   "color": "#1a1a1a", "scale": 0.4},
            {"shape": "cylinder", "color": "#e85020", "scale": 1.2},
            {"shape": "cylinder", "color": "#e85020", "scale": 1.2},
            {"shape": "cylinder", "color": "#e85020", "scale": 1.0},
            {"shape": "cube",     "color": "#1a1a1a", "scale": 0.3},
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
            "designer": c.get("designer", ""),
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
            "Modern design (1923–1985) restaged as primitive_stack totems. "
            "14 furniture / lighting / object icons where shape + color IS the "
            "signature: Bauhaus, Modernism, Mid-century, Italian post-war, "
            "Memphis. Each entry translates one designer's gesture into a stack "
            "the engine can bake."
        ),
        "entries": entries,
    }
    (out_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    evals = out_dir / "evals.json"
    if not evals.exists():
        evals.write_text("{}\n", encoding="utf-8")


def merge_into_primitive_stack_gallery(configs: list[dict]) -> None:
    """Copy PNG+JSON into /primitive-stack-gallery/ and append manifest entries."""
    src_dir = ENC / "public" / GALLERY_SLUG
    dst_dir = ENC / "public" / PS_GALLERY
    for c in configs:
        cid = c["id"]
        for ext in (".png", ".json"):
            sp = src_dir / f"{cid}{ext}"
            if sp.exists():
                shutil.copy2(sp, dst_dir / f"{cid}{ext}")

    ps_manifest = dst_dir / "manifest.json"
    m = json.loads(ps_manifest.read_text(encoding="utf-8"))
    existing = {e["id"] for e in m["entries"]}
    added = 0
    for c in configs:
        if c["id"] in existing:
            continue
        m["entries"].append({
            "id": c["id"],
            "notes": f"[{c.get('designer','')} · {c.get('year','')} · {c.get('movement','')}] {c['notes']}",
            "layout": c["layout"],
            "image": f"/{PS_GALLERY}/{c['id']}.png",
            "config": f"/{PS_GALLERY}/{c['id']}.json",
        })
        added += 1
    ps_manifest.write_text(json.dumps(m, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"  merged into /{PS_GALLERY}/: +{added} entries (total {len(m['entries'])})")


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dry", action="store_true")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--no-merge", action="store_true",
                    help="Skip appending into primitive-stack-gallery.")
    args = ap.parse_args()

    print(f"modern-design-gallery: {len(MODERN_DESIGN)} entries")
    for c in MODERN_DESIGN:
        print(f"  {c['id']:36s} {c['designer'][:28]:28s} ({c.get('year','')}) {c.get('movement','')}")
    print()

    if args.dry:
        return

    godot = _find_godot()
    if not godot:
        print("No Godot found. Set GODOT_EXE.")
        sys.exit(1)

    for c in MODERN_DESIGN:
        render_one(godot, c, args.force)
    write_manifest(MODERN_DESIGN)
    print(f"\nWrote: ada_encyclopedia/public/{GALLERY_SLUG}/")
    if not args.no_merge:
        merge_into_primitive_stack_gallery(MODERN_DESIGN)
    print(f"View:  http://localhost:3003/{GALLERY_SLUG}/<id>.png")
    print(f"       http://localhost:3003/{PS_GALLERY}  (filter for designer name)")


if __name__ == "__main__":
    main()
