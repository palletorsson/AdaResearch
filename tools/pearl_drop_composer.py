#!/usr/bin/env python3
"""Pearl-drop composer.

Drop a chain of dressing rooms into an existing map's silhouette under
gravity. The pearls (rooms) stay attached in sequence order; gravity
packs them toward the bottom of the container (max row first, then
leftmost column).

Usage:
    python tools/pearl_drop_composer.py \\
        --container MANN_Gallery_Museum \\
        --rooms pompeii_mosaic_floor san_michele_mosaic_floor \\
                spiral_mosaic_floor wfc_tile_mosaic \\
        --name MANN_Gallery_Pearl --png

The container map's structure layer is read; cells with h >= 1 form the
"glass-sheet silhouette" the pearls drop into. The chain is placed into
that silhouette greedily — each pearl picks the lowest-leftmost cell
that fits its footprint and is reachable from the previous pearl.

Output: commons/maps/<name>/map_data.json + map_data.png.
"""
from __future__ import annotations

import argparse
import json
import sys
from collections import deque
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
import compose_map_from_dressing_rooms as base  # noqa: E402  reuse rotate / render

MAPS_DIR = REPO / "commons" / "maps"
ROOMS_DIR = REPO / "commons" / "artifacts" / "dressing_rooms"


# ── Container detection ───────────────────────────────────────────────

def cell_height(cell) -> int:
    if isinstance(cell, int): return cell
    if isinstance(cell, str):
        try: return int(cell)
        except Exception: return 0
    return 0


def load_container(map_name: str) -> tuple[set[tuple[int, int]], dict]:
    """Read an existing map's structure layer; return walkable-cell set
    plus the full map_data so we preserve geometry."""
    path = MAPS_DIR / map_name / "map_data.json"
    if not path.exists():
        raise FileNotFoundError(f"no map: {path}")
    md = json.loads(path.read_text(encoding="utf-8", errors="replace"))
    structure = md.get("layers", {}).get("structure", [])
    cells: set[tuple[int, int]] = set()
    for r, row in enumerate(structure):
        if not isinstance(row, list): continue
        for c, val in enumerate(row):
            if cell_height(val) >= 1:
                cells.add((r, c))
    return cells, md


# ── Pearl footprint extraction ────────────────────────────────────────

def pearl_footprint(room: dict, rot_deg: int) -> tuple[list[tuple[int, int]], tuple[int, int],
                                                       tuple[int, int]]:
    """Returns (cell_offsets_relative_to_top_left, anchor_offset_in_pearl,
                (rows, cols))."""
    src = room.get("footing", {}).get("tiles", [[1]])
    src_int = [[int(v) for v in row] for row in src]
    src_rows = len(src_int)
    src_cols = max((len(r) for r in src_int), default=1)
    src_anchor_raw = room.get("footing", {}).get("anchor", [0, 0])
    src_anchor = (int(src_anchor_raw[0]), int(src_anchor_raw[1]))
    rot_tiles = base.rotate_tiles(src_int, rot_deg)
    rot_rows = len(rot_tiles)
    rot_cols = len(rot_tiles[0]) if rot_rows else 0
    rot_anchor = base.rotate_anchor(src_anchor, rot_deg, src_rows, src_cols)
    # Cell offsets where the pearl exists (any non-void footing tile).
    offsets: list[tuple[int, int]] = []
    for dr, row in enumerate(rot_tiles):
        for dc, v in enumerate(row):
            if int(v) != 0:
                offsets.append((dr, dc))
    return offsets, rot_anchor, (rot_rows, rot_cols)


# ── Reachability + placement ──────────────────────────────────────────

def bfs_reachable(start: tuple[int, int], allowed: set[tuple[int, int]]) -> set[tuple[int, int]]:
    """Set of cells reachable via 4-neighbour walk staying inside `allowed`."""
    if start not in allowed:
        return set()
    seen = {start}
    q = deque([start])
    while q:
        r, c = q.popleft()
        for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (r + dr, c + dc)
            if n in allowed and n not in seen:
                seen.add(n)
                q.append(n)
    return seen


def shortest_path(start: tuple[int, int], goal: tuple[int, int],
                  allowed: set[tuple[int, int]]) -> list[tuple[int, int]]:
    """BFS shortest path (start..goal) through `allowed` cells."""
    if start not in allowed or goal not in allowed: return []
    if start == goal: return [start]
    came_from: dict = {start: None}
    q = deque([start])
    while q:
        cur = q.popleft()
        if cur == goal: break
        for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (cur[0] + dr, cur[1] + dc)
            if n in allowed and n not in came_from:
                came_from[n] = cur
                q.append(n)
    if goal not in came_from: return []
    path = [goal]
    while came_from[path[-1]] is not None:
        path.append(came_from[path[-1]])
    path.reverse()
    return path


def find_placement(container: set[tuple[int, int]], occupied: set[tuple[int, int]],
                   pearl_offsets: list[tuple[int, int]],
                   prev_anchor: tuple[int, int] | None,
                   prev_exit: tuple[int, int] | None,
                   bias: str = "down") -> tuple[int, int] | None:
    """Pearl-on-head physics. Pearl 0 hits the bottom of the container
    (lowest-leftmost cell). Subsequent pearls *land on top* of the
    previous one — same column when possible, falling as low as gravity
    allows but resting on the existing pile.

    `bias = "down"` is the canonical case. The fall axis is vertical;
    only the *first* pearl has a free landing spot. Every other pearl
    is stacked on the head, spreading sideways only when its column is
    full.
    """
    free = container - occupied
    rows_set = {r for r, _ in container}
    cols_set = {c for _, c in container}
    if not rows_set: return None
    rmin, rmax = min(rows_set), max(rows_set)
    cmin, cmax = min(cols_set), max(cols_set)

    reachable_from_prev: set | None = None
    if prev_exit is not None:
        reachable_from_prev = bfs_reachable(prev_exit, free)

    def fits(top_r: int, top_c: int) -> bool:
        cells = {(top_r + dr, top_c + dc) for (dr, dc) in pearl_offsets}
        if not cells.issubset(container): return False
        if cells & occupied: return False
        if reachable_from_prev is not None:
            touching = False
            for cell in cells:
                for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    if (cell[0] + dr, cell[1] + dc) in reachable_from_prev:
                        touching = True; break
                if touching: break
            if not touching: return False
        return True

    # ── Pearl 0: free fall to the bottom. ────────────────────────────
    if prev_anchor is None:
        if bias == "down":
            row_order = range(rmax, rmin - 1, -1)
            col_order = range(cmin, cmax + 1)
        elif bias == "up":
            row_order = range(rmin, rmax + 1)
            col_order = range(cmin, cmax + 1)
        elif bias == "right":
            row_order = range(rmin, rmax + 1)
            col_order = range(cmax, cmin - 1, -1)
        else:  # left
            row_order = range(rmin, rmax + 1)
            col_order = range(cmin, cmax + 1)
        for top_r in row_order:
            for top_c in col_order:
                if fits(top_r, top_c): return (top_r, top_c)
        return None

    # ── Pearl N (N >= 1): land on the head. ──────────────────────────
    # Preferred column = previous pearl's column. Fall to the lowest
    # row in that column where the footprint fits AND the bottom cell
    # of the new pearl is one row above any existing pearl (gravity
    # rests pearl N on pearl N-1's top).
    target_col = prev_anchor[1]
    # Columns expanding outward from target_col.
    col_attempts: list[int] = [target_col]
    for dist in range(1, max(target_col - cmin, cmax - target_col) + 1):
        if target_col - dist >= cmin: col_attempts.append(target_col - dist)
        if target_col + dist <= cmax: col_attempts.append(target_col + dist)

    if bias == "down":
        # Lowest row first (the pearl falls until it rests).
        row_order = range(rmax, rmin - 1, -1)
    elif bias == "up":
        row_order = range(rmin, rmax + 1)
    elif bias == "right":
        row_order = range(rmin, rmax + 1)
        col_attempts = list(range(cmax, cmin - 1, -1))
    else:
        row_order = range(rmin, rmax + 1)
        col_attempts = list(range(cmin, cmax + 1))

    for top_c in col_attempts:
        for top_r in row_order:
            if fits(top_r, top_c): return (top_r, top_c)
    return None


# ── Compose ──────────────────────────────────────────────────────────

def compose_pearl_drop(container_map: str, room_names: list[str], out_name: str,
                       gravity: str = "down") -> tuple[Path, dict]:
    container, source_md = load_container(container_map)
    if not container:
        raise ValueError(f"container {container_map} has no walkable cells")

    # Source layers we'll copy + mutate.
    source_struct = source_md.get("layers", {}).get("structure", [])
    source_dims = source_md.get("map_info", {}).get("dimensions", {})
    rows = max((r for r, _ in container), default=0) + 1
    cols = max((c for _, c in container), default=0) + 1
    # Re-pad layers to the same shape (in case the source had ragged rows).
    structure = []
    for r in range(rows):
        row = []
        src_row = source_struct[r] if r < len(source_struct) else []
        for c in range(cols):
            val = src_row[c] if c < len(src_row) else "0"
            row.append(str(cell_height(val)) if isinstance(val, (int, str)) else "0")
        structure.append(row)
    utilities = [[" "] * cols for _ in range(rows)]
    interact = [[" "] * cols for _ in range(rows)]

    occupied: set[tuple[int, int]] = set()
    placements: list[dict] = []
    prev_exit: tuple[int, int] | None = None
    prev_anchor: tuple[int, int] | None = None

    rooms_loaded: list[tuple[str, dict]] = []
    for n in room_names:
        room = base.load_room(n) if (ROOMS_DIR / f"{n}.json").exists() else None
        if room is None:
            print(f"  ! skipping {n}: no dressing room")
            continue
        rooms_loaded.append((n, room))
    if not rooms_loaded:
        raise ValueError("no rooms with dressing rooms")

    for i, (lookup, room) in enumerate(rooms_loaded):
        # Try each allowed rotation; pick the one that places.
        rot_options = [int(str(r)) for r in room.get("rotations", ["0"])] or [0]
        # Prefer rotations whose approach is opposite gravity (so the chain
        # enters from the side the previous pearl came from).
        placed = False
        for rot in rot_options:
            offsets, rot_anchor, (rh, rw) = pearl_footprint(room, rot)
            top = find_placement(container, occupied, offsets,
                                 prev_anchor=prev_anchor,
                                 prev_exit=prev_exit, bias=gravity)
            if top is None: continue
            top_r, top_c = top
            # Stamp the pearl into the layers.
            anchor_abs = (top_r + rot_anchor[0], top_c + rot_anchor[1])
            for (dr, dc) in offsets:
                rr, cc = top_r + dr, top_c + dc
                # Plinth at anchor → step-up (h=2). Other plinths stay 3.
                src_tiles = base.rotate_tiles(
                    [[int(v) for v in row] for row in room["footing"]["tiles"]], rot)
                v = int(src_tiles[dr][dc])
                if v == 3 and (dr, dc) == rot_anchor:
                    v = 2
                if 0 < v:
                    structure[rr][cc] = str(v)
                occupied.add((rr, cc))
            interact[anchor_abs[0]][anchor_abs[1]] = f"{lookup}:{rot}:0"

            # Carve a corridor from previous exit to this pearl's approach
            # cell, staying inside (container - other pearls' occupied).
            eff_app = base.rotate_dir(str(room.get("approach", "south")), rot)
            eff_exit = base.rotate_dir(str(room.get("exit", "north")), rot)
            # Approach/exit cells are just outside the pearl on the right side.
            app_cell = base.compute_perimeter_cell(room, rot, top_r, top_c, eff_app)
            exit_cell = base.compute_perimeter_cell(room, rot, top_r, top_c, eff_exit)

            if prev_exit is not None and app_cell is not None:
                # Allow path through container minus this pearl's interior;
                # use the approach cell even if it's outside container —
                # if so, fall back to the closest container cell adjacent
                # to the pearl.
                allowed = (container - occupied) | {app_cell}
                path = shortest_path(prev_exit, app_cell, allowed)
                if not path:
                    # Try any cell adjacent to the pearl that's reachable.
                    reachable = bfs_reachable(prev_exit, container - occupied)
                    fallback = None
                    for cell in occupied:
                        for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                            n = (cell[0] + dr, cell[1] + dc)
                            if n in reachable:
                                fallback = n; break
                        if fallback: break
                    if fallback:
                        path = shortest_path(prev_exit, fallback, container - occupied)
                # Path cells stay floor (1) — don't overwrite higher
                # geometry like plinths or walls already there.
                for (r, c) in path:
                    if structure[r][c] == "0":
                        structure[r][c] = "1"

            placements.append({
                "lookup": lookup, "rot": rot,
                "top": (top_r, top_c),
                "anchor": list(anchor_abs),
                "approach_cell": list(app_cell) if app_cell else None,
                "exit_cell": list(exit_cell) if exit_cell else None,
            })
            prev_exit = exit_cell or anchor_abs
            prev_anchor = anchor_abs
            placed = True
            break
        if not placed:
            print(f"  · could not place pearl {i}: {lookup} (no rotation fit in container)")

    # Spawn at first pearl's approach cell (or at the pearl's anchor).
    if placements:
        first = placements[0]
        spawn = first.get("approach_cell") or first["anchor"]
        if spawn and 0 <= spawn[0] < rows and 0 <= spawn[1] < cols:
            sr, sc = int(spawn[0]), int(spawn[1])
            if structure[sr][sc] == "0":
                structure[sr][sc] = "1"
            utilities[sr][sc] = "s"

        # Teleporter at last pearl's exit cell.
        last = placements[-1]
        tele = last.get("exit_cell") or last["anchor"]
        if tele:
            tr, tc = int(tele[0]), int(tele[1])
            if 0 <= tr < rows and 0 <= tc < cols:
                utilities[tr][tc] = "t"
                # Teleporter convention: cell is void.
                structure[tr][tc] = "0"

    map_data = {
        "map_info": {
            "lookup_name": out_name,
            "name": out_name,
            "description": f"Pearl-drop composition. Container: {container_map}.",
            "version": "1.0",
            "format": "ada-3layer-v1",
            "dimensions": {
                "width": cols, "depth": rows,
                "max_height": int(source_dims.get("max_height", 5)),
            },
            "metadata": {
                "composed_from_dressing_rooms": True,
                "compose_mode": "pearl_drop",
                "container_map": container_map,
                "gravity": gravity,
                "room_sequence": [p["lookup"] for p in placements],
                "anchors": [
                    {"lookup": p["lookup"], "row": p["anchor"][0], "col": p["anchor"][1],
                     "rotation": p["rot"]} for p in placements
                ],
                "n_unplaced": len(rooms_loaded) - len(placements),
            },
        },
        "utility_definitions": {
            "s": {"type": "spawn", "properties": {"height": 1.5}},
            "t": {"type": "teleporter", "name": "Next",
                  "description": "Continue to next map",
                  "properties": {"action": "next_in_sequence"}},
        },
        "layers": {
            "structure": structure,
            "utilities": utilities,
            "interactables": interact,
        },
    }
    out_dir = MAPS_DIR / out_name
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / "map_data.json"
    out_path.write_text(json.dumps(map_data, indent=2), encoding="utf-8")
    return out_path, map_data


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--container", required=True,
        help="existing map name; its silhouette becomes the container")
    p.add_argument("--rooms", nargs="+", required=True,
        help="dressing-room lookup names — the chain to drop")
    p.add_argument("--name", required=True, help="output map name")
    p.add_argument("--gravity", default="down", choices=["down", "up", "right", "left"])
    p.add_argument("--png", action="store_true")
    p.add_argument("--cell-px", type=int, default=14)
    args = p.parse_args()

    out_path, md = compose_pearl_drop(args.container, args.rooms, args.name, args.gravity)
    n_placed = len(md["map_info"]["metadata"]["anchors"])
    n_un = md["map_info"]["metadata"]["n_unplaced"]
    print(f"wrote {out_path.relative_to(REPO)}  (placed {n_placed}, unplaced {n_un})")
    if args.png:
        png_path = out_path.with_suffix(".png")
        if base.render_png(md, png_path, cell_px=args.cell_px):
            print(f"  png: {png_path.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
