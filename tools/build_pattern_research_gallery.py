#!/usr/bin/env python3
"""
build_pattern_research_gallery.py
==================================

Auto-research pass on the off-spine patterngeneration sequence
(commons/maps/sequences/patterngeneration.json — "Shaders & Patterns:
The Book of Shaders"). Every algorithm subdirectory in
algorithms/patterngeneration/ has an existing .tscn scene that animates
itself; this builder instantiates each, lets it run for a few seconds,
then snapshots a PNG.

Patterns covered:
  animalpatterns          — leopard / tiger / zebra shader skins
  diffusion_limited_aggregation — DLA fractal dendrite (Brownian)
  fabrics                 — woven textile shader
  glassdivider            — glass partition pattern
  gridscheckers           — checkerboard variants
  penrose_tilings         — aperiodic 5-fold (kite + dart subdivision)
  reactiondiffusion       — Gray-Scott Turing patterns
  truchettiles            — Smith-Truchet field
  waves                   — caustic wave / cat-water

Each entry runs the SAME scene with a different `wait` to capture
different evolution states (e.g. DLA at t=2s vs t=15s).

Run:
    python tools/build_pattern_research_gallery.py
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
GALLERY_SLUG = "pattern-research-gallery"
PS_GALLERY = "primitive-stack-gallery"
STAGING_DIR = REPO / "commons" / "primitive_grammar" / "_staging"
RENDER_GD = "res://commons/testing/render_pattern_specimen.gd"


# Each entry: id, scene path, camera mode, look_at, distance, wait, notes.
ENTRIES = [
    # ── Penrose tilings (aperiodic, kite + dart subdivision) ─────
    {"id": "penrose_iter_1",
     "scene": "res://algorithms/patterngeneration/penrose_tilings/penrose_tilings.tscn",
     "camera": "top", "distance": 12.0, "wait": 5.5,
     "notes": "Penrose tiling at iteration ~1 — large kites and darts before the first subdivision passes."},
    {"id": "penrose_iter_3",
     "scene": "res://algorithms/patterngeneration/penrose_tilings/penrose_tilings.tscn",
     "camera": "top", "distance": 12.0, "wait": 13.0,
     "notes": "Penrose at ~iter 3 — five-fold symmetric pattern emerging through repeated subdivision."},
    {"id": "penrose_iter_5",
     "scene": "res://algorithms/patterngeneration/penrose_tilings/penrose_tilings.tscn",
     "camera": "top", "distance": 12.0, "wait": 22.0,
     "notes": "Penrose at full depth — aperiodic order with no translational repeat. Roger Penrose 1974."},

    # ── DLA dendrites (Brownian growth) ──────────────────────────
    {"id": "dla_early",
     "scene": "res://algorithms/patterngeneration/diffusion_limited_aggregation/diffusion_limited_aggregation.tscn",
     "camera": "top", "distance": 14.0, "wait": 6.0,
     "notes": "DLA at early growth — sparse seed crystal, walkers still finding the aggregate."},
    {"id": "dla_mid",
     "scene": "res://algorithms/patterngeneration/diffusion_limited_aggregation/diffusion_limited_aggregation.tscn",
     "camera": "top", "distance": 14.0, "wait": 15.0,
     "notes": "DLA mid-growth — branching dendrite forming. Same physics as frost crystals + lightning."},
    {"id": "dla_dense",
     "scene": "res://algorithms/patterngeneration/diffusion_limited_aggregation/diffusion_limited_aggregation.tscn",
     "camera": "top", "distance": 14.0, "wait": 26.0,
     "notes": "DLA dense — fractal dimension ≈ 1.71. Turing-class morphogenesis: the fractal dimension comes from the sticking_radius."},

    # ── Animal patterns (shader-based skins) ─────────────────────
    {"id": "animal_leopard",
     "scene": "res://algorithms/patterngeneration/animalpatterns/animalpatterns.tscn",
     "camera": "front", "distance": 4.0, "wait": 5.0,
     "notes": "Animal patterns shader — leopard / tiger / zebra / dalmatian / snake skins on plane meshes."},

    # ── Reaction-diffusion (already in rd-gallery, but the tscn variant) ─
    {"id": "rd_grayscott",
     "scene": "res://algorithms/patterngeneration/reactiondiffusion/reaction_diffusion.tscn",
     "camera": "front", "distance": 5.0, "wait": 10.0,
     "notes": "Gray-Scott RD — 3D surface reaction-diffusion with VR controls. Turing patterns on a plane."},

    # ── Truchet (already in truchet-grid-gallery, but the live scene) ─
    {"id": "truchet_live",
     "scene": "res://algorithms/patterngeneration/truchettiles/truchettiles.tscn",
     "camera": "top", "distance": 8.0, "wait": 5.0,
     "notes": "Truchet tile field — the live shader/scene version. Every cell rotated 0/90°; curves emerge."},

    # ── Waves (caustic / cat-water) ──────────────────────────────
    {"id": "waves_caustic",
     "scene": "res://algorithms/patterngeneration/waves/catwater.tscn",
     "camera": "oblique", "distance": 6.0, "wait": 6.0,
     "notes": "Caustic-water wave shader — 'catwater' interference pattern. Light through rippling surface."},

    # ── Fabrics (textile) ─────────────────────────────────────────
    {"id": "fabrics_weave",
     "scene": "res://algorithms/patterngeneration/fabrics/fabrics.tscn",
     "camera": "front", "distance": 4.0, "wait": 5.0,
     "notes": "Textile / weave shader — warp + weft procedural pattern."},

    # ── Glass divider ─────────────────────────────────────────────
    {"id": "glass_divider",
     "scene": "res://algorithms/patterngeneration/glassdivider/glassdivider.tscn",
     "camera": "front", "distance": 4.5, "wait": 5.0,
     "notes": "Glass partition shader — translucent geometric divider pattern."},

    # ── Grid checkers ─────────────────────────────────────────────
    {"id": "grid_checkers",
     "scene": "res://algorithms/patterngeneration/gridscheckers/gridscheckers.tscn",
     "camera": "top", "distance": 7.0, "wait": 4.5,
     "notes": "Checkerboard variants — the simplest 2-tone grid. UV mod-2 coloring."},
]


def render_one(godot: str, entry: dict, force: bool) -> bool:
    cid = entry["id"]
    out_dir = ENC / "public" / GALLERY_SLUG
    out_dir.mkdir(parents=True, exist_ok=True)
    out_png = out_dir / f"{cid}.png"
    out_cfg = out_dir / f"{cid}.json"
    if out_png.exists() and out_cfg.exists() and not force:
        print(f"    skip   {cid}")
        return True

    out_cfg.write_text(json.dumps(entry, indent=2) + "\n", encoding="utf-8")

    STAGING_DIR.mkdir(parents=True, exist_ok=True)
    cfg_for_render = {
        "id": cid,
        "scene": entry["scene"],
        "camera": entry.get("camera", "oblique"),
        "distance": entry.get("distance", 8.0),
        "look_at": entry.get("look_at", [0, 0, 0]),
        "fov": entry.get("fov", 42.0),
        "wait": entry.get("wait", 6.0),
    }
    cfg_staging = STAGING_DIR / f"{cid}.json"
    cfg_staging.write_text(json.dumps(cfg_for_render, indent=2), encoding="utf-8")

    user_out = f"user://pattern_gallery/{cid}.png"
    res_cfg = f"res://commons/primitive_grammar/_staging/{cid}.json"
    cmd = [
        godot, "--path", str(REPO), "--xr-mode", "off",
        "--script", "res://commons/testing/render_pattern_specimen.gd", "--",
        f"--config={res_cfg}", f"--out={user_out}", "--size=800",
    ]
    print(f"    render {cid:30s} (wait={entry.get('wait', 6.0)}s) ", end="", flush=True)
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        print("TIMEOUT"); return False
    if proc.returncode != 0:
        print(f"FAIL rc={proc.returncode}")
        if proc.stderr:
            print(f"      stderr: {proc.stderr[-300:]}")
        return False

    appdata = os.environ.get("APPDATA", "")
    if not appdata:
        print("no APPDATA"); return False
    ud = Path(appdata) / "Godot" / "app_userdata"
    src = None
    if ud.exists():
        for d in ud.iterdir():
            cand = d / "pattern_gallery" / f"{cid}.png"
            if cand.exists():
                src = cand; break
    if src is None:
        print("no PNG produced"); return False
    shutil.copy2(src, out_png)
    print(f"OK ({src.stat().st_size // 1024} KB)")
    return True


def write_manifest():
    out_dir = ENC / "public" / GALLERY_SLUG
    rows = []
    for e in ENTRIES:
        rows.append({
            "id": e["id"],
            "scene": e["scene"],
            "camera": e.get("camera", "oblique"),
            "wait": e.get("wait", 6.0),
            "notes": e["notes"],
            "image": f"/{GALLERY_SLUG}/{e['id']}.png",
            "config": f"/{GALLERY_SLUG}/{e['id']}.json",
        })
    manifest = {
        "schema_version": 1, "version": 1,
        "description": (
            "Off-spine patterngeneration sequence ('Shaders & Patterns: "
            "The Book of Shaders'). Each entry instantiates an algorithm's "
            ".tscn scene from algorithms/patterngeneration/<name>/, lets "
            "it animate for N seconds, snapshots. Multiple entries per "
            "scene capture different evolution states (DLA at 6s vs 26s, "
            "Penrose at iter 1 vs 5)."
        ),
        "entries": rows,
    }
    (out_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    evals = out_dir / "evals.json"
    if not evals.exists():
        evals.write_text("{}\n", encoding="utf-8")


def merge_into_master():
    src_dir = ENC / "public" / GALLERY_SLUG
    dst_dir = ENC / "public" / PS_GALLERY
    if not (dst_dir / "manifest.json").exists(): return
    for e in ENTRIES:
        for ext in (".png", ".json"):
            sp = src_dir / (e["id"] + ext)
            if sp.exists(): shutil.copy2(sp, dst_dir / (e["id"] + ext))
    m = json.loads((dst_dir / "manifest.json").read_text(encoding="utf-8"))
    existing = {x["id"] for x in m["entries"]}
    added = 0
    for e in ENTRIES:
        if e["id"] in existing: continue
        m["entries"].append({
            "id": e["id"],
            "notes": f"[pattern-research] {e['notes']}",
            "layout": "pattern_specimen",
            "image": f"/{PS_GALLERY}/{e['id']}.png",
            "config": f"/{PS_GALLERY}/{e['id']}.json",
        })
        added += 1
    (dst_dir / "manifest.json").write_text(json.dumps(m, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"  merged into /{PS_GALLERY}/: +{added}")


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dry", action="store_true")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--no-merge", action="store_true")
    args = ap.parse_args()

    print(f"pattern-research-gallery: {len(ENTRIES)} entries")
    for e in ENTRIES:
        print(f"  - {e['id']:30s} scene={e['scene'].split('/')[-1]:35s} wait={e.get('wait',6.0)}s")
    print()
    if args.dry: return

    godot = _find_godot()
    if not godot:
        print("No Godot."); sys.exit(1)

    for e in ENTRIES:
        render_one(godot, e, args.force)
    write_manifest()
    if not args.no_merge:
        merge_into_master()
    print(f"\nGallery: http://localhost:3003/{GALLERY_SLUG}")


if __name__ == "__main__":
    main()
