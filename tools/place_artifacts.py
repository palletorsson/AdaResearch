"""Apply the hybrid placement algorithm to a real existing map.

Takes a map name, reads its map_data.json, extracts the distinct artifacts
from the interactables layer, looks up each artifact's spatial_needs from
the registry, runs strategy_hybrid (from placement_research.py) to produce
new positions, writes a sibling map `<MapName>_Hybrid` with the same
structure/utilities but the new placements.

Then re-scores the placement with the same scorer used in the auto-research.

Run:
  python tools/place_artifacts.py --map=Noise_Perlin_Simplex
  python tools/place_artifacts.py --map=Point_Tests --strategy=simulated_annealing
  python tools/place_artifacts.py --batch=Random_Four,Noise_Perlin_Simplex,Point_Tests

Output: commons/maps/<MapName>_Hybrid/map_data.json + a comparison row in
        doc/placement_research/real_map_results.json
"""
from __future__ import annotations

import argparse
import json
import random
import re
import sys
import io
from pathlib import Path
from typing import Optional

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
MAPS_DIR = ROOT / "commons" / "maps"
REGISTRY_DIR = ROOT / "commons" / "artifacts" / "registry"
RESULTS_DIR = ROOT / "doc" / "placement_research"

# Import the strategies + scorer from the research tool
sys.path.insert(0, str(ROOT / "tools"))
from placement_research import (    # type: ignore
    Artifact, Room, Placement, score_placement, render_ascii,
    strategy_hybrid, strategy_simulated_annealing, strategy_rule_based,
    strategy_sdf, strategy_fold, strategy_humanoid_walker,
)


# ─────────────────────────────────────────────────────────────────────
# Parse interactable tokens — handle the messy formats
# ─────────────────────────────────────────────────────────────────────

TOKEN_RE = re.compile(r"^([a-zA-Z_][a-zA-Z0-9_]*)(?:[:#]|$)")


def parse_lookup_name(token: str) -> Optional[str]:
    """Extract just the lookup_name from any interactable token.
    Examples:
      'point' -> 'point'
      'point:0:0.0' -> 'point'
      'facade_builder:180:1.0#plan_path:res://...' -> 'facade_builder'
    """
    if not token or token.strip() == "":
        return None
    s = token.strip()
    # Match leading identifier
    m = TOKEN_RE.match(s)
    if not m:
        return None
    return m.group(1)


# ─────────────────────────────────────────────────────────────────────
# Look up spatial_needs from the registry
# ─────────────────────────────────────────────────────────────────────

_registry_cache: dict[str, dict] = {}


def load_registry() -> dict[str, dict]:
    """Build a flat dict: lookup_name -> {spatial_needs: {...}, description: ...}."""
    if _registry_cache:
        return _registry_cache
    for f in REGISTRY_DIR.glob("*.json"):
        try:
            with open(f, "r", encoding="utf-8") as fp:
                data = json.load(fp)
        except (json.JSONDecodeError, OSError):
            continue
        # Registry can be { "artifacts": [...] } or other shapes; walk all leaves
        _collect(data, _registry_cache)
    return _registry_cache


def _collect(node, out: dict[str, dict]) -> None:
    """Recursively walk a registry JSON tree, harvest any dict with
    lookup_name + spatial_needs."""
    if isinstance(node, dict):
        if "lookup_name" in node and isinstance(node["lookup_name"], str):
            out[node["lookup_name"]] = node
        for v in node.values():
            _collect(v, out)
    elif isinstance(node, list):
        for v in node:
            _collect(v, out)


def artifact_from_registry(lookup_name: str) -> Optional[Artifact]:
    """Look up an artifact's spatial_needs in the registry, build an Artifact."""
    reg = load_registry()
    entry = reg.get(lookup_name)
    if not entry:
        return None
    sn = entry.get("spatial_needs", {}) or {}
    clr = sn.get("clearance", {}) or {}
    return Artifact(
        lookup_name=lookup_name,
        footprint_cells=sn.get("footprint_cells", 1),
        clearance_front=clr.get("front", 1),
        clearance_back=clr.get("back", 1),
        clearance_left=clr.get("left", 1),
        clearance_right=clr.get("right", 1),
        player_position=sn.get("player_position", "front"),
        wall_backing=bool(sn.get("wall_backing", False)),
        orientation=sn.get("orientation", "face_approach"),
        isolation=sn.get("isolation", 0),
        cluster_with=sn.get("cluster_with", []) or [],
        preferred_zone=sn.get("preferred_zone", "any"),
    )


# ─────────────────────────────────────────────────────────────────────
# Pick room dimensions from existing map; locate spawn/teleporter
# ─────────────────────────────────────────────────────────────────────

def room_from_map(map_data: dict) -> tuple[Room, str, str]:
    """Build a Room and find spawn+teleporter token names from utilities layer."""
    info = map_data["map_info"]
    dims = info.get("dimensions", {})
    width = dims.get("width", 10)
    depth = dims.get("depth", 6)
    util_layer = map_data["layers"]["utilities"]
    sp_r = sp_c = -1
    te_r = te_c = -1
    sp_token = "sp"; te_token = "t"
    for r, row in enumerate(util_layer):
        for c, tok in enumerate(row):
            if not isinstance(tok, str): continue
            base = parse_lookup_name(tok) or tok.strip()
            if base.startswith("sp"):
                sp_r, sp_c = r, c
                sp_token = tok
            elif base == "t" or base.startswith("teleporter"):
                te_r, te_c = r, c
                te_token = tok
    if sp_r < 0:
        sp_r, sp_c = depth - 1, width // 2
    if te_r < 0:
        te_r, te_c = 0, width // 2
    return Room(width=width, depth=depth, spawn_row=sp_r, spawn_col=sp_c,
                teleporter_row=te_r, teleporter_col=te_c), sp_token, te_token


def existing_placements(map_data: dict, room: Room) -> list[Placement]:
    """Reconstruct Placement objects from the map's current interactables.
    Uses each artifact's spatial_needs from the registry where available."""
    inter = map_data["layers"]["interactables"]
    seen: dict[str, list[tuple[int, int]]] = {}
    for r, row in enumerate(inter):
        for c, tok in enumerate(row):
            if not isinstance(tok, str): continue
            name = parse_lookup_name(tok)
            if not name: continue
            seen.setdefault(name, []).append((r, c))
    placements: list[Placement] = []
    for name, cells in seen.items():
        # Use the FIRST occurrence as the placement
        a = artifact_from_registry(name)
        if a is None:
            continue
        r, c = cells[0]
        placements.append(Placement(a, r, c))
    return placements


# ─────────────────────────────────────────────────────────────────────
# Apply hybrid placement to an existing map
# ─────────────────────────────────────────────────────────────────────

STRATEGY_FNS = {
    "hybrid": strategy_hybrid,
    "simulated_annealing": strategy_simulated_annealing,
    "rule_based": strategy_rule_based,
    "sdf": strategy_sdf,
    "fold": strategy_fold,
    "humanoid_walker": strategy_humanoid_walker,
}


def apply_strategy(map_name: str, strategy: str = "hybrid", seed: int = 0) -> dict:
    """Read a map, apply the strategy, write a sibling map, return scores."""
    src = MAPS_DIR / map_name / "map_data.json"
    if not src.exists():
        raise FileNotFoundError(f"map_data.json not found: {src}")
    with open(src, "r", encoding="utf-8") as f:
        original = json.load(f)

    room, sp_tok, te_tok = room_from_map(original)
    old_placements = existing_placements(original, room)
    if not old_placements:
        raise ValueError(f"no placeable artifacts found in {map_name}")

    # Score the EXISTING placement
    before_metrics = score_placement(room, old_placements)

    # Run the strategy on the SAME set of artifacts
    artifacts = [p.artifact for p in old_placements]
    fn = STRATEGY_FNS.get(strategy)
    if not fn:
        raise ValueError(f"unknown strategy: {strategy}")
    rng = random.Random(seed)
    new_placements = fn(room, artifacts, rng)
    after_metrics = score_placement(room, new_placements)

    # Build the new map_data.json: keep structure, utilities; rewrite interactables
    width = room.width; depth = room.depth
    new_interactables = [[" " for _ in range(width)] for _ in range(depth)]
    for p in new_placements:
        r = max(0, min(depth - 1, p.row))
        c = max(0, min(width - 1, p.col))
        # Try to preserve the original full token (rotation/config) from the source
        orig_token = None
        for rr, row in enumerate(original["layers"]["interactables"]):
            for cc, tok in enumerate(row):
                if isinstance(tok, str) and parse_lookup_name(tok) == p.artifact.lookup_name:
                    orig_token = tok
                    break
            if orig_token: break
        new_interactables[r][c] = orig_token if orig_token else f"{p.artifact.lookup_name}:0:0.0"

    new_map_name = f"{map_name}_Hybrid" if strategy == "hybrid" else f"{map_name}_{strategy.title().replace('_', '')}"
    new_dir = MAPS_DIR / new_map_name
    new_dir.mkdir(exist_ok=True)
    new_map = json.loads(json.dumps(original))   # deep copy
    new_map["map_info"]["name"] = new_map_name
    new_map["map_info"]["lookup_name"] = new_map_name
    new_map["map_info"]["description"] = (
        f"Auto-placement variant of {map_name} using the '{strategy}' "
        f"strategy from placement_research. Score: "
        f"before={before_metrics['total']:.3f}, after={after_metrics['total']:.3f}."
    )
    new_map["map_info"]["version"] = f"auto-placement-{strategy}"
    new_map["layers"]["interactables"] = new_interactables
    with open(new_dir / "map_data.json", "w", encoding="utf-8") as f:
        json.dump(new_map, f, indent="\t")

    return {
        "map":             map_name,
        "new_map":         new_map_name,
        "strategy":        strategy,
        "artifacts":       [p.artifact.lookup_name for p in old_placements],
        "before":          {k: round(v, 3) for k, v in before_metrics.items()},
        "after":           {k: round(v, 3) for k, v in after_metrics.items()},
        "delta":           round(after_metrics["total"] - before_metrics["total"], 3),
        "before_ascii":    render_ascii(room, old_placements),
        "after_ascii":     render_ascii(room, new_placements),
    }


# ─────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--map", type=str, help="single map name")
    p.add_argument("--batch", type=str, help="comma-separated map names")
    p.add_argument("--strategy", type=str, default="hybrid",
                   choices=list(STRATEGY_FNS.keys()),
                   help="placement strategy")
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
    for m in targets:
        print(f"\n--- {m} ---")
        try:
            r = apply_strategy(m, args.strategy, args.seed)
        except (FileNotFoundError, ValueError) as e:
            print(f"  skip: {e}")
            continue
        delta = r["delta"]
        marker = "+" if delta >= 0 else "-"
        sign = marker if delta != 0 else "="
        print(f"  artifacts:   {len(r['artifacts'])}")
        print(f"  before:      {r['before']['total']:.3f}")
        print(f"  after:       {r['after']['total']:.3f}")
        print(f"  delta:       {sign}{abs(delta):.3f}")
        print(f"  new map:     commons/maps/{r['new_map']}/")
        print(f"")
        print(f"  BEFORE:                              AFTER:")
        before = r["before_ascii"]; after = r["after_ascii"]
        for a, b in zip(before, after):
            print(f"    {a:<20}    {b}")
        results.append(r)

    if results:
        out = RESULTS_DIR / "real_map_results.json"
        with open(out, "w", encoding="utf-8") as f:
            json.dump(results, f, indent=2)
        print(f"\nwrote {out}")

        # Aggregate
        deltas = [r["delta"] for r in results]
        wins = sum(1 for d in deltas if d > 0)
        losses = sum(1 for d in deltas if d < 0)
        avg = sum(deltas) / len(deltas)
        print(f"\nsummary: {wins}/{len(results)} maps improved, {losses} regressed, mean Δ={avg:+.3f}")


if __name__ == "__main__":
    main()
