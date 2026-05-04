"""Cellular automata cave smoothing.

Standard 4-5 rule: start from random fill, then for N iterations each
cell becomes wall if it has >= birth_threshold wall neighbours; floor
otherwise. Gives organic chambers — Conway-flavoured generation."""
from __future__ import annotations

from typing import Iterator
from .base import Strategy, StrategyResult, make_grid, seeded_rng, neighbours4


class CellularAutomataCave(Strategy):
    name = "cellular_automata"
    tier = "automaton"
    description = ("Random fill → smooth via Moore-neighbourhood rule. "
                   "wall_chance sets the seed density; iterations decide "
                   "how round the chambers become.")

    def iter_candidates(self, width: int, height: int, seed: int) -> Iterator[StrategyResult]:
        for wall_chance, iterations, birth in [
            (0.40, 4, 5),
            (0.45, 5, 5),
            (0.50, 5, 5),
            (0.45, 8, 4),
            (0.55, 5, 5),
        ]:
            yield self._evolve(width, height, wall_chance, iterations, birth, seed)

    def _evolve(self, cols: int, rows: int, wall_chance: float,
                iterations: int, birth: int, seed: int) -> StrategyResult:
        rng = seeded_rng(seed, f"ca:{wall_chance}:{iterations}:{birth}")
        # 1 = wall, 0 = floor while smoothing — invert to project's
        # convention at the end.
        grid = [[1 if rng.random() < wall_chance else 0
                 for _ in range(cols)] for _ in range(rows)]
        for _ in range(iterations):
            grid = self._step(grid, rows, cols, birth)
        # Flip: 0 walls → floor=1, 1 walls → wall=4. Border = wall.
        out = [[4 if grid[r][c] == 1 or r == 0 or c == 0
                or r == rows - 1 or c == cols - 1 else 1
                for c in range(cols)] for r in range(rows)]
        return StrategyResult(
            name=self.name,
            label=f"p={wall_chance:.2f} iter={iterations} b={birth}",
            heights=out,
            params={"wall_chance": wall_chance, "iterations": iterations,
                    "birth": birth, "seed": seed},
        )

    def _step(self, grid, rows, cols, birth):
        out = [[0] * cols for _ in range(rows)]
        for r in range(rows):
            for c in range(cols):
                walls = 0
                for dr in (-1, 0, 1):
                    for dc in (-1, 0, 1):
                        nr, nc = r + dr, c + dc
                        if not (0 <= nr < rows and 0 <= nc < cols):
                            walls += 1   # treat out-of-bounds as wall
                            continue
                        if dr == 0 and dc == 0: continue
                        walls += grid[nr][nc]
                out[r][c] = 1 if walls >= birth else 0
        return out
