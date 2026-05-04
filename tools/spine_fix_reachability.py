#!/usr/bin/env python3
"""Walk every artifact from spawn on the best-per-base variants. For any
unreachable artifact, lay wp ramps / tc transports / structural fills so
the player can actually get there. Re-eval after the fix.

Usage:
    python tools/spine_fix_reachability.py            # fix best-per-base
    python tools/spine_fix_reachability.py --all      # fix every variant
    python tools/spine_fix_reachability.py --sequence color
    python tools/spine_fix_reachability.py --dry-run  # report only
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))

from map_grammar.ops import MapState                            # noqa: E402
from spine_auto_research import (                                # noqa: E402
    _ensure_artifacts_reachable, _bfs_reachable,
)


def parse_height(v) -> int:
    if isinstance(v, int): return v
    if isinstance(v, str):
        try: return int(v)
        except ValueError: return 0
    return 0
from iso_voxel_render import render_iso                          # noqa: E402

MAPS_DIR = REPO / "commons" / "maps"
ENCYCLOPEDIA = REPO.parent / "ada_encyclopedia"
MIRROR_DIR = ENCYCLOPEDIA / "public" / "spine-research"


def state_from_map_data(md: dict) -> MapState:
    layers = md.get("layers", {})
    struct = layers.get("structure", [])
    utils = layers.get("utilities", [])
    interact = layers.get("interactables", [])
    rows = len(struct)
    cols = max((len(r) for r in struct), default=0)
    s = MapState(rows=rows, cols=cols)
    for r in range(rows):
        for c in range(cols):
            if c < len(struct[r]):
                s.structure[r][c] = parse_height(struct[r][c])
            if r < len(utils) and c < len(utils[r]):
                s.utilities[r][c] = utils[r][c] or " "
            if r < len(interact) and c < len(interact[r]):
                s.interactables[r][c] = interact[r][c] or " "
    return s


def state_to_map_data(state: MapState, md: dict) -> dict:
    md.setdefault("layers", {})
    md["layers"]["structure"] = [
        [str(state.structure[r][c]) for c in range(state.cols)]
        for r in range(state.rows)
    ]
    md["layers"]["utilities"] = [
        [(state.utilities[r][c] or " ") for c in range(state.cols)]
        for r in range(state.rows)
    ]
    md["layers"]["interactables"] = [
        [(state.interactables[r][c] or " ") for c in range(state.cols)]
        for r in range(state.rows)
    ]
    return md


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--all", action="store_true",
                   help="walk every variant (default: best-per-base only)")
    p.add_argument("--sequence", default="", help="limit to one sequence")
    p.add_argument("--dry-run", action="store_true",
                   help="report orphans and proposed fixes without writing")
    args = p.parse_args()

    manifest_path = MIRROR_DIR / "manifest.json"
    if not manifest_path.exists():
        sys.exit(f"missing {manifest_path}")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    entries = manifest.get("entries", [])

    chosen = [
        e for e in entries
        if (args.all or e.get("is_best_for_base"))
        and (not args.sequence or e.get("sequence") == args.sequence)
    ]
    print(f"  scope: {len(chosen)} variant(s)")

    totals = {"wp_added": 0, "tc_added": 0, "cubes_added": 0,
              "fixed_artifacts": 0, "still_orphan": 0,
              "variants_modified": 0, "variants_clean": 0}

    for e in chosen:
        eid = e.get("id")
        map_path = MAPS_DIR / eid / "map_data.json"
        if not map_path.exists():
            continue
        md = json.loads(map_path.read_text(encoding="utf-8"))
        state = state_from_map_data(md)

        # Quick pre-check: any orphans at all?
        before_reach = _bfs_reachable(state)
        artifact_cells = [
            (r, c) for r in range(state.rows) for c in range(state.cols)
            if (state.interactables[r][c] or "").strip() not in ("", " ")
        ]
        orphans_before = [a for a in artifact_cells if a not in before_reach]
        if not orphans_before:
            totals["variants_clean"] += 1
            continue

        # Apply fixup.
        fixes = _ensure_artifacts_reachable(state)
        for k in ("wp_added", "tc_added", "cubes_added", "still_orphan"):
            totals[k] += fixes.get(k, 0)
        if fixes.get("fixed_artifacts", 0) > 0:
            totals["variants_modified"] += 1
            totals["fixed_artifacts"] += fixes["fixed_artifacts"]
            print(f"  + {eid:50s} orphans={len(orphans_before):2d} "
                  f"wp={fixes['wp_added']} tc={fixes['tc_added']} "
                  f"cubes={fixes['cubes_added']}")

            if not args.dry_run:
                state_to_map_data(state, md)
                md.setdefault("map_info", {}).setdefault("metadata", {})
                md["map_info"]["metadata"].setdefault("scores", {})
                md["map_info"]["metadata"]["scores"]["reachability_fixes"] = fixes
                map_path.write_text(json.dumps(md, indent=2), encoding="utf-8")
                # Re-render the iso PNG (the gallery thumbnail) so the new
                # ramps/transports are visible immediately.
                thumb = MAPS_DIR / eid / "map_iso.png"
                try:
                    render_iso(state.structure, thumb, cell_px=12,
                               utilities=state.utilities,
                               interactables=state.interactables)
                    # Mirror to the encyclopedia too.
                    mirror = MIRROR_DIR / f"{eid}.png"
                    if mirror.exists():
                        import shutil
                        shutil.copy2(thumb, mirror)
                except Exception as ex:
                    print(f"    ! re-render failed: {ex}")

    print(f"\n=== reachability fixup ===")
    print(f"  variants modified:  {totals['variants_modified']}")
    print(f"  variants clean:     {totals['variants_clean']}")
    print(f"  artifacts rescued:  {totals['fixed_artifacts']}")
    print(f"  wp ramps added:     {totals['wp_added']}")
    print(f"  tc transports added:{totals['tc_added']}")
    print(f"  cubes filled:       {totals['cubes_added']}")
    print(f"  still-orphan:       {totals['still_orphan']}")
    if args.dry_run:
        print("(dry run — no writes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
