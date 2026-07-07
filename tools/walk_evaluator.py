"""Walk-evaluate a placement.

Given a placement produced by any strategy, simulate a walker traversing
from spawn to teleporter. Measure:
  - encounter_order: did artifacts get encountered in queue order?
  - walk_length: how many cells walked
  - detour_ratio: walk_length / straight-line distance (lower is better)
  - backtracking: cells visited more than once (lower is better)
  - centerpiece_visibility: does the largest artifact become visible early?
  - per-step encounter ribbon: artifact closest at each step of the walk

The walker here doesn't PLACE anything — it WALKS A FIXED placement and
reports the experience. This is the placement's encounter quality, separate
from its constraint quality.

Then rank all strategies on this NEW axis.

Run:
  python tools/walk_evaluator.py
  python tools/walk_evaluator.py --map=Point_Tests

Output:
  doc/placement_research/walkability_results.json
  doc/placement_research/walkability_comparison.svg
"""
from __future__ import annotations

import argparse
import json
import math
import random
import sys
from collections import deque
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "doc" / "placement_research"

sys.path.insert(0, str(ROOT / "tools"))
from placement_research import (
    Room, Artifact, Placement, score_placement, render_ascii, TEST_ARTIFACTS,
    STRATEGIES,
)


# ─────────────────────────────────────────────────────────────────────
# Walk simulation through a FIXED placement
# ─────────────────────────────────────────────────────────────────────

def bfs_path(room: Room, start: tuple[int, int], goal: tuple[int, int],
             blocked: set[tuple[int, int]]) -> list[tuple[int, int]]:
    """Full BFS path from start to goal, returning every cell visited.
    Returns [] if no path."""
    if start == goal:
        return [start]
    prev: dict[tuple[int, int], tuple[int, int] | None] = {start: None}
    q: deque[tuple[int, int]] = deque([start])
    while q:
        cur = q.popleft()
        if cur == goal:
            path = [cur]
            while prev[cur] is not None:
                cur = prev[cur]  # type: ignore[assignment]
                path.append(cur)
            return list(reversed(path))
        for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nr, nc = cur[0] + dr, cur[1] + dc
            if not room.in_bounds(nr, nc): continue
            if (nr, nc) in prev: continue
            if (nr, nc) in blocked and (nr, nc) != goal: continue
            prev[(nr, nc)] = cur
            q.append((nr, nc))
    return []


def walk_placement(room: Room, placements: list[Placement]) -> dict:
    """Simulate a player walking spawn → all artifacts (in encounter order)
    → teleporter. Compute walkability metrics."""
    if not placements:
        return {"valid": False, "reason": "no placements"}

    occ: set[tuple[int, int]] = set()
    for p in placements:
        for cell in p.footprint_cells_occupied():
            occ.add(cell)

    spawn = (room.spawn_row, room.spawn_col)
    teleporter = (room.teleporter_row, room.teleporter_col)

    # Order artifacts by walk-order: greedy nearest from current pos
    remaining = list(placements)
    pos = spawn
    visit_order: list[Placement] = []
    full_path: list[tuple[int, int]] = [spawn]

    while remaining:
        # Find nearest artifact (by approach-cell distance)
        best = None; best_d = 1e9; best_path = None
        for p in remaining:
            # Approach cells = cells adjacent to artifact footprint, free
            my_cells = set(p.footprint_cells_occupied())
            approaches = []
            for (r, c) in my_cells:
                for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    a = (r + dr, c + dc)
                    if (a in my_cells) or (a in occ): continue
                    if not room.in_bounds(*a): continue
                    approaches.append(a)
            # Pick closest reachable approach cell
            for a in approaches:
                local_blocked = occ - {a}    # the approach is open
                # Also unblock current pos
                path = bfs_path(room, pos, a, occ - {a, pos})
                if path:
                    d = len(path)
                    if d < best_d:
                        best_d = d; best = p; best_path = path
        if best is None:
            break
        visit_order.append(best)
        if best_path:
            full_path.extend(best_path[1:])
        pos = full_path[-1]
        remaining.remove(best)

    # Finally walk to teleporter
    final_path = bfs_path(room, pos, teleporter, occ)
    if final_path:
        full_path.extend(final_path[1:])

    # ── METRICS ──
    # 1. encounter_order — did artifacts get encountered in "natural" order?
    #    Natural = wall_backing/entry first, center next, cluster_with last
    def natural_priority(p: Placement) -> tuple:
        a = p.artifact
        return (
            0 if a.wall_backing else 1,
            0 if a.preferred_zone == "entry" else (1 if a.preferred_zone == "center" else 2),
            1 if a.cluster_with else 0,    # cluster later
            -a.footprint_cells,
        )
    natural_order = sorted(placements, key=natural_priority)
    natural_idx = {id(p): i for i, p in enumerate(natural_order)}
    actual_idx = {id(p): i for i, p in enumerate(visit_order)}
    if len(visit_order) == len(natural_order):
        # Spearman-style: 1 - normalized rank distance
        n = len(visit_order)
        diff_sum = sum(abs(natural_idx[id(p)] - actual_idx[id(p)]) for p in visit_order)
        max_diff = n * (n - 1) // 2 + (n // 2)   # rough upper bound
        encounter_order = max(0, 1 - diff_sum / max(1, max_diff))
    else:
        encounter_order = 0.5

    # 2. walk_length / detour ratio
    straight_line = abs(spawn[0] - teleporter[0]) + abs(spawn[1] - teleporter[1])
    walk_length = len(full_path) - 1
    detour_ratio = walk_length / max(1, straight_line)

    # 3. backtracking — cells visited > once
    counts: dict[tuple[int, int], int] = {}
    for cell in full_path:
        counts[cell] = counts.get(cell, 0) + 1
    backtracked = sum(c - 1 for c in counts.values() if c > 1)
    backtrack_rate = backtracked / max(1, walk_length)

    # 4. centerpiece visibility — distance from spawn to largest artifact's center
    if placements:
        centerpiece = max(placements, key=lambda p: p.artifact.footprint_cells)
        cp_cells = centerpiece.footprint_cells_occupied()
        cp_cx = sum(c for (_, c) in cp_cells) / len(cp_cells)
        cp_cy = sum(r for (r, _) in cp_cells) / len(cp_cells)
        cp_dist = math.hypot(spawn[0] - cp_cy, spawn[1] - cp_cx)
        # Closer = more visible (proxy for line-of-sight); normalize
        max_dist = math.hypot(room.depth, room.width)
        centerpiece_proximity = 1 - cp_dist / max_dist
    else:
        centerpiece_proximity = 0

    # 5. did all artifacts get visited?
    visited_count = len(visit_order)
    coverage = visited_count / max(1, len(placements))

    # ── COMPOSITE walkability score ──
    walkability = (
        0.30 * encounter_order +
        0.20 * (1.0 - min(1.0, max(0, detour_ratio - 1) / 3))  # punish detours
        + 0.20 * (1.0 - min(1.0, backtrack_rate * 2))
        + 0.15 * centerpiece_proximity
        + 0.15 * coverage
    )

    return {
        "valid":                  True,
        "walk_length":            walk_length,
        "straight_line":          straight_line,
        "detour_ratio":           round(detour_ratio, 3),
        "backtrack_rate":         round(backtrack_rate, 3),
        "encounter_order":        round(encounter_order, 3),
        "centerpiece_proximity":  round(centerpiece_proximity, 3),
        "coverage":               round(coverage, 3),
        "walkability":            round(walkability, 3),
        "visit_order_names":      [p.artifact.lookup_name for p in visit_order],
        "natural_order_names":    [p.artifact.lookup_name for p in natural_order],
        "full_path":              [list(c) for c in full_path],
    }


# ─────────────────────────────────────────────────────────────────────
# Compare across all strategies
# ─────────────────────────────────────────────────────────────────────

def evaluate_all_strategies(room: Room, artifacts: list[Artifact],
                             seed: int = 0) -> dict:
    results = {}
    for name, fn in STRATEGIES.items():
        rng = random.Random(seed)
        placements = fn(room, list(artifacts), rng)
        constraint = score_placement(room, placements)
        walk = walk_placement(room, placements)
        results[name] = {
            "constraint_score":   constraint["total"],
            "walkability":        walk.get("walkability", 0),
            "combined":           round(constraint["total"] * 0.6 + walk.get("walkability", 0) * 0.4, 3),
            "constraint_details": {k: round(v, 3) for k, v in constraint.items() if k != "total"},
            "walk_details":       {k: walk[k] for k in (
                "walk_length", "detour_ratio", "backtrack_rate", "encounter_order",
                "centerpiece_proximity", "coverage", "visit_order_names",
            ) if k in walk},
            "full_path":          walk.get("full_path", []),
            "placements":         [
                {"artifact": p.artifact.lookup_name, "row": p.row, "col": p.col}
                for p in placements
            ],
        }
    return results


# ─────────────────────────────────────────────────────────────────────
# Visualization
# ─────────────────────────────────────────────────────────────────────

CELL = 22
GAP = 14
PANEL_LABEL_H = 50


def render_comparison_svg(room: Room, results: dict) -> str:
    """Side-by-side trajectory for each strategy with both scores."""
    ranked = sorted(results.items(), key=lambda kv: -kv[1]["combined"])

    cols = 3
    rows = (len(ranked) + cols - 1) // cols
    panel_w = room.width * CELL + 20
    panel_h = room.depth * CELL + PANEL_LABEL_H + 50

    canvas_w = GAP + cols * (panel_w + GAP)
    canvas_h = 90 + rows * (panel_h + GAP)

    parts = [f'<rect width="{canvas_w}" height="{canvas_h}" fill="#0A0A0E"/>']
    parts.append(f'<text x="{GAP}" y="36" font-family="ui-monospace,monospace" '
                 f'font-size="20" font-weight="700" fill="#FFFFFF">'
                 f'Walkability comparison — every strategy walked through</text>')
    parts.append(f'<text x="{GAP}" y="60" font-family="ui-monospace,monospace" '
                 f'font-size="11" fill="#9090A0">'
                 f'GREEN = walk path · BOXES = artifacts (numbered in visit order) · '
                 f'ranked by COMBINED score (60% constraint + 40% walkability)</text>')

    artifact_colors_by_name = {}
    for i, p in enumerate(ranked[0][1]["placements"]):
        artifact_colors_by_name[p["artifact"]] = [
            "#E63946", "#457B9D", "#F4A261", "#2A9D8F", "#E9C46A", "#9B5DE5",
            "#FF6B9D", "#06D6A0", "#118AB2", "#FFD166"
        ][i % 10]

    for idx, (name, r) in enumerate(ranked):
        col = idx % cols
        row = idx // cols
        x = GAP + col * (panel_w + GAP)
        y = 90 + row * (panel_h + GAP)

        parts.append(f'<g transform="translate({x},{y})">')
        parts.append(f'<rect width="{panel_w}" height="{panel_h}" fill="#1A1A1F" '
                     f'stroke="#2A2A33" rx="6"/>')

        # Title
        parts.append(f'<text x="10" y="20" font-family="ui-monospace,monospace" '
                     f'font-size="13" font-weight="700" fill="#E8E8EE">{name}</text>')
        # Scores
        parts.append(f'<text x="10" y="36" font-family="ui-monospace,monospace" '
                     f'font-size="10" fill="#FFD700">'
                     f'C={r["constraint_score"]:.3f}</text>')
        parts.append(f'<text x="80" y="36" font-family="ui-monospace,monospace" '
                     f'font-size="10" fill="#7DFFA8">'
                     f'W={r["walkability"]:.3f}</text>')
        parts.append(f'<text x="150" y="36" font-family="ui-monospace,monospace" '
                     f'font-size="11" font-weight="700" fill="#FFFFFF">'
                     f'Σ={r["combined"]:.3f}</text>')

        # Grid
        gx = 10; gy = PANEL_LABEL_H
        for rr in range(room.depth):
            for cc in range(room.width):
                parts.append(f'<rect x="{gx + cc * CELL}" y="{gy + rr * CELL}" '
                             f'width="{CELL}" height="{CELL}" '
                             f'fill="#0E0E12" stroke="#1F1F26" stroke-width="0.3"/>')

        # Walk path
        path = r.get("full_path", [])
        if len(path) >= 2:
            pts = " ".join(f"{gx + p[1] * CELL + CELL/2},{gy + p[0] * CELL + CELL/2}"
                           for p in path)
            parts.append(f'<polyline points="{pts}" fill="none" stroke="#7DFFA8" '
                         f'stroke-width="2.5" stroke-opacity="0.65" '
                         f'stroke-linejoin="round" stroke-linecap="round"/>')

        # Placements (numbered by visit order)
        visit_names = r["walk_details"]["visit_order_names"]
        for pi, pl in enumerate(r["placements"]):
            color = artifact_colors_by_name.get(pl["artifact"], "#888")
            # Get footprint dim
            footprint_cells = next((a.footprint_cells for a in TEST_ARTIFACTS
                                    if a.lookup_name == pl["artifact"]), 1)
            fp = max(1, int(round(math.sqrt(footprint_cells))))
            bx = gx + pl["col"] * CELL
            by = gy + pl["row"] * CELL
            parts.append(f'<rect x="{bx}" y="{by}" width="{fp * CELL}" '
                         f'height="{fp * CELL}" fill="{color}" fill-opacity="0.55" '
                         f'stroke="{color}" stroke-width="1.5"/>')
            # Visit-order number
            try:
                visit_num = visit_names.index(pl["artifact"]) + 1
            except ValueError:
                visit_num = "?"
            cx = bx + fp * CELL / 2; cy = by + fp * CELL / 2
            parts.append(f'<text x="{cx}" y="{cy + 5}" font-family="ui-monospace,monospace" '
                         f'font-size="14" font-weight="700" fill="#FFFFFF" '
                         f'text-anchor="middle">{visit_num}</text>')

        # Spawn / teleporter
        sx = gx + room.spawn_col * CELL + CELL / 2
        sy = gy + room.spawn_row * CELL + CELL / 2
        parts.append(f'<circle cx="{sx}" cy="{sy}" r="9" fill="#80FF80" '
                     f'stroke="#0A0A0E" stroke-width="1.5"/>')
        parts.append(f'<text x="{sx}" y="{sy + 4}" font-family="ui-monospace,monospace" '
                     f'font-size="9" font-weight="700" fill="#0A0A0E" '
                     f'text-anchor="middle">S</text>')
        tx = gx + room.teleporter_col * CELL + CELL / 2
        ty = gy + room.teleporter_row * CELL + CELL / 2
        parts.append(f'<circle cx="{tx}" cy="{ty}" r="9" fill="#FF8080" '
                     f'stroke="#0A0A0E" stroke-width="1.5"/>')
        parts.append(f'<text x="{tx}" y="{ty + 4}" font-family="ui-monospace,monospace" '
                     f'font-size="9" font-weight="700" fill="#0A0A0E" '
                     f'text-anchor="middle">T</text>')

        # Bottom: walk stats
        wd = r["walk_details"]
        parts.append(f'<text x="10" y="{panel_h - 20}" font-family="ui-monospace,monospace" '
                     f'font-size="9" fill="#9090A0">'
                     f'walk={wd["walk_length"]} · detour={wd["detour_ratio"]:.2f}× · '
                     f'backtrack={wd["backtrack_rate"]:.2f}</text>')
        parts.append(f'<text x="10" y="{panel_h - 8}" font-family="ui-monospace,monospace" '
                     f'font-size="9" fill="#9090A0">'
                     f'order={wd["encounter_order"]:.2f} · cp={wd["centerpiece_proximity"]:.2f} · '
                     f'cov={wd["coverage"]:.2f}</text>')

        parts.append('</g>')

    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{canvas_w}" height="{canvas_h}" '
            f'viewBox="0 0 {canvas_w} {canvas_h}">'
            + "".join(parts) + '</svg>')


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--map", type=str)
    p.add_argument("--seed", type=int, default=0)
    args = p.parse_args()

    if args.map:
        from place_artifacts import existing_placements, room_from_map  # type: ignore
        src = ROOT / "commons" / "maps" / args.map / "map_data.json"
        with open(src, "r", encoding="utf-8") as f:
            map_data = json.load(f)
        room, _, _ = room_from_map(map_data)
        old_placements = existing_placements(map_data, room)
        artifacts = [p.artifact for p in old_placements]
        out_name = f"walkability_{args.map}"
    else:
        room = Room()
        artifacts = list(TEST_ARTIFACTS)
        out_name = "walkability_comparison"

    print(f"evaluating walkability for {len(STRATEGIES)} strategies on "
          f"{len(artifacts)} artifacts in a {room.width}x{room.depth} room...")
    results = evaluate_all_strategies(room, artifacts, seed=args.seed)

    # Print ranking
    ranked = sorted(results.items(), key=lambda kv: -kv[1]["combined"])
    print()
    print(f"{'strategy':22} {'C':>7} {'W':>7} {'Σ':>7} {'detour':>7} {'order':>7} {'backtrack':>10}")
    print("-" * 78)
    for name, r in ranked:
        wd = r["walk_details"]
        print(f"{name:22} {r['constraint_score']:>7.3f} {r['walkability']:>7.3f} "
              f"{r['combined']:>7.3f} {wd['detour_ratio']:>6.2f}× "
              f"{wd['encounter_order']:>6.2f}  {wd['backtrack_rate']:>9.2f}")

    # Save data
    data_path = OUT_DIR / f"{out_name}.json"
    with open(data_path, "w", encoding="utf-8") as f:
        json.dump({
            "room": {
                "width": room.width, "depth": room.depth,
                "spawn_row": room.spawn_row, "spawn_col": room.spawn_col,
                "teleporter_row": room.teleporter_row, "teleporter_col": room.teleporter_col,
            },
            "artifacts": [a.__dict__ for a in artifacts],
            "results": results,
        }, f, indent=2)
    print(f"\nwrote {data_path}")

    # Save SVG
    svg_path = OUT_DIR / f"{out_name}.svg"
    with open(svg_path, "w", encoding="utf-8") as f:
        f.write(render_comparison_svg(room, results))
    print(f"wrote {svg_path}")


if __name__ == "__main__":
    main()
