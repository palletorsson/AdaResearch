#!/usr/bin/env python3
"""
Auto-Structure Generator — build structure layers from anchor points.

Places `A` in the utilities layer to mark reachability anchors. Artifacts,
spawn, and teleporter are implicit anchors. The generator connects all
anchors with walkable floor using a chosen topology mode, fills the rest
with walls.

Usage:
  python tools/generate_structure.py --map Gallery_Randomness              # default corridor
  python tools/generate_structure.py --map Gallery_Randomness --mode room  # room zones
  python tools/generate_structure.py --map Gallery_Randomness --mode ring  # loop path
  python tools/generate_structure.py --map Gallery_Randomness --dry-run    # ASCII preview
  python tools/generate_structure.py --map Gallery_Randomness --padding 2  # wider zones
  python tools/generate_structure.py --sequence randomness                 # all maps in seq
"""

import argparse
import json
import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from lib.plan_utils import (
    ROOT,
    MAPS_DIR,
    load_json,
    parse_interactable_cell,
    scan_all_sequences,
)


# ═══════════════════════════════════════════════════════════════
# ANCHOR COLLECTION
# ═══════════════════════════════════════════════════════════════

def collect_anchors(utilities: list, interactables: list) -> dict:
    """Collect all anchor positions from utilities + interactables.

    Returns dict with keys: 'all', 'spawn', 'teleporter', 'explicit', 'artifacts'.
    Each value is a list of (row, col) tuples.
    """
    result = {
        "spawn": [],
        "teleporter": [],
        "explicit": [],
        "artifacts": [],
        "all": [],
    }
    seen = set()

    def _add(row, col, category):
        pos = (row, col)
        if pos not in seen:
            seen.add(pos)
            result[category].append(pos)
            result["all"].append(pos)

    # Scan utilities
    for row_idx, row in enumerate(utilities):
        for col_idx, cell in enumerate(row):
            if not isinstance(cell, str):
                continue
            c = cell.strip()
            if not c or c == " ":
                continue
            code = c.split(":")[0].lower()
            if code == "sp" or code == "s":
                _add(row_idx, col_idx, "spawn")
            elif code == "t":
                _add(row_idx, col_idx, "teleporter")
            elif code == "a":
                _add(row_idx, col_idx, "explicit")

    # Scan interactables — all non-empty cells are implicit anchors
    for row_idx, row in enumerate(interactables):
        for col_idx, cell in enumerate(row):
            if not isinstance(cell, str):
                continue
            c = cell.strip()
            if not c or c == " ":
                continue
            name, _ = parse_interactable_cell(c)
            if name and len(name) > 1:
                _add(row_idx, col_idx, "artifacts")

    return result


# ═══════════════════════════════════════════════════════════════
# CONNECTION ALGORITHMS
# ═══════════════════════════════════════════════════════════════

def manhattan(a, b):
    return abs(a[0] - b[0]) + abs(a[1] - b[1])


def connect_mst(anchors: list) -> list:
    """Minimum spanning tree using Prim's algorithm, Manhattan distance."""
    if len(anchors) <= 1:
        return []

    edges = []
    in_tree = {anchors[0]}
    remaining = set(range(1, len(anchors)))

    while remaining:
        best_edge = None
        best_dist = float("inf")
        best_idx = -1

        for idx in remaining:
            for tree_node in in_tree:
                d = manhattan(anchors[idx], tree_node)
                if d < best_dist:
                    best_dist = d
                    best_edge = (tree_node, anchors[idx])
                    best_idx = idx

        if best_idx >= 0:
            edges.append(best_edge)
            in_tree.add(anchors[best_idx])
            remaining.remove(best_idx)
        else:
            break

    return edges


def connect_ring(anchors: list) -> list:
    """Nearest-neighbor TSP loop visiting all anchors."""
    if len(anchors) <= 1:
        return []
    if len(anchors) == 2:
        return [(anchors[0], anchors[1])]

    # Start from first anchor (spawn if available)
    visited = [anchors[0]]
    remaining = list(anchors[1:])

    while remaining:
        current = visited[-1]
        nearest_idx = min(range(len(remaining)),
                          key=lambda i: manhattan(current, remaining[i]))
        visited.append(remaining.pop(nearest_idx))

    # Close the loop
    edges = []
    for i in range(len(visited)):
        edges.append((visited[i], visited[(i + 1) % len(visited)]))
    return edges


def connect_branch(anchors: list, spawn: tuple) -> list:
    """BFS tree from spawn to all other anchors."""
    if len(anchors) <= 1:
        return []

    # Sort anchors by distance from spawn, connect each to nearest already-connected
    others = [a for a in anchors if a != spawn]
    others.sort(key=lambda a: manhattan(spawn, a))

    edges = []
    connected = {spawn}

    for anchor in others:
        # Find nearest connected node
        nearest = min(connected, key=lambda c: manhattan(c, anchor))
        edges.append((nearest, anchor))
        connected.add(anchor)

    return edges


def connect_grid(anchors: list, rows: int, cols: int, spacing: int = 3) -> list:
    """Regular grid corridors. Anchors connect to nearest grid intersection."""
    edges = []

    # Create grid intersections
    grid_points = []
    for r in range(1, rows - 1, spacing):
        for c in range(1, cols - 1, spacing):
            grid_points.append((r, c))

    # Connect grid points in grid pattern
    for i, gp in enumerate(grid_points):
        # Right neighbor
        right = (gp[0], gp[1] + spacing)
        if right in grid_points:
            edges.append((gp, right))
        # Down neighbor
        down = (gp[0] + spacing, gp[1])
        if down in grid_points:
            edges.append((gp, down))

    # Connect each anchor to nearest grid point
    for anchor in anchors:
        if grid_points:
            nearest = min(grid_points, key=lambda g: manhattan(g, anchor))
            edges.append((anchor, nearest))

    return edges


# ═══════════════════════════════════════════════════════════════
# CARVING
# ═══════════════════════════════════════════════════════════════

def carve_corridor(grid: list, start: tuple, end: tuple, width: int = 1) -> None:
    """Carve L-shaped corridor between two points. Goes horizontal then vertical."""
    rows = len(grid)
    cols = len(grid[0])
    half = width // 2

    r1, c1 = start
    r2, c2 = end

    # Horizontal segment at r1
    c_min, c_max = min(c1, c2), max(c1, c2)
    for c in range(c_min, c_max + 1):
        for dr in range(-half, half + 1):
            rr = r1 + dr
            if 0 < rr < rows - 1 and 0 < c < cols - 1:
                grid[rr][c] = "1"

    # Vertical segment at c2
    r_min, r_max = min(r1, r2), max(r1, r2)
    for r in range(r_min, r_max + 1):
        for dc in range(-half, half + 1):
            cc = c2 + dc
            if 0 < r < rows - 1 and 0 < cc < cols - 1:
                grid[r][cc] = "1"


def carve_zone(grid: list, center: tuple, padding: int) -> None:
    """Carve rectangular floor zone around a point."""
    rows = len(grid)
    cols = len(grid[0])
    r, c = center

    for dr in range(-padding, padding + 1):
        for dc in range(-padding, padding + 1):
            rr, cc = r + dr, c + dc
            if 0 < rr < rows - 1 and 0 < cc < cols - 1:
                grid[rr][cc] = "1"


# ═══════════════════════════════════════════════════════════════
# VALIDATION
# ═══════════════════════════════════════════════════════════════

def validate_reachability(structure: list, anchors: list, spawn: tuple) -> tuple:
    """BFS flood-fill from spawn. Returns (all_reached, unreachable_anchors)."""
    rows = len(structure)
    cols = len(structure[0]) if structure else 0
    if rows == 0 or cols == 0:
        return False, anchors

    visited = set()
    queue = deque([spawn])
    visited.add(spawn)

    while queue:
        r, c = queue.popleft()
        for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nr, nc = r + dr, c + dc
            if 0 <= nr < rows and 0 <= nc < cols and (nr, nc) not in visited:
                h = int(structure[nr][nc]) if structure[nr][nc].isdigit() else 0
                if h > 0:  # walkable
                    visited.add((nr, nc))
                    queue.append((nr, nc))

    # Check which anchors are reachable (anchor or adjacent cell)
    unreachable = []
    for anchor in anchors:
        r, c = anchor
        reachable = False
        # Check anchor cell and its 4 neighbors
        for dr, dc in [(0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)]:
            nr, nc = r + dr, c + dc
            if (nr, nc) in visited:
                reachable = True
                break
        if not reachable:
            unreachable.append(anchor)

    return len(unreachable) == 0, unreachable


# ═══════════════════════════════════════════════════════════════
# MAIN GENERATOR
# ═══════════════════════════════════════════════════════════════

def generate_structure(
    map_data: dict,
    mode: str = "corridor",
    padding: int = 1,
    wall_height: int = 2,
    corridor_width: int = 2,
    preserve_existing: bool = True,
) -> list:
    """Main pipeline: collect anchors → connect → carve → border → validate."""

    layers = map_data.get("layers", {})
    utilities = layers.get("utilities", [])
    interactables = layers.get("interactables", [])
    existing_structure = layers.get("structure", [])

    # Get dimensions
    dims = map_data.get("map_info", {}).get("dimensions", {})
    grid_rows = dims.get("depth", len(utilities))
    grid_cols = dims.get("width", len(utilities[0]) if utilities else 11)

    # Also check spacer config in map_data
    spacer = map_data.get("spacer", {})
    if not mode and spacer:
        mode = spacer.get("mode", "corridor")
    if spacer:
        padding = spacer.get("padding", padding)
        wall_height = spacer.get("wall_height", wall_height)
        corridor_width = spacer.get("corridor_width", corridor_width)

    mode = mode or "corridor"

    # Initialize grid with walls
    grid = []
    for r in range(grid_rows):
        row = []
        for c in range(grid_cols):
            # Preserve existing non-zero structure
            if preserve_existing and r < len(existing_structure) and c < len(existing_structure[r]):
                existing_val = str(existing_structure[r][c]).strip()
                if existing_val.isdigit() and int(existing_val) > 0:
                    row.append(existing_val)
                    continue
            row.append(str(wall_height))
        grid.append(row)

    # Collect anchors
    anchor_data = collect_anchors(utilities, interactables)
    all_anchors = anchor_data["all"]

    if not all_anchors:
        print("  No anchors found — returning wall grid")
        return grid

    # Find spawn position (first spawn, or first anchor)
    spawn = anchor_data["spawn"][0] if anchor_data["spawn"] else all_anchors[0]

    # Connect anchors based on mode
    if mode == "open":
        # Everything is floor except border
        for r in range(1, grid_rows - 1):
            for c in range(1, grid_cols - 1):
                grid[r][c] = "1"
    else:
        # Get edges from connection algorithm
        if mode == "ring":
            edges = connect_ring(all_anchors)
        elif mode == "branch":
            edges = connect_branch(all_anchors, spawn)
        elif mode == "grid":
            edges = connect_grid(all_anchors, grid_rows, grid_cols)
        else:  # corridor, room
            edges = connect_mst(all_anchors)

        # Carve anchor zones
        zone_padding = padding if mode == "room" else max(0, padding - 1)
        for anchor in all_anchors:
            carve_zone(grid, anchor, zone_padding)

        # If room mode, give bigger zones
        if mode == "room":
            for anchor in all_anchors:
                carve_zone(grid, anchor, padding + 1)

        # Carve corridors along edges
        for start, end in edges:
            carve_corridor(grid, start, end, corridor_width)

    # Ensure border walls
    for r in range(grid_rows):
        grid[r][0] = str(wall_height)
        if grid_cols > 1:
            grid[r][grid_cols - 1] = str(wall_height)
    for c in range(grid_cols):
        grid[0][c] = str(wall_height)
        if grid_rows > 1:
            grid[grid_rows - 1][c] = str(wall_height)

    # Teleporter cells must be void (height 0)
    for t_pos in anchor_data["teleporter"]:
        r, c = t_pos
        if 0 <= r < grid_rows and 0 <= c < grid_cols:
            grid[r][c] = "0"

    # Spawn cell must be walkable
    sr, sc = spawn
    if 0 < sr < grid_rows - 1 and 0 < sc < grid_cols - 1:
        grid[sr][sc] = "1"

    # Validate reachability
    ok, unreachable = validate_reachability(grid, all_anchors, spawn)
    if not ok:
        print(f"  WARNING: {len(unreachable)} unreachable anchors, adding emergency corridors")
        for unr in unreachable:
            carve_corridor(grid, spawn, unr, corridor_width)
            carve_zone(grid, unr, 1)
        # Re-validate
        ok2, still_bad = validate_reachability(grid, all_anchors, spawn)
        if not ok2:
            print(f"  ERROR: Still {len(still_bad)} unreachable after emergency corridors")

    return grid


def ascii_preview(grid: list) -> str:
    """Render structure grid as ASCII art."""
    chars = {"0": ".", "1": " ", "2": "#", "3": "#", "4": "#", "5": "#"}
    lines = []
    for row in grid:
        line = ""
        for cell in row:
            c = str(cell).strip()
            line += chars.get(c, c)
        lines.append(line)
    return "\n".join(lines)


# ═══════════════════════════════════════════════════════════════
# CLI
# ═══════════════════════════════════════════════════════════════

def main():
    parser = argparse.ArgumentParser(description="Generate structure layer from anchors")
    parser.add_argument("--map", help="Single map name")
    parser.add_argument("--sequence", help="All maps in a sequence")
    parser.add_argument("--mode", default="corridor",
                        choices=["corridor", "room", "branch", "ring", "grid", "open"],
                        help="Topology mode (default: corridor)")
    parser.add_argument("--padding", type=int, default=1, help="Floor padding around anchors")
    parser.add_argument("--wall-height", type=int, default=2, help="Wall height (default: 2)")
    parser.add_argument("--corridor-width", type=int, default=2, help="Corridor width (default: 2)")
    parser.add_argument("--dry-run", action="store_true", help="ASCII preview, don't write")
    parser.add_argument("--no-preserve", action="store_true", help="Ignore existing structure")
    args = parser.parse_args()

    # Collect target maps
    targets = []
    if args.map:
        targets = [args.map]
    elif args.sequence:
        sequences = scan_all_sequences()
        for sid, seq in sequences.items():
            if sid.lower() == args.sequence.lower():
                for m in seq.get("maps", []):
                    name = m if isinstance(m, str) else m.get("name", "")
                    if name:
                        targets.append(name)
                break
        if not targets:
            print(f"Sequence '{args.sequence}' not found or has no maps")
            return
    else:
        print("Specify --map or --sequence")
        return

    generated = 0
    for map_name in targets:
        map_dir = MAPS_DIR / map_name
        map_file = map_dir / "map_data.json"

        if not map_file.is_file():
            print(f"  SKIP: {map_name} — no map_data.json")
            continue

        map_data = load_json(map_file)
        if not map_data:
            print(f"  SKIP: {map_name} — failed to parse")
            continue

        print(f"\n{'='*50}")
        print(f"Generating structure for: {map_name}")
        print(f"Mode: {args.mode} | Padding: {args.padding} | Corridor: {args.corridor_width}")

        structure = generate_structure(
            map_data,
            mode=args.mode,
            padding=args.padding,
            wall_height=args.wall_height,
            corridor_width=args.corridor_width,
            preserve_existing=not args.no_preserve,
        )

        # Count anchors for reporting
        layers = map_data.get("layers", {})
        anchor_data = collect_anchors(
            layers.get("utilities", []),
            layers.get("interactables", [])
        )
        print(f"Anchors: {len(anchor_data['all'])} "
              f"(spawn:{len(anchor_data['spawn'])} "
              f"teleporter:{len(anchor_data['teleporter'])} "
              f"explicit:{len(anchor_data['explicit'])} "
              f"artifacts:{len(anchor_data['artifacts'])})")

        # Count floor vs wall
        floor_count = sum(1 for r in structure for c in r if c == "1")
        wall_count = sum(1 for r in structure for c in r if int(c) >= 2 if c.isdigit())
        total = len(structure) * (len(structure[0]) if structure else 0)
        print(f"Grid: {len(structure)}x{len(structure[0]) if structure else 0} "
              f"({floor_count} floor, {wall_count} wall, {total - floor_count - wall_count} void)")

        if args.dry_run:
            print(f"\nASCII Preview:")
            print(ascii_preview(structure))
        else:
            # Write back
            map_data["layers"]["structure"] = structure
            with open(map_file, "w", encoding="utf-8") as f:
                json.dump(map_data, f, indent=2, ensure_ascii=False)
            print(f"  Written: {map_file}")
            generated += 1

    if not args.dry_run:
        print(f"\nDone. Generated: {generated}")


if __name__ == "__main__":
    main()
