"""tools/place.py — the shipping placement CLI.

Auto-selects the right placement engine for a map based on its
characteristics (sequence membership, name pattern, artifact count, size),
applies it, optionally writes back to the map (with .bak backup).

Three engines, three jobs (as the auto-research data showed):
  - humanoid_walker:     curriculum-arc maps where encounter order matters
                         (decisively wins on real maps; #1 on Point_Tests)
  - hybrid:              chambers, principle maps, single-centerpiece rooms
                         (deterministic, lowest variance, best constraints)
  - simulated_annealing: opt-in heavy-compute mode for maps that need it
                         (slightly higher peaks; ~100× the compute)

Usage:
  python tools/place.py --map=Point_Tests
        # auto-select, write sibling Point_Tests_Placed (safe)
  python tools/place.py --map=Point_Tests --in-place
        # auto-select, write back to Point_Tests/map_data.json (with .bak)
  python tools/place.py --map=Point_Tests --engine=hybrid
        # manual override
  python tools/place.py --batch=Point_Tests,Noise_Perlin_Simplex --in-place
        # batch mode

Output: ada_run/placement_log.json with per-map result entries.
"""
from __future__ import annotations

import argparse
import json
import random
import shutil
import sys
from pathlib import Path
from typing import Optional

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
MAPS_DIR = ROOT / "commons" / "maps"
SPINE_PATH = ROOT / "commons" / "maps" / "curriculum_spine.json"
SEQ_DIR = ROOT / "commons" / "maps" / "sequences"
LOG_PATH = ROOT / "ada_run" / "placement_log.json"

sys.path.insert(0, str(ROOT / "tools"))
from placement_research import (    # type: ignore
    Artifact, Room, Placement, score_placement, render_ascii,
    strategy_hybrid, strategy_simulated_annealing, strategy_humanoid_walker,
    strategy_focal_composition, strategy_pacing_arc, strategy_alexander,
    strategy_promenade, strategy_tile_wfc,
)
from place_artifacts import (
    existing_placements, room_from_map, parse_lookup_name, artifact_from_registry,
)
from walk_evaluator import walk_placement


# ─────────────────────────────────────────────────────────────────────
# Engine routing
# ─────────────────────────────────────────────────────────────────────

ENGINES = {
    "humanoid_walker":     strategy_humanoid_walker,
    "hybrid":              strategy_hybrid,
    "simulated_annealing": strategy_simulated_annealing,
    "focal_composition":   strategy_focal_composition,
    "pacing_arc":          strategy_pacing_arc,
    "alexander":           strategy_alexander,
    "promenade":           strategy_promenade,
    "tile_wfc":            strategy_tile_wfc,
}


def map_in_spine(map_name: str) -> Optional[dict]:
    """Return spine metadata if map belongs to a spine sequence, else None."""
    if not SPINE_PATH.exists():
        return None
    with open(SPINE_PATH, "r", encoding="utf-8") as f:
        spine = json.load(f)
    spine_sequences = {entry["name"]: entry for entry in spine["spine"]["sequences"]}
    # Check each sequence file for the map
    for seq_file in SEQ_DIR.glob("*.json"):
        try:
            with open(seq_file, "r", encoding="utf-8") as f:
                sf = json.load(f)
        except (json.JSONDecodeError, OSError):
            continue
        seqs = sf.get("sequences", {})
        if not isinstance(seqs, dict): continue
        for seq_id, seq in seqs.items():
            maps = seq.get("maps", []) if isinstance(seq, dict) else []
            if map_name in maps:
                return {
                    "sequence_id":     seq_id,
                    "in_spine":        seq_id in spine_sequences,
                    "phase":           spine_sequences.get(seq_id, {}).get("phase"),
                    "order":           spine_sequences.get(seq_id, {}).get("order"),
                }
    return None


def auto_select_engine(map_name: str, map_data: dict, n_artifacts: int,
                       sequence_info: Optional[dict]) -> tuple[str, str]:
    """Return (engine_name, reason).

    Routing by MAP TYPE (the design tradition that fits the room's purpose):
      - Gallery_* / Showcase_* / Exhibition_*   → focal_composition (interior design)
      - Hub_* / Commons_* / Sitting_*           → alexander (#185 sitting circle)
      - Chamber_*                               → hybrid (small + tight constraints)
      - *_Principle / *_Assembly_Principle      → hybrid (clean canonical hits)
      - in-spine + many artifacts               → pacing_arc (Mario 4-beat curriculum walk)
      - in-spine + medium                       → humanoid_walker (encounter order)
      - big lab / big room                      → simulated_annealing (heavy compute)
      - default                                  → humanoid_walker (general)
    """
    name = map_name
    is_chamber = name.startswith("Chamber_") or name.endswith("_Chamber") or "_Chamber_" in name
    is_principle = name.endswith("_Principle") or "_Principle_" in name or name.endswith("_Assembly_Principle")
    is_gallery = name.startswith(("Gallery_", "Showcase_", "Exhibition_")) or "Gallery_" in name
    is_hub = name.startswith(("Hub_", "Commons_", "Sitting_", "Atlas_"))
    is_lab = "Lab" in name or name.startswith("MANN_")
    in_spine = sequence_info is not None and sequence_info.get("in_spine", False)

    dims = map_data["map_info"].get("dimensions", {})
    width = int(dims.get("width", 10) or 10)
    depth = int(dims.get("depth", 6) or 6)
    area = width * depth
    # Aspect ratio: depth/width. >= 1.8 = corridor (Palle's signature shape).
    aspect = depth / max(1, width)
    is_corridor = aspect >= 1.8 or width <= 7

    # 1. Specific MAP TYPE routing
    if is_chamber and n_artifacts <= 4:
        return "hybrid", "chamber + few artifacts → hybrid (tight constraint optimization)"
    if is_principle:
        return "hybrid", "principle map → hybrid (clean canonical hits matter)"
    if is_gallery and n_artifacts >= 3:
        return "focal_composition", f"gallery/showcase map → focal_composition (centerpiece + supporting cast, interior-design pattern)"
    if is_hub and n_artifacts >= 4:
        return "alexander", f"hub/commons map → alexander (sitting-circle pattern #185)"

    # 2. Corridor-shaped in-spine maps → PROMENADE (Palle's scroll style)
    if is_corridor and in_spine and n_artifacts >= 3:
        return "promenade", f"corridor {width}×{depth} (aspect {aspect:.1f}) in-spine → promenade (CSS-column-flow scroll)"
    if is_corridor and n_artifacts >= 3:
        return "promenade", f"corridor {width}×{depth} (aspect {aspect:.1f}) → promenade (scroll layout)"

    # 3. By size + role
    if n_artifacts >= 8 and area >= 200:
        if in_spine and n_artifacts >= 5:
            return "pacing_arc", f"{n_artifacts} artifacts in-spine in {area}-cell room → pacing_arc (Mario 4-beat curriculum walk)"
        return "simulated_annealing", f"{n_artifacts} artifacts in {area}-cell room → sim_annealing (heavy compute justified)"

    # 4. In-spine sequences default to humanoid_walker (proven on real maps)
    if in_spine and n_artifacts >= 3:
        return "humanoid_walker", f"in-spine sequence + {n_artifacts} artifacts → humanoid_walker (encounter order matters)"

    # 4. General multi-artifact default
    if n_artifacts >= 3:
        return "humanoid_walker", f"{n_artifacts} artifacts → humanoid_walker (default for multi-artifact maps)"
    return "hybrid", f"{n_artifacts} artifacts → hybrid (default for sparse maps)"


# ─────────────────────────────────────────────────────────────────────
# Apply
# ─────────────────────────────────────────────────────────────────────

def apply_to_map(map_name: str, engine: Optional[str] = None,
                  in_place: bool = False, seed: int = 0,
                  only_improve: bool = False, dry_run: bool = False) -> dict:
    src = MAPS_DIR / map_name / "map_data.json"
    if not src.exists():
        raise FileNotFoundError(f"map_data.json not found: {src}")
    with open(src, "r", encoding="utf-8") as f:
        original = json.load(f)

    room, _, _ = room_from_map(original)
    old_placements = existing_placements(original, room)
    if not old_placements:
        raise ValueError(f"no placeable artifacts found in {map_name}")

    artifacts = [p.artifact for p in old_placements]
    sequence_info = map_in_spine(map_name)

    # Engine selection
    chosen_reason = None
    if engine is None:
        engine, chosen_reason = auto_select_engine(map_name, original, len(artifacts), sequence_info)

    if engine not in ENGINES:
        raise ValueError(f"unknown engine: {engine}")
    fn = ENGINES[engine]

    # Score before
    before_constraint = score_placement(room, old_placements)
    before_walk = walk_placement(room, old_placements)

    # Apply
    rng = random.Random(seed)
    new_placements = fn(room, artifacts, rng)
    after_constraint = score_placement(room, new_placements)
    after_walk = walk_placement(room, new_placements)

    # Build new map
    width = int(room.width); depth = int(room.depth)
    new_inter = [[" " for _ in range(width)] for _ in range(depth)]
    # Preserve original tokens (rotation/config) by lookup_name
    name_to_token: dict[str, str] = {}
    for r_row in original["layers"]["interactables"]:
        for tok in r_row:
            if isinstance(tok, str):
                base = parse_lookup_name(tok)
                if base and base not in name_to_token:
                    name_to_token[base] = tok
    for p in new_placements:
        r = max(0, min(depth - 1, p.row))
        c = max(0, min(width - 1, p.col))
        new_inter[r][c] = name_to_token.get(p.artifact.lookup_name,
                                            f"{p.artifact.lookup_name}:0:0.0")

    new_map = json.loads(json.dumps(original))
    new_map["layers"]["interactables"] = new_inter
    if not in_place:
        new_map["map_info"]["name"] = f"{map_name}_Placed"
        new_map["map_info"]["lookup_name"] = f"{map_name}_Placed"
    new_map["map_info"]["version"] = f"placed-{engine}"
    new_map["map_info"]["description"] = (
        (new_map["map_info"].get("description") or "") +
        f"\n\n[Placement applied {engine} engine — "
        f"constraint {before_constraint['total']:.3f}→{after_constraint['total']:.3f}, "
        f"walkability {before_walk.get('walkability', 0):.3f}→"
        f"{after_walk.get('walkability', 0):.3f}]"
    ).strip()

    # Improvement guard: combined score must be strictly better
    combined_before = before_constraint["total"] * 0.6 + before_walk.get("walkability", 0) * 0.4
    combined_after = after_constraint["total"] * 0.6 + after_walk.get("walkability", 0) * 0.4
    is_improvement = combined_after > combined_before + 0.005  # small epsilon

    written = False
    if dry_run:
        out_path = "(dry-run: not written)"
    elif only_improve and not is_improvement:
        out_path = f"(skipped: Δcombined={combined_after - combined_before:+.3f} < 0.005)"
    elif in_place:
        backup = src.with_suffix(".json.bak")
        if not backup.exists():
            shutil.copy2(src, backup)
        with open(src, "w", encoding="utf-8") as f:
            json.dump(new_map, f, indent="\t")
        out_path = str(src.relative_to(ROOT))
        written = True
    else:
        sibling_dir = MAPS_DIR / f"{map_name}_Placed"
        sibling_dir.mkdir(exist_ok=True)
        with open(sibling_dir / "map_data.json", "w", encoding="utf-8") as f:
            json.dump(new_map, f, indent="\t")
        out_path = str((sibling_dir / "map_data.json").relative_to(ROOT))
        written = True

    return {
        "map":             map_name,
        "engine":          engine,
        "reason":          chosen_reason or "manual override",
        "in_place":        in_place,
        "n_artifacts":     len(artifacts),
        "before": {
            "constraint":  round(before_constraint["total"], 3),
            "walkability": round(before_walk.get("walkability", 0), 3),
            "combined":    round(combined_before, 3),
        },
        "after": {
            "constraint":  round(after_constraint["total"], 3),
            "walkability": round(after_walk.get("walkability", 0), 3),
            "combined":    round(combined_after, 3),
        },
        "delta": {
            "constraint":  round(after_constraint["total"] - before_constraint["total"], 3),
            "walkability": round(after_walk.get("walkability", 0) - before_walk.get("walkability", 0), 3),
            "combined":    round(combined_after - combined_before, 3),
        },
        "is_improvement":  is_improvement,
        "written":         written,
        "output":          out_path,
        "sequence_info":   sequence_info,
    }


# ─────────────────────────────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────────────────────────────

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--map", type=str, help="single map name")
    p.add_argument("--batch", type=str, help="comma-separated map names")
    p.add_argument("--engine", type=str, choices=list(ENGINES.keys()),
                   help="manual override (default: auto-select)")
    p.add_argument("--in-place", action="store_true",
                   help="overwrite original map (with .bak backup); default: write sibling")
    p.add_argument("--only-improve", action="store_true",
                   help="skip writing if combined score doesn't improve by 0.005+")
    p.add_argument("--dry-run", action="store_true",
                   help="compute scores but don't write")
    p.add_argument("--seed", type=int, default=0)
    args = p.parse_args()

    targets: list[str] = []
    if args.batch:
        targets = [s.strip() for s in args.batch.split(",") if s.strip()]
    elif args.map:
        targets = [args.map]
    else:
        p.error("specify --map or --batch")

    results = []
    print(f"placing {len(targets)} map(s)  ·  {'IN-PLACE' if args.in_place else 'SIBLING'} mode")
    print()

    for m in targets:
        try:
            r = apply_to_map(m, engine=args.engine, in_place=args.in_place,
                             seed=args.seed, only_improve=args.only_improve,
                             dry_run=args.dry_run)
        except (FileNotFoundError, ValueError) as e:
            print(f"  SKIP {m}: {e}")
            continue
        results.append(r)
        dc = r["delta"]["constraint"]
        dw = r["delta"]["walkability"]
        dcomb = r["delta"]["combined"]
        sign_c = "+" if dc >= 0 else ""
        sign_w = "+" if dw >= 0 else ""
        sign_co = "+" if dcomb >= 0 else ""
        marker = "✓" if r["written"] else ("·" if args.dry_run else "✗")
        print(f"  {marker} {r['map']:35} engine={r['engine']:20} "
              f"C={r['before']['constraint']:.2f}→{r['after']['constraint']:.2f} ({sign_c}{dc:.2f})  "
              f"W={r['before']['walkability']:.2f}→{r['after']['walkability']:.2f} ({sign_w}{dw:.2f})  "
              f"Σ={sign_co}{dcomb:.3f}")
        print(f"      reason: {r['reason']}")
        print(f"      output: {r['output']}")
        print()

    # Log
    LOG_PATH.parent.mkdir(exist_ok=True)
    log_existing = []
    if LOG_PATH.exists():
        try:
            with open(LOG_PATH, "r", encoding="utf-8") as f:
                log_existing = json.load(f)
        except (json.JSONDecodeError, OSError):
            log_existing = []
    log_existing.extend(results)
    with open(LOG_PATH, "w", encoding="utf-8") as f:
        json.dump(log_existing, f, indent=2)
    print(f"logged {len(results)} entries to {LOG_PATH.relative_to(ROOT)}")

    if results:
        c_deltas = [r["delta"]["constraint"] for r in results]
        w_deltas = [r["delta"]["walkability"] for r in results]
        improved_c = sum(1 for d in c_deltas if d > 0)
        improved_w = sum(1 for d in w_deltas if d > 0)
        print()
        print(f"summary: {len(results)} maps processed")
        print(f"  constraint improved: {improved_c}/{len(results)}  mean Δ={sum(c_deltas)/len(c_deltas):+.3f}")
        print(f"  walkability improved: {improved_w}/{len(results)}  mean Δ={sum(w_deltas)/len(w_deltas):+.3f}")


if __name__ == "__main__":
    main()
