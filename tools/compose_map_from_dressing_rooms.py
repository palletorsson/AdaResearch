#!/usr/bin/env python3
"""Compose a map from dressing rooms — v2.

Adds (vs the v1 first-cut):
  - Per-room rotation selection: each room is rotated so its `approach`
    points back toward the previous room, and its `exit` points toward
    the next.
  - A* between consecutive rooms' (exit → approach) cells, navigating
    around earlier footprints.
  - Extras (3t labels, tt panels, el lights) stamped into utilities at
    their (rotated) offsets.
  - Sequence-aware mode: --sequence <id> pulls the artifact list per map
    from commons/maps/sequences/<id>.json.
  - PNG renderer (Pillow) showing structure / utilities / interactables
    in a top-down legend.
  - Read-only placement negotiation from real candidate rooms via
    --negotiate-dry-run.

Usage:
    # Three hand-authored rooms in a row, render a PNG too:
    python tools/compose_map_from_dressing_rooms.py \\
        --name TestComposed \\
        --rooms lambda_slider qfep_formula_3d russell_set_box --png

    # Build a map per sequence step:
    python tools/compose_map_from_dressing_rooms.py \\
        --sequence foundationscrisis --png
"""
from __future__ import annotations

import argparse
import heapq
import json
import math
from pathlib import Path

import placement_negotiator

REPO = Path(__file__).resolve().parent.parent
ROOMS_DIR = REPO / "commons" / "artifacts" / "dressing_rooms"
SEQUENCES_DIR = REPO / "commons" / "maps" / "sequences"
MAPS_DIR = REPO / "commons" / "maps"
REGISTRY_DIR = REPO / "commons" / "artifacts" / "registry"

# Cached registry index — lookup_name → registry entry.
_REGISTRY_CACHE: dict[str, dict] = {}


def _load_registry() -> dict[str, dict]:
    if _REGISTRY_CACHE:
        return _REGISTRY_CACHE
    if not REGISTRY_DIR.exists():
        return _REGISTRY_CACHE
    for p in sorted(REGISTRY_DIR.glob("*.json")):
        try:
            data = json.loads(p.read_text(encoding="utf-8", errors="replace"))
        except Exception:
            continue
        artifacts = data.get("artifacts", data) if isinstance(data, dict) else {}
        if not isinstance(artifacts, dict):
            continue
        for k, v in artifacts.items():
            if isinstance(v, dict):
                lookup = v.get("lookup_name") or k
                if isinstance(lookup, str):
                    # Stamp the lookup_name into the entry so filters can
                    # see it (registry entries don't always carry the key).
                    if "lookup_name" not in v:
                        v = {**v, "lookup_name": lookup}
                    _REGISTRY_CACHE[lookup] = v
    return _REGISTRY_CACHE


def _artifacts_in_sequence(seq_id: str) -> list[str]:
    """Walk a sequence's maps and collect every interactable lookup_name."""
    p = SEQUENCES_DIR / f"{seq_id}.json"
    if not p.exists():
        return []
    try:
        data = json.loads(p.read_text(encoding="utf-8", errors="replace"))
    except Exception:
        return []
    seqs = data.get("sequences", {})
    if not isinstance(seqs, dict):
        return []
    seq = seqs.get(seq_id) or next(iter(seqs.values()), {})
    map_names = seq.get("maps", [])
    seen: set[str] = set()
    order: list[str] = []
    for m in map_names:
        if not isinstance(m, str):
            continue
        md_path = MAPS_DIR / m / "map_data.json"
        if not md_path.exists():
            continue
        try:
            md = json.loads(md_path.read_text(encoding="utf-8", errors="replace"))
        except Exception:
            continue
        for row in md.get("layers", {}).get("interactables", []):
            if not isinstance(row, list):
                continue
            for cell in row:
                if not isinstance(cell, str): continue
                token = cell.strip()
                if not token or token == " ": continue
                lookup = token.split(":", 1)[0]
                if lookup and lookup not in seen:
                    seen.add(lookup)
                    order.append(lookup)
    return order


def _matches_filter(entry: dict, where: dict) -> bool:
    """Simple field=value matcher with list-membership for tags/dev_themes."""
    for k, want in where.items():
        if k in ("tag", "tags"):
            tags = entry.get("tags", []) or []
            if isinstance(want, str):
                if want not in tags: return False
            elif isinstance(want, list):
                if not any(t in tags for t in want): return False
        elif k == "dev_theme":
            themes = entry.get("dev_themes", []) or []
            if want not in themes: return False
        elif k == "name_contains":
            name = str(entry.get("lookup_name", entry.get("name", ""))).lower()
            if str(want).lower() not in name:
                return False
        else:
            if entry.get(k) != want:
                return False
    return True


# Layout patterns (returns offsets in (drow, dcol) cell-fractional units).
def _layout_offsets(layout: str, n: int, radius: float = 0.4) -> list[tuple[float, float]]:
    import math
    if n <= 0: return []
    if layout == "ring":
        return [(radius * math.cos(2 * math.pi * i / n - math.pi / 2),
                 radius * math.sin(2 * math.pi * i / n - math.pi / 2))
                for i in range(n)]
    if layout == "row":
        if n == 1: return [(0.0, 0.0)]
        step = 0.8 / (n - 1)
        return [(0.0, -0.4 + step * i) for i in range(n)]
    if layout == "column":
        if n == 1: return [(0.0, 0.0)]
        step = 0.8 / (n - 1)
        return [(-0.4 + step * i, 0.0) for i in range(n)]
    if layout == "grid":
        side = max(1, int(math.ceil(math.sqrt(n))))
        out: list[tuple[float, float]] = []
        for i in range(n):
            r = i // side
            c = i % side
            out.append((-0.35 + 0.7 * r / max(1, side - 1) if side > 1 else 0.0,
                        -0.35 + 0.7 * c / max(1, side - 1) if side > 1 else 0.0))
        return out
    if layout == "cluster":
        # Random-ish but deterministic spread inside a small disk.
        return [(radius * math.cos(i * 2.4), radius * math.sin(i * 2.4))
                for i in range(n)]
    return [(0.0, 0.0)] * n


def resolve_vitrine_grammar(room: dict) -> list[dict]:
    """Expand a `vitrine_grammar` rule into concrete sub_anchor entries.
    Each returned dict: {lookup, offset:[dr,dc], scale}."""
    g = room.get("vitrine_grammar")
    if not isinstance(g, dict):
        return []
    select_from = str(g.get("select_from", ""))
    where = g.get("where") or {}
    limit = int(g.get("limit", 4))
    layout = str(g.get("layout", "ring"))
    scale = float(g.get("scale", 0.35))
    radius = float(g.get("radius", 0.4))
    self_lookup = str(room.get("lookup_name", ""))
    exclude_self = bool(g.get("exclude_self", True))

    # Source of candidate lookups.
    candidates: list[str] = []
    if select_from.startswith("sequence:"):
        candidates = _artifacts_in_sequence(select_from.split(":", 1)[1])
    elif select_from.startswith("registry:"):
        # All artifacts in a single registry file (e.g. registry:qfep).
        reg = select_from.split(":", 1)[1]
        path = REGISTRY_DIR / f"{reg}.json"
        if path.exists():
            try:
                data = json.loads(path.read_text(encoding="utf-8", errors="replace"))
                arts = data.get("artifacts", data)
                if isinstance(arts, dict):
                    candidates = [
                        v.get("lookup_name", k) for k, v in arts.items()
                        if isinstance(v, dict)
                    ]
            except Exception:
                pass
    elif select_from == "all":
        registry = _load_registry()
        candidates = list(registry.keys())
    elif isinstance(g.get("explicit"), list):
        candidates = [str(x) for x in g["explicit"]]

    # Filter via `where` against the registry entry.
    registry = _load_registry()
    filtered: list[str] = []
    for lookup in candidates:
        if exclude_self and lookup == self_lookup:
            continue
        entry = registry.get(lookup, {"lookup_name": lookup})
        if where and not _matches_filter(entry, where):
            continue
        filtered.append(lookup)
        if len(filtered) >= limit:
            break

    # Place via the chosen layout.
    offsets = _layout_offsets(layout, len(filtered), radius=radius)
    out: list[dict] = []
    for lookup, (dr, dc) in zip(filtered, offsets):
        out.append({"lookup": lookup, "offset": [float(dr), float(dc)], "scale": scale})
    return out

INTER_ROOM_GAP = 3       # min cells between adjacent rooms
EDGE_PADDING = 3
DIRECTIONS = ["north", "east", "south", "west"]
DIR_VECTOR = {"north": (-1, 0), "south": (1, 0), "east": (0, 1), "west": (0, -1)}


# ── Dressing-room loading + rotation helpers ──────────────────────────

def load_room(name: str) -> dict:
    p = ROOMS_DIR / f"{name}.json"
    if not p.exists():
        raise FileNotFoundError(f"no dressing room: {p}")
    return json.loads(p.read_text(encoding="utf-8"))


def rotate_dir(d: str, rot_deg: int) -> str:
    """Rotate a cardinal direction clockwise (looking down) by rot_deg."""
    if d not in DIRECTIONS:
        return d
    steps = (rot_deg // 90) % 4
    idx = (DIRECTIONS.index(d) + steps) % 4
    return DIRECTIONS[idx]


def rotate_tiles(tiles: list[list[int]], rot_deg: int) -> list[list[int]]:
    """Rotate a 2D tile array clockwise by rot_deg (0/90/180/270)."""
    rot = rot_deg % 360
    if rot == 0:
        return [row[:] for row in tiles]
    rows = len(tiles)
    cols = max((len(r) for r in tiles), default=0)
    # Pad rows so the rotation source is rectangular.
    padded = [list(r) + [0] * (cols - len(r)) for r in tiles]
    if rot == 90:
        out = [[padded[rows - 1 - r][c] for r in range(rows)] for c in range(cols)]
    elif rot == 180:
        out = [list(reversed(r)) for r in reversed(padded)]
    elif rot == 270:
        out = [[padded[r][cols - 1 - c] for r in range(rows)] for c in range(cols)]
    else:
        out = [r[:] for r in padded]
    return out


def rotate_anchor(anchor: tuple[int, int], rot_deg: int, src_rows: int, src_cols: int) -> tuple[int, int]:
    """Inverse of rotate_tiles for a single (row, col) cell."""
    r, c = anchor
    rot = rot_deg % 360
    if rot == 0:
        return (r, c)
    if rot == 90:
        return (c, src_rows - 1 - r)
    if rot == 180:
        return (src_rows - 1 - r, src_cols - 1 - c)
    if rot == 270:
        return (src_cols - 1 - c, r)
    return (r, c)


def rotate_offset_2d(dr: int, dc: int, rot_deg: int) -> tuple[int, int]:
    """Rotate a (drow, dcol) offset clockwise by rot_deg (looking down).
    drow points south (+) and dcol points east (+)."""
    rot = rot_deg % 360
    if rot == 0: return (dr, dc)
    if rot == 90: return (dc, -dr)
    if rot == 180: return (-dr, -dc)
    if rot == 270: return (-dc, dr)
    return (dr, dc)


def pick_rotation(room: dict, want_approach: str, want_exit: str | None) -> int:
    """Choose a rotation from the room's allowed list whose rotated
    approach == want_approach (and exit == want_exit if specified).
    Falls back to the first allowed rotation if no exact match."""
    base_app = str(room.get("approach", "south"))
    base_exit = str(room.get("exit", "north"))
    rots = [int(str(r)) for r in room.get("rotations", ["0"])]
    candidates: list[tuple[int, int]] = []   # (score, rot)
    for r in rots:
        ra = rotate_dir(base_app, r)
        re = rotate_dir(base_exit, r)
        score = 0
        if ra == want_approach: score += 2
        if want_exit is None or re == want_exit: score += 1
        candidates.append((score, r))
    candidates.sort(reverse=True)
    return candidates[0][1] if candidates else 0


# ── Map composition (linear placement with rotation) ──────────────────

def make_layer(rows: int, cols: int, fill):
    return [[fill for _ in range(cols)] for _ in range(rows)]


def in_bounds(r: int, c: int, rows: int, cols: int) -> bool:
    return 0 <= r < rows and 0 <= c < cols


def stamp_room(structure, utilities, interactables, room: dict, lookup: str,
               rot_deg: int, place_row: int, place_col: int) -> tuple[int, int]:
    """Stamp a rotated room at (place_row, place_col) into the layers.
    place_row/col is the TOP-LEFT corner of the rotated tile array.
    Returns the rotated anchor's absolute (row, col)."""
    src_tiles = room.get("footing", {}).get("tiles", [[1]])
    src_rows = len(src_tiles)
    src_cols = max((len(r) for r in src_tiles), default=1)
    src_anchor = tuple(room.get("footing", {}).get("anchor", [0, 0]))
    # Tiles can come back as floats from the JSON — coerce to int.
    src_tiles_int = [[int(v) for v in row] for row in src_tiles]
    rot_tiles = rotate_tiles(src_tiles_int, rot_deg)
    rot_anchor = rotate_anchor((int(src_anchor[0]), int(src_anchor[1])),
                               rot_deg, src_rows, src_cols)

    rows_out = len(structure)
    cols_out = len(structure[0]) if rows_out else 0

    # Stamp footing tiles. Plinth (3) at the ANCHOR is lowered to 2 so
    # the player can step up to it.
    for dr, row in enumerate(rot_tiles):
        for dc, v in enumerate(row):
            tr = place_row + dr
            tc = place_col + dc
            if not in_bounds(tr, tc, rows_out, cols_out):
                continue
            v_out = int(v)
            if v_out == 3 and (dr, dc) == rot_anchor:
                v_out = 2
            structure[tr][tc] = str(v_out)

    # Place artifact at the rotated anchor.
    abs_anchor = (place_row + rot_anchor[0], place_col + rot_anchor[1])
    if in_bounds(abs_anchor[0], abs_anchor[1], rows_out, cols_out):
        token = f"{lookup}:{rot_deg}:0"
        artifact_config = room.get("artifact_config", {})
        if isinstance(artifact_config, dict):
            for key in sorted(artifact_config):
                value = artifact_config[key]
                if isinstance(value, bool):
                    encoded = "true" if value else "false"
                elif isinstance(value, (str, int, float)):
                    encoded = str(value)
                else:
                    continue
                token += f"#{key}:{encoded}"
        interactables[abs_anchor[0]][abs_anchor[1]] = token

    # Extras: stamp into utilities at rotated offsets relative to anchor.
    # Mapping (best-effort, the existing project format isn't documented
    # for these tokens — we use generic codes the schema doc proposes):
    #   3t  -> "3t:<text>"
    #   tt  -> "tt:<key>"
    #   el  -> "el:<params>"
    for extra in room.get("extras", []) or []:
        if not isinstance(extra, dict):
            continue
        et = str(extra.get("type", ""))
        offset = extra.get("offset", [0, 0, 0])
        if not (isinstance(offset, list) and len(offset) >= 2):
            continue
        # Per-extra rotation override; otherwise rotate with the room.
        eff_rot = int(extra.get("rotation", rot_deg)) if "rotation" in extra else rot_deg
        rd, rc = rotate_offset_2d(int(offset[0]), int(offset[1]), eff_rot)
        tr = abs_anchor[0] + rd
        tc = abs_anchor[1] + rc
        if not in_bounds(tr, tc, rows_out, cols_out):
            continue
        # Don't overwrite the artifact itself.
        if (tr, tc) == abs_anchor:
            continue
        # Token formatting per type. Floor under the extra cell so it's
        # visible (otherwise it floats over void).
        if structure[tr][tc] == "0":
            structure[tr][tc] = "1"
        if et == "3t":
            utilities[tr][tc] = f"3t:{extra.get('text', '?')}"
        elif et == "tt":
            utilities[tr][tc] = f"tt:{extra.get('key', '?')}"
        elif et == "el":
            utilities[tr][tc] = f"el:{extra.get('params', '3:1')}"
        elif et == "wp":
            utilities[tr][tc] = f"wp:{int(extra.get('rotation', rot_deg))}"
        elif et == "sub":
            utilities[tr][tc] = f"sub:{extra.get('value', '?')}"

    return abs_anchor


def compute_perimeter_cell(room: dict, rot_deg: int, place_row: int, place_col: int,
                           which: str) -> tuple[int, int] | None:
    """Find the cell just outside the room's footing on the side indicated
    by `which` (the rotated approach or exit direction). Used as the A*
    endpoint for the corridor. Returns None on failure."""
    src_tiles = room.get("footing", {}).get("tiles", [[1]])
    src_rows = len(src_tiles)
    src_cols = max((len(r) for r in src_tiles), default=1)
    rot_tiles = rotate_tiles(src_tiles, rot_deg)
    rot_rows = len(rot_tiles)
    rot_cols = len(rot_tiles[0]) if rot_rows else 0
    src_anchor_raw = room.get("footing", {}).get("anchor", [0, 0])
    rot_anchor = rotate_anchor((int(src_anchor_raw[0]), int(src_anchor_raw[1])),
                               rot_deg, src_rows, src_cols)
    ar = int(rot_anchor[0]) + int(place_row)
    ac = int(rot_anchor[1]) + int(place_col)
    pr = int(place_row); pc = int(place_col)
    if which == "north":
        return (pr - 1, ac)
    if which == "south":
        return (pr + int(rot_rows), ac)
    if which == "east":
        return (ar, pc + int(rot_cols))
    if which == "west":
        return (ar, pc - 1)
    return None


def a_star(structure, start, goal, occupied: set[tuple[int, int]]) -> list[tuple[int, int]]:
    """A* on a grid. Walkable: in_bounds, not in occupied, height <= 4 and
    height-step diff <= 1. Returns list of cells from start to goal."""
    rows = len(structure)
    cols = len(structure[0]) if rows else 0
    if not (in_bounds(*start, rows, cols) and in_bounds(*goal, rows, cols)):
        return []

    def h(a, b): return abs(a[0] - b[0]) + abs(a[1] - b[1])

    def cell_height(r, c):
        v = structure[r][c]
        try: return int(v)
        except Exception: return 0

    open_q: list[tuple[int, tuple[int, int]]] = []
    heapq.heappush(open_q, (0, start))
    came_from: dict[tuple[int, int], tuple[int, int] | None] = {start: None}
    g_score: dict[tuple[int, int], int] = {start: 0}
    while open_q:
        _, cur = heapq.heappop(open_q)
        if cur == goal:
            # Reconstruct.
            path = [cur]
            while came_from.get(path[-1]) is not None:
                path.append(came_from[path[-1]])
            path.reverse()
            return path
        cur_h = cell_height(*cur)
        for dr, dc in DIR_VECTOR.values():
            nr, nc = cur[0] + dr, cur[1] + dc
            if not in_bounds(nr, nc, rows, cols):
                continue
            if (nr, nc) in occupied and (nr, nc) != goal:
                continue
            nh = cell_height(nr, nc)
            # Neighbour height: void (0) is OK to pave; floor (1) and
            # plinth (2) are walkable.
            if nh > 0 and abs(nh - cur_h) > 1 and (nr, nc) != goal:
                continue
            tentative = g_score[cur] + 1
            if tentative < g_score.get((nr, nc), 1 << 30):
                g_score[(nr, nc)] = tentative
                came_from[(nr, nc)] = cur
                f = tentative + h((nr, nc), goal)
                heapq.heappush(open_q, (f, (nr, nc)))
    return []


def collect_room_cells(structure, place_row, place_col, rot_tiles) -> set[tuple[int, int]]:
    cells = set()
    for dr, row in enumerate(rot_tiles):
        for dc, _ in enumerate(row):
            cells.add((place_row + dr, place_col + dc))
    return cells


def required_map_height(rooms: list[tuple[str, dict]], minimum: int = 5) -> int:
    """Return the vertical envelope required by the composed room contracts.

    Clearance is authoritative because it includes visitor and installation
    space; measured footprint height is the fallback for older rooms. Keeping
    the legacy five-metre minimum avoids changing ordinary gallery volumes.
    """
    required = float(minimum)
    for _, room in rooms:
        clearance = room.get("clearance", [])
        footprint = room.get("footprint", [])
        if isinstance(clearance, list) and len(clearance) >= 3:
            required = max(required, float(clearance[2]))
        if isinstance(footprint, list) and len(footprint) >= 3:
            required = max(required, float(footprint[2]))
    return int(math.ceil(required))


def compose(map_name: str, room_names: list[str], write: bool = True) -> tuple[Path, dict]:
    rooms = []
    for name in room_names:
        try:
            rooms.append((name, load_room(name)))
        except FileNotFoundError:
            print(f"  ! skipped {name}: no dressing room")
    if not rooms:
        raise ValueError("no rooms to compose")

    max_height = required_map_height(rooms)

    # Pre-pick a uniform "we walk west→east" axis: every room rotates so
    # its approach is "west" and its exit is "east". Falls back if not
    # in the room's allowed rotations.
    chosen_rots: list[int] = []
    for _, r in rooms:
        chosen_rots.append(pick_rotation(r, "west", "east"))

    # Pre-compute rotated dimensions for sizing the canvas.
    rot_dims: list[tuple[int, int]] = []
    for (_, r), rot in zip(rooms, chosen_rots):
        src = r.get("footing", {}).get("tiles", [[1]])
        rot_t = rotate_tiles(src, rot)
        rot_dims.append((len(rot_t), len(rot_t[0]) if rot_t else 1))

    # Total canvas: rooms in a single row, with INTER_ROOM_GAP between.
    total_cols = sum(c for _, c in rot_dims) + INTER_ROOM_GAP * (len(rooms) + 1) + 2 * EDGE_PADDING
    max_rows = max(r for r, _ in rot_dims) + 2 * EDGE_PADDING + 4

    structure = make_layer(max_rows, total_cols, "0")
    utilities = make_layer(max_rows, total_cols, " ")
    interact = make_layer(max_rows, total_cols, " ")
    occupied: set[tuple[int, int]] = set()

    center_row = max_rows // 2

    placements: list[dict] = []
    placements_vitrines: list[dict] = []
    cur_col = EDGE_PADDING + INTER_ROOM_GAP
    for (lookup, room), rot, (rr, rc) in zip(rooms, chosen_rots, rot_dims):
        # Find the rotated anchor's row within the rotated tile grid so we
        # can align the room so its anchor sits on center_row.
        src_tiles = room.get("footing", {}).get("tiles", [[1]])
        src_rows = len(src_tiles)
        src_cols = max((len(r) for r in src_tiles), default=1)
        src_anchor_raw = room.get("footing", {}).get("anchor", [0, 0])
        src_anchor = (int(src_anchor_raw[0]), int(src_anchor_raw[1]))
        ranchor = rotate_anchor(src_anchor, rot, src_rows, src_cols)
        place_row = center_row - ranchor[0]
        place_col = cur_col

        anchor_abs = stamp_room(structure, utilities, interact, room, lookup,
                                rot, place_row, place_col)
        rot_tiles = rotate_tiles(src_tiles, rot)
        cells = collect_room_cells(structure, place_row, place_col, rot_tiles)
        occupied |= cells

        # Vitrine sub-anchors: literal sub_anchors + grammar-resolved ones.
        # Stored in metadata.vitrines so the PNG renderer + future runtime
        # can show them. Sub-anchor offsets rotate with the room.
        vitrine_subs: list[dict] = []
        for entry in (room.get("sub_anchors") or []):
            if isinstance(entry, dict):
                vitrine_subs.append(entry)
        vitrine_subs.extend(resolve_vitrine_grammar(room))
        if vitrine_subs:
            placement_vitrine: list[dict] = []
            for sub in vitrine_subs:
                off = sub.get("offset", [0.0, 0.0])
                if len(off) < 2: off = [0.0, 0.0]
                # Rotate offset with the room (90° increments).
                from math import cos, sin, radians
                a = radians(rot)
                rdr = float(off[0]) * cos(a) + float(off[1]) * sin(a)
                rdc = -float(off[0]) * sin(a) + float(off[1]) * cos(a)
                placement_vitrine.append({
                    "lookup": str(sub.get("lookup", "?")),
                    "row": anchor_abs[0] + rdr,
                    "col": anchor_abs[1] + rdc,
                    "scale": float(sub.get("scale", 0.35)),
                })
            placements_vitrines.append({
                "host": lookup,
                "host_anchor": list(anchor_abs),
                "subs": placement_vitrine,
            })

        eff_app = rotate_dir(str(room.get("approach", "south")), rot)
        eff_exit = rotate_dir(str(room.get("exit", "north")), rot)
        approach_cell = compute_perimeter_cell(room, rot, place_row, place_col, eff_app)
        exit_cell = compute_perimeter_cell(room, rot, place_row, place_col, eff_exit)

        placements.append({
            "lookup": lookup, "rot": rot,
            "place": (place_row, place_col),
            "rot_dims": (rr, rc),
            "anchor": anchor_abs,
            "approach_cell": approach_cell,
            "exit_cell": exit_cell,
        })

        cur_col = place_col + rc + INTER_ROOM_GAP

    # Spawn at the first room's approach cell (or just before).
    first_app = placements[0]["approach_cell"]
    if first_app and in_bounds(*first_app, max_rows, total_cols):
        if structure[first_app[0]][first_app[1]] == "0":
            structure[first_app[0]][first_app[1]] = "1"
        utilities[first_app[0]][first_app[1]] = "s"

    # A* corridor from each room's exit → next room's approach.
    for i in range(len(placements) - 1):
        a = placements[i]["exit_cell"]
        b = placements[i + 1]["approach_cell"]
        if not (a and b):
            continue
        # Make sure both endpoints are floor before pathing.
        if in_bounds(*a, max_rows, total_cols) and structure[a[0]][a[1]] == "0":
            structure[a[0]][a[1]] = "1"
        if in_bounds(*b, max_rows, total_cols) and structure[b[0]][b[1]] == "0":
            structure[b[0]][b[1]] = "1"
        path = a_star(structure, a, b, occupied)
        # Carve the path: any void cell on the path becomes floor.
        for (r, c) in path:
            if structure[r][c] == "0":
                structure[r][c] = "1"

    # Teleporter just past the last room's exit.
    last_exit = placements[-1]["exit_cell"]
    if last_exit and in_bounds(*last_exit, max_rows, total_cols):
        # Walk one step further in the exit direction; place teleporter on
        # void there, with the exit cell itself as the approach.
        last_room = placements[-1]
        exit_dir = rotate_dir(
            str(rooms[-1][1].get("exit", "north")), last_room["rot"])
        dr, dc = DIR_VECTOR.get(exit_dir, (0, 1))
        tr, tc = last_exit[0] + dr, last_exit[1] + dc
        if structure[last_exit[0]][last_exit[1]] == "0":
            structure[last_exit[0]][last_exit[1]] = "1"
        if in_bounds(tr, tc, max_rows, total_cols):
            utilities[tr][tc] = "t"
            structure[tr][tc] = "0"
            # A teleporter is a void threshold, not the edge of the world.
            # Keep one floor cell beyond it so an overshooting player lands.
            catch_r, catch_c = tr + dr, tc + dc
            if in_bounds(catch_r, catch_c, max_rows, total_cols):
                structure[catch_r][catch_c] = "1"

    map_data = {
        "map_info": {
            "lookup_name": map_name,
            "name": map_name,
            "description": "Auto-composed from dressing rooms (v2).",
            "version": "2.0",
            "format": "ada-3layer-v1",
            "dimensions": {"width": total_cols, "depth": max_rows, "max_height": max_height},
            "metadata": {
                "composed_from_dressing_rooms": True,
                "room_sequence": room_names,
                "rotations": chosen_rots,
                "anchors": [
                    {"lookup": p["lookup"], "row": p["anchor"][0], "col": p["anchor"][1],
                     "rotation": p["rot"]}
                    for p in placements
                ],
                "vitrines": placements_vitrines,
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

    out_dir = MAPS_DIR / map_name
    out_path = out_dir / "map_data.json"
    if write:
        out_dir.mkdir(parents=True, exist_ok=True)
        out_path.write_text(json.dumps(map_data, indent=2), encoding="utf-8")
    return out_path, map_data


# ── Placement-negotiation offer extraction ───────────────────────────

def _edge_wall_sides(rot_tiles: list[list[int]]) -> list[str]:
    """Return room edges that contain authored wall-height cells."""
    if not rot_tiles or not rot_tiles[0]:
        return []
    rows = len(rot_tiles)
    cols = len(rot_tiles[0])
    sides: list[str] = []
    if any(int(rot_tiles[0][c]) >= 4 for c in range(cols)):
        sides.append("north")
    if any(int(rot_tiles[r][cols - 1]) >= 4 for r in range(rows)):
        sides.append("east")
    if any(int(rot_tiles[rows - 1][c]) >= 4 for c in range(cols)):
        sides.append("south")
    if any(int(rot_tiles[r][0]) >= 4 for r in range(rows)):
        sides.append("west")
    return sides


def _outer_ring_walkable(rot_tiles: list[list[int]]) -> bool:
    """A full-orbit room keeps every cell on its outer ring walkable."""
    if not rot_tiles or not rot_tiles[0]:
        return False
    rows = len(rot_tiles)
    cols = len(rot_tiles[0])
    ring: list[int] = []
    ring.extend(int(rot_tiles[0][c]) for c in range(cols))
    if rows > 1:
        ring.extend(int(rot_tiles[rows - 1][c]) for c in range(cols))
    if rows > 2:
        ring.extend(int(rot_tiles[r][0]) for r in range(1, rows - 1))
        if cols > 1:
            ring.extend(int(rot_tiles[r][cols - 1]) for r in range(1, rows - 1))
    return bool(ring) and all(value == 1 for value in ring)


def _expansion_directions(
    bounds: tuple[int, int, int, int],
    other_cells: set[tuple[int, int]],
    rows: int,
    cols: int,
) -> list[str]:
    """Test whether a one-cell strip is free on each side of a room."""
    top, left, height, width = bounds
    candidates = {
        "north": [(top - 1, c) for c in range(left, left + width)],
        "east": [(r, left + width) for r in range(top, top + height)],
        "south": [(top + height, c) for c in range(left, left + width)],
        "west": [(r, left - 1) for r in range(top, top + height)],
    }
    available: list[str] = []
    for direction, cells in candidates.items():
        if cells and all(in_bounds(r, c, rows, cols) and (r, c) not in other_cells for r, c in cells):
            available.append(direction)
    return available


def derive_floorplan_offers(map_name: str, map_data: dict) -> dict:
    """Convert actual candidate placements into negotiator floorplan offers.

    The offer comes from the composed candidate: rotated tile dimensions,
    detected wall edges, authored support, surrounding free strips, and outer
    ring walkability. No canonical room data is changed.
    """
    metadata = map_data.get("map_info", {}).get("metadata", {})
    anchors = metadata.get("anchors", []) or []
    dimensions = map_data.get("map_info", {}).get("dimensions", {})
    rows = int(dimensions.get("depth", 0))
    cols = int(dimensions.get("width", 0))

    geometries: list[dict] = []
    all_room_cells: dict[str, set[tuple[int, int]]] = {}
    for index, anchor_info in enumerate(anchors):
        lookup = str(anchor_info.get("lookup", ""))
        room = load_room(lookup)
        rot = int(anchor_info.get("rotation", 0)) % 360
        src_tiles = room.get("footing", {}).get("tiles", [[1]])
        src_rows = len(src_tiles)
        src_cols = max((len(row) for row in src_tiles), default=1)
        src_anchor_raw = room.get("footing", {}).get("anchor", [0, 0])
        rotated_anchor = rotate_anchor(
            (int(src_anchor_raw[0]), int(src_anchor_raw[1])), rot, src_rows, src_cols
        )
        rot_tiles = rotate_tiles([[int(v) for v in row] for row in src_tiles], rot)
        room_rows = len(rot_tiles)
        room_cols = len(rot_tiles[0]) if rot_tiles else 1
        top = int(anchor_info.get("row", 0)) - rotated_anchor[0]
        left = int(anchor_info.get("col", 0)) - rotated_anchor[1]
        key = f"{index}:{lookup}"
        cells = {
            (top + dr, left + dc)
            for dr in range(room_rows)
            for dc in range(room_cols)
        }
        all_room_cells[key] = cells
        geometries.append({
            "key": key,
            "lookup": lookup,
            "room": room,
            "rotation": rot,
            "anchor": (int(anchor_info.get("row", 0)), int(anchor_info.get("col", 0))),
            "tiles": rot_tiles,
            "bounds": (top, left, room_rows, room_cols),
        })

    offers: list[dict] = []
    for geometry in geometries:
        lookup = geometry["lookup"]
        room = geometry["room"]
        contract = room.get("placement_contract", {})
        if not isinstance(contract, dict) or not contract:
            raise ValueError(f"{lookup}: placement_contract required for negotiation dry-run")
        allowed_modes = [str(x) for x in contract.get("allowed_modes", [])]
        preferred_mode = str(contract.get("preferred_mode", allowed_modes[0] if allowed_modes else ""))
        clearance = room.get("clearance", [geometry["bounds"][3], geometry["bounds"][2], 3])
        height = float(clearance[2]) if isinstance(clearance, list) and len(clearance) >= 3 else 3.0
        other_cells: set[tuple[int, int]] = set()
        for key, cells in all_room_cells.items():
            if key != geometry["key"]:
                other_cells |= cells
        expansion = _expansion_directions(
            geometry["bounds"], other_cells, rows, cols
        )
        circulation = str(contract.get("circulation", "frontal"))
        route_width = 1.0 if circulation != "full_orbit" or _outer_ring_walkable(geometry["tiles"]) else 0.0
        offers.append({
            "artifact": lookup,
            "room_m": [geometry["bounds"][3], geometry["bounds"][2], height],
            "mode": preferred_mode,
            "rotation": geometry["rotation"],
            "support": str(contract.get("required_support", room.get("posture", ""))),
            "support_surface_height_m": (
                sum(float(x) for x in contract["support_surface_height_m"]) / 2.0
                if isinstance(contract.get("support_surface_height_m"), list)
                and len(contract["support_surface_height_m"]) == 2
                else None
            ),
            "wall_sides": _edge_wall_sides(geometry["tiles"]),
            "neighbor_artifacts": [],
            "expansion_directions": expansion,
            "allow_shrink": False,
            "route_width_m": route_width,
            "candidate_anchor": [
                geometry["anchor"][0],
                geometry["anchor"][1],
            ],
        })

    return {
        "schema": "adaresearch.floorplan_offers.v1",
        "title": f"Composer candidate offers for {map_name}",
        "source": "compose_map_from_dressing_rooms --negotiate-dry-run",
        "map": map_name,
        "offers": offers,
    }


def run_negotiation_dry_run(
    map_name: str,
    map_data: dict,
    rules_path: Path,
    measurement_report_path: Path,
    output_root: Path,
) -> tuple[bool, Path]:
    """Evaluate and persist a candidate map without authorizing a map write."""
    safe_name = map_name.replace("/", "__").replace("\\", "__")
    out_dir = output_root / safe_name
    overlay_dir = out_dir / "overlays"
    out_dir.mkdir(parents=True, exist_ok=True)
    offers_path = out_dir / "floorplan_offers.json"

    try:
        offers = derive_floorplan_offers(map_name, map_data)
        offers_path.write_text(json.dumps(offers, indent=2), encoding="utf-8")
        rules = placement_negotiator.load_json(rules_path)
        measurement_report = placement_negotiator.load_json(measurement_report_path)
        report = placement_negotiator.build_report(rules, offers, measurement_report)
        report["source_map"] = map_name
        report["mode"] = "composer_dry_run"
        report["map_written"] = False
        for decision in report.get("decisions", []):
            decision["overlay_image"] = f"overlays/{decision['artifact']}.png"
            placement_negotiator.render_overlay(
                decision, overlay_dir / f"{decision['artifact']}.png"
            )
    except Exception as exc:
        report = {
            "schema": "adaresearch.placement_negotiation_report.v1",
            "source_map": map_name,
            "mode": "composer_dry_run",
            "map_written": False,
            "summary": {"decisions": 0, "accepted": 0, "changed": 0,
                        "rejected": 1, "hard_failures": 1, "soft_compromises": 0},
            "error": str(exc),
            "decisions": [],
        }

    report_path = out_dir / "negotiation_report.json"
    report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    accepted = int(report.get("summary", {}).get("rejected", 1)) == 0
    return accepted, report_path


# ── PNG renderer ──────────────────────────────────────────────────────

def render_png(map_data: dict, out_path: Path, cell_px: int = 24) -> bool:
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        print("  ! Pillow not installed (pip install Pillow) — skipping PNG")
        return False
    structure = map_data["layers"]["structure"]
    utilities = map_data["layers"]["utilities"]
    interact = map_data["layers"]["interactables"]
    rows = len(structure)
    cols = len(structure[0]) if rows else 0
    width = cols * cell_px
    height = rows * cell_px + 40   # legend strip at bottom
    img = Image.new("RGB", (width, height), (16, 18, 22))
    draw = ImageDraw.Draw(img)
    color_for_h = {
        "0": (28, 30, 36),     # void
        "1": (94, 110, 128),    # floor
        "2": (140, 158, 178),   # plinth/step
        "3": (60, 68, 78),      # wall step
        "4": (40, 44, 50),      # tall wall
    }
    try:
        font = ImageFont.truetype("arial.ttf", 11)
        legend_font = ImageFont.truetype("arial.ttf", 12)
    except Exception:
        font = ImageFont.load_default()
        legend_font = font
    for r in range(rows):
        for c in range(cols):
            x0 = c * cell_px
            y0 = r * cell_px
            h = str(structure[r][c])
            color = color_for_h.get(h, (90, 90, 90))
            draw.rectangle([x0, y0, x0 + cell_px - 1, y0 + cell_px - 1], fill=color, outline=(10, 12, 16))
            u = str(utilities[r][c]).strip()
            i = str(interact[r][c]).strip()
            if u == "s":
                draw.ellipse([x0 + 4, y0 + 4, x0 + cell_px - 5, y0 + cell_px - 5],
                             fill=(120, 200, 120), outline=(20, 60, 20))
                draw.text((x0 + cell_px // 2 - 4, y0 + cell_px // 2 - 7),
                          "S", fill=(0, 0, 0), font=font)
            elif u == "t":
                draw.ellipse([x0 + 4, y0 + 4, x0 + cell_px - 5, y0 + cell_px - 5],
                             fill=(200, 160, 90), outline=(80, 50, 0))
                draw.text((x0 + cell_px // 2 - 4, y0 + cell_px // 2 - 7),
                          "T", fill=(0, 0, 0), font=font)
            elif u.startswith("3t:"):
                draw.rectangle([x0 + 6, y0 + 6, x0 + cell_px - 7, y0 + cell_px - 7],
                               outline=(220, 180, 80), width=1)
                draw.text((x0 + 4, y0 + cell_px // 2 - 7), u[3:5],
                          fill=(220, 180, 80), font=font)
            elif u.startswith("tt:"):
                draw.rectangle([x0 + 6, y0 + 6, x0 + cell_px - 7, y0 + cell_px - 7],
                               outline=(180, 220, 220), width=1)
            elif u.startswith("el:"):
                draw.ellipse([x0 + 8, y0 + 8, x0 + cell_px - 9, y0 + cell_px - 9],
                             fill=(255, 240, 130))
            if i:
                # Artifact pip: blue dot at the centre of the cell.
                cx = x0 + cell_px // 2
                cy = y0 + cell_px // 2
                draw.ellipse([cx - 5, cy - 5, cx + 5, cy + 5],
                             fill=(110, 160, 255), outline=(40, 70, 160))
    # Vitrine sub-anchors: small purple pips at fractional offsets from
    # the host anchor. Drawn AFTER the base layers so they sit on top.
    vitrines = map_data.get("map_info", {}).get("metadata", {}).get("vitrines", []) or []
    for v in vitrines:
        for sub in v.get("subs", []) or []:
            sr = float(sub.get("row", 0))
            sc = float(sub.get("col", 0))
            scale = max(0.1, min(0.9, float(sub.get("scale", 0.35))))
            cx = int((sc + 0.5) * cell_px)
            cy = int((sr + 0.5) * cell_px)
            r = int(cell_px * 0.18 * (0.5 + scale))
            draw.ellipse([cx - r, cy - r, cx + r, cy + r],
                         fill=(195, 130, 220), outline=(110, 60, 140))
    # Legend.
    legend_y = rows * cell_px + 4
    legend_items = [
        ("void", color_for_h["0"]),
        ("floor", color_for_h["1"]),
        ("plinth", color_for_h["2"]),
        ("wall step", color_for_h["3"]),
        ("S=spawn",  (120, 200, 120)),
        ("T=teleport", (200, 160, 90)),
        ("artifact", (110, 160, 255)),
        ("3t label", (220, 180, 80)),
        ("vitrine sub", (195, 130, 220)),
    ]
    x = 8
    for name, color in legend_items:
        draw.rectangle([x, legend_y + 6, x + 14, legend_y + 20], fill=color)
        draw.text((x + 18, legend_y + 6), name, fill=(220, 220, 220), font=legend_font)
        x += 110
    img.save(out_path)
    return True


def render_ascii(map_data: dict) -> str:
    structure = map_data["layers"]["structure"]
    utilities = map_data["layers"]["utilities"]
    interact = map_data["layers"]["interactables"]
    char_for_struct = {"0": ".", "1": " ", "2": "P", "3": "#", "4": "W"}
    rows = len(structure)
    cols = len(structure[0]) if rows else 0
    out = []
    for r in range(rows):
        line = []
        for c in range(cols):
            u = str(utilities[r][c]).strip()
            i = str(interact[r][c]).strip()
            if u == "s": ch = "S"
            elif u == "t": ch = "T"
            elif i: ch = "A"
            elif u.startswith("3t:"): ch = "L"
            elif u.startswith("tt:"): ch = "?"
            elif u.startswith("el:"): ch = "*"
            else: ch = char_for_struct.get(str(structure[r][c]), "?")
            line.append(ch)
        out.append("".join(line))
    return "\n".join(out)


# ── Sequence input ────────────────────────────────────────────────────

def rooms_from_sequence(seq_id: str) -> list[tuple[str, list[str]]]:
    """Returns [(map_name, [lookup_name, ...]), ...] for a sequence.

    The project's sequence files list map NAMES; we extract the artifact
    lookups by reading each named map's existing map_data.json and pulling
    unique tokens from its interactables layer."""
    p = SEQUENCES_DIR / f"{seq_id}.json"
    if not p.exists():
        raise FileNotFoundError(f"no sequence: {p}")
    data = json.loads(p.read_text(encoding="utf-8", errors="replace"))
    seqs = data.get("sequences", {})
    if not isinstance(seqs, dict):
        return []
    seq = seqs.get(seq_id) or next(iter(seqs.values()), {})
    map_names = seq.get("maps", [])
    out: list[tuple[str, list[str]]] = []
    for map_name in map_names:
        if not isinstance(map_name, str): continue
        existing = MAPS_DIR / map_name / "map_data.json"
        lookups: list[str] = []
        if existing.exists():
            try:
                md = json.loads(existing.read_text(encoding="utf-8", errors="replace"))
                seen: set[str] = set()
                for row in md.get("layers", {}).get("interactables", []):
                    for cell in row:
                        if not isinstance(cell, str): continue
                        token = cell.strip()
                        if not token or token == " ": continue
                        # Format "<lookup>:<rotation>:<y_offset>" — keep only lookup.
                        lookup = token.split(":", 1)[0]
                        if lookup and lookup not in seen:
                            seen.add(lookup)
                            lookups.append(lookup)
            except Exception as e:
                print(f"  ! could not parse {existing}: {e}")
        if lookups:
            out.append((f"{map_name}_composed", lookups))
        else:
            print(f"  · {map_name}: no artifacts found, skipping")
    return out


# ── CLI ───────────────────────────────────────────────────────────────

def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--name", default="TestComposed", help="output map name (single-map mode)")
    p.add_argument("--rooms", nargs="*", help="dressing-room lookup_names (single-map mode)")
    p.add_argument("--sequence", default="", help="sequence id; composes one map per entry")
    p.add_argument("--show", action="store_true", help="print ASCII preview")
    p.add_argument("--png", action="store_true", help="write a PNG render alongside the JSON")
    p.add_argument("--cell-px", type=int, default=24)
    p.add_argument(
        "--negotiate-dry-run",
        action="store_true",
        help="evaluate placements and write evidence without writing map_data.json",
    )
    p.add_argument(
        "--negotiation-rules",
        type=Path,
        default=REPO / "commons" / "data" / "placement_rules_v1.json",
    )
    p.add_argument(
        "--measurement-report",
        type=Path,
        default=REPO / "ada_run" / "museum_aaa_pass" / "report.json",
    )
    p.add_argument(
        "--negotiation-out",
        type=Path,
        default=REPO / "ada_run" / "composer_negotiation",
    )
    args = p.parse_args()

    targets: list[tuple[str, list[str]]] = []
    if args.sequence:
        targets = rooms_from_sequence(args.sequence)
        print(f"sequence '{args.sequence}': {len(targets)} maps")
    elif args.rooms:
        targets = [(args.name, args.rooms)]
    else:
        p.error("either --rooms or --sequence required")

    exit_code = 0
    for map_name, room_list in targets:
        try:
            out_path, map_data = compose(
                map_name, room_list, write=not args.negotiate_dry_run
            )
        except Exception as e:
            print(f"  ! {map_name}: {e}")
            exit_code = 1
            continue

        if args.negotiate_dry_run:
            accepted, report_path = run_negotiation_dry_run(
                map_name=map_name,
                map_data=map_data,
                rules_path=args.negotiation_rules,
                measurement_report_path=args.measurement_report,
                output_root=args.negotiation_out,
            )
            verdict = "ACCEPTED" if accepted else "REJECTED"
            print(
                f"dry-run {verdict}: {report_path.relative_to(REPO)}  "
                f"({len(room_list)} rooms; map not written)"
            )
            if not accepted:
                exit_code = 1
        else:
            print(f"wrote {out_path.relative_to(REPO)}  ({len(room_list)} rooms)")

        if args.show:
            print(render_ascii(map_data))
        if args.png:
            if args.negotiate_dry_run:
                png_path = report_path.parent / "candidate_map.png"
            else:
                png_path = out_path.with_suffix(".png")
            if render_png(map_data, png_path, cell_px=args.cell_px):
                print(f"  png:  {png_path.relative_to(REPO)}")
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
