#!/usr/bin/env python3
"""Render an iso voxel thumbnail for every map in commons/maps/.

Output:
    ada_encyclopedia/public/all-maps-gallery/<map_name>.png
    ada_encyclopedia/public/all-maps-gallery/index.json

Skips maps that already have a thumb unless --force is passed.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
from iso_voxel_render import render_iso  # noqa: E402

MAPS_DIR = REPO / "commons" / "maps"
ENCYCLOPEDIA = REPO.parent / "ada_encyclopedia"
OUT_DIR = ENCYCLOPEDIA / "public" / "all-maps-gallery"


def cell_height(v) -> int:
    if isinstance(v, int): return v
    if isinstance(v, str):
        try: return int(v)
        except Exception: return 0
    return 0


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--force", action="store_true")
    p.add_argument("--cell-px", type=int, default=10)
    p.add_argument("--limit", type=int, default=0)
    args = p.parse_args()

    if not ENCYCLOPEDIA.exists():
        print("encyclopedia not found"); return 1
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    entries: list[dict] = []
    rendered = 0
    skipped = 0
    failed = 0

    map_dirs = sorted(d for d in MAPS_DIR.iterdir()
                      if d.is_dir() and d.name not in {"sequences"})
    if args.limit:
        map_dirs = map_dirs[: args.limit]

    for i, map_dir in enumerate(map_dirs):
        name = map_dir.name
        md_path = map_dir / "map_data.json"
        if not md_path.exists():
            continue
        thumb_path = OUT_DIR / f"{name}.png"
        meta = {"name": name, "image": f"/all-maps-gallery/{name}.png"}
        try:
            md = json.loads(md_path.read_text(encoding="utf-8", errors="replace"))
            layers = md.get("layers", {})
            structure = layers.get("structure", [])
            if not structure:
                failed += 1; continue
            heights = [[cell_height(v) for v in row] for row in structure]
            utilities = layers.get("utilities", [])
            interactables = layers.get("interactables", [])
            rows = len(heights)
            cols = max((len(r) for r in heights), default=0)
            meta.update({
                "rows": rows, "cols": cols,
                "lookup_name": (md.get("map_info") or {}).get("lookup_name", name),
                "description": (md.get("map_info") or {}).get("description", ""),
                "compose_mode": (md.get("map_info", {}).get("metadata") or {}).get("compose_mode", ""),
            })
            if thumb_path.exists() and not args.force:
                skipped += 1
                entries.append(meta)
                continue
            ok = render_iso(heights, thumb_path, cell_px=args.cell_px,
                            utilities=utilities, interactables=interactables)
            if ok:
                rendered += 1
                entries.append(meta)
            else:
                failed += 1
        except Exception as e:
            failed += 1
            print(f"  ! {name}: {e}")
            continue
        if (i + 1) % 100 == 0:
            print(f"  ...processed {i + 1}/{len(map_dirs)}")

    entries.sort(key=lambda e: e["name"].lower())
    (OUT_DIR / "index.json").write_text(json.dumps({
        "version": 1,
        "count": len(entries),
        "entries": entries,
    }, indent=2), encoding="utf-8")
    print(f"\nrendered {rendered}, skipped {skipped}, failed {failed}")
    print(f"index: {(OUT_DIR / 'index.json')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
