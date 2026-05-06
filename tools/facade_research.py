#!/usr/bin/env python
"""
facade_research.py — Batch-render facade-composer presets as gallery artifacts.
Reuses the existing commons/facade_parts/presets/*.json files directly —
each preset IS the DNA. No duplication, no invented configs.

For each preset: load, render via commons/testing/render_facade.gd → PNG,
copy to ada_encyclopedia/public/facade-gallery/<id>.png + paired JSON.
"""
from __future__ import annotations
import argparse, json, os, subprocess, sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
GODOT_EXE = os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
PRESETS_DIR = REPO_ROOT / "commons" / "facade_parts" / "presets"
ENCYCLOPEDIA_DIR = REPO_ROOT.parent / "ada_encyclopedia"
OUTPUT_DIR = ENCYCLOPEDIA_DIR / "public" / "facade-gallery"
STAGE_DIR_NAME = "facade_gallery"

# Curated notes for each preset — shown in gallery cards + modal.
PRESET_NOTES = {
    "classical": "Symmetric 5-bay facade with cornice + piano nobile. The canonical Renaissance composition.",
    "baroque":   "Dynamic rhythm with broken pediments and sculptural detail. 17th-century drama.",
    "gothic_portal": "Pointed arches, tracery, verticality. Cathedral-front composition.",
    "capri_whitewash": "Mediterranean vernacular — small windows, white stucco, flat roof.",
    "florence_marble": "Polychrome marble Renaissance facade. Florentine striping.",
    "florentine_polychrome": "Alternating marble courses in the Giotto tradition.",
    "bernini_colonnade": "Colonnade reaching outward — the piazza's embracing arms.",
    "galleria_vittorio_emanuele": "Milan's 19th-century iron-and-glass gallery arcade.",
    "continuous_monument": "Superstudio's gridded monument — endless rational surface.",
    "decon_fragment": "Deconstructivist fragment — intentional dissonance, tilted planes.",
    "memphis_totem": "Sottsass 1980s postmodern — bright colors, graphic geometry.",
    "naples_diamond_rustication": "Diamond-point rusticated stone, Neapolitan palazzo base.",
    "nyc_tenement": "19th-century tenement fire-escape facade, walk-up rhythm.",
    "painted_vault": "Pompeii-style trompe-l'oeil painted architecture on a flat surface.",
    "pompeii_black_room": "Pompeii Fourth Style — black ground with delicate figures.",
    "pompeii_ceiling_coffers": "Deep-relief coffered ceiling, classical order.",
    "pompeii_ceiling_medallion": "Central painted medallion, radiating panels.",
    "pompeii_fourth_style": "Theatrical fantasy architecture, Pompeii's final wall style.",
    "pompeii_red_room": "Rich red ground, classical architectural framing.",
    "pompeii_second_style": "Illusionistic architecture opening walls into depicted space.",
}


def load_preset(path: Path) -> dict:
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def _find_godot_userdata() -> Path | None:
    appdata = os.environ.get("APPDATA", "")
    if not appdata: return None
    ud = Path(appdata) / "Godot" / "app_userdata"
    if not ud.exists(): return None
    for d in ud.iterdir():
        stage = d / STAGE_DIR_NAME
        if stage.exists(): return stage
    for d in ud.iterdir():
        if "ada" in d.name.lower(): return d / STAGE_DIR_NAME
    return None


def render_one(preset_path: Path, force: bool) -> bool:
    cid = preset_path.stem
    out_png = OUTPUT_DIR / f"{cid}.png"
    out_cfg = OUTPUT_DIR / f"{cid}.json"
    if out_png.exists() and out_cfg.exists() and not force:
        print(f"  skip  {cid}")
        return True
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    # Copy preset JSON as the paired config
    data = load_preset(preset_path)
    out_cfg.write_text(json.dumps(data, indent=2))
    # Point render script at preset via res:// path
    res_cfg = f"res://commons/facade_parts/presets/{preset_path.name}"
    user_out = f"user://{STAGE_DIR_NAME}/{cid}.png"
    args = [
        GODOT_EXE, "--path", str(REPO_ROOT), "--xr-mode", "off", "--no-window",
        "--script", "res://commons/testing/render_facade.gd", "--",
        f"--config={res_cfg}", f"--out={user_out}", "--size=640",
    ]
    print(f"  render {cid} ...")
    proc = subprocess.run(args, capture_output=True, text=True, timeout=180)
    if proc.returncode != 0:
        print(f"    FAILED (rc={proc.returncode})  stderr: {proc.stderr[-400:]}")
        return False
    stage = _find_godot_userdata()
    src = None
    if stage is not None:
        cand = stage / f"{cid}.png"
        if cand.exists(): src = cand
    if src is None:
        print("    rendered but PNG not found")
        return False
    out_png.write_bytes(src.read_bytes())
    print(f"    -> public/facade-gallery/{cid}.png")
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--id", help="Single preset name (no .json)")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    if not PRESETS_DIR.exists():
        print(f"Presets dir not found: {PRESETS_DIR}"); return 1
    presets = sorted(PRESETS_DIR.glob("*.json"))
    if args.id:
        presets = [p for p in presets if p.stem == args.id]
        if not presets: print(f"No preset {args.id}"); return 1
    print(f"Facade: {len(presets)} presets -> {OUTPUT_DIR}")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    ok, fail = [], []
    for p in presets:
        (ok if render_one(p, args.force) else fail).append(p.stem)

    # Manifest
    entries = []
    for p in sorted(PRESETS_DIR.glob("*.json")):
        cid = p.stem
        png = OUTPUT_DIR / f"{cid}.png"
        if not png.exists(): continue
        data = load_preset(p)
        # Extract some facade metadata for filter pills
        facade = data.get("facade", {})
        entries.append({
            "id": cid,
            "notes": PRESET_NOTES.get(cid, ""),
            "bays": int(facade.get("bays", 0)) if facade else 0,
            "stories": int(facade.get("stories", 0)) if facade else 0,
            "style": cid.split("_")[0],  # rough style grouping
            "image": f"/facade-gallery/{cid}.png",
            "config": f"/facade-gallery/{cid}.json",
        })
    manifest = {
        "version": 1,
        "description": "Facade research — 26 Italian/classical facade presets rendered as gallery artifacts. Each preset IS the DNA (bays, stories, zones, materials, parts). Reuses commons/facade_parts/FacadeComposer directly.",
        "entries": entries,
    }
    (OUTPUT_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2))
    print(f"\nManifest: {len(entries)} entries   OK: {len(ok)}  Fail: {len(fail)}")
    if fail:
        for f in fail: print(f"  - {f}")
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
