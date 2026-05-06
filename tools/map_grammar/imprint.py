"""Sequence imprint: encode the algorithm of the lesson into the map.

Three signals layered on top of the budget system:

  1. STRATEGY ROSTER PER SEQUENCE — fractals get curves and recursion,
     l-systems get branching, randomness gets walks, cellular-automata
     get evolved fields. The wrong strategies don't show up in the wrong
     sequences. The map's *vocabulary* matches the lesson.

  2. GROWING BUDGET WITHIN SEQUENCE — map index 0 starts at 60% of the
     phase budget; the last map reaches 100%. So even within a phase
     (where the QFEP budget is fixed), the player feels the rooms grow
     as they walk the sequence. Each map is the algorithm at step N.

  3. GROWTH / DECAY PARAMETERS — the strategy's iteration count, depth,
     period, or seed-density scales with map index. Hilbert order 1
     becomes Hilbert order 4. CA generations 0 become CA generations
     200. Recursion depth 1 becomes recursion depth 5. The map IS the
     algorithm at step N.

This is the missing layer between the grammar and the curriculum.
The grammar produces shapes; the imprint connects them to lessons.
"""
from __future__ import annotations

from dataclasses import dataclass


# Per-sequence preferred strategies. Empty list = use any.
# Names match the strategy ids in spine_auto_research.py:
#   v1_corridor, v2_bsp, v3_terraced, v4_islands, v5_symmetric,
#   v6_column_grid, v7_curve.
SEQUENCE_STRATEGIES: dict[str, list[str]] = {
    # F_order — tight, pure, structural
    "primitives":           ["v1_corridor", "v3_terraced", "v6_column_grid"],
    "transformation":       ["v3_terraced", "v5_symmetric", "v6_column_grid"],
    "array_tutorial":       ["v6_column_grid", "v7_curve", "v5_symmetric"],
    "color":                ["v6_column_grid", "v3_terraced", "v5_symmetric"],

    # oscillation — flow, wave, repetition
    "forces":               ["v4_islands", "v3_terraced", "v1_corridor"],
    "wavefunctions":        ["v7_curve", "v5_symmetric", "v3_terraced"],

    # E_entropy — disorder, sampling
    "randomness":           ["v1_corridor", "v2_bsp", "v4_islands"],
    "noise":                ["v3_terraced", "v4_islands", "v2_bsp"],
    "cellularautomata":     ["v2_bsp", "v3_terraced", "v5_symmetric"],

    # lambda_edge — emergent, recursive
    "fractals":             ["v7_curve", "v3_terraced", "v5_symmetric"],
    "lsystems":             ["v7_curve", "v4_islands", "v3_terraced"],
    "proceduralgeneration": ["v2_bsp", "v4_islands", "v7_curve"],
    "isosurfaces":          ["v3_terraced", "v4_islands", "v7_curve"],
    "boolean_surfaces":     ["v3_terraced", "v6_column_grid", "v5_symmetric"],

    # integration — composing systems
    "softbodies":           ["v3_terraced", "v4_islands", "v5_symmetric"],
    "swarmintelligence":    ["v1_corridor", "v4_islands", "v7_curve"],
    "machinelearning":      ["v3_terraced", "v2_bsp", "v5_symmetric"],
    "graphtheory":          ["v2_bsp", "v6_column_grid", "v5_symmetric"],

    # synthesis — full library
    "foundationscrisis":    ["v5_symmetric", "v4_islands", "v3_terraced"],
    "qfeplaboratory":       ["v6_column_grid", "v3_terraced", "v5_symmetric"],
    "postfoundationscrisis":["v4_islands", "v5_symmetric", "v2_bsp"],
}


def allowed_strategies(sequence_id: str) -> list[str] | None:
    """Return the list of strategy ids preferred for this sequence,
    or None if the sequence has no roster (use all)."""
    return SEQUENCE_STRATEGIES.get(sequence_id)


# ── Growth ────────────────────────────────────────────────────────
def growth_factor(idx: int, total: int) -> float:
    """0.6 (first map) → 1.0 (last map). Linear within sequence."""
    if total <= 1:
        return 1.0
    return 0.6 + 0.4 * (idx / (total - 1))


@dataclass
class Imprint:
    """Per-map imprint: the algorithm-step parameters scaled by index."""
    sequence:    str
    idx:         int
    total:       int
    growth:      float       # 0.6 → 1.0
    cells_scale: float       # apply to budget.cells_max
    # Strategy-specific growth parameters. Each maps to an op's input
    # so the op's *iteration count*, *recursion depth*, *period*, etc.
    # scale with index — the map literally embodies the algorithm at
    # step N.
    hilbert_order:    int    # 1 → 4 across sequence (curve)
    bsp_depth:        int    # 1 → 4 (procedural partitioning)
    terraced_steps:   int    # 1 → 5 (height tiers)
    voronoi_seeds:    int    # 2 → 8 (cell partitioning)
    petal_count:      int    # 3 → 8 (radial composition)
    column_period:    int    # 2 → 4 (Mies bay scale)
    ca_generations:   int    # 1 → 80 (cellular-automata steps)
    drunkard_steps_factor: float  # 0.15 → 0.40 of cells (random walk density)


def imprint_for(sequence_id: str, idx: int, total: int) -> Imprint:
    """Build the per-map imprint."""
    g = growth_factor(idx, total)
    # Most parameters scale linearly with growth. We round and clamp
    # to the op's reasonable range.
    def s(lo: int, hi: int) -> int:
        return int(round(lo + (hi - lo) * g))
    return Imprint(
        sequence=sequence_id, idx=idx, total=total, growth=g,
        cells_scale=g,
        hilbert_order=max(1, min(5, s(1, 4))),
        bsp_depth=max(1, min(5, s(1, 4))),
        terraced_steps=max(1, min(6, s(1, 5))),
        voronoi_seeds=max(2, min(10, s(2, 8))),
        petal_count=max(3, min(8, s(3, 8))),
        column_period=max(2, min(4, s(2, 4))),
        ca_generations=max(0, s(0, 80)),
        drunkard_steps_factor=0.15 + 0.25 * g,
    )
