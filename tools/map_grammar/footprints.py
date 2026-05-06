"""Footprint registry — additive stamps for the place-first generator.

Each footprint is a function `(rng) -> list[(dr, dc, h)]` returning
offsets from the artifact's cell + the height to stamp at each. The
generator places artifacts on a grid, calls the footprint for each,
and uses max-blend composition.

Twelve footprints organized by sequence theme:

  spatial (matches dir_group):
    panel, plane, floor, pedestal, omni
  algorithmic (matches sequence vocabulary):
    terrace, noise_patch, well, tower, bridge,
    atrium, fractal_l, expansion
"""
from __future__ import annotations

import math
import random
from typing import Callable

# Each footprint takes an rng (for stochastic ones) and returns
# (dr, dc, height) offsets from the artifact's cell.
Footprint = Callable[[random.Random], list[tuple[int, int, int]]]


# ── Spatial / dir_group footprints (from Grow Map) ────────────────

def fp_panel(rng: random.Random) -> list[tuple[int, int, int]]:
    """Wall-anchored. h=3 wall behind + 3×3 h=1 floor in front."""
    return [
        (-1, -1, 3), (-1, 0, 3), (-1, 1, 3),
        (0, -1, 1),  (0, 0, 1),  (0, 1, 1),
        (1, -1, 1),  (1, 0, 1),  (1, 1, 1),
    ]


def fp_plane(rng: random.Random) -> list[tuple[int, int, int]]:
    """Flat-on-top. 3×3 h=1 floor."""
    return [(dr, dc, 1) for dr in (-1, 0, 1) for dc in (-1, 0, 1)]


def fp_floor(rng: random.Random) -> list[tuple[int, int, int]]:
    """Gravity-anchored. h=1 + 4-cardinal cross."""
    return [(0, 0, 1), (-1, 0, 1), (1, 0, 1), (0, -1, 1), (0, 1, 1)]


def fp_pedestal(rng: random.Random) -> list[tuple[int, int, int]]:
    """Raised display. h=2 cube + h=1 surround."""
    out = [(0, 0, 2)]
    for dr in (-1, 0, 1):
        for dc in (-1, 0, 1):
            if dr == 0 and dc == 0: continue
            out.append((dr, dc, 1))
    return out


def fp_omni(rng: random.Random) -> list[tuple[int, int, int]]:
    """Place-anywhere. h=1 cube + 1-cell clearance."""
    return [(dr, dc, 1) for dr in (-1, 0, 1) for dc in (-1, 0, 1)]


# ── Algorithmic footprints (matched to sequence themes) ───────────

def fp_terrace(rng: random.Random) -> list[tuple[int, int, int]]:
    """Concentric height rings — h=3 centre, h=2 ring, h=1 ring.
    Reads as amphitheatre. Good for transformation, color (composition),
    qfeplaboratory."""
    out: list[tuple[int, int, int]] = [(0, 0, 3)]
    for dr in (-1, 0, 1):
        for dc in (-1, 0, 1):
            if dr == 0 and dc == 0: continue
            out.append((dr, dc, 2))
    for dr in range(-2, 3):
        for dc in range(-2, 3):
            if max(abs(dr), abs(dc)) != 2: continue
            out.append((dr, dc, 1))
    return out


def fp_noise_patch(rng: random.Random) -> list[tuple[int, int, int]]:
    """Random scatter — 25 cells in 5×5 area get random heights 1 or 2,
    with ~25% void. Reads as rough terrain.

    Good for randomness, noise sequences."""
    out: list[tuple[int, int, int]] = []
    for dr in range(-2, 3):
        for dc in range(-2, 3):
            r = rng.random()
            if r < 0.25: continue          # void
            elif r < 0.85: out.append((dr, dc, 1))
            else: out.append((dr, dc, 2))
    return out


def fp_well(rng: random.Random) -> list[tuple[int, int, int]]:
    """Gravity well — h=2 walls around an h=0 centre.
    The artifact sits in a depression. Reads as workshop / pit.

    Good for forces, qfeplaboratory."""
    out: list[tuple[int, int, int]] = []
    for dr in (-1, 0, 1):
        for dc in (-1, 0, 1):
            if dr == 0 and dc == 0: continue
            if abs(dr) == 1 and abs(dc) == 1: continue   # no diagonal corners
            out.append((dr, dc, 2))
    # Floor 2 cells out so player can approach
    for dr, dc in [(-2, 0), (2, 0), (0, -2), (0, 2)]:
        out.append((dr, dc, 1))
    return out


def fp_tower(rng: random.Random) -> list[tuple[int, int, int]]:
    """Tall pillar — h=4 spike at centre + 4-cardinal h=1 floor.
    Reads as obelisk / minaret. Good for foundations, lambda_edge,
    primitives."""
    return [
        (0, 0, 4),
        (-1, 0, 1), (1, 0, 1), (0, -1, 1), (0, 1, 1),
        (-2, 0, 1), (2, 0, 1), (0, -2, 1), (0, 2, 1),
    ]


def fp_bridge(rng: random.Random) -> list[tuple[int, int, int]]:
    """Linear h=1 strip — 5 cells along one axis. Reads as causeway.

    Good for any sequence where the artifact needs a long approach
    (transformation_translation, wavefunctions)."""
    axis = rng.choice([0, 1])
    return [
        (i if axis == 0 else 0, i if axis == 1 else 0, 1)
        for i in range(-2, 3)
    ]


def fp_atrium(rng: random.Random) -> list[tuple[int, int, int]]:
    """Open courtyard — 5×5 h=1 floor with h=3 corner pillars.
    The artifact has space and the courtyard reads as a room.

    Good for color, composition, lambda_edge sequences."""
    out: list[tuple[int, int, int]] = []
    for dr in range(-2, 3):
        for dc in range(-2, 3):
            out.append((dr, dc, 1))
    for dr, dc in [(-2, -2), (-2, 2), (2, -2), (2, 2)]:
        out.append((dr, dc, 3))
    return out


def fp_fractal_l(rng: random.Random) -> list[tuple[int, int, int]]:
    """Recursive L-shape — depth-2 self-similar pattern.
    Reads as fractal seed. Good for fractals, l-systems, procgen."""
    # Depth-1 L: 3 cells
    base = [(0, 0), (1, 0), (0, 1)]
    out: list[tuple[int, int, int]] = []
    # Depth-2: each base cell anchors another L scaled by 2
    for (br, bc) in base:
        for (sr, sc) in base:
            r = br * 2 + sr
            c = bc * 2 + sc
            out.append((r, c, 1))
    # Centre marker raised
    out.append((0, 0, 2))
    return out


def fp_expansion(rng: random.Random) -> list[tuple[int, int, int]]:
    """Radial expansion — h=1 cells at distances 0, 2, 4 from centre.
    Reads as ripple. Good for wavefunctions, swarmintelligence."""
    out: list[tuple[int, int, int]] = [(0, 0, 2)]
    for dr in range(-4, 5):
        for dc in range(-4, 5):
            d = max(abs(dr), abs(dc))
            if d in (2, 4):
                out.append((dr, dc, 1))
    return out


def fp_grove(rng: random.Random) -> list[tuple[int, int, int]]:
    """Scattered h=2 columns inside a 5×5 h=1 floor. Reads as columns
    in an open plaza. Good for swarm, integration, lsystems."""
    out: list[tuple[int, int, int]] = []
    for dr in range(-2, 3):
        for dc in range(-2, 3):
            out.append((dr, dc, 1))
    # Place 4–6 random pillars at h=2 inside the plaza
    candidates = [(dr, dc) for dr in range(-2, 3) for dc in range(-2, 3)
                  if not (dr == 0 and dc == 0)]
    rng.shuffle(candidates)
    n_pillars = rng.randint(4, 6)
    for (dr, dc) in candidates[:n_pillars]:
        out.append((dr, dc, 2))
    return out


def fp_ca_seed(rng: random.Random) -> list[tuple[int, int, int]]:
    """Cellular-automata seed pattern — Conway-still-life "block" or
    "blinker" or "beacon" stamped as h=1 cells. Reads as a frozen
    moment in a CA. Good for cellularautomata sequence."""
    pattern_choice = rng.choice(["block", "blinker", "beacon", "glider"])
    if pattern_choice == "block":
        cells = [(0, 0), (0, 1), (1, 0), (1, 1)]
    elif pattern_choice == "blinker":
        cells = [(0, -1), (0, 0), (0, 1)]
    elif pattern_choice == "beacon":
        cells = [(0, 0), (0, 1), (1, 0), (1, 1),
                 (2, 2), (2, 3), (3, 2), (3, 3)]
    else:  # glider
        cells = [(0, 1), (1, 2), (2, 0), (2, 1), (2, 2)]
    out = [(r, c, 1) for (r, c) in cells]
    # 5x5 plaza floor under it
    for dr in range(-1, 4):
        for dc in range(-1, 4):
            if (dr, dc) not in cells:
                out.append((dr, dc, 1))
    return out


# ── Registry ──────────────────────────────────────────────────────

REGISTRY: dict[str, Footprint] = {
    "panel":       fp_panel,
    "plane":       fp_plane,
    "floor":       fp_floor,
    "pedestal":    fp_pedestal,
    "omni":        fp_omni,
    "terrace":     fp_terrace,
    "noise_patch": fp_noise_patch,
    "well":        fp_well,
    "tower":       fp_tower,
    "bridge":      fp_bridge,
    "atrium":      fp_atrium,
    "fractal_l":   fp_fractal_l,
    "expansion":   fp_expansion,
    "grove":       fp_grove,
    "ca_seed":     fp_ca_seed,
}


# ── Per-sequence footprint roster ─────────────────────────────────
# Which footprints are appropriate for which sequence's lesson. The
# place-first generator picks from these (one per artifact, weighted
# by spatial_profile + sequence theme).

SEQUENCE_FOOTPRINTS: dict[str, list[str]] = {
    # F_order — atomic, structural
    "primitives":           ["floor", "pedestal", "omni", "tower"],
    "transformation":       ["pedestal", "panel", "terrace"],
    "array_tutorial":       ["plane", "floor", "atrium", "tower"],
    "color":                ["plane", "panel", "atrium", "pedestal"],

    # oscillation — dynamic
    "forces":               ["well", "pedestal", "terrace", "bridge"],
    "wavefunctions":        ["expansion", "bridge", "terrace"],

    # E_entropy — disorder
    "randomness":           ["noise_patch", "grove", "floor"],
    "noise":                ["noise_patch", "expansion", "grove"],
    "cellularautomata":     ["ca_seed", "grove", "noise_patch"],

    # lambda_edge — emergence
    "fractals":             ["fractal_l", "tower", "terrace"],
    "lsystems":             ["fractal_l", "grove", "expansion"],
    "proceduralgeneration": ["noise_patch", "fractal_l", "atrium"],
    "isosurfaces":          ["expansion", "well", "terrace"],
    "boolean_surfaces":     ["tower", "well", "pedestal"],

    # integration — composing
    "softbodies":           ["well", "expansion", "noise_patch"],
    "swarmintelligence":    ["grove", "expansion", "bridge"],
    "machinelearning":      ["terrace", "expansion", "atrium"],
    "graphtheory":          ["grove", "bridge", "tower"],

    # synthesis — full library
    "foundationscrisis":    ["terrace", "well", "tower"],
    "qfeplaboratory":       ["atrium", "terrace", "tower", "expansion"],
    "postfoundationscrisis":["atrium", "grove", "well"],
}


def footprint_for(name: str, rng: random.Random) -> list[tuple[int, int, int]]:
    """Look up + invoke a footprint by name."""
    fn = REGISTRY.get(name)
    if fn is None:
        raise KeyError(f"unknown footprint: {name}")
    return fn(rng)


def pick_footprint(sequence_id: str, role: str, rng: random.Random) -> str:
    """Pick a footprint name for an artifact, given its sequence and role.

    role: 'central' | 'spawn-adjacent' | 'tele-adjacent' | 'peripheral'.
    Currently uses sequence roster as primary signal; role is a tiebreaker
    for the central artifact (gets the 'biggest' footprint in the roster).
    """
    roster = SEQUENCE_FOOTPRINTS.get(sequence_id, ["floor", "pedestal", "omni"])
    if role == "central" and len(roster) > 0:
        # Prefer the most distinctive footprint in the roster as the centerpiece.
        # By convention, the first entry is the dominant one.
        return roster[0]
    return rng.choice(roster)
