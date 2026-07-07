"""tools/generate_archetype_maps_2.py — 10 MORE archetypes beyond the first set.

Continues the structural-archetype catalogue. Where the first 10 (promenade,
pit, ziggurat, dungeon, cathedral, amphitheater, spiral, hub_spokes, atrium,
crossroads) covered the canonical architectural / level-design forms, these
10 push into less obvious territory:

  11. FORUM         — open flat plaza with peripheral pillars (gathering ground)
  12. BRIDGE        — long narrow walkway over void
  13. TOWER         — concentric stacked-height squares (visible verticality)
  14. MAZE          — winding corridors with dead-ends
  15. STACKS        — parallel narrow aisles (library / archive)
  16. CAVE          — irregular organic carved-out space
  17. THEATER       — rectangular audience facing a raised stage
  18. QUADRANTS     — four sealed sections joined only at the centre
  19. CITADEL       — concentric defensive rings with moat
  20. CONSTELLATION — scattered raised platforms connected by paths (no walls)

Run:
  python tools/generate_archetype_maps_2.py
"""
from __future__ import annotations

import json
import math
import random
import sys
from pathlib import Path
from typing import Callable

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
MAPS_DIR = ROOT / "commons" / "maps"

VOID = "0"; FLOOR_LOW = "1"; FLOOR = "2"; TABLE = "3"; HALF_WALL = "4"; WALL = "5"

PLACEHOLDERS = {
    "centerpiece":   "library_rack",
    "wall_display":  "science_screen",
    "small_inter":   "xyz_slider_plate",
    "point":         "point",
    "sphere":        "dark_sphere",
    "puzzle":        "snap_pyramid_puzzle",
    "catalyst":      "catalyst_target",
    "wedge":         "wedge_skill_pickup",
    "frame":         "bigframe",
    "totem":         "totem",
}


def empty_layers(w: int, d: int) -> tuple[list, list, list]:
    return (
        [[VOID] * w for _ in range(d)],
        [[" "] * w for _ in range(d)],
        [[" "] * w for _ in range(d)],
    )


def place(inter: list, r: int, c: int, kind: str, rot: int = 0) -> None:
    name = PLACEHOLDERS.get(kind, kind)
    inter[r][c] = f"{name}:{rot}:0.0"


# ─────────────────────────────────────────────────────────────────────
# 11. FORUM — open flat plaza, peripheral pillars
# ─────────────────────────────────────────────────────────────────────

def make_forum() -> dict:
    W, D = 25, 25
    struct, util, inter = empty_layers(W, D)
    # All floor (open plaza)
    for r in range(D):
        for c in range(W):
            struct[r][c] = FLOOR
    # Peripheral pillars at regular intervals
    pillar_positions = []
    for c in range(2, W - 2, 4):
        pillar_positions.append((1, c))
        pillar_positions.append((D - 2, c))
    for r in range(2, D - 2, 4):
        pillar_positions.append((r, 1))
        pillar_positions.append((r, W - 2))
    for (pr, pc) in pillar_positions:
        struct[pr][pc] = HALF_WALL    # pillar h=3
    # Slightly raised central rostrum
    cx, cy = W // 2, D // 2
    for r in range(cy - 1, cy + 2):
        for c in range(cx - 1, cx + 2):
            struct[r][c] = TABLE
    # Spawn at one corner, teleporter at the opposite
    util[D - 2][1] = "sp"
    util[1][W - 2] = "t"
    # Centerpiece on the rostrum
    place(inter, cy, cx, "centerpiece", rot=180)
    # Scattered satellites around the plaza
    for (r, c) in [(cy - 4, cx - 4), (cy - 4, cx + 4), (cy + 4, cx - 4), (cy + 4, cx + 4),
                    (cy - 7, cx), (cy + 7, cx), (cy, cx - 7), (cy, cx + 7)]:
        if 0 <= r < D and 0 <= c < W:
            place(inter, r, c, "small_inter", rot=180)
    return {"name": "Forum", "subtitle": "open flat plaza with peripheral pillars",
            "W": W, "D": D, "struct": struct, "util": util, "inter": inter}


# ─────────────────────────────────────────────────────────────────────
# 12. BRIDGE — long narrow walkway over void
# ─────────────────────────────────────────────────────────────────────

def make_bridge() -> dict:
    W, D = 9, 35
    struct, util, inter = empty_layers(W, D)
    # All void
    # Carve a 3-wide bridge down the centre
    spine = W // 2
    for r in range(D):
        for c in range(spine - 1, spine + 2):
            struct[r][c] = FLOOR
    # Side platforms (paired) at three points along the bridge for artifacts
    for r in (5, D // 2, D - 6):
        struct[r][spine - 3] = TABLE
        struct[r][spine - 2] = FLOOR
        struct[r][spine + 2] = FLOOR
        struct[r][spine + 3] = TABLE
    # Connectors making the side platforms reachable
    # Anchor end-platforms a bit wider
    for r in (0, 1, D - 2, D - 1):
        for c in range(spine - 3, spine + 4):
            if 0 <= c < W:
                struct[r][c] = FLOOR
    # Spawn at south end, teleporter at north end
    util[D - 1][spine] = "sp"
    util[0][spine] = "t"
    # Centerpiece mid-bridge
    place(inter, D // 2, spine, "centerpiece", rot=180)
    # Paired side artifacts at the three platform points
    for r in (5, D // 2, D - 6):
        place(inter, r, spine - 3, "wall_display", rot=90)
        place(inter, r, spine + 3, "wall_display", rot=270)
    return {"name": "Bridge", "subtitle": "long narrow walkway over void",
            "W": W, "D": D, "struct": struct, "util": util, "inter": inter}


# ─────────────────────────────────────────────────────────────────────
# 13. TOWER — concentric stacked-height squares (verticality)
# ─────────────────────────────────────────────────────────────────────

def make_tower() -> dict:
    W, D = 21, 21
    struct, util, inter = empty_layers(W, D)
    # Concentric rings ascending in height toward the centre, but with
    # a STAIRCASE carved through to the top
    cx, cy = W // 2, D // 2
    for r in range(D):
        for c in range(W):
            d_edge = min(r, c, D - 1 - r, W - 1 - c)
            if d_edge < 2:
                struct[r][c] = FLOOR        # outer plaza
            elif d_edge < 4:
                struct[r][c] = TABLE        # h=2 mid-ring
            elif d_edge < 6:
                struct[r][c] = HALF_WALL    # h=3 inner-ring
            elif d_edge < 8:
                struct[r][c] = WALL         # h=4 tower base
            else:
                struct[r][c] = WALL         # h=4 core
    # Carve a staircase from outer plaza to the top — straight north channel
    for r in range(2, cy + 1):
        struct[r][cx] = FLOOR if r > cy - 3 else TABLE
    # Carve top observation platform — small flat area on top
    for r in range(cy - 1, cy + 2):
        for c in range(cx - 1, cx + 2):
            struct[r][c] = TABLE
    # Spawn at south outer plaza, teleporter at observation top
    util[D - 2][cx] = "sp"
    util[cy][cx] = "t"
    # Top artifact: centerpiece on the observation platform
    place(inter, cy - 1, cx, "centerpiece", rot=180)
    # Cardinal mid-ring artifacts
    place(inter, 3, cx, "totem", rot=180)
    place(inter, cy, 3, "totem", rot=90)
    place(inter, cy, W - 4, "totem", rot=270)
    place(inter, D - 4, cx + 4, "wall_display", rot=180)
    place(inter, D - 4, cx - 4, "wall_display", rot=180)
    return {"name": "Tower", "subtitle": "concentric stacked-height tower with stair to top",
            "W": W, "D": D, "struct": struct, "util": util, "inter": inter}


# ─────────────────────────────────────────────────────────────────────
# 14. MAZE — winding corridors with dead-ends
# ─────────────────────────────────────────────────────────────────────

def make_maze() -> dict:
    W, D = 23, 23
    struct, util, inter = empty_layers(W, D)
    # All walls
    for r in range(D):
        for c in range(W):
            struct[r][c] = WALL

    # Generate maze via recursive backtracker on a coarse grid (cells of 2x2)
    rng = random.Random(42)
    cw = (W - 1) // 2   # number of cells horizontally
    ch = (D - 1) // 2
    visited = [[False] * cw for _ in range(ch)]

    def carve(cr: int, cc: int) -> None:
        visited[cr][cc] = True
        # Convert cell coords to grid coords
        r = cr * 2 + 1
        c = cc * 2 + 1
        struct[r][c] = FLOOR
        dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)]
        rng.shuffle(dirs)
        for dr, dc in dirs:
            nr, nc = cr + dr, cc + dc
            if 0 <= nr < ch and 0 <= nc < cw and not visited[nr][nc]:
                # Carve wall between (cr,cc) and (nr,nc)
                wall_r = r + dr
                wall_c = c + dc
                struct[wall_r][wall_c] = FLOOR
                carve(nr, nc)

    carve(0, 0)
    # Spawn at maze entry (0,0 cell), teleporter at far corner
    util[1][1] = "sp"
    util[ch * 2 - 1][cw * 2 - 1] = "t"
    # Place some artifacts at distinctive dead-ends (high-coordinate corners)
    place(inter, ch * 2 - 1, cw * 2 - 1, "centerpiece", rot=180)
    place(inter, 1, cw * 2 - 1, "puzzle", rot=270)
    place(inter, ch * 2 - 1, 1, "puzzle", rot=90)
    place(inter, ch, cw, "wall_display", rot=180)
    return {"name": "Maze", "subtitle": "winding corridors with dead-ends",
            "W": W, "D": D, "struct": struct, "util": util, "inter": inter}


# ─────────────────────────────────────────────────────────────────────
# 15. STACKS — parallel narrow aisles (library)
# ─────────────────────────────────────────────────────────────────────

def make_stacks() -> dict:
    W, D = 23, 19
    struct, util, inter = empty_layers(W, D)
    # All wall first
    for r in range(D):
        for c in range(W):
            struct[r][c] = WALL
    # Parallel aisles: floors at every odd column
    for c in range(1, W, 2):
        for r in range(1, D - 1):
            struct[r][c] = FLOOR
    # Crossing corridor at top and bottom
    for c in range(1, W - 1):
        struct[1][c] = FLOOR
        struct[D - 2][c] = FLOOR
    # Stack shelves — TABLE platforms in the even columns
    for c in range(2, W - 1, 2):
        for r in range(2, D - 2):
            struct[r][c] = TABLE
    # Spawn at bottom-left aisle, teleporter at top-right aisle
    util[D - 2][1] = "sp"
    util[1][W - 2] = "t"
    # Artifacts on shelves (TABLE cells) — like books displayed
    aisle_cols = list(range(1, W, 2))   # walkable columns
    shelf_cols = list(range(2, W - 1, 2))
    for i, sc in enumerate(shelf_cols[:5]):
        # One artifact per shelf at varied row
        target_r = 3 + i * 3
        if target_r < D - 2:
            kind = ["wall_display", "puzzle", "frame", "wedge", "totem"][i % 5]
            place(inter, target_r, sc, kind, rot=90 if i % 2 == 0 else 270)
    return {"name": "Stacks", "subtitle": "parallel aisles flanked by tall shelves",
            "W": W, "D": D, "struct": struct, "util": util, "inter": inter}


# ─────────────────────────────────────────────────────────────────────
# 16. CAVE — irregular organic carved-out space (cellular automata)
# ─────────────────────────────────────────────────────────────────────

def make_cave() -> dict:
    W, D = 25, 25
    rng = random.Random(7)
    # Initialise random fill (each cell 45% wall)
    grid = [[WALL if rng.random() < 0.45 else FLOOR for _ in range(W)] for _ in range(D)]
    # Border always wall
    for r in range(D):
        grid[r][0] = WALL; grid[r][W - 1] = WALL
    for c in range(W):
        grid[0][c] = WALL; grid[D - 1][c] = WALL

    # CA smoothing — 5 iterations
    for _ in range(5):
        new_grid = [row[:] for row in grid]
        for r in range(1, D - 1):
            for c in range(1, W - 1):
                walls = 0
                for dr in (-1, 0, 1):
                    for dc in (-1, 0, 1):
                        if dr == 0 and dc == 0: continue
                        if grid[r + dr][c + dc] == WALL: walls += 1
                if walls >= 5:
                    new_grid[r][c] = WALL
                elif walls <= 2:
                    new_grid[r][c] = FLOOR
        grid = new_grid

    # Make sure the centre is floor (so we can place things)
    cx, cy = W // 2, D // 2
    for r in range(cy - 2, cy + 3):
        for c in range(cx - 2, cx + 3):
            grid[r][c] = FLOOR

    struct = grid
    util = [[" "] * W for _ in range(D)]
    inter = [[" "] * W for _ in range(D)]
    # Find a spawn cell: top-left-ish floor
    sp_placed = False
    for r in range(1, D // 2):
        for c in range(1, W // 2):
            if grid[r][c] == FLOOR:
                util[r][c] = "sp"
                sp_placed = True
                break
        if sp_placed: break
    # Teleporter at the centre (organic cavity)
    util[cy][cx] = "t"
    # Centerpiece near the centre
    place(inter, cy - 1, cx, "centerpiece", rot=180)
    # Scatter satellites in floor cells far from the centre
    candidates = []
    for r in range(1, D - 1):
        for c in range(1, W - 1):
            if grid[r][c] == FLOOR:
                dist = math.hypot(r - cy, c - cx)
                if 5 < dist < 9:
                    candidates.append((r, c, dist))
    candidates.sort(key=lambda x: -x[2])
    for i, (r, c, _) in enumerate(candidates[:5]):
        kind = ["sphere", "wedge", "small_inter", "puzzle", "frame"][i]
        place(inter, r, c, kind, rot=rng.choice([0, 90, 180, 270]))
    return {"name": "Cave", "subtitle": "irregular organic carved space (cellular automaton)",
            "W": W, "D": D, "struct": struct, "util": util, "inter": inter}


# ─────────────────────────────────────────────────────────────────────
# 17. THEATER — rectangular audience facing a raised stage
# ─────────────────────────────────────────────────────────────────────

def make_theater() -> dict:
    W, D = 21, 21
    struct, util, inter = empty_layers(W, D)
    # All void initially; carve a rectangular theater
    # Audience area: rows 6..D-2, cols 2..W-3 — floor
    for r in range(6, D - 1):
        for c in range(2, W - 2):
            struct[r][c] = FLOOR
    # Tiered audience platforms (every 3rd row gets a raised step)
    for r in range(8, D - 1, 3):
        for c in range(2, W - 2):
            struct[r][c] = TABLE
    # Stage at front: raised platform spanning the width
    for c in range(2, W - 2):
        for r in range(2, 5):
            struct[r][c] = TABLE
    # Stage front edge slightly higher (proscenium)
    for c in (2, W - 3):
        for r in range(2, 5):
            struct[r][c] = HALF_WALL
    # Back wall to audience
    for c in range(2, W - 2):
        struct[D - 1][c] = WALL
    # Side walls
    for r in range(2, D):
        struct[r][1] = WALL
        struct[r][W - 2] = WALL
    # Spawn at back-row centre, teleporter on stage centre
    util[D - 2][W // 2] = "sp"
    util[3][W // 2] = "t"
    # Stage centerpiece (the performer / focal artifact)
    place(inter, 3, W // 2, "centerpiece", rot=180)
    # Stage flanking elements
    place(inter, 3, W // 2 - 4, "totem", rot=180)
    place(inter, 3, W // 2 + 4, "totem", rot=180)
    # Audience markers (interactive seats)
    for r in (8, 11, 14):
        place(inter, r, W // 2 - 3, "small_inter", rot=0)
        place(inter, r, W // 2 + 3, "small_inter", rot=0)
    return {"name": "Theater", "subtitle": "rectangular audience facing raised stage",
            "W": W, "D": D, "struct": struct, "util": util, "inter": inter}


# ─────────────────────────────────────────────────────────────────────
# 18. QUADRANTS — four sealed sections joined only at the centre
# ─────────────────────────────────────────────────────────────────────

def make_quadrants() -> dict:
    W, D = 23, 23
    struct, util, inter = empty_layers(W, D)
    # Floor everywhere except a + cross of walls
    for r in range(D):
        for c in range(W):
            struct[r][c] = FLOOR
    cx, cy = W // 2, D // 2
    # Cross-walls dividing into 4 quadrants
    for r in range(D):
        struct[r][cx] = WALL
    for c in range(W):
        struct[cy][c] = WALL
    # Outer wall
    for r in range(D):
        struct[r][0] = WALL; struct[r][W - 1] = WALL
    for c in range(W):
        struct[0][c] = WALL; struct[D - 1][c] = WALL
    # Central crossing chamber (3×3 floor in the middle)
    for r in range(cy - 1, cy + 2):
        for c in range(cx - 1, cx + 2):
            struct[r][c] = TABLE
    # Doorways from each quadrant into the central chamber
    struct[cy][cx - 2] = FLOOR
    struct[cy][cx + 2] = FLOOR
    struct[cy - 2][cx] = FLOOR
    struct[cy + 2][cx] = FLOOR
    # Spawn in NW quadrant; teleporter in SE quadrant
    util[3][3] = "sp"
    util[D - 4][W - 4] = "t"
    # Centerpiece at central chamber
    place(inter, cy, cx, "centerpiece", rot=180)
    # One quadrant artifact each (themed)
    place(inter, 4, 4, "wall_display", rot=180)            # NW
    place(inter, 4, W - 5, "puzzle", rot=180)              # NE
    place(inter, D - 5, 4, "wedge", rot=0)                 # SW
    place(inter, D - 5, W - 5, "frame", rot=0)             # SE
    # Bridge artifacts at the doorways
    place(inter, cy - 3, cx, "small_inter", rot=180)
    place(inter, cy + 3, cx, "small_inter", rot=180)
    return {"name": "Quadrants", "subtitle": "four sealed sections joined at the centre",
            "W": W, "D": D, "struct": struct, "util": util, "inter": inter}


# ─────────────────────────────────────────────────────────────────────
# 19. CITADEL — concentric defensive rings with moat
# ─────────────────────────────────────────────────────────────────────

def make_citadel() -> dict:
    W, D = 23, 23
    struct, util, inter = empty_layers(W, D)
    cx, cy = W // 2, D // 2
    for r in range(D):
        for c in range(W):
            d_edge = min(r, c, D - 1 - r, W - 1 - c)
            if d_edge == 0:
                struct[r][c] = WALL          # outer wall
            elif d_edge in (1, 2):
                struct[r][c] = FLOOR         # outer ward
            elif d_edge == 3:
                struct[r][c] = VOID          # MOAT (void/water)
            elif d_edge == 4:
                struct[r][c] = WALL          # middle wall
            elif d_edge in (5, 6):
                struct[r][c] = FLOOR         # inner ward
            elif d_edge == 7:
                struct[r][c] = HALF_WALL     # keep wall
            else:
                struct[r][c] = WALL          # keep base
    # Carve a small keep interior (h=2 floor inside the centre)
    for r in range(cy - 1, cy + 2):
        for c in range(cx - 1, cx + 2):
            struct[r][c] = TABLE
    # Bridges over the moat (cardinal)
    # Moat is at d_edge==3. To bridge, carve floor at moat cell on cardinal lines.
    for (mr, mc) in [(3, cx), (D - 4, cx), (cy, 3), (cy, W - 4)]:
        struct[mr][mc] = FLOOR
    # Doorway through middle wall on south
    struct[4][cx] = FLOOR
    struct[D - 5][cx] = FLOOR
    struct[cy][4] = FLOOR
    struct[cy][W - 5] = FLOOR
    # Doorway through keep wall on south
    struct[7][cx] = FLOOR
    struct[D - 8][cx] = FLOOR
    # Spawn at outer ward south, teleporter at keep centre
    util[D - 2][cx] = "sp"
    util[cy][cx] = "t"
    # Keep centerpiece
    place(inter, cy, cx, "centerpiece", rot=180)
    # Outer ward gate artifacts
    place(inter, D - 3, cx, "wall_display", rot=180)
    place(inter, 2, cx, "wall_display", rot=0)
    # Inner ward markers
    place(inter, cy, 5, "totem", rot=90)
    place(inter, cy, W - 6, "totem", rot=270)
    place(inter, 5, cx + 3, "small_inter", rot=180)
    place(inter, D - 6, cx - 3, "small_inter", rot=0)
    return {"name": "Citadel", "subtitle": "concentric defensive rings with moat",
            "W": W, "D": D, "struct": struct, "util": util, "inter": inter}


# ─────────────────────────────────────────────────────────────────────
# 20. CONSTELLATION — scattered raised platforms connected by paths
# ─────────────────────────────────────────────────────────────────────

def make_constellation() -> dict:
    W, D = 23, 23
    struct, util, inter = empty_layers(W, D)
    # All open floor
    for r in range(D):
        for c in range(W):
            struct[r][c] = FLOOR
    # Pick 6 "star" positions
    star_positions = [
        (3, 5), (4, W - 5),
        (D // 2 - 2, 4), (D // 2, W // 2),
        (D - 6, W // 2 - 4), (D - 4, W - 4),
    ]
    # Each star: a raised 2×2 platform (TABLE = h=2)
    for (sr, sc) in star_positions:
        for r in range(sr - 1, sr + 1):
            for c in range(sc - 1, sc + 1):
                if 0 <= r < D and 0 <= c < W:
                    struct[r][c] = TABLE
    # Outer border — no wall, just edge-of-platform (negative space beyond)
    # Actually leave the outer 1-row as VOID for the "constellation" effect
    for r in range(D):
        struct[r][0] = VOID
        struct[r][W - 1] = VOID
    for c in range(W):
        struct[0][c] = VOID
        struct[D - 1][c] = VOID

    # Spawn at one star, teleporter at the central star
    util[3][5] = "sp"
    util[D // 2][W // 2] = "t"
    # Place a small interactive on each star platform
    star_kinds = ["wall_display", "puzzle", "wedge", "centerpiece", "frame", "totem"]
    for i, (sr, sc) in enumerate(star_positions):
        place(inter, sr, sc, star_kinds[i], rot=180)
    # Small markers along the implicit paths (the empty floor between stars)
    place(inter, 7, 10, "point", rot=180)
    place(inter, 14, 14, "point", rot=180)
    place(inter, 10, 17, "point", rot=180)
    return {"name": "Constellation", "subtitle": "scattered raised platforms connected by open floor",
            "W": W, "D": D, "struct": struct, "util": util, "inter": inter}


# ─────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────

ARCHETYPES: list[Callable[[], dict]] = [
    make_forum, make_bridge, make_tower, make_maze, make_stacks,
    make_cave, make_theater, make_quadrants, make_citadel, make_constellation,
]


def write_map(result: dict) -> Path:
    map_name = f"Archetype_{result['name']}"
    out_dir = MAPS_DIR / map_name
    out_dir.mkdir(exist_ok=True)
    struct = result["struct"]; util = result["util"]; inter = result["inter"]
    W, D = result["W"], result["D"]

    map_data = {
        "map_info": {
            "name":         map_name,
            "lookup_name":  map_name,
            "description":  f"Archetype demonstration map (set 2 of 2) — {result['subtitle']}. "
                            f"Generated by tools/generate_archetype_maps_2.py to extend the "
                            f"structural archetype catalogue.",
            "version":      "archetype-0.2",
            "format":       "json",
            "created_from": "tools/generate_archetype_maps_2.py 2026-05-16",
            "dimensions":   {"width": W, "depth": D, "max_height": 5},
            "metadata":     {
                "category":  "archetype_demo",
                "archetype": result["name"].lower(),
                "estimated_time": "2-4 minutes",
                "subtitle":  result["subtitle"],
            },
            "title":        f"Archetype: {result['name']}",
        },
        "utility_definitions": {
            "sp": {"name": "Spawn", "description": "Player spawn point", "type": "spawn"},
            "t":  {"name": "Exit Portal",
                   "description": "Step here to leave",
                   "type": "teleporter",
                   "properties": {"action": "next_in_sequence"}},
        },
        "documentation": {
            "summary":  f"Archetype_{result['name']} — {result['subtitle']}",
            "layout":   f"{W}×{D} bounding box. Demonstrates the '{result['name'].lower()}' archetype.",
            "objective": "Walk the archetype. The shape is the lesson.",
            "key_elements": [
                "Spawn at archetype-appropriate entry",
                "Teleporter at archetype-appropriate exit",
                "Placeholder artifacts marking compositional roles",
            ],
        },
        "lighting": {
            "ambient_color": [0.30, 0.32, 0.40],
            "ambient_energy": 0.9,
            "directional_light": {"enabled": True, "direction": [-0.3, -1.0, -0.2], "energy": 0.7},
        },
        "settings": {"player_spawn_height": 0.5, "floor_tile_size": 1.0},
        "layers": {"structure": struct, "utilities": util, "interactables": inter},
    }

    with open(out_dir / "map_data.json", "w", encoding="utf-8") as f:
        json.dump(map_data, f, indent="\t")

    intent_lines = [
        f"Concept: A {result['subtitle']}. One of 10 archetypes in set 2 (continuation of the structural catalogue).",
        "",
        f"Actualizes: The {result['name'].lower()} archetype — a less-canonical spatial pattern that nonetheless carries distinctive teaching affordances.",
        "",
        "Sequence role: Not curriculum content. Reference geometry. Walking it reveals which forms feel right for what kinds of content.",
        "",
        f"Technical angle: {W}×{D} cells. Structure uses height codes 0-5. Interactables at compositional roles using registered placeholder artifacts.",
        "",
        "Critical angle: Each archetype proposes a different relationship between space, motion, and attention. Walking ten of them produces a vocabulary; walking twenty produces a fluency.",
        "",
        "Key artifacts:",
        f"- Placeholders: library_rack (centerpiece), science_screen (wall display), various interactive primitives.",
        "",
        "Gap: Reference geometry only; curriculum-specific artifacts replace placeholders once a real content match is identified.",
    ]
    (out_dir / "intent.md").write_text("\n".join(intent_lines), encoding="utf-8")
    (out_dir / "blurb.md").write_text(
        f"{result['subtitle'].capitalize()}. Walk the {result['name'].lower()} archetype.\n\n"
        f"Set 2 of 2 — completing the 20-archetype catalogue. Placeholder artifacts mark "
        f"compositional roles; the form is the point.\n",
        encoding="utf-8",
    )
    return out_dir / "map_data.json"


def main():
    print(f"generating 10 MORE archetype maps (set 2 of 2)...")
    print()
    for fn in ARCHETYPES:
        r = fn()
        path = write_map(r)
        n_inter = sum(1 for row in r["inter"] for c in row if c.strip())
        print(f"  ✓ Archetype_{r['name']:14}  {r['W']:2}×{r['D']:2}  {n_inter:>2} placeholders  →  {path.relative_to(ROOT)}")
    print()
    print(f"20 archetypes total now live in commons/maps/Archetype_*/")


if __name__ == "__main__":
    main()
