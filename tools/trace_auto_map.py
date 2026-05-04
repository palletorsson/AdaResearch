#!/usr/bin/env python3
"""Trace one auto-generated map through every pipeline step.

Replays the variant's ops in order, snapshotting the MapState after
each one as an iso PNG. Then runs the post-strategy steps (apply_finish
→ place_artifacts → reachability_fixup) and snapshots after each.
The result is a folder of step-N.png files plus a manifest.json the
UI page can read.

Usage:
    python tools/trace_auto_map.py Color_Pillar_v3_terraced
    python tools/trace_auto_map.py Color_Pillar_v3_terraced --force

Output:
    commons/maps/<variant>/trace/
        00_init.png, 01_<op>.png, 02_<op>.png, ..., NN_finish.png,
        NN+1_place_artifacts.png, NN+2_reachability_fix.png
        manifest.json  (steps with names, descriptions, file paths)
    ada_encyclopedia/public/map-trace/<variant>/  (mirrored)
"""
from __future__ import annotations

import argparse
import copy
import json
import shutil
import sys
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))

from map_grammar.ops import MapState, _OPS, _apply_finish      # noqa: E402
from map_grammar.budget import budget_for_sequence              # noqa: E402
from map_grammar.imprint import imprint_for                     # noqa: E402
from spine_auto_research import (                                # noqa: E402
    _extract_original_artifacts, _place_artifacts_in_variant,
    _ensure_artifacts_reachable,
)
from iso_voxel_render import render_iso                          # noqa: E402
import random as _random

MAPS_DIR = REPO / "commons" / "maps"
ENCYCLOPEDIA = REPO.parent / "ada_encyclopedia"
TRACE_MIRROR = ENCYCLOPEDIA / "public" / "map-trace"


def _state_clone(state: MapState) -> MapState:
    new = MapState(rows=state.rows, cols=state.cols)
    for r in range(state.rows):
        for c in range(state.cols):
            new.structure[r][c] = state.structure[r][c]
            new.utilities[r][c] = state.utilities[r][c]
            new.interactables[r][c] = state.interactables[r][c]
    return new


def _stats(state: MapState) -> dict:
    rows, cols = state.rows, state.cols
    walkable = sum(1 for r in range(rows) for c in range(cols)
                   if state.structure[r][c] >= 1)
    n_heights = len({state.structure[r][c]
                     for r in range(rows) for c in range(cols)
                     if state.structure[r][c] > 0})
    arts = sum(1 for r in range(rows) for c in range(cols)
               if (state.interactables[r][c] or " ").strip() not in ("", " "))
    util_count = sum(1 for r in range(rows) for c in range(cols)
                     if (state.utilities[r][c] or " ").strip() not in ("", " "))
    return {"walkable": walkable, "n_heights": n_heights,
            "artifacts": arts, "utilities": util_count}


def trace(variant_id: str, force: bool = False) -> int:
    src = MAPS_DIR / variant_id / "map_data.json"
    if not src.exists():
        print(f"missing {src}"); return 1
    md = json.loads(src.read_text(encoding="utf-8"))
    meta = md.get("map_info", {}).get("metadata", {})
    ops = meta.get("ops") or []
    if not ops:
        print(f"variant has no ops in metadata; cannot trace"); return 1

    rows = int(meta.get("rows") or md.get("layers", {}).get("structure", [[0]])[0].__len__() or 16)
    cols = int(meta.get("cols") or len(md.get("layers", {}).get("structure", [])) or 16)

    out_dir = MAPS_DIR / variant_id / "trace"
    if out_dir.exists() and not force:
        print(f"trace already exists at {out_dir}; use --force to overwrite")
        return 0
    out_dir.mkdir(parents=True, exist_ok=True)

    # Reproduce the variant's RNG seed mix.
    seed = 42
    rng = _random.Random(seed ^ hash(meta.get("config_id") or variant_id) & 0xFFFFFFFF)
    state = MapState(rows=rows, cols=cols)

    steps: list[dict] = []

    def snap(idx: int, name: str, description: str = "") -> None:
        png = out_dir / f"{idx:02d}_{name}.png"
        try:
            render_iso(state.structure, png, cell_px=14,
                       utilities=state.utilities,
                       interactables=state.interactables,
                       supersample=2)
        except Exception as e:
            print(f"  ! render failed for step {idx} {name}: {e}")
        steps.append({
            "index": idx,
            "name": name,
            "description": description,
            "image": f"/map-trace/{variant_id}/{idx:02d}_{name}.png",
            "stats": _stats(state),
        })

    snap(0, "init", "Empty grid, all cells h=0.")

    for i, step in enumerate(ops, start=1):
        op_name = step.get("op")
        params = step.get("params", {}) or {}
        fn = _OPS.get(op_name)
        if fn is None:
            print(f"  ! unknown op: {op_name}")
            snap(i, f"unknown_{op_name}", f"unknown op: {op_name}")
            continue
        fn(state, params, rng)
        snap(i, op_name, f"{op_name}({json.dumps(params)})")

    # Post-ops: apply_finish (spawn + corridor + teleporter)
    next_idx = len(ops) + 1
    _apply_finish(state)
    snap(next_idx, "apply_finish",
         "Spawn at (1,1), corridor to nearest walkable cell, teleporter on void.")
    next_idx += 1

    # Place artifacts
    base_name = meta.get("derived_from") or variant_id
    base_path = MAPS_DIR / base_name / "map_data.json"
    artifacts_placed = 0
    if base_path.exists():
        base_md = json.loads(base_path.read_text(encoding="utf-8"))
        original_arts = _extract_original_artifacts(base_md)
        artifacts_placed = _place_artifacts_in_variant(state, original_arts)
        snap(next_idx, "place_artifacts",
             f"Placed {artifacts_placed} of {len(original_arts)} artifacts (AABB-aware).")
        next_idx += 1

    # Reachability fixup
    fixes = _ensure_artifacts_reachable(state)
    snap(next_idx, "reachability_fix",
         f"Fixes: {fixes['fixed_artifacts']} artifacts rescued, "
         f"{fixes['wp_added']} wp + {fixes['tc_added']} tc + {fixes['cubes_added']} cubes added.")

    # Manifest
    manifest = {
        "variant_id": variant_id,
        "derived_from": base_name,
        "sequence": meta.get("sequence"),
        "budget": meta.get("budget"),
        "scores": meta.get("scores"),
        "composite_score": meta.get("composite_score"),
        "rows": rows,
        "cols": cols,
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "steps": steps,
    }
    (out_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2), encoding="utf-8")

    # Mirror to the encyclopedia public dir
    if ENCYCLOPEDIA.exists():
        mirror_dir = TRACE_MIRROR / variant_id
        mirror_dir.mkdir(parents=True, exist_ok=True)
        for f in out_dir.iterdir():
            shutil.copy2(f, mirror_dir / f.name)

    print(f"\n=== trace ===  variant: {variant_id}")
    print(f"  steps:   {len(steps)}")
    print(f"  output:  {out_dir.relative_to(REPO)}")
    if ENCYCLOPEDIA.exists():
        print(f"  mirror:  ada_encyclopedia/public/map-trace/{variant_id}")
        print(f"  view at: localhost:3003/map-trace/{variant_id}")
    return 0


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("variant_id", help="variant id, e.g. Color_Pillar_v3_terraced")
    p.add_argument("--force", action="store_true",
                   help="overwrite existing trace")
    args = p.parse_args()
    return trace(args.variant_id, force=args.force)


if __name__ == "__main__":
    raise SystemExit(main())
