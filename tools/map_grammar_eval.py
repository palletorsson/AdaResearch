#!/usr/bin/env python3
"""Auto-research eval loop for map-grammar.

For every entry in the gallery manifest, score the map on objective
metrics, assign verdict + stars, write evals.json in the schema the
existing /galleries/[id]/[entry] page already reads. Then propose
next-gen variants based on what failed and emit a queue of candidate
configs to feed back into the generator.

Output:
    ada_encyclopedia/public/map-grammar-gallery/evals.json
    tools/map_grammar/next_gen_queue.json   ← proposed configs for gen01

Run:
    python tools/map_grammar_eval.py
    python tools/map_grammar_eval.py --propose   # emit next-gen queue too
"""
from __future__ import annotations

import argparse
import json
import sys
from collections import deque
from datetime import date
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))

ENCYCLOPEDIA = REPO.parent / "ada_encyclopedia"
GALLERY_DIR = ENCYCLOPEDIA / "public" / "map-grammar-gallery"
MAPS_DIR = REPO / "commons" / "maps"
NEXT_GEN_PATH = REPO / "tools" / "map_grammar" / "next_gen_queue.json"
SEED_LIBRARY = REPO / "tools" / "map_grammar" / "research_configs.json"


def cell_height(v) -> int:
    if isinstance(v, int): return v
    if isinstance(v, str):
        try: return int(v)
        except Exception: return 0
    return 0


def metrics_for(map_data: dict) -> dict:
    """Compute a set of objective scores for one map."""
    layers = map_data.get("layers", {})
    structure = layers.get("structure", [])
    utilities = layers.get("utilities", [])
    rows = len(structure)
    cols = max((len(r) for r in structure), default=0)
    if rows == 0 or cols == 0:
        return {"empty": True}
    total = rows * cols
    grid = [[cell_height(structure[r][c]) if c < len(structure[r]) else 0
             for c in range(cols)] for r in range(rows)]

    # Cells with `wp` (walkable prism) or `tc` (transport cube) tokens
    # on them become walkable for path purposes regardless of height —
    # they unlock climb-up and void-crossing under the runtime rules.
    has_wp_or_tc: set[tuple[int, int]] = set()
    for r in range(min(rows, len(utilities))):
        u_row = utilities[r] if utilities[r] is not None else []
        for c in range(min(cols, len(u_row))):
            tok = str(u_row[c] if u_row[c] is not None else "").strip()
            if tok.startswith("wp") or tok.startswith("tc"):
                has_wp_or_tc.add((r, c))

    walkable_cells: set[tuple[int, int]] = set()
    walkable_thin_count = 0
    height_set: set[int] = set()
    for r in range(rows):
        for c in range(cols):
            v = grid[r][c]
            height_set.add(v)
            # A cell counts as walkable if h>=1 OR it has a wp/tc token
            # (those make void/wall cells traversable at runtime).
            if v >= 1 or (r, c) in has_wp_or_tc:
                walkable_cells.add((r, c))
                # "Thin" = walkable cell with no walkable cardinal neighbour.
                neighbours = sum(
                    1 for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1))
                    if 0 <= r + dr < rows and 0 <= c + dc < cols
                    and grid[r + dr][c + dc] >= 1
                )
                if neighbours <= 1:
                    walkable_thin_count += 1

    walkable = len(walkable_cells)
    walkable_pct = walkable / total

    # Largest connected component starting from spawn (or any walkable cell).
    spawn = None
    for r in range(rows):
        u_row = utilities[r] if r < len(utilities) else []
        for c in range(min(len(u_row), cols)):
            v = str(u_row[c] if u_row[c] is not None else "").strip()
            if v in ("s", "sp"):
                spawn = (r, c); break
        if spawn: break
    if spawn is None and walkable_cells:
        spawn = next(iter(walkable_cells))
    reachable = 0
    if spawn is not None and spawn in walkable_cells:
        seen = {spawn}; q = deque([spawn])
        while q:
            cr, cc = q.popleft()
            for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                n = (cr + dr, cc + dc)
                if n in walkable_cells and n not in seen:
                    seen.add(n); q.append(n)
        reachable = len(seen)

    connectivity = (reachable / walkable) if walkable else 0.0

    # Symmetry
    def sym(grid_a, grid_b):
        if not grid_a or not grid_b: return 0.0
        cnt = sum(1 for r in range(rows) for c in range(cols)
                  if grid_a[r][c] == grid_b[r][c])
        return cnt / (rows * cols)
    h_flip = [list(reversed(row)) for row in grid]
    v_flip = list(reversed(grid))
    horiz_sym = sym(grid, h_flip)
    vert_sym = sym(grid, v_flip)
    sym_score = max(horiz_sym, vert_sym)

    return {
        "rows": rows, "cols": cols,
        "walkable": walkable, "walkable_pct": round(walkable_pct, 3),
        "reachable": reachable, "connectivity": round(connectivity, 3),
        "thin_cells": walkable_thin_count,
        "thin_ratio": round(walkable_thin_count / max(1, walkable), 3),
        "n_heights": len(height_set),
        "horiz_symmetry": round(horiz_sym, 3),
        "vert_symmetry": round(vert_sym, 3),
        "max_symmetry": round(sym_score, 3),
        "has_spawn": spawn is not None,
    }


def score_to_verdict(m: dict) -> tuple[int, str, str, list[str]]:
    """Map metrics → (stars 1..5, verdict, notes, next_gen_hints)."""
    if m.get("empty"):
        return 1, "broken", "Empty grid — no structure cells.", ["increase rows/cols"]

    notes: list[str] = []
    hints: list[str] = []

    # Hard failures.
    if m["walkable"] < 6:
        return 1, "broken", f"Only {m['walkable']} walkable cells; map is barely playable.", [
            "increase fraction or use room/circle_room ops",
            "remove safe_borders if it's eating the floor",
        ]
    if m["connectivity"] < 0.5:
        return 1, "broken", f"Spawn reaches only {m['reachable']}/{m['walkable']} cells.", [
            "add corridor between disconnected regions",
            "lower CA birth threshold so chambers join",
        ]
    if not m["has_spawn"]:
        return 1, "broken", "No spawn placed.", ["append spawn_at op"]

    score = 3   # baseline 'working'

    # Reward thicker (safer) walkable.
    if m["thin_ratio"] > 0.4:
        notes.append(f"{int(m['thin_ratio'] * 100)}% of walkable cells are thin (1-cell wide) — risk of falling off.")
        hints.append("append thicken op with radius=1")
        score -= 1
    elif m["thin_ratio"] < 0.1:
        notes.append("Excellent path width — almost no thin cells.")
        score += 1

    # Reward connectivity.
    if m["connectivity"] >= 0.95:
        notes.append("Fully connected.")
        score += 1
    elif m["connectivity"] >= 0.8:
        notes.append(f"Mostly connected ({int(m['connectivity'] * 100)}%).")
    else:
        notes.append(f"Partial connectivity ({int(m['connectivity'] * 100)}%) — split regions.")
        hints.append("add corridor op linking spawn region to the rest")
        score -= 1

    # Reward height variety (more 3D interest).
    if m["n_heights"] >= 3:
        notes.append(f"{m['n_heights']} distinct heights — good 3D variation.")
        score += 1

    # Reward symmetry slightly (corpus avg 0.85+).
    if m["max_symmetry"] >= 0.85:
        notes.append(f"Strong symmetry ({m['max_symmetry']}).")
    elif m["max_symmetry"] < 0.6:
        hints.append("apply mirror op for symmetry")

    # Walkable fraction sweet-spot 0.3 – 0.7.
    if m["walkable_pct"] < 0.15:
        notes.append("Map feels sparse.")
        hints.append("increase fraction or add a room")
        score -= 1
    elif m["walkable_pct"] > 0.85:
        notes.append("Map is almost all floor — lacks structure.")
        hints.append("add walls / plinths / frame border")

    score = max(1, min(5, score))
    verdict = (
        "broken" if score <= 1
        else "weak" if score == 2
        else "working" if score == 3
        else "strong" if score == 4
        else "exemplary"
    )
    note_text = " ".join(notes) if notes else "OK."
    return score, verdict, note_text, hints


def propose_next_gen(entries: list[dict], evals: dict, seed_configs: list[dict]) -> list[dict]:
    """Take broken/weak entries + their hints, emit fresh candidate configs
    for the next generation of auto-research."""
    by_id = {c["id"]: c for c in seed_configs}
    out: list[dict] = []
    for e in entries:
        eid = e["id"]
        ev = evals.get(eid)
        if not ev: continue
        if ev.get("verdict") not in ("broken", "weak"): continue
        base = by_id.get(eid)
        if not base: continue
        for hi, hint in enumerate(ev.get("next_gen_hints", []) or []):
            new_id = f"{eid}_g1_{hi}"
            new_cfg = json.loads(json.dumps(base))   # deep copy
            new_cfg["id"] = new_id
            new_cfg["notes"] = f"gen1: {hint} (parent={eid})"
            ops = new_cfg.setdefault("ops", [])
            # Apply the hint as a concrete op append. Heuristic mapping.
            if "thicken" in hint:
                ops.append({"op": "thicken", "params": {"radius": 1}})
            elif "safe_borders" in hint:
                ops.append({"op": "safe_borders", "params": {"edge_h": 2}})
            elif "corridor" in hint:
                ops.append({"op": "corridor", "params": {
                    "from_r": 1, "from_c": 1,
                    "to_r": new_cfg.get("rows", 16) - 2,
                    "to_c": new_cfg.get("cols", 16) - 2,
                    "width": 2,
                }})
            elif "mirror" in hint:
                ops.append({"op": "mirror", "params": {"axis": "horizontal"}})
            elif "spawn_at" in hint:
                ops.append({"op": "spawn_at", "params": {}})
            elif "fraction" in hint:
                # Bump existing drunkard fraction or add one.
                bumped = False
                for step in ops:
                    if step.get("op") == "drunkard_walk":
                        f = float(step["params"].get("fraction", 0.4))
                        step["params"]["fraction"] = min(0.7, f + 0.15)
                        bumped = True
                if not bumped:
                    ops.append({"op": "drunkard_walk", "params": {"fraction": 0.5}})
            elif "rows" in hint:
                new_cfg["rows"] = int(new_cfg.get("rows", 16) + 6)
                new_cfg["cols"] = int(new_cfg.get("cols", 16) + 6)
            else:
                # Generic fallback.
                ops.append({"op": "thicken", "params": {"radius": 1}})
            out.append(new_cfg)
    return out


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--propose", action="store_true",
        help="also emit next-gen candidate configs for broken/weak maps")
    p.add_argument("--dry-run", action="store_true")
    args = p.parse_args()

    manifest_path = GALLERY_DIR / "manifest.json"
    if not manifest_path.exists():
        print("no manifest — run tools/map_grammar_research.py first")
        return 1
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    entries = manifest.get("entries", []) or []

    evals_out: dict[str, dict] = {}
    today = str(date.today())
    counts = {"strong": 0, "exemplary": 0, "working": 0, "weak": 0, "broken": 0}

    for e in entries:
        eid = e["id"]
        map_path = MAPS_DIR / e.get("map_name", eid) / "map_data.json"
        if not map_path.exists():
            evals_out[eid] = {
                "stars": 1, "verdict": "broken",
                "notes": "Map JSON missing on disk.",
                "next_gen_hints": ["regenerate via tools/map_grammar_research.py"],
                "evaluated_by": "auto", "date": today,
            }
            counts["broken"] += 1; continue
        try:
            md = json.loads(map_path.read_text(encoding="utf-8", errors="replace"))
        except Exception as ex:
            evals_out[eid] = {
                "stars": 1, "verdict": "broken",
                "notes": f"JSON parse error: {ex}",
                "next_gen_hints": [], "evaluated_by": "auto", "date": today,
            }
            counts["broken"] += 1; continue

        m = metrics_for(md)
        stars, verdict, notes, hints = score_to_verdict(m)
        counts[verdict] = counts.get(verdict, 0) + 1
        evals_out[eid] = {
            "stars": stars, "verdict": verdict, "notes": notes,
            "next_gen_hints": hints,
            "evaluated_by": "auto", "date": today,
            "metrics": m,
        }
        print(f"  {eid:30s} stars={stars} verdict={verdict:9s} {notes[:60]}")

    payload = {
        "evaluated_by": "auto",
        "date": today,
        "schema_version": 1,
        "evals": evals_out,
        "summary": {"counts": counts},
    }
    if not args.dry_run:
        (GALLERY_DIR / "evals.json").write_text(json.dumps(payload, indent=2),
                                                encoding="utf-8")
        print(f"wrote {(GALLERY_DIR / 'evals.json')}")
    print(f"\n=== verdict counts ===  {counts}")

    if args.propose and SEED_LIBRARY.exists():
        seed = json.loads(SEED_LIBRARY.read_text(encoding="utf-8"))
        seed_configs = seed.get("configs", []) or []
        proposals = propose_next_gen(entries, evals_out, seed_configs)
        if proposals:
            queue = {
                "version": 1,
                "generated_from": str(manifest_path.name),
                "configs": proposals,
            }
            NEXT_GEN_PATH.parent.mkdir(parents=True, exist_ok=True)
            NEXT_GEN_PATH.write_text(json.dumps(queue, indent=2), encoding="utf-8")
            print(f"\nproposed {len(proposals)} next-gen configs -> {NEXT_GEN_PATH}")
            print("    run: python tools/map_grammar_research.py --library tools/map_grammar/next_gen_queue.json --force")
        else:
            print("no next-gen proposals (no broken/weak hits)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
