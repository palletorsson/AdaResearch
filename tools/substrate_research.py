#!/usr/bin/env python
"""substrate_research.py — Batch-render substrate configs into a gallery.

Mirror of tools/mesh_grammar_research.py; same loop, different content.
Reads commons/substrate_research/research_configs.json (seed library),
renders each config to a PNG via commons/testing/render_substrate_config.gd,
saves PNG + paired JSON in ada_encyclopedia/public/substrate-gallery/, and
updates a manifest. Critique by AI/human is then written to evals.json
in the same dir, same schema as the mesh-grammar gallery.

Usage:
  python tools/substrate_research.py                     # render missing
  python tools/substrate_research.py --force             # overwrite all
  python tools/substrate_research.py --id gen00_glyph_uniform   # one config
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
CONFIG_PATH = REPO_ROOT / "commons" / "substrate_research" / "research_configs.json"
ENCYCLOPEDIA_DIR = REPO_ROOT.parent / "ada_encyclopedia"
OUTPUT_DIR = ENCYCLOPEDIA_DIR / "public" / "substrate-gallery"
STAGE_DIR_NAME = "sub_gallery"


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

    staging_dir = REPO_ROOT / "commons" / "substrate_research" / "_staging"
    staging_dir.mkdir(parents=True, exist_ok=True)
    cfg_staging = staging_dir / f"{cid}.json"
    cfg_staging.write_text(json.dumps(config, indent=2))

    user_out = f"user://{STAGE_DIR_NAME}/{cid}.png"
    res_cfg = f"res://commons/substrate_research/_staging/{cid}.json"

    args = [
        GODOT_EXE,
        "--path", str(REPO_ROOT),
        "--xr-mode", "off",
        "--no-window",
        "--script", "res://commons/testing/render_substrate_config.gd",
        "--",
        f"--config={res_cfg}",
        f"--out={user_out}",
        "--size=640",
    ]
    print(f"  render {cid} ...")
    proc = subprocess.run(args, capture_output=True, text=True, timeout=120)
    if proc.returncode != 0:
        print(f"    FAILED (rc={proc.returncode})")
        print(f"    stderr: {proc.stderr[-400:]}")
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
    print(f"    -> public/substrate-gallery/{cid}.png")
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

    print(f"Substrate research: {len(configs)} config(s) -> {OUTPUT_DIR}")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    results = {"ok": [], "fail": []}
    for cfg in configs:
        ok = render_one(cfg, args.force)
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
            "grid_dims": cfg.get("grid_dims", []),
            "visibility": cfg.get("visibility", ""),
            "channels": [
                k for k in ("enable_part", "enable_glyph", "enable_3d_expressions")
                if cfg.get(k, False)
            ],
            "image": f"/substrate-gallery/{cfg['id']}.png",
            "config": f"/substrate-gallery/{cfg['id']}.json",
        })
    manifest = {
        "schema_version": 1,
        "generated_at": None,
        "config_library": str(lib_path.relative_to(REPO_ROOT)),
        "entries": entries,
    }
    (OUTPUT_DIR / "manifest.json").write_text(json.dumps(manifest, indent=2))
    print(f"\nWrote manifest with {len(entries)} entries")
    print(f"OK: {len(results['ok'])}  FAIL: {len(results['fail'])}")
    if results["fail"]:
        print(f"  failed: {results['fail']}")
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
