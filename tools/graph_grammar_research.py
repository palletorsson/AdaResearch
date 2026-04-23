#!/usr/bin/env python
"""
graph_grammar_research.py — Batch-render graph grammar configs.

Mirrors tools/mesh_grammar_research.py but for graph grammars. Each config
becomes a PNG + paired JSON in ada_encyclopedia/public/graph-grammar-gallery/.

Usage:
  python tools/graph_grammar_research.py                 # render missing
  python tools/graph_grammar_research.py --id gg00_tree_classic
  python tools/graph_grammar_research.py --force
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
CONFIG_PATH = REPO_ROOT / "commons" / "graph_grammar" / "research_configs.json"
ENCYCLOPEDIA_DIR = REPO_ROOT.parent / "ada_encyclopedia"
OUTPUT_DIR = ENCYCLOPEDIA_DIR / "public" / "graph-grammar-gallery"
STAGE_DIR_NAME = "gg_gallery"


def _find_godot_userdata() -> Path | None:
    appdata = os.environ.get("APPDATA", "")
    if not appdata:
        return None
    ud = Path(appdata) / "Godot" / "app_userdata"
    if not ud.exists():
        return None
    for d in ud.iterdir():
        stage = d / STAGE_DIR_NAME
        if stage.exists():
            return stage
    for d in ud.iterdir():
        if "ada" in d.name.lower():
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
    out_cfg.write_text(json.dumps(config, indent=2))

    staging_cfg = REPO_ROOT / "commons" / "graph_grammar" / "_staging"
    staging_cfg.mkdir(parents=True, exist_ok=True)
    cfg_staging = staging_cfg / f"{cid}.json"
    cfg_staging.write_text(json.dumps(config, indent=2))

    user_out = f"user://{STAGE_DIR_NAME}/{cid}.png"
    res_cfg = f"res://commons/graph_grammar/_staging/{cid}.json"

    args = [
        GODOT_EXE,
        "--path", str(REPO_ROOT),
        "--xr-mode", "off",
        "--no-window",
        "--script", "res://commons/testing/render_graph_grammar.gd",
        "--",
        f"--config={res_cfg}",
        f"--out={user_out}",
        "--size=640",
    ]
    print(f"  render {cid} ...")
    # Timeout 300s — metaball configs at 96³ with many segments need breathing room.
    proc = subprocess.run(args, capture_output=True, text=True, timeout=300)
    if proc.returncode != 0:
        print(f"    FAILED (rc={proc.returncode})")
        print(f"    stderr: {proc.stderr[-500:]}")
        return False
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
    print(f"    -> public/graph-grammar-gallery/{cid}.png")
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--id", help="Render a single config")
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

    print(f"Graph grammar research: {len(configs)} -> {OUTPUT_DIR}")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    results = {"ok": [], "fail": []}
    for cfg in configs:
        ok = render_one(cfg, args.force)
        (results["ok"] if ok else results["fail"]).append(cfg["id"])

    entries = []
    for cfg in lib["configs"]:
        png = OUTPUT_DIR / f"{cfg['id']}.png"
        if not png.exists():
            continue
        entries.append({
            "id": cfg["id"],
            "notes": cfg.get("notes", ""),
            "iterations": cfg.get("iterations", 1),
            "rule_count": len(cfg.get("rules", [])),
            "image": f"/graph-grammar-gallery/{cfg['id']}.png",
            "config": f"/graph-grammar-gallery/{cfg['id']}.json",
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
