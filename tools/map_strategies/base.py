"""Map-strategy base class.

A strategy generates a 2D height grid (the structure layer). Heights are
ints 0..5 matching the project's existing convention:
  0 = void
  1 = floor (walkable)
  2 = step / low plinth
  3 = plinth top
  4 = wall (tall)
  5 = wall (taller)

Each strategy is a Python file under tools/map_strategies/. The runner
discovers all subclasses of `Strategy`, sweeps their parameter space,
and outputs PNG previews + (optionally) map_data.json files.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Iterator
import random


@dataclass
class StrategyResult:
    """One generated grid + the parameters that made it."""
    name: str                      # strategy identifier (e.g. "bsp")
    label: str                     # short human label for this candidate
    heights: list[list[int]]       # rows × cols, ints 0..5
    params: dict                   # the parameter set used
    metrics: dict = field(default_factory=dict)   # filled in by runner


class Strategy:
    """Subclass and implement `iter_candidates`. Keep candidates between
    6 and 12 — the gallery becomes unreadable above that. Use parameter
    sweeps that genuinely change the look (don't tweak +/- 0.1)."""
    name: str = "unnamed"
    tier: str = "unspecified"
    description: str = ""

    def iter_candidates(self, width: int, height: int, seed: int) -> Iterator[StrategyResult]:
        raise NotImplementedError


# ── Helpers used by multiple strategies ───────────────────────────────

def make_grid(rows: int, cols: int, fill: int = 0) -> list[list[int]]:
    return [[fill for _ in range(cols)] for _ in range(rows)]


def in_bounds(r: int, c: int, rows: int, cols: int) -> bool:
    return 0 <= r < rows and 0 <= c < cols


def neighbours4(r: int, c: int):
    yield r - 1, c
    yield r + 1, c
    yield r, c - 1
    yield r, c + 1


def count_walkable(grid: list[list[int]]) -> int:
    return sum(1 for row in grid for v in row if v >= 1)


def largest_component_size(grid: list[list[int]]) -> int:
    """Size of the biggest 4-connected walkable region (h >= 1)."""
    rows = len(grid)
    cols = max((len(r) for r in grid), default=0)
    seen = [[False] * cols for _ in range(rows)]
    best = 0
    for r0 in range(rows):
        for c0 in range(cols):
            if seen[r0][c0] or grid[r0][c0] < 1:
                continue
            stack = [(r0, c0)]
            seen[r0][c0] = True
            count = 0
            while stack:
                r, c = stack.pop()
                count += 1
                for nr, nc in neighbours4(r, c):
                    if (in_bounds(nr, nc, rows, cols)
                            and not seen[nr][nc] and grid[nr][nc] >= 1):
                        seen[nr][nc] = True
                        stack.append((nr, nc))
            if count > best:
                best = count
    return best


def seeded_rng(base_seed: int, key: str) -> random.Random:
    """Deterministic per-candidate RNG: same (seed, key) → same map."""
    return random.Random((base_seed, key).__hash__() & 0xFFFF_FFFF)
