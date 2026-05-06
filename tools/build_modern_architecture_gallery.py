#!/usr/bin/env python3
"""
build_modern_architecture_gallery.py
====================================

Third in the trilogy: art → design → architecture. Where the art gallery
abstracted painting and the design gallery abstracted objects, this one
takes 14 modern buildings (1909–1997) and reads each as a primitive_stack
totem — base, mass, signature element, crown — in the same shape + color
language the engine speaks.

Lineage:
  Wright        — Robie House (1909): Prairie horizontality
  Gropius       — Bauhaus Dessau (1926): the school as its own diagram
  Mies          — Barcelona Pavilion (1929): travertine plinth, onyx wall
  Van Alen      — Chrysler Building (1930): art-deco crown
  Le Corbusier  — Villa Savoye (1931): pilotis + box + roof garden
  Wright        — Fallingwater (1935): cantilever over stream
  Mies          — Farnsworth House (1951): glass box on steel
  Le Corbusier  — Ronchamp (1955): poured-concrete vessel
  Mies          — Seagram (1958): bronze tower + plaza
  Wright        — Guggenheim NYC (1959): white spiral
  Safdie        — Habitat 67 (1967): stacked cube modules
  Utzon         — Sydney Opera (1973): white sail shells
  Piano/Rogers  — Pompidou (1977): exoskeleton in primary colors
  Gehry         — Guggenheim Bilbao (1997): titanium curves

Output: ada_encyclopedia/public/modern-architecture-gallery/, plus
appended into /primitive-stack-gallery/ for the master grid.

Run:
    python tools/build_modern_architecture_gallery.py
    python tools/build_modern_architecture_gallery.py --dry
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
GALLERY_SLUG = "modern-architecture-gallery"
PS_GALLERY = "primitive-stack-gallery"
STAGING_DIR = REPO / "commons" / "primitive_grammar" / "_staging"


MODERN_ARCH = [
    {
        "id": "wright_robie_house",
        "architect": "Frank Lloyd Wright",
        "year": 1909,
        "movement": "Prairie School",
        "notes": "Robie House: low horizontal bands, deep eaves, Roman brick. Wright's prairie thesis — the building belongs to the ground plane.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.30,
        "sequence": [
            {"shape": "cuboid", "color": "#7a3018", "scale": 1.6},
            {"shape": "cuboid", "color": "#a85028", "scale": 1.4},
            {"shape": "cuboid", "color": "#e8c890", "scale": 1.5},
            {"shape": "cuboid", "color": "#5a2818", "scale": 0.4},
        ],
    },
    {
        "id": "gropius_bauhaus_dessau",
        "architect": "Walter Gropius",
        "year": 1926,
        "movement": "Bauhaus",
        "notes": "Bauhaus Dessau: white planar volumes, ribbon glazing, the school as its own pedagogical diagram. Studio block, workshop wing, bridge.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.28,
        "sequence": [
            {"shape": "cuboid", "color": "#f4f2ec", "scale": 1.5},
            {"shape": "cuboid", "color": "#1f4ecc", "scale": 0.18},
            {"shape": "cuboid", "color": "#f4f2ec", "scale": 1.5},
            {"shape": "cuboid", "color": "#1f4ecc", "scale": 0.18},
            {"shape": "cuboid", "color": "#f4f2ec", "scale": 1.5},
        ],
    },
    {
        "id": "mies_barcelona_pavilion",
        "architect": "Ludwig Mies van der Rohe",
        "year": 1929,
        "movement": "International Style",
        "notes": "Barcelona Pavilion: travertine plinth, free-standing onyx wall, chromed cruciform columns. 'God is in the details.' Plinth + wall + sky.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.30,
        "sequence": [
            {"shape": "cuboid",   "color": "#d8c8a8", "scale": 1.6},
            {"shape": "cylinder", "color": "#bcbcbc", "scale": 0.22},
            {"shape": "cuboid",   "color": "#a8783a", "scale": 1.3},
            {"shape": "cuboid",   "color": "#f4f2ec", "scale": 1.5},
        ],
    },
    {
        "id": "van_alen_chrysler",
        "architect": "William Van Alen",
        "year": 1930,
        "movement": "Art Deco",
        "notes": "Chrysler Building: brick shaft rising into stainless-steel sunburst crown. The setback skyscraper as Cadillac hood ornament.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.20,
        "sequence": [
            {"shape": "cuboid",   "color": "#5a3018", "scale": 1.0},
            {"shape": "cuboid",   "color": "#7a3818", "scale": 1.2},
            {"shape": "cuboid",   "color": "#a85028", "scale": 1.4},
            {"shape": "sphere",   "color": "#cccccc", "scale": 1.0},
            {"shape": "cylinder", "color": "#e8e8e8", "scale": 0.5},
            {"shape": "cylinder", "color": "#bcbcbc", "scale": 0.18},
        ],
    },
    {
        "id": "lecorbusier_villa_savoye",
        "architect": "Le Corbusier",
        "year": 1931,
        "movement": "Modernism",
        "notes": "Villa Savoye: the Five Points incarnate. Pilotis lift a white box; ribbon windows wrap; roof garden crowns. Machine for living.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.30,
        "sequence": [
            {"shape": "cylinder", "color": "#bcbcbc", "scale": 0.20},
            {"shape": "cylinder", "color": "#bcbcbc", "scale": 0.20},
            {"shape": "cuboid",   "color": "#f4f2ec", "scale": 1.5},
            {"shape": "cuboid",   "color": "#1a1a1a", "scale": 0.18},
            {"shape": "cuboid",   "color": "#f4f2ec", "scale": 1.5},
            {"shape": "cylinder", "color": "#a86028", "scale": 0.6},
        ],
    },
    {
        "id": "wright_fallingwater",
        "architect": "Frank Lloyd Wright",
        "year": 1935,
        "movement": "Organic architecture",
        "notes": "Fallingwater: ochre concrete trays cantilevered over Bear Run, rooted in stone. The house and the waterfall are one structure.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.26,
        "sequence": [
            {"shape": "cuboid", "color": "#5a4838", "scale": 1.5},
            {"shape": "cuboid", "color": "#d8c098", "scale": 1.7},
            {"shape": "cuboid", "color": "#a87838", "scale": 1.0},
            {"shape": "cuboid", "color": "#d8c098", "scale": 1.5},
            {"shape": "cuboid", "color": "#a87838", "scale": 0.9},
        ],
    },
    {
        "id": "mies_farnsworth",
        "architect": "Ludwig Mies van der Rohe",
        "year": 1951,
        "movement": "International Style",
        "notes": "Farnsworth House: white-painted steel frame holding a glass box above the floodplain. Inhabited transparency.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.28,
        "sequence": [
            {"shape": "cuboid", "color": "#888888", "scale": 1.4},
            {"shape": "cuboid", "color": "#f4f2ec", "scale": 0.30},
            {"shape": "cuboid", "color": "#cce8f4", "scale": 1.5},
            {"shape": "cuboid", "color": "#f4f2ec", "scale": 0.30},
        ],
    },
    {
        "id": "lecorbusier_ronchamp",
        "architect": "Le Corbusier",
        "year": 1955,
        "movement": "Modernism (late)",
        "notes": "Notre-Dame du Haut, Ronchamp: white-washed concrete vessel with a swelling dark roof. Le Corbusier's late turn from machine to ship.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.30,
        "sequence": [
            {"shape": "cuboid",   "color": "#f4f2ec", "scale": 1.5},
            {"shape": "cuboid",   "color": "#f4f2ec", "scale": 1.3},
            {"shape": "cylinder", "color": "#e8e0d0", "scale": 1.4},
            {"shape": "wedge",    "color": "#3a2818", "scale": 1.7},
        ],
    },
    {
        "id": "mies_seagram",
        "architect": "Mies van der Rohe + Philip Johnson",
        "year": 1958,
        "movement": "International Style",
        "notes": "Seagram Building: bronze-clad I-beams celebrating structure on a granite plaza. The corporate tower as ethics.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.20,
        "sequence": [
            {"shape": "cuboid", "color": "#888888", "scale": 1.6},
            {"shape": "cuboid", "color": "#3a2818", "scale": 1.0},
            {"shape": "cuboid", "color": "#5a3818", "scale": 1.0},
            {"shape": "cuboid", "color": "#3a2818", "scale": 1.0},
            {"shape": "cuboid", "color": "#5a3818", "scale": 1.0},
            {"shape": "cuboid", "color": "#3a2818", "scale": 1.0},
            {"shape": "cuboid", "color": "#5a3818", "scale": 1.0},
            {"shape": "cuboid", "color": "#1a1a1a", "scale": 0.25},
        ],
    },
    {
        "id": "wright_guggenheim_nyc",
        "architect": "Frank Lloyd Wright",
        "year": 1959,
        "movement": "Organic / late modernism",
        "notes": "Guggenheim NYC: a single white spiral inverted on Fifth Avenue. The gallery is the ramp; the ramp is the building.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.30,
        "sequence": [
            {"shape": "cylinder", "color": "#f4f2ec", "scale": 1.0},
            {"shape": "cylinder", "color": "#f4f2ec", "scale": 1.3},
            {"shape": "cylinder", "color": "#f4f2ec", "scale": 1.5},
            {"shape": "cylinder", "color": "#f4f2ec", "scale": 1.7},
            {"shape": "cylinder", "color": "#f4f2ec", "scale": 0.20},
        ],
    },
    {
        "id": "safdie_habitat_67",
        "architect": "Moshe Safdie",
        "year": 1967,
        "movement": "Brutalism / megastructure",
        "notes": "Habitat 67, Montreal: 354 prefab concrete cubes stacked into a city for the Expo. Modular housing as landscape.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.22,
        "sequence": [
            {"shape": "cube", "color": "#d0c8b8", "scale": 1.4},
            {"shape": "cube", "color": "#c8c0a8", "scale": 1.0},
            {"shape": "cube", "color": "#d0c8b8", "scale": 1.5},
            {"shape": "cube", "color": "#b8b098", "scale": 0.9},
            {"shape": "cube", "color": "#d0c8b8", "scale": 1.2},
            {"shape": "cube", "color": "#c8c0a8", "scale": 1.4},
        ],
    },
    {
        "id": "utzon_sydney_opera",
        "architect": "Jørn Utzon",
        "year": 1973,
        "movement": "Expressionist modernism",
        "notes": "Sydney Opera House: white tile shells like sails on a granite podium. The roof IS the building's sign.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.28,
        "sequence": [
            {"shape": "cuboid", "color": "#a89878", "scale": 1.6},
            {"shape": "cuboid", "color": "#888888", "scale": 0.20},
            {"shape": "wedge",  "color": "#f4f2ec", "scale": 1.5},
            {"shape": "wedge",  "color": "#f4f2ec", "scale": 1.3},
            {"shape": "wedge",  "color": "#f4f2ec", "scale": 1.0},
        ],
    },
    {
        "id": "piano_rogers_pompidou",
        "architect": "Renzo Piano + Richard Rogers",
        "year": 1977,
        "movement": "High-tech",
        "notes": "Centre Pompidou: building-as-diagram — structure blue, water green, electricity yellow, circulation red. Inside-out, color-coded.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.18,
        "sequence": [
            {"shape": "cuboid",   "color": "#888888", "scale": 1.4},
            {"shape": "cylinder", "color": "#1f4ecc", "scale": 0.22},
            {"shape": "cuboid",   "color": "#f4f2ec", "scale": 1.4},
            {"shape": "cylinder", "color": "#cc1f1f", "scale": 0.25},
            {"shape": "cuboid",   "color": "#f4f2ec", "scale": 1.4},
            {"shape": "cylinder", "color": "#f0c020", "scale": 0.22},
            {"shape": "cuboid",   "color": "#f4f2ec", "scale": 1.4},
            {"shape": "cylinder", "color": "#1a8848", "scale": 0.22},
        ],
    },
    {
        "id": "gehry_bilbao",
        "architect": "Frank Gehry",
        "year": 1997,
        "movement": "Deconstructivism",
        "notes": "Guggenheim Bilbao: titanium-clad volumes folded along the river. The end of the modernist box; the start of the parametric era.",
        "layout": "vertical_stack",
        "palette": "color_pedagogy",
        "base_scale": 0.24,
        "sequence": [
            {"shape": "cuboid", "color": "#a89878", "scale": 1.4},
            {"shape": "wedge",  "color": "#d0c8b8", "scale": 1.5},
            {"shape": "wedge",  "color": "#bcb8b0", "scale": 1.3},
            {"shape": "wedge",  "color": "#d8d0c0", "scale": 1.2},
            {"shape": "sphere", "color": "#bcb8b0", "scale": 1.0},
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
            "architect": c.get("architect", ""),
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
            "Modern architecture (1909–1997) restaged as primitive_stack totems. "
            "14 buildings where massing + signature element is the lesson: "
            "Prairie, Bauhaus, International Style, Art Deco, Organic, "
            "Brutalism, High-tech, Deconstructivism. Each entry compresses "
            "one building into a stack the engine can bake."
        ),
        "entries": entries,
    }
    (out_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    evals = out_dir / "evals.json"
    if not evals.exists():
        evals.write_text("{}\n", encoding="utf-8")


def merge_into_primitive_stack_gallery(configs: list[dict]) -> None:
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
            "notes": f"[{c.get('architect','')} · {c.get('year','')} · {c.get('movement','')}] {c['notes']}",
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
    ap.add_argument("--no-merge", action="store_true")
    args = ap.parse_args()

    print(f"modern-architecture-gallery: {len(MODERN_ARCH)} entries")
    for c in MODERN_ARCH:
        print(f"  {c['id']:36s} {c['architect'][:28]:28s} ({c.get('year','')}) {c.get('movement','')}")
    print()

    if args.dry:
        return

    godot = _find_godot()
    if not godot:
        print("No Godot found. Set GODOT_EXE.")
        sys.exit(1)

    for c in MODERN_ARCH:
        render_one(godot, c, args.force)
    write_manifest(MODERN_ARCH)
    print(f"\nWrote: ada_encyclopedia/public/{GALLERY_SLUG}/")
    if not args.no_merge:
        merge_into_primitive_stack_gallery(MODERN_ARCH)
    print(f"View:  http://localhost:3003/{GALLERY_SLUG}/<id>.png")
    print(f"       http://localhost:3003/{PS_GALLERY}")


if __name__ == "__main__":
    main()
