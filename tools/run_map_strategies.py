#!/usr/bin/env python3
"""Run every map-generation strategy, render PNG previews, score each
candidate, build an index for the encyclopedia gallery.

    python tools/run_map_strategies.py
    python tools/run_map_strategies.py --width 20 --height 20

Outputs:
    doc/reports/map_strategies/index.json
    doc/reports/map_strategies/<strategy>/<i>.png
    doc/reports/map_strategies/<strategy>/<i>.json (the heights array)
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
from map_strategies import Strategy   # noqa: E402
from map_strategies.base import (
    count_walkable, largest_component_size,
)
from iso_voxel_render import render_iso

OUT_DIR = REPO / "doc" / "reports" / "map_strategies"
# Encyclopedia gallery output — same shape as mesh-grammar so it slots
# straight into the existing /galleries/ index. Write only if the
# encyclopedia repo is alongside.
ENCYCLOPEDIA = REPO.parent / "ada_encyclopedia"
GALLERY_DIR = ENCYCLOPEDIA / "public" / "map-grammar-gallery"


def render_flat_png(heights, out_path: Path, cell_px: int = 14) -> bool:
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        return False
    rows = len(heights)
    cols = max((len(r) for r in heights), default=0)
    if rows == 0 or cols == 0: return False
    img = Image.new("RGB", (cols * cell_px, rows * cell_px), (16, 18, 22))
    draw = ImageDraw.Draw(img)
    palette = {
        0: (28, 30, 36),     # void
        1: (94, 110, 128),   # floor
        2: (140, 158, 178),  # step / plinth low
        3: (180, 196, 216),  # plinth top
        4: (52, 60, 70),     # wall
        5: (40, 44, 50),
    }
    for r in range(rows):
        row = heights[r]
        for c in range(min(cols, len(row))):
            v = int(row[c]) if isinstance(row[c], int) else int(str(row[c]))
            color = palette.get(v, (90, 90, 90))
            x0 = c * cell_px; y0 = r * cell_px
            draw.rectangle([x0, y0, x0 + cell_px - 1, y0 + cell_px - 1],
                           fill=color, outline=(10, 12, 16))
    img.save(out_path)
    return True


def score(heights) -> dict:
    rows = len(heights)
    cols = max((len(r) for r in heights), default=0)
    total = rows * cols if rows and cols else 1
    walkable = count_walkable(heights)
    largest = largest_component_size(heights)
    # Connectivity = how much of the walkable area is in one component.
    connectivity = (largest / walkable) if walkable else 0.0
    # Density = walkable fraction.
    density = walkable / total
    # Roughness = number of cell-pair boundaries between different heights.
    rough = 0
    for r in range(rows):
        row = heights[r]
        for c in range(len(row) - 1):
            if int(row[c]) != int(row[c + 1]): rough += 1
        if r + 1 < rows:
            for c in range(min(len(row), len(heights[r + 1]))):
                if int(row[c]) != int(heights[r + 1][c]): rough += 1
    return {
        "walkable": walkable,
        "largest_component": largest,
        "density": round(density, 3),
        "connectivity": round(connectivity, 3),
        "roughness": rough,
    }


def discover_strategies() -> list[Strategy]:
    """Return one instance per Strategy subclass."""
    out: list[Strategy] = []
    for cls in Strategy.__subclasses__():
        out.append(cls())
    return out


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--width", type=int, default=24)
    p.add_argument("--height", type=int, default=24)
    p.add_argument("--seed", type=int, default=1)
    p.add_argument("--cell-px", type=int, default=12)
    args = p.parse_args()

    strategies = discover_strategies()
    print(f"strategies: {[s.name for s in strategies]}")
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    write_gallery = ENCYCLOPEDIA.exists()
    if write_gallery:
        GALLERY_DIR.mkdir(parents=True, exist_ok=True)
    index: list[dict] = []
    manifest_entries: list[dict] = []

    for strat in strategies:
        sub = OUT_DIR / strat.name
        sub.mkdir(parents=True, exist_ok=True)
        candidates: list[dict] = []
        for i, result in enumerate(
                strat.iter_candidates(args.width, args.height, args.seed)):
            png_name = f"{strat.name}_{i:02d}.png"
            cfg_name = f"{strat.name}_{i:02d}.json"
            local_png = sub / f"{i:02d}.png"
            local_json = sub / f"{i:02d}.json"
            render_iso(result.heights, local_png, cell_px=args.cell_px)
            metrics = score(result.heights)
            cfg = {
                "id": f"{strat.name}_{i:02d}",
                "strategy": strat.name,
                "tier": strat.tier,
                "label": result.label,
                "params": result.params,
                "metrics": metrics,
                "heights": result.heights,
            }
            local_json.write_text(json.dumps(cfg, indent=2), encoding="utf-8")
            candidates.append({
                "i": i,
                "label": result.label,
                "metrics": metrics,
                "params": result.params,
            })
            print(f"  {strat.name:24s} [{i:02d}] {result.label:24s} "
                  f"density={metrics['density']:.2f} "
                  f"connect={metrics['connectivity']:.2f}")

            # Mirror to the encyclopedia gallery dir.
            if write_gallery:
                gallery_png = GALLERY_DIR / png_name
                gallery_json = GALLERY_DIR / cfg_name
                render_iso(result.heights, gallery_png, cell_px=args.cell_px)
                gallery_json.write_text(json.dumps(cfg, indent=2), encoding="utf-8")
                manifest_entries.append({
                    "id": cfg["id"],
                    "strategy": strat.name,
                    "tier": strat.tier,
                    "notes": f"{strat.description}  ({result.label})",
                    "image": f"/map-grammar-gallery/{png_name}",
                    "config": f"/map-grammar-gallery/{cfg_name}",
                    "label": result.label,
                    "grid_dims": [args.width, args.height],
                    "metrics": metrics,
                    "rating": None,
                })

        index.append({
            "name": strat.name,
            "tier": strat.tier,
            "description": strat.description,
            "candidates": candidates,
        })

    (OUT_DIR / "index.json").write_text(json.dumps({
        "size": [args.width, args.height],
        "seed": args.seed,
        "strategies": index,
    }, indent=2), encoding="utf-8")
    print(f"\nwrote {(OUT_DIR / 'index.json').relative_to(REPO)}")

    if write_gallery:
        manifest = {
            "schema_version": 1,
            "version": 1,
            "description": ("Map-grammar gallery — auto-research-style sweeps "
                           "of generation strategies producing structure layers. "
                           "Same loop as mesh-grammar: render, score, propose, "
                           "render. From simple agent walks through grammars "
                           "and constraint solvers."),
            "entries": manifest_entries,
        }
        manifest_path = GALLERY_DIR / "manifest.json"
        manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
        print(f"wrote {manifest_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
