#!/usr/bin/env python3
"""Placement-only research pass — keep the structure, replace the layout.

Some sequences (Wavefunctions, Soft Bodies, Procedural Generation) have
floors that are already right; the rework they need is artifact
*placement*, not new structure. This tool reads each base map's existing
structure and utility layers, clears its interactables, then re-runs the
AABB-aware artifact placer in N variant configurations with different
placement seeds. Each variant is written as <base>_p<n> alongside the
original.

Usage:
    python tools/spine_placement_only.py --sequences wavefunctions
    python tools/spine_placement_only.py --sequences wavefunctions,softbodies
    python tools/spine_placement_only.py --map Color_Pillar --n 3
    python tools/spine_placement_only.py --sequences proceduralgeneration --force
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))

from map_grammar.ops import MapState                            # noqa: E402
from spine_auto_research import (                                # noqa: E402
    _extract_original_artifacts,
    _place_artifacts_in_variant,
    _ensure_artifacts_reachable,
    eval_variant,
    load_sequence_maps,
    emit_manifest,
)
from iso_voxel_render import render_iso                          # noqa: E402

MAPS_DIR = REPO / "commons" / "maps"


def _parse_h(v) -> int:
    if isinstance(v, int): return v
    if isinstance(v, str):
        try: return int(v)
        except ValueError: return 0
    return 0


def _state_from_base(base_name: str) -> tuple[MapState | None, list[dict], dict]:
    """Load <base>/map_data.json into a MapState that preserves structure
    and utilities but clears interactables. Returns (state, original_arts,
    raw_data) — None if the base map doesn't exist."""
    src = MAPS_DIR / base_name / "map_data.json"
    if not src.exists():
        return None, [], {}
    md = json.loads(src.read_text(encoding="utf-8"))
    layers = md.get("layers", {})
    struct = layers.get("structure", [])
    utils = layers.get("utilities", [])
    rows = len(struct)
    cols = max((len(r) for r in struct), default=0)
    s = MapState(rows=rows, cols=cols)
    for r in range(rows):
        for c in range(cols):
            if c < len(struct[r]):
                s.structure[r][c] = _parse_h(struct[r][c])
            if r < len(utils) and c < len(utils[r]):
                s.utilities[r][c] = utils[r][c] or " "
            # interactables are intentionally left empty for re-placement
    arts = _extract_original_artifacts(md)
    return s, arts, md


def _placement_variant_seeds(n: int) -> list[tuple[str, int]]:
    """Each variant differs only in the placement RNG seed and a small
    twist on the role-distance weights. Returns [(suffix, seed), ...]."""
    return [(f"_p{i+1}", 17 + 211 * i) for i in range(n)]


def run_one_map(base_name: str, sequence_id: str, n_variants: int,
                force: bool = False) -> list[dict]:
    state0, original_arts, src_md = _state_from_base(base_name)
    if state0 is None:
        return [{"base": base_name, "error": "no map_data.json"}]
    if not original_arts:
        return [{"base": base_name, "error": "no artifacts to place"}]

    artifact_defs = src_md.get("artifact_definitions", {}) or {}
    results: list[dict] = []
    for suffix, seed in _placement_variant_seeds(n_variants):
        vid = f"{base_name}{suffix}"
        out_dir = MAPS_DIR / vid
        out_path = out_dir / "map_data.json"
        if out_path.exists() and not force:
            results.append({"id": vid, "status": "exists"})
            continue

        # Fresh state per variant (deep copy of base structure/utilities).
        state = MapState(rows=state0.rows, cols=state0.cols)
        for r in range(state0.rows):
            for c in range(state0.cols):
                state.structure[r][c] = state0.structure[r][c]
                state.utilities[r][c] = state0.utilities[r][c]
                # interactables stay empty

        # Tweak the artifact ordering to vary placements between variants.
        import random as _r
        rng = _r.Random(seed)
        arts_shuffled = original_arts[:]
        rng.shuffle(arts_shuffled)

        n_placed = _place_artifacts_in_variant(state, arts_shuffled)
        fixes = _ensure_artifacts_reachable(state)
        scores = eval_variant(state)
        scores["artifacts_placed"] = n_placed
        scores["artifacts_original"] = len(original_arts)
        scores["reachability_fixes"] = fixes

        # Build the output map_data by deep-copying the source then
        # overwriting structure/utilities/interactables with our state.
        out_md = json.loads(json.dumps(src_md))
        out_md.setdefault("layers", {})
        out_md["layers"]["structure"] = [
            [str(state.structure[r][c]) for c in range(state.cols)]
            for r in range(state.rows)
        ]
        out_md["layers"]["utilities"] = [
            [(state.utilities[r][c] or " ") for c in range(state.cols)]
            for r in range(state.rows)
        ]
        out_md["layers"]["interactables"] = [
            [(state.interactables[r][c] or " ") for c in range(state.cols)]
            for r in range(state.rows)
        ]
        if artifact_defs:
            out_md["artifact_definitions"] = artifact_defs

        # Tag the lineage. placement_only flag distinguishes these from
        # full structure variants in the gallery.
        mi = out_md.setdefault("map_info", {})
        mi["lookup_name"] = vid
        mi["name"] = vid.replace("_", " ")
        mi.setdefault("metadata", {})
        mi["metadata"].update({
            "spine_research": True,
            "placement_only": True,
            "derived_from": base_name,
            "scores": scores,
            "placement_seed": seed,
            "rows": state.rows, "cols": state.cols,
            "saved_at": datetime.utcnow().isoformat() + "Z",
        })

        out_dir.mkdir(parents=True, exist_ok=True)
        out_path.write_text(json.dumps(out_md, indent=2), encoding="utf-8")
        thumb = out_dir / "map_iso.png"
        try:
            render_iso(state.structure, thumb, cell_px=12,
                       utilities=state.utilities,
                       interactables=state.interactables)
        except Exception as e:
            results.append({"id": vid, "warn": f"render: {e}"})

        results.append({
            "id": vid, "status": "written", "scores": scores,
            "notes": f"placement-only variant of {base_name}: re-run AABB placer "
                     f"with seed {seed}, fixes={fixes['fixed_artifacts']}",
        })
    return results


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--sequences", default="",
                   help="comma-separated sequence ids (e.g. wavefunctions,softbodies)")
    p.add_argument("--map", default="", help="run on a single base map")
    p.add_argument("--n", type=int, default=3,
                   help="number of placement variants per map (default 3)")
    p.add_argument("--force", action="store_true",
                   help="overwrite existing _p<n> directories")
    args = p.parse_args()

    if not args.sequences and not args.map:
        p.print_help(); return 1

    if args.map:
        # Find which sequence the map belongs to (best-effort).
        seq_dir = REPO / "commons" / "maps" / "sequences"
        sid = ""
        for sf in seq_dir.glob("*.json"):
            try:
                sd = json.loads(sf.read_text(encoding="utf-8"))
                seq = next(iter(sd.get("sequences", {}).values()), {}) or {}
                if args.map in (seq.get("maps") or []):
                    sid = sf.stem; break
            except Exception:
                continue
        print(f"  [{sid or '?'}] -> {args.map}")
        results = run_one_map(args.map, sid, args.n, force=args.force)
        emit_manifest(sid or "placement_only", [{"base": args.map, "variants": results}])
        return 0

    sequences = [s.strip() for s in args.sequences.split(",") if s.strip()]
    for sid in sequences:
        try:
            maps = load_sequence_maps(sid)
        except SystemExit as e:
            print(f"  ! {sid}: {e}"); continue
        runs: list[dict] = []
        for base in maps:
            print(f"  [{sid}] -> {base}")
            results = run_one_map(base, sid, args.n, force=args.force)
            runs.append({"base": base, "variants": results})
        manifest = emit_manifest(sid, runs)
        print(f"    wrote {manifest.relative_to(REPO)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
