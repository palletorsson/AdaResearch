#!/usr/bin/env python3
"""
harvest_player_compositions.py
===============================

The composition_platform writes captured stacks to two locations:
  user://player_compositions/<id>.json  (per-machine save)
  res://commons/generated/player_compositions/<id>.json  (repo-shared)

This tool reads the repo-shared captures and turns them into a real
gallery (player-creations-gallery) the way build_color_galleries.py
turns hand-written configs into the color galleries. For each capture:

  1. Render PNG via res://commons/testing/render_primitive_stack.gd
  2. Copy the JSON config into the gallery folder
  3. Append to manifest.json (notes, captured_at, layout)

After running this, /player-creations-gallery shows up alongside the
other galleries on the encyclopedia, and the bake pipeline can promote
any capture to a placeable artifact.

Run:
    python tools/harvest_player_compositions.py
    python tools/harvest_player_compositions.py --watch       # poll every 3s
    python tools/harvest_player_compositions.py --force       # re-render all
"""

from __future__ import annotations
import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))
from measure_artifact_aabbs import _find_godot          # noqa: E402

ENC = REPO.parent / "ada_encyclopedia"
CAPTURES = REPO / "commons" / "generated" / "player_compositions"
GALLERY = ENC / "public" / "player-creations-gallery"
STAGING = REPO / "commons" / "primitive_grammar" / "_staging"


def render_one(godot: str, cfg: dict, out_png: Path, force: bool) -> bool:
    cid = cfg["id"]
    if out_png.exists() and not force:
        return True

    STAGING.mkdir(parents=True, exist_ok=True)
    cfg_staging = STAGING / f"{cid}.json"
    cfg_staging.write_text(json.dumps(cfg, indent=2), encoding="utf-8")
    user_out = f"user://ps_gallery/{cid}.png"
    res_cfg = f"res://commons/primitive_grammar/_staging/{cid}.json"
    cmd = [
        godot, "--path", str(REPO), "--xr-mode", "off", "--no-window",
        "--script", "res://commons/testing/render_primitive_stack.gd", "--",
        f"--config={res_cfg}", f"--out={user_out}", "--size=640",
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    if proc.returncode != 0:
        return False
    appdata = os.environ.get("APPDATA", "")
    if not appdata:
        return False
    ud = Path(appdata) / "Godot" / "app_userdata"
    if not ud.exists():
        return False
    src = None
    for d in ud.iterdir():
        cand = d / "ps_gallery" / f"{cid}.png"
        if cand.exists():
            src = cand
            break
    if src is None:
        return False
    shutil.copy2(src, out_png)
    return True


def harvest_once(godot: str | None, force: bool) -> int:
    GALLERY.mkdir(parents=True, exist_ok=True)
    if not CAPTURES.exists():
        print(f"  no captures yet at {CAPTURES.relative_to(REPO)}")
        return 0

    captures = sorted(CAPTURES.glob("*.json"))
    if not captures:
        print("  no captures to harvest")
        return 0

    entries: list[dict] = []
    new_count = 0
    for cap in captures:
        try:
            cfg = json.loads(cap.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            print(f"  SKIP corrupt: {cap.name}")
            continue
        cid = cfg.get("id", cap.stem)
        out_json = GALLERY / f"{cid}.json"
        out_png = GALLERY / f"{cid}.png"
        is_new = not out_json.exists()
        out_json.write_text(json.dumps(cfg, indent=2), encoding="utf-8")
        if godot:
            ok = render_one(godot, cfg, out_png, force or is_new)
            print(f"  {'render' if is_new else 'skip  '}  {cid}  ({'OK' if ok else 'FAIL'})")
        else:
            print(f"  copy    {cid}  (no Godot — config only)")
        entries.append({
            "id": cid,
            "notes": cfg.get("notes", "Player creation"),
            "captured_at": cfg.get("captured_at", ""),
            "layout": cfg.get("layout", "vertical_stack"),
            "primitive_count": len(cfg.get("sequence", [])),
            "image": f"/player-creations-gallery/{cid}.png",
            "config": f"/player-creations-gallery/{cid}.json",
        })
        if is_new:
            new_count += 1

    manifest = {
        "schema_version": 1,
        "version": 1,
        "description": (
            "Player creations — compositions captured at runtime by the "
            "composition_platform artifact. Each entry is a primitive_stack "
            "config the player invented by stacking conveyor pieces."
        ),
        "entries": sorted(entries, key=lambda e: e.get("captured_at", ""), reverse=True),
    }
    (GALLERY / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    evals = GALLERY / "evals.json"
    if not evals.exists():
        evals.write_text("{}\n", encoding="utf-8")
    return new_count


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--watch", action="store_true", help="Poll every 3s.")
    ap.add_argument("--force", action="store_true", help="Re-render existing PNGs.")
    ap.add_argument("--no-render", action="store_true",
                    help="Skip Godot — only sync JSON + manifest.")
    args = ap.parse_args()

    godot = None if args.no_render else _find_godot()
    if not args.no_render and not godot:
        print("No Godot found — proceeding without renders.")

    if args.watch:
        seen = -1
        while True:
            n = harvest_once(godot, args.force)
            if n > 0 or seen < 0:
                print(f"  [{time.strftime('%H:%M:%S')}] harvested {n} new captures")
            seen = n
            time.sleep(3.0)
    else:
        n = harvest_once(godot, args.force)
        print(f"\nHarvested {n} new captures.")
        print(f"Gallery: http://localhost:3003/player-creations-gallery")


if __name__ == "__main__":
    main()
