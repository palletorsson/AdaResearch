#!/usr/bin/env python3
"""
build_modern_canon_showcase_map.py
===================================

Builds Modern_Canon_Showcase — three rows of 14 totems each:
  Front (z=2)  Modern art canon       (Malevich → Kandinsky)
  Mid   (z=6)  Modern design canon    (Breuer → Colombo)
  Back  (z=10) Modern architecture    (Wright → Gehry)

Steps:
  1. Copy each gallery's <entry>.json into the bake-pipeline's
     best_of/configs/ as <gallery>__<entry>.json so the wrapper can
     find it.
  2. Bake every config to a PackedScene via bake_artifact.gd.
  3. Place all 42 prebaked totems with one empty cube between each
     so they read individually. base_scale targets ~1m per artifact.
  4. Multi-angle capture.
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
MAP_NAME = "Modern_Canon_Showcase"
MAP_DIR = REPO / "commons" / "maps" / MAP_NAME

BEST_OF_CONFIGS = REPO / "commons" / "generated" / "gallery_best_of" / "configs"
BEST_OF_SCENES  = REPO / "commons" / "generated" / "gallery_best_of" / "scenes"
BAKE_GD = "res://commons/testing/bake_artifact.gd"
WRAPPER = "res://commons/artifacts/composition_artifact/composition_artifact.tscn"

# Each entry is (gallery_slug, entry_id, label).
ART = [
    ("modern-art-gallery", "malevich_black_square",     "Malevich: Black Square (1915)"),
    ("modern-art-gallery", "mondrian_de_stijl",         "Mondrian: De Stijl (1930)"),
    ("modern-art-gallery", "albers_homage_warm",        "Albers: Homage to the Square"),
    ("modern-art-gallery", "rothko_chromatic_field",    "Rothko: chromatic field"),
    ("modern-art-gallery", "newman_zip",                "Newman: zip"),
    ("modern-art-gallery", "klein_ikb_monochrome",      "Klein: IKB monochrome"),
    ("modern-art-gallery", "kelly_hard_edge",           "Kelly: hard-edge"),
    ("modern-art-gallery", "stella_concentric_stripes", "Stella: stripes"),
    ("modern-art-gallery", "judd_minimalist_stack",     "Judd: stack"),
    ("modern-art-gallery", "lewitt_modular_cube",       "LeWitt: modular cube"),
    ("modern-art-gallery", "flavin_fluorescent_pair",   "Flavin: fluorescent"),
    ("modern-art-gallery", "riley_op_alternation",      "Riley: Op art"),
    ("modern-art-gallery", "calder_mobile_primaries",   "Calder: mobile primaries"),
    ("modern-art-gallery", "kandinsky_bauhaus_triad",   "Kandinsky: Bauhaus triad"),
]

DESIGN = [
    ("modern-design-gallery", "breuer_wassily_b3",            "Breuer: Wassily Chair (1925)"),
    ("modern-design-gallery", "lecorbusier_lc4_chaise",       "LC4 Chaise (1928)"),
    ("modern-design-gallery", "aalto_paimio_41",              "Aalto: Paimio (1932)"),
    ("modern-design-gallery", "saarinen_tulip_pedestal",      "Saarinen: Tulip (1957)"),
    ("modern-design-gallery", "eames_lcw_plywood",            "Eames: LCW (1946)"),
    ("modern-design-gallery", "bertoia_diamond",              "Bertoia: Diamond (1952)"),
    ("modern-design-gallery", "panton_s_curve",               "Panton (1967)"),
    ("modern-design-gallery", "castiglioni_arco",             "Castiglioni: Arco (1962)"),
    ("modern-design-gallery", "sapper_tizio",                 "Sapper: Tizio (1972)"),
    ("modern-design-gallery", "sottsass_carlton_memphis",     "Sottsass: Carlton (1981)"),
    ("modern-design-gallery", "sottsass_valentine_typewriter","Olivetti: Valentine (1969)"),
    ("modern-design-gallery", "wegner_round_chair",           "Wegner: Round Chair (1949)"),
    ("modern-design-gallery", "rietveld_red_blue_chair",      "Rietveld: Red/Blue (1923)"),
    ("modern-design-gallery", "colombo_boby_trolley",         "Colombo: Boby (1970)"),
]

ARCH = [
    ("modern-architecture-gallery", "wright_robie_house",          "Wright: Robie (1909)"),
    ("modern-architecture-gallery", "gropius_bauhaus_dessau",      "Gropius: Bauhaus Dessau (1926)"),
    ("modern-architecture-gallery", "mies_barcelona_pavilion",     "Mies: Barcelona Pavilion (1929)"),
    ("modern-architecture-gallery", "van_alen_chrysler",           "Van Alen: Chrysler (1930)"),
    ("modern-architecture-gallery", "lecorbusier_villa_savoye",    "Le Corbusier: Villa Savoye (1931)"),
    ("modern-architecture-gallery", "wright_fallingwater",         "Wright: Fallingwater (1935)"),
    ("modern-architecture-gallery", "mies_farnsworth",             "Mies: Farnsworth (1951)"),
    ("modern-architecture-gallery", "lecorbusier_ronchamp",        "Ronchamp (1955)"),
    ("modern-architecture-gallery", "mies_seagram",                "Mies: Seagram (1958)"),
    ("modern-architecture-gallery", "wright_guggenheim_nyc",       "Wright: Guggenheim NYC (1959)"),
    ("modern-architecture-gallery", "safdie_habitat_67",           "Safdie: Habitat 67"),
    ("modern-architecture-gallery", "utzon_sydney_opera",          "Utzon: Sydney Opera (1973)"),
    ("modern-architecture-gallery", "piano_rogers_pompidou",       "Piano/Rogers: Pompidou (1977)"),
    ("modern-architecture-gallery", "gehry_bilbao",                "Gehry: Bilbao (1997)"),
]


def stage_configs(rows: list[list[tuple]]) -> int:
    """Copy gallery <entry>.json files to best_of/configs/ as
    <gallery>__<entry>.json so the bake pipeline can find them."""
    BEST_OF_CONFIGS.mkdir(parents=True, exist_ok=True)
    n = 0
    for row in rows:
        for gallery, entry_id, _ in row:
            src = ENC / "public" / gallery / f"{entry_id}.json"
            if not src.exists():
                print(f"  MISSING: {src}")
                continue
            dst = BEST_OF_CONFIGS / f"{gallery}__{entry_id}.json"
            shutil.copy2(src, dst)
            n += 1
    return n


def bake_all(godot: str, rows: list[list[tuple]], force: bool) -> int:
    BEST_OF_SCENES.mkdir(parents=True, exist_ok=True)
    ok = 0
    for row in rows:
        for gallery, entry_id, _ in row:
            out_path = BEST_OF_SCENES / f"{gallery}__{entry_id}.tscn"
            if out_path.exists() and not force:
                ok += 1
                continue
            params = {
                "config_path": f"res://commons/generated/gallery_best_of/configs/{gallery}__{entry_id}.json",
                "grammar": "primitive_stack",
                "vr_preview": False,
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

    rows = [ART, DESIGN, ARCH]

    print("Stage configs into best_of/configs/ ...")
    n = stage_configs(rows)
    print(f"  staged {n} configs\n")

    godot = _find_godot()
    if not godot:
        print("No Godot found. Set GODOT_EXE.")
        sys.exit(1)

    if not args.no_bake:
        print("Bake configs to .tscn ...")
        ok = bake_all(godot, rows, args.force)
        print(f"  baked {ok}/{n}\n")

    # ── Build map. 14 totems × 2 (one cube between) = 27 + 2 edges = 29 cols.
    #   z=2 art, z=6 design, z=10 architecture.
    rows_n, cols = 14, 29
    structure = [["1" for _ in range(cols)] for _ in range(rows_n)]
    utilities = [[" " for _ in range(cols)] for _ in range(rows_n)]
    interactables = [[" " for _ in range(cols)] for _ in range(rows_n)]

    # Spawn south-center, teleporter north-center.
    utilities[0][cols // 2] = "sp"
    utilities[rows_n - 1][cols // 2] = "t"

    # Base ~1m: primitive_stack base_scale ≈ 0.25 → multiply by 4.0.
    BASE_SCALE = 4.0

    layout = [(2, ART), (6, DESIGN), (10, ARCH)]
    for z, items in layout:
        for i, (gallery, eid, label) in enumerate(items):
            c = 1 + i * 2  # columns 1, 3, 5, ..., 27
            artifact, params, mode = resolve(gallery, eid)
            if artifact == "prebaked_loader":
                params["scale"] = BASE_SCALE
            interactables[z][c] = make_token(artifact, params)
            print(f"  z={z:2d} c={c:2d}  {label:42s} -> {mode:8s}")

    md = {
        "map_info": {
            "name": MAP_NAME, "lookup_name": MAP_NAME,
            "description": (
                "Modern Canon Showcase — 42 totems across three rows: art, "
                "design, architecture. Each is a primitive_stack composition "
                "baked from the curated gallery findings. Walk south to north "
                "to traverse the modern century."
            ),
            "format": "json", "version": "1.0",
            "dimensions": {"width": cols, "depth": rows_n, "max_height": 5},
            "metadata": {
                "source": "build_modern_canon_showcase_map.py",
                "art_count": len(ART),
                "design_count": len(DESIGN),
                "arch_count": len(ARCH),
                "base_scale": BASE_SCALE,
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
        f"# {MAP_NAME}\n\n42 modern-canon totems across three rows "
        f"(art / design / architecture), one cube between each. "
        f"Baked from /dna and placed via prebaked_loader.\n",
        encoding="utf-8")
    print(f"\nWrote: commons/maps/{MAP_NAME}/")
    print(f"Three.js: http://localhost:3003/map-3d/{MAP_NAME}\n")

    if args.no_godot: return

    flags_path = REPO / "ada_run" / "runtime_flags.json"
    flags_path.parent.mkdir(parents=True, exist_ok=True)
    flags_path.write_text(json.dumps({
        "biome_enabled": False,
        "artifacts_enabled": True,
        "_capture_active": True,
        "_note": "modern canon showcase capture",
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
        if proc.stderr:
            print(proc.stderr.decode("utf-8", errors="ignore")[-400:])
        return
    pngs = sorted((cap_out / MAP_NAME).glob("*.png"))
    print(f"\nRendered {len(pngs)} angles:")
    for p in pngs:
        print(f"  {p.stat().st_size//1024:5d} KB  http://localhost:3003/captures/maps/{MAP_NAME}/{p.name}")


if __name__ == "__main__":
    main()
