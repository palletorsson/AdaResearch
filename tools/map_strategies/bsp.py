"""Binary space partition — recursive rectangle split, room per leaf,
corridors connecting siblings. Doom (1993) and roguelikes since."""
from __future__ import annotations

from typing import Iterator
from .base import Strategy, StrategyResult, make_grid, seeded_rng


class BSPStrategy(Strategy):
    name = "bsp"
    tier = "partition"
    description = ("Recursively split the canvas into rectangles. Each leaf "
                   "becomes a room (floor surrounded by walls). Sibling "
                   "rooms are connected by axis-aligned corridors.")

    def iter_candidates(self, width: int, height: int, seed: int) -> Iterator[StrategyResult]:
        for min_size, room_pad, walls in [
            (3, 0, False),
            (5, 1, False),
            (5, 1, True),
            (8, 2, True),
            (10, 2, True),
        ]:
            yield self._build(width, height, min_size, room_pad, walls, seed)

    def _build(self, cols: int, rows: int, min_size: int, room_pad: int,
               walls: bool, seed: int) -> StrategyResult:
        rng = seeded_rng(seed, f"bsp:{min_size}:{room_pad}:{walls}")
        grid = make_grid(rows, cols, 4 if walls else 0)
        rooms: list[tuple[int, int, int, int]] = []   # (r, c, h, w)

        def split(r: int, c: int, h: int, w: int, depth: int):
            if h <= min_size * 2 + 2 and w <= min_size * 2 + 2:
                rooms.append((r, c, h, w))
                return
            split_horiz = h > w if h != w else rng.random() < 0.5
            if split_horiz and h > min_size * 2 + 2:
                cut = rng.randint(min_size + 1, h - min_size - 1)
                split(r, c, cut, w, depth + 1)
                split(r + cut, c, h - cut, w, depth + 1)
            elif w > min_size * 2 + 2:
                cut = rng.randint(min_size + 1, w - min_size - 1)
                split(r, c, h, cut, depth + 1)
                split(r, c + cut, h, w - cut, depth + 1)
            else:
                rooms.append((r, c, h, w))

        split(0, 0, rows, cols, 0)
        # Carve each room with floor, optionally inset for room_pad.
        room_centers: list[tuple[int, int]] = []
        for (rr, cc, hh, ww) in rooms:
            r0 = rr + 1 + room_pad
            c0 = cc + 1 + room_pad
            r1 = rr + hh - 1 - room_pad
            c1 = cc + ww - 1 - room_pad
            if r1 <= r0 or c1 <= c0:
                continue
            for r in range(r0, r1):
                for c in range(c0, c1):
                    grid[r][c] = 1
            room_centers.append(((r0 + r1) // 2, (c0 + c1) // 2))
        # Connect rooms in chain order via L-shaped corridors.
        for i in range(len(room_centers) - 1):
            r0, c0 = room_centers[i]
            r1, c1 = room_centers[i + 1]
            for c in range(min(c0, c1), max(c0, c1) + 1):
                if 0 <= r0 < rows and 0 <= c < cols:
                    grid[r0][c] = 1
            for r in range(min(r0, r1), max(r0, r1) + 1):
                if 0 <= r < rows and 0 <= c1 < cols:
                    grid[r][c1] = 1
        return StrategyResult(
            name=self.name,
            label=f"min={min_size} pad={room_pad}{' walls' if walls else ''}",
            heights=grid,
            params={"min_size": min_size, "room_pad": room_pad,
                    "walls": walls, "seed": seed},
        )
