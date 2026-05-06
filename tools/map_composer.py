#!/usr/bin/env python
"""map_composer.py — assemble a candidate map from a list of artifacts +
their dressing rooms.

Pulls each artifact's dressing-room JSON, picks a placement + rotation
along the spawn→teleport line, A*-routes the path between rooms, bakes
the structure / utilities / interactables layers into a candidate
map_data.json. Writes to a `_proposed/` sibling directory by default so
originals stay untouched until accepted.

Usage:
  python tools/map_composer.py \\
      --name Test_Composer --width 14 --depth 12 \\
      --spawn 1,1 --teleport 12,7 \\
      --artifacts russell_set_box,qfep_formula_3d,lambda_slider \\
      --out commons/maps/Test_Composer/_proposed/map_data.json

  python tools/map_composer.py --target Joints_Kinematics \\
      --artifacts PendulumPin,GimbalStabilizer

Default output path:
  commons/maps/<name>/_proposed/map_data.json
"""
from __future__ import annotations

import argparse
import heapq
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DRESSING_ROOMS_DIR = REPO / "commons" / "artifacts" / "dressing_rooms"
MAPS_DIR = REPO / "commons" / "maps"

DIR_DELTAS = {
    "north": (-1, 0),
    "south": (1, 0),
    "east":  (0, 1),
    "west":  (0, -1),
}
ROTATION_OF_DIR = {
    "north": 0, "east": 90, "south": 180, "west": 270,
}
DIR_OF_ROTATION = {v: k for k, v in ROTATION_OF_DIR.items()}


def rotate_dir(d: str, rot: int) -> str:
    """Rotate a cardinal direction by `rot` degrees clockwise."""
    base = ROTATION_OF_DIR.get(d, 0)
    return DIR_OF_ROTATION[(base + rot) % 360]


def rotate_offset(off: tuple[int, int, int], rot: int) -> tuple[int, int, int]:
    """Rotate (dr, dc, dh) clockwise looking down. dh unchanged."""
    dr, dc, dh = off
    if rot % 360 == 0:
        return (dr, dc, dh)
    if rot % 360 == 90:
        return (dc, -dr, dh)
    if rot % 360 == 180:
        return (-dr, -dc, dh)
    if rot % 360 == 270:
        return (-dc, dr, dh)
    return (dr, dc, dh)


def rotate_tiles(tiles: list[list[int]], rot: int) -> list[list[int]]:
    """Rotate a 2D tile grid clockwise."""
    rot = rot % 360
    if rot == 0:
        return [list(row) for row in tiles]
    if rot == 90:
        # Clockwise 90: new[r][c] = old[len-1-c][r]
        rows = len(tiles)
        cols = max(len(r) for r in tiles) if tiles else 0
        out = [[tiles[rows - 1 - c][r] if r < len(tiles[rows - 1 - c]) else 0
                for c in range(rows)] for r in range(cols)]
        return out
    if rot == 180:
        return [list(reversed(row)) for row in reversed(tiles)]
    if rot == 270:
        return rotate_tiles(rotate_tiles(rotate_tiles(tiles, 90), 90), 90)
    return [list(row) for row in tiles]


def rotate_anchor(anchor: list[int], tiles: list[list[int]], rot: int) -> list[int]:
    """Rotate (row, col) anchor inside a tile grid."""
    rot = rot % 360
    rows = len(tiles)
    cols = max(len(r) for r in tiles) if tiles else 0
    ar, ac = anchor
    if rot == 0:
        return [ar, ac]
    if rot == 90:
        return [ac, rows - 1 - ar]
    if rot == 180:
        return [rows - 1 - ar, cols - 1 - ac]
    if rot == 270:
        return [cols - 1 - ac, ar]
    return [ar, ac]


def load_dressing_room(name: str) -> dict:
    """Load a dressing-room JSON or fall back to a 1x1 default."""
    p = DRESSING_ROOMS_DIR / f"{name}.json"
    if p.exists():
        try:
            return json.loads(p.read_text(encoding="utf-8"))
        except Exception as e:
            print(f"  ! could not parse {p}: {e}; using default")
    return {
        "lookup_name": name,
        "footprint": [1, 1, 1],
        "rotations": ["0", "90", "180", "270"],
        "approach": "south",
        "exit": "north",
        "footing": {"anchor": [0, 0], "tiles": [[1]]},
        "extras": [],
    }


# ───────────────────────────────────────────────────────────────────────
# Placement
# ───────────────────────────────────────────────────────────────────────

def choose_position(spawn: tuple[int, int], teleport: tuple[int, int],
                    fraction: float) -> tuple[int, int]:
    """Linear interpolation along the spawn→teleport line."""
    sr, sc = spawn
    tr, tc = teleport
    return (round(sr + (tr - sr) * fraction),
            round(sc + (tc - sc) * fraction))


def overlap(rect1: tuple[int, int, int, int], rect2: tuple[int, int, int, int]) -> bool:
    """Two (r0, c0, r1, c1) rects overlap?"""
    r0a, c0a, r1a, c1a = rect1
    r0b, c0b, r1b, c1b = rect2
    return not (r1a <= r0b or r1b <= r0a or c1a <= c0b or c1b <= c0a)


def place_rooms(artifacts: list[str], spawn: tuple[int, int], teleport: tuple[int, int],
                width: int, depth: int) -> list[dict]:
    """Lay rooms along spawn→teleport at fractional positions; pick rotation
    aligning approach toward the previous waypoint and exit toward the next."""
    placed: list[dict] = []
    n = len(artifacts)
    if n == 0:
        return placed

    placed_rects: list[tuple[int, int, int, int]] = []

    for i, art_name in enumerate(artifacts):
        room = load_dressing_room(art_name)
        # Target fraction along the path — even spacing between spawn (0) and teleport (1).
        f = (i + 1) / (n + 1)
        target = choose_position(spawn, teleport, f)

        tiles = room["footing"]["tiles"]
        anchor = room["footing"]["anchor"]
        valid_rots = [int(r) for r in room.get("rotations", ["0"])]

        # Find the rotation that fits + best aligns approach toward incoming
        # direction (from previous waypoint).
        prev = placed[-1]["anchor_world"] if placed else spawn
        # Incoming direction (the room's approach should face the prev point).
        dr = prev[0] - target[0]
        dc = prev[1] - target[1]
        if abs(dr) >= abs(dc):
            preferred_approach = "north" if dr < 0 else "south"
        else:
            preferred_approach = "west" if dc < 0 else "east"

        best_rot = valid_rots[0]
        for rot in valid_rots:
            current_approach = rotate_dir(room["approach"], rot)
            if current_approach == preferred_approach:
                best_rot = rot
                break

        # Rotate tiles + anchor + extras for the chosen rotation.
        rotated_tiles = rotate_tiles(tiles, best_rot)
        rotated_anchor = rotate_anchor(anchor, tiles, best_rot)
        rt_rows = len(rotated_tiles)
        rt_cols = max(len(r) for r in rotated_tiles) if rotated_tiles else 0

        # Target world position = put the anchor ON the target cell.
        anchor_r, anchor_c = rotated_anchor
        top_left_r = target[0] - anchor_r
        top_left_c = target[1] - anchor_c
        # Clamp into bounds.
        top_left_r = max(0, min(depth - rt_rows, top_left_r))
        top_left_c = max(0, min(width - rt_cols, top_left_c))

        new_rect = (top_left_r, top_left_c, top_left_r + rt_rows, top_left_c + rt_cols)
        # Resolve overlaps by nudging along the perpendicular to the path.
        attempt = 0
        while any(overlap(new_rect, r) for r in placed_rects) and attempt < 8:
            attempt += 1
            sign = (-1) ** attempt
            nudge = sign * ((attempt + 1) // 2)
            top_left_c = max(0, min(width - rt_cols, new_rect[1] + nudge))
            new_rect = (new_rect[0], top_left_c, new_rect[2], top_left_c + rt_cols)

        anchor_world = (top_left_r + rotated_anchor[0], top_left_c + rotated_anchor[1])
        placed.append({
            "name": art_name,
            "room": room,
            "rotation": best_rot,
            "rotated_tiles": rotated_tiles,
            "rotated_anchor": rotated_anchor,
            "top_left": (top_left_r, top_left_c),
            "anchor_world": anchor_world,
            "approach_world": rotate_dir(room["approach"], best_rot),
            "exit_world": rotate_dir(room["exit"], best_rot),
            "rect": new_rect,
        })
        placed_rects.append(new_rect)
    return placed


# ───────────────────────────────────────────────────────────────────────
# Pathfinding (A*)
# ───────────────────────────────────────────────────────────────────────

def astar(start: tuple[int, int], goal: tuple[int, int],
          width: int, depth: int,
          blocked: set[tuple[int, int]]) -> list[tuple[int, int]]:
    """4-connected A* avoiding `blocked` cells. Returns path including endpoints."""
    if start == goal:
        return [start]
    def h(a, b): return abs(a[0] - b[0]) + abs(a[1] - b[1])
    open_heap: list[tuple[int, tuple[int, int]]] = [(h(start, goal), start)]
    came_from: dict[tuple[int, int], tuple[int, int]] = {}
    g_score: dict[tuple[int, int], int] = {start: 0}
    while open_heap:
        _, current = heapq.heappop(open_heap)
        if current == goal:
            path = [current]
            while current in came_from:
                current = came_from[current]
                path.append(current)
            path.reverse()
            return path
        for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nr, nc = current[0] + dr, current[1] + dc
            neighbour = (nr, nc)
            if not (0 <= nr < depth and 0 <= nc < width):
                continue
            if neighbour in blocked and neighbour != goal:
                continue
            tentative = g_score[current] + 1
            if tentative < g_score.get(neighbour, 10**9):
                came_from[neighbour] = current
                g_score[neighbour] = tentative
                heapq.heappush(open_heap, (tentative + h(neighbour, goal), neighbour))
    return []


# ───────────────────────────────────────────────────────────────────────
# Bake layers
# ───────────────────────────────────────────────────────────────────────

def empty_grid(rows: int, cols: int, fill: str = " ") -> list[list[str]]:
    return [[fill for _ in range(cols)] for _ in range(rows)]


def empty_int_grid(rows: int, cols: int, fill: int = 0) -> list[list[int]]:
    return [[fill for _ in range(cols)] for _ in range(rows)]


def bake_map(name: str, width: int, depth: int,
             spawn: tuple[int, int], teleport: tuple[int, int],
             placed: list[dict], description: str = "") -> dict:
    structure = empty_int_grid(depth, width, 0)
    utilities = empty_grid(depth, width, " ")
    interactables = empty_grid(depth, width, " ")

    # Step 1: stamp footing tiles into structure.
    placed_cells: set[tuple[int, int]] = set()
    for p in placed:
        tlr, tlc = p["top_left"]
        for dr, row in enumerate(p["rotated_tiles"]):
            for dc, val in enumerate(row):
                r = tlr + dr
                c = tlc + dc
                if 0 <= r < depth and 0 <= c < width:
                    structure[r][c] = max(structure[r][c], int(val))
                    placed_cells.add((r, c))

    # Step 2: A*-path connecting spawn → each room's approach edge → exit edge → next.
    # Targeting the approach edge (perimeter cell on the side facing the path)
    # rather than the anchor lets the path reach rooms whose anchor is inside a
    # plinth-and-wall arrangement.

    def approach_cell(p: dict) -> tuple[int, int]:
        """Cell on the room's perimeter where the path enters."""
        d = p["approach_world"]
        rect = p["rect"]  # (r0, c0, r1, c1)
        r0, c0, r1, c1 = rect
        anchor_r, anchor_c = p["anchor_world"]
        if d == "north":
            return (max(0, r0 - 1), anchor_c)
        if d == "south":
            return (min(depth - 1, r1), anchor_c)
        if d == "west":
            return (anchor_r, max(0, c0 - 1))
        if d == "east":
            return (anchor_r, min(width - 1, c1))
        return (anchor_r, anchor_c)

    def exit_cell(p: dict) -> tuple[int, int]:
        """Cell on the room's perimeter where the path leaves."""
        d = p["exit_world"]
        rect = p["rect"]
        r0, c0, r1, c1 = rect
        anchor_r, anchor_c = p["anchor_world"]
        if d == "north":
            return (max(0, r0 - 1), anchor_c)
        if d == "south":
            return (min(depth - 1, r1), anchor_c)
        if d == "west":
            return (anchor_r, max(0, c0 - 1))
        if d == "east":
            return (anchor_r, min(width - 1, c1))
        return (anchor_r, anchor_c)

    # Reserved cells = footing tiles whose value is a wall (≥ 2 but not 3 = plinth).
    # The approach + exit cells must NOT be reserved (path must reach them).
    reserved: set[tuple[int, int]] = set()
    for r in range(depth):
        for c in range(width):
            if structure[r][c] >= 2 and structure[r][c] != 3:
                reserved.add((r, c))
    # Allow path to reach approach + exit cells, even if they happen to be
    # inside another room's footprint (rare).
    for p in placed:
        reserved.discard(approach_cell(p))
        reserved.discard(exit_cell(p))

    # Build waypoint list: spawn → approach[0] → exit[0] → approach[1] → ... → teleport.
    waypoints: list[tuple[int, int]] = [spawn]
    for p in placed:
        waypoints.append(approach_cell(p))
        waypoints.append(p["anchor_world"])
        waypoints.append(exit_cell(p))
    waypoints.append(teleport)

    path_cells: set[tuple[int, int]] = set()
    for i in range(len(waypoints) - 1):
        leg = astar(waypoints[i], waypoints[i + 1], width, depth, reserved)
        if not leg:
            print(f"  ! no path from {waypoints[i]} to {waypoints[i+1]}")
            continue
        path_cells.update(leg)

    # Step 3: every path cell becomes floor (height ≥ 1).
    for r, c in path_cells:
        structure[r][c] = max(structure[r][c], 1)

    # Step 4: surround the assembled territory with walls (height 2).
    used = placed_cells | path_cells
    for r in range(depth):
        for c in range(width):
            if (r, c) in used:
                continue
            # If any 4-neighbour is used, this cell becomes a wall.
            for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nr, nc = r + dr, c + dc
                if (nr, nc) in used:
                    structure[r][c] = max(structure[r][c], 2)
                    break

    # Step 5: utilities — spawn, teleport, and each room's extras.
    sr, sc = spawn
    if 0 <= sr < depth and 0 <= sc < width:
        utilities[sr][sc] = "s"
    tr, tc = teleport
    if 0 <= tr < depth and 0 <= tc < width:
        utilities[tr][tc] = "t:lab"

    for p in placed:
        anchor_r, anchor_c = p["anchor_world"]
        for extra in p["room"].get("extras", []):
            off = tuple(extra.get("offset", [0, 0, 0]))
            rdr, rdc, rdh = rotate_offset(off, p["rotation"])
            er, ec = anchor_r + rdr, anchor_c + rdc
            if not (0 <= er < depth and 0 <= ec < width):
                continue
            etype = extra.get("type", "")
            token = ""
            if etype == "3t":
                txt = extra.get("text", "")
                token = f"3t:{txt}"
            elif etype == "tt":
                key = extra.get("key", "")
                token = f"tt:{key}:180:0.5"
            elif etype == "el":
                params = extra.get("params", "3:1")
                token = f"el:{params}"
            elif etype == "sub":
                token = f"sub:{extra.get('value', 'map')}"
            if token and utilities[er][ec].strip() in {"", " "}:
                utilities[er][ec] = token

    # Step 6: interactables — each room's artifact at its anchor.
    for p in placed:
        ar, ac = p["anchor_world"]
        if 0 <= ar < depth and 0 <= ac < width:
            rot_str = str(p["rotation"]) if p["rotation"] != 0 else "0"
            interactables[ar][ac] = f"{p['name']}:{rot_str}"

    return {
        "map_info": {
            "name": name.replace("_", " "),
            "lookup_name": name,
            "title": name.replace("_", " "),
            "description": description or f"Composed by tools/map_composer.py from {len(placed)} dressing rooms.",
            "version": "0.1-composed",
            "format": "json",
            "dimensions": {"width": width, "depth": depth, "max_height": 5},
            "metadata": {
                "category": "composed",
                "estimated_time": "3-5 minutes",
                "composed_from": [p["name"] for p in placed],
            },
        },
        "utility_definitions": {
            "t": {"type": "teleporter", "name": "Return", "description": "Exit the map."},
            "s": {"type": "spawn", "name": "Spawn", "description": "Player entry."},
        },
        "layers": {
            "structure": [[str(v) for v in row] for row in structure],
            "utilities": utilities,
            "interactables": interactables,
        },
    }


# ───────────────────────────────────────────────────────────────────────
# CLI
# ───────────────────────────────────────────────────────────────────────

def parse_coord(s: str) -> tuple[int, int]:
    parts = [int(x) for x in s.split(",")]
    if len(parts) != 2:
        raise ValueError(f"expected row,col got {s}")
    return (parts[0], parts[1])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--name", help="map name (also used for default --out path)")
    ap.add_argument("--target", help="existing map name; reuse its dimensions/spawn/teleport")
    ap.add_argument("--width", type=int, default=14)
    ap.add_argument("--depth", type=int, default=12)
    ap.add_argument("--spawn", type=parse_coord, default=(1, 1))
    ap.add_argument("--teleport", type=parse_coord, default=None)
    ap.add_argument("--artifacts", required=True,
                    help="comma-separated artifact lookup_names")
    ap.add_argument("--out", type=Path, default=None,
                    help="output path (default: commons/maps/<name>/_proposed/map_data.json)")
    ap.add_argument("--description", default="")
    args = ap.parse_args()

    width, depth = args.width, args.depth
    spawn = args.spawn
    teleport = args.teleport or (depth - 1, width // 2)

    # If --target given, reuse its dimensions + spawn + teleport.
    if args.target:
        tp = MAPS_DIR / args.target / "map_data.json"
        if tp.exists():
            try:
                td = json.loads(tp.read_text(encoding="utf-8"))
                dims = td.get("map_info", {}).get("dimensions", {})
                width = int(dims.get("width", width))
                depth = int(dims.get("depth", depth))
                # Read spawn + teleport from target's utilities.
                util = td.get("layers", {}).get("utilities", [])
                for r, row in enumerate(util):
                    if not isinstance(row, list): continue
                    for c, cell in enumerate(row):
                        if isinstance(cell, str):
                            head = cell.strip().split(":")[0]
                            if head in {"s", "sp"}:
                                spawn = (r, c)
                            elif head == "t":
                                teleport = (r, c)
                print(f"[composer] reusing target {args.target}: {width}×{depth}, "
                      f"spawn={spawn}, teleport={teleport}")
            except Exception as e:
                print(f"  ! could not parse target {args.target}: {e}")
        else:
            print(f"  ! target not found: {args.target}")

    map_name = args.name or args.target or "Composed_Map"
    artifacts = [a.strip() for a in args.artifacts.split(",") if a.strip()]
    if not artifacts:
        print("--artifacts required (comma-separated lookup_names)")
        sys.exit(2)

    out_path = args.out or (MAPS_DIR / map_name / "_proposed" / "map_data.json")
    out_path = Path(out_path)

    print(f"[composer] {map_name}: {len(artifacts)} artifacts, {width}×{depth}")
    print(f"[composer] spawn={spawn}, teleport={teleport}")

    placed = place_rooms(artifacts, spawn, teleport, width, depth)
    print(f"[composer] placed {len(placed)} rooms")
    for p in placed:
        print(f"  {p['name']:<32} anchor={p['anchor_world']} "
              f"rot={p['rotation']:>3} approach={p['approach_world']} exit={p['exit_world']}")

    map_data = bake_map(map_name, width, depth, spawn, teleport, placed,
                        description=args.description)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(map_data, indent=2, ensure_ascii=False),
                        encoding="utf-8")
    print(f"[composer] wrote {out_path.relative_to(REPO)}")


if __name__ == "__main__":
    main()
