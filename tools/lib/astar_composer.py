"""
astar_composer.py — A* pathfinding as spatial composition.

Artifacts are force fields on a cost grid. A* finds the path from spawn
to teleporter through overlapping artifact gravities. The path IS the map.
Temperature controls determinism: T=0 is pure A*, T=1 is stochastic wandering.

Each boundary type produces a different force field shape:
  arrival     = attractor (low cost, pulls path toward artifact)
  departure   = directional push (low cost behind, high ahead)
  preparation = forward funnel (low cost in approach direction)
  continuation = neutral (no gravity modification)
  rest        = repeller on main path (high cost, creates dead-end branch)

Usage:
  from lib.astar_composer import compose_astar_map
"""

import math
import random
from typing import Optional
import heapq


# ═══════════════════════════════════════════════════════════════
# FORCE FIELDS — artifact gravity shapes
# ═══════════════════════════════════════════════════════════════

def apply_attractor(cost_grid: list, cr: int, cc: int, radius: int = 4, strength: float = 0.3):
    """Arrival: low cost near artifact — path curves toward it."""
    rows, cols = len(cost_grid), len(cost_grid[0])
    for r in range(max(0, cr - radius), min(rows, cr + radius + 1)):
        for c in range(max(0, cc - radius), min(cols, cc + radius + 1)):
            dist = math.sqrt((r - cr) ** 2 + (c - cc) ** 2)
            if dist <= radius:
                # Cost decreases near artifact (normalized 0-1)
                factor = 1.0 - strength * (1.0 - dist / radius)
                cost_grid[r][c] *= max(0.1, factor)


def apply_repeller(cost_grid: list, cr: int, cc: int, radius: int = 3, strength: float = 3.0):
    """Rest: high cost near artifact — main path avoids it, creating dead-end branch."""
    rows, cols = len(cost_grid), len(cost_grid[0])
    for r in range(max(0, cr - radius), min(rows, cr + radius + 1)):
        for c in range(max(0, cc - radius), min(cols, cc + radius + 1)):
            dist = math.sqrt((r - cr) ** 2 + (c - cc) ** 2)
            if 0 < dist <= radius:  # don't modify the artifact cell itself
                factor = 1.0 + strength * (1.0 - dist / radius)
                cost_grid[r][c] *= factor


def apply_funnel(cost_grid: list, cr: int, cc: int, direction: tuple,
                 length: int = 5, width: int = 2, strength: float = 0.4):
    """Preparation: low cost in approach direction — pulls path forward."""
    rows, cols = len(cost_grid), len(cost_grid[0])
    dr, dc = direction
    for step in range(1, length + 1):
        nr = cr + dr * step
        nc = cc + dc * step
        for dw in range(-width, width + 1):
            wr = nr + (0 if dr != 0 else dw)
            wc = nc + (dw if dr != 0 else 0)
            if 0 <= wr < rows and 0 <= wc < cols:
                decay = 1.0 - strength * (1.0 - step / length)
                cost_grid[wr][wc] *= max(0.2, decay)


def apply_directional_push(cost_grid: list, cr: int, cc: int, direction: tuple,
                           radius: int = 3, strength: float = 2.0):
    """Departure: high cost behind (where you came from), low ahead."""
    rows, cols = len(cost_grid), len(cost_grid[0])
    dr, dc = direction
    for r in range(max(0, cr - radius), min(rows, cr + radius + 1)):
        for c in range(max(0, cc - radius), min(cols, cc + radius + 1)):
            dist = math.sqrt((r - cr) ** 2 + (c - cc) ** 2)
            if dist <= radius and dist > 0:
                # Dot product with direction: positive = ahead, negative = behind
                dot = (r - cr) * dr + (c - cc) * dc
                if dot < 0:  # behind — increase cost (push away)
                    cost_grid[r][c] *= 1.0 + strength * (1.0 - dist / radius)
                else:  # ahead — decrease cost (pull forward)
                    cost_grid[r][c] *= max(0.2, 1.0 - 0.3 * (1.0 - dist / radius))


# ═══════════════════════════════════════════════════════════════
# STOCHASTIC A* — temperature-controlled pathfinding
# ═══════════════════════════════════════════════════════════════

def heuristic(a: tuple, b: tuple) -> float:
    """Manhattan distance heuristic."""
    return abs(a[0] - b[0]) + abs(a[1] - b[1])


def astar_stochastic(cost_grid: list, start: tuple, goal: tuple,
                     temperature: float = 0.0, rng: random.Random = None) -> list:
    """A* with temperature-controlled exploration.

    T=0.0: pure A* (deterministic, optimal path)
    T=0.5: warm (slight wandering, structured exploration)
    T=1.0: hot (significant wandering, organic paths)
    T>1.0: very hot (near-random walk biased toward goal)

    Returns list of (row, col) positions along the path.
    """
    if rng is None:
        rng = random.Random()

    rows = len(cost_grid)
    cols = len(cost_grid[0]) if cost_grid else 0

    # Priority queue: (f_score, counter, position)
    counter = 0
    open_set = [(0, counter, start)]
    came_from = {}
    g_score = {start: 0.0}
    f_score = {start: heuristic(start, goal)}

    DIRS = [(-1, 0), (1, 0), (0, -1), (0, 1)]

    while open_set:
        _, _, current = heapq.heappop(open_set)

        if current == goal:
            # Reconstruct path
            path = [current]
            while current in came_from:
                current = came_from[current]
                path.append(current)
            path.reverse()
            return path

        for dr, dc in DIRS:
            nr, nc = current[0] + dr, current[1] + dc
            if not (0 <= nr < rows and 0 <= nc < cols):
                continue

            neighbor = (nr, nc)
            move_cost = cost_grid[nr][nc]

            # Temperature noise: add random perturbation to cost
            if temperature > 0:
                noise = rng.gauss(0, temperature * move_cost * 0.5)
                move_cost = max(0.01, move_cost + noise)

            tentative_g = g_score.get(current, float("inf")) + move_cost

            if tentative_g < g_score.get(neighbor, float("inf")):
                came_from[neighbor] = current
                g_score[neighbor] = tentative_g
                f = tentative_g + heuristic(neighbor, goal)
                f_score[neighbor] = f
                counter += 1
                heapq.heappush(open_set, (f, counter, neighbor))

    # No path found — return direct line
    return [start, goal]


# ═══════════════════════════════════════════════════════════════
# MULTI-PATH: visit all artifacts via waypoint A*
# ═══════════════════════════════════════════════════════════════

def find_ordered_path(cost_grid: list, waypoints: list,
                      temperature: float = 0.0, seed: int = -1) -> list:
    """Find a path visiting all waypoints in order.

    waypoints: [(row, col), ...] — first is spawn, last is teleporter
    Returns complete path as list of (row, col).
    """
    rng = random.Random(seed if seed >= 0 else None)

    full_path = []
    for i in range(len(waypoints) - 1):
        segment = astar_stochastic(cost_grid, waypoints[i], waypoints[i + 1],
                                   temperature=temperature, rng=rng)
        if i > 0 and segment:
            segment = segment[1:]  # skip duplicate waypoint
        full_path.extend(segment)

    return full_path


# ═══════════════════════════════════════════════════════════════
# COMPOSER: artifacts + grammar + temperature → map
# ═══════════════════════════════════════════════════════════════

def compose_astar_map(
    sections: list,
    grid_width: int = 15,
    grid_depth: int = 15,
    wall_height: int = 2,
    temperature: float = 0.3,
    seed: int = -1,
    gutter: int = 1,
) -> dict:
    """Compose a map using A* through artifact force fields.

    1. Place artifacts on the grid (gravity packing)
    2. Build cost grid from artifact force fields
    3. A* from spawn to teleporter through all artifacts
    4. The path IS the floor — everything else is wall

    Returns same structure as spatial_grammar generators.
    """
    from lib.spatial_grammar import BOUNDARIES

    # Collect artifact sections
    artifact_secs = [s for s in sections if s.get("artifact")]
    if not artifact_secs:
        grid = [[str(wall_height)] * grid_width for _ in range(grid_depth)]
        return {"structure": grid, "artifact_positions": [], "spawn": (1, 1),
                "teleporter": (grid_depth - 2, grid_width - 2),
                "grid_depth": grid_depth, "grid_width": grid_width, "sections": sections}

    rng = random.Random(seed if seed >= 0 else None)

    # ── Place artifacts on grid ────────────────────────────────
    # Simple packing: spread across the grid with some randomness
    n = len(artifact_secs)
    positions = []

    # Reserve spawn at top-center and teleporter at bottom-center
    spawn = (1, grid_width // 2)
    teleporter = (grid_depth - 2, grid_width // 2)

    # Distribute artifacts across the grid interior
    margin = 3
    available_r = grid_depth - 2 * margin
    available_c = grid_width - 2 * margin

    for i, sec in enumerate(artifact_secs):
        # Distribute evenly with slight randomness
        t = (i + 0.5) / n  # 0 to 1 progress
        base_r = margin + int(t * available_r)
        base_c = margin + int((i % 3 - 1) * (available_c / 3))
        base_c = max(margin, min(grid_width - margin - 1, base_c))

        # Add temperature-controlled jitter
        if temperature > 0:
            base_r += int(rng.gauss(0, temperature * 2))
            base_c += int(rng.gauss(0, temperature * 2))

        base_r = max(margin, min(grid_depth - margin - 1, base_r))
        base_c = max(margin, min(grid_width - margin - 1, base_c))

        positions.append((base_r, base_c))

    # ── Build cost grid ────────────────────────────────────────
    # Start with uniform cost
    cost_grid = [[1.0] * grid_width for _ in range(grid_depth)]

    # Apply force fields based on boundary types
    for i, sec in enumerate(artifact_secs):
        r, c = positions[i]
        boundary = sec.get("boundary", "continuation")

        if boundary == "arrival":
            apply_attractor(cost_grid, r, c, radius=5, strength=0.5)
        elif boundary == "rest":
            apply_repeller(cost_grid, r, c, radius=3, strength=3.0)
            # But make the artifact cell itself reachable
            cost_grid[r][c] = 0.3
        elif boundary == "preparation":
            # Funnel pointing from previous position toward this one
            if i > 0:
                pr, pc = positions[i - 1]
                dr = 1 if r > pr else (-1 if r < pr else 0)
                dc = 1 if c > pc else (-1 if c < pc else 0)
                if dr == 0 and dc == 0:
                    dr = 1
                apply_funnel(cost_grid, r, c, (-dr, -dc), length=4, strength=0.4)
        elif boundary == "departure":
            # Push away from previous direction
            if i > 0:
                pr, pc = positions[i - 1]
                dr = 1 if r > pr else (-1 if r < pr else 0)
                dc = 1 if c > pc else (-1 if c < pc else 0)
                if dr == 0 and dc == 0:
                    dr = 1
                apply_directional_push(cost_grid, r, c, (dr, dc), radius=3)
        # continuation: no force field modification

    # Make border very expensive (keeps path interior)
    for r in range(grid_depth):
        cost_grid[r][0] = 999.0
        cost_grid[r][grid_width - 1] = 999.0
    for c in range(grid_width):
        cost_grid[0][c] = 999.0
        cost_grid[grid_depth - 1][c] = 999.0

    # ── Build waypoint order ───────────────────────────────────
    # Spawn → artifacts in section order → teleporter
    waypoints = [spawn] + positions + [teleporter]

    # ── Run stochastic A* ──────────────────────────────────────
    path = find_ordered_path(cost_grid, waypoints, temperature=temperature, seed=seed)

    # ── Carve the path into structure ──────────────────────────
    grid = [[str(wall_height)] * grid_width for _ in range(grid_depth)]

    # The path becomes floor
    path_set = set(path)
    for r, c in path:
        if 0 < r < grid_depth - 1 and 0 < c < grid_width - 1:
            grid[r][c] = "1"

    # Add gutter around path (so you don't walk pressed against walls)
    if gutter > 0:
        gutter_cells = set()
        for r, c in path_set:
            for dr in range(-gutter, gutter + 1):
                for dc in range(-gutter, gutter + 1):
                    nr, nc = r + dr, c + dc
                    if 0 < nr < grid_depth - 1 and 0 < nc < grid_width - 1:
                        gutter_cells.add((nr, nc))
        for r, c in gutter_cells:
            grid[r][c] = "1"

    # Carve artifact niches (ensure each artifact has floor + gutter)
    artifact_positions = []
    for i, sec in enumerate(artifact_secs):
        r, c = positions[i]
        if sec.get("artifact"):
            artifact_positions.append((r, c, sec["artifact"]))
        niche_size = 2 if sec.get("boundary") == "arrival" else 1
        for dr in range(-niche_size, niche_size + 1):
            for dc in range(-niche_size, niche_size + 1):
                nr, nc = r + dr, c + dc
                if 0 < nr < grid_depth - 1 and 0 < nc < grid_width - 1:
                    grid[nr][nc] = "1"

    # Rest artifacts: carve a dead-end branch from nearest path cell
    for i, sec in enumerate(artifact_secs):
        if sec.get("boundary") == "rest":
            r, c = positions[i]
            # Find nearest path cell
            nearest = min(path_set, key=lambda p: abs(p[0] - r) + abs(p[1] - c))
            # Carve 1-wide passage from path to rest artifact
            cr, cc = nearest
            while (cr, cc) != (r, c):
                if 0 < cr < grid_depth - 1 and 0 < cc < grid_width - 1:
                    grid[cr][cc] = "1"
                if cr < r: cr += 1
                elif cr > r: cr -= 1
                elif cc < c: cc += 1
                elif cc > c: cc -= 1

    # Teleporter on void
    grid[teleporter[0]][teleporter[1]] = "0"

    # Spawn floor
    grid[spawn[0]][spawn[1]] = "1"

    # Border walls
    for r in range(grid_depth):
        grid[r][0] = str(wall_height)
        grid[r][grid_width - 1] = str(wall_height)
    for c in range(grid_width):
        grid[0][c] = str(wall_height)
        grid[grid_depth - 1][c] = str(wall_height)

    return {
        "structure": grid,
        "artifact_positions": artifact_positions,
        "spawn": spawn,
        "teleporter": teleporter,
        "grid_depth": grid_depth,
        "grid_width": grid_width,
        "sections": sections,
        "path_length": len(path),
        "cost_grid": cost_grid,  # for visualization
        "temperature": temperature,
    }


def ascii_preview_astar(result: dict) -> str:
    """Render A* composed structure with cost overlay."""
    grid = result["structure"]
    artifacts = {(r, c): n for r, c, n in result["artifact_positions"]}
    spawn = result["spawn"]
    teleporter = result["teleporter"]

    chars = {"0": ".", "1": " ", "2": "#", "3": "#"}
    lines = []
    for r, row in enumerate(grid):
        line = ""
        for c, cell in enumerate(row):
            pos = (r, c)
            if pos == spawn:
                line += "S"
            elif pos == teleporter:
                line += "T"
            elif pos in artifacts:
                line += "*"
            else:
                line += chars.get(str(cell), str(cell))
        for (ar, ac), name in artifacts.items():
            if ar == r:
                line += f"  <- {name}"
                break
        lines.append(line)
    return "\n".join(lines)
