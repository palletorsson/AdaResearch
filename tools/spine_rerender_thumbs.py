#!/usr/bin/env python3
"""Re-render the iso PNG for every spine-research variant.

Used after improving tools/iso_voxel_render.py — picks up the new camera
angle, anti-aliasing, marker styling, etc. without regenerating the
underlying map_data. Walks the gallery manifest, rerenders each entry's
map_iso.png from its on-disk map_data.json, and mirrors to the
encyclopedia public dir.

Usage:
    python tools/spine_rerender_thumbs.py
    python tools/spine_rerender_thumbs.py --sequence color
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))

from iso_voxel_render import render_iso         # noqa: E402

MAPS_DIR = REPO / "commons" / "maps"
ENCYCLOPEDIA = REPO.parent / "ada_encyclopedia"
MIRROR_DIR = ENCYCLOPEDIA / "public" / "spine-research"
MANIFEST = MIRROR_DIR / "manifest.json"


def parse_h(v) -> int:
    if isinstance(v, int): return v
    if isinstance(v, str):
        try: return int(v)
        except ValueError: return 0
    return 0


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--sequence", default="", help="limit to one sequence")
    p.add_argument("--cell-px", type=int, default=14)
    p.add_argument("--supersample", type=int, default=2)
    args = p.parse_args()

    if not MANIFEST.exists():
        sys.exit(f"missing {MANIFEST}")
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    entries = manifest.get("entries", [])
    if args.sequence:
        entries = [e for e in entries if e.get("sequence") == args.sequence]
    print(f"  scope: {len(entries)} variants")

    written = 0
    skipped = 0
    for e in entries:
        eid = e.get("id")
        map_path = MAPS_DIR / eid / "map_data.json"
        if not map_path.exists():
            skipped += 1; continue
        try:
            md = json.loads(map_path.read_text(encoding="utf-8"))
            layers = md.get("layers", {})
            struct = layers.get("structure", [])
            heights = [[parse_h(v) for v in row] for row in struct]
            utils = layers.get("utilities", [])
            interact = layers.get("interactables", [])
        except Exception as ex:
            print(f"  ! skip {eid}: {ex}")
            skipped += 1; continue
        local_thumb = MAPS_DIR / eid / "map_iso.png"
        ok = render_iso(heights, local_thumb, cell_px=args.cell_px,
                        utilities=utils, interactables=interact,
                        supersample=args.supersample)
        if ok and ENCYCLOPEDIA.exists():
            mirror = MIRROR_DIR / f"{eid}.png"
            shutil.copy2(local_thumb, mirror)
        written += 1
        if written % 100 == 0:
            print(f"    rendered {written}/{len(entries)}")

    print(f"\n=== rerender ===  written: {written}  skipped: {skipped}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
