#!/usr/bin/env python3
"""The floorplan layer — architecture offers, artifacts ask.

One coherent architectural grammar (an enfilade of bays either side of a
through-route) with controlled parameters, rather than a random choice among
unrelated map grammars. `spine_auto_research.py` keeps the second job — that is
structural RESEARCH across many grammars — and the two stay separate on purpose.

The plan owns architecture and circulation only. It never mentions an artifact
by name and holds no artifact-specific exceptions. What it publishes is a set
of OFFERS: slots on the floor and rectangles on the walls, each with what it
can supply.

Cell roles are the vocabulary `commons/data/template_patterns.json` already
uses, so this is the same language the template editor speaks:

    ''   void        '1'  floor       '1s' floor slot
    '2'  platform    '2s' podium slot '3s' high podium slot     '4' wall

Usage:
    python tools/spatial_floorplan.py --bays=3
    python tools/spatial_floorplan.py --bays=3 --ascii
"""
from __future__ import annotations

import argparse
import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

VOID, FLOOR, WALL = "", "1", "4"
FLOOR_SLOT, PODIUM_SLOT, HIGH_PODIUM_SLOT = "1s", "2s", "3s"
SLOT_RANKS = {FLOOR_SLOT: "floor", PODIUM_SLOT: "podium", HIGH_PODIUM_SLOT: "high_podium"}


@dataclass
class Slot:
    """A candidate placement zone the architecture offers to any artifact."""
    id: str
    cell: tuple[int, int]                 # (x, z) anchor
    role: str                             # cell-role token
    bay: str
    bay_side: str                         # west | east — which pocket it is in
    z_range: tuple[int, int]              # the bay's z extent
    wall_side: str | None                 # which wall it backs onto, if any
    free_cells: set[tuple[int, int]]      # the bay pocket this slot may use
    support: str                          # floor | podium | wall
    surface_height_m: float
    #: What this slot can hold, precomputed by tools/slot_capacity.py:
    #: {"per_rotation": {"0": {"max_w","max_d","max_area","wall_backed"}, ...}}.
    #: Empty for slots this plan invented rather than read from a template.
    capacity: dict = field(default_factory=dict)
    #: interior | courtyard | porch | balcony | bridge | outside
    venue: str = "interior"
    #: EVERY wall this slot backs onto, not just the first. 115 of the corpus's
    #: 475 slots sit in a corner, and keeping only one of their walls threw away
    #: the rotation that would have fitted.
    wall_sides: list = field(default_factory=list)

    def as_dict(self) -> dict[str, Any]:
        return {
            "id": self.id, "cell": list(self.cell), "role": self.role,
            "bay": self.bay, "bay_side": self.bay_side,
            "wall_side": self.wall_side, "support": self.support,
            "surface_height_m": self.surface_height_m,
            "pocket_cells": len(self.free_cells),
        }


@dataclass
class WallSurface:
    """A wall as a 2D placement domain, not a slice of a voxel grid.

    (u, v): u runs along the wall from its start corner, v runs floor-to-ceiling.
    Both in metres, which on a 1 m grid is also cells.
    """
    id: str
    side: str                             # west | east | north | south
    bay: str
    bay_side: str                         # which pocket this wall serves
    length_m: float
    height_m: float
    origin_cell: tuple[int, int]          # world cell of u=0 at the floor
    normal: tuple[int, int]               # inward (dx, dz) — the way it faces
    openings: list[list[float]] = field(default_factory=list)   # [u0,v0,u1,v1]
    occupied: list[dict[str, Any]] = field(default_factory=list)
    reserved: list[dict[str, Any]] = field(default_factory=list)

    @property
    def feature_zone(self) -> list[float]:
        """The visual centre, reserved for the feature work: middle 50% of the
        run, between 0.9 m and 2.9 m — gallery hanging height."""
        return [self.length_m * 0.25, 0.9, self.length_m * 0.75, 2.9]

    def rect_free(self, rect: list[float]) -> tuple[bool, str]:
        """Is a (u0,v0,u1,v1) rectangle placeable? Returns (ok, reason)."""
        if rect[0] < 0 or rect[2] > self.length_m:
            return False, "runs past the end of the wall"
        if rect[1] < 0 or rect[3] > self.height_m:
            return False, "runs past the ceiling"
        for op in self.openings:
            if _overlap(rect, op):
                return False, "overlaps a door or opening"
        for item in self.occupied:
            if _overlap(rect, item["rect"]):
                return False, f"overlaps {item['token']}"
        return True, "clear"

    def world_of(self, u: float, v: float) -> tuple[float, float, float]:
        """(u, v) -> world (x, y, z) in metres, cell centres on the 1 m grid."""
        x, z = self.origin_cell
        if self.side in ("west", "east"):
            return (float(x) + 0.5, v, float(z) + u)
        return (float(x) + u, v, float(z) + 0.5)

    def as_dict(self) -> dict[str, Any]:
        return {
            "id": self.id, "side": self.side, "bay": self.bay,
            "length_m": self.length_m, "height_m": self.height_m,
            "origin_cell": list(self.origin_cell), "normal": list(self.normal),
            "openings": self.openings, "feature_zone_uv": self.feature_zone,
            "occupied": self.occupied, "reserved": self.reserved,
        }


def _overlap(a: list[float], b: list[float]) -> bool:
    return a[0] < b[2] and a[2] > b[0] and a[1] < b[3] and a[3] > b[1]


@dataclass
class FloorPlan:
    width: int
    depth: int
    grid: list[list[str]]
    route: set[tuple[int, int]]
    slots: list[Slot]
    walls: list[WallSurface]
    spawn: tuple[int, int]
    exit: tuple[int, int]
    wall_height_m: float = 4.0
    #: The exterior margin from_museum wrapped around the tile, in cells. 0 for
    #: scaffolds. Stored so a consumer can recover the TILE width
    #: (width - 2*apron) without importing the exporter's constant — the
    #: courtyard rung needs it to refuse a court the corridor cannot honour.
    apron: int = 0
    expansions: list[str] = field(default_factory=list)
    #: May the negotiator grow this building? True for a parametric scaffold.
    #: FALSE for one of the 30 authored museums — their proportions are the
    #: authorship, and widening the Uffizi to fit an artifact is not a
    #: placement decision, it is vandalism. A body that will not fit goes to a
    #: courtyard, a porch or the grounds instead.
    expandable: bool = True

    def in_bounds(self, x: int, z: int) -> bool:
        return 0 <= x < self.width and 0 <= z < self.depth

    def walkable(self, x: int, z: int) -> bool:
        return self.in_bounds(x, z) and self.grid[z][x] not in (VOID, WALL)

    def free_floor(self) -> set[tuple[int, int]]:
        return {(x, z) for z in range(self.depth) for x in range(self.width)
                if self.walkable(x, z)}

    def widen(self, extra: int = 2) -> None:
        """Late-fallback room expansion.

        Grows BOTH pockets by `extra` cells — inserting only on the east side
        would leave a west bay exactly as cramped as it was, which is the kind
        of expansion that looks like a fix and is not one. The route keeps its
        width and stays central; everything east of it shifts by `extra`.
        """
        for z in range(self.depth):
            row = self.grid[z]
            west_fill = FLOOR if row[1] not in (VOID, WALL) else row[1]
            east_fill = FLOOR if row[-2] not in (VOID, WALL) else row[-2]
            self.grid[z] = ([row[0]] + [west_fill] * extra + row[1:-1]
                            + [east_fill] * extra + [row[-1]])
        self.width += 2 * extra
        self.route = {(x + extra, z) for x, z in self.route}
        self.spawn = (self.spawn[0] + extra, self.spawn[1])
        self.exit = (self.exit[0] + extra, self.exit[1])
        for w in self.walls:
            if w.side == "east":
                w.origin_cell = (w.origin_cell[0] + 2 * extra, w.origin_cell[1])
            elif w.side in ("south", "north"):     # a bay end wall (fin)
                if w.bay_side == "east":
                    w.origin_cell = (w.origin_cell[0] + 2 * extra, w.origin_cell[1])
                w.length_m += extra
        for s in self.slots:
            # A west slot keeps its x (the west wall did not move); an east
            # slot rides the east wall outward by the full 2*extra.
            if s.bay_side == "east":
                s.cell = (s.cell[0] + 2 * extra, s.cell[1])
        self._recompute_pockets()
        self.expansions.append(
            f"widened both pockets by {extra} cells (total width {self.width})")

    def raise_ceiling(self, height_m: float) -> None:
        """The other axis a room can grow on. Every wall surface grows with it,
        so the wall diagnostic keeps describing the wall that gets built."""
        if height_m <= self.wall_height_m:
            return
        old = self.wall_height_m
        self.wall_height_m = height_m
        for w in self.walls:
            w.height_m = height_m
        self.expansions.append(
            f"raised the walls from {old:g} m to {height_m:g} m")

    def _recompute_pockets_from_grid(self) -> None:
        """For template-loaded plans: a slot's pocket is the walkable region it
        can reach without crossing a wall, capped so one slot does not claim the
        whole building."""
        from collections import deque
        for s in self.slots:
            if s.free_cells:
                continue
            seen = {s.cell}
            q = deque([(s.cell, 0)])
            while q:
                (x, z), dist = q.popleft()
                if dist >= 6:
                    continue
                for n in ((x + 1, z), (x - 1, z), (x, z + 1), (x, z - 1)):
                    if n in seen or not self.walkable(*n):
                        continue
                    seen.add(n)
                    q.append((n, dist + 1))
            s.free_cells = seen

    def _recompute_pockets(self) -> None:
        """Derive each slot's pocket from the grid, so pockets can never drift
        out of step with the architecture they describe."""
        route_xs = {x for x, _ in self.route}
        rx0, rx1 = (min(route_xs), max(route_xs)) if route_xs else (0, 0)
        for s in self.slots:
            z0, z1 = s.z_range
            if s.bay_side == "west":
                xs = range(1, rx0)
            else:
                xs = range(rx1 + 1, self.width - 1)
            s.free_cells = {(x, z) for x in xs for z in range(z0, z1)
                            if self.walkable(x, z)}

    def ascii(self) -> str:
        out = []
        for z in range(self.depth):
            row = []
            for x in range(self.width):
                c = self.grid[z][x]
                if (x, z) == self.spawn:      row.append("S")
                elif (x, z) == self.exit:     row.append("T")
                elif c == WALL:               row.append("#")
                elif c == VOID:               row.append(" ")
                elif c in SLOT_RANKS:         row.append(c[0])
                elif (x, z) in self.route:    row.append(":")
                else:                          row.append(".")
            out.append("".join(row))
        return "\n".join(out)


# ── The grammar ─────────────────────────────────────────────────────

def build_enfilade(bays: int = 3, width: int = 15, bay_depth: int = 7,
                   route_width: int = 3, wall_height_m: float = 4.0) -> FloorPlan:
    """An enfilade: bays alternating left and right of a central through-route.

    Parameters, not a random grammar choice. Every bay offers one high podium
    slot (its feature position), one podium slot and one floor slot, plus the
    wall run behind it.
    """
    depth = bays * bay_depth + 4
    grid = [[FLOOR for _ in range(width)] for _ in range(depth)]
    for z in range(depth):
        grid[z][0] = WALL
        grid[z][width - 1] = WALL
    for x in range(width):
        grid[0][x] = WALL
        grid[depth - 1][x] = WALL

    route_x0 = (width - route_width) // 2
    route = {(x, z) for z in range(1, depth - 1)
             for x in range(route_x0, route_x0 + route_width)}

    slots: list[Slot] = []
    walls: list[WallSurface] = []
    for i in range(bays):
        z0 = 2 + i * bay_depth
        z1 = z0 + bay_depth - 1
        side = "west" if i % 2 == 0 else "east"
        bay_id = f"bay{i}"
        if side == "west":
            pocket = {(x, z) for x in range(1, route_x0) for z in range(z0, z1)}
            wall_x, normal = 0, (1, 0)
            feature_cell = (1, z0 + (z1 - z0) // 2)
        else:
            pocket = {(x, z) for x in range(route_x0 + route_width, width - 1)
                      for z in range(z0, z1)}
            wall_x, normal = width - 1, (-1, 0)
            feature_cell = (width - 2, z0 + (z1 - z0) // 2)

        walls.append(WallSurface(
            id=f"{side}_{i:02d}", side=side, bay=bay_id, bay_side=side,
            length_m=float(z1 - z0), height_m=wall_height_m,
            origin_cell=(wall_x, z0), normal=normal,
        ))
        # The bay's end wall — the fin that makes an enfilade a sequence of
        # rooms rather than one corridor. It faces back down the bay (-z), so
        # it is the only surface an artifact locked to rotation 0 can use.
        fin_x0 = 1 if side == "west" else route_x0 + route_width
        fin_x1 = route_x0 if side == "west" else width - 1
        for x in range(fin_x0, fin_x1):
            grid[z1][x] = WALL
        walls.append(WallSurface(
            id=f"end_{i:02d}", side="south", bay=bay_id, bay_side=side,
            length_m=float(fin_x1 - fin_x0), height_m=wall_height_m,
            origin_cell=(fin_x0, z1), normal=(0, -1),
        ))

        # The bay's near end wall, facing +z. An alcove is closed at both ends,
        # and the two ends face opposite ways — which is what gives artifacts
        # locked to a single rotation somewhere to go. Under the declared
        # rotation_semantics a rotation-0 artifact backs onto THIS one.
        for x in range(fin_x0, fin_x1):
            grid[z0 - 1][x] = WALL
        walls.append(WallSurface(
            id=f"head_{i:02d}", side="north", bay=bay_id, bay_side=side,
            length_m=float(fin_x1 - fin_x0), height_m=wall_height_m,
            origin_cell=(fin_x0, z0 - 1), normal=(0, 1),
        ))

        # Feature position: against the bay's end wall, centred in the pocket.
        end_cell = ((fin_x0 + fin_x1) // 2, z1 - 1)
        slots.append(Slot(
            id=f"{bay_id}_feature", cell=end_cell, role=HIGH_PODIUM_SLOT,
            bay=bay_id, bay_side=side, z_range=(z0, z1), wall_side="south",
            free_cells=set(pocket), support="floor", surface_height_m=0.0))
        slots.append(Slot(
            id=f"{bay_id}_head", cell=((fin_x0 + fin_x1) // 2, z0), role=FLOOR_SLOT,
            bay=bay_id, bay_side=side, z_range=(z0, z1), wall_side="north",
            free_cells=set(pocket), support="floor", surface_height_m=0.0))
        # Island position: out in the pocket, off every wall.
        island_x = feature_cell[0] + (2 * normal[0])
        slots.append(Slot(
            id=f"{bay_id}_island", cell=(island_x, z0 + 2), role=PODIUM_SLOT,
            bay=bay_id, bay_side=side, z_range=(z0, z1), wall_side=None,
            free_cells=set(pocket), support="podium", surface_height_m=0.95))
        # A side-wall position on the long run.
        slots.append(Slot(
            id=f"{bay_id}_side", cell=feature_cell, role=FLOOR_SLOT,
            bay=bay_id, bay_side=side, z_range=(z0, z1), wall_side=side,
            free_cells=set(pocket), support="floor", surface_height_m=0.0))
        for s in slots[-3:]:
            x, z = s.cell
            if 0 < x < width - 1 and 0 < z < depth - 1:
                grid[z][x] = s.role

    spawn = (route_x0 + route_width // 2, 1)
    exit_cell = (route_x0 + route_width // 2, depth - 2)
    return FloorPlan(width=width, depth=depth, grid=grid, route=route,
                     slots=slots, walls=walls, spawn=spawn, exit=exit_cell,
                     wall_height_m=wall_height_m)


# ── The real corpus ─────────────────────────────────────────────────

REPO = Path(__file__).resolve().parent.parent
PATTERNS = REPO / "commons" / "data" / "template_patterns.json"
CAPACITY = REPO / "commons" / "data" / "slot_capacity.json"
#: THE wall height's one owner is em_detail.gd (WALL_H). The dataclass
#: default of 4.0 was a THIRD copy — never 3.0 when the building was 3.0, not
#: 4.5 when it became 4.5 — so the plan refused every body between the two
#: numbers for a wall the museum was actually tall enough to hold. Read the
#: owner, the way spatial_contract.plinth_band() reads em_plinths.gd.
DETAIL_GD = REPO / "commons" / "scenes" / "em" / "em_detail.gd"


def museum_wall_height_m() -> float:
    """em_detail.WALL_H, or 4.0 if the file is unreadable (the old default)."""
    try:
        import re as _re
        m = _re.search(r"^const WALL_H *:= *([0-9.]+)", DETAIL_GD.read_text(encoding="utf-8"), _re.M)
        if m:
            return float(m.group(1))
    except OSError:
        pass
    return 4.0

#: Where a body can go when the building itself cannot hold it. Ordered by how
#: much they still belong to the museum: a courtyard is inside the walls, a
#: porch is on the threshold, outside is the grounds.
EXTERIOR_VENUES = ("courtyard", "porch", "balcony", "bridge", "outside")


def _enclosed_voids(grid: list[list[str]], w: int, h: int) -> list[set[tuple[int, int]]]:
    """Void regions the outside world cannot reach — courtyards.

    The template vocabulary says '' is "legal only if walled off", so an
    enclosed void is not an absence, it is a room without a roof.
    """
    outside: set[tuple[int, int]] = set()
    stack = [(x, z) for x in range(w) for z in (0, h - 1) if grid[z][x] == VOID]
    stack += [(x, z) for z in range(h) for x in (0, w - 1) if grid[z][x] == VOID]
    while stack:
        x, z = stack.pop()
        if (x, z) in outside or not (0 <= x < w and 0 <= z < h):
            continue
        if grid[z][x] != VOID:
            continue
        outside.add((x, z))
        stack += [(x + 1, z), (x - 1, z), (x, z + 1), (x, z - 1)]

    seen: set[tuple[int, int]] = set()
    regions: list[set[tuple[int, int]]] = []
    for z in range(h):
        for x in range(w):
            if grid[z][x] != VOID or (x, z) in outside or (x, z) in seen:
                continue
            region: set[tuple[int, int]] = set()
            stack = [(x, z)]
            while stack:
                cx, cz = stack.pop()
                if (cx, cz) in region or not (0 <= cx < w and 0 <= cz < h):
                    continue
                if grid[cz][cx] != VOID:
                    continue
                region.add((cx, cz))
                stack += [(cx + 1, cz), (cx - 1, cz), (cx, cz + 1), (cx, cz - 1)]
            seen |= region
            if region:
                regions.append(region)
    return regions


def from_museum(key: str, apron: int = 14, rooms: int | None = None) -> FloorPlan:
    """Load one of the 30 authored museums as a plan, with its slots' declared
    capacity attached, plus the exterior venues that can host what the building
    cannot.

    This replaces build_enfilade for production work. The enfilade was a
    scaffold for proving the negotiator; the museums are the actual corpus, and
    their slots carry authored sightlines and pacing no solver reproduces.
    """
    patterns = json.loads(PATTERNS.read_text(encoding="utf-8"))["patterns"]
    if key not in patterns:
        raise KeyError(f"unknown museum template: {key}")
    tile = [list(map(str, row)) for row in patterns[key]["tile"]]
    if rooms:
        # ROOMS PER PEARL (tools/em_rooms.py): a pearl gets `rooms` of the tile,
        # not all of it — the same crop the plan row will carry to the runtime
        from em_rooms import crop_tile
        tile = crop_tile(tile, rooms)
    th, tw = len(tile), len(tile[0])

    caps: dict[str, dict] = {}
    if CAPACITY.exists():
        try:
            table = json.loads(CAPACITY.read_text(encoding="utf-8"))
            for s in table.get("museums", {}).get(key, {}).get("slots", []):
                caps[s["id"]] = s
        except Exception:
            pass

    # An apron of open ground around the building, so a body the museum cannot
    # hold still has somewhere real to stand rather than being dropped.
    off = apron
    w, h = tw + 2 * apron, th + 2 * apron
    grid = [[VOID for _ in range(w)] for _ in range(h)]
    for z in range(th):
        for x in range(tw):
            grid[z + off][x + off] = tile[z][x]
    for z in range(h):
        for x in range(w):
            if grid[z][x] == VOID and not (off <= x < off + tw and off <= z < off + th):
                grid[z][x] = FLOOR                     # the grounds

    courtyards = _enclosed_voids(grid, w, h)
    for region in courtyards:
        for x, z in region:
            grid[z][x] = FLOOR                          # a courtyard has a floor

    # Entry and exit: the validator guarantees a walkable run in the tile's
    # first and last rows.
    def gap(row_z: int) -> int:
        run = [x for x in range(off, off + tw) if grid[row_z][x] in (FLOOR, FLOOR_SLOT)]
        return run[len(run) // 2] if run else off + tw // 2

    spawn = (gap(off), off)
    exit_cell = (gap(off + th - 1), off + th - 1)

    plan = FloorPlan(width=w, depth=h, grid=grid, route=set(), slots=[],
                     apron=apron, wall_height_m=museum_wall_height_m(),
                     walls=[], spawn=spawn, exit=exit_cell, expandable=False)
    plan.route = _route_between(plan, spawn, exit_cell)

    # Interior slots, carrying the capacity the table computed.
    for sid, rec in caps.items():
        sx, sz = rec["cell"]
        if rooms and sz >= th - 1:
            continue          # the capacity table is over the WHOLE tile; a cropped hall has no such slot
        cell = (sx + off, sz + off)
        token = rec.get("token", FLOOR_SLOT)
        plan.slots.append(Slot(
            id=f"{key}/{sid}", cell=cell, role=token, bay=key,
            bay_side="west" if sx < tw // 2 else "east",
            z_range=(off, off + th),
            wall_side=(rec["wall_sides"][0] if rec.get("wall_sides") else None),
            wall_sides=list(rec.get("wall_sides") or []),
            free_cells=set(), support=("podium" if token in (PODIUM_SLOT, HIGH_PODIUM_SLOT)
                                       else "floor"),
            surface_height_m=(0.95 if token == PODIUM_SLOT else
                              1.4 if token == HIGH_PODIUM_SLOT else 0.0),
            capacity=rec.get("capacity", {}), venue="interior"))

    plan.slots.extend(_exterior_slots(plan, courtyards, off, tw, th, key))
    plan.walls.extend(_wall_surfaces(plan, off, tw, th, key))
    plan._recompute_pockets_from_grid()
    # an INTERIOR slot's pocket stays inside the tile: the flood fill walks out
    # of the exit gap onto the grounds, and on a CROPPED tile (rooms) that put
    # bodies past the last row — rows the assembler never builds
    for s in plan.slots:
        if s.venue == "interior" and s.free_cells:
            s.free_cells = {c for c in s.free_cells if off <= c[0] < off + tw and off <= c[1] < off + th}
    return plan


def _route_between(plan: FloorPlan, a: tuple[int, int],
                   b: tuple[int, int]) -> set[tuple[int, int]]:
    """The protected through-route: the shortest walk from spawn to exit,
    thickened by one cell so an artifact cannot pinch it to nothing."""
    from collections import deque
    prev: dict[tuple[int, int], tuple[int, int]] = {}
    seen = {a}
    q = deque([a])
    while q:
        cur = q.popleft()
        if cur == b:
            break
        x, z = cur
        for n in ((x + 1, z), (x - 1, z), (x, z + 1), (x, z - 1)):
            if n in seen or not plan.walkable(*n):
                continue
            seen.add(n)
            prev[n] = cur
            q.append(n)
    if b not in prev and a != b:
        return set()
    path = [b]
    while path[-1] != a:
        path.append(prev[path[-1]])
    out: set[tuple[int, int]] = set()
    for x, z in path:
        for dx in (-1, 0, 1):
            for dz in (-1, 0, 1):
                if plan.walkable(x + dx, z + dz):
                    out.add((x + dx, z + dz))
    return out


def _exterior_slots(plan: FloorPlan, courtyards: list[set[tuple[int, int]]],
                    off: int, tw: int, th: int, key: str) -> list[Slot]:
    """Venues for bodies the building cannot hold.

    A room-scale artifact is not a failed exhibit — it is an exhibit that wants
    sky. Every one of these is a real, reachable place with a named kind, so a
    placement there is a decision on the record rather than a fallback nobody
    can see.
    """
    out: list[Slot] = []
    for i, region in enumerate(sorted(courtyards, key=len, reverse=True)):
        xs = [c[0] for c in region]
        zs = [c[1] for c in region]
        centre = (sum(xs) // len(xs), sum(zs) // len(zs))
        out.append(Slot(
            id=f"{key}/courtyard{i}", cell=centre, role=FLOOR_SLOT, bay=key,
            bay_side="west", z_range=(min(zs), max(zs) + 1), wall_side=None,
            free_cells=set(region), support="floor", surface_height_m=0.0,
            capacity={}, venue="courtyard"))

    # The porch is a THRESHOLD, not a field: the ground immediately before the
    # door, where a piece still reads as belonging to the entrance. Defining it
    # as the whole apron made it swallow everything, so the grounds were never
    # reached and a room-scale work stood on the doorstep.
    sx, sz = plan.spawn
    porch_depth, porch_half = 6, 5
    out.append(Slot(
        id=f"{key}/porch", cell=(sx, max(1, sz - 3)), role=FLOOR_SLOT, bay=key,
        bay_side="west", z_range=(max(1, sz - porch_depth), sz), wall_side=None,
        free_cells={(x, z)
                    for x in range(sx - porch_half, sx + porch_half + 1)
                    for z in range(max(1, sz - porch_depth), sz)
                    if plan.walkable(x, z)},
        support="floor", surface_height_m=0.0, capacity={}, venue="porch"))

    # The grounds: everything outside the walls, on all four sides.
    grounds = {(x, z) for x in range(1, plan.width - 1) for z in range(1, plan.depth - 1)
               if plan.walkable(x, z)
               and not (off <= x < off + tw and off <= z < off + th)}
    if grounds:
        gx = sum(c[0] for c in grounds) // len(grounds)
        out.append(Slot(
            id=f"{key}/outside", cell=(gx, off + th + 3), role=FLOOR_SLOT, bay=key,
            bay_side="east", z_range=(off + th, plan.depth - 1), wall_side=None,
            free_cells=grounds, support="floor", surface_height_m=0.0,
            capacity={}, venue="outside"))
    return out


def _wall_surfaces(plan: FloorPlan, off: int, tw: int, th: int,
                   key: str) -> list[WallSurface]:
    """EVERY wall face that looks onto walkable floor, grouped into runs.

    The previous version scanned two perimeter columns and found two surfaces
    per museum. That mattered more than it looked: measured across the corpus,
    the floor offers 36 slot series for 481 artifacts that declare a DNA run —
    while the same thirty museums carry 345 wall runs of 4 m or more. Lineages
    are a WALL proposition, and a floorplan that publishes two walls cannot say
    so. A run here is a maximal line of wall cells sharing one facing.
    """
    faces: dict[tuple[str, int, tuple[int, int]], list[int]] = {}
    for z in range(plan.depth):
        for x in range(plan.width):
            if plan.grid[z][x] != WALL:
                continue
            for side, (dx, dz) in (("west", (1, 0)), ("east", (-1, 0)),
                                   ("north", (0, 1)), ("south", (0, -1))):
                if not plan.walkable(x + dx, z + dz):
                    continue
                # A vertical wall varies along z at fixed x, and vice versa.
                if dx:
                    faces.setdefault((side, x, (dx, dz)), []).append(z)
                else:
                    faces.setdefault((side, z, (dx, dz)), []).append(x)

    out: list[WallSurface] = []
    for (side, fixed, normal), coords in sorted(faces.items(), key=lambda kv: str(kv[0])):
        coords.sort()
        start = prev = coords[0]
        for c in coords[1:] + [None]:
            if c is not None and c == prev + 1:
                prev = c
                continue
            length = prev - start + 1
            if length >= 2:
                origin = (fixed, start) if normal[0] else (start, fixed)
                out.append(WallSurface(
                    id=f"{key}/{side}_{fixed}_{start}", side=side, bay=key,
                    bay_side=side, length_m=float(length),
                    height_m=plan.wall_height_m,
                    origin_cell=origin, normal=normal))
            if c is None:
                break
            start = prev = c
    return out


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--museum", default="", help="load an authored museum template")
    p.add_argument("--bays", type=int, default=3)
    p.add_argument("--width", type=int, default=15)
    p.add_argument("--bay-depth", type=int, default=7)
    p.add_argument("--ascii", action="store_true")
    args = p.parse_args()
    plan = build_enfilade(args.bays, args.width, args.bay_depth)
    if args.ascii:
        print(plan.ascii())
        print()
    print(json.dumps({
        "width": plan.width, "depth": plan.depth,
        "spawn": list(plan.spawn), "exit": list(plan.exit),
        "route_cells": len(plan.route),
        "slots": [s.as_dict() for s in plan.slots],
        "walls": [w.as_dict() for w in plan.walls],
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
