#!/usr/bin/env python
"""
pattern_research.py — Batch-render wallpaper-group pattern configs.
DNA = { group, tile_size, motif_seed, palette, motif, canvas_size }.
"""
from __future__ import annotations
import argparse, json, os, subprocess, sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
GODOT_EXE = os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
CONFIG_PATH = REPO_ROOT / "commons" / "pattern_grammar" / "research_configs.json"
ENCYCLOPEDIA_DIR = REPO_ROOT.parent / "ada_encyclopedia"
OUTPUT_DIR = ENCYCLOPEDIA_DIR / "public" / "pattern-gallery"
STAGE_DIR_NAME = "pattern_gallery"


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


def render_one(config: dict, force: bool) -> bool:
    cid = config["id"]
    out_png = OUTPUT_DIR / f"{cid}.png"
    out_cfg = OUTPUT_DIR / f"{cid}.json"
    if out_png.exists() and out_cfg.exists() and not force:
        print(f"  skip  {cid}")
        return True
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    out_cfg.write_text(json.dumps(config, indent=2))
    staging = REPO_ROOT / "commons" / "pattern_grammar" / "_staging"
    staging.mkdir(parents=True, exist_ok=True)
    cfg_staging = staging / f"{cid}.json"
    cfg_staging.write_text(json.dumps(config, indent=2))
    user_out = f"user://{STAGE_DIR_NAME}/{cid}.png"
    res_cfg = f"res://commons/pattern_grammar/_staging/{cid}.json"
    args = [
        GODOT_EXE, "--path", str(REPO_ROOT), "--xr-mode", "off", "--no-window",
        "--script", "res://commons/testing/render_pattern.gd", "--",
        f"--config={res_cfg}", f"--out={user_out}",
    ]
    print(f"  render {cid} ({config.get('group','?')}) ...")
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
    print(f"    -> public/pattern-gallery/{cid}.png")
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--id")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    if not CONFIG_PATH.exists():
        print(f"Config not found: {CONFIG_PATH}"); return 1
    lib = json.loads(CONFIG_PATH.read_text())
    configs = lib["configs"]
    if args.id:
        configs = [c for c in configs if c["id"] == args.id]
        if not configs: print(f"No config {args.id}"); return 1
    print(f"Pattern: {len(configs)} configs -> {OUTPUT_DIR}")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    ok, fail = [], []
    for cfg in configs:
        (ok if render_one(cfg, args.force) else fail).append(cfg["id"])

    entries = []
    for cfg in lib["configs"]:
        png = OUTPUT_DIR / f"{cfg['id']}.png"
        if not png.exists(): continue
        entries.append({
            "id": cfg["id"],
            "notes": cfg.get("notes", ""),
            "group": cfg.get("group", ""),
            "palette": cfg.get("palette", ""),
            "motif": cfg.get("motif", ""),
            "image": f"/pattern-gallery/{cfg['id']}.png",
            "config": f"/pattern-gallery/{cfg['id']}.json",
        })
    manifest = {
        "version": lib.get("version", 1),
        "description": lib.get("description", ""),
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
