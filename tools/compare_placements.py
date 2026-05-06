#!/usr/bin/env python3
"""Generate the same base map under every placement strategy so you
can compare them side by side.

For each strategy (nearest_role, linear_path, cluster_center, cardinal,
perimeter), runs spine_auto_research with that strategy on the chosen
base map, then captures an iso PNG and writes a comparison manifest
the encyclopedia can render.

Usage:
    python tools/compare_placements.py Color_Pillar
    python tools/compare_placements.py Color_Pillar --strategy-variant v6_column_grid

Output:
    commons/maps/<base>_compare_<strategy>/map_data.json + map_iso.png
    ada_encyclopedia/public/placement-compare/<base>/manifest.json
        with `strategies: [{ name, image, score, n_artifacts, ... }]`
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))

from iso_voxel_render import render_iso                          # noqa: E402

MAPS_DIR = REPO / "commons" / "maps"
ENCYCLOPEDIA = REPO.parent / "ada_encyclopedia"
COMPARE_DIR = ENCYCLOPEDIA / "public" / "placement-compare"

STRATEGIES = ["nearest_role", "linear_path", "cluster_center",
              "cardinal", "perimeter"]


def _parse_h(v) -> int:
    if isinstance(v, int): return v
    if isinstance(v, str):
        try: return int(v)
        except ValueError: return 0
    return 0


def _stats(map_data: dict) -> dict:
    layers = map_data.get("layers", {})
    s = layers.get("structure", [])
    i = layers.get("interactables", [])
    walkable = sum(1 for r in s for c in r if _parse_h(c) >= 1)
    arts: list[tuple[int, int, str]] = []
    for r, row in enumerate(i):
        for c, v in enumerate(row):
            tok = (str(v) if v else "").strip()
            if tok and tok != " ":
                arts.append((r, c, tok))
    return {
        "rows": len(s),
        "cols": max((len(r) for r in s), default=0),
        "walkable": walkable,
        "artifacts": len(arts),
        "artifact_positions": arts,
        "score": map_data.get("map_info", {}).get("metadata", {}).get(
            "composite_score", {}).get("score"),
    }


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("base", help="base map name, e.g. Color_Pillar")
    p.add_argument("--strategy-variant", default=None,
                   help="which generated variant to inspect (e.g. v3_terraced); "
                        "defaults to the first one in the sequence's roster")
    p.add_argument("--n", type=int, default=7,
                   help="number of strategies to run (max 5; uses STRATEGIES)")
    args = p.parse_args()

    src = MAPS_DIR / args.base / "map_data.json"
    if not src.exists():
        sys.exit(f"missing base map: {src}")

    # Find which sequence this base belongs to.
    seq_dir = REPO / "commons" / "maps" / "sequences"
    sequence_id = ""
    for sf in seq_dir.glob("*.json"):
        try:
            sd = json.loads(sf.read_text(encoding="utf-8"))
            seq = next(iter(sd.get("sequences", {}).values()), {}) or {}
            if args.base in (seq.get("maps") or []):
                sequence_id = sf.stem
                break
        except Exception:
            continue

    print(f"  base: {args.base}  sequence: {sequence_id or '?'}")
    print(f"  strategies: {STRATEGIES}")
    print()

    results: list[dict] = []
    for strategy in STRATEGIES[:args.n]:
        print(f"  -> {strategy} ...")
        # Run spine_auto_research for just this map+strategy.
        env = os.environ.copy()
        env["ADA_PLACEMENT_STRATEGY"] = strategy
        cmd = [
            sys.executable, str(REPO / "tools" / "spine_auto_research.py"),
            sequence_id or args.base, "--map", args.base,
            "--n", "7", "--budget", "tight", "--force",
            "--placement", strategy,
        ]
        proc = subprocess.run(cmd, cwd=str(REPO), env=env,
                              capture_output=True, text=True, timeout=120)
        if proc.returncode != 0:
            print(f"    ! generation failed for {strategy}: rc={proc.returncode}")
            print(f"    stderr tail: {proc.stderr[-300:]}")
            continue

        # Find the generated variant for this strategy. Prefer the one
        # named in --strategy-variant, else the first roster match.
        target_variant = None
        if args.strategy_variant:
            target_variant = f"{args.base}_{args.strategy_variant}"
        else:
            for suffix in ("_v3_terraced", "_v5_symmetric", "_v6_column_grid",
                           "_v1_corridor", "_v2_bsp", "_v4_islands", "_v7_curve"):
                candidate = f"{args.base}{suffix}"
                if (MAPS_DIR / candidate / "map_data.json").exists():
                    target_variant = candidate
                    break
        if not target_variant:
            print(f"    ! no generated variant found for {args.base}")
            continue

        src_md = MAPS_DIR / target_variant / "map_data.json"
        if not src_md.exists():
            print(f"    ! variant missing: {src_md}")
            continue

        # Snapshot the strategy's output to a separate compare directory
        # (so the next strategy doesn't overwrite it).
        compare_id = f"{args.base}_compare_{strategy}"
        compare_dir = MAPS_DIR / compare_id
        compare_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src_md, compare_dir / "map_data.json")

        # Render iso PNG into the compare dir.
        md = json.loads(src_md.read_text(encoding="utf-8"))
        struct = md.get("layers", {}).get("structure", [])
        utils = md.get("layers", {}).get("utilities", [])
        interact = md.get("layers", {}).get("interactables", [])
        heights = [[_parse_h(v) for v in row] for row in struct]
        thumb_path = compare_dir / "map_iso.png"
        try:
            render_iso(heights, thumb_path, cell_px=18,
                       utilities=utils, interactables=interact,
                       supersample=2)
        except Exception as e:
            print(f"    ! render failed: {e}")

        # Mirror the PNG to the encyclopedia.
        if ENCYCLOPEDIA.exists():
            mirror_dir = COMPARE_DIR / args.base
            mirror_dir.mkdir(parents=True, exist_ok=True)
            shutil.copy2(thumb_path, mirror_dir / f"{strategy}.png")

        stats = _stats(md)
        results.append({
            "strategy": strategy,
            "variant_id": target_variant,
            "compare_id": compare_id,
            "image": f"/placement-compare/{args.base}/{strategy}.png",
            "stats": stats,
        })
        print(f"    placed: {stats['artifacts']}  score: {stats['score']}")

    # Write the manifest.
    if ENCYCLOPEDIA.exists():
        mirror_dir = COMPARE_DIR / args.base
        mirror_dir.mkdir(parents=True, exist_ok=True)
        manifest = {
            "base": args.base,
            "sequence": sequence_id,
            "generated_at": datetime.utcnow().isoformat() + "Z",
            "strategies": results,
        }
        (mirror_dir / "manifest.json").write_text(
            json.dumps(manifest, indent=2), encoding="utf-8")
        print()
        print(f"=== compare ===  written {len(results)} strategy variants")
        print(f"  view at: localhost:3003/placement-compare/{args.base}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
