"""Placement auto-research — compare 5 placement strategies on 4 test artifacts.

Pattern follows tools/map_grammar_research.py + map_grammar_eval.py:
  generate variant -> score -> log -> iterate.

The hypothesis the user wants tested: distance fields (SDF), folding, or
paradoxical / Gödel geometry might solve placement better than rule-based
heuristics. Auto-research answers it: generate variants under each strategy,
score them on objective constraint-satisfaction metrics, see which wins.

Run:
  python tools/placement_research.py            # default: 200 seeds per strategy
  python tools/placement_research.py --seeds=50 # quick
  python tools/placement_research.py --report   # print only, don't re-run

Output: doc/placement_research/results.json + summary table on stdout.
"""
from __future__ import annotations

import argparse
import json
import math
import random
import sys
import io
from dataclasses import dataclass, asdict, field
from pathlib import Path
from typing import Optional

# UTF-8 stdout for any unicode in artifact descriptions.
try:
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
except Exception:
    pass

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "doc" / "placement_research"
OUT_DIR.mkdir(parents=True, exist_ok=True)


# ─────────────────────────────────────────────────────────────────────
# Test artifacts — 4 with distinct spatial_needs profiles
# ─────────────────────────────────────────────────────────────────────

@dataclass
class Artifact:
    lookup_name: str
    footprint_cells: int
    clearance_front: int
    clearance_back: int
    clearance_left: int
    clearance_right: int
    player_position: str   # 'front' | 'back' | 'around'
    wall_backing: bool
    orientation: str
    isolation: int          # cells of empty around required
    cluster_with: list[str] = field(default_factory=list)
    preferred_zone: str = "any"   # 'entry' | 'center' | 'back' | 'any'

    def footprint_dim(self) -> tuple[int, int]:
        """Approximate footprint as a square. footprint_cells = w*d, prefer square."""
        s = max(1, int(round(math.sqrt(self.footprint_cells))))
        return (s, s)


TEST_ARTIFACTS: list[Artifact] = [
    # 1. Small interactive — anywhere
    Artifact(
        lookup_name="GaussianBlurCircle",
        footprint_cells=1, clearance_front=1, clearance_back=1,
        clearance_left=1, clearance_right=1,
        player_position="front", wall_backing=False,
        orientation="face_approach", isolation=0,
        preferred_zone="any",
    ),
    # 2. Wall-backing display (entry)
    Artifact(
        lookup_name="2d_in_3d_randomness_vis",
        footprint_cells=3, clearance_front=1, clearance_back=1,
        clearance_left=1, clearance_right=1,
        player_position="front", wall_backing=True,
        orientation="face_approach", isolation=0,
        preferred_zone="entry",
    ),
    # 3. CENTERPIECE — big, room-scale, isolated, demands centre attention
    Artifact(
        lookup_name="gallery_winner_showcase",
        footprint_cells=8, clearance_front=3, clearance_back=2,
        clearance_left=2, clearance_right=2,
        player_position="front", wall_backing=False,
        orientation="face_approach", isolation=1,
        preferred_zone="center",
    ),
    # 4. Cluster anchor — pulls siblings to it
    Artifact(
        lookup_name="FlowFieldMain",
        footprint_cells=5, clearance_front=2, clearance_back=2,
        clearance_left=2, clearance_right=2,
        player_position="front", wall_backing=False,
        orientation="face_approach", isolation=0,
        cluster_with=["GaussianBlurCircle", "neon_wave_grid"],
        preferred_zone="entry",
    ),
    # 5. Wall display (second one — for the back)
    Artifact(
        lookup_name="affect_theory_visualization",
        footprint_cells=2, clearance_front=1, clearance_back=0,
        clearance_left=1, clearance_right=1,
        player_position="front", wall_backing=True,
        orientation="face_approach", isolation=0,
        preferred_zone="back",
    ),
    # 6. Medium centre-zone artifact (companion to centerpiece)
    Artifact(
        lookup_name="neon_wave_grid",
        footprint_cells=4, clearance_front=2, clearance_back=1,
        clearance_left=1, clearance_right=1,
        player_position="front", wall_backing=False,
        orientation="face_approach", isolation=0,
        preferred_zone="center",
    ),
    # 7. Small atomic display — anywhere
    Artifact(
        lookup_name="point",
        footprint_cells=1, clearance_front=1, clearance_back=1,
        clearance_left=1, clearance_right=1,
        player_position="front", wall_backing=False,
        orientation="face_approach", isolation=0,
        preferred_zone="any",
    ),
]


# ─────────────────────────────────────────────────────────────────────
# Room — 10 wide × 6 deep, spawn at back-centre
# ─────────────────────────────────────────────────────────────────────

@dataclass
class Room:
    width: int = 12
    depth: int = 8
    spawn_row: int = 7      # back row
    spawn_col: int = 6      # centre-ish
    teleporter_row: int = 0
    teleporter_col: int = 6

    def __post_init__(self) -> None:
        # Map JSON stores dimensions as floats (e.g. depth: 20.0); these fields
        # feed range() and grid indexing, which require ints. Coerce here so every
        # construction path — room_from_map, defaults, future callers — is safe.
        self.width = int(self.width)
        self.depth = int(self.depth)
        self.spawn_row = int(self.spawn_row)
        self.spawn_col = int(self.spawn_col)
        self.teleporter_row = int(self.teleporter_row)
        self.teleporter_col = int(self.teleporter_col)

    def cells(self) -> list[tuple[int, int]]:
        return [(r, c) for r in range(self.depth) for c in range(self.width)]

    def in_bounds(self, r: int, c: int) -> bool:
        return 0 <= r < self.depth and 0 <= c < self.width

    def on_wall(self, r: int, c: int) -> bool:
        return r == 0 or r == self.depth - 1 or c == 0 or c == self.width - 1

    def zone_of(self, r: int, c: int) -> str:
        """entry = back third (high r), center = middle third, back = front third (low r)."""
        if r >= 2 * self.depth // 3:
            return "entry"
        elif r <= self.depth // 3:
            return "back"
        return "center"


# ─────────────────────────────────────────────────────────────────────
# Placement representation
# ─────────────────────────────────────────────────────────────────────

@dataclass
class Placement:
    artifact: Artifact
    row: int
    col: int
    rotation: int = 0   # 0/90/180/270 — affects which side is 'front'

    def footprint_cells_occupied(self) -> list[tuple[int, int]]:
        w, d = self.artifact.footprint_dim()
        return [(self.row + dr, self.col + dc)
                for dr in range(d) for dc in range(w)]

    def clearance_cells(self) -> list[tuple[int, int]]:
        """All cells in the artifact's clearance ring."""
        w, d = self.artifact.footprint_dim()
        a = self.artifact
        out: list[tuple[int, int]] = []
        # front clearance: cells in front (depending on rotation)
        for k in range(1, a.clearance_front + 1):
            out.append((self.row + d - 1 + k, self.col + w // 2))
        for k in range(1, a.clearance_back + 1):
            out.append((self.row - k, self.col + w // 2))
        for k in range(1, a.clearance_left + 1):
            out.append((self.row + d // 2, self.col - k))
        for k in range(1, a.clearance_right + 1):
            out.append((self.row + d // 2, self.col + w + k - 1))
        return out


# ─────────────────────────────────────────────────────────────────────
# Scoring — same constraint set across strategies, no strategy-specific bias
# ─────────────────────────────────────────────────────────────────────

def bfs_reachable(room: Room, blocked: set[tuple[int, int]]) -> set[tuple[int, int]]:
    """BFS from spawn through cells not in `blocked`."""
    start = (room.spawn_row, room.spawn_col)
    visited: set[tuple[int, int]] = set()
    if start in blocked:
        return visited
    frontier = [start]
    visited.add(start)
    while frontier:
        nxt = []
        for (r, c) in frontier:
            for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nr, nc = r + dr, c + dc
                if not room.in_bounds(nr, nc):
                    continue
                if (nr, nc) in visited:
                    continue
                if (nr, nc) in blocked:
                    continue
                visited.add((nr, nc))
                nxt.append((nr, nc))
        frontier = nxt
    return visited


def score_placement(room: Room, placements: list[Placement]) -> dict:
    """Score a complete placement. Returns dict of metric→[0,1] plus total."""

    metrics: dict = {}

    # Build occupied set
    occupied: set[tuple[int, int]] = set()
    for p in placements:
        for cell in p.footprint_cells_occupied():
            occupied.add(cell)

    # 1. footprint_in_bounds: all artifact cells in room
    in_bounds = 0
    for p in placements:
        if all(room.in_bounds(r, c) for (r, c) in p.footprint_cells_occupied()):
            in_bounds += 1
    metrics["footprint_in_bounds"] = in_bounds / len(placements)

    # 2. no_overlap: no two artifacts overlap
    cell_counts: dict[tuple[int, int], int] = {}
    for p in placements:
        for cell in p.footprint_cells_occupied():
            cell_counts[cell] = cell_counts.get(cell, 0) + 1
    overlaps = sum(1 for v in cell_counts.values() if v > 1)
    metrics["no_overlap"] = 1.0 if overlaps == 0 else max(0.0, 1.0 - overlaps / 5.0)

    # 3. clearance_satisfied: each artifact's clearance cells are walkable
    clearance_ok = 0
    for p in placements:
        ring = p.clearance_cells()
        if not ring:
            clearance_ok += 1
            continue
        my_cells = set(p.footprint_cells_occupied())
        bad = 0
        for cell in ring:
            if not room.in_bounds(*cell):
                bad += 1
                continue
            if cell in occupied and cell not in my_cells:
                bad += 1
        if bad == 0:
            clearance_ok += 1
        else:
            clearance_ok += max(0.0, 1.0 - bad / max(1, len(ring)))
    metrics["clearance_satisfied"] = clearance_ok / len(placements)

    # 4. wall_backing_satisfied: when required, the artifact's footprint
    #    must touch EITHER the front wall (row 0) OR the back wall (row depth-1)
    #    OR side walls. Round 3 fix: previously only checked artifact's TOP row,
    #    so an artifact at rows 4-5 (touching back wall row 5) failed the check.
    backed_ok = 0
    needs_backing = 0
    for p in placements:
        if not p.artifact.wall_backing:
            continue
        needs_backing += 1
        w, d = p.artifact.footprint_dim()
        # Any footprint cell on any wall counts
        cells = p.footprint_cells_occupied()
        if any(r == 0 or r == room.depth - 1 or c == 0 or c == room.width - 1
               for (r, c) in cells):
            backed_ok += 1
    metrics["wall_backing_satisfied"] = (backed_ok / needs_backing) if needs_backing > 0 else 1.0

    # 5. isolation_satisfied: artifacts requiring isolation have no neighbours within radius
    iso_ok = 0
    iso_needed = 0
    for p in placements:
        if p.artifact.isolation <= 0:
            continue
        iso_needed += 1
        my_cells = set(p.footprint_cells_occupied())
        radius = p.artifact.isolation
        ring_cells = []
        for (r, c) in my_cells:
            for dr in range(-radius, radius + 1):
                for dc in range(-radius, radius + 1):
                    if dr == 0 and dc == 0: continue
                    nr, nc = r + dr, c + dc
                    if (nr, nc) in my_cells: continue
                    ring_cells.append((nr, nc))
        violations = sum(1 for cell in ring_cells
                         if cell in occupied)
        if violations == 0:
            iso_ok += 1
        else:
            iso_ok += max(0.0, 1.0 - violations / 10.0)
    metrics["isolation_satisfied"] = (iso_ok / iso_needed) if iso_needed > 0 else 1.0

    # 6. cluster_satisfied: cluster members are within 3-cell radius
    cluster_ok = 0
    cluster_needed = 0
    name_to_p: dict[str, Placement] = {p.artifact.lookup_name: p for p in placements}
    for p in placements:
        if not p.artifact.cluster_with:
            continue
        for partner_name in p.artifact.cluster_with:
            if partner_name not in name_to_p:
                continue
            cluster_needed += 1
            other = name_to_p[partner_name]
            # Distance between centers
            cx = p.col + p.artifact.footprint_dim()[0] / 2
            cy = p.row + p.artifact.footprint_dim()[1] / 2
            ox = other.col + other.artifact.footprint_dim()[0] / 2
            oy = other.row + other.artifact.footprint_dim()[1] / 2
            d = math.hypot(cx - ox, cy - oy)
            cluster_ok += max(0.0, 1.0 - max(0, d - 3) / 6.0)
    metrics["cluster_satisfied"] = (cluster_ok / cluster_needed) if cluster_needed > 0 else 1.0

    # 7. preferred_zone_match
    zone_ok = 0
    zone_needed = 0
    for p in placements:
        if p.artifact.preferred_zone == "any":
            continue
        zone_needed += 1
        zone = room.zone_of(p.row, p.col)
        if zone == p.artifact.preferred_zone:
            zone_ok += 1
        else:
            zone_ok += 0.3  # partial credit for being in the room
    metrics["preferred_zone_match"] = (zone_ok / zone_needed) if zone_needed > 0 else 1.0

    # 8. reachability: BFS from spawn reaches every artifact
    blocked = set()
    for p in placements:
        for cell in p.footprint_cells_occupied():
            blocked.add(cell)
    # spawn + teleporter cells must remain reachable
    blocked.discard((room.spawn_row, room.spawn_col))
    blocked.discard((room.teleporter_row, room.teleporter_col))
    reachable = bfs_reachable(room, blocked)
    reach_ok = 0
    for p in placements:
        # an artifact is "reachable" if any adjacent cell is in `reachable`
        my_cells = set(p.footprint_cells_occupied())
        adj = set()
        for (r, c) in my_cells:
            for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                adj.add((r + dr, c + dc))
        adj -= my_cells
        if any(cell in reachable for cell in adj):
            reach_ok += 1
    metrics["reachability"] = reach_ok / len(placements)

    # 9. spawn_walkable: spawn cell is not blocked
    metrics["spawn_walkable"] = 1.0 if (room.spawn_row, room.spawn_col) not in occupied else 0.0

    # 10. teleporter_walkable: teleporter cell is not blocked
    metrics["teleporter_walkable"] = 1.0 if (room.teleporter_row, room.teleporter_col) not in occupied else 0.0

    # Total: weighted average
    weights = {
        "footprint_in_bounds":    2.0,   # hard constraint
        "no_overlap":             2.0,   # hard constraint
        "clearance_satisfied":    1.5,
        "wall_backing_satisfied": 1.0,
        "isolation_satisfied":    1.0,
        "cluster_satisfied":      0.8,
        "preferred_zone_match":   0.8,
        "reachability":           2.0,   # hard
        "spawn_walkable":         1.5,
        "teleporter_walkable":    1.5,
    }
    total_w = sum(weights.values())
    total = sum(metrics[k] * w for k, w in weights.items()) / total_w
    metrics["total"] = round(total, 4)
    return metrics


# ─────────────────────────────────────────────────────────────────────
# Strategy 1 — RANDOM baseline
# ─────────────────────────────────────────────────────────────────────

def strategy_random(room: Room, artifacts: list[Artifact], rng: random.Random) -> list[Placement]:
    placements = []
    used: set[tuple[int, int]] = set()
    for a in artifacts:
        w, d = a.footprint_dim()
        for _ in range(50):  # try up to 50 times
            r = rng.randint(0, room.depth - d)
            c = rng.randint(0, room.width - w)
            cells = {(r + dr, c + dc) for dr in range(d) for dc in range(w)}
            if cells & used:
                continue
            if (room.spawn_row, room.spawn_col) in cells:
                continue
            if (room.teleporter_row, room.teleporter_col) in cells:
                continue
            placements.append(Placement(a, r, c))
            used.update(cells)
            break
        else:
            # fallback — place at (0,0) even if overlapping
            placements.append(Placement(a, 0, 0))
    return placements


# ─────────────────────────────────────────────────────────────────────
# Strategy 2 — RULE-BASED (replicates placement_rules.json + R4 template)
# ─────────────────────────────────────────────────────────────────────

def strategy_rule_based(room: Room, artifacts: list[Artifact], rng: random.Random) -> list[Placement]:
    """Apply rules in priority: wall_backing first → preferred_zone → cluster → fill."""
    placements: list[Placement] = []
    used: set[tuple[int, int]] = set()

    def reserve(p: Placement) -> bool:
        cells = set(p.footprint_cells_occupied())
        if cells & used: return False
        if (room.spawn_row, room.spawn_col) in cells: return False
        if (room.teleporter_row, room.teleporter_col) in cells: return False
        placements.append(p)
        used.update(cells)
        return True

    # First pass: wall_backing artifacts get the back wall (row 0)
    for a in artifacts:
        if not a.wall_backing: continue
        w, d = a.footprint_dim()
        for c in rng.sample(range(0, room.width - w + 1), room.width - w + 1):
            p = Placement(a, 0, c)
            if reserve(p):
                break

    # Second pass: preferred_zone="center" gets the middle
    for a in artifacts:
        if a in [p.artifact for p in placements]: continue
        if a.preferred_zone != "center": continue
        w, d = a.footprint_dim()
        cr = room.depth // 2 - d // 2
        cc = room.width // 2 - w // 2
        # try shifts
        for dr in [0, -1, 1, -2, 2]:
            for dc in [0, -1, 1, -2, 2]:
                if reserve(Placement(a, cr + dr, cc + dc)):
                    break
            else:
                continue
            break

    # Third pass: cluster_with — place near partner
    name_to_p = {p.artifact.lookup_name: p for p in placements}
    for a in artifacts:
        if a in [p.artifact for p in placements]: continue
        if not a.cluster_with: continue
        partner = next((name_to_p[n] for n in a.cluster_with if n in name_to_p), None)
        if partner is None: continue
        w, d = a.footprint_dim()
        # try concentric rings around partner
        for radius in range(2, 6):
            placed = False
            for dr in range(-radius, radius + 1):
                for dc in range(-radius, radius + 1):
                    if max(abs(dr), abs(dc)) != radius: continue
                    r = partner.row + dr
                    c = partner.col + dc
                    if not (0 <= r <= room.depth - d): continue
                    if not (0 <= c <= room.width - w): continue
                    if reserve(Placement(a, r, c)):
                        placed = True; break
                if placed: break
            if placed: break

    # Fourth pass: fill remaining at preferred_zone="entry" — back third
    for a in artifacts:
        if a in [p.artifact for p in placements]: continue
        w, d = a.footprint_dim()
        zone_row = room.depth - d - 1 if a.preferred_zone == "entry" else room.depth // 2
        for tries in range(30):
            r = max(0, min(room.depth - d, zone_row + rng.randint(-1, 1)))
            c = rng.randint(0, room.width - w)
            if reserve(Placement(a, r, c)):
                break

    return placements


# ─────────────────────────────────────────────────────────────────────
# Strategy 3 — SDF (distance fields)
# ─────────────────────────────────────────────────────────────────────

def strategy_sdf(room: Room, artifacts: list[Artifact], rng: random.Random) -> list[Placement]:
    """Place each artifact at the position MAXIMIZING the composed SDF.

    Each previously-placed artifact contributes a negative SDF lobe
    (footprint+clearance). New artifact picks the point with highest
    composed SDF value (farthest from any obstacle), within zone preference.
    """
    placements: list[Placement] = []
    # Obstacles: cells with negative SDF contribution
    # spawn, teleporter, and prior artifact footprints

    def sdf_at(r: float, c: float) -> float:
        """Composed SDF — positive = open space, negative = inside obstacle."""
        # Distance to room walls (positive when inside)
        d_wall = min(r, c, room.depth - 1 - r, room.width - 1 - c)
        # Distance to spawn (treat as small obstacle, want clearance)
        d_spawn = math.hypot(r - room.spawn_row, c - room.spawn_col) - 0.5
        # Distance to teleporter
        d_tele = math.hypot(r - room.teleporter_row, c - room.teleporter_col) - 0.5
        # Distance to existing placements (their footprint + clearance radius)
        d_prior = []
        for p in placements:
            w, d = p.artifact.footprint_dim()
            cx = p.col + w / 2
            cy = p.row + d / 2
            req_radius = max(w, d) / 2 + max(
                p.artifact.clearance_front, p.artifact.clearance_back,
                p.artifact.clearance_left, p.artifact.clearance_right
            )
            d_prior.append(math.hypot(r - cy, c - cx) - req_radius)

        candidates = [d_wall, d_spawn, d_tele] + d_prior
        return min(candidates)

    # Order artifacts: large first (room.center loving), then by footprint
    order = sorted(range(len(artifacts)), key=lambda i: -artifacts[i].footprint_cells)

    for idx in order:
        a = artifacts[idx]
        w, d = a.footprint_dim()
        best = None
        best_score = -1e9
        # Sample all valid cell origins; pick the one with highest SDF
        for r in range(room.depth - d + 1):
            for c in range(room.width - w + 1):
                # SDF at center of footprint
                center_r = r + d / 2 - 0.5
                center_c = c + w / 2 - 0.5
                sdf_val = sdf_at(center_r, center_c)
                # Need enough room for own footprint + clearance
                req = max(w, d) / 2 + 0.5
                if sdf_val < req - 0.5:  # not enough space — penalize but don't reject
                    sdf_val -= 5.0

                # Bonus for matching preferred_zone
                zone = room.zone_of(r, c)
                if zone == a.preferred_zone:
                    sdf_val += 1.5
                elif a.preferred_zone == "any":
                    pass
                else:
                    sdf_val -= 0.3

                # Bonus for wall_backing satisfaction
                if a.wall_backing:
                    if r == 0:
                        sdf_val += 3.0
                    else:
                        sdf_val -= 2.0

                # Bonus for cluster proximity
                name_to_p = {p.artifact.lookup_name: p for p in placements}
                for partner_name in a.cluster_with:
                    if partner_name in name_to_p:
                        pp = name_to_p[partner_name]
                        partner_cx = pp.col + pp.artifact.footprint_dim()[0] / 2
                        partner_cy = pp.row + pp.artifact.footprint_dim()[1] / 2
                        dist = math.hypot(center_r - partner_cy, center_c - partner_cx)
                        sdf_val += max(0, 2.0 - abs(dist - 3))  # peak at distance 3

                # Tiny random jitter so ties don't always go to the same cell
                sdf_val += rng.random() * 0.01

                if sdf_val > best_score:
                    best_score = sdf_val
                    best = (r, c)

        if best is not None:
            placements.append(Placement(a, best[0], best[1]))

    return placements


# ─────────────────────────────────────────────────────────────────────
# Strategy 4 — FOLD relaxation (constraint energy minimization)
# ─────────────────────────────────────────────────────────────────────

def strategy_fold(room: Room, artifacts: list[Artifact], rng: random.Random) -> list[Placement]:
    """Start with random placement, then iteratively 'fold' (relax) by
    moving artifacts to reduce constraint-violation energy.

    Energy function includes spawn/teleporter preservation now —
    blocking either is a high-energy state.
    """
    # Initial: random valid placement (like strategy_random)
    placements = strategy_random(room, artifacts, rng)

    def energy(ps: list[Placement]) -> float:
        """Total constraint-violation energy. Lower = better."""
        e = 0.0
        # Pairwise repulsion based on clearance requirements
        for i in range(len(ps)):
            for j in range(i + 1, len(ps)):
                pa, pb = ps[i], ps[j]
                wa, da = pa.artifact.footprint_dim()
                wb, db = pb.artifact.footprint_dim()
                cax = pa.col + wa / 2; cay = pa.row + da / 2
                cbx = pb.col + wb / 2; cby = pb.row + db / 2
                d = math.hypot(cax - cbx, cay - cby)
                req = (max(wa, da) + max(wb, db)) / 2 + 2  # +2 clearance
                if d < req:
                    e += (req - d) ** 2
            # Wall_backing
            if ps[i].artifact.wall_backing:
                if ps[i].row > 0:
                    e += ps[i].row * 2.0
            # Cluster_with attraction
            name_to_p = {p.artifact.lookup_name: p for p in ps}
            for partner in ps[i].artifact.cluster_with:
                if partner in name_to_p:
                    pp = name_to_p[partner]
                    pcx = pp.col + pp.artifact.footprint_dim()[0] / 2
                    pcy = pp.row + pp.artifact.footprint_dim()[1] / 2
                    icx = ps[i].col + ps[i].artifact.footprint_dim()[0] / 2
                    icy = ps[i].row + ps[i].artifact.footprint_dim()[1] / 2
                    d = math.hypot(icx - pcx, icy - pcy)
                    target = 3.0
                    e += (d - target) ** 2 * 0.3
            # Preferred zone
            if ps[i].artifact.preferred_zone != "any":
                if room.zone_of(ps[i].row, ps[i].col) != ps[i].artifact.preferred_zone:
                    e += 1.0
            # Spawn / teleporter occupation — HIGH ENERGY (fix from round 1)
            cells = set(ps[i].footprint_cells_occupied())
            if (room.spawn_row, room.spawn_col) in cells:
                e += 30.0
            if (room.teleporter_row, room.teleporter_col) in cells:
                e += 30.0
        return e

    # Greedy relaxation: try moving each artifact ±1 in each direction; keep if E drops
    for iteration in range(40):
        improved = False
        for i in range(len(placements)):
            current_e = energy(placements)
            best_e = current_e
            best_move: Optional[tuple[int, int]] = None
            a = placements[i].artifact
            w, d = a.footprint_dim()
            for dr in [-1, 0, 1]:
                for dc in [-1, 0, 1]:
                    if dr == 0 and dc == 0: continue
                    new_r = placements[i].row + dr
                    new_c = placements[i].col + dc
                    if not (0 <= new_r <= room.depth - d): continue
                    if not (0 <= new_c <= room.width - w): continue
                    saved = (placements[i].row, placements[i].col)
                    placements[i].row, placements[i].col = new_r, new_c
                    new_e = energy(placements)
                    if new_e < best_e:
                        best_e = new_e
                        best_move = (new_r, new_c)
                    placements[i].row, placements[i].col = saved
            if best_move is not None:
                placements[i].row, placements[i].col = best_move
                improved = True
        if not improved:
            break

    return placements


# ─────────────────────────────────────────────────────────────────────
# Strategy 5 — PARADOXICAL (Gödel) — allow constraint violation for coverage
# ─────────────────────────────────────────────────────────────────────

def strategy_paradoxical(room: Room, artifacts: list[Artifact], rng: random.Random) -> list[Placement]:
    """Place artifacts at carefully-distributed grid points to maximize
    coverage of the room, accepting some constraint violation in exchange.

    The Gödel-ish move: refuse the consistency requirement (every constraint
    must be satisfied), trade some satisfaction for guaranteed coverage of
    the room's whole spatial range. Round 2: still distributes to quadrants
    but now PUSHES away from collisions when planted cells overlap.
    """
    placements: list[Placement] = []
    used: set[tuple[int, int]] = set()

    def try_place(a: Artifact, target_r: int, target_c: int) -> bool:
        w, d = a.footprint_dim()
        # Spiral search outward from target
        for radius in range(0, max(room.depth, room.width)):
            for dr in range(-radius, radius + 1):
                for dc in range(-radius, radius + 1):
                    if radius > 0 and max(abs(dr), abs(dc)) != radius:
                        continue
                    r = max(0, min(room.depth - d, target_r + dr))
                    c = max(0, min(room.width - w, target_c + dc))
                    cells = {(r + di, c + dj) for di in range(d) for dj in range(w)}
                    if cells & used: continue
                    if (room.spawn_row, room.spawn_col) in cells: continue
                    if (room.teleporter_row, room.teleporter_col) in cells: continue
                    placements.append(Placement(a, r, c))
                    used.update(cells)
                    return True
        return False

    # Order artifacts: wall_backing first (will go to row 0),
    # then center-zone, then cluster, then rest
    quads = [
        (1, 1),
        (1, room.width - 2),
        (room.depth - 2, 1),
        (room.depth - 2, room.width - 2),
    ]
    sorted_arts = sorted(artifacts, key=lambda a: (
        not a.wall_backing,
        a.preferred_zone != "center",
        -a.footprint_cells,
    ))

    q_idx = 0
    for a in sorted_arts:
        if a.wall_backing:
            # Try along back wall (row 0)
            placed = False
            for c in range(0, room.width - a.footprint_dim()[0] + 1):
                if try_place(a, 0, c):
                    placed = True; break
            if not placed:
                try_place(a, 0, 0)
        elif a.preferred_zone == "center":
            try_place(a, room.depth // 2, room.width // 2)
        else:
            # Use next quadrant — rotates so we get coverage
            target = quads[q_idx % len(quads)]
            q_idx += 1
            try_place(a, target[0], target[1])

    return placements


# ─────────────────────────────────────────────────────────────────────
# Strategy 6 — HYBRID: SDF math + rule-based ordering
# ─────────────────────────────────────────────────────────────────────

def strategy_hybrid(room: Room, artifacts: list[Artifact], rng: random.Random) -> list[Placement]:
    """Best of both: SDF for the geometry (composed distance fields find
    open space), rule-based ORDERING (wall_backing first, center next,
    cluster last) for the priority. Test hypothesis from round 1.
    """
    placements: list[Placement] = []

    def sdf_at(r: float, c: float, skip_walls: bool = False) -> float:
        """Composed SDF. When skip_walls=True, exclude wall distance — used
        for wall_backing artifacts that WANT to be against the wall."""
        terms = []
        if not skip_walls:
            terms.append(min(r, c, room.depth - 1 - r, room.width - 1 - c))
        terms.append(math.hypot(r - room.spawn_row, c - room.spawn_col) - 0.7)
        terms.append(math.hypot(r - room.teleporter_row, c - room.teleporter_col) - 0.7)
        for p in placements:
            w, d = p.artifact.footprint_dim()
            cx = p.col + w / 2; cy = p.row + d / 2
            req_radius = max(w, d) / 2 + max(
                p.artifact.clearance_front, p.artifact.clearance_back,
                p.artifact.clearance_left, p.artifact.clearance_right
            ) * 0.5
            terms.append(math.hypot(r - cy, c - cx) - req_radius)
        return min(terms)

    def best_pos(a: Artifact) -> tuple[int, int]:
        w, d = a.footprint_dim()
        best = (0, 0)
        best_score = -1e9
        # KEY FIX from round 2: wall_backing artifacts ignore wall SDF
        skip_walls = a.wall_backing
        for r in range(room.depth - d + 1):
            for c in range(room.width - w + 1):
                cy = r + d / 2 - 0.5
                cx = c + w / 2 - 0.5
                sdf_val = sdf_at(cy, cx, skip_walls=skip_walls)
                # Required openness based on footprint+clearance
                req = max(w, d) / 2 + 0.5
                if sdf_val < req - 0.5:
                    sdf_val -= 8.0  # large penalty
                # Strong zone bias (this is the rule-based contribution)
                zone = room.zone_of(r, c)
                if zone == a.preferred_zone:
                    sdf_val += 2.5
                elif a.preferred_zone == "any":
                    pass
                else:
                    sdf_val -= 0.5
                # Wall backing — STRONG bonus for r=0 OR r=depth-1 when required
                if a.wall_backing:
                    if r == 0 or r + d == room.depth:
                        sdf_val += 6.0
                    else:
                        sdf_val -= 3.0
                # Cluster pull
                name_to_p = {p.artifact.lookup_name: p for p in placements}
                for partner_name in a.cluster_with:
                    if partner_name in name_to_p:
                        pp = name_to_p[partner_name]
                        pcx = pp.col + pp.artifact.footprint_dim()[0] / 2
                        pcy = pp.row + pp.artifact.footprint_dim()[1] / 2
                        dist = math.hypot(cy - pcy, cx - pcx)
                        sdf_val += max(0, 3.0 - abs(dist - 3))
                sdf_val += rng.random() * 0.01
                if sdf_val > best_score:
                    best_score = sdf_val
                    best = (r, c)
        return best

    # Rule-based ORDERING: wall first, then center, then cluster, then rest
    order_key = lambda a: (
        0 if a.wall_backing else 1,
        0 if a.preferred_zone == "center" else 1,
        0 if a.cluster_with else 1,
        -a.footprint_cells,  # larger first within tier
    )
    for a in sorted(artifacts, key=order_key):
        r, c = best_pos(a)
        placements.append(Placement(a, r, c))

    return placements


# ─────────────────────────────────────────────────────────────────────
# Strategy 7 — CIRCLE PACKING (classical computational geometry)
# ─────────────────────────────────────────────────────────────────────

def strategy_circle_packing(room: Room, artifacts: list[Artifact], rng: random.Random) -> list[Placement]:
    """Treat each artifact as a circle of radius = footprint+clearance,
    pack non-overlapping into the room. Iterative front-and-back algorithm:
    largest first, place at lowest valid corner, then push down/right.

    Used in real warehouse picking (NP-hard bin packing → 2D circle packing
    has the same family of approximation algorithms).
    """
    # Order: largest circles first
    sorted_arts = sorted(artifacts, key=lambda a: -(a.footprint_cells + max(
        a.clearance_front, a.clearance_back, a.clearance_left, a.clearance_right)))
    placements: list[Placement] = []
    occupied_circles: list[tuple[float, float, float]] = []  # (cy, cx, radius)
    # Pre-seed spawn + teleporter as circles
    occupied_circles.append((float(room.spawn_row), float(room.spawn_col), 0.6))
    occupied_circles.append((float(room.teleporter_row), float(room.teleporter_col), 0.6))

    for a in sorted_arts:
        w, d = a.footprint_dim()
        radius = max(w, d) / 2 + max(
            a.clearance_front, a.clearance_back, a.clearance_left, a.clearance_right
        ) * 0.4

        # Wall-backing artifacts: scan along walls first (front/back/left/right)
        candidates: list[tuple[int, int]] = []
        if a.wall_backing:
            for c in range(room.width - w + 1):
                candidates.append((0, c))
                candidates.append((room.depth - d, c))
            for r in range(room.depth - d + 1):
                candidates.append((r, 0))
                candidates.append((r, room.width - w))
        else:
            for r in range(room.depth - d + 1):
                for c in range(room.width - w + 1):
                    candidates.append((r, c))

        best = None
        best_overlap = 1e9
        for (r, c) in candidates:
            cy = r + d / 2; cx = c + w / 2
            overlap = 0.0
            for (oy, ox, orad) in occupied_circles:
                dist = math.hypot(cy - oy, cx - ox)
                if dist < radius + orad:
                    overlap += (radius + orad - dist) ** 2
            # Zone bias
            zone = room.zone_of(r, c)
            zbias = -2.0 if (zone == a.preferred_zone) else (0 if a.preferred_zone == "any" else 0.5)
            score = overlap + zbias
            if score < best_overlap:
                best_overlap = score; best = (r, c)
        if best is not None:
            placements.append(Placement(a, best[0], best[1]))
            bcy = best[0] + d / 2; bcx = best[1] + w / 2
            occupied_circles.append((bcy, bcx, radius))
    return placements


# ─────────────────────────────────────────────────────────────────────
# Strategy 8 — WAREHOUSE (Amazon-style frequency-based slotting)
# ─────────────────────────────────────────────────────────────────────

def strategy_warehouse(room: Room, artifacts: list[Artifact], rng: random.Random) -> list[Placement]:
    """Amazon-Kiva warehouse algorithm: high-frequency items near the
    pickup point (spawn), low-frequency items deeper. 'Frequency' for
    artifacts is approximated by:
       - large footprint = centerpiece = HIGH priority (player will visit)
       - clustered artifacts = co-visited = same shelf-row
       - small/isolated = low priority = deep slots

    The cost function is travel-distance × visit-frequency. Minimize total.
    """
    # Assign priority: footprint_cells × 1 + isolation × 2 + (1.5 if center-zone)
    def priority(a: Artifact) -> float:
        p = a.footprint_cells * 1.0
        p += 1.5 if a.preferred_zone == "center" else 0
        p += 1.0 if a.cluster_with else 0
        p += 0.5 if a.wall_backing else 0
        return p

    sorted_arts = sorted(artifacts, key=lambda a: -priority(a))
    placements: list[Placement] = []
    used: set[tuple[int, int]] = set()

    # "Pickup point" = spawn. Build distance map from spawn.
    def cost_at(r: int, c: int, a: Artifact) -> float:
        # Manhattan distance from spawn × visit weight
        dist = abs(r - room.spawn_row) + abs(c - room.spawn_col)
        visit_weight = priority(a) / 10.0  # high = wants to be close
        # If artifact wants to be CENTER, override with center cost
        if a.preferred_zone == "center":
            return abs(r - room.depth // 2) + abs(c - room.width // 2)
        if a.preferred_zone == "entry":
            # High-frequency: minimize spawn distance (want close)
            return dist * visit_weight
        if a.preferred_zone == "back":
            return abs(r - 0) + abs(c - room.width // 2)
        return dist * 0.5

    for a in sorted_arts:
        w, d = a.footprint_dim()
        best = None
        best_cost = 1e9
        for r in range(room.depth - d + 1):
            for c in range(room.width - w + 1):
                cells = {(r + di, c + dj) for di in range(d) for dj in range(w)}
                if cells & used: continue
                if (room.spawn_row, room.spawn_col) in cells: continue
                if (room.teleporter_row, room.teleporter_col) in cells: continue
                cost = cost_at(r, c, a)
                # Wall-backing bonus when artifact requires it
                if a.wall_backing and not (r == 0 or r + d == room.depth
                                            or c == 0 or c + w == room.width):
                    cost += 5.0
                # Cluster: minimize distance to already-placed cluster partners
                name_to_p = {p.artifact.lookup_name: p for p in placements}
                for partner in a.cluster_with:
                    if partner in name_to_p:
                        pp = name_to_p[partner]
                        cost += abs(r - pp.row) + abs(c - pp.col)
                cost += rng.random() * 0.01
                if cost < best_cost:
                    best_cost = cost; best = (r, c)
        if best is not None:
            placements.append(Placement(a, best[0], best[1]))
            for di in range(d):
                for dj in range(w):
                    used.add((best[0] + di, best[1] + dj))
    return placements


# ─────────────────────────────────────────────────────────────────────
# Strategy 9 — SIMULATED ANNEALING (Isaac Gym / RL surrogate)
# ─────────────────────────────────────────────────────────────────────

def strategy_simulated_annealing(room: Room, artifacts: list[Artifact], rng: random.Random) -> list[Placement]:
    """Stand-in for RL placement (Isaac Gym uses massively-parallel PPO,
    but the optimization signal — accept worse moves with cooling probability
    to escape local minima — is the same shape).

    Start from a rule-based initialization, then anneal: temperature starts
    high (accept many bad moves), cools slowly, ends greedy.
    """
    # Initialize from rule_based
    placements = strategy_rule_based(room, list(artifacts), rng)

    def total_score(ps: list[Placement]) -> float:
        return score_placement(room, ps)["total"]

    current_score = total_score(placements)
    best_placements = [Placement(p.artifact, p.row, p.col) for p in placements]
    best_score = current_score

    temperature = 1.0
    cooling = 0.95
    n_steps = 100

    for step in range(n_steps):
        # Pick a random artifact, try a random new position
        i = rng.randint(0, len(placements) - 1)
        a = placements[i].artifact
        w, d = a.footprint_dim()
        new_r = rng.randint(0, room.depth - d)
        new_c = rng.randint(0, room.width - w)
        old_r, old_c = placements[i].row, placements[i].col
        placements[i].row, placements[i].col = new_r, new_c
        new_score = total_score(placements)
        delta = new_score - current_score
        if delta > 0:
            # accept improvement
            current_score = new_score
            if new_score > best_score:
                best_score = new_score
                best_placements = [Placement(p.artifact, p.row, p.col) for p in placements]
        elif rng.random() < math.exp(delta / max(0.001, temperature)):
            # accept downhill (escape local minimum)
            current_score = new_score
        else:
            # revert
            placements[i].row, placements[i].col = old_r, old_c
        temperature *= cooling

    return best_placements


# ─────────────────────────────────────────────────────────────────────
# Strategy 10 — VORONOI (maximize each artifact's territory)
# ─────────────────────────────────────────────────────────────────────

def strategy_voronoi(room: Room, artifacts: list[Artifact], rng: random.Random) -> list[Placement]:
    """Place artifacts at centroids of Voronoi cells that maximize each
    artifact's territory (cells closer to it than to any other). Uses
    Lloyd-style relaxation: place randomly, compute Voronoi assignment,
    move each artifact to the centroid of its cell, repeat.
    """
    # Initial random valid placement
    placements = strategy_random(room, list(artifacts), rng)

    for _ in range(8):
        # Voronoi assignment: each cell belongs to closest artifact center
        cell_owner: dict[tuple[int, int], int] = {}
        for r in range(room.depth):
            for c in range(room.width):
                if (r, c) in [(room.spawn_row, room.spawn_col),
                              (room.teleporter_row, room.teleporter_col)]:
                    continue
                best_i = 0
                best_d = 1e9
                for i, p in enumerate(placements):
                    w, d = p.artifact.footprint_dim()
                    cy = p.row + d / 2; cx = p.col + w / 2
                    dist = math.hypot(r - cy, c - cx)
                    if dist < best_d:
                        best_d = dist; best_i = i
                cell_owner[(r, c)] = best_i

        # Move each artifact to centroid of its cell
        new_placements = []
        for i, p in enumerate(placements):
            cells = [(r, c) for (r, c), owner in cell_owner.items() if owner == i]
            if not cells:
                new_placements.append(p)
                continue
            avg_r = sum(r for (r, _) in cells) / len(cells)
            avg_c = sum(c for (_, c) in cells) / len(cells)
            w, d = p.artifact.footprint_dim()
            new_r = max(0, min(room.depth - d, int(round(avg_r - d / 2))))
            new_c = max(0, min(room.width - w, int(round(avg_c - w / 2))))
            # Apply wall_backing constraint after centroid
            if p.artifact.wall_backing:
                # Snap to nearest wall
                wall_options = [(0, new_c), (room.depth - d, new_c),
                                (new_r, 0), (new_r, room.width - w)]
                wall_options.sort(key=lambda rc: abs(rc[0] - new_r) + abs(rc[1] - new_c))
                new_r, new_c = wall_options[0]
            new_placements.append(Placement(p.artifact, new_r, new_c))
        placements = new_placements

    return placements


# ─────────────────────────────────────────────────────────────────────
# Strategy 11 — HUMANOID WALKER (embodied sequential placement)
# Simulates an Amazon-style picker walking the room: enters at spawn,
# carries the artifact queue, at each step LOOKS at current cell, decides
# whether to PLACE the head-of-queue artifact here, then TWEAKS ±1 to
# improve local fit, then MOVES one step toward teleporter, avoiding what
# they've already placed.
#
# Differs from god-mode strategies: places ONE at a time, sees only LOCAL
# constraints from current pos, produces a TRAJECTORY (walk path + decisions)
# in addition to the placement. Local-optimal, not global-optimal — but
# the walk path mirrors how the player will actually traverse the room,
# so encounter-order is built-in.
# ─────────────────────────────────────────────────────────────────────

def strategy_humanoid_walker(room: Room, artifacts: list[Artifact], rng: random.Random,
                              trace: Optional[list] = None) -> list[Placement]:
    """Embodied walker. If `trace` is given, append (action, pos, artifact, score)
    tuples to it for later visualization."""

    def in_bounds(r: int, c: int) -> bool:
        return room.in_bounds(r, c)

    def occupied(placed: list[Placement]) -> set[tuple[int, int]]:
        out = set()
        for p in placed:
            for cell in p.footprint_cells_occupied():
                out.add(cell)
        return out

    def look_score(a: Artifact, r: int, c: int, placed: list[Placement]) -> float:
        """How good is (r,c) as a placement for `a`, looking from there?"""
        w, d = a.footprint_dim()
        # Bounds + don't crush placed
        for di in range(d):
            for dj in range(w):
                rr, cc = r + di, c + dj
                if not in_bounds(rr, cc): return -10
                if (rr, cc) == (room.spawn_row, room.spawn_col): return -10
                if (rr, cc) == (room.teleporter_row, room.teleporter_col): return -10
        occ = occupied(placed)
        my_cells = {(r + di, c + dj) for di in range(d) for dj in range(w)}
        if my_cells & occ: return -10
        # Constraint bonuses
        score = 1.0
        cells = list(my_cells)
        on_wall = any(rr == 0 or rr == room.depth - 1 or cc == 0 or cc == room.width - 1
                      for (rr, cc) in cells)
        if a.wall_backing and on_wall: score += 2.0
        elif a.wall_backing and not on_wall: score -= 1.5
        # Zone
        zone = room.zone_of(r, c)
        if zone == a.preferred_zone: score += 1.5
        elif a.preferred_zone == "any": pass
        else: score -= 0.5
        # Cluster — proximity to already-placed partners
        for partner_name in a.cluster_with:
            for p in placed:
                if p.artifact.lookup_name == partner_name:
                    pw, pd = p.artifact.footprint_dim()
                    pcx = p.col + pw / 2; pcy = p.row + pd / 2
                    icx = c + w / 2; icy = r + d / 2
                    dist = math.hypot(icx - pcx, icy - pcy)
                    score += max(0, 2.0 - abs(dist - 3.0))
        # Clearance — bonus if surrounding cells are mostly free
        free_around = 0
        for dr in [-1, 1]:
            for dc in [-1, 1]:
                nr, nc = r + dr, c + dc
                if in_bounds(nr, nc) and (nr, nc) not in occ:
                    free_around += 1
        score += free_around * 0.2
        return score

    def bfs_step(start: tuple[int, int], goal: tuple[int, int],
                 occ: set[tuple[int, int]]) -> Optional[tuple[int, int]]:
        """Return the FIRST step from start toward goal via BFS, avoiding occ.
        Returns None if no path."""
        if start == goal: return start
        from collections import deque
        prev: dict[tuple[int, int], Optional[tuple[int, int]]] = {start: None}
        q = deque([start])
        while q:
            cur = q.popleft()
            if cur == goal:
                # Reconstruct
                path = []
                while cur is not None:
                    path.append(cur)
                    cur = prev[cur]
                path.reverse()
                return path[1] if len(path) > 1 else path[0]
            for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nr, nc = cur[0] + dr, cur[1] + dc
                if not in_bounds(nr, nc): continue
                if (nr, nc) in prev: continue
                if (nr, nc) in occ and (nr, nc) != goal: continue
                prev[(nr, nc)] = cur
                q.append((nr, nc))
        return None

    # ── main loop ──
    pos = (room.spawn_row, room.spawn_col)
    teleporter = (room.teleporter_row, room.teleporter_col)
    placed: list[Placement] = []
    # Order queue: wall_backing first, then center-zone (likely centerpiece), then cluster
    queue = sorted(artifacts, key=lambda a: (
        0 if a.wall_backing else 1,
        0 if a.preferred_zone == "center" else 1,
        0 if a.preferred_zone == "entry" else 1,
        1 if a.cluster_with else 0,   # cluster members LATER (need partner placed first)
        -a.footprint_cells,           # larger first within tier
    ))

    PLACE_THRESHOLD = 1.5
    max_steps = room.depth * room.width * 2
    steps = 0
    if trace is not None:
        trace.append(("start", pos, None, 0.0))

    while queue and pos != teleporter and steps < max_steps:
        steps += 1
        artifact = queue[0]
        # LOOK at current cell as candidate
        s = look_score(artifact, pos[0], pos[1], placed)
        if trace is not None:
            trace.append(("look", pos, artifact.lookup_name, round(s, 2)))

        # Decide: place here or move on
        decide_place = s >= PLACE_THRESHOLD
        # If we're running out of steps, lower the bar
        if steps > max_steps * 0.6 and s > 0.5:
            decide_place = True

        if decide_place:
            new_p = Placement(artifact, pos[0], pos[1])
            placed.append(new_p)
            if trace is not None:
                trace.append(("place", pos, artifact.lookup_name, round(s, 2)))
            # LOOK AGAIN — try ±1 tweaks, keep best
            base_score = s
            best_pos = pos
            for dr in [-1, 0, 1]:
                for dc in [-1, 0, 1]:
                    if dr == 0 and dc == 0: continue
                    np = (pos[0] + dr, pos[1] + dc)
                    if not in_bounds(np[0], np[1]): continue
                    # Re-evaluate with placement at np (temporarily)
                    placed.pop()
                    s2 = look_score(artifact, np[0], np[1], placed)
                    placed.append(new_p)
                    if s2 > base_score + 0.3:    # meaningful improvement
                        base_score = s2
                        best_pos = np
            if best_pos != pos:
                new_p.row, new_p.col = best_pos
                if trace is not None:
                    trace.append(("tweak", best_pos, artifact.lookup_name, round(base_score, 2)))
            queue.pop(0)

        # MOVE one step toward teleporter (or away if it's still busy)
        occ = occupied(placed)
        # Want to keep walking — but pause if there are still artifacts and we're
        # not near a sensible spot yet. Step toward teleporter.
        next_pos = bfs_step(pos, teleporter, occ)
        if next_pos is None or next_pos == pos:
            # blocked — try lateral move
            for dr, dc in [(0, 1), (0, -1), (-1, 0), (1, 0)]:
                cand = (pos[0] + dr, pos[1] + dc)
                if in_bounds(*cand) and cand not in occ:
                    next_pos = cand
                    break
            else:
                break
        if trace is not None:
            trace.append(("move", next_pos, None, 0.0))
        pos = next_pos

    # If artifacts remain at the end, do a salvage pass: place them at the
    # best available open cell (god-mode fallback for whatever wasn't placed
    # during the walk). This prevents the strategy from leaving artifacts
    # un-placed when the walker hits the teleporter early.
    if queue:
        for a in queue:
            occ = occupied(placed)
            w, d = a.footprint_dim()
            best = None; best_s = -1e9
            for r in range(room.depth - d + 1):
                for c in range(room.width - w + 1):
                    s = look_score(a, r, c, placed)
                    if s > best_s:
                        best_s = s; best = (r, c)
            if best is not None:
                placed.append(Placement(a, best[0], best[1]))
                if trace is not None:
                    trace.append(("salvage", best, a.lookup_name, round(best_s, 2)))

    return placed


# ─────────────────────────────────────────────────────────────────────
# Strategy 12 — GROW WALKER (the map emerges from the walk)
# Inverts every other strategy. They take a fixed room and place INTO it.
# This one starts with an empty space and lays the floor AS the agent
# walks. Each step: extend floor ahead; if current cell suits an artifact,
# lay clearance around it, place a TABLE (height-2 cube) for small displays
# OR a flat floor patch for room-scale artifacts, then continue. When the
# queue is empty, the current cell becomes the teleporter.
#
# Output for placement_research: just placements (compatible with scorer).
# Real map output: see tools/grow_map.py — runs this strategy and reads
# the trace to assemble a complete map_data.json.
# ─────────────────────────────────────────────────────────────────────

def strategy_grow_walker(room: Room, artifacts: list[Artifact],
                          rng: random.Random,
                          trace: Optional[list] = None) -> list[Placement]:
    """Embodied + map-creating. The trace, if given, accumulates events
    AND the final laid_cells / tables sets so the map can be assembled."""

    laid: set[tuple[int, int]] = {(room.spawn_row, room.spawn_col)}
    tables: set[tuple[int, int]] = set()
    placements: list[Placement] = []

    # Walk direction: front of room (low row) if spawn is at back; otherwise the other way
    forward_dr = -1 if room.spawn_row > room.depth // 2 else 1

    def in_bounds(r: int, c: int) -> bool:
        return 0 <= r < room.depth and 0 <= c < room.width

    def lay(r: int, c: int) -> None:
        if in_bounds(r, c):
            laid.add((r, c))

    def occupied_by_placements() -> set[tuple[int, int]]:
        out: set[tuple[int, int]] = set()
        for p in placements:
            for cell in p.footprint_cells_occupied():
                out.add(cell)
        return out

    def is_frontier(r: int, c: int) -> bool:
        """Cell is at the edge of laid floor (has at least one unlaid neighbor)."""
        for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nr, nc = r + dr, c + dc
            if in_bounds(nr, nc) and (nr, nc) not in laid:
                return True
        return False

    def look_score(a: Artifact, r: int, c: int) -> float:
        """Score current cell as candidate for artifact a (in the GROWING context)."""
        w, d = a.footprint_dim()
        # Footprint must fit in room bounds
        for di in range(d):
            for dj in range(w):
                rr, cc = r + di, c + dj
                if not in_bounds(rr, cc): return -10.0
                if (rr, cc) == (room.spawn_row, room.spawn_col): return -10.0
        # Don't overlap existing placements
        my_cells = {(r + di, c + dj) for di in range(d) for dj in range(w)}
        if my_cells & occupied_by_placements():
            return -10.0
        score = 1.0
        # Wall_backing in grow context = at a FRONTIER (one or more sides unlaid)
        # — the artifact has "wall" because the floor doesn't continue behind it
        if a.wall_backing:
            if is_frontier(r, c): score += 2.0
            else: score -= 1.0
        # Zone: distance-fraction from spawn determines zone
        dist_from_spawn = abs(r - room.spawn_row) + abs(c - room.spawn_col)
        max_dist = room.depth + room.width
        frac = dist_from_spawn / max_dist
        if a.preferred_zone == "entry":
            score += max(0, 1.5 - frac * 3)   # closer to spawn = better
        elif a.preferred_zone == "back":
            score += max(0, frac * 3 - 0.5)   # farther = better
        elif a.preferred_zone == "center":
            score += max(0, 1.5 - abs(frac - 0.5) * 3)
        # Cluster: proximity to placed partners
        for partner_name in a.cluster_with:
            for p in placements:
                if p.artifact.lookup_name == partner_name:
                    pcx = p.col + p.artifact.footprint_dim()[0] / 2
                    pcy = p.row + p.artifact.footprint_dim()[1] / 2
                    icx = c + w / 2; icy = r + d / 2
                    dist = math.hypot(icx - pcx, icy - pcy)
                    score += max(0, 2.5 - abs(dist - 3.0))
        # Isolation: penalty if other placements are too close
        if a.isolation > 0:
            for p in placements:
                d_p = math.hypot(r - p.row, c - p.col)
                if d_p < a.isolation + 2:
                    score -= 1.0
        return score

    # ── Order the queue ──
    queue = sorted(artifacts, key=lambda a: (
        0 if a.wall_backing else 1,
        0 if a.preferred_zone == "entry" else 1,
        0 if a.preferred_zone == "center" else 1,
        1 if a.cluster_with else 0,   # cluster later (partner needs to be placed)
        -a.footprint_cells,
    ))

    PLACE_THRESHOLD = 1.5
    pos = (room.spawn_row, room.spawn_col)
    max_steps = room.depth * room.width
    steps = 0

    if trace is not None:
        trace.append(("start", pos, None, 0.0))

    while queue and steps < max_steps:
        steps += 1
        a = queue[0]
        s = look_score(a, pos[0], pos[1])

        if s >= PLACE_THRESHOLD:
            # PLACE — including laying clearance + (maybe) a table under it
            new_p = Placement(a, pos[0], pos[1])
            placements.append(new_p)
            # Lay clearance cells around (so player can walk to it)
            w, d = a.footprint_dim()
            for di in range(-a.clearance_back, d + a.clearance_front + 1):
                for dj in range(-a.clearance_left, w + a.clearance_right + 1):
                    rr, cc = pos[0] + di, pos[1] + dj
                    # Don't lay across isolation distance for isolated artifacts
                    if a.isolation > 0 and max(abs(di), abs(dj)) > 1:
                        continue
                    lay(rr, cc)
            # Decide: TABLE or floor
            use_table = (a.footprint_cells <= 2 and not a.wall_backing
                         and a.preferred_zone != "back")
            if use_table:
                # Mark the artifact's footprint cells as tables (height-2)
                for cell in new_p.footprint_cells_occupied():
                    tables.add(cell)
            if trace is not None:
                trace.append(("place_table" if use_table else "place_floor",
                              pos, a.lookup_name, round(s, 2)))
            queue.pop(0)

        # MOVE — step forward, laying a new floor cell if needed
        # Pick the best next step: prefer forward (toward 0 or depth-1),
        # prefer frontier cells to keep walking into new space
        best_next = None
        best_move_score = -1e9
        for dr, dc in [(forward_dr, 0), (0, 1), (0, -1), (-forward_dr, 0)]:
            nr, nc = pos[0] + dr, pos[1] + dc
            if not in_bounds(nr, nc): continue
            if (nr, nc) in occupied_by_placements(): continue
            # Prefer cells not yet laid (we're growing)
            move_score = 1.0 if (nr, nc) not in laid else -0.5
            # Prefer moving forward
            if dr == forward_dr: move_score += 0.8
            # Prefer moving away from spawn (no doubling back)
            d_from_spawn = abs(nr - room.spawn_row) + abs(nc - room.spawn_col)
            move_score += d_from_spawn * 0.05
            move_score += rng.random() * 0.05
            if move_score > best_move_score:
                best_move_score = move_score
                best_next = (nr, nc)

        if best_next is None:
            break
        lay(*best_next)
        pos = best_next
        if trace is not None:
            trace.append(("lay_step", pos, None, 0.0))

    # ── Fallback for unplaced artifacts: god-mode within laid floor ──
    for a in queue:
        w, d = a.footprint_dim()
        best = None; best_s = -1e9
        for (r, c) in sorted(laid):
            # Need to fit footprint; for grow context, allow extending laid
            for di in range(d):
                for dj in range(w):
                    if not in_bounds(r + di, c + dj):
                        break
                else:
                    continue
                break
            else:
                s = look_score(a, r, c)
                if s > best_s:
                    best_s = s; best = (r, c)
        if best is not None:
            placements.append(Placement(a, best[0], best[1]))
            # Lay clearance
            for di in range(-1, d + 1):
                for dj in range(-1, w + 1):
                    lay(best[0] + di, best[1] + dj)
            if trace is not None:
                trace.append(("salvage", best, a.lookup_name, round(best_s, 2)))

    # End: pos is the teleporter; ensure it's laid
    lay(*pos)
    if trace is not None:
        trace.append(("end_at_teleporter", pos, None, 0.0))
        # Side-channel: deposit the laid cells + tables so map writer can pick up
        trace.append(("__laid_cells__", tuple(sorted(laid)), None, 0))
        trace.append(("__tables__", tuple(sorted(tables)), None, 0))
        trace.append(("__teleporter_pos__", pos, None, 0))

    return placements


# ─────────────────────────────────────────────────────────────────────
# Strategy 13 — FOCAL COMPOSITION (interior design + Disney "weenie")
# Centerpiece at the visible-from-spawn position, supporting cast in
# arcs around it, negative space respected. Combines:
#   - interior design's focal point + supporting cast
#   - Disney's "weenie" (visible landmark drawing the player forward)
#   - Alexander's #131 (flow), #205 (structure follows social spaces)
#   - functionalism's group-by-function zoning
# ─────────────────────────────────────────────────────────────────────

def strategy_focal_composition(room: Room, artifacts: list[Artifact],
                                rng: random.Random,
                                trace: Optional[list] = None) -> list[Placement]:
    """Compose the room around a chosen centerpiece. The other artifacts
    arc around it in 1-2 clusters. Negative space is preserved."""
    if not artifacts:
        return []

    def importance(a: Artifact) -> float:
        s = float(a.footprint_cells) * 1.5
        if a.preferred_zone == "center": s += 4.0
        if a.isolation > 0: s += 2.0
        if a.wall_backing: s -= 2.0          # wall-things aren't centerpieces
        s += len(a.cluster_with) * 0.5       # anchors of clusters can also star
        return s

    sorted_arts = sorted(artifacts, key=importance, reverse=True)
    centerpiece = sorted_arts[0]
    rest = sorted_arts[1:]

    spawn = (room.spawn_row, room.spawn_col)
    tele = (room.teleporter_row, room.teleporter_col)

    # Weenie position: ~⅔ along spawn→tele, offset perpendicular so spawn↔tele
    # sightline isn't blocked. Slightly biased toward the back (away from spawn).
    walk_dr = tele[0] - spawn[0]
    walk_dc = tele[1] - spawn[1]
    weenie_t = 0.62
    cp_w, cp_d = centerpiece.footprint_dim()
    base_r = spawn[0] + walk_dr * weenie_t
    base_c = spawn[1] + walk_dc * weenie_t
    # Perpendicular offset (1-2 cells off the spawn-tele line)
    perp_dr = -walk_dc / max(1, math.hypot(walk_dr, walk_dc))   # rotate 90°
    perp_dc = walk_dr / max(1, math.hypot(walk_dr, walk_dc))
    offset_sign = 1 if rng.random() > 0.5 else -1
    offset_mag = 2.0
    cp_r = int(round(base_r + perp_dr * offset_mag * offset_sign - cp_d / 2))
    cp_c = int(round(base_c + perp_dc * offset_mag * offset_sign - cp_w / 2))
    # Clamp inside room
    cp_r = max(0, min(room.depth - cp_d, cp_r))
    cp_c = max(0, min(room.width - cp_w, cp_c))

    placements: list[Placement] = [Placement(centerpiece, cp_r, cp_c)]
    if trace is not None:
        trace.append(("place_centerpiece", (cp_r, cp_c), centerpiece.lookup_name, 0.0))

    # Compute centerpiece centre for arc calculations
    cp_cx = cp_c + cp_w / 2
    cp_cy = cp_r + cp_d / 2

    # Group remaining artifacts by FUNCTION (wall_backing / cluster member / display)
    wall_members  = [a for a in rest if a.wall_backing]
    cluster_with_cp = [a for a in rest if centerpiece.lookup_name in a.cluster_with
                       or any(p.artifact.lookup_name in a.cluster_with for p in placements)]
    other_displays = [a for a in rest if a not in wall_members and a not in cluster_with_cp]

    occupied: set[tuple[int, int]] = set()
    for p in placements:
        for cell in p.footprint_cells_occupied():
            occupied.add(cell)

    def try_place_at(a: Artifact, target_r: float, target_c: float) -> bool:
        w, d = a.footprint_dim()
        # Spiral outward from target
        for radius in range(0, max(room.depth, room.width)):
            for dr in range(-radius, radius + 1):
                for dc in range(-radius, radius + 1):
                    if radius > 0 and max(abs(dr), abs(dc)) != radius:
                        continue
                    r = int(round(target_r + dr - d / 2))
                    c = int(round(target_c + dc - w / 2))
                    if r < 0 or r > room.depth - d: continue
                    if c < 0 or c > room.width - w: continue
                    cells = {(r + di, c + dj) for di in range(d) for dj in range(w)}
                    if cells & occupied: continue
                    if (room.spawn_row, room.spawn_col) in cells: continue
                    if (room.teleporter_row, room.teleporter_col) in cells: continue
                    # Wall-backing must touch a wall
                    if a.wall_backing:
                        on_wall = any(cr == 0 or cr == room.depth - 1 or cc == 0 or cc == room.width - 1
                                      for (cr, cc) in cells)
                        if not on_wall: continue
                    placements.append(Placement(a, r, c))
                    occupied.update(cells)
                    return True
        return False

    # 1. Wall_backing artifacts go to walls FACING the centerpiece (back/front
    #    depending on which side centerpiece sits). Place at evenly spaced
    #    points along that wall.
    # Choose the wall opposite the centerpiece's perpendicular offset
    # (so they "look at" the centerpiece across the room).
    for i, a in enumerate(wall_members):
        w_a, d_a = a.footprint_dim()
        # Distribute along the back wall (row 0) or front wall depending on zone
        if a.preferred_zone == "entry":
            target_r = room.depth - d_a
        elif a.preferred_zone == "back":
            target_r = 0
        else:
            target_r = 0
        offset = (i + 1) / (len(wall_members) + 1)
        target_c = offset * room.width
        if not try_place_at(a, target_r, target_c):
            try_place_at(a, 0, target_c)
        if trace is not None and placements:
            last = placements[-1]
            trace.append(("place_wall", (last.row, last.col), a.lookup_name, 0.0))

    # 2. Cluster-with-centerpiece artifacts arc directly around the centerpiece
    #    at radius = max(cp_w, cp_d)/2 + 2.5
    arc_r = max(cp_w, cp_d) / 2 + 2.5
    for i, a in enumerate(cluster_with_cp):
        # Place evenly around the centerpiece — angles span ~270° (the side
        # facing the spawn stays open for the player's approach path)
        angle_span = math.pi * 1.5
        angle_start = math.pi / 2   # bottom (toward spawn) stays clear
        angle = angle_start + angle_span * ((i + 1) / (len(cluster_with_cp) + 1))
        tr = cp_cy + arc_r * math.sin(angle)
        tc = cp_cx + arc_r * math.cos(angle)
        if try_place_at(a, tr, tc):
            if trace is not None:
                last = placements[-1]
                trace.append(("place_cluster", (last.row, last.col), a.lookup_name, 0.0))

    # 3. Other displays — place in the "wings" (left/right thirds), with
    #    breathing room. Avoid the spawn↔centerpiece corridor.
    n_others = len(other_displays)
    for i, a in enumerate(other_displays):
        # Alternate wings
        wing_sign = 1 if i % 2 == 0 else -1
        # Distribute vertically along the walk
        t_fraction = 0.25 + 0.6 * (i // 2) / max(1, (n_others + 1) // 2)
        tr = spawn[0] + walk_dr * t_fraction
        tc = spawn[1] + walk_dc * t_fraction + wing_sign * (room.width * 0.3)
        if try_place_at(a, tr, tc):
            if trace is not None:
                last = placements[-1]
                trace.append(("place_wing", (last.row, last.col), a.lookup_name, 0.0))

    # Final pass — anything that didn't fit: god-mode fallback (best open cell)
    for a in artifacts:
        if any(p.artifact.lookup_name == a.lookup_name for p in placements): continue
        w, d = a.footprint_dim()
        best = None
        best_dist_to_centerpiece = 1e9
        for r in range(room.depth - d + 1):
            for c in range(room.width - w + 1):
                cells = {(r + di, c + dj) for di in range(d) for dj in range(w)}
                if cells & occupied: continue
                if (room.spawn_row, room.spawn_col) in cells: continue
                if (room.teleporter_row, room.teleporter_col) in cells: continue
                if a.wall_backing:
                    on_wall = any(cr == 0 or cr == room.depth - 1 or cc == 0 or cc == room.width - 1
                                  for (cr, cc) in cells)
                    if not on_wall: continue
                cy = r + d / 2; cx = c + w / 2
                d_cp = math.hypot(cy - cp_cy, cx - cp_cx)
                if d_cp < best_dist_to_centerpiece:
                    best_dist_to_centerpiece = d_cp
                    best = (r, c)
        if best is not None:
            placements.append(Placement(a, best[0], best[1]))
            for cell in placements[-1].footprint_cells_occupied():
                occupied.add(cell)
            if trace is not None:
                trace.append(("place_fallback", best, a.lookup_name, 0.0))

    return placements


# ─────────────────────────────────────────────────────────────────────
# Strategy 14 — PACING ARC (Mario-style 4-beat)
# Sort artifacts by "intensity" (footprint × isolation), distribute
# along spawn→teleporter walk in: intro → develop → twist → conclude.
# ─────────────────────────────────────────────────────────────────────

def strategy_pacing_arc(room: Room, artifacts: list[Artifact],
                          rng: random.Random,
                          trace: Optional[list] = None) -> list[Placement]:
    """Place along the walk with intensity rising to a peak (twist) and
    resolving before the exit. Each artifact's t-along-walk is determined
    by its rank in the pacing arc."""
    if not artifacts:
        return []

    def intensity(a: Artifact) -> float:
        return float(a.footprint_cells) + a.isolation * 2.0 + (
            1.0 if a.preferred_zone == "center" else 0.0
        )

    sorted_arts = sorted(artifacts, key=intensity, reverse=True)
    n = len(sorted_arts)

    spawn = (room.spawn_row, room.spawn_col)
    tele = (room.teleporter_row, room.teleporter_col)

    # 4-beat pacing curve: t along the walk = (introduce, develop, twist, conclude).
    # Map artifact rank to a t in [0.1, 0.9] following the curve:
    #   t=0.20 (intro, low),     t=0.40 (develop, medium-low),
    #   t=0.65 (twist, peak),    t=0.85 (conclude, resolution)
    # For >4 artifacts, expand the curve with intermediate points.
    def beat_t(rank: int, n: int) -> float:
        if n == 1: return 0.65
        if n == 2: return [0.4, 0.65][rank]
        if n == 3: return [0.3, 0.65, 0.85][rank]
        if n == 4: return [0.2, 0.4, 0.65, 0.85][rank]
        # >4: interpolate around the 4-beat curve
        # Highest-intensity items cluster near the twist (0.65)
        # Lower-intensity items fan out
        beats = [0.2, 0.4, 0.65, 0.85]
        if rank < 4:
            return beats[rank]
        # Extra items: alternate left/right of twist
        extras = rank - 4
        side = -1 if extras % 2 == 0 else 1
        dist = (extras // 2 + 1) * 0.08
        return max(0.1, min(0.95, 0.65 + side * dist))

    # Alternate sides of the walk for visual rhythm
    walk_dr = tele[0] - spawn[0]
    walk_dc = tele[1] - spawn[1]
    walk_len = max(1, math.hypot(walk_dr, walk_dc))
    perp_dr = -walk_dc / walk_len
    perp_dc = walk_dr / walk_len

    placements: list[Placement] = []
    occupied: set[tuple[int, int]] = set()

    def try_place_at(a: Artifact, target_r: float, target_c: float) -> bool:
        w, d = a.footprint_dim()
        for radius in range(0, max(room.depth, room.width)):
            for dr in range(-radius, radius + 1):
                for dc in range(-radius, radius + 1):
                    if radius > 0 and max(abs(dr), abs(dc)) != radius:
                        continue
                    r = int(round(target_r + dr - d / 2))
                    c = int(round(target_c + dc - w / 2))
                    if r < 0 or r > room.depth - d: continue
                    if c < 0 or c > room.width - w: continue
                    cells = {(r + di, c + dj) for di in range(d) for dj in range(w)}
                    if cells & occupied: continue
                    if (room.spawn_row, room.spawn_col) in cells: continue
                    if (room.teleporter_row, room.teleporter_col) in cells: continue
                    if a.wall_backing:
                        on_wall = any(cr == 0 or cr == room.depth - 1 or cc == 0 or cc == room.width - 1
                                      for (cr, cc) in cells)
                        if not on_wall: continue
                    placements.append(Placement(a, r, c))
                    occupied.update(cells)
                    return True
        return False

    for rank, a in enumerate(sorted_arts):
        t = beat_t(rank, n)
        # Side alternation (left/right of the walk axis)
        # Twist (highest intensity, rank 0) goes ON the line; others alternate
        side = 0 if rank == 0 else (1 if rank % 2 == 1 else -1)
        side_offset = side * (2 if abs(walk_dc) < abs(walk_dr) else 1.5)
        tr = spawn[0] + walk_dr * t + perp_dr * side_offset
        tc = spawn[1] + walk_dc * t + perp_dc * side_offset
        ok = try_place_at(a, tr, tc)
        if trace is not None and ok:
            last = placements[-1]
            beat_name = (
                "intro" if t < 0.3 else
                "develop" if t < 0.55 else
                "twist" if t < 0.75 else "conclude"
            )
            trace.append((f"place_{beat_name}", (last.row, last.col), a.lookup_name, t))

    return placements


# ─────────────────────────────────────────────────────────────────────
# Strategy 15 — ALEXANDER (Christopher Alexander's pattern language)
# Selects between patterns by artifact count + map geometry:
#   - n ≤ 3:           Pattern #179 "Alcoves" (small bays off main path)
#   - 4 ≤ n ≤ 6:       Pattern #185 "Sitting circle" (ring facing inward)
#   - 7 ≤ n:           Pattern #131 "Flow through rooms" (linear sequence)
#                       + Pattern #129 "Common areas at heart" (central pause)
# ─────────────────────────────────────────────────────────────────────

def strategy_alexander(room: Room, artifacts: list[Artifact],
                        rng: random.Random,
                        trace: Optional[list] = None) -> list[Placement]:
    """Apply specific Alexander patterns based on artifact count."""
    if not artifacts:
        return []
    n = len(artifacts)

    placements: list[Placement] = []
    occupied: set[tuple[int, int]] = set()

    def try_place_at(a: Artifact, target_r: float, target_c: float) -> bool:
        w, d = a.footprint_dim()
        for radius in range(0, max(room.depth, room.width)):
            for dr in range(-radius, radius + 1):
                for dc in range(-radius, radius + 1):
                    if radius > 0 and max(abs(dr), abs(dc)) != radius:
                        continue
                    r = int(round(target_r + dr - d / 2))
                    c = int(round(target_c + dc - w / 2))
                    if r < 0 or r > room.depth - d: continue
                    if c < 0 or c > room.width - w: continue
                    cells = {(r + di, c + dj) for di in range(d) for dj in range(w)}
                    if cells & occupied: continue
                    if (room.spawn_row, room.spawn_col) in cells: continue
                    if (room.teleporter_row, room.teleporter_col) in cells: continue
                    if a.wall_backing:
                        on_wall = any(cr == 0 or cr == room.depth - 1 or cc == 0 or cc == room.width - 1
                                      for (cr, cc) in cells)
                        if not on_wall: continue
                    placements.append(Placement(a, r, c))
                    occupied.update(cells)
                    return True
        return False

    spawn = (room.spawn_row, room.spawn_col)
    tele = (room.teleporter_row, room.teleporter_col)
    cx = room.width / 2
    cy = room.depth / 2

    # Choose pattern
    if n <= 3:
        # PATTERN #179 — ALCOVES — small bays at the wall, off the main path
        pattern = "alcoves"
        # Alcoves go along the side walls (left or right)
        wall_side = "left"
        # Place artifacts along the chosen wall at evenly spaced rows
        positions = []
        for i in range(n):
            t = (i + 1) / (n + 1)
            r_target = room.depth * (0.2 + 0.6 * t)
            c_target = 1 if wall_side == "left" else room.width - 2
            positions.append((r_target, c_target))
    elif n <= 6:
        # PATTERN #185 — SITTING CIRCLE — ring of artifacts facing inward
        pattern = "sitting_circle"
        # Ring radius based on room scale
        radius = min(room.width, room.depth) * 0.3
        positions = []
        # Skip the angle that points to spawn (player approaches through that gap)
        spawn_angle = math.atan2(spawn[0] - cy, spawn[1] - cx)
        for i in range(n):
            angle = spawn_angle + math.pi + (i - (n - 1) / 2) * (math.pi * 1.5 / max(1, n - 1))
            tr = cy + radius * math.sin(angle)
            tc = cx + radius * math.cos(angle)
            positions.append((tr, tc))
    else:
        # PATTERN #131 (FLOW) + #129 (COMMON AREA AT HEART)
        # — most important artifact in the centre as the "heart"
        # — rest distributed along the spawn→tele path as sequence
        pattern = "flow_with_heart"
        # Pick centerpiece: largest footprint
        sorted_arts_temp = sorted(range(n), key=lambda i: -artifacts[i].footprint_cells)
        heart_idx = sorted_arts_temp[0]
        # The heart goes at room centre
        positions = [(0, 0)] * n  # placeholder
        positions[heart_idx] = (cy, cx)
        # Others distributed along walk path
        path_indices = [i for i in range(n) if i != heart_idx]
        for j, i in enumerate(path_indices):
            t = (j + 1) / (len(path_indices) + 1)
            tr = spawn[0] + (tele[0] - spawn[0]) * t
            tc = spawn[1] + (tele[1] - spawn[1]) * t
            # Offset to the side (alternate)
            side = -1 if j % 2 == 0 else 1
            walk_dr = tele[0] - spawn[0]
            walk_dc = tele[1] - spawn[1]
            walk_len = max(1, math.hypot(walk_dr, walk_dc))
            perp_dr = -walk_dc / walk_len
            perp_dc = walk_dr / walk_len
            tr += perp_dr * side * 2
            tc += perp_dc * side * 2
            positions[i] = (tr, tc)

    if trace is not None:
        trace.append(("pattern", (0, 0), pattern, n))

    # Place artifacts in original order at their assigned positions
    for i, a in enumerate(artifacts):
        tr, tc = positions[i]
        ok = try_place_at(a, tr, tc)
        if trace is not None and ok:
            last = placements[-1]
            trace.append((f"place_{pattern}", (last.row, last.col), a.lookup_name, 0.0))

    return placements


# ─────────────────────────────────────────────────────────────────────
# Strategy 16 — PROMENADE (CSS-column-flow / scroll layout)
# Based on observed authorial patterns in primitives / transformation /
# wavefunctions / randomness sequences: corridor-shaped rooms with
# artifacts flowing top-to-bottom in two or three columns, with a
# central spine where the centerpiece + cluster members live, and
# wall_backing artifacts alternating left/right.
#
# Distinctive features:
#   - Treat the map as a flex/grid column layout (3 cols if width >= 9,
#     else 2 cols)
#   - Row flow: spawn end → teleporter end
#   - Centerpiece always on the central spine
#   - Wall_backing artifacts alternate left/right columns
#   - A "breathing room" of ~30-40% empty rows in the middle of the walk
#   - Bilateral symmetry encouraged via left/right pairing
# ─────────────────────────────────────────────────────────────────────

def strategy_promenade(room: Room, artifacts: list[Artifact],
                        rng: random.Random,
                        trace: Optional[list] = None) -> list[Placement]:
    """Scroll-style placement: artifacts flow top→bottom in columns.

    Columns are derived from the room width:
      - width >= 9: 3 columns (left wall, centre spine, right wall)
      - width <  9: 2 columns (left, right; spine = middle implicit)
    """
    if not artifacts:
        return []

    # Determine walking direction (spawn → teleporter, in row units)
    spawn_r = room.spawn_row
    tele_r = room.teleporter_row
    forward = 1 if tele_r > spawn_r else -1
    start_r = spawn_r + forward       # first row past spawn
    end_r = tele_r - forward          # last row before teleporter
    if forward * (end_r - start_r) < 0:
        # Spawn and teleporter adjacent or same row — just bail to a 2-col fill
        start_r = 0
        end_r = room.depth - 1
        forward = 1

    n_walk_rows = abs(end_r - start_r) + 1
    if n_walk_rows < 4:
        # Too short for a promenade; fall back to focal composition
        return strategy_focal_composition(room, artifacts, rng, trace)

    # Column layout
    three_col = room.width >= 9
    spine_col = room.width // 2
    if three_col:
        left_col = max(1, spine_col - 3)
        right_col = min(room.width - 2, spine_col + 3)
    else:
        left_col = max(0, spine_col - 1)
        right_col = min(room.width - 1, spine_col + 1)

    # Categorize artifacts into columns by role
    def importance(a: Artifact) -> float:
        s = float(a.footprint_cells) * 1.5
        if a.preferred_zone == "center": s += 4.0
        if a.isolation > 0: s += 2.0
        if a.wall_backing: s -= 3.0
        return s

    sorted_arts = sorted(artifacts, key=importance, reverse=True)

    centerpiece = sorted_arts[0] if sorted_arts else None
    wall_arts = [a for a in sorted_arts[1:] if a.wall_backing]
    cluster_arts = [a for a in sorted_arts[1:]
                    if (centerpiece and centerpiece.lookup_name in a.cluster_with)
                    or any(a.lookup_name in c.cluster_with for c in sorted_arts)]
    cluster_arts = [a for a in cluster_arts if not a.wall_backing]
    other_center = [a for a in sorted_arts[1:]
                    if a not in wall_arts and a not in cluster_arts]

    placements: list[Placement] = []
    occupied: set[tuple[int, int]] = set()

    def place_at(a: Artifact, r: int, c: int) -> bool:
        w, d = a.footprint_dim()
        # Snap to a valid origin for the chosen anchor cell
        rr = max(0, min(room.depth - d, r - d // 2))
        cc = max(0, min(room.width - w, c - w // 2))
        cells = {(rr + di, cc + dj) for di in range(d) for dj in range(w)}
        if cells & occupied: return False
        if (room.spawn_row, room.spawn_col) in cells: return False
        if (room.teleporter_row, room.teleporter_col) in cells: return False
        placements.append(Placement(a, rr, cc))
        occupied.update(cells)
        return True

    def place_with_search(a: Artifact, r: int, c: int) -> bool:
        """Try anchor (r,c), then small perturbations along the walk axis."""
        if place_at(a, r, c): return True
        for off in (1, -1, 2, -2, 3, -3):
            if place_at(a, r + forward * off, c): return True
        return False

    # Layout plan — assign each artifact a row along the walk axis.
    # The centerpiece goes at the BEAT POSITION: ~0.6 along the walk.
    # Cluster members go at +/- 1-2 rows around it.
    # Wall artifacts spread along the walk, alternating sides.
    # Other_center fills remaining beats with breathing room between sections.

    def walk_row(t: float) -> int:
        return int(round(start_r + forward * (n_walk_rows - 1) * t))

    if trace is not None:
        trace.append(("layout", (0, 0),
                      f"{'3col' if three_col else '2col'} promenade · "
                      f"{n_walk_rows} rows · centerpiece={centerpiece.lookup_name if centerpiece else 'none'}",
                      n_walk_rows))

    # 1. Centerpiece on the spine at t ≈ 0.6
    if centerpiece:
        cr = walk_row(0.6)
        place_with_search(centerpiece, cr, spine_col)
        if trace is not None and placements:
            p = placements[-1]
            trace.append(("centerpiece", (p.row, p.col), centerpiece.lookup_name, 0.6))

    # 2. Cluster members on the spine, paired around centerpiece
    for i, a in enumerate(cluster_arts):
        offset = (i // 2 + 1)  # 1, 1, 2, 2, 3, 3, ...
        sign = -1 if i % 2 == 0 else 1
        cr = walk_row(0.6) + forward * sign * offset
        place_with_search(a, cr, spine_col)
        if trace is not None and placements:
            p = placements[-1]
            trace.append(("cluster", (p.row, p.col), a.lookup_name, 0.0))

    # 3. Wall artifacts — distribute along walk, alternating left/right
    for i, a in enumerate(wall_arts):
        # Evenly space along walk, skipping the very middle (breathing room)
        t = 0.15 + (0.75 - 0.15) * (i / max(1, len(wall_arts) - 1)) if len(wall_arts) > 1 else 0.25
        # Skip the centerpiece zone (0.5-0.7)
        if 0.5 <= t <= 0.7:
            t = 0.85 if t > 0.6 else 0.35
        side = -1 if i % 2 == 0 else 1
        col = left_col if side < 0 else right_col
        cr = walk_row(t)
        place_with_search(a, cr, col)
        if trace is not None and placements:
            p = placements[-1]
            trace.append(("wall", (p.row, p.col), a.lookup_name, t))

    # 4. Other artifacts — fill remaining beats, prefer spine, alternating cols
    available_ts = [0.2, 0.3, 0.4, 0.8, 0.9, 0.1, 0.5, 0.7]
    for i, a in enumerate(other_center):
        if i < len(available_ts):
            t = available_ts[i]
        else:
            t = (i + 1) / (len(other_center) + 1)
        col_choice = spine_col if i % 2 == 0 else (left_col if i % 4 == 1 else right_col)
        cr = walk_row(t)
        if not place_with_search(a, cr, col_choice):
            # Try the other columns
            for c in (spine_col, left_col, right_col):
                if c == col_choice: continue
                if place_with_search(a, cr, c): break
        if trace is not None and placements:
            p = placements[-1]
            trace.append(("fill", (p.row, p.col), a.lookup_name, t))

    return placements


# ─────────────────────────────────────────────────────────────────────
# Strategy 17 — TILE WFC (Wang tiles + Wave Function Collapse + Alexander)
# A small palette of 3×3 tile templates with declared edge codes
# (N/E/S/W). The map becomes a corridor of tiles; adjacency rules
# (palette._meta.compat) constrain which tile can sit next to which.
# Each tile carries a structure fragment + utility fragment + interactable
# slots; concrete artifacts from the input pool get assigned to slots
# at materialization.
#
# Differs fundamentally from the prior 16: the unit of placement is a
# pre-composed 3×3 COMPOSITION, not an individual artifact. The author's
# job moves up — design tiles + rules, not per-cell positions.
# ─────────────────────────────────────────────────────────────────────

_TILE_PALETTE_CACHE: Optional[dict] = None


def _load_tile_palette() -> dict:
    """Load the tile palette from commons/maps/tile_palette/palette.json."""
    global _TILE_PALETTE_CACHE
    if _TILE_PALETTE_CACHE is not None:
        return _TILE_PALETTE_CACHE
    p = ROOT / "commons" / "maps" / "tile_palette" / "palette.json"
    if not p.exists():
        return {"tiles": [], "_meta": {"compat": {}, "tile_size": 3}}
    with open(p, "r", encoding="utf-8") as f:
        _TILE_PALETTE_CACHE = json.load(f)
    return _TILE_PALETTE_CACHE


def _edges_compatible(palette: dict, edge_a: str, edge_b: str) -> bool:
    """Two edge codes are adjacency-compatible if either appears in the
    other's compat list (symmetric)."""
    compat = palette.get("_meta", {}).get("compat", {})
    a_can = compat.get(edge_a, [])
    b_can = compat.get(edge_b, [])
    return (edge_b in a_can) or (edge_a in b_can) or (edge_a == edge_b)


def _slot_type_to_artifacts(artifacts: list[Artifact]) -> dict[str, list[Artifact]]:
    """Group input artifacts by which slot types they can fill."""
    by_type: dict[str, list[Artifact]] = {
        "centerpiece": [], "wall_backing": [], "cluster_anchor": [],
        "cluster_member": [], "small": [],
    }
    for a in artifacts:
        if a.wall_backing:
            by_type["wall_backing"].append(a)
            continue
        if a.footprint_cells >= 6 or a.preferred_zone == "center" or a.isolation > 0:
            by_type["centerpiece"].append(a)
            continue
        if a.cluster_with:
            by_type["cluster_anchor"].append(a)
            continue
        # Otherwise small
        by_type["small"].append(a)
    # Anything not yet placeable as cluster_member also fits "small"
    by_type["cluster_member"] = by_type["small"][:]
    return by_type


def strategy_tile_wfc(room: Room, artifacts: list[Artifact],
                       rng: random.Random,
                       trace: Optional[list] = None) -> list[Placement]:
    """Tile-based placement via Wang tiles + WFC.

    Generates a 1-column corridor of 3×3 tiles along the walk axis. Each
    tile slot gets assigned a concrete artifact from the input pool.
    """
    palette = _load_tile_palette()
    tiles_by_id = {t["id"]: t for t in palette.get("tiles", [])}
    tile_size = palette.get("_meta", {}).get("tile_size", 3)
    if not tiles_by_id:
        # No palette → fall through to hybrid
        return strategy_hybrid(room, artifacts, rng)

    # Determine corridor orientation + length
    spawn = (room.spawn_row, room.spawn_col)
    tele = (room.teleporter_row, room.teleporter_col)
    walk_dr = tele[0] - spawn[0]
    walk_dc = tele[1] - spawn[1]
    vertical = abs(walk_dr) >= abs(walk_dc)
    walk_len = abs(walk_dr) if vertical else abs(walk_dc)
    perp_len = room.width if vertical else room.depth
    if walk_len < tile_size or perp_len < tile_size:
        return strategy_hybrid(room, artifacts, rng)

    n_tiles = max(2, (walk_len + 1) // tile_size)
    tile_grid: list[Optional[dict]] = [None] * n_tiles

    # First tile = entry (must contain spawn). Find best candidate.
    # In our palette: T01_spawn_intro
    entry_candidates = [t for t in tiles_by_id.values() if t.get("role") == "entry"]
    exit_candidates = [t for t in tiles_by_id.values() if t.get("role") == "exit"]
    if not entry_candidates or not exit_candidates:
        return strategy_hybrid(room, artifacts, rng)

    # Decide tile-grid orientation: spawn at low or high index?
    # Convention: tile_grid[0] is the SPAWN end (where the player enters).
    # The "outgoing" edge from each tile is the one facing the next tile.
    # For vertical corridors with spawn at high-row (back), the player walks
    # toward low-row (front). So tile_grid[0] is at high-row; outgoing = "N".
    # We use simple labels: "out" = edge facing the next tile in the grid,
    # "in" = edge facing the previous tile. For our palette, all tiles have
    # N/S as the path-axis edges, so out = N (going to next tile) and in = S
    # (facing previous tile).

    def tile_out_edge(t: dict) -> str: return t["edges"]["N"]
    def tile_in_edge(t: dict) -> str: return t["edges"]["S"]

    tile_grid[0] = entry_candidates[0]
    tile_grid[-1] = exit_candidates[0]
    if trace is not None:
        trace.append(("tile_entry", (0, 0), tile_grid[0]["id"], 0))
        trace.append(("tile_exit", (n_tiles - 1, 0), tile_grid[-1]["id"], 0))

    # Slot-budget bookkeeping: track how many of each slot type we still need
    # to place (== count of input artifacts of each type)
    by_type = _slot_type_to_artifacts(artifacts)
    needs = {k: len(v) for k, v in by_type.items()}
    # Also count cluster_anchor placements
    needs["cluster_anchor"] = len(by_type["cluster_anchor"])

    def tile_slot_demand(t: dict) -> dict[str, int]:
        out: dict[str, int] = {}
        for s in t.get("slots", []):
            out[s["type"]] = out.get(s["type"], 0) + 1
        return out

    # WFC the middle tiles. For each position i in [1, n_tiles - 2]:
    #   compute the compatible candidates given:
    #     - prev tile's N edge must compat with this tile's S edge
    #     - this tile's N edge must compat with the FIXED exit tile's S edge
    #       if i == n_tiles - 2, OR loosely if the next tile isn't placed yet
    # Pick the best candidate by:
    #   - matches an unplaced slot demand (artifacts still need a home)
    #   - role variation (don't put two centerpieces back-to-back)
    #   - random tiebreaker
    prev_tile = tile_grid[0]
    for i in range(1, n_tiles - 1):
        candidates = []
        for t in tiles_by_id.values():
            if t.get("role") in ("entry", "exit"): continue
            # Edge in: prev's OUT must be compat with this tile's IN
            if not _edges_compatible(palette, tile_out_edge(prev_tile), tile_in_edge(t)):
                continue
            # If this is the second-to-last position, also check forward compat
            if i == n_tiles - 2:
                if not _edges_compatible(palette, tile_out_edge(t),
                                          tile_in_edge(tile_grid[-1])):
                    continue
            candidates.append(t)
        if not candidates:
            # Fallback: breathing room or any "open"-edged tile
            candidates = [t for t in tiles_by_id.values()
                          if t.get("role") == "breathing"]
            if not candidates:
                candidates = list(tiles_by_id.values())

        def score(t: dict) -> float:
            s = 0.0
            demand = tile_slot_demand(t)
            for k, n in demand.items():
                if needs.get(k, 0) > 0:
                    s += min(n, needs[k]) * 3.0     # rewards filling unplaced needs
                else:
                    s -= n * 1.5                     # penalises empty slots
            # Variety: penalise if same role as prev
            if t.get("role") == prev_tile.get("role"):
                s -= 1.0
            # Centerpiece tile should appear roughly in the middle of the walk
            if t.get("role") == "centerpiece":
                target_i = max(1, n_tiles // 2)
                s += 2.0 - abs(i - target_i) * 0.5
            s += rng.random() * 0.3
            return s

        candidates.sort(key=score, reverse=True)
        chosen = candidates[0]
        tile_grid[i] = chosen
        # Consume slot demands
        for k, n in tile_slot_demand(chosen).items():
            needs[k] = max(0, needs.get(k, 0) - n)
        if trace is not None:
            trace.append((f"tile_{i}", (i, 0), chosen["id"], 0))
        prev_tile = chosen

    # ── Materialize: assign concrete artifacts to slots, emit Placements ──
    placements: list[Placement] = []
    occupied: set[tuple[int, int]] = set()
    by_type = _slot_type_to_artifacts(artifacts)
    pool = {k: list(v) for k, v in by_type.items()}

    # Compute the tile's origin in room coordinates.
    # We anchor tile_grid[0] at the spawn end and grow toward the teleporter.
    if vertical:
        # Walk along depth. tile_grid[0] is at spawn end.
        path_step = -1 if walk_dr < 0 else 1
        # Start row: the row just inside the spawn (so tile fully fits)
        if path_step < 0:
            start_row = spawn[0] - tile_size + 1
        else:
            start_row = spawn[0]
        # Perpendicular column: centered
        start_col = max(0, min(room.width - tile_size, room.width // 2 - tile_size // 2))
    else:
        path_step = -1 if walk_dc < 0 else 1
        start_col = spawn[1] if path_step > 0 else spawn[1] - tile_size + 1
        start_row = max(0, min(room.depth - tile_size, room.depth // 2 - tile_size // 2))

    for i, tile in enumerate(tile_grid):
        if tile is None: continue
        if vertical:
            tile_r0 = start_row + path_step * i * tile_size
            tile_c0 = start_col
        else:
            tile_r0 = start_row
            tile_c0 = start_col + path_step * i * tile_size

        # Fill artifacts for each slot
        for slot in tile.get("slots", []):
            slot_type = slot["type"]
            # Try cluster_anchor pool for cluster_anchor slots, etc.
            candidate_pool = pool.get(slot_type) or pool.get("small") or []
            # cluster_member can pull from small if empty
            if not candidate_pool and slot_type == "cluster_member":
                candidate_pool = pool.get("small") or []
            if not candidate_pool:
                # Try centerpiece pool as last resort for any large slot
                candidate_pool = pool.get("centerpiece") or []
            if not candidate_pool:
                continue
            a = candidate_pool.pop(0)
            # Position = tile origin + slot offset
            r = tile_r0 + slot["r"]
            c = tile_c0 + slot["c"]
            # Clamp + check
            w, d = a.footprint_dim()
            r = max(0, min(room.depth - d, r))
            c = max(0, min(room.width - w, c))
            cells = {(r + di, c + dj) for di in range(d) for dj in range(w)}
            if cells & occupied: continue
            if (room.spawn_row, room.spawn_col) in cells: continue
            if (room.teleporter_row, room.teleporter_col) in cells: continue
            placements.append(Placement(a, r, c))
            occupied.update(cells)

    # Fallback for any artifact not assigned to a tile slot: place at
    # any open cell in the interior, near the centerpiece tile
    remaining = []
    for kind, lst in pool.items():
        remaining.extend(lst)
    for a in remaining:
        if any(p.artifact.lookup_name == a.lookup_name for p in placements): continue
        w, d = a.footprint_dim()
        placed = False
        for r in range(room.depth - d + 1):
            for c in range(room.width - w + 1):
                cells = {(r + di, c + dj) for di in range(d) for dj in range(w)}
                if cells & occupied: continue
                if (room.spawn_row, room.spawn_col) in cells: continue
                if (room.teleporter_row, room.teleporter_col) in cells: continue
                placements.append(Placement(a, r, c))
                occupied.update(cells)
                placed = True
                break
            if placed: break

    return placements


STRATEGIES = {
    "random":              strategy_random,
    "rule_based":          strategy_rule_based,
    "sdf":                 strategy_sdf,
    "fold":                strategy_fold,
    "paradoxical":         strategy_paradoxical,
    "hybrid":              strategy_hybrid,
    "circle_packing":      strategy_circle_packing,
    "warehouse":           strategy_warehouse,
    "simulated_annealing": strategy_simulated_annealing,
    "voronoi":             strategy_voronoi,
    "humanoid_walker":     strategy_humanoid_walker,
    "grow_walker":         strategy_grow_walker,
    "focal_composition":   strategy_focal_composition,
    "pacing_arc":          strategy_pacing_arc,
    "alexander":           strategy_alexander,
    "promenade":           strategy_promenade,
    "tile_wfc":            strategy_tile_wfc,
}


# ─────────────────────────────────────────────────────────────────────
# Main loop
# ─────────────────────────────────────────────────────────────────────

def render_ascii(room: Room, placements: list[Placement]) -> list[str]:
    """ASCII grid for visual inspection of a placement."""
    grid = [['.' for _ in range(room.width)] for _ in range(room.depth)]
    grid[room.spawn_row][room.spawn_col] = 'S'
    grid[room.teleporter_row][room.teleporter_col] = 'T'
    for i, p in enumerate(placements):
        glyph = str(i + 1)
        for (r, c) in p.footprint_cells_occupied():
            if 0 <= r < room.depth and 0 <= c < room.width:
                grid[r][c] = glyph
    return [''.join(row) for row in grid]


def run(seeds: int = 200, write: bool = True) -> dict:
    room = Room()
    results: dict[str, list[dict]] = {name: [] for name in STRATEGIES}
    best_placements: dict[str, tuple[float, list[Placement]]] = {}

    for strategy_name, fn in STRATEGIES.items():
        for seed in range(seeds):
            rng = random.Random(seed)
            placements = fn(room, list(TEST_ARTIFACTS), rng)
            metrics = score_placement(room, placements)
            results[strategy_name].append({"seed": seed, **metrics})
            score = metrics["total"]
            cur = best_placements.get(strategy_name)
            if cur is None or score > cur[0]:
                best_placements[strategy_name] = (score, placements)

    # Aggregate
    summary = {}
    for name, runs in results.items():
        totals = [r["total"] for r in runs]
        avg_per_metric = {}
        for key in runs[0].keys():
            if key in ("seed", "total"): continue
            avg_per_metric[key] = round(sum(r[key] for r in runs) / len(runs), 3)
        summary[name] = {
            "n":         len(runs),
            "mean":      round(sum(totals) / len(totals), 4),
            "best":      round(max(totals), 4),
            "worst":     round(min(totals), 4),
            "std":       round((sum((t - sum(totals) / len(totals)) ** 2 for t in totals) / len(totals)) ** 0.5, 4),
            "per_metric": avg_per_metric,
        }

    out = {
        "seeds_per_strategy": seeds,
        "room":               asdict(room),
        "artifacts":          [asdict(a) for a in TEST_ARTIFACTS],
        "summary":            summary,
        "best_placements":    {
            name: {
                "score": best_placements[name][0],
                "placements": [
                    {
                        "artifact": p.artifact.lookup_name,
                        "row":      p.row,
                        "col":      p.col,
                    }
                    for p in best_placements[name][1]
                ],
                "ascii": render_ascii(room, best_placements[name][1]),
            }
            for name in STRATEGIES
        },
    }

    if write:
        out_path = OUT_DIR / "results.json"
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(out, f, indent=2)
        print(f"wrote {out_path}")

    return out


def print_summary(out: dict) -> None:
    print()
    print("=" * 78)
    print(f"PLACEMENT AUTO-RESEARCH — {out['seeds_per_strategy']} seeds × {len(STRATEGIES)} strategies")
    print("=" * 78)
    print()
    print(f"{'strategy':14} {'mean':>7} {'best':>7} {'worst':>7} {'std':>7}")
    print("-" * 78)
    ranked = sorted(out["summary"].items(), key=lambda kv: -kv[1]["mean"])
    for name, stats in ranked:
        print(f"{name:14} {stats['mean']:>7} {stats['best']:>7} {stats['worst']:>7} {stats['std']:>7}")
    print()
    print("PER-METRIC AVERAGES (rows = strategies, cols = metrics):")
    print("-" * 78)
    metrics = list(out["summary"][ranked[0][0]]["per_metric"].keys())
    short = {
        "footprint_in_bounds":    "ftpt",
        "no_overlap":             "noOv",
        "clearance_satisfied":    "clr",
        "wall_backing_satisfied": "wall",
        "isolation_satisfied":    "iso",
        "cluster_satisfied":      "clst",
        "preferred_zone_match":   "zone",
        "reachability":           "rch",
        "spawn_walkable":         "spwn",
        "teleporter_walkable":    "tele",
    }
    print(f"{'strategy':14} " + " ".join(f"{short[m]:>5}" for m in metrics))
    print("-" * 78)
    for name, stats in ranked:
        row = " ".join(f"{stats['per_metric'][m]:>5.2f}" for m in metrics)
        print(f"{name:14} {row}")
    print()
    print("BEST PLACEMENT PER STRATEGY (ASCII — S=spawn, T=tele, 1-4 = artifacts):")
    print("-" * 78)
    for name, stats in ranked:
        bp = out["best_placements"][name]
        print(f"\n  {name}  (score={bp['score']:.3f})")
        for line in bp["ascii"]:
            print(f"    {line}")
    print()
    print("ARTIFACT KEY:")
    for i, a in enumerate(out["artifacts"]):
        print(f"  {i+1} = {a['lookup_name']:30} ftpt={a['footprint_cells']} wall={a['wall_backing']} zone={a['preferred_zone']}")
    print()


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--seeds", type=int, default=200, help="iterations per strategy")
    p.add_argument("--report", action="store_true", help="reread existing results.json instead of regenerating")
    args = p.parse_args()

    if args.report:
        with open(OUT_DIR / "results.json", "r", encoding="utf-8") as f:
            out = json.load(f)
    else:
        out = run(seeds=args.seeds, write=True)
    print_summary(out)
