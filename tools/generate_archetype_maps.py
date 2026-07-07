"""tools/generate_archetype_maps.py — 10 large maps in distinct structural archetypes.

The placement strategies (16 of them) optimise WHERE artifacts go inside an
existing room. This tool generates the ROOMS themselves, in 10 archetypal
shapes drawn from architecture + game level design + classical building forms.

Each map is "big" (20-32 cells per axis), with placeholder artifacts that show
the SPATIAL ROLES (centerpiece, wall-display, cluster, satellites). Names use
real registered artifacts (science_screen, library_rack, etc.) so the maps
walk in Godot.

The 10 archetypes:
  1.  PROMENADE         — long axial walk (control / Mario-like)
  2.  PIT               — sunken arena, raised border walls
  3.  ZIGGURAT          — stepped pyramid ascending to apex
  4.  DUNGEON           — branching corridors + small chambers
  5.  CATHEDRAL         — cruciform nave + transept + apse
  6.  AMPHITHEATER      — circular tiered rings around central focus
  7.  SPIRAL            — labyrinth winding inward
  8.  HUB_SPOKES        — central plaza + radial corridors
  9.  ATRIUM            — peripheral rooms surrounding central courtyard
  10. CROSSROADS        — two corridors crossing perpendicularly

Run:
  python tools/generate_archetype_maps.py
Output: commons/maps/Archetype_<Name>/{map_data.json, intent.md, blurb.md}
"""
from __future__ import annotations

import json
import math
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

# Structure codes (height layers)
VOID = "0"        # empty cell
FLOOR_LOW = "1"   # h=0.5 (sunken)
FLOOR = "2"       # h=1 (standard walkable)
TABLE = "3"       # h=2 (raised platform / step)
HALF_WALL = "4"   # h=3
WALL = "5"        # h=4 (full wall)

# Common placeholder artifacts (real registered names; they'll render in Godot)
PLACEHOLDERS = {
    "centerpiece":   "library_rack",          # large display
    "wall_display":  "science_screen",         # information panel
    "small_inter":   "xyz_slider_plate",       # small interactive
    "point":         "point",                  # tiny marker
    "sphere":        "dark_sphere",            # decorative
    "puzzle":        "snap_pyramid_puzzle",    # interactive puzzle
    "catalyst":      "catalyst_target",        # target object
    "wedge":         "wedge_skill_pickup",     # pickup
    "frame":         "bigframe",               # framing element
    "totem":         "totem",                  # vertical accent
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
# 1. PROMENADE
# ─────────────────────────────────────────────────────────────────────

def make_promenade() -> dict:
    W, D = 9, 32
    struct, util, inter = empty_layers(W, D)
    # Floor everywhere
    for r in range(D):
        for c in range(W):
            struct[r][c] = FLOOR
    # Spawn at south, teleporter at north
    util[D - 1][W // 2] = "sp"
    util[0][W // 2] = "t"
    # Spine artifacts at paced intervals
    beats = [(D - 4, "small_inter"), (D - 9, "wall_display"),
             (D - 14, "centerpiece"), (D - 19, "wall_display"),
             (D - 24, "small_inter"), (3, "point")]
    for r, k in beats:
        place(inter, r, W // 2, k, rot=180)
    # Paired side artifacts at one beat
    place(inter, D - 14, W // 2 - 2, "frame", rot=90)
    place(inter, D - 14, W // 2 + 2, "frame", rot=270)
    return {"name": "Promenade", "subtitle": "long axial walk",
            "W": W, "D": D, "struct": struct, "util": util, "inter": inter}


# ─────────────────────────────────────────────────────────────────────
# 2. PIT — sunken arena bounded by raised walls
# ─────────────────────────────────────────────────────────────────────

def make_pit() -> dict:
    W, D = 21, 27
    struct, util, inter = empty_layers(W, D)
    # Wall border h=4
    for r in range(D):
        for c in range(W):
            if r == 0 or r == D - 1 or c == 0 or c == W - 1:
                struct[r][c] = WALL
            else:
                struct[r][c] = FLOOR
    # Inner tier: raised step (h=2) one row inside
    for r in range(1, D - 1):
        for c in range(1, W - 1):
            if r == 1 or r == D - 2 or c == 1 or c == W - 2:
                struct[r][c] = TABLE
    # Central sunken pit (h=0.5) in the middle
    cx, cy = W // 2, D // 2
    pit_r0, pit_r1 = cy - 4, cy + 4
    pit_c0, pit_c1 = cx - 5, cx + 5
    for r in range(pit_r0, pit_r1 + 1):
        for c in range(pit_c0, pit_c1 + 1):
            struct[r][c] = FLOOR_LOW
    # Stair down from north entry
    util[2][cx] = "sp"
    util[D - 3][cx] = "t"
    # Place artifacts: centerpiece deep in pit, satellites on tiers
    place(inter, cy, cx, "centerpiece", rot=180)
    place(inter, pit_r0, cx - 3, "wedge", rot=180)
    place(inter, pit_r0, cx + 3, "wedge", rot=180)
    place(inter, pit_r1, cx - 3, "wedge", rot=0)
    place(inter, pit_r1, cx + 3, "wedge", rot=0)
    # Tier displays on the raised step
    place(inter, 3, 3, "wall_display", rot=90)
    place(inter, 3, W - 4, "wall_display", rot=270)
    place(inter, D - 4, 3, "wall_display", rot=90)
    place(inter, D - 4, W - 4, "wall_display", rot=270)
    return {"name": "Pit", "subtitle": "sunken arena with raised border",
            "W": W, "D": D, "struct": struct, "util": util, "inter": inter}


# ─────────────────────────────────────────────────────────────────────
# 3. ZIGGURAT — stepped pyramid
# ─────────────────────────────────────────────────────────────────────

def make_ziggurat() -> dict:
    W, D = 21, 21
    struct, util, inter = empty_layers(W, D)
    # Concentric ascending squares
    layers = [(0, FLOOR), (2, TABLE), (4, HALF_WALL), (6, WALL)]
    for r in range(D):
        for c in range(W):
            # Distance from edge
            d_edge = min(r, c, D - 1 - r, W - 1 - c)
            # Pick the layer
            code = FLOOR
            for thresh, lcode in layers:
                if d_edge >= thresh:
                    code = lcode
            struct[r][c] = code
    # The apex is fully walled = inaccessible top step. Carve top into a small floor.
    cx, cy = W // 2, D // 2
    for r in range(cy - 1, cy + 2):
        for c in range(cx - 1, cx + 2):
            struct[r][c] = TABLE   # top platform = h=2 (player can stand on summit)
    # Single column from south edge giving stair access up — carve a strip
    for r in range(cy, D - 1):
        struct[r][cx] = FLOOR    # walking ramp up
    # Actually for player progression, we should carve a single SPIRAL stair.
    # Simpler: keep terraced; player walks UP the steps via path on south side.
    # Spawn at south edge, teleporter at apex
    util[D - 1][cx] = "sp"
    util[cy][cx] = "t"
    # Apex centerpiece
    place(inter, cy - 1, cx, "centerpiece", rot=180)
    # Cardinal terrace artifacts
    place(inter, cy, 3, "totem", rot=90)
    place(inter, cy, W - 4, "totem", rot=270)
    place(inter, 3, cx, "totem", rot=180)
    # Stair displays
    place(inter, cy + 3, cx + 3, "wall_display", rot=180)
    place(inter, cy + 3, cx - 3, "wall_display", rot=180)
    return {"name": "Ziggurat", "subtitle": "stepped pyramid ascending to apex",
            "W": W, "D": D, "struct": struct, "util": util, "inter": inter}


# ─────────────────────────────────────────────────────────────────────
# 4. DUNGEON — chambers connected by corridors
# ─────────────────────────────────────────────────────────────────────

def make_dungeon() -> dict:
    W, D = 27, 27
    struct, util, inter = empty_layers(W, D)
    # All walls
    for r in range(D):
        for c in range(W):
            struct[r][c] = WALL
    # 6 chambers: 4 corners + 2 mid-axial
    chambers = [
        (2, 2, 7, 7),         # NW
        (2, W - 8, 7, W - 2), # NE
        (D - 8, 2, D - 2, 7), # SW
        (D - 8, W - 8, D - 2, W - 2), # SE
        (10, 10, 16, 16),     # central
        (D - 8, W // 2 - 3, D - 2, W // 2 + 3),  # south
    ]
    for r0, c0, r1, c1 in chambers:
        for r in range(r0, r1 + 1):
            for c in range(c0, c1 + 1):
                struct[r][c] = FLOOR
    # Corridors between chambers (1-cell wide)
    def corridor(r0, c0, r1, c1):
        for r in range(min(r0, r1), max(r0, r1) + 1):
            struct[r][c0] = FLOOR
        for c in range(min(c0, c1), max(c0, c1) + 1):
            struct[r1][c] = FLOOR
    # NW → central
    corridor(5, 7, 13, 10)
    # NE → central
    corridor(5, W - 8, 13, 16)
    # central → SW
    corridor(16, 13, D - 5, 4)
    # central → SE
    corridor(16, 16, D - 5, W - 4)
    # central → south
    corridor(16, 13, D - 5, W // 2)
    # Spawn in NW chamber, teleporter in central
    util[5][5] = "sp"
    util[13][13] = "t"
    # Artifacts: one centerpiece in central, one per peripheral chamber
    place(inter, 13, 13, "centerpiece", rot=180)
    place(inter, 5, 5, "point", rot=180)
    place(inter, 5, W - 5, "wall_display", rot=270)
    place(inter, D - 5, 5, "puzzle", rot=90)
    place(inter, D - 5, W - 5, "wedge", rot=0)
    place(inter, D - 5, W // 2, "sphere", rot=180)
    return {"name": "Dungeon", "subtitle": "branching chambers + corridors",
            "W": W, "D": D, "struct": struct, "util": util, "inter": inter}


# ─────────────────────────────────────────────────────────────────────
# 5. CATHEDRAL — cruciform: nave + transept + apse
# ─────────────────────────────────────────────────────────────────────

def make_cathedral() -> dict:
    W, D = 15, 30
    struct, util, inter = empty_layers(W, D)
    # All void initially
    # Nave: 3-cell central column the full length
    nave_cl, nave_cr = W // 2 - 1, W // 2 + 1
    for r in range(D):
        for c in range(nave_cl, nave_cr + 1):
            struct[r][c] = FLOOR
    # Side aisles: 1-cell on each side, ⅔ of the way
    aisle_end = int(D * 0.85)
    for r in range(2, aisle_end):
        struct[r][nave_cl - 1] = FLOOR
        struct[r][nave_cr + 1] = FLOOR
    # Transept: perpendicular cross at ⅔ along
    transept_r = int(D * 0.65)
    for c in range(1, W - 1):
        for r in range(transept_r - 1, transept_r + 2):
            struct[r][c] = FLOOR
    # Apse: rounded endpoint at the front (low rows)
    apse_r = 1
    for c in range(W // 2 - 3, W // 2 + 4):
        struct[apse_r][c] = TABLE   # raised altar
        struct[apse_r + 1][c] = FLOOR
    # Walls along nave (h=4)
    for r in range(2, D):
        for c in (nave_cl - 2, nave_cr + 2):
            if 0 <= c < W:
                struct[r][c] = HALF_WALL
    # Spawn at south (nave entrance), teleporter at apse
    util[D - 2][W // 2] = "sp"
    util[apse_r][W // 2] = "t"
    # Apse altar centerpiece
    place(inter, apse_r, W // 2, "centerpiece", rot=180)
    # Nave column markers
    place(inter, transept_r, W // 2, "totem", rot=180)
    # Transept arms
    place(inter, transept_r, 2, "wall_display", rot=90)
    place(inter, transept_r, W - 3, "wall_display", rot=270)
    # Aisle artifacts (paired left/right)
    for tr in [transept_r + 5, transept_r + 10]:
        if tr < D - 2:
            place(inter, tr, nave_cl - 1, "frame", rot=90)
            place(inter, tr, nave_cr + 1, "frame", rot=270)
    return {"name": "Cathedral", "subtitle": "cruciform — nave, transept, apse",
            "W": W, "D": D, "struct": struct, "util": util, "inter": inter}


# ─────────────────────────────────────────────────────────────────────
# 6. AMPHITHEATER — circular tiered rings around central focus
# ─────────────────────────────────────────────────────────────────────

def make_amphitheater() -> dict:
    W, D = 23, 23
    struct, util, inter = empty_layers(W, D)
    cx, cy = W / 2, D / 2
    for r in range(D):
        for c in range(W):
            dist = math.hypot(r - cy, c - cx)
            if dist < 3:
                struct[r][c] = FLOOR_LOW      # stage (sunken)
            elif dist < 5:
                struct[r][c] = FLOOR          # first ring
            elif dist < 7:
                struct[r][c] = TABLE          # tier 1
            elif dist < 9:
                struct[r][c] = HALF_WALL      # tier 2
            elif dist < 11:
                struct[r][c] = WALL           # outer wall
    # Carve an entry gap on the south
    for r in range(D // 2 + 5, D):
        struct[r][W // 2] = FLOOR
    # Spawn at south, teleporter at centre (the stage)
    util[D - 1][W // 2] = "sp"
    util[int(cy)][int(cx)] = "t"
    # Performer at stage
    place(inter, int(cy) - 1, int(cx), "centerpiece", rot=180)
    # Tier audience — paired around the ring
    import_offsets = [
        (-5, -3), (-5, 3), (5, -3), (5, 3),
        (-3, -5), (-3, 5), (3, -5), (3, 5),
    ]
    for dr, dc in import_offsets:
        r, c = int(cy + dr), int(cx + dc)
        if 0 <= r < D and 0 <= c < W and struct[r][c] not in (VOID, WALL):
            place(inter, r, c, "small_inter", rot=180)
    return {"name": "Amphitheater", "subtitle": "circular tiered rings around the stage",
            "W": W, "D": D, "struct": struct, "util": util, "inter": inter}


# ─────────────────────────────────────────────────────────────────────
# 7. SPIRAL — labyrinth winding inward to a centre
# ─────────────────────────────────────────────────────────────────────

def make_spiral() -> dict:
    W, D = 21, 21
    struct, util, inter = empty_layers(W, D)
    # Fill with walls
    for r in range(D):
        for c in range(W):
            struct[r][c] = WALL
    # Carve a spiral path inward
    cx, cy = W // 2, D // 2
    # Walk in a spiral path from outside to centre
    # Use bounding rings shrinking inward
    rings = []
    for k in range(0, min(W, D) // 2):
        rings.append((k, k, D - 1 - k, W - 1 - k))   # r0, c0, r1, c1
    # Walk the perimeter of each ring, leaving a 1-cell gap to the inner ring
    for i, (r0, c0, r1, c1) in enumerate(rings):
        if r1 <= r0 or c1 <= c0: break
        # Top edge
        for c in range(c0, c1 + 1):
            struct[r0][c] = FLOOR
        # Right edge
        for r in range(r0, r1 + 1):
            struct[r][c1] = FLOOR
        # Bottom edge
        for c in range(c1, c0 - 1, -1):
            struct[r1][c] = FLOOR
        # Left edge — STOP one cell short so the spiral continues inward
        for r in range(r1, r0, -1):
            struct[r][c0] = FLOOR
        # Keep one wall to force the spiral motion: open downward at the
        # bottom-left corner of each ring (the entry to the next ring)
        if i < len(rings) - 1:
            inner_r0 = rings[i + 1][0]
            inner_c0 = rings[i + 1][1]
            # Connect ring's inner edge to the next ring's start
            if inner_r0 - 1 < D and inner_c0 - 1 < W:
                struct[r0 + 1][c0 + 1] = FLOOR
    # Spawn at the outer entry (top-left), teleporter at the centre
    util[0][0] = "sp"
    util[cy][cx] = "t"
    # Artifacts at each spiral turn (the corners of each ring)
    for i, (r0, c0, r1, c1) in enumerate(rings[1:5]):
        kinds = ["wedge", "small_inter", "wall_display", "puzzle"]
        if r1 > r0 and c1 > c0:
            place(inter, r0, c1, kinds[i % 4], rot=0)
    # Centerpiece at the heart
    place(inter, cy - 1, cx, "centerpiece", rot=180)
    return {"name": "Spiral", "subtitle": "labyrinth winding inward",
            "W": W, "D": D, "struct": struct, "util": util, "inter": inter}


# ─────────────────────────────────────────────────────────────────────
# 8. HUB_SPOKES — central plaza + radial corridors
# ─────────────────────────────────────────────────────────────────────

def make_hub_spokes() -> dict:
    W, D = 25, 25
    struct, util, inter = empty_layers(W, D)
    cx, cy = W // 2, D // 2
    # Central plaza (5×5 circle-ish)
    for r in range(D):
        for c in range(W):
            if math.hypot(r - cy, c - cx) < 4:
                struct[r][c] = FLOOR
            elif math.hypot(r - cy, c - cx) < 5:
                struct[r][c] = TABLE       # rim around plaza
    # 4 radial corridors (N, E, S, W)
    for k in range(4, cy):
        struct[cy - k][cx] = FLOOR
        struct[cy + k][cx] = FLOOR
        struct[cy][cx - k] = FLOOR
        struct[cy][cx + k] = FLOOR
    # Terminal small rooms at each radial end
    for (er, ec) in [(1, cx), (D - 2, cx), (cy, 1), (cy, W - 2)]:
        for r in range(max(0, er - 1), min(D, er + 2)):
            for c in range(max(0, ec - 1), min(W, ec + 2)):
                struct[r][c] = FLOOR
    # Spawn at south radial terminus, teleporter at centre plaza
    util[D - 2][cx] = "sp"
    util[cy][cx] = "t"
    # Hub centerpiece
    place(inter, cy - 1, cx, "centerpiece", rot=180)
    # Terminal artifacts (one per spoke)
    place(inter, 1, cx, "wall_display", rot=180)
    place(inter, cy, 1, "puzzle", rot=90)
    place(inter, cy, W - 2, "wedge", rot=270)
    place(inter, D - 3, cx, "frame", rot=0)
    # Plaza rim companions
    place(inter, cy - 3, cx - 2, "small_inter", rot=180)
    place(inter, cy - 3, cx + 2, "small_inter", rot=180)
    return {"name": "HubSpokes", "subtitle": "central plaza + 4 radial corridors",
            "W": W, "D": D, "struct": struct, "util": util, "inter": inter}


# ─────────────────────────────────────────────────────────────────────
# 9. ATRIUM — peripheral rooms surrounding a central courtyard
# ─────────────────────────────────────────────────────────────────────

def make_atrium() -> dict:
    W, D = 21, 21
    struct, util, inter = empty_layers(W, D)
    # Outer ring rooms (h=1)
    for r in range(D):
        for c in range(W):
            struct[r][c] = FLOOR
    # Central courtyard is "void" or sunken — make it h=0.5
    cx, cy = W // 2, D // 2
    for r in range(cy - 4, cy + 5):
        for c in range(cx - 4, cx + 5):
            struct[r][c] = FLOOR_LOW
    # Inner ring border (rim around the courtyard) — raised platform
    for r in range(D):
        for c in range(W):
            if (cy - 4 <= r <= cy + 4 and (c == cx - 4 or c == cx + 4)) or \
               (cx - 4 <= c <= cx + 4 and (r == cy - 4 or r == cy + 4)):
                struct[r][c] = TABLE
    # Cardinal openings into the courtyard
    struct[cy][cx - 4] = FLOOR
    struct[cy][cx + 4] = FLOOR
    struct[cy - 4][cx] = FLOOR
    struct[cy + 4][cx] = FLOOR
    # Outer wall
    for r in range(D):
        for c in range(W):
            if r == 0 or r == D - 1 or c == 0 or c == W - 1:
                struct[r][c] = WALL
    util[D - 2][cx] = "sp"
    util[cy][cx] = "t"
    # Atrium centerpiece (in the courtyard centre)
    place(inter, cy - 1, cx, "centerpiece", rot=180)
    # Peripheral artifacts — paired in the surrounding rooms
    place(inter, 2, 2, "wall_display", rot=180)
    place(inter, 2, W - 3, "wall_display", rot=180)
    place(inter, D - 3, 2, "puzzle", rot=0)
    place(inter, D - 3, W - 3, "wedge", rot=0)
    place(inter, cy, 2, "frame", rot=90)
    place(inter, cy, W - 3, "frame", rot=270)
    return {"name": "Atrium", "subtitle": "peripheral rooms around central courtyard",
            "W": W, "D": D, "struct": struct, "util": util, "inter": inter}


# ─────────────────────────────────────────────────────────────────────
# 10. CROSSROADS — two corridors crossing perpendicularly
# ─────────────────────────────────────────────────────────────────────

def make_crossroads() -> dict:
    W, D = 23, 23
    struct, util, inter = empty_layers(W, D)
    # Fill with walls
    for r in range(D):
        for c in range(W):
            struct[r][c] = WALL
    cx, cy = W // 2, D // 2
    # N-S corridor (3 wide)
    for r in range(D):
        for c in range(cx - 1, cx + 2):
            struct[r][c] = FLOOR
    # E-W corridor (3 wide)
    for r in range(cy - 1, cy + 2):
        for c in range(W):
            struct[r][c] = FLOOR
    # Crossroads centre — slightly raised
    for r in range(cy - 1, cy + 2):
        for c in range(cx - 1, cx + 2):
            struct[r][c] = TABLE
    # Spawn at south terminus, teleporter at north terminus
    util[D - 1][cx] = "sp"
    util[0][cx] = "t"
    # Centerpiece at the crossroads
    place(inter, cy, cx, "centerpiece", rot=180)
    # Cardinal terminus artifacts
    place(inter, cy - 8, cx, "wall_display", rot=180)
    place(inter, cy + 8, cx, "wall_display", rot=180)
    place(inter, cy, cx - 8, "puzzle", rot=90)
    place(inter, cy, cx + 8, "wedge", rot=270)
    # Walking-line markers along each arm
    for k in [3, 5]:
        place(inter, cy - k, cx, "point", rot=180)
        place(inter, cy + k, cx, "point", rot=180)
    return {"name": "Crossroads", "subtitle": "two corridors crossing perpendicularly",
            "W": W, "D": D, "struct": struct, "util": util, "inter": inter}


# ─────────────────────────────────────────────────────────────────────
# Main — write all 10 maps to disk
# ─────────────────────────────────────────────────────────────────────

ARCHETYPES: list[Callable[[], dict]] = [
    make_promenade, make_pit, make_ziggurat, make_dungeon, make_cathedral,
    make_amphitheater, make_spiral, make_hub_spokes, make_atrium, make_crossroads,
]


def write_map(result: dict) -> Path:
    map_name = f"Archetype_{result['name']}"
    out_dir = MAPS_DIR / map_name
    out_dir.mkdir(exist_ok=True)

    struct = result["struct"]
    util = result["util"]
    inter = result["inter"]
    W, D = result["W"], result["D"]

    map_data = {
        "map_info": {
            "name":         map_name,
            "lookup_name":  map_name,
            "description":  f"Archetype demonstration map — {result['subtitle']}. "
                            f"Generated by tools/generate_archetype_maps.py to explore "
                            f"structural archetypes beyond the promenade.",
            "version":      "archetype-0.1",
            "format":       "json",
            "created_from": "tools/generate_archetype_maps.py 2026-05-16",
            "dimensions":   {"width": W, "depth": D, "max_height": 5},
            "metadata":     {
                "category":  "archetype_demo",
                "archetype": result["name"].lower(),
                "estimated_time": "2-4 minutes",
                "subtitle":  result["subtitle"],
            },
            "title": f"Archetype: {result['name']}",
        },
        "utility_definitions": {
            "sp": {"name": "Spawn", "description": "Player spawn point", "type": "spawn"},
            "t":  {"name": "Exit Portal",
                   "description": "Step here to leave",
                   "type": "teleporter",
                   "properties": {"action": "next_in_sequence"}}
        },
        "documentation": {
            "summary":  f"Archetype_{result['name']} — {result['subtitle']}",
            "layout":   f"{W}×{D} bounding box. "
                        f"Demonstrates the '{result['name'].lower()}' structural archetype.",
            "objective": "Walk the archetype. The shape is the lesson.",
            "key_elements": [
                f"Spawn at archetype-appropriate entry",
                f"Teleporter at archetype-appropriate exit",
                f"Placeholder artifacts marking compositional roles "
                f"(centerpiece, wall_display, etc.)"
            ],
        },
        "lighting": {
            "ambient_color": [0.30, 0.32, 0.40],
            "ambient_energy": 0.9,
            "directional_light": {
                "enabled": True,
                "direction": [-0.3, -1.0, -0.2],
                "energy": 0.7,
            },
        },
        "settings": {"player_spawn_height": 0.5, "floor_tile_size": 1.0},
        "layers": {
            "structure":     struct,
            "utilities":     util,
            "interactables": inter,
        },
    }

    with open(out_dir / "map_data.json", "w", encoding="utf-8") as f:
        json.dump(map_data, f, indent="\t")

    # intent.md
    intent_lines = [
        f"Concept: A {result['subtitle']}. Generated as one of 10 structural archetypes to expose what's possible beyond the promenade form.",
        "",
        f"Actualizes: The {result['name'].lower()} archetype — a recurring spatial pattern from architecture, level design, or both.",
        "",
        "Sequence role: Not curriculum content. Reference geometry. The shape demonstrates a compositional possibility space.",
        "",
        f"Technical angle: Map is {W}×{D} cells in the bounding box. Structure layer uses height codes 0-5 to encode void / sunken / floor / table / half-wall / wall. Interactables placed at compositional roles (centerpiece, wall_display, paired_satellite) using existing registered artifacts as placeholders.",
        "",
        "Critical angle: The promenade isn't the only spatial vocabulary. Each archetype here proposes a different way to relate spawn, teleporter, walls, height, and artifact placement. Walking them reveals which forms feel right for which curriculum content.",
        "",
        "Key artifacts:",
        f"- Placeholders: library_rack (centerpiece), science_screen (wall display), xyz_slider_plate (small interactive), point, dark_sphere, etc.",
        "",
        "Gap: These are reference geometries; the artifacts are scaffolding. Real content gets routed via tools/place.py or the tile palette once a real curriculum match is found for this archetype.",
    ]
    (out_dir / "intent.md").write_text("\n".join(intent_lines), encoding="utf-8")

    # blurb.md
    blurb = (
        f"{result['subtitle'].capitalize()}. Walk the {result['name'].lower()} archetype "
        f"to see how a different structural shape would carry curriculum content.\n\n"
        f"This is reference geometry — placeholder artifacts mark the compositional roles "
        f"(centerpiece, wall display, paired satellites). The form is the point.\n"
    )
    (out_dir / "blurb.md").write_text(blurb, encoding="utf-8")

    return out_dir / "map_data.json"


def main():
    print(f"generating 10 archetype maps...")
    print()
    results = []
    for fn in ARCHETYPES:
        result = fn()
        path = write_map(result)
        n_inter = sum(1 for row in result["inter"] for c in row if c.strip())
        print(f"  ✓ Archetype_{result['name']:14}  {result['W']:2}×{result['D']:2}  "
              f"{n_inter:>2} placeholders  →  {path.relative_to(ROOT)}")
        results.append(result)
    print()
    print(f"all 10 generated. capture any in Godot via:")
    print(f"  godot_console --path . --xr-mode off --no-window --script res://commons/testing/capture_multi_angle.gd -- --mode=map --target=Archetype_<Name>")


if __name__ == "__main__":
    main()
