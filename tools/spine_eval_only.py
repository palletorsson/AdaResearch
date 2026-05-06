#!/usr/bin/env python3
"""Re-score every spine-research variant in place — no regeneration.

Walks commons/maps/<base>_v*_<strategy>/map_data.json and computes a
composite 0–100 score per variant from:
    - verdict             (30 pts)
    - BFS reachability    (20 pts)
    - artifacts placed    (15 pts: ratio × 15)
    - walkability density (10 pts: sweet-spot 30-70%)
    - n_heights >= 2      (10 pts)
    - budget compliance   (10 pts: rows*cols within cells_max)
    - path-budget compliance (5 pts: BFS path <= phase path_budget)

Score and reasons get stamped onto each map_data.json's metadata.scores
field, and the gallery manifest gets re-written with the new score and
a `is_best_for_base` flag on the highest-scoring variant per parent.

Usage:
    python tools/spine_eval_only.py
    python tools/spine_eval_only.py --sequence color
    python tools/spine_eval_only.py --dry-run
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
from collections import defaultdict, deque
from pathlib import Path
from datetime import datetime

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))

from map_grammar.budget import BUDGET_BY_PHASE, RELAXED   # noqa: E402

MAPS_DIR = REPO / "commons" / "maps"
SPINE_PATH = REPO / "commons" / "maps" / "curriculum_spine.json"
ENCYCLOPEDIA = REPO.parent / "ada_encyclopedia"
MIRROR_DIR = ENCYCLOPEDIA / "public" / "spine-research"

VERDICT_PTS = {"exemplary": 30, "strong": 22, "working": 14, "weak": 6, "broken": 0}


def parse_height(v) -> int:
    if isinstance(v, int): return v
    if isinstance(v, str):
        try: return int(v)
        except ValueError: return 0
    return 0


def bfs_path_steps(struct: list[list], utils: list[list]) -> int | None:
    """Same rules as the player viewer: spawn → teleport via cubes,
    drops <= 1 free, climbs require wp on either side."""
    rows = len(struct)
    cols = max((len(r) for r in struct), default=0)
    spawn = tele = None
    heights: list[list[int]] = []
    walk: set[tuple[int, int]] = set()
    tele_set: set[tuple[int, int]] = set()
    for r in range(rows):
        hr: list[int] = []
        for c in range(cols):
            h = parse_height(struct[r][c] if c < len(struct[r]) else 0)
            hr.append(h)
            u = (utils[r][c] if r < len(utils) and c < len(utils[r]) else "" or "").strip() \
                if r < len(utils) else ""
            if u in ("s", "sp"): spawn = (r, c)
            elif u in ("t", "tp"): tele = (r, c); tele_set.add((r, c))
            if h >= 1 or u.startswith(("wp", "tc")) or u in ("t", "tp"):
                walk.add((r, c))
        heights.append(hr)
    if spawn is None or tele is None:
        return None

    def is_ramp(r: int, c: int) -> bool:
        if r >= len(utils) or c >= len(utils[r]): return False
        u = (utils[r][c] or "").strip()
        return u.startswith("wp") or u in ("r",) or u.startswith("r:")
    def is_tc(r: int, c: int) -> bool:
        if r >= len(utils) or c >= len(utils[r]): return False
        u = (utils[r][c] or "").strip()
        return u.startswith("tc")

    seen = {spawn}
    q: deque = deque([(spawn, 0)])
    while q:
        (r, c), d = q.popleft()
        if (r, c) == tele:
            return d
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nr, nc = r + dr, c + dc
            if (nr, nc) in seen: continue
            if 0 > nr or nr >= rows or 0 > nc or nc >= cols: continue
            if (nr, nc) not in walk: continue
            fh, th = heights[r][c], heights[nr][nc]
            climb = th - fh
            ok = (
                climb <= 0
                or (climb == 1 and (is_ramp(r, c) or is_ramp(nr, nc)))
                or (is_tc(r, c) or is_tc(nr, nc))
                or (nr, nc) in tele_set
            )
            if ok:
                seen.add((nr, nc))
                q.append(((nr, nc), d + 1))
    return None


def composite_score(map_data: dict, spine_phase: str) -> dict:
    """Return { score: int, breakdown: {...}, reasons: [str] }."""
    layers = map_data.get("layers", {})
    struct = layers.get("structure", [])
    utils = layers.get("utilities", [])
    rows = len(struct)
    cols = max((len(r) for r in struct), default=0)
    cells = rows * cols
    walkable = sum(1 for r in range(rows) for c in range(cols)
                   if parse_height((struct[r] if r < len(struct) else [])[c] if c < len(struct[r] or []) else 0) >= 1)
    n_heights = len({parse_height(struct[r][c])
                     for r in range(rows) for c in range(min(cols, len(struct[r])))
                     if parse_height(struct[r][c]) > 0})
    meta = map_data.get("map_info", {}).get("metadata", {})
    scores = meta.get("scores", {}) or {}
    verdict = scores.get("verdict") or "weak"
    placed = scores.get("artifacts_placed", 0)
    original = max(scores.get("artifacts_original", 0), 1)

    pts: dict[str, int] = {}
    reasons: list[str] = []

    pts["verdict"] = VERDICT_PTS.get(verdict, 0)
    reasons.append(f"verdict={verdict} ({pts['verdict']}/30)")

    bfs = bfs_path_steps(struct, utils)
    if bfs is None:
        pts["reachable"] = 0
        reasons.append("teleport unreachable (0/20)")
    else:
        pts["reachable"] = 20
        reasons.append(f"BFS path={bfs} steps (20/20)")

    art_ratio = placed / original
    pts["artifacts"] = round(art_ratio * 15)
    reasons.append(f"artifacts {placed}/{original} ({pts['artifacts']}/15)")

    walk_pct = walkable / max(cells, 1)
    if 0.30 <= walk_pct <= 0.70: pts["density"] = 10
    elif 0.20 <= walk_pct <= 0.85: pts["density"] = 6
    else: pts["density"] = 2
    reasons.append(f"walk_pct={walk_pct:.2f} ({pts['density']}/10)")

    pts["heights"] = 10 if n_heights >= 2 else 4
    reasons.append(f"n_heights={n_heights} ({pts['heights']}/10)")

    budget = BUDGET_BY_PHASE.get(spine_phase, RELAXED)
    interior = max(1, (rows - 2) * (cols - 2))
    pts["budget"] = 10 if interior <= budget.cells_max * 1.05 else 4
    reasons.append(f"interior {interior} vs cells_max {budget.cells_max} ({pts['budget']}/10)")

    if bfs is not None and budget.path_budget > 0 and bfs <= budget.path_budget:
        pts["path_budget"] = 5
    elif bfs is not None and budget.path_budget < 0:
        pts["path_budget"] = 5
    else:
        pts["path_budget"] = 0
    reasons.append(f"path_budget={budget.path_budget} ({pts['path_budget']}/5)")

    total = sum(pts.values())
    return {"score": total, "breakdown": pts, "reasons": reasons,
            "bfs_steps": bfs, "phase": spine_phase}


def find_phase_for_base(base_name: str, sequence_id: str, spine: dict) -> str:
    for s in spine.get("spine", {}).get("sequences", []):
        if s.get("name") == sequence_id:
            return s.get("phase", "F_order")
    return "F_order"


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--sequence", default="", help="re-eval one sequence only")
    p.add_argument("--dry-run", action="store_true",
                   help="print scores without writing back")
    args = p.parse_args()

    spine = json.loads(SPINE_PATH.read_text(encoding="utf-8"))
    manifest_path = MIRROR_DIR / "manifest.json"
    if not manifest_path.exists():
        sys.exit(f"missing {manifest_path}")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    entries = manifest.get("entries", [])

    by_base: dict[str, list[tuple[int, dict]]] = defaultdict(list)
    updated = 0
    for e in entries:
        sid = e.get("sequence")
        if args.sequence and sid != args.sequence:
            continue
        eid = e.get("id")
        if not eid: continue
        map_path = MAPS_DIR / eid / "map_data.json"
        if not map_path.exists(): continue
        try:
            md = json.loads(map_path.read_text(encoding="utf-8"))
        except Exception:
            continue
        phase = find_phase_for_base(e.get("derived_from", ""), sid, spine)
        score = composite_score(md, phase)
        # Stamp into the variant's map_data.json metadata.
        if not args.dry_run:
            md.setdefault("map_info", {}).setdefault("metadata", {})
            md["map_info"]["metadata"]["composite_score"] = score
            md["map_info"]["metadata"]["evaluated_at"] = datetime.utcnow().isoformat() + "Z"
            map_path.write_text(json.dumps(md, indent=2), encoding="utf-8")
        # Surface on the manifest entry too.
        e["score"] = score["score"]
        e["score_breakdown"] = score["breakdown"]
        e["bfs_steps"] = score["bfs_steps"]
        by_base[e.get("derived_from") or eid].append((score["score"], e))
        updated += 1

    # Mark the highest-scoring variant per base as the recommended pick.
    for base, lst in by_base.items():
        lst.sort(key=lambda x: -x[0])
        for i, (_, e) in enumerate(lst):
            e["is_best_for_base"] = (i == 0)
            e["rank_for_base"] = i + 1

    if not args.dry_run:
        manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"\n=== eval ===  variants scored: {updated}, "
          f"bases ranked: {len(by_base)}")
    if updated:
        scores = [e.get("score", 0) for _, lst in by_base.items() for _, e in lst]
        print(f"  score range: {min(scores)}–{max(scores)}, "
              f"median: {sorted(scores)[len(scores)//2]}")
        bests = [(b, lst[0][0]) for b, lst in by_base.items() if lst]
        bests.sort(key=lambda x: -x[1])
        print(f"  top 5 base map winners:")
        for b, s in bests[:5]:
            print(f"    {b:32s} {s}/100")
    if args.dry_run:
        print("(dry run — no writes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
