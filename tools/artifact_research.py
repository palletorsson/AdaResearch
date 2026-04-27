#!/usr/bin/env python
"""artifact_research.py — Batch-render artifact configs into a gallery.

Third clone of the auto-research pattern (after mesh_grammar_research and
substrate_research). Reads commons/artifact_research/research_configs.json,
renders each config via commons/testing/render_artifact_config.gd, saves
PNG + paired JSON in ada_encyclopedia/public/artifact-gallery/, writes a
manifest. Critique goes in evals.json (same schema as the other two).

Usage:
  python tools/artifact_research.py
  python tools/artifact_research.py --force
  python tools/artifact_research.py --id gen00_persian_rug
  python tools/artifact_research.py --multi    # 4-angle capture per artifact
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
CONFIG_PATH = REPO_ROOT / "commons" / "artifact_research" / "research_configs.json"
ENCYCLOPEDIA_DIR = REPO_ROOT.parent / "ada_encyclopedia"
OUTPUT_DIR = ENCYCLOPEDIA_DIR / "public" / "artifact-gallery"
STAGE_DIR_NAME = "art_gallery"


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


def render_one(config: dict, force: bool, multi: bool) -> bool:
    cid = config["id"]
    out_png = OUTPUT_DIR / f"{cid}.png"
    out_cfg = OUTPUT_DIR / f"{cid}.json"
    if out_png.exists() and out_cfg.exists() and not force:
        print(f"  skip  {cid}  (exists)")
        return True
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    out_cfg.write_text(json.dumps(config, indent=2))

    staging_dir = REPO_ROOT / "commons" / "artifact_research" / "_staging"
    staging_dir.mkdir(parents=True, exist_ok=True)
    cfg_staging = staging_dir / f"{cid}.json"
    cfg_staging.write_text(json.dumps(config, indent=2))

    user_out = f"user://{STAGE_DIR_NAME}/{cid}.png"
    res_cfg = f"res://commons/artifact_research/_staging/{cid}.json"

    args = [
        GODOT_EXE,
        "--path", str(REPO_ROOT),
        "--xr-mode", "off",
        "--no-window",
        "--script", "res://commons/testing/render_artifact_config.gd",
        "--",
        f"--config={res_cfg}",
        f"--out={user_out}",
    ]
    if multi:
        args.append("--multi=true")

    print(f"  render {cid} ...")
    proc = subprocess.run(args, capture_output=True, text=True, timeout=180)
    if proc.returncode != 0:
        print(f"    FAILED (rc={proc.returncode})")
        print(f"    stderr: {proc.stderr[-400:]}")
        return False

    stage = _find_godot_userdata()
    if stage is None:
        print(f"    rendered but user-data dir not found")
        return False

    if multi:
        # Look for {cid}__{angle}.png files
        ok = False
        for angle in ("front", "left", "right", "top"):
            cand = stage / f"{cid}__{angle}.png"
            if cand.exists():
                dst = OUTPUT_DIR / f"{cid}__{angle}.png"
                dst.write_bytes(cand.read_bytes())
                ok = True
        # Use front as the gallery default
        front = OUTPUT_DIR / f"{cid}__front.png"
        if front.exists():
            out_png.write_bytes(front.read_bytes())
        return ok
    else:
        cand = stage / f"{cid}.png"
        if not cand.exists():
            print(f"    PNG not found at {cand}")
            return False
        out_png.write_bytes(cand.read_bytes())
        return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--id")
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--multi", action="store_true",
                        help="4-angle capture per artifact (front/left/right/top)")
    parser.add_argument("--library", default=str(CONFIG_PATH))
    args = parser.parse_args()

    lib = json.loads(Path(args.library).read_text())
    configs = lib["configs"]
    if args.id:
        configs = [c for c in configs if c["id"] == args.id]

    print(f"Artifact research: {len(configs)} config(s) -> {OUTPUT_DIR}")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    results = {"ok": [], "fail": []}
    for cfg in configs:
        ok = render_one(cfg, args.force, args.multi)
        (results["ok"] if ok else results["fail"]).append(cfg["id"])

    # Manifest
    entries = []
    for cfg in lib["configs"]:
        png = OUTPUT_DIR / f"{cfg['id']}.png"
        if not png.exists():
            continue
        entries.append({
            "id": cfg["id"],
            "notes": cfg.get("notes", ""),
            "scene": cfg.get("scene", ""),
            "image": f"/artifact-gallery/{cfg['id']}.png",
            "config": f"/artifact-gallery/{cfg['id']}.json",
        })
    manifest = {
        "schema_version": 1,
        "config_library": str(Path(args.library).relative_to(REPO_ROOT)),
        "entries": entries,
    }
    (OUTPUT_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2))
    print(f"\nWrote manifest with {len(entries)} entries")
    print(f"OK: {len(results['ok'])}  FAIL: {len(results['fail'])}")
    if results["fail"]:
        print(f"  failed: {results['fail']}")
    return 0 if not results["fail"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
