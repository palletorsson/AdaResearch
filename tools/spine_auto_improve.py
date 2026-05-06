#!/usr/bin/env python3
"""Hill-climb auto-improvement on the current best-per-base variants.

Reads the spine-research manifest, takes every variant flagged
`is_best_for_base`, and generates N mutation candidates whose only goal
is to beat the parent's composite score. Mutations are small and
intentional (shrink the perimeter, smooth a height jump, swap two
artifact cells, drop an unreachable artifact's tier by 1) so each child
is a legible local edit of its parent rather than a fresh roll.

Children that beat their parent are saved as
    <parent_id>_g2_<mutation_kind>
and surfaced to the gallery. The next eval-only pass will replace the
old best-per-base flag with the new winner.

Usage:
    python tools/spine_auto_improve.py
    python tools/spine_auto_improve.py --sequence color
    python tools/spine_auto_improve.py --max-bases 20
    python tools/spine_auto_improve.py --dry-run
"""
from __future__ import annotations

import argparse
import copy
import json
import sys
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))

from map_grammar.ops import MapState                            # noqa: E402
from spine_auto_research import (                                # noqa: E402
    _ensure_artifacts_reachable, _bfs_reachable,
    _place_artifacts_in_variant, _extract_original_artifacts,
    eval_variant, emit_manifest,
)
from spine_eval_only import composite_score, find_phase_for_base   # noqa: E402
from iso_voxel_render import render_iso                          # noqa: E402

MAPS_DIR = REPO / "commons" / "maps"
SPINE_PATH = REPO / "commons" / "maps" / "curriculum_spine.json"
ENCYCLOPEDIA = REPO.parent / "ada_encyclopedia"
MIRROR_DIR = ENCYCLOPEDIA / "public" / "spine-research"


def _parse_h(v) -> int:
    if isinstance(v, int): return v
    if isinstance(v, str):
        try: return int(v)
        except ValueError: return 0
    return 0


def _state_from_map_data(md: dict) -> MapState:
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
                s.structure[r][c] = _parse_h(struct[r][c])
            if r < len(utils) and c < len(utils[r]):
                s.utilities[r][c] = utils[r][c] or " "
            if r < len(interact) and c < len(interact[r]):
                s.interactables[r][c] = interact[r][c] or " "
    return s


def _state_to_map_data(state: MapState, src_md: dict) -> dict:
    md = copy.deepcopy(src_md)
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


# ── Mutations ──────────────────────────────────────────────────────
# Each mutation takes a (state, original_arts) and returns a new state
# (or None to indicate the mutation isn't applicable to this map).

def mut_shrink_perimeter(state: MapState, _arts) -> MapState | None:
    """Remove the outermost ring of cubes if removing it leaves the
    interior intact and walkable. Tightens the budget by ~one row of
    cells without changing the design vocabulary."""
    if state.rows <= 6 or state.cols <= 6: return None
    new = MapState(rows=state.rows - 2, cols=state.cols - 2)
    for r in range(new.rows):
        for c in range(new.cols):
            new.structure[r][c] = state.structure[r + 1][c + 1]
            new.utilities[r][c] = state.utilities[r + 1][c + 1]
            new.interactables[r][c] = state.interactables[r + 1][c + 1]
    return new


def mut_smooth_height_jump(state: MapState, _arts) -> MapState | None:
    """Find a height-≥2 jump between adjacent cells and turn the higher
    cell into a wp ramp instead. Removes the need for the player to use
    the existing wp; flattens the architecture by one notch."""
    new = copy.deepcopy(state)
    for r in range(new.rows):
        for c in range(new.cols):
            for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                nr, nc = r + dr, c + dc
                if not new.in_bounds(nr, nc): continue
                fh, th = new.structure[r][c], new.structure[nr][nc]
                if th - fh >= 2 and (new.utilities[nr][nc] or " ").strip() == "":
                    heading = 0 if dc == 1 else 2 if dc == -1 else 1 if dr == 1 else 3
                    new.utilities[nr][nc] = f"wp:{heading * 90}"
                    return new
    return None


def mut_clear_void_islands(state: MapState, _arts) -> MapState | None:
    """If there are isolated h=1 islands disconnected from spawn,
    fill the void around them with cubes to merge them with the main
    component. Boosts walkable density without changing topology."""
    reach = _bfs_reachable(state)
    if not reach: return None
    new = copy.deepcopy(state)
    added = 0
    for r in range(new.rows):
        for c in range(new.cols):
            if new.structure[r][c] >= 1 and (r, c) not in reach:
                # Walk one cell toward the nearest reachable cell.
                nearest = min(((abs(r - rr) + abs(c - cc), rr, cc)
                               for (rr, cc) in reach), default=None)
                if not nearest: continue
                _, rr, cc = nearest
                # Build one cube along the line.
                step_r = r + (1 if rr > r else -1 if rr < r else 0)
                step_c = c + (1 if cc > c else -1 if cc < c else 0)
                if new.in_bounds(step_r, step_c) and new.structure[step_r][step_c] == 0:
                    new.structure[step_r][step_c] = 1
                    added += 1
                if added >= 2: break
        if added >= 2: break
    return new if added > 0 else None


def mut_flatten_top_tier(state: MapState, _arts) -> MapState | None:
    """If the map has any h=4 or h=5 cells, knock them down to h=3.
    Tames over-tall maps and reclaims voxels for the budget."""
    new = copy.deepcopy(state)
    changed = 0
    for r in range(new.rows):
        for c in range(new.cols):
            if new.structure[r][c] > 3:
                new.structure[r][c] = 3; changed += 1
    return new if changed > 0 else None


def mut_replace_artifacts(state: MapState, original_arts) -> MapState | None:
    """Clear all interactables and re-run the AABB placer with a
    different seed permutation. Lets the placer revisit decisions made
    on the parent, often producing tighter clusters near spawn."""
    if not original_arts: return None
    new = copy.deepcopy(state)
    for r in range(new.rows):
        for c in range(new.cols):
            new.interactables[r][c] = " "
    import random
    arts = list(original_arts)
    random.Random(7919).shuffle(arts)
    _place_artifacts_in_variant(new, arts)
    return new


MUTATIONS: dict[str, callable] = {
    "shrink":    mut_shrink_perimeter,
    "smooth":    mut_smooth_height_jump,
    "merge":     mut_clear_void_islands,
    "flatten":   mut_flatten_top_tier,
    "replace":   mut_replace_artifacts,
}


# ── Main loop ──────────────────────────────────────────────────────
def improve_one(entry: dict, spine: dict, dry_run: bool) -> list[dict]:
    """For one best-per-base entry, try each mutation; keep children
    that beat the parent's composite score."""
    parent_id = entry["id"]
    parent_path = MAPS_DIR / parent_id / "map_data.json"
    if not parent_path.exists():
        return [{"parent": parent_id, "error": "missing"}]
    parent_md = json.loads(parent_path.read_text(encoding="utf-8"))
    state0 = _state_from_map_data(parent_md)
    base_name = entry.get("derived_from", parent_id)
    seq_id = entry.get("sequence", "")
    phase = find_phase_for_base(base_name, seq_id, spine)

    parent_score_obj = composite_score(parent_md, phase)
    parent_score = parent_score_obj["score"]

    # Read the originals from the BASE map, not the parent variant — so
    # the placer's "replace" mutation has the full artifact set.
    base_md_path = MAPS_DIR / base_name / "map_data.json"
    original_arts = []
    if base_md_path.exists():
        try:
            base_md = json.loads(base_md_path.read_text(encoding="utf-8"))
            original_arts = _extract_original_artifacts(base_md)
        except Exception:
            pass

    results = []
    for kind, mutate in MUTATIONS.items():
        try:
            new_state = mutate(state0, original_arts)
        except Exception as e:
            results.append({"kind": kind, "error": str(e)})
            continue
        if new_state is None:
            results.append({"kind": kind, "status": "n/a"})
            continue
        # All mutations re-run the reachability fixer so the child is
        # always playable end-to-end.
        _ensure_artifacts_reachable(new_state)
        new_md = _state_to_map_data(new_state, parent_md)
        # Stamp child metadata.
        mi = new_md.setdefault("map_info", {})
        mi.setdefault("metadata", {})
        child_id = f"{parent_id}_g2_{kind}"
        mi["lookup_name"] = child_id
        mi["name"] = child_id.replace("_", " ")
        mi["metadata"].update({
            "spine_research": True,
            "auto_improved": True,
            "parent_id": parent_id,
            "mutation": kind,
            "parent_score": parent_score,
            "saved_at": datetime.utcnow().isoformat() + "Z",
        })
        # Score.
        child_eval = eval_variant(new_state)
        child_score_obj = composite_score(new_md, phase)
        child_score = child_score_obj["score"]
        mi["metadata"]["scores"] = child_eval
        mi["metadata"]["composite_score"] = child_score_obj
        # Decide.
        if child_score > parent_score:
            results.append({
                "kind": kind, "status": "improved",
                "parent_score": parent_score, "child_score": child_score,
                "child_id": child_id,
            })
            if not dry_run:
                out_dir = MAPS_DIR / child_id
                out_dir.mkdir(parents=True, exist_ok=True)
                (out_dir / "map_data.json").write_text(
                    json.dumps(new_md, indent=2), encoding="utf-8")
                try:
                    render_iso(new_state.structure, out_dir / "map_iso.png",
                               cell_px=12, utilities=new_state.utilities,
                               interactables=new_state.interactables)
                    src_png = out_dir / "map_iso.png"
                    if src_png.exists() and ENCYCLOPEDIA.exists():
                        import shutil
                        MIRROR_DIR.mkdir(parents=True, exist_ok=True)
                        shutil.copy2(src_png, MIRROR_DIR / f"{child_id}.png")
                except Exception:
                    pass
        else:
            results.append({
                "kind": kind, "status": "rejected",
                "parent_score": parent_score, "child_score": child_score,
            })
    return [{"parent": parent_id, "results": results}]


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--sequence", default="", help="limit to one sequence")
    p.add_argument("--max-bases", type=int, default=0,
                   help="stop after this many bases (0 = all)")
    p.add_argument("--dry-run", action="store_true",
                   help="print proposals without writing")
    args = p.parse_args()

    spine = json.loads(SPINE_PATH.read_text(encoding="utf-8"))
    manifest_path = MIRROR_DIR / "manifest.json"
    if not manifest_path.exists():
        sys.exit(f"missing {manifest_path}")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    entries = manifest.get("entries", [])

    bests = [e for e in entries if e.get("is_best_for_base")
             and (not args.sequence or e.get("sequence") == args.sequence)]
    if args.max_bases:
        bests = bests[:args.max_bases]
    print(f"  scope: {len(bests)} best-per-base candidates")

    totals = {"improved": 0, "rejected": 0, "na": 0,
              "improved_bases": 0, "no_improvement_bases": 0}
    new_entries: list[dict] = []
    for entry in bests:
        out = improve_one(entry, spine, args.dry_run)
        for o in out:
            results = o.get("results", [])
            improved = [r for r in results if r.get("status") == "improved"]
            for r in results:
                if r.get("status") == "improved":
                    totals["improved"] += 1
                elif r.get("status") == "rejected":
                    totals["rejected"] += 1
                else:
                    totals["na"] += 1
            if improved:
                totals["improved_bases"] += 1
                # Print best gain for this parent.
                best_child = max(improved, key=lambda r: r["child_score"])
                gain = best_child["child_score"] - best_child["parent_score"]
                print(f"  + {o['parent']:55s} +{gain:2d}  ({best_child['kind']})")
                new_entries.extend({
                    "id": r["child_id"],
                    "notes": f"auto-improved from {o['parent']} via {r['kind']} (+{r['child_score']-r['parent_score']})",
                    "image": f"/spine-research/{r['child_id']}.png",
                    "map_name": r["child_id"],
                    "derived_from": entry.get("derived_from", o['parent']),
                    "sequence": entry.get("sequence"),
                    "verdict": "exemplary" if r["child_score"] >= 95 else
                               "strong" if r["child_score"] >= 85 else "working",
                    "score": r["child_score"],
                    "auto_improved": True,
                    "parent_id": o['parent'],
                    "mutation": r["kind"],
                } for r in improved)
            else:
                totals["no_improvement_bases"] += 1

    # Splice new entries into the manifest.
    if new_entries and not args.dry_run:
        manifest["entries"].extend(new_entries)
        manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
        print(f"\n  wrote {len(new_entries)} improved entries to manifest")

    print(f"\n=== improvement loop ===")
    print(f"  parents tried:        {len(bests)}")
    print(f"  parents improved:     {totals['improved_bases']}")
    print(f"  parents at peak:      {totals['no_improvement_bases']}")
    print(f"  child wins:           {totals['improved']}")
    print(f"  child rejections:     {totals['rejected']}")
    print(f"  mutations not applic: {totals['na']}")
    if args.dry_run:
        print("(dry run — no writes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
