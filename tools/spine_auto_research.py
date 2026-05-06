#!/usr/bin/env python3
"""Spine map auto-research driver.

Closes the loop on existing spine maps:

  read sequence → for each map → propose N grammar variants →
  run each variant through ops → eval → render iso thumbnail →
  write commons/maps/<map>_v<n>/map_data.json + delta record →
  emit a manifest the encyclopedia gallery can read.

This is the OUTER loop the project has been missing. Earlier tools
(map_grammar_research.py, map_grammar_eval.py) generate maps from
scratch off a config library. This tool starts from a real spine map
and asks: what does the grammar say its variants look like?

Usage:
    python tools/spine_auto_research.py <sequence_id> [--n 5]
    python tools/spine_auto_research.py color --map Color_Pillar --n 3
    python tools/spine_auto_research.py --all-spine --n 2

Each variant is saved as <map>_v<n> alongside the original. Pathfinder
checks run after generation; failures are flagged in the manifest but
not auto-deleted (human reviews via /map-3d/<name>).

Output:
    commons/maps/<base>_v<n>/map_data.json       - the variant
    commons/maps/<base>_v<n>/map_iso.png         - iso thumbnail
    doc/spine_research/<sequence>.json           - rollup with scores
    ada_encyclopedia/public/spine-research/...   - mirrored gallery
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from datetime import datetime

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))

from map_grammar import run_config, to_map_data_json     # noqa: E402
from map_grammar.ops import MapState                      # noqa: E402
from map_grammar.budget import (                          # noqa: E402
    Budget, fit_dims, budget_for_sequence,
)
from map_grammar.imprint import (                         # noqa: E402
    Imprint, imprint_for, allowed_strategies,
)
from iso_voxel_render import render_iso                   # noqa: E402

MAPS_DIR = REPO / "commons" / "maps"
SEQ_DIR = REPO / "commons" / "maps" / "sequences"
SPINE_PATH = REPO / "commons" / "maps" / "curriculum_spine.json"
RESEARCH_DIR = REPO / "doc" / "spine_research"
ENCYCLOPEDIA = REPO.parent / "ada_encyclopedia"
MIRROR_DIR = ENCYCLOPEDIA / "public" / "spine-research"


# ── Variant proposal strategies ────────────────────────────────────
# Each strategy reads the original map's structure and emits a config
# (op chain) that the grammar engine can run. The strategies aim to
# span the design space rather than tweak around a single point.

def _grid_dims(struct: list[list[str]]) -> tuple[int, int]:
    rows = len(struct)
    cols = max((len(r) for r in struct), default=0)
    return rows, cols


def variant_strategies(rows: int, cols: int, base_name: str,
                       budget: Budget | None = None,
                       imprint: Imprint | None = None) -> list[dict]:
    """Return a fixed roster of variant configs sized to the original (or
    to the budget when one is given). Budget rescales rows/cols, caps
    util density, and tightens loop counts.

    When `imprint` is provided, strategy parameters scale with the map's
    position in its sequence — the map embodies the algorithm at step N.
    Hilbert depth grows, CA generations grow, BSP depth grows, terraced
    tiers grow. Earlier maps are seed states; later maps are full unfurl."""
    # Density steps for drunkard_walk: tighter budget + imprint = denser fill.
    walk_factor = imprint.drunkard_steps_factor if imprint else 0.30
    walk_steps = max(8, int(rows * cols * walk_factor))
    # Period for column_grid: imprint takes priority over budget.
    col_period = (imprint.column_period if imprint
                  else 2 if (budget and budget.cells_max <= 110) else 3)
    col_h = min(5, max(2, max(rows, cols) // 5))
    # All other imprint-controlled params (with budget defaults).
    h_order = imprint.hilbert_order if imprint else (
        2 if (budget and budget.cells_max <= 110) else 3)
    bsp_depth = imprint.bsp_depth if imprint else (
        2 if (budget and budget.cells_max <= 110) else 3)
    terr_steps = imprint.terraced_steps if imprint else (
        2 if (budget and budget.cells_max <= 110) else 3)
    voron_n = imprint.voronoi_seeds if imprint else (
        3 if (budget and budget.cells_max <= 110) else 5)
    petals = imprint.petal_count if imprint else (
        3 if (budget and budget.cells_max <= 110) else 4)
    # Noise injection for variance — scales with budget so tight maps
    # don't get scrambled but loose ones gain visible character. Each
    # strategy ends with a noise_perturb op; the rng inside it produces
    # different bumps/pillars per strategy id, so two same-strategy
    # variants of different bases now look distinct.
    # Bumped meaningfully — 3 cells of noise is invisible on an 8×8 thumb.
    # Aim for ~10–15% of cells perturbed so each base reads differently.
    noise_bumps   = 5 if (budget and budget.cells_max <= 80) else 8
    # Dips are the main fall hazard (single-cell bridges) — keep low and
    # let widen_paths repair what dips remain.
    noise_dips    = 1 if (budget and budget.cells_max <= 80) else 2
    noise_pillars = 3 if (budget and budget.cells_max <= 80) else 4
    noise_op = {"op": "noise_perturb", "params": {
        "bumps": noise_bumps, "dips": noise_dips, "pillars": noise_pillars,
        "avoid_edge": 1,
    }}
    # Widen 1-cell-wide paths so the player doesn't constantly walk a
    # ledge. Runs AFTER noise so noise-induced thinning gets patched.
    # ratio 0.9 = ~90% of bottlenecks widened; the remaining 10% stay
    # as intentional rope-bridge moments.
    widen_op = {"op": "widen_paths", "params": {
        "ratio": 0.9, "avoid_edge": 1,
    }}
    return [
        {
            "id": f"{base_name}_v1_corridor",
            "notes": "Straight corridor remix — minimal floor, single wp ramp midway",
            "rows": rows, "cols": cols,
            "ops": [
                {"op": "frame", "params": {"rows": rows, "cols": cols, "thickness": 1, "h": 1}},
                {"op": "drunkard_walk", "params": {"steps": walk_steps, "h": 1}},
                noise_op,
                widen_op,
            ],
        },
        {
            "id": f"{base_name}_v2_bsp",
            "notes": "BSP-partitioned variant — rooms with corridors, mixed heights",
            "rows": rows, "cols": cols,
            "ops": [
                {"op": "frame", "params": {"rows": rows, "cols": cols, "thickness": 1, "h": 1}},
                {"op": "bsp", "params": {
                    "min_room": 2 if (budget and budget.cells_max <= 110) else 3,
                    "max_depth": bsp_depth,
                }},
                noise_op,
                widen_op,
            ],
        },
        {
            "id": f"{base_name}_v3_terraced",
            "notes": "Terraced variant — multiple heights with wp ramps to climb",
            "rows": rows, "cols": cols,
            "ops": [
                {"op": "room", "params": {"rows": rows, "cols": cols, "h": 1}},
                {"op": "terraced", "params": {"steps": terr_steps}},
                noise_op,
                widen_op,
            ],
        },
        {
            "id": f"{base_name}_v4_islands",
            "notes": "Floating islands — tc transports bridge voids",
            "rows": rows, "cols": cols,
            "ops": [
                {"op": "voronoi_cells", "params": {"n": voron_n, "h": 1}},
                {"op": "floating_platforms", "params": {"n": max(3, voron_n - 2)}},
                noise_op,
                widen_op,
            ],
        },
        {
            "id": f"{base_name}_v5_symmetric",
            "notes": "Mirror-symmetric variant — readable spine + side chambers",
            "rows": rows, "cols": cols,
            "ops": [
                {"op": "room", "params": {"rows": rows, "cols": cols, "h": 1}},
                {"op": "petal_ring", "params": {"petals": petals}},
                {"op": "mirror", "params": {"axis": "x"}},
                noise_op,
                widen_op,
            ],
        },
        {
            # The Mies bay — sourced from mg_mies_dense. Pillars on a
            # regular period; artifacts go in the open bays between them.
            # period and column_h scale with map size so 8x8 and 18x26
            # both produce a readable grid.
            "id": f"{base_name}_v6_column_grid",
            "notes": (f"Column grid (Mies bay) — pillars on a {col_period}-cell period"
                      + (" (compressed by budget)" if col_period == 2 else "")),
            "rows": rows, "cols": cols,
            "ops": [
                {"op": "frame", "params": {"rows": rows, "cols": cols, "thickness": 1, "h": 1}},
                {"op": "column_grid", "params": {
                    "period": col_period,
                    "column_h": col_h,
                }},
                noise_op,
                widen_op,
            ],
        },
        {
            # Hilbert/L-system filling curve — single-path teaching maps
            # for fractals, l-systems, cellular automata sequences.
            "id": f"{base_name}_v7_curve",
            "notes": "Hilbert filling curve — one continuous path",
            "rows": rows, "cols": cols,
            "ops": [
                {"op": "frame", "params": {"rows": rows, "cols": cols, "thickness": 1, "h": 1}},
                {"op": "hilbert_curve", "params": {"order": h_order}},
                noise_op,
                widen_op,
            ],
        },
    ]


# ── Eval ───────────────────────────────────────────────────────────
def eval_variant(state: MapState) -> dict:
    """Cheap structural scoring. Returns a dict that goes into the manifest."""
    rows, cols = state.rows, state.cols
    cells = rows * cols
    walk = sum(1 for r in range(rows) for c in range(cols)
               if state.structure[r][c] >= 1)
    n_heights = len({state.structure[r][c]
                     for r in range(rows) for c in range(cols)
                     if state.structure[r][c] > 0})
    util_count = sum(1 for r in range(rows) for c in range(cols)
                     if (state.utilities[r][c] or "").strip())
    has_spawn = any((state.utilities[r][c] or "").startswith(("s", "sp"))
                    for r in range(rows) for c in range(cols))
    has_tele = any((state.utilities[r][c] or "").startswith(("t", "tp"))
                   for r in range(rows) for c in range(cols))
    return {
        "walk_pct": round(walk / max(cells, 1), 3),
        "n_heights": n_heights,
        "util_count": util_count,
        "has_spawn": has_spawn,
        "has_teleporter": has_tele,
        "verdict": (
            "exemplary" if has_spawn and has_tele and walk / cells > 0.4
            and n_heights >= 2
            else "strong" if has_spawn and has_tele and walk / cells > 0.3
            else "weak" if has_spawn and has_tele
            else "broken"
        ),
    }


# ── Sequence reading ───────────────────────────────────────────────
def load_sequence_maps(sequence_id: str) -> list[str]:
    path = SEQ_DIR / f"{sequence_id}.json"
    if not path.exists():
        raise SystemExit(f"sequence file not found: {path}")
    data = json.loads(path.read_text(encoding="utf-8"))
    seqs = data.get("sequences", {})
    if not seqs:
        return []
    # Prefer 'maps' (clean list) over 'content' (display strings).
    seq = next(iter(seqs.values()))
    return seq.get("maps", []) or seq.get("content", [])


def load_spine_sequences() -> list[str]:
    spine = json.loads(SPINE_PATH.read_text(encoding="utf-8"))
    return [s["name"] for s in spine.get("spine", {}).get("sequences", [])]


# ── Variant runner ─────────────────────────────────────────────────
def _extract_original_artifacts(src_data: dict) -> list[dict]:
    """Return a list of {row, col, token, role} from the original map.

    role is inferred:
      - 'central' when the artifact is closest to the center of mass
      - 'spawn-adjacent' when within 2 cells of the spawn utility
      - 'tele-adjacent' when within 2 cells of the teleporter
      - 'peripheral' otherwise
    """
    layers = src_data.get("layers", {})
    interact = layers.get("interactables", []) or []
    utils = layers.get("utilities", []) or []
    rows = len(interact)
    cols = max((len(r) for r in interact), default=0)
    spawn = tele = None
    for r in range(rows):
        for c in range(cols):
            u = str((utils[r] if r < len(utils) else [None] * cols)[c] if c < len((utils[r] if r < len(utils) else [])) else "" or "").strip()
            if u in ("s", "sp"): spawn = (r, c)
            elif u in ("t", "tp"): tele = (r, c)
    arts: list[dict] = []
    for r in range(rows):
        for c in range(min(cols, len(interact[r]))):
            tok = str(interact[r][c] or "").strip()
            if not tok or tok == " ":
                continue
            d_spawn = (abs(r - spawn[0]) + abs(c - spawn[1])) if spawn else 99
            d_tele = (abs(r - tele[0]) + abs(c - tele[1])) if tele else 99
            role = ("spawn-adjacent" if d_spawn <= 2
                    else "tele-adjacent" if d_tele <= 2
                    else "peripheral")
            arts.append({
                "row": r, "col": c, "token": tok, "role": role,
                "d_spawn": d_spawn, "d_tele": d_tele,
            })
    if arts:
        # Mark the artifact closest to spawn↔tele midpoint as 'central'.
        if spawn and tele:
            mid = ((spawn[0] + tele[0]) // 2, (spawn[1] + tele[1]) // 2)
            best = min(arts, key=lambda a: abs(a["row"] - mid[0]) + abs(a["col"] - mid[1]))
            best["role"] = "central"
    return arts


# ── AABB / spatial_needs lookup ────────────────────────────────────
# Cached on first call: token → { grid_cells: [w, d], spatial_needs: {...} }
_REG_CACHE: dict[str, dict] | None = None


def _load_artifact_metadata() -> dict[str, dict]:
    """Index commons/artifacts/registry/*.json by lookup_name → measurements + spatial_needs."""
    global _REG_CACHE
    if _REG_CACHE is not None:
        return _REG_CACHE
    out: dict[str, dict] = {}
    reg_dir = REPO / "commons" / "artifacts" / "registry"
    for reg_path in reg_dir.glob("*.json"):
        try:
            data = json.loads(reg_path.read_text(encoding="utf-8"))
        except Exception:
            continue
        arts = data.get("artifacts")
        if not isinstance(arts, dict):
            continue
        for key, entry in arts.items():
            if not isinstance(entry, dict):
                continue
            lname = entry.get("lookup_name") or key
            measurements = entry.get("measurements") or {}
            footprint_manual = entry.get("footprint")          # 3-int override (dressing-room)
            footprint_measured = entry.get("footprint_measured")
            grid_cells = (
                # manual takes priority, then [w,1,d] form, then 2-tuple
                [footprint_manual[0], footprint_manual[2]]
                if isinstance(footprint_manual, list) and len(footprint_manual) == 3
                else footprint_measured if isinstance(footprint_measured, list) and len(footprint_measured) == 2
                else (footprint_measured[:3:2] if isinstance(footprint_measured, list) and len(footprint_measured) == 3 else None)
                or measurements.get("grid_cells")
                or [1, 1]
            )
            out[lname] = {
                "grid_cells": grid_cells,
                "max_dim_m":  measurements.get("max_dimension_m") or 1.0,
                "spatial_needs": entry.get("spatial_needs") or {},
                # spatial_profile = auto-derived (or manually-overridden)
                # placement opinions: dir_group, range, density, etc.
                "spatial_profile": entry.get("spatial_profile") or {},
            }
    _REG_CACHE = out
    return out


def _token_to_lookup(token: str) -> str:
    """Strip the rotation/offset suffix from a placement token."""
    return (token or "").split(":", 1)[0].strip()


# Placement compatibility: (this_density, other_density) → "reject", "space",
# "overlap". "space" means must be ≥ 2 cells apart.
_DENS_RULES: dict[tuple[str, str], str] = {
    ("high", "high"):     "reject",
    ("high", "medium"):   "space",
    ("high", "low"):      "reject",
    ("high", "field"):    "overlap",
    ("medium", "high"):   "space",
    ("medium", "medium"): "space",
    ("medium", "low"):    "overlap",
    ("medium", "field"):  "overlap",
    ("low", "high"):      "reject",
    ("low", "medium"):    "overlap",
    ("low", "low"):       "overlap",
    ("low", "field"):     "overlap",
    ("field", "high"):    "overlap",
    ("field", "medium"):  "overlap",
    ("field", "low"):     "overlap",
    ("field", "field"):   "reject",
}


def _density_compatible(my_dens: str, their_dens: str, distance: int,
                        my_range: int, their_range: int) -> bool:
    """Can these two artifacts coexist at this distance?"""
    # Always OK if outside the larger of the two ranges.
    if distance > max(my_range, their_range, 1):
        return True
    rule = _DENS_RULES.get((my_dens or "medium", their_dens or "medium"), "space")
    if rule == "overlap": return True
    if rule == "reject":  return False
    # "space": apart by ≥ 2 cells.
    return distance >= 2


def _dir_group_fits(state: MapState, r: int, c: int, dir_group: str) -> bool:
    """Does cell (r, c) satisfy the artifact's orientation requirements?"""
    if not dir_group or dir_group in ("omni", "any"):
        return True
    h = state.structure[r][c] if state.in_bounds(r, c) else 0
    if dir_group == "plane":
        return h >= 2                              # sits on a raised plane
    if dir_group == "floor":
        return h >= 1                              # any walkable cube
    if dir_group == "panel":
        # at least one cardinal neighbor void OR a higher cube (back wall)
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nr, nc = r + dr, c + dc
            if not state.in_bounds(nr, nc): return True   # grid edge counts
            if state.structure[nr][nc] < 1: return True   # void neighbor
            if state.structure[nr][nc] > h: return True   # taller cube next door
        return False
    if dir_group == "corner":
        # two perpendicular cardinal neighbors must be void/edge
        n_void = 0
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nr, nc = r + dr, c + dc
            if not state.in_bounds(nr, nc) or state.structure[nr][nc] < 1:
                n_void += 1
        return n_void >= 2
    return True                                    # unknown → allow


def _bfs_reachable(state: MapState) -> set[tuple[int, int]]:
    """Cells reachable from spawn under the project's pathfinder rules:
    same-height free, drop free, climb only with wp on either side, tc/teleport
    cells walkable, void unwalkable. Returns set of (row, col)."""
    rows, cols = state.rows, state.cols
    spawn = None
    for r in range(rows):
        for c in range(cols):
            u = (state.utilities[r][c] or "").strip()
            if u in ("s", "sp"):
                spawn = (r, c); break
        if spawn: break
    if spawn is None:
        return set()
    walkable: set[tuple[int, int]] = set()
    teleset: set[tuple[int, int]] = set()
    for r in range(rows):
        for c in range(cols):
            u = (state.utilities[r][c] or "").strip()
            if u in ("t", "tp"): teleset.add((r, c))
            if state.structure[r][c] >= 1 or u.startswith(("wp", "tc")) or u in ("t", "tp"):
                walkable.add((r, c))

    def is_ramp(r: int, c: int) -> bool:
        u = (state.utilities[r][c] or "").strip()
        return u.startswith("wp") or u in ("r",) or u.startswith("r:")
    def is_tc(r: int, c: int) -> bool:
        u = (state.utilities[r][c] or "").strip()
        return u.startswith("tc")

    seen = {spawn}
    q: list[tuple[int, int]] = [spawn]
    while q:
        r, c = q.pop(0)
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nr, nc = r + dr, c + dc
            if (nr, nc) in seen: continue
            if not state.in_bounds(nr, nc): continue
            if (nr, nc) not in walkable: continue
            fh, th = state.structure[r][c], state.structure[nr][nc]
            climb = th - fh
            ok = (
                climb <= 0                                       # same height or drop
                or (climb == 1 and (is_ramp(r, c) or is_ramp(nr, nc)))   # +1 with wp
                or (is_tc(r, c) or is_tc(nr, nc))                # tc handles bigger
                or (nr, nc) in teleset
            )
            if ok:
                seen.add((nr, nc))
                q.append((nr, nc))
    return seen


def _ensure_artifacts_reachable(state: MapState, max_iters: int = 24) -> dict:
    """Walk every artifact cell from spawn. For any unreachable artifact,
    add the smallest mutation (wp ramp on a height-jump, tc transport on
    a void crossing, or h=1 cube to bridge) that would let the player
    walk there. Returns a diagnostics dict with counts.

    Algorithm per orphan:
        1. Find the spawn-reachable cell closest to the artifact.
        2. Walk a Manhattan path from there to the artifact.
        3. For each step:
             - dest is void   → set struct = 1
             - dest is climb of >1   → set wp:0 utility on dest
             - dest is climb of 1 with no ramp → set wp:0 on dest
        4. Re-run BFS; loop until reached or max_iters.

    The fixup keeps mutations *minimal* — it only patches the cells on
    the chosen path, not the whole map. The terraced strategy gets wp
    ramps; the islands strategy gets tc transports.
    """
    rows, cols = state.rows, state.cols
    fixes = {"wp_added": 0, "tc_added": 0, "cubes_added": 0,
             "fixed_artifacts": 0, "still_orphan": 0}

    # Collect artifact cells.
    art_cells: list[tuple[int, int]] = []
    for r in range(rows):
        for c in range(cols):
            tok = (state.interactables[r][c] or "").strip()
            if tok and tok != " ":
                art_cells.append((r, c))
    if not art_cells:
        return fixes

    for _ in range(max_iters):
        reachable = _bfs_reachable(state)
        orphans = [(r, c) for (r, c) in art_cells if (r, c) not in reachable]
        if not orphans:
            break

        # Process the orphan whose closest reachable cell is nearest first.
        def closest_reach(cell):
            return min(
                ((abs(r - cell[0]) + abs(c - cell[1]), (r, c)) for (r, c) in reachable),
                default=(10**9, None),
            )

        orphan = min(orphans, key=lambda x: closest_reach(x)[0])
        dist, src = closest_reach(orphan)
        if src is None:
            fixes["still_orphan"] += 1
            break

        # Walk Manhattan-style from src toward orphan, mutating as we go.
        r, c = src
        tr, tc = orphan
        while (r, c) != (tr, tc):
            # Choose next step: prefer the larger remaining axis.
            steps = []
            if r != tr: steps.append((1 if tr > r else -1, 0))
            if c != tc: steps.append((0, 1 if tc > c else -1))
            steps.sort(key=lambda s: -abs(s[0] * (tr - r) + s[1] * (tc - c)))
            dr, dc = steps[0]
            nr, nc = r + dr, c + dc
            if not state.in_bounds(nr, nc):
                break
            fh, th = state.structure[r][c], state.structure[nr][nc]
            u = (state.utilities[nr][nc] or "").strip()
            # Three cases:
            if th == 0:
                # Bridge a void. Prefer tc over a fresh cube on the
                # islands strategy (multiple voids). Heuristic: if both
                # the current cell and 2-cells-out are also void, this
                # is mid-void — use tc. Otherwise place a cube.
                two_out_r = nr + dr; two_out_c = nc + dc
                in2 = state.in_bounds(two_out_r, two_out_c)
                two_void = in2 and state.structure[two_out_r][two_out_c] == 0
                if two_void and u == "":
                    state.utilities[nr][nc] = "tc:1:auto:auto"
                    fixes["tc_added"] += 1
                else:
                    state.set_h(nr, nc, 1)
                    fixes["cubes_added"] += 1
            elif th - fh == 1 and not (
                u.startswith("wp") or u in ("r",) or u.startswith("r:")):
                # +1 climb: wp ramp on the higher cell. Heading is in
                # *degrees* (project convention, e.g. wp:90 in
                # Trans_Translation). Rotation points the low edge back
                # toward the approach direction so the wedge slopes
                # correctly.
                heading = 0 if dc == 1 else 2 if dc == -1 else 1 if dr == 1 else 3
                state.utilities[nr][nc] = f"wp:{heading * 90}"
                fixes["wp_added"] += 1
            elif th - fh >= 2:
                # +2/+3/+4 climb: physical wp ramp can't reach. Replace
                # the destination cube with a transport cube (tc) at the
                # *current* tier so the player can walk onto it and ride
                # up. tc:N:y means transport N cells along the y axis.
                lift = th - fh
                state.structure[nr][nc] = max(1, fh)        # bring cube down to walkable tier
                state.utilities[nr][nc] = f"tc:{lift}:y"    # lifts player by `lift`
                fixes["tc_added"] += 1
            # else: drop or same height — no fix needed for this step
            r, c = nr, nc

        fixes["fixed_artifacts"] += 1
    else:
        # Hit max_iters — count remaining orphans.
        reachable = _bfs_reachable(state)
        fixes["still_orphan"] = sum(1 for cell in art_cells if cell not in reachable)
    return fixes


# ── Placement strategies ────────────────────────────────────────────
# Each strategy is a function that takes (state, originals) and returns
# a list of (row, col, token) placements. The strategy doesn't write
# to state directly — the caller decides whether to apply, score, or
# skip (so we can A/B different strategies for the same map).
#
# strategies:
#   "nearest_role"  - Manhattan-nearest walkable cell, role-distance preserved
#                     (default; matches the previous behaviour)
#   "linear_path"   - artifacts strung along the BFS path spawn → teleport
#   "cluster_center"- central artifact at the path midpoint, others ring it
#   "cardinal"      - N/E/S/W of the map center; central at the centre
#   "perimeter"     - along the walkable border, evenly spaced

def _walkable_cells(state: MapState) -> list[tuple[int, int]]:
    cells = []
    for r in range(state.rows):
        for c in range(state.cols):
            if state.structure[r][c] >= 1:
                cells.append((r, c))
    return cells


def _spawn_tele(state: MapState) -> tuple[tuple[int, int] | None, tuple[int, int] | None]:
    spawn = tele = None
    for r in range(state.rows):
        for c in range(state.cols):
            u = (state.utilities[r][c] or "").strip()
            if u in ("s", "sp"): spawn = (r, c)
            elif u in ("t", "tp"): tele = (r, c)
    return spawn, tele


def _bfs_path(state: MapState, src: tuple[int, int],
              dst: tuple[int, int]) -> list[tuple[int, int]]:
    """Walkable cells along the shortest spawn→teleport path."""
    if src is None or dst is None: return []
    seen = {src}
    prev: dict[tuple[int, int], tuple[int, int]] = {}
    q = [src]
    while q:
        r, c = q.pop(0)
        if (r, c) == dst:
            path = [dst]
            while path[-1] != src:
                path.append(prev[path[-1]])
            path.reverse()
            return path
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nr, nc = r + dr, c + dc
            if (nr, nc) in seen: continue
            if not state.in_bounds(nr, nc): continue
            if state.structure[nr][nc] < 1: continue
            seen.add((nr, nc)); prev[(nr, nc)] = (r, c); q.append((nr, nc))
    return []


def _strategy_nearest_role(state: MapState, originals: list[dict],
                            occupied: set[tuple[int, int]]) -> list[tuple[int, int, str]]:
    """Original behaviour: pick walkable cells nearest to the original
    artifact positions, role-distance preserved (central vs spawn/tele
    adjacent)."""
    cands = [c for c in _walkable_cells(state) if c not in occupied]
    spawn, tele = _spawn_tele(state)
    out: list[tuple[int, int, str]] = []
    for art in originals:
        if not cands: break
        d_s = art.get("d_spawn", 99); d_t = art.get("d_tele", 99)
        def cost(cell: tuple[int, int]) -> int:
            r, c = cell
            ds = (abs(r - spawn[0]) + abs(c - spawn[1])) if spawn else 0
            dt = (abs(r - tele[0]) + abs(c - tele[1])) if tele else 0
            base = (abs(r - art["row"]) + abs(c - art["col"]))
            return base + abs(ds - d_s) + abs(dt - d_t)
        best = min(cands, key=cost)
        out.append((best[0], best[1], art["token"]))
        cands.remove(best)
    return out


def _strategy_linear_path(state: MapState, originals: list[dict],
                           occupied: set[tuple[int, int]]) -> list[tuple[int, int, str]]:
    """Distribute artifacts evenly along the spawn → teleport path so the
    player walks past each one in lesson order."""
    spawn, tele = _spawn_tele(state)
    path = _bfs_path(state, spawn, tele) if spawn and tele else []
    if not path:
        return _strategy_nearest_role(state, originals, occupied)
    # Sort artifacts by their original spawn-distance so role order is preserved.
    sorted_arts = sorted(originals, key=lambda a: a.get("d_spawn", 0))
    out: list[tuple[int, int, str]] = []
    n = len(sorted_arts)
    for i, art in enumerate(sorted_arts):
        if not path: break
        # Fractional position along the path; skip endpoints (spawn, tele).
        frac = (i + 1) / (n + 1)
        idx = max(1, min(len(path) - 2, int(frac * (len(path) - 1))))
        cell = path[idx]
        if cell in occupied:
            # find nearest free cell on path
            for off in range(1, len(path)):
                for sign in (1, -1):
                    j = idx + sign * off
                    if 0 <= j < len(path) and path[j] not in occupied:
                        cell = path[j]; break
                else: continue
                break
        out.append((cell[0], cell[1], art["token"]))
        occupied.add(cell)
    return out


def _strategy_cluster_center(state: MapState, originals: list[dict],
                              occupied: set[tuple[int, int]]) -> list[tuple[int, int, str]]:
    """Central teaching artifact at the path midpoint, others spiraling
    outward. Reads as a focused workshop with the focus in the middle."""
    spawn, tele = _spawn_tele(state)
    path = _bfs_path(state, spawn, tele) if spawn and tele else []
    center = path[len(path) // 2] if path else (state.rows // 2, state.cols // 2)
    walkable = [c for c in _walkable_cells(state) if c not in occupied]
    walkable.sort(key=lambda cc: abs(cc[0] - center[0]) + abs(cc[1] - center[1]))
    sorted_arts = sorted(originals, key=lambda a: 0 if a.get("role") == "central" else 1)
    out: list[tuple[int, int, str]] = []
    for art in sorted_arts:
        if not walkable: break
        cell = walkable.pop(0)
        out.append((cell[0], cell[1], art["token"]))
        occupied.add(cell)
    return out


def _strategy_cardinal(state: MapState, originals: list[dict],
                        occupied: set[tuple[int, int]]) -> list[tuple[int, int, str]]:
    """Central artifact at map centre, others at N/E/S/W cardinal points
    of the walkable region."""
    walkable = [c for c in _walkable_cells(state) if c not in occupied]
    if not walkable:
        return []
    cr = sum(c[0] for c in walkable) / len(walkable)
    cc = sum(c[1] for c in walkable) / len(walkable)
    # North = smallest row, South = largest, etc.
    by_row = sorted(walkable, key=lambda x: x[0])
    by_col = sorted(walkable, key=lambda x: x[1])
    cardinals = [
        (round(cr), round(cc)),                        # center
        by_row[0] if by_row else None,                  # north
        by_row[-1] if by_row else None,                 # south
        by_col[0] if by_col else None,                  # west
        by_col[-1] if by_col else None,                 # east
    ]
    sorted_arts = sorted(originals, key=lambda a: 0 if a.get("role") == "central" else 1)
    out: list[tuple[int, int, str]] = []
    used = set()
    for art in sorted_arts:
        cell = next((c for c in cardinals if c and c not in used and c not in occupied), None)
        if cell is None and walkable:
            cell = walkable.pop(0)
        if cell is None: break
        used.add(cell); occupied.add(cell)
        out.append((cell[0], cell[1], art["token"]))
    return out


def _strategy_perimeter(state: MapState, originals: list[dict],
                         occupied: set[tuple[int, int]]) -> list[tuple[int, int, str]]:
    """Artifacts along the walkable boundary, evenly spaced. Reads as a
    gallery / colonnade where the player walks around viewing each."""
    walkable = set(_walkable_cells(state))
    border = [c for c in walkable if any(
        (c[0] + dr, c[1] + dc) not in walkable
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1))
    ) and c not in occupied]
    if not border:
        return _strategy_nearest_role(state, originals, occupied)
    border.sort(key=lambda c: c)         # stable order
    n = len(originals)
    step = max(1, len(border) // max(n, 1))
    out: list[tuple[int, int, str]] = []
    for i, art in enumerate(originals):
        idx = (i * step) % len(border)
        cell = border[idx]
        if cell in occupied: continue
        out.append((cell[0], cell[1], art["token"]))
        occupied.add(cell)
    return out


PLACEMENT_STRATEGIES = {
    "nearest_role":   _strategy_nearest_role,
    "linear_path":    _strategy_linear_path,
    "cluster_center": _strategy_cluster_center,
    "cardinal":       _strategy_cardinal,
    "perimeter":      _strategy_perimeter,
}


def _place_artifacts_in_variant(state: MapState, originals: list[dict]) -> int:
    """Copy each original artifact onto a walkable cube in the variant.

    Now AABB-aware: each artifact's measured grid_cells are read from the
    registry; placement candidates whose footprint would overlap a wall,
    void, or already-placed artifact are rejected. Where spatial_needs is
    set, the placement honors:
      - surface=floor (default): cell must be a cube h>=1
      - surface=wall: cell must have an adjacent void/wall in some direction
      - surface=pedestal: cell must have h>=2 (raised)
    """
    rows, cols = state.rows, state.cols
    occupied: set[tuple[int, int]] = set()      # cells already taken by a footprint
    spawn = tele = None
    for r in range(rows):
        for c in range(cols):
            u = (state.utilities[r][c] or "").strip()
            if u in ("s", "sp"): spawn = (r, c); occupied.add((r, c))
            elif u in ("t", "tp"): tele = (r, c); occupied.add((r, c))
            tok = (state.interactables[r][c] or "").strip()
            if tok and tok != " ":
                occupied.add((r, c))

    # Strategy dispatch — env var ADA_PLACEMENT_STRATEGY (set by CLI)
    # picks one of PLACEMENT_STRATEGIES. Default "nearest_role" matches
    # the original behaviour. Strategies emit a plan; we then validate
    # it (AABB-fit + spatial_profile + density compatibility) before
    # writing to state, so the strategy can't violate the placer's
    # invariants — it just changes the *order* of candidate cells.
    import os as _os
    strat_name = _os.environ.get("ADA_PLACEMENT_STRATEGY", "nearest_role")
    strategy_fn = PLACEMENT_STRATEGIES.get(strat_name, _strategy_nearest_role)
    plan = strategy_fn(state, originals, set(occupied))   # pass copy
    if _os.environ.get("ADA_PLACEMENT_DEBUG") == "1":
        print(f"  placer[{strat_name}]: plan={[(r,c,t.split(':')[0]) for (r,c,t) in plan[:3]]}")

    meta = _load_artifact_metadata()

    def footprint_cells(r: int, c: int, w: int, d: int) -> list[tuple[int, int]]:
        """Return all cells the footprint covers, anchored at (r,c)."""
        return [(r + dr, c + dc) for dr in range(d) for dc in range(w)]

    def fits(cell: tuple[int, int], w: int, d: int, surface: str) -> bool:
        """True if the artifact's footprint can be placed at (cell, w, d)."""
        r, c = cell
        for fr, fc in footprint_cells(r, c, w, d):
            if fr < 0 or fr >= rows or fc < 0 or fc >= cols: return False
            # Every covered cell must be a walkable cube and not occupied.
            if state.structure[fr][fc] < 1: return False
            if (fr, fc) in occupied: return False
            if surface == "pedestal" and state.structure[fr][fc] < 2: return False
        if surface == "wall":
            # At least one cardinal neighbor of the anchor must be void/wall
            # so the artifact has a back wall to face.
            voids = 0
            for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nr, nc = r + dr, c + dc
                if nr < 0 or nr >= rows or nc < 0 or nc >= cols: voids += 1
                elif state.structure[nr][nc] < 1: voids += 1
            if voids == 0: return False
        return True

    # Track placements with their spatial profile so range/density rules
    # can be checked against neighbors.
    placed_with_profile: list[tuple[tuple[int, int], dict]] = []
    placed = 0
    for art in originals:
        token = art["token"]
        lookup = _token_to_lookup(token)
        info = meta.get(lookup) or {"grid_cells": [1, 1], "spatial_needs": {},
                                     "spatial_profile": {}}
        gc = info.get("grid_cells") or [1, 1]
        # Be conservative: round to ints, cap at 3 cells in a single dim
        # (huge artifacts like AntColonyV2 default to 3 — prevents wholesale
        # rejection, but flags up in the manifest's diagnostic data).
        w = max(1, min(3, int(round(gc[0])) if len(gc) > 0 else 1))
        d = max(1, min(3, int(round(gc[1])) if len(gc) > 1 else 1))
        # Manual spatial_needs (the editor) wins; auto spatial_profile
        # fills the rest.
        sneeds = info.get("spatial_needs") or {}
        sprof  = info.get("spatial_profile") or {}
        surface   = sneeds.get("surface", "floor")
        dir_group = sneeds.get("dir_group") or sprof.get("dir_group") or "omni"
        density   = sneeds.get("density")   or sprof.get("density")   or "medium"
        my_range  = sneeds.get("range")     or sprof.get("range")     or 2
        clearance = sneeds.get("min_clearance") or sprof.get("min_clearance") or 0

        # Build & rank candidate anchor cells.
        cands: list[tuple[int, int]] = []
        for r in range(rows):
            for c in range(cols):
                if (r, c) in occupied: continue
                if state.structure[r][c] < 1: continue
                # surface (legacy) and dir_group (new) must both pass.
                if not fits((r, c), w, d, surface): continue
                if not _dir_group_fits(state, r, c, dir_group): continue
                # density × range compatibility against everyone already placed.
                ok = True
                for (pr, pc), p_prof in placed_with_profile:
                    distance = abs(r - pr) + abs(c - pc)
                    p_dens  = p_prof.get("density", "medium")
                    p_range = p_prof.get("range", 2)
                    if not _density_compatible(density, p_dens, distance,
                                                my_range, p_range):
                        ok = False; break
                if not ok: continue
                cands.append((r, c))
        if not cands:
            # No placement fits — fall back to single-cell anchor on any
            # walkable cube. Better one cell wrong than the artifact dropped.
            for r in range(rows):
                for c in range(cols):
                    if (r, c) in occupied: continue
                    if state.structure[r][c] >= 1: cands.append((r, c)); break
                if cands: break
        if not cands:
            continue

        target_d_spawn = art.get("d_spawn", 99)
        target_d_tele = art.get("d_tele", 99)
        # Look up the strategy's preferred cell for this artifact (by token).
        planned_cell = next(
            ((pr, pc) for (pr, pc, ptok) in plan if ptok == token), None
        )
        def cost(cell: tuple[int, int]) -> int:
            r, c = cell
            ds = (abs(r - spawn[0]) + abs(c - spawn[1])) if spawn else 0
            dt = (abs(r - tele[0]) + abs(c - tele[1])) if tele else 0
            base = (abs(r - art["row"]) + abs(c - art["col"]))
            score = base + abs(ds - target_d_spawn) + abs(dt - target_d_tele)
            # Strong bias toward the strategy's planned cell (first
            # acceptable candidate) so e.g. linear_path actually gets
            # used when AABB/density let it through.
            if planned_cell is not None and cell == planned_cell:
                score -= 1000
            elif planned_cell is not None:
                # Bias toward cells *near* the planned cell as a
                # secondary signal — keeps the strategy's intent even
                # if the exact cell is unavailable.
                score += abs(r - planned_cell[0]) + abs(c - planned_cell[1])
            return score
        best = min(cands, key=cost)
        if _os.environ.get("ADA_PLACEMENT_DEBUG") == "1":
            short_tok = (token or "").split(":")[0]
            in_cands = planned_cell in cands if planned_cell else False
            print(f"    {short_tok:30s} plan={planned_cell} chose={best} "
                  f"plan_in_cands={in_cands} n_cands={len(cands)}")
        state.interactables[best[0]][best[1]] = token
        for fc in footprint_cells(best[0], best[1], w, d):
            occupied.add(fc)
        placed_with_profile.append((best, {
            "density": density, "range": my_range,
            "dir_group": dir_group, "lookup": lookup,
        }))
        placed += 1
    return placed


def run_one_map(base_name: str, n_variants: int, seed: int = 42,
                force: bool = False, budget: Budget | None = None,
                imprint: Imprint | None = None,
                roster: list[str] | None = None) -> list[dict]:
    src = MAPS_DIR / base_name / "map_data.json"
    if not src.exists():
        return [{"base": base_name, "error": "no map_data.json"}]
    src_data = json.loads(src.read_text(encoding="utf-8"))
    struct = src_data.get("layers", {}).get("structure", [])
    orig_rows, orig_cols = _grid_dims(struct)
    if orig_rows == 0 or orig_cols == 0:
        return [{"base": base_name, "error": "empty structure"}]
    # Apply the budget — if any — to clamp variant dimensions. This is the
    # heart of "constraint produces character": same strategies, smaller
    # canvas, denser composition.
    if budget is not None:
        # Imprint scales the budget AND the target dimensions, so even
        # when the original map is small the growth signal gets through.
        # Without dimension scaling, fit_dims keeps small originals
        # small at g=1.0 — the player can't feel the rooms grow.
        if imprint is not None:
            g = imprint.cells_scale
            # Target dims interpolate between grid_min (g=0) and grid_max (g=1).
            # We use a softened lower bound (60% of grid_min size, capped)
            # so map idx 0 isn't aggressively shrunk to nothing.
            min_r, min_c = budget.grid_min
            max_r, max_c = budget.grid_max
            target_r = max(min_r, int(min_r + (max_r - min_r) * g))
            target_c = max(min_c, int(min_c + (max_c - min_c) * g))
            scaled = Budget(
                label=f"{budget.label} g{imprint.idx+1}/{imprint.total}",
                cells_max=int(budget.cells_max * g),
                voxels_max=int(budget.voxels_max * g),
                artifacts_required=budget.artifacts_required,
                path_budget=budget.path_budget,
                util_density=budget.util_density,
                grid_max=(target_r, target_c),         # the imprint sets
                grid_min=budget.grid_min,
            )
            # Use scaled max as the *target* (not just upper bound) so
            # fit_dims pads when the original is smaller than the target.
            rows = max(min_r, min(target_r, max_r))
            cols = max(min_c, min(target_c, max_c))
            budget = scaled
        else:
            scaled = budget
            rows, cols = fit_dims(orig_rows, orig_cols, scaled)
            budget = scaled
    else:
        rows, cols = orig_rows, orig_cols
    original_arts = _extract_original_artifacts(src_data)
    original_artifact_defs = src_data.get("artifact_definitions", {}) or {}

    all_strategies = variant_strategies(rows, cols, base_name,
                                         budget=budget, imprint=imprint)
    # Filter roster: only keep strategies the sequence allows.
    if roster:
        all_strategies = [c for c in all_strategies
                          if any(c["id"].endswith(s) for s in roster)]
    strategies = all_strategies[:n_variants]
    results: list[dict] = []
    for cfg in strategies:
        # Pass dims into the runner so MapState gets sized correctly.
        cfg.setdefault("rows", rows)
        cfg.setdefault("cols", cols)
        vid = cfg["id"]
        out_dir = MAPS_DIR / vid
        out_path = out_dir / "map_data.json"
        if out_path.exists() and not force:
            results.append({"id": vid, "status": "exists"})
            continue
        # Two flows:
        #   grammar_first (default) — generate structure via ops, then
        #     fit artifacts to the structure that came out.
        #   place_first — artifacts are placed FIRST on a flat canvas
        #     (their footprints become inviolable), then grammar runs,
        #     then artifact cells are restored if grammar overwrote.
        #     Reads as "artifacts choose where they want to be; the
        #     architecture grows around them."
        import os as _os
        gen_mode = _os.environ.get("ADA_GEN_MODE", "grammar_first")

        if gen_mode == "place_first":
            try:
                # Start with a flat walkable canvas so the placer has
                # candidates everywhere.
                from map_grammar.ops import MapState as _MS
                pre_state = _MS(rows=cfg.get("rows", rows), cols=cfg.get("cols", cols))
                for r in range(pre_state.rows):
                    for c in range(pre_state.cols):
                        pre_state.set_h(r, c, 1)
                # Place artifacts on the flat canvas.
                pre_placed = _place_artifacts_in_variant(pre_state, original_arts)
                # Capture the artifact footprints + tokens so we can
                # re-stamp after grammar runs.
                anchored_cells: list[tuple[int, int, str]] = []
                for r in range(pre_state.rows):
                    for c in range(pre_state.cols):
                        tok = (pre_state.interactables[r][c] or "").strip()
                        if tok and tok != " ":
                            anchored_cells.append((r, c, tok))
                # Now run grammar ops on a *fresh* state (so ops apply
                # cleanly without pre-stamped floor confusing them).
                state = run_config(cfg, seed=seed)
                # Re-assert artifact footprints: force walkable cube
                # AND restore the interactable token on each anchored
                # cell. Grammar's structural choice is preserved
                # everywhere ELSE.
                for (ar, ac, atok) in anchored_cells:
                    if not state.in_bounds(ar, ac): continue
                    if state.structure[ar][ac] < 1:
                        state.set_h(ar, ac, 1)
                    state.interactables[ar][ac] = atok
                n_placed = len(anchored_cells)
            except Exception as e:
                results.append({"id": vid, "error": f"place_first: {e}"})
                continue
        else:
            try:
                state = run_config(cfg, seed=seed)
            except Exception as e:
                results.append({"id": vid, "error": str(e)})
                continue
            # Carry the original artifacts onto walkable cubes in the variant
            # using a role-aware nearest-cell strategy. This is the part that
            # makes the variant *teach the same lesson* as its parent.
            n_placed = _place_artifacts_in_variant(state, original_arts)
        # Reachability fixup: lay wp ramps / tc transports / fill cubes
        # so the player can actually walk to every placed artifact. This
        # is the difference between "structurally interesting" and
        # "playable" — terraced strategies in particular leave artifacts
        # stranded on platforms without it.
        fixes = _ensure_artifacts_reachable(state)
        scores = eval_variant(state)
        scores["artifacts_placed"] = n_placed
        scores["artifacts_original"] = len(original_arts)
        scores["reachability_fixes"] = fixes
        data = to_map_data_json(
            state, vid,
            description=f"Spine variant of {base_name}: {cfg['notes']}",
            config_id=vid,
            ops=cfg["ops"],
        )
        # Carry over artifact_definitions so the variant resolves the
        # same scenes the original used (avoids "unknown artifact" warnings).
        if original_artifact_defs:
            data["artifact_definitions"] = original_artifact_defs
        # Tag the lineage so the encyclopedia can render derived-from chips.
        data.setdefault("map_info", {}).setdefault("metadata", {})
        data["map_info"]["metadata"].update({
            "spine_research": True,
            "derived_from": base_name,
            "scores": scores,
            "budget": budget.to_dict() if budget else None,
            "rows": rows, "cols": cols,
            "saved_at": datetime.utcnow().isoformat() + "Z",
        })
        out_dir.mkdir(parents=True, exist_ok=True)
        out_path.write_text(json.dumps(data, indent=2), encoding="utf-8")
        # Iso thumbnail next to the JSON (and mirrored to the encyclopedia).
        thumb = out_dir / "map_iso.png"
        try:
            render_iso(state.structure, thumb, cell_px=12,
                       utilities=state.utilities,
                       interactables=state.interactables)
        except Exception as e:
            results.append({"id": vid, "warn": f"render failed: {e}"})
        results.append({
            "id": vid, "status": "written",
            "scores": scores, "notes": cfg["notes"],
        })
    return results


# ── Manifest emit ──────────────────────────────────────────────────
import shutil


def _flatten_entries(sequence_id: str, runs: list[dict]) -> list[dict]:
    """Convert per-map runs to flat entries the gallery reader understands."""
    entries: list[dict] = []
    for r in runs:
        base = r["base"]
        for v in r.get("variants", []):
            if "id" not in v or v.get("error"):
                continue
            scores = v.get("scores", {})
            # Pull rows/cols/budget directly off the variant's map_data so
            # the gallery has it without a second read.
            map_path = MAPS_DIR / v["id"] / "map_data.json"
            rows = cols = None
            budget_label = None
            if map_path.exists():
                try:
                    md = json.loads(map_path.read_text(encoding="utf-8"))
                    md_meta = md.get("map_info", {}).get("metadata", {})
                    rows = md_meta.get("rows")
                    cols = md_meta.get("cols")
                    budget_label = (md_meta.get("budget") or {}).get("label")
                except Exception:
                    pass
            entries.append({
                "id": v["id"],
                "notes": v.get("notes") or f"variant of {base} ({sequence_id})",
                "image": f"/spine-research/{v['id']}.png",
                "map_name": v["id"],
                "derived_from": base,
                "sequence": sequence_id,
                "verdict": scores.get("verdict"),
                "walk_pct": scores.get("walk_pct"),
                "n_heights": scores.get("n_heights"),
                "rows": rows,
                "cols": cols,
                "budget": budget_label,
                "rule_count": None,
            })
    return entries


def emit_manifest(sequence_id: str, runs: list[dict]) -> Path:
    RESEARCH_DIR.mkdir(parents=True, exist_ok=True)
    out = RESEARCH_DIR / f"{sequence_id}.json"
    payload = {
        "sequence": sequence_id,
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "runs": runs,
    }
    out.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    if not ENCYCLOPEDIA.exists():
        return out

    MIRROR_DIR.mkdir(parents=True, exist_ok=True)
    (MIRROR_DIR / f"{sequence_id}.json").write_text(
        json.dumps(payload, indent=2), encoding="utf-8")

    # Copy each variant's iso thumbnail into the gallery so manifest paths
    # resolve from /spine-research/<id>.png.
    new_entries = _flatten_entries(sequence_id, runs)
    for e in new_entries:
        src_png = MAPS_DIR / e["id"] / "map_iso.png"
        if src_png.exists():
            shutil.copy2(src_png, MIRROR_DIR / f"{e['id']}.png")

    # Merge with any prior manifest entries (drop ones for ids we just wrote
    # plus stale ones whose underlying map_data.json has been deleted).
    manifest_path = MIRROR_DIR / "manifest.json"
    existing: list[dict] = []
    if manifest_path.exists():
        try:
            existing = json.loads(manifest_path.read_text(encoding="utf-8")).get(
                "entries", []) or []
        except Exception:
            existing = []
    new_ids = {e["id"] for e in new_entries}
    def map_alive(eid: str) -> bool:
        return (MAPS_DIR / eid / "map_data.json").exists()
    # Drop any existing entry that belongs to THIS sequence — the new
    # run is the truth for it. Existing entries from OTHER sequences are
    # kept (still alive on disk). This is what makes the roster filter
    # effective: strategies dropped from a sequence's roster fall out
    # of its gallery on the next sweep.
    merged = [e for e in existing
              if e.get("id") not in new_ids
              and e.get("sequence") != sequence_id
              and map_alive(e.get("id", ""))]
    merged.extend(new_entries)
    manifest_path.write_text(json.dumps({
        "schema_version": 1,
        "version": 1,
        "description": ("Spine-research gallery — N grammar variants per "
                        "spine map, each a real commons/maps/<base>_v<n>. "
                        "Click to play in the Three.js voxel viewer."),
        "entries": merged,
    }, indent=2), encoding="utf-8")
    return out


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("sequence", nargs="?", help="sequence id (e.g. color)")
    p.add_argument("--map", default="", help="run only this map in the sequence")
    p.add_argument("--n", type=int, default=5,
                   help="number of variant strategies per map (1-5)")
    p.add_argument("--seed", type=int, default=42)
    p.add_argument("--force", action="store_true",
                   help="overwrite existing variant directories")
    p.add_argument("--all-spine", action="store_true",
                   help="run every spine sequence in order")
    p.add_argument("--budget", default="tight",
                   choices=["tight", "relaxed", "one_step_tighter"],
                   help="resource budget mode: tight=phase-aware compression "
                        "(default), relaxed=no constraint, one_step_tighter="
                        "use the previous phase's budget for ascetic variants")
    p.add_argument("--placement", default="nearest_role",
                   choices=list(PLACEMENT_STRATEGIES.keys()),
                   help="artifact placement strategy: nearest_role (default), "
                        "linear_path (along spawn→tele), cluster_center "
                        "(focal point in middle), cardinal (N/E/S/W), "
                        "perimeter (gallery walk around the edge)")
    p.add_argument("--mode", default="grammar_first",
                   choices=["grammar_first", "place_first"],
                   help="generation order: grammar_first (default — generate "
                        "structure, then place artifacts on it) or "
                        "place_first (artifacts anchor first, leaving their "
                        "footprints, grammar fills the rest)")
    args = p.parse_args()
    # Set the placement strategy + generation mode via env so they
    # reach _place_artifacts_in_variant and run_one_map without
    # threading kwargs through the whole stack.
    import os as _os
    _os.environ["ADA_PLACEMENT_STRATEGY"] = args.placement
    _os.environ["ADA_GEN_MODE"] = args.mode

    sequences = load_spine_sequences() if args.all_spine else (
        [args.sequence] if args.sequence else [])
    if not sequences:
        p.print_help(); return 1

    # Load the spine once so we can look up phases for budget resolution.
    spine_data = json.loads(SPINE_PATH.read_text(encoding="utf-8"))

    summary = {"sequences": []}
    for sid in sequences:
        try:
            maps = load_sequence_maps(sid)
        except SystemExit as e:
            print(f"  ! {sid}: {e}"); continue
        if args.map:
            maps = [m for m in maps if m == args.map]
        budget = budget_for_sequence(sid, spine_data, mode=args.budget)
        roster = allowed_strategies(sid)
        roster_label = ",".join(roster) if roster else "all"
        print(f"  budget for {sid}: {budget.label} "
              f"(cells_max={budget.cells_max}, grid<={budget.grid_max})")
        print(f"  roster:  {roster_label}")
        runs: list[dict] = []
        for i, base in enumerate(maps):
            imp = imprint_for(sid, i, len(maps))
            print(f"  [{sid}] -> {base}  g={imp.growth:.2f} "
                  f"(hilbert={imp.hilbert_order} bsp={imp.bsp_depth} "
                  f"terr={imp.terraced_steps} ca_gen={imp.ca_generations})")
            results = run_one_map(base, args.n,
                                  seed=args.seed, force=args.force,
                                  budget=budget, imprint=imp,
                                  roster=roster)
            runs.append({"base": base, "variants": results})
        manifest = emit_manifest(sid, runs)
        print(f"    wrote {manifest.relative_to(REPO)}")
        summary["sequences"].append({"id": sid, "n_maps": len(runs)})

    print(f"\n=== summary ===  sequences: {len(summary['sequences'])}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
