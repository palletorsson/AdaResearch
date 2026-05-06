#!/usr/bin/env python3
"""
Generate the two biome-lab timeline maps via the encyclopedia save API.

Two long corridors. Each zone is W_ZONE cells of painted floor; you walk
the corridor and the transitions show themselves at the boundaries.

  Biome_Zoo    — 12 zones × 4 cells = 48-cell corridor.
                 Each zone demonstrates one transition strategy
                 (sterile, hard edge, gradient, halo, salt&pepper, …).
                 Walked left to right it forms a vocabulary of how
                 biome paint can vary across cells.

  Biome_Spine  — 19 zones × 4 cells = 76-cell corridor.
                 Each zone is one spine sequence's biome state —
                 density + kingdoms scaled so the corridor reads as the
                 curriculum's progression from sterile lab (seq 1) to
                 fully saturated QFEP nature (seq 19).
                 The top-down render of this map IS the project's
                 timeline image.

Saves through localhost:3003/api/voxel-editor so the JSON lands in
compact-rows format (same path the catalyst test maps use).

Run: python tools/generate_biome_lab_maps.py
"""

from __future__ import annotations

import json
import sys
import urllib.request
import urllib.error
from typing import Callable

API = "http://localhost:3003/api/voxel-editor"

# Geometry: each zone is W_ZONE cells wide along the corridor, DEPTH
# cells deep across it. 4×6 reads cleanly from above and is short
# enough to walk in VR without exhausting the player.
W_ZONE = 4
DEPTH = 6


# ────────────────────────────────────────────────────────────────────
# Map skeleton
# ────────────────────────────────────────────────────────────────────
def base_map(name: str, length: int, teleporter_target: str) -> dict:
    """A length×DEPTH open corridor with floor at h=1 everywhere.

    Spawn at (1, 1) — start of corridor. Teleporter at the far end so
    Zoo loops to Spine and Spine loops back to Zoo for continuous walks.
    """
    structure = [["1"] * length for _ in range(DEPTH)]
    utilities = [[" "] * length for _ in range(DEPTH)]
    interactables = [[" "] * length for _ in range(DEPTH)]
    biome_paint = [[" "] * length for _ in range(DEPTH)]
    utilities[1][1] = "sp"
    utilities[DEPTH - 2][length - 2] = f"t:{teleporter_target}"
    return {
        "map_info": {
            "name": name,
            "lookup_name": name,
            "format": "json",
            "version": "1.0",
            "dimensions": {"width": length, "depth": DEPTH, "max_height": 5},
            "metadata": {"source": "biome_lab_generator"},
        },
        "layers": {
            "structure": structure,
            "utilities": utilities,
            "interactables": interactables,
            "biome_paint": biome_paint,
        },
        "settings": {
            "cube_size": 1, "gutter": 0, "show_grid": True,
            # Soft lavender night so painted cells pop in the top-down
            # render. The hero image needs the painted layer to read.
            "background": {"type": "sky", "color": [0.06, 0.07, 0.13]},
            "grid_animation": {"enabled": False},
            "initial_tile_visibility": "all_visible",
        },
        "utility_definitions": {
            "sp": {"type": "spawn"}, "t": {"type": "teleporter"},
        },
    }


def paint_zone(m: dict, zone_idx: int, fn: Callable[[int, int], str | None]) -> None:
    """Apply a paint pattern function to one zone of the corridor.

    fn(row, col_within_zone) → biome paint token (e.g. "f3") or None.
    """
    col_start = zone_idx * W_ZONE
    for r in range(DEPTH):
        for c in range(W_ZONE):
            tok = fn(r, c)
            if tok:
                m["layers"]["biome_paint"][r][col_start + c] = tok


# ────────────────────────────────────────────────────────────────────
# ZOO — 12 transition strategies
# ────────────────────────────────────────────────────────────────────
# Each pattern fn takes (row, col_within_zone) and returns the token to
# place (or None for blank). Zone is 4 cols × 6 rows = 24 cells.

def zoo_sterile(_r: int, _c: int) -> str | None:
    return None  # Empty — fog and grid only.

def zoo_hard_edge(_r: int, c: int) -> str | None:
    return "f5" if c < W_ZONE // 2 else "-"  # left dense flower, right carved sterile

def zoo_gradient(_r: int, c: int) -> str | None:
    # Density ramps left to right: f1 → f2 → f3 → f4
    return f"f{min(c + 1, 5)}"

def zoo_halo(r: int, c: int) -> str | None:
    # Single dense seed in the middle, fading outward.
    cx, cy = W_ZONE // 2, DEPTH // 2
    d = abs(c - cx) + abs(r - cy)
    if d == 0: return "f5"
    if d == 1: return "f3"
    if d == 2: return "f1"
    return None

def zoo_salt_pepper(r: int, c: int) -> str | None:
    # Dense biome with deterministically-scattered sterile cells.
    if (r * 13 + c * 7) % 7 == 0:
        return "-"
    return "f4"

def zoo_voronoi(r: int, c: int) -> str | None:
    # Three kingdom seeds, each cell takes the nearest seed's kingdom.
    seeds = [(0, 0, "f4"), (5, 1, "t4"), (2, 3, "u4")]
    return min(seeds, key=lambda s: (s[0] - r) ** 2 + (s[1] - c) ** 2)[2]

def zoo_bands(r: int, _c: int) -> str | None:
    # Horizontal stripes — flower / tree / fungus.
    return ["f3", "t3", "u3"][r % 3]

def zoo_cross(_r: int, _c: int) -> str | None:
    return "x3"  # uniform cross-kingdom field

def zoo_chamber(r: int, c: int) -> str | None:
    # Catalyst chamber radial: creature core, flower ring, tree outer.
    cx, cy = W_ZONE // 2, DEPTH // 2
    d = max(abs(c - cx), abs(r - cy))
    if d == 0: return "c5"
    if d == 1: return "f3"
    return "t2"

def zoo_lsystem(r: int, c: int) -> str | None:
    # Snake-like recursive trace — alternating row offsets.
    if r % 2 == 0:
        return "t4" if c < 3 else None
    return "t4" if c >= 1 else None

def zoo_anchor(r: int, c: int) -> str | None:
    # One strong seed, sparse weak neighbours — the field falls off fast.
    ax, ay = 1, 2
    d = abs(c - ax) + abs(r - ay)
    if d == 0: return "f5"
    if d == 1: return "f2"
    if d == 2: return "f1"
    return None

def zoo_saturated(r: int, c: int) -> str | None:
    # Every cell painted, every kingdom, intensity 5 — what seq 19 looks like.
    kingdoms = ["f", "t", "u", "c", "m"]
    return f"{kingdoms[(r * 7 + c * 3) % len(kingdoms)]}5"


ZOO_ZONES: list[tuple[str, Callable[[int, int], str | None]]] = [
    ("Sterile",      zoo_sterile),
    ("HardEdge",     zoo_hard_edge),
    ("Gradient",     zoo_gradient),
    ("Halo",         zoo_halo),
    ("SaltPepper",   zoo_salt_pepper),
    ("Voronoi",      zoo_voronoi),
    ("Bands",        zoo_bands),
    ("Cross",        zoo_cross),
    ("Chamber",      zoo_chamber),
    ("LSystem",      zoo_lsystem),
    ("Anchor",       zoo_anchor),
    ("Saturated",    zoo_saturated),
]


# ────────────────────────────────────────────────────────────────────
# SPINE — 19 sequences, density curve + per-stage kingdom unlocks
# ────────────────────────────────────────────────────────────────────
# This is the canonical curve. Edit SPINE_STAGES to redraw the
# curriculum's biome arc — the top-down render is derived from it.
#
# kingdoms tokens: f=flower, t=tree, u=fungus, c=creature, x=cross.

SPINE_STAGES: list[dict] = [
    {"seq": "primitives",        "density": 0.00, "kingdoms": []},
    {"seq": "transformation",    "density": 0.00, "kingdoms": []},
    {"seq": "color",             "density": 0.05, "kingdoms": ["f"]},
    {"seq": "vectors",           "density": 0.10, "kingdoms": ["f"]},
    {"seq": "forces",            "density": 0.18, "kingdoms": ["f"]},
    {"seq": "oscillation",       "density": 0.26, "kingdoms": ["f", "t"]},
    {"seq": "particles",         "density": 0.34, "kingdoms": ["f", "t"]},
    {"seq": "randomness",        "density": 0.42, "kingdoms": ["f", "t"]},
    {"seq": "mathematics",       "density": 0.50, "kingdoms": ["f", "t"]},
    {"seq": "fractals",          "density": 0.58, "kingdoms": ["f", "t"]},
    {"seq": "lsystems",          "density": 0.65, "kingdoms": ["f", "t", "u"]},
    {"seq": "proceduralgen",     "density": 0.72, "kingdoms": ["f", "t", "u"]},
    {"seq": "softbodies",        "density": 0.78, "kingdoms": ["f", "t", "u", "c"]},
    {"seq": "swarm",             "density": 0.84, "kingdoms": ["f", "t", "u", "c"]},
    {"seq": "ml",                "density": 0.88, "kingdoms": ["f", "t", "u", "c"]},
    {"seq": "foundationscrisis", "density": 0.92, "kingdoms": ["f", "t", "u", "c"]},
    {"seq": "qfeplaboratory",    "density": 0.95, "kingdoms": ["f", "t", "u", "c", "x"]},
    {"seq": "postfoundations",   "density": 0.97, "kingdoms": ["f", "t", "u", "c", "x"]},
    {"seq": "graphtheory",       "density": 0.99, "kingdoms": ["f", "t", "u", "c", "x"]},
]


def apply_structure_zone(m: dict, zone_idx: int, stage: dict) -> None:
    """Write per-cell heights for one spine zone. Implements the
    "knowledge has transformed into qfep nature" claim literally: by
    zone 19, the grid has dissolved into nature — most cells are voids
    ("0", no cube at all) with a few tall ruins poking up where the
    structure used to be.

    Three regimes, smoothly transitioning by stage density:

      density ≤ 0.70   ("low/mid", zones 1..12)
        Rises only. Cells deviate from "1" up to height 2 or 3. The
        grid is bumpier but solid. Walkable.

      0.70 < density ≤ 0.90   ("high", zones 13..16)
        Rises + voids start appearing. Up to ~50% of deviations are
        "0" (void). Knowledge is thinning; some cells have already
        gone fully back to nature.

      density > 0.90   ("terminal", zones 17..19)
        Almost all cells become voids. Only a few tall remnants
        (heights 3..5) remain — the ruins of the grid. By zone 19,
        ~95% of cells are "0". The lab is gone.

    Spawn and teleporter cells are forced back to "1" at the end so
    the map stays loadable / traversable at its endpoints.
    """
    density: float = float(stage["density"])
    col_start = zone_idx * W_ZONE
    n_cells = DEPTH * W_ZONE  # 24

    if density <= 0.0:
        # Pristine grid.
        for r in range(DEPTH):
            for c in range(W_ZONE):
                m["layers"]["structure"][r][col_start + c] = "1"
        return

    # Deterministic positional ordering — hash-sort cell coordinates
    # using the seq name as seed so the choice is stable across runs
    # and varies between sequences.
    seed: int = sum(ord(ch) for ch in stage["seq"])
    positions: list[tuple[int, int]] = [
        (r, c) for r in range(DEPTH) for c in range(W_ZONE)
    ]
    positions.sort(key=lambda p: (p[0] * 17 + p[1] * 7 + seed * 13) & 0xFFFF)

    # Pick the n_deviate / n_void / n_rise counts per regime.
    if density <= 0.70:
        # LOW/MID: rises only.
        n_deviate = int(round(density * 0.60 * n_cells))
        n_void = 0
        n_rise = n_deviate
        pool = ["2"] if density < 0.40 else ["2", "2", "3"]
    elif density <= 0.90:
        # HIGH: rises + voids start appearing.
        n_deviate = int(round(density * 0.85 * n_cells))
        # void fraction climbs from 0% at d=0.7 to 50% at d=0.9
        void_frac = (density - 0.70) / 0.20 * 0.50
        n_void = int(round(n_deviate * void_frac))
        n_rise = n_deviate - n_void
        pool = ["3", "2", "5"]
    else:
        # TERMINAL: mostly voids, sparse tall ruins.
        n_deviate = n_cells  # every cell changes
        # void fraction climbs from 85% at d=0.90 to ~95% at d=1.0
        void_frac = 0.85 + (density - 0.90) * 1.0
        n_void = int(round(n_cells * void_frac))
        n_rise = n_cells - n_void
        pool = ["5", "3"]  # only tall remnants left

    voids = set(positions[:n_void])
    rises = set(positions[n_void:n_void + n_rise])

    for r in range(DEPTH):
        for c in range(W_ZONE):
            if (r, c) in voids:
                m["layers"]["structure"][r][col_start + c] = "0"
            elif (r, c) in rises:
                h = (r * 17 + c * 7 + seed * 13) & 0xFFFF
                m["layers"]["structure"][r][col_start + c] = pool[(h >> 4) % len(pool)]
            else:
                m["layers"]["structure"][r][col_start + c] = "1"


def make_stage_pattern(stage: dict) -> Callable[[int, int], str | None]:
    """Return a paint fn for one spine sequence.

    Cells are filled deterministically (hash-based) so the corridor is
    reproducible run-over-run. Density controls fill ratio; intensity
    scales with density too (so seq 4's flowers are sparse + faint and
    seq 19's are dense + intense). Kingdoms cycle across cells.
    """
    density: float = float(stage["density"])
    kingdoms: list[str] = list(stage["kingdoms"])

    if not kingdoms or density <= 0.0:
        return zoo_sterile

    intensity = max(1, min(5, int(round(density * 5))))
    seed = sum(ord(ch) for ch in stage["seq"])
    threshold = int(round(density * 100))

    def fn(r: int, c: int) -> str | None:
        h = (r * 17 + c * 7 + seed) & 0xFFFF
        if (h % 100) >= threshold:
            return None
        kingdom = kingdoms[(r * 13 + c * 5) % len(kingdoms)]
        return f"{kingdom}{intensity}"

    return fn


# ────────────────────────────────────────────────────────────────────
# Build + save
# ────────────────────────────────────────────────────────────────────
def build_zoo() -> dict:
    length = len(ZOO_ZONES) * W_ZONE
    m = base_map("Biome_Zoo", length, teleporter_target="Biome_Spine")
    for i, (_name, fn) in enumerate(ZOO_ZONES):
        paint_zone(m, i, fn)
    return m


def build_spine() -> dict:
    length = len(SPINE_STAGES) * W_ZONE
    m = base_map("Biome_Spine", length, teleporter_target="Biome_Zoo")
    for i, stage in enumerate(SPINE_STAGES):
        paint_zone(m, i, make_stage_pattern(stage))
        # Structure arc: grid disintegrates as density rises (Reading B).
        # Zones 1..3 stay flat; zone 19 has only sparse ruins remaining.
        apply_structure_zone(m, i, stage)

    # Walkable spine — keep one row of "1" connecting spawn to
    # teleporter so a future credits-roll player can walk the corridor
    # end to end. Without this, terminal zones become impassable voids.
    spawn_row = 1
    teleporter_row = DEPTH - 2
    # Row 2 (between spawn at row 1 and teleporter at row DEPTH-2) is
    # the natural mid-line. Force it to height 1 across the full length.
    walk_row = (spawn_row + teleporter_row) // 2  # row 2 for DEPTH=6
    for c in range(length):
        m["layers"]["structure"][walk_row][c] = "1"
    # Spawn + teleporter cells themselves must be solid for the map to
    # load (utilities references a cell that doesn't have a floor break).
    m["layers"]["structure"][spawn_row][1] = "1"
    m["layers"]["structure"][teleporter_row][length - 2] = "1"
    return m


def post_save(name: str, data: dict) -> bool:
    body = json.dumps({"mapName": name, "data": data}).encode("utf-8")
    req = urllib.request.Request(
        API, data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        resp = urllib.request.urlopen(req, timeout=20)
    except urllib.error.URLError as e:
        print(f"  FAIL: {name} -- {e}")
        return False
    if resp.status != 200:
        print(f"  FAIL: {name} -- HTTP {resp.status}")
        return False
    return True


def main() -> int:
    print(f"Generating biome lab timeline maps via {API}...")

    zoo = build_zoo()
    zoo_len = len(ZOO_ZONES) * W_ZONE
    ok_zoo = post_save("Biome_Zoo", zoo)
    print(f"  {'OK' if ok_zoo else 'FAIL'}: Biome_Zoo  "
          f"({len(ZOO_ZONES)} zones, {zoo_len}x{DEPTH})")

    spine = build_spine()
    spine_len = len(SPINE_STAGES) * W_ZONE
    ok_spine = post_save("Biome_Spine", spine)
    print(f"  {'OK' if ok_spine else 'FAIL'}: Biome_Spine "
          f"({len(SPINE_STAGES)} zones, {spine_len}x{DEPTH})")

    return 0 if (ok_zoo and ok_spine) else 1


if __name__ == "__main__":
    sys.exit(main())
