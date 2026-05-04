#!/usr/bin/env python3
"""
repair_oversaturated_wedges.py
==============================

Strip and re-build the utilities layer for maps where the old editor
stamped a `wp:N` on every h>=2 cell (one wedge per high cell instead of
one wedge per actual climb need).

Algorithm — matches the new reachability-driven solver in
ada_encyclopedia/src/app/editor/page.tsx:

  1. Find spawn (utility 'sp' or 's', falls back to first walkable cell).
  2. Targets to reach = artifact cells (interactables layer) + teleports.
  3. BFS from spawn using the player's step rule:
       - flat: walk freely
       - +1 climb: needs wp / r / tc on either cell
       - +N climb (N>=2): needs tc on either cell
  4. Pick first unreachable target → flood the connected plateau it sits
     on → on that plateau, find a boundary cell adjacent to the reachable
     set with the smallest climb (prefer wp over tc) and shortest distance
     to the target. Drop ONE wedge there.
  5. Repeat until all targets reachable or no progress.

Wedges and transports already present from non-suspect ops (terraces,
zigzag levels, multi-floor stairs) are preserved by re-running this
solver on top of them — but the targets are saturated maps where the
ENTIRE wedge layer was the bug, so we wipe and rebuild.

Run:
    python tools/repair_oversaturated_wedges.py            # dry run
    python tools/repair_oversaturated_wedges.py --apply    # write
    python tools/repair_oversaturated_wedges.py --apply --map Point_One
"""

from __future__ import annotations
import argparse
import json
import os
import sys
from collections import deque
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
MAPS_DIR = REPO / "commons" / "maps"

# Maps confirmed to have the oversaturated pattern (wp >= 60% of h>=2 cells).
DEFAULT_TARGETS = [
    "AdvancedLaboratory_Lab_Equipment_Simulation_v5_symmetric",
    "ComputationalGeometry_Convex_Hull_Algorithms",
    "ComputationalGeometry_Euclidean_Distance_Transform",
    "Point_One",
    "RecursiveEmergence_Iterated_Function_Systems_IFS",
]


def heading_for(dr: int, dc: int) -> int:
    if dc > 0: return 0
    if dc < 0: return 180
    if dr > 0: return 90
    return 270


def parse_height(v) -> int:
    if isinstance(v, int): return v
    try: return int(str(v).strip() or 0)
    except (ValueError, TypeError): return 0


def find_spawn(util_layer, struct_h):
    rows = len(struct_h)
    cols = len(struct_h[0]) if rows else 0
    # 1st pass: canonical 'sp'
    for r in range(rows):
        for c in range(cols):
            tok = str(util_layer[r][c] if r < len(util_layer) and c < len(util_layer[r]) else "").strip()
            if tok == "sp":
                return (r, c)
    # 2nd pass: lone 's' (legacy variant in a few maps)
    for r in range(rows):
        for c in range(cols):
            tok = str(util_layer[r][c] if r < len(util_layer) and c < len(util_layer[r]) else "").strip()
            if tok == "s":
                return (r, c)
    # fallback to first walkable
    for r in range(rows):
        for c in range(cols):
            if struct_h[r][c] >= 1:
                return (r, c)
    return (1, 1)


def collect_targets(util_layer, interact_layer, struct_h, spawn):
    """All cells we need reachable: teleporter + every artifact.

    Skip cells with h=0 — the structure says they're void, so no wedge
    can possibly make them walkable. Such targets indicate a corrupt
    map (artifact placed on void); leave them as-is and don't pile on
    wedges trying to reach the impossible."""
    targets = set()
    rows, cols = len(struct_h), len(struct_h[0]) if struct_h else 0
    for r in range(rows):
        for c in range(cols):
            if struct_h[r][c] < 1:
                continue
            u = str(util_layer[r][c] if r < len(util_layer) and c < len(util_layer[r]) else "").strip()
            if u in ("t", "tp"):
                targets.add((r, c))
            i = str(interact_layer[r][c] if r < len(interact_layer) and c < len(interact_layer[r]) else "").strip()
            if i and i != " ":
                targets.add((r, c))
    targets.discard(spawn)
    return targets


def reachable_from(struct_h, util, start):
    rows, cols = len(struct_h), len(struct_h[0]) if struct_h else 0
    seen = {start}
    if struct_h[start[0]][start[1]] < 1:
        return seen
    q = deque([start])

    def util_at(r, c):
        return str(util[r][c]).strip() if 0 <= r < rows and 0 <= c < cols else ""

    while q:
        r, c = q.popleft()
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nr, nc = r + dr, c + dc
            if (nr, nc) in seen: continue
            if not (0 <= nr < rows and 0 <= nc < cols): continue
            if struct_h[nr][nc] < 1: continue
            climb = abs(struct_h[nr][nc] - struct_h[r][c])
            if climb > 0:
                u1, u2 = util_at(r, c), util_at(nr, nc)
                ramp = lambda u: u.startswith("wp") or u.startswith("r") or u.startswith("tc")
                if climb == 1:
                    if not (ramp(u1) or ramp(u2)): continue
                else:
                    if not (u1.startswith("tc") or u2.startswith("tc")): continue
            seen.add((nr, nc))
            q.append((nr, nc))
    return seen


def flood_plateau(struct_h, target):
    rows, cols = len(struct_h), len(struct_h[0]) if struct_h else 0
    seen = {target}
    q = deque([target])
    while q:
        r, c = q.popleft()
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nr, nc = r + dr, c + dc
            if (nr, nc) in seen: continue
            if not (0 <= nr < rows and 0 <= nc < cols): continue
            if struct_h[nr][nc] < 1: continue
            seen.add((nr, nc))
            q.append((nr, nc))
    return seen


def solve_utilities(struct_h, util_layer, interact_layer, preserve_special=True):
    """Build a fresh utilities layer with reachability-driven wedges.

    Preserved tokens (non-wedge utilities): sp, t, ds, m, an, 3t, *
    Wedge tokens removed: wp, tc, r."""
    rows = len(struct_h)
    cols = len(struct_h[0]) if rows else 0
    new_util = [[" " for _ in range(cols)] for _ in range(rows)]

    # Preserve non-wedge utilities (spawn, teleport, danger, label, etc.)
    if preserve_special:
        for r in range(rows):
            for c in range(cols):
                if r >= len(util_layer) or c >= len(util_layer[r]): continue
                tok = str(util_layer[r][c]).strip()
                if not tok: continue
                # Drop wedges/transports/ramps; keep everything else.
                if tok.startswith("wp") or tok.startswith("tc") or tok.startswith("r:") or tok == "r":
                    continue
                new_util[r][c] = tok

    spawn = find_spawn(new_util, struct_h)
    targets = collect_targets(new_util, interact_layer, struct_h, spawn)
    if not targets:
        return new_util  # nothing to reach; clean utility layer

    for _ in range(60):  # safety cap
        reach = reachable_from(struct_h, new_util, spawn)
        unreached = targets - reach
        if not unreached:
            break
        # pick closest target to spawn for stable ordering
        target = min(unreached, key=lambda t: abs(t[0] - spawn[0]) + abs(t[1] - spawn[1]))
        plateau = flood_plateau(struct_h, target)

        best = None  # (climb, dist, r, c, dr, dc)
        for (pr, pc) in plateau:
            if str(new_util[pr][pc]).strip(): continue
            for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                nr, nc = pr + dr, pc + dc
                if not (0 <= nr < rows and 0 <= nc < cols): continue
                if (nr, nc) not in reach: continue
                climb = struct_h[pr][pc] - struct_h[nr][nc]
                if climb < 1: continue
                dist = abs(pr - target[0]) + abs(pc - target[1])
                key = (climb, dist)
                if best is None or key < (best[0], best[1]):
                    best = (climb, dist, pr, pc, dr, dc)
        if best is None:
            break  # no boundary candidate; can't help this target

        climb, _, pr, pc, dr, dc = best
        if climb == 1:
            new_util[pr][pc] = f"wp:{heading_for(dr, dc)}"
        else:
            new_util[pr][pc] = f"tc:{climb}:y"

    return new_util


def repair_one(map_name: str, apply: bool, verbose: bool = True):
    map_path = MAPS_DIR / map_name / "map_data.json"
    if not map_path.exists():
        print(f"[skip] {map_name}: no map_data.json")
        return False
    data = json.loads(map_path.read_text(encoding="utf-8"))
    layers = data.get("layers", {})
    struct_raw = layers.get("structure", []) or []
    util = layers.get("utilities", []) or []
    interact = layers.get("interactables", []) or []
    rows = len(struct_raw)
    cols = len(struct_raw[0]) if rows else 0
    struct_h = [[parse_height(struct_raw[r][c] if c < len(struct_raw[r]) else 0) for c in range(cols)] for r in range(rows)]

    # Count old wedges
    old_wp = sum(1 for row in util for cell in row if isinstance(cell, str) and cell.startswith("wp"))
    old_tc = sum(1 for row in util for cell in row if isinstance(cell, str) and cell.startswith("tc"))

    new_util = solve_utilities(struct_h, util, interact)
    new_wp = sum(1 for row in new_util for cell in row if isinstance(cell, str) and cell.startswith("wp"))
    new_tc = sum(1 for row in new_util for cell in row if isinstance(cell, str) and cell.startswith("tc"))

    if verbose:
        print(f"  {map_name}:  wp {old_wp} -> {new_wp}   tc {old_tc} -> {new_tc}")

    if not apply:
        return True

    # Persist with utilities replaced.
    layers["utilities"] = new_util
    data["layers"] = layers
    map_path.write_text(json.dumps(data, indent="\t", ensure_ascii=False) + "\n", encoding="utf-8")
    return True


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--apply", action="store_true", help="Write changes to disk (else dry run)")
    ap.add_argument("--map", action="append", help="Override map name(s) — repeat for many")
    args = ap.parse_args()

    targets = args.map if args.map else DEFAULT_TARGETS
    print(f"{'Repairing' if args.apply else 'Dry run for'} {len(targets)} maps:")
    for m in targets:
        repair_one(m, apply=args.apply, verbose=True)
    if not args.apply:
        print("\nRe-run with --apply to write changes.")


if __name__ == "__main__":
    main()
