#!/usr/bin/env python
"""
Capture the Form Gallery — renders each curated config in
commons/morphology/gallery_configs.json to a PNG.

Output:
  ada_encyclopedia/public/form-gallery/<id>.png
  ada_encyclopedia/public/form-gallery/manifest.json

Usage:
  python tools/capture_form_gallery.py               # all configs
  python tools/capture_form_gallery.py --id flower_classic   # single
  python tools/capture_form_gallery.py --force       # overwrite existing
"""
from __future__ import annotations
import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
GODOT_EXE = os.environ.get(
    "GODOT_EXE",
    "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe",
)
CONFIG_PATH = REPO_ROOT / "commons" / "morphology" / "gallery_configs.json"
ENCYCLOPEDIA_DIR = REPO_ROOT.parent / "ada_encyclopedia"
OUTPUT_DIR = ENCYCLOPEDIA_DIR / "public" / "form-gallery"


def render_one(cfg: dict, force: bool) -> bool:
    cfg_id = cfg["id"]
    out_path = OUTPUT_DIR / f"{cfg_id}.png"
    if out_path.exists() and not force:
        print(f"  skip {cfg_id} (exists)")
        return True
    out_path.parent.mkdir(parents=True, exist_ok=True)
    dna_json = json.dumps(cfg.get("dna", {}), separators=(",", ":"))
    out_godot = f"res://../ada_encyclopedia/public/form-gallery/{cfg_id}.png"
    # Use user:// path then move — safer across filesystems
    out_user = f"user://form_gallery/{cfg_id}.png"

    args = [
        GODOT_EXE,
        "--path", str(REPO_ROOT),
        "--xr-mode", "off",
        "--no-window",
        "--script", "res://commons/testing/render_form.gd",
        "--",
        f"--recipe={cfg['recipe']}",
        f"--dna={dna_json}",
        f"--materials={cfg.get('materials', 'neutral')}",
        f"--out={out_user}",
        "--size=640",
    ]
    print(f"  render {cfg_id} ...")
    proc = subprocess.run(args, capture_output=True, text=True, timeout=90)
    if proc.returncode != 0:
        print(f"    FAILED (rc={proc.returncode})")
        print(f"    stderr: {proc.stderr[-500:]}")
        return False
    # Locate the user:// file on disk (Godot's per-project user dir)
    # On Windows: %APPDATA%/Godot/app_userdata/<ProjectName>/form_gallery/<id>.png
    candidates = [
        Path(os.environ.get("APPDATA", "")) / "Godot" / "app_userdata" / "AdaResearch" / "form_gallery" / f"{cfg_id}.png",
        Path(os.environ.get("APPDATA", "")) / "Godot" / "app_userdata" / "AdaResearch_46" / "form_gallery" / f"{cfg_id}.png",
        Path(os.environ.get("APPDATA", "")) / "Godot" / "app_userdata" / "Ada Research" / "form_gallery" / f"{cfg_id}.png",
    ]
    src = next((c for c in candidates if c.exists()), None)
    if src is None:
        # Also scan app_userdata for any form_gallery dir
        appdata_ud = Path(os.environ.get("APPDATA", "")) / "Godot" / "app_userdata"
        if appdata_ud.exists():
            for d in appdata_ud.iterdir():
                candidate = d / "form_gallery" / f"{cfg_id}.png"
                if candidate.exists():
                    src = candidate
                    break
    if src is None:
        print(f"    rendered but file not found in user://")
        return False
    out_path.write_bytes(src.read_bytes())
    print(f"    -> {out_path.relative_to(REPO_ROOT.parent)}")
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--id", help="Render a single config by id")
    parser.add_argument("--force", action="store_true", help="Overwrite existing PNGs")
    args = parser.parse_args()

    if not CONFIG_PATH.exists():
        print(f"Config not found: {CONFIG_PATH}")
        return 1
    data = json.loads(CONFIG_PATH.read_text())
    configs = data["configs"]
    if args.id:
        configs = [c for c in configs if c["id"] == args.id]
        if not configs:
            print(f"No config with id={args.id}")
            return 1

    print(f"Form Gallery: {len(configs)} config(s) -> {OUTPUT_DIR}")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    successes = []
    failures = []
    for cfg in configs:
        ok = render_one(cfg, force=args.force)
        (successes if ok else failures).append(cfg["id"])

    # Write manifest for the web page
    manifest_entries = []
    for cfg in data["configs"]:
        png = OUTPUT_DIR / f"{cfg['id']}.png"
        if not png.exists():
            continue
        manifest_entries.append({
            "id": cfg["id"],
            "form": cfg.get("form", ""),
            "label": cfg.get("label", cfg["id"]),
            "category": cfg.get("category", ""),
            "dna": cfg.get("dna", {}),
            "materials": cfg.get("materials", "neutral"),
            "image": f"/form-gallery/{cfg['id']}.png",
        })
    manifest = {
        "version": data.get("version", 1),
        "description": data.get("description", ""),
        "entries": manifest_entries,
    }
    (OUTPUT_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2))
    print(f"\nManifest: {len(manifest_entries)} entries written")
    print(f"OK: {len(successes)}   Failed: {len(failures)}")
    if failures:
        print(f"Failed ids: {failures}")
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
