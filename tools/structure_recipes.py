"""
structure_recipes.py -- parameterized 16x8 corridor shape generators.

Each recipe is a function (params_dict) -> structure_array, where
structure_array is a list of 16 rows, each row a list of 8 cell values.
Cell values are strings:
    ""  = void (no floor, no collision, walkable only if bridged)
    "0" = void/pit (explicit hole)
    "1" = floor at height 1
    "2" = floor at height 2 (raised platform)
    "3" = floor at height 3 (high platform, often ceiling piece)
    ...up to max_height from map_info.

Recipes can be composed via union()/subtract() to build complex shapes:
    base = recipe("flat_corridor")
    with_pit = subtract(base, recipe("pit", {"row": 9, "size": 2}))
    with_plat = union(with_pit, recipe("platform", {"row": 9, "height": 2}))
"""
from __future__ import annotations

from typing import Callable

FRAME_ROWS = 16
FRAME_COLS = 8


def _blank(height: str = "") -> list[list[str]]:
    return [[height for _ in range(FRAME_COLS)] for _ in range(FRAME_ROWS)]


# ─── Base recipes ─────────────────────────────────────────────────────────

def flat_corridor(params: dict | None = None) -> list[list[str]]:
    """Full 16x8 floor at height 1. The default."""
    return _blank("1")


def narrow_corridor(params: dict | None = None) -> list[list[str]]:
    """Only middle 4 cols walkable, side cols void -- claustrophobic path."""
    params = params or {}
    width = int(params.get("width", 4))
    margin = (FRAME_COLS - width) // 2
    grid = _blank("")
    for r in range(FRAME_ROWS):
        for c in range(margin, margin + width):
            grid[r][c] = "1"
    return grid


def platform_over_pit(params: dict | None = None) -> list[list[str]]:
    """A pit in the middle, with a raised platform bridging it.
    params: pit_center_row (default 9), pit_size (default 4),
            pit_cols (default [2,3,4,5]), platform_height (default 2)."""
    params = params or {}
    grid = flat_corridor()
    pit_row = int(params.get("pit_center_row", 9))
    pit_size = int(params.get("pit_size", 4))
    pit_cols = params.get("pit_cols", [2, 3, 4, 5])
    plat_height = int(params.get("platform_height", 2))
    half = pit_size // 2
    for r in range(pit_row - half, pit_row + half):
        for c in pit_cols:
            if 0 <= r < FRAME_ROWS and 0 <= c < FRAME_COLS:
                grid[r][c] = "0"  # pit
    # Platform over center of pit
    pcol_start = pit_cols[0] + 1
    pcol_end = pit_cols[-1]
    for c in range(pcol_start, pcol_end):
        if 0 <= pit_row < FRAME_ROWS:
            grid[pit_row][c] = str(plat_height)
    return grid


def stepped_descent(params: dict | None = None) -> list[list[str]]:
    """Staircase descending from row 0 (high) to row 15 (low).
    params: start_height (default 4), end_height (default 1)."""
    params = params or {}
    start_h = int(params.get("start_height", 4))
    end_h = int(params.get("end_height", 1))
    grid = _blank("")
    for r in range(FRAME_ROWS):
        t = r / max(1, FRAME_ROWS - 1)
        h = round(start_h + (end_h - start_h) * t)
        h = max(1, h)
        for c in range(FRAME_COLS):
            grid[r][c] = str(h)
    return grid


def amphitheater(params: dict | None = None) -> list[list[str]]:
    """Flat with a bowl depression around row `center_row`.
    params: center_row (default 9), radius (default 3), depth (default 2)."""
    params = params or {}
    grid = flat_corridor()
    cr = int(params.get("center_row", 9))
    cc = FRAME_COLS / 2.0 - 0.5
    radius = float(params.get("radius", 3.0))
    depth = int(params.get("depth", 2))
    for r in range(FRAME_ROWS):
        for c in range(FRAME_COLS):
            d = ((r - cr) ** 2 + (c - cc) ** 2) ** 0.5
            if d <= radius:
                # lower by depth, but stay >= 1 so we don't fall through
                h = max(1, 1 - depth)
                # Actually for a bowl we want the edge high, center low
                # Using ring thickness:
                t = d / radius
                step = round(1 + (1 - t) * (depth - 1))
                # Invert: center is lowest. Use height 1 floor but raise surrounding
                if d < radius * 0.4:
                    grid[r][c] = "1"   # center
                else:
                    grid[r][c] = str(1 + max(0, int(round((1 - t) * depth))))
    return grid


def split_level(params: dict | None = None) -> list[list[str]]:
    """South half at height 1, north half at height 2, connected by a step.
    params: split_row (default 8), upper_height (default 2)."""
    params = params or {}
    grid = _blank("")
    split = int(params.get("split_row", 8))
    upper = int(params.get("upper_height", 2))
    for r in range(FRAME_ROWS):
        h = "1" if r < split else str(upper)
        for c in range(FRAME_COLS):
            grid[r][c] = h
    return grid


def island_chain(params: dict | None = None) -> list[list[str]]:
    """Discrete square islands along the centerline, floating over void.
    params: count (default 4), island_size (default 3)."""
    params = params or {}
    count = int(params.get("count", 4))
    size = int(params.get("island_size", 3))
    grid = _blank("")
    spacing = FRAME_ROWS / count
    half = size // 2
    c_mid = FRAME_COLS // 2
    for i in range(count):
        cr = int((i + 0.5) * spacing)
        for r in range(cr - half, cr - half + size):
            for c in range(c_mid - half, c_mid - half + size):
                if 0 <= r < FRAME_ROWS and 0 <= c < FRAME_COLS:
                    grid[r][c] = "1"
    # Spawn and teleport cells must be reachable — force floor there
    grid[1][3] = "1"
    grid[15][3] = "1"
    return grid


# ─── Composition ──────────────────────────────────────────────────────────

def union(a: list[list[str]], b: list[list[str]]) -> list[list[str]]:
    """For each cell, take the NON-EMPTY one (b wins if both set)."""
    out = _blank("")
    for r in range(FRAME_ROWS):
        for c in range(FRAME_COLS):
            av = a[r][c] if r < len(a) and c < len(a[r]) else ""
            bv = b[r][c] if r < len(b) and c < len(b[r]) else ""
            out[r][c] = bv if bv else av
    return out


def subtract(a: list[list[str]], b: list[list[str]]) -> list[list[str]]:
    """Wherever b has '0' (pit marker), force a to '0' too."""
    out = [row[:] for row in a]
    for r in range(FRAME_ROWS):
        for c in range(FRAME_COLS):
            if b[r][c] == "0":
                out[r][c] = "0"
    return out


def guarantee_walkable(grid: list[list[str]], cells: list[tuple[int, int]]) -> list[list[str]]:
    """Force specified cells to have floor at height 1. Used to ensure
    spawn + teleport cells are always reachable regardless of the recipe."""
    out = [row[:] for row in grid]
    for (r, c) in cells:
        if 0 <= r < FRAME_ROWS and 0 <= c < FRAME_COLS:
            if not out[r][c] or out[r][c] == "0":
                out[r][c] = "1"
    return out


# ─── Registry ─────────────────────────────────────────────────────────────

RECIPES: dict[str, Callable[[dict | None], list[list[str]]]] = {
    "flat_corridor":     flat_corridor,
    "narrow_corridor":   narrow_corridor,
    "platform_over_pit": platform_over_pit,
    "stepped_descent":   stepped_descent,
    "amphitheater":      amphitheater,
    "split_level":       split_level,
    "island_chain":      island_chain,
}


def build_structure(recipe_name: str, params: dict | None = None) -> list[list[str]]:
    """Main entry point. Returns a structure grid by name."""
    if recipe_name not in RECIPES:
        print(f"structure_recipes: unknown recipe '{recipe_name}', falling back to flat_corridor")
        return flat_corridor()
    return RECIPES[recipe_name](params)


def list_recipes() -> list[str]:
    return list(RECIPES.keys())


if __name__ == "__main__":
    # Debug dump of each recipe as ASCII
    import sys
    name = sys.argv[1] if len(sys.argv) > 1 else None
    if name:
        names = [name]
    else:
        names = list_recipes()
    for n in names:
        print(f"\n=== {n} ===")
        grid = build_structure(n)
        for r, row in enumerate(grid):
            line = f"r{r:>2} "
            for c in row:
                line += (c if c else "·") + " "
            print(line)
