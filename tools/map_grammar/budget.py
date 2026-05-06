"""Resource budgets for spine variant generation.

The principle: every notable spatial vocabulary in history was shaped by a
scarcity (steel after the war, tatami mats, taxed perimeter walls, the
formwork mold of brutalist concrete). Without a budget, the grammar
sprawls; with one slightly too tight, it makes choices.

We map the QFEP curriculum phases onto a budget arc:

    F_order      → tight       (primitives, transformation, array, color)
    oscillation  → tight-medium (forces, wavefunctions)
    E_entropy    → medium      (randomness, noise, cellularautomata)
    lambda_edge  → medium-loose (fractals, lsystems, procgen, iso/boolean)
    integration  → loose       (softbodies, swarm, ML, graphtheory)
    synthesis    → very loose  (foundationscrisis, qfeplaboratory, post)

The result is a built-in arc: rooms get bigger as you walk the spine.
The architecture *embodies* the QFEP progression.
"""
from __future__ import annotations

from dataclasses import dataclass, asdict
from typing import Optional


@dataclass(frozen=True)
class Budget:
    """Resource ceiling for a single variant generation."""
    label:        str         # human-readable tag, e.g. "F_order tight"
    cells_max:    int         # total walkable cells allowed
    voxels_max:   int         # total cube volume (sum of heights) allowed
    artifacts_required: int   # MUST fit at least this many
    path_budget:  int         # max BFS spawn → teleport steps; -1 = no cap
    util_density: float       # max ratio of wp/tc cells to walkable cells
    grid_max:     tuple[int, int]   # (rows_max, cols_max) hard ceiling
    grid_min:     tuple[int, int]   # (rows_min, cols_min) hard floor

    def to_dict(self) -> dict:
        return asdict(self)


# ── Phase budgets ──────────────────────────────────────────────────
# Numbers chosen so the *areas* roughly double each phase. The intent
# is for the player to feel the rooms get bigger as they walk the spine.

BUDGET_BY_PHASE: dict[str, Budget] = {
    "F_order": Budget(
        label="F_order tight",
        cells_max=64,           # ~ 8×8 walkable interior
        voxels_max=110,
        artifacts_required=3,
        path_budget=14,
        util_density=0.05,
        grid_max=(10, 10),
        grid_min=(6, 6),
    ),
    "oscillation": Budget(
        label="oscillation tight-medium",
        cells_max=110,
        voxels_max=200,
        artifacts_required=4,
        path_budget=20,
        util_density=0.10,
        grid_max=(13, 13),
        grid_min=(8, 8),
    ),
    "E_entropy": Budget(
        label="E_entropy medium",
        cells_max=160,
        voxels_max=280,
        artifacts_required=5,
        path_budget=26,
        util_density=0.15,
        grid_max=(15, 15),
        grid_min=(10, 10),
    ),
    "lambda_edge": Budget(
        label="lambda_edge medium-loose",
        cells_max=220,
        voxels_max=380,
        artifacts_required=6,
        path_budget=32,
        util_density=0.20,
        grid_max=(18, 18),
        grid_min=(12, 12),
    ),
    "integration": Budget(
        label="integration loose",
        cells_max=300,
        voxels_max=520,
        artifacts_required=7,
        path_budget=40,
        util_density=0.25,
        grid_max=(22, 22),
        grid_min=(14, 14),
    ),
    "synthesis": Budget(
        label="synthesis very-loose",
        cells_max=400,
        voxels_max=700,
        artifacts_required=8,
        path_budget=50,
        util_density=0.30,
        grid_max=(26, 26),
        grid_min=(16, 16),
    ),
}


# Override for the "no constraint" mode — generates at the original map's
# dimensions, the way we did before this module existed.
RELAXED = Budget(
    label="relaxed",
    cells_max=10_000, voxels_max=20_000, artifacts_required=0,
    path_budget=-1, util_density=1.0,
    grid_max=(40, 40), grid_min=(4, 4),
)


def fit_dims(orig_rows: int, orig_cols: int, b: Budget) -> tuple[int, int]:
    """Clamp the variant's grid dimensions to fit the budget.

    Aim is to keep aspect ratio close to the original while:
      - rows × cols stays under the implied area cap
      - rows ≥ grid_min[0], cols ≥ grid_min[1]
      - rows ≤ grid_max[0], cols ≤ grid_max[1]
    """
    rows = max(b.grid_min[0], min(b.grid_max[0], orig_rows))
    cols = max(b.grid_min[1], min(b.grid_max[1], orig_cols))
    # Area cap: walkable interior ~ (rows-2)(cols-2) when border is 1 thick.
    # If too big, scale both axes down proportionally.
    interior = max(1, (rows - 2) * (cols - 2))
    if interior > b.cells_max:
        scale = (b.cells_max / interior) ** 0.5
        rows = max(b.grid_min[0], int(rows * scale))
        cols = max(b.grid_min[1], int(cols * scale))
    return rows, cols


def phase_for_sequence(seq_name: str, spine: dict) -> str:
    """Look up the QFEP phase from the curriculum spine."""
    for s in spine.get("spine", {}).get("sequences", []):
        if s.get("name") == seq_name:
            return s.get("phase", "F_order")
    return "F_order"


def budget_for_sequence(seq_name: str, spine: dict, mode: str = "tight") -> Budget:
    """Return the budget that should govern variants in this sequence.

    mode:
      'tight'     - phase budget as defined in BUDGET_BY_PHASE
      'relaxed'   - no constraint (back to pre-budget behavior)
      'one_step_tighter' - apply the previous phase's budget; useful to
        force compression (e.g. an integration sequence under E_entropy
        budget produces ascetic late-spine maps).
    """
    if mode == "relaxed":
        return RELAXED
    phase = phase_for_sequence(seq_name, spine)
    if mode == "one_step_tighter":
        order = ["F_order", "oscillation", "E_entropy",
                 "lambda_edge", "integration", "synthesis"]
        i = order.index(phase) if phase in order else 0
        phase = order[max(0, i - 1)]
    return BUDGET_BY_PHASE.get(phase, BUDGET_BY_PHASE["F_order"])
