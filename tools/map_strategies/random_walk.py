"""Drunkard's walk — agent-based cave carving.

A random walker starts at the centre and turns each step. Cells visited
become floor. Sweep target_fraction to get small cells vs. wide caves.
Lineage: Polya (1921), Brogue, NetHack."""
from __future__ import annotations

from typing import Iterator
from .base import Strategy, StrategyResult, make_grid, neighbours4, seeded_rng


class RandomWalk(Strategy):
    name = "random_walk"
    tier = "agent"
    description = ("A drunkard's walk carves floor cells until target "
                   "fraction reached. Each fraction value gives a different "
                   "cave size; same seed = same cave.")

    def iter_candidates(self, width: int, height: int, seed: int) -> Iterator[StrategyResult]:
        for fraction in (0.15, 0.25, 0.4, 0.55, 0.7):
            yield self._carve(width, height, fraction, seed)

    def _carve(self, cols: int, rows: int, fraction: float, seed: int) -> StrategyResult:
        rng = seeded_rng(seed, f"rw:{fraction}")
        target = int(rows * cols * fraction)
        grid = make_grid(rows, cols, 0)
        r, c = rows // 2, cols // 2
        grid[r][c] = 1
        visited = 1
        steps = 0
        while visited < target and steps < target * 12:
            dr, dc = rng.choice([(-1, 0), (1, 0), (0, -1), (0, 1)])
            r = max(1, min(rows - 2, r + dr))
            c = max(1, min(cols - 2, c + dc))
            if grid[r][c] == 0:
                grid[r][c] = 1
                visited += 1
            steps += 1
        return StrategyResult(
            name=self.name,
            label=f"frac={fraction:.2f}",
            heights=grid,
            params={"fraction": fraction, "seed": seed},
        )
