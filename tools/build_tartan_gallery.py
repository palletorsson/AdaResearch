#!/usr/bin/env python3
"""
build_tartan_gallery.py
========================

A tartan-research-gallery — one card per Scottish-clan / Pride palette,
each rendered through commons/resourses/shaders/tartanshader.gdshader on
a single 2m cube. Palettes lifted from algorithms/misc/tartan_grid_3d.gd.

Outputs:
  ada_encyclopedia/public/tartan-gallery/<id>.{png,json}
  ada_encyclopedia/public/tartan-gallery/manifest.json
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
from measure_artifact_aabbs import _find_godot

ENC = REPO.parent / "ada_encyclopedia"
GALLERY_SLUG = "tartan-gallery"
PS_GALLERY = "primitive-stack-gallery"
STAGING_DIR = REPO / "commons" / "primitive_grammar" / "_staging"


# Color values from algorithms/misc/tartan_grid_3d.gd, converted to hex.
PALETTES = [
    # ── Scottish clans ──────────────────────────────────────────
    {"id": "tartan_royal_stewart", "name": "Royal Stewart", "family": "Clan",
     "colors": ["#ff0000", "#0000ff", "#00ff00", "#ffff00"],
     "brightness": 1.4, "saturation": 2.0,
     "notes": "The most recognized tartan worldwide — bold red ground with blue, green, yellow stripes. Worn by the Royal Family."},
    {"id": "tartan_black_watch", "name": "Black Watch", "family": "Clan",
     "colors": ["#004ccc", "#008033", "#1a1a1a", "#ffffff"],
     "brightness": 1.2, "saturation": 1.6,
     "notes": "The 'Black' Watch regimental tartan — dark blue + green grid on near-black, with a white sett. 1739."},
    {"id": "tartan_gordon", "name": "Gordon", "family": "Clan",
     "colors": ["#009933", "#0033cc", "#000000", "#ffff00"],
     "brightness": 1.3, "saturation": 1.8,
     "notes": "Gordon clan — green and blue stripes on black, with a yellow over-stripe. Highland Aberdeenshire."},
    {"id": "tartan_macleod", "name": "MacLeod", "family": "Clan",
     "colors": ["#ffff00", "#000000", "#ff0000", "#ffffff"],
     "brightness": 1.5, "saturation": 2.2,
     "notes": "MacLeod 'Loud Tartan' — yellow ground, black + red stripes. Among the most visually striking clan tartans."},
    {"id": "tartan_campbell", "name": "Campbell", "family": "Clan",
     "colors": ["#00801a", "#0050b3", "#000000", "#ffffff"],
     "brightness": 1.3, "saturation": 1.7,
     "notes": "Campbell of Argyll — closely related to Black Watch (the Campbell-led regiment). Green + blue dominant."},
    {"id": "tartan_mackenzie", "name": "MacKenzie", "family": "Clan",
     "colors": ["#006633", "#cc0000", "#003399", "#000000"],
     "brightness": 1.4, "saturation": 1.9,
     "notes": "MacKenzie clan — green + red over a dark blue/black ground."},
    {"id": "tartan_fraser", "name": "Fraser", "family": "Clan",
     "colors": ["#ff0000", "#00804d", "#0050cc", "#ffffff"],
     "brightness": 1.3, "saturation": 1.8,
     "notes": "Fraser of Lovat — the Outlander tartan. Red, green, blue, and a white over-stripe."},
    {"id": "tartan_macdonald", "name": "MacDonald", "family": "Clan",
     "colors": ["#00991a", "#ff0000", "#000000", "#0066cc"],
     "brightness": 1.4, "saturation": 2.0,
     "notes": "MacDonald (clan Donald) — the largest Scottish clan. Green ground with red, black, and blue."},
    {"id": "tartan_wallace", "name": "Wallace", "family": "Clan",
     "colors": ["#ffff00", "#ff0000", "#000000", "#ffffff"],
     "brightness": 1.5, "saturation": 2.1,
     "notes": "Wallace clan — yellow + red on black with white. Named for William Wallace; high-contrast battle palette."},
    {"id": "tartan_scott", "name": "Scott", "family": "Clan",
     "colors": ["#ff0000", "#008033", "#000000", "#ffffff"],
     "brightness": 1.3, "saturation": 1.7,
     "notes": "Scott clan — Borders region. Red + green check on black with white over-stripes."},

    # ── Pride flags as tartan ───────────────────────────────────
    {"id": "tartan_pride_rainbow", "name": "Pride Rainbow", "family": "Pride",
     "colors": ["#ff0000", "#ff8000", "#ffff00", "#00cc00"],
     "brightness": 1.6, "saturation": 2.5,
     "notes": "Pride rainbow recoded as tartan — the 6-color flag becomes a woven sett."},
    {"id": "tartan_trans_pride", "name": "Trans Pride", "family": "Pride",
     "colors": ["#56cffa", "#f5a9cf", "#ffffff", "#f5a9cf"],
     "brightness": 1.4, "saturation": 1.8,
     "notes": "Trans Pride flag (Helms 1999) — pale blue, pink, white. Gentle alternation as woven plaid."},
    {"id": "tartan_lesbian_pride", "name": "Lesbian Pride", "family": "Pride",
     "colors": ["#d6262e", "#ff6b2e", "#ffffff", "#d66bea"],
     "brightness": 1.5, "saturation": 2.0,
     "notes": "Lesbian Pride — orange-to-magenta gradient + white. Tartan structure makes the colors pop."},
    {"id": "tartan_bi_pride", "name": "Bi Pride", "family": "Pride",
     "colors": ["#d62691", "#9f59b5", "#0052d1"],
     "brightness": 1.4, "saturation": 2.2,
     "notes": "Bi Pride flag — magenta, purple, blue. Three-color sett (the missing 4th repeats the dominant)."},
    {"id": "tartan_pan_pride", "name": "Pan Pride", "family": "Pride",
     "colors": ["#ff2187", "#ffd900", "#21ABFF"],
     "brightness": 1.5, "saturation": 2.3,
     "notes": "Pan Pride — magenta, yellow, cyan. The brightest of the Pride tartans."},
    {"id": "tartan_non_binary", "name": "Non-Binary", "family": "Pride",
     "colors": ["#ffff00", "#ffffff", "#9c59b5", "#000000"],
     "brightness": 1.3, "saturation": 1.9,
     "notes": "Non-Binary Pride flag — yellow, white, purple, black. Strong palette contrast in the weave."},
]


def render_one(godot: str, p: dict, force: bool) -> bool:
    cid = p["id"]
    out_dir = ENC / "public" / GALLERY_SLUG
    out_dir.mkdir(parents=True, exist_ok=True)
    out_png = out_dir / f"{cid}.png"
    out_cfg = out_dir / f"{cid}.json"
    if out_png.exists() and out_cfg.exists() and not force:
        return True

    out_cfg.write_text(json.dumps(p, indent=2) + "\n", encoding="utf-8")
    STAGING_DIR.mkdir(parents=True, exist_ok=True)
    # Pass neutral 1.0 for brightness/saturation/contrast — the shader's
    # boost-functions overflow color channels and pastelize the output.
    # Render the literal palette; the colors already have authored impact.
    cfg_for_render = {
        "colors": p["colors"],
        "brightness": 1.0,
        "saturation": 1.0,
        "contrast": 1.0,
        "seed": hash(p["id"]) & 0xffff,
    }
    cfg_staging = STAGING_DIR / f"{cid}.json"
    cfg_staging.write_text(json.dumps(cfg_for_render, indent=2), encoding="utf-8")

    user_out = f"user://tartan/{cid}.png"
    res_cfg = f"res://commons/primitive_grammar/_staging/{cid}.json"
    cmd = [
        godot, "--path", str(REPO), "--xr-mode", "off",
        "--script", "res://commons/testing/render_tartan_specimen.gd", "--",
        f"--config={res_cfg}", f"--out={user_out}",
    ]
    print(f"  render {cid:32s} ", end="", flush=True)
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    if proc.returncode != 0:
        print(f"FAIL rc={proc.returncode}")
        if proc.stderr: print(f"    stderr: {proc.stderr[-300:]}")
        return False

    appdata = os.environ.get("APPDATA", "")
    ud = Path(appdata) / "Godot" / "app_userdata" if appdata else None
    src = None
    if ud and ud.exists():
        for d in ud.iterdir():
            cand = d / "tartan" / f"{cid}.png"
            if cand.exists():
                src = cand; break
    if src is None:
        print("no PNG"); return False
    shutil.copy2(src, out_png)
    print(f"OK ({src.stat().st_size//1024} KB)")
    return True


def write_manifest():
    out_dir = ENC / "public" / GALLERY_SLUG
    rows = []
    for p in PALETTES:
        rows.append({
            "id": p["id"],
            "name": p["name"],
            "family": p["family"],
            "n_colors": len(p["colors"]),
            "notes": p["notes"],
            "image": f"/{GALLERY_SLUG}/{p['id']}.png",
            "config": f"/{GALLERY_SLUG}/{p['id']}.json",
        })
    manifest = {
        "schema_version": 1, "version": 1,
        "description": (
            "Tartan setts — Scottish clan tartans + Pride flags rendered "
            "through commons/resourses/shaders/tartanshader.gdshader on a "
            "2m cube. Palettes lifted from algorithms/misc/tartan_grid_3d.gd. "
            "Tartan = orthogonal woven stripes; the same shader paints the "
            "weave for any 4-color palette."
        ),
        "entries": rows,
    }
    (out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    evals = out_dir / "evals.json"
    if not evals.exists():
        evals.write_text("{}\n", encoding="utf-8")


def merge_into_master():
    src = ENC / "public" / GALLERY_SLUG
    dst = ENC / "public" / PS_GALLERY
    if not (dst / "manifest.json").exists(): return
    for p in PALETTES:
        for ext in (".png", ".json"):
            sp = src / (p["id"] + ext)
            if sp.exists(): shutil.copy2(sp, dst / (p["id"] + ext))
    m = json.loads((dst / "manifest.json").read_text(encoding="utf-8"))
    existing = {x["id"] for x in m["entries"]}
    added = 0
    for p in PALETTES:
        if p["id"] in existing: continue
        m["entries"].append({
            "id": p["id"],
            "notes": f"[tartan] {p['name']} ({p['family']}) — {p['notes']}",
            "layout": "tartan_specimen",
            "image": f"/{PS_GALLERY}/{p['id']}.png",
            "config": f"/{PS_GALLERY}/{p['id']}.json",
        })
        added += 1
    (dst / "manifest.json").write_text(json.dumps(m, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"  merged into /{PS_GALLERY}/: +{added}")


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    godot = _find_godot()
    if not godot:
        print("No Godot."); sys.exit(1)
    print(f"Tartan gallery: {len(PALETTES)} palettes")
    for p in PALETTES:
        render_one(godot, p, args.force)
    write_manifest()
    merge_into_master()
    print(f"\nGallery: http://localhost:3003/{GALLERY_SLUG}")


if __name__ == "__main__":
    main()
