#!/usr/bin/env python
"""
mesh_grammar_research.py — Batch-render mesh grammar configs and build a
gallery that AI can review.

Workflow:
  1. Reads commons/mesh_grammar/research_configs.json (seed library)
  2. For each config, writes a per-image JSON config alongside the PNG
     (so you always know what DNA produced each shape)
  3. Invokes Godot headless to render via commons/testing/render_mesh_grammar.gd
  4. Updates a manifest in ada_encyclopedia/public/mesh-grammar-gallery/

Output layout:
  ada_encyclopedia/public/mesh-grammar-gallery/
    manifest.json
    gen00_tower_plain.png
    gen00_tower_plain.json       ← exact config that produced the PNG
    gen00_coral_random.png
    gen00_coral_random.json
    ...

Usage:
  python tools/mesh_grammar_research.py                       # render missing
  python tools/mesh_grammar_research.py --force               # overwrite all
  python tools/mesh_grammar_research.py --id gen00_mushroom   # one config
  python tools/mesh_grammar_research.py --library <path.json> # alt library
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
CONFIG_PATH = REPO_ROOT / "commons" / "mesh_grammar" / "research_configs.json"
ENCYCLOPEDIA_DIR = REPO_ROOT.parent / "ada_encyclopedia"
OUTPUT_DIR = ENCYCLOPEDIA_DIR / "public" / "mesh-grammar-gallery"
# Godot user:// staging path
STAGE_DIR_NAME = "mg_gallery"


def _find_godot_userdata() -> Path | None:
    appdata = os.environ.get("APPDATA", "")
    if not appdata:
        return None
    ud = Path(appdata) / "Godot" / "app_userdata"
    if not ud.exists():
        return None
    # Find a project dir containing mg_gallery
    for d in ud.iterdir():
        stage = d / STAGE_DIR_NAME
        if stage.exists():
            return stage
    # Otherwise prefer the first AdaResearch-like dir
    for d in ud.iterdir():
        if "ada" in d.name.lower() or "adaresearch" in d.name.lower():
            return d / STAGE_DIR_NAME
    return None


def render_one(config: dict, force: bool) -> bool:
    cid = config["id"]
    out_png = OUTPUT_DIR / f"{cid}.png"
    out_cfg = OUTPUT_DIR / f"{cid}.json"
    if out_png.exists() and out_cfg.exists() and not force:
        print(f"  skip  {cid}  (exists)")
        return True
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Write per-config JSON NEXT TO the png so it's always paired
    out_cfg.write_text(json.dumps(config, indent=2))

    # Staging path: write config to res:// temp dir so Godot can read
    staging_cfg = REPO_ROOT / "commons" / "mesh_grammar" / "_staging"
    staging_cfg.mkdir(parents=True, exist_ok=True)
    cfg_staging = staging_cfg / f"{cid}.json"
    cfg_staging.write_text(json.dumps(config, indent=2))

    user_out = f"user://{STAGE_DIR_NAME}/{cid}.png"
    res_cfg = f"res://commons/mesh_grammar/_staging/{cid}.json"

    args = [
        GODOT_EXE,
        "--path", str(REPO_ROOT),
        "--xr-mode", "off",
        "--no-window",
        "--script", "res://commons/testing/render_mesh_grammar.gd",
        "--",
        f"--config={res_cfg}",
        f"--out={user_out}",
        "--size=640",
    ]
    print(f"  render {cid} ...")
    proc = subprocess.run(args, capture_output=True, text=True, timeout=90)
    if proc.returncode != 0:
        print(f"    FAILED (rc={proc.returncode})")
        print(f"    stderr: {proc.stderr[-400:]}")
        return False
    # Find user:// output and copy into the gallery dir
    stage = _find_godot_userdata()
    src = None
    if stage is not None:
        cand = stage / f"{cid}.png"
        if cand.exists():
            src = cand
    if src is None:
        print(f"    rendered but PNG not found in user data")
        return False
    out_png.write_bytes(src.read_bytes())
    print(f"    -> public/mesh-grammar-gallery/{cid}.png")
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--id", help="Render a single config id")
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--library", default=str(CONFIG_PATH))
    args = parser.parse_args()

    lib_path = Path(args.library)
    if not lib_path.exists():
        print(f"Library not found: {lib_path}")
        return 1
    lib = json.loads(lib_path.read_text())
    configs = lib["configs"]
    if args.id:
        configs = [c for c in configs if c["id"] == args.id]
        if not configs:
            print(f"No config with id={args.id}")
            return 1

    print(f"Mesh grammar research: {len(configs)} config(s) -> {OUTPUT_DIR}")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    results = {"ok": [], "fail": []}
    for cfg in configs:
        ok = render_one(cfg, args.force)
        (results["ok"] if ok else results["fail"]).append(cfg["id"])

    # Rebuild manifest from whatever pngs exist
    entries = []
    for cfg in lib["configs"]:
        png = OUTPUT_DIR / f"{cfg['id']}.png"
        if not png.exists():
            continue
        entries.append({
            "id": cfg["id"],
            "notes": cfg.get("notes", ""),
            "seed": cfg.get("seed", ""),
            "generations": cfg.get("generations", 1),
            "rule_count": len(cfg.get("rules", [])),
            "image": f"/mesh-grammar-gallery/{cfg['id']}.png",
            "config": f"/mesh-grammar-gallery/{cfg['id']}.json",
            "rating": None,
        })
    manifest = {
        "version": lib.get("version", 1),
        "description": lib.get("description", ""),
        "entries": entries,
    }
    (OUTPUT_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2))
    print(f"\nManifest: {len(entries)} entries")
    print(f"OK: {len(results['ok'])}   Failed: {len(results['fail'])}")
    if results["fail"]:
        for f in results["fail"]: print(f"  - {f}")
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
