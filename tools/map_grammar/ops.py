"""Map operations — the grammar's vocabulary.

Each operation takes a MapState + params and mutates it. Configs are
JSON dicts with `{rows, cols, ops: [{op, params}, ...]}`. The runner
applies them in order.

Operations grouped by tier:

  shape:      room, plinth_field, hollow_box, frame
  walk:       drunkard_walk, lsystem_walk
  partition:  bsp
  automaton:  ca_evolve
  motif:      mirror, tile_motif, repeat_grid
  finish:     spawn_at, teleport_at, label_corner

The composer adds `s` / `t` automatically if not placed.
"""
from __future__ import annotations

import math
import random
from dataclasses import dataclass, field


@dataclass
class MapState:
    rows: int
    cols: int
    structure: list[list[int]] = field(default_factory=list)
    utilities: list[list[str]] = field(default_factory=list)
    interactables: list[list[str]] = field(default_factory=list)

    def __post_init__(self):
        if not self.structure:
            self.structure = [[0] * self.cols for _ in range(self.rows)]
        if not self.utilities:
            self.utilities = [[" "] * self.cols for _ in range(self.rows)]
        if not self.interactables:
            self.interactables = [[" "] * self.cols for _ in range(self.rows)]

    def in_bounds(self, r: int, c: int) -> bool:
        return 0 <= r < self.rows and 0 <= c < self.cols

    def set_h(self, r: int, c: int, h: int):
        if self.in_bounds(r, c):
            self.structure[r][c] = max(0, min(5, h))

    def get_h(self, r: int, c: int) -> int:
        return self.structure[r][c] if self.in_bounds(r, c) else 0


# Op registry. Each op is `def fn(state, params, rng) -> None`.
_OPS: dict = {}


def op(name):
    def deco(fn):
        _OPS[name] = fn
        return fn
    return deco


# ── Shape ops ─────────────────────────────────────────────────────────

@op("room")
def op_room(state: MapState, p: dict, rng: random.Random):
    """Rectangular floor room. Optional border walls."""
    r = int(p.get("r", 0)); c = int(p.get("c", 0))
    h = int(p.get("h", 4)); w = int(p.get("w", 4))
    fill = int(p.get("fill", 1))
    border = int(p.get("border", 0))   # 0 = no wall, else wall height
    for dr in range(h):
        for dc in range(w):
            rr, cc = r + dr, c + dc
            if not state.in_bounds(rr, cc): continue
            on_edge = (dr == 0 or dr == h - 1 or dc == 0 or dc == w - 1)
            state.set_h(rr, cc, border if (border and on_edge) else fill)


@op("frame")
def op_frame(state: MapState, p: dict, rng: random.Random):
    """Wall border around the whole grid."""
    h = int(p.get("h", 2))
    for r in range(state.rows):
        state.set_h(r, 0, h)
        state.set_h(r, state.cols - 1, h)
    for c in range(state.cols):
        state.set_h(0, c, h)
        state.set_h(state.rows - 1, c, h)


@op("plinth_field")
def op_plinth_field(state: MapState, p: dict, rng: random.Random):
    """Scatter plinth cells (h=2 by default) over walkable cells."""
    spacing = int(p.get("spacing", 3))
    plinth_h = int(p.get("plinth_h", 2))
    for r in range(0, state.rows, spacing):
        for c in range(0, state.cols, spacing):
            if state.get_h(r, c) >= 1:
                state.set_h(r, c, plinth_h)


# ── Walk ops ──────────────────────────────────────────────────────────

@op("drunkard_walk")
def op_drunkard(state: MapState, p: dict, rng: random.Random):
    fraction = float(p.get("fraction", 0.4))
    target = int(state.rows * state.cols * fraction)
    r, c = state.rows // 2, state.cols // 2
    state.set_h(r, c, 1)
    visited = 1
    steps = 0
    cap = target * 12
    while visited < target and steps < cap:
        dr, dc = rng.choice([(-1, 0), (1, 0), (0, -1), (0, 1)])
        nr, nc = max(1, min(state.rows - 2, r + dr)), max(1, min(state.cols - 2, c + dc))
        r, c = nr, nc
        if state.get_h(r, c) == 0:
            state.set_h(r, c, 1)
            visited += 1
        steps += 1


@op("lsystem_walk")
def op_lsystem_walk(state: MapState, p: dict, rng: random.Random):
    """Carve floor along an L-system turtle path. Axiom is a string of
    symbols; rules expand one symbol → string. F = step+carve, + = turn
    right, - = turn left, [ = push, ] = pop."""
    axiom = str(p.get("axiom", "F"))
    rules: dict = p.get("rules", {"F": "F+F-F-F+F"})
    iterations = int(p.get("iterations", 3))
    angle = int(p.get("angle", 90))
    start_r = int(p.get("start_r", state.rows // 2))
    start_c = int(p.get("start_c", state.cols // 2))
    s = axiom
    for _ in range(iterations):
        s = "".join(rules.get(ch, ch) for ch in s)
    r = start_r; c = start_c; heading = 0      # 0=N, 90=E, 180=S, 270=W
    stack: list[tuple] = []
    state.set_h(r, c, 1)
    for ch in s:
        if ch == "F":
            dr = -1 if heading == 0 else (1 if heading == 180 else 0)
            dc = 1 if heading == 90 else (-1 if heading == 270 else 0)
            r += dr; c += dc
            if state.in_bounds(r, c):
                state.set_h(r, c, 1)
            else:
                break
        elif ch == "+":
            heading = (heading + angle) % 360
        elif ch == "-":
            heading = (heading - angle) % 360
        elif ch == "[":
            stack.append((r, c, heading))
        elif ch == "]":
            if stack: r, c, heading = stack.pop()


# ── Partition ─────────────────────────────────────────────────────────

@op("bsp")
def op_bsp(state: MapState, p: dict, rng: random.Random):
    min_size = int(p.get("min_size", 4))
    pad = int(p.get("pad", 1))
    rooms: list = []

    def split(r: int, c: int, h: int, w: int):
        if h <= min_size * 2 + 2 and w <= min_size * 2 + 2:
            rooms.append((r, c, h, w)); return
        if h > w and h > min_size * 2 + 2:
            cut = rng.randint(min_size + 1, h - min_size - 1)
            split(r, c, cut, w); split(r + cut, c, h - cut, w)
        elif w > min_size * 2 + 2:
            cut = rng.randint(min_size + 1, w - min_size - 1)
            split(r, c, h, cut); split(r, c + cut, h, w - cut)
        else:
            rooms.append((r, c, h, w))

    split(0, 0, state.rows, state.cols)
    centers: list = []
    for (rr, cc, hh, ww) in rooms:
        r0 = rr + 1 + pad; c0 = cc + 1 + pad
        r1 = rr + hh - 1 - pad; c1 = cc + ww - 1 - pad
        if r1 <= r0 or c1 <= c0: continue
        for r in range(r0, r1):
            for c in range(c0, c1):
                state.set_h(r, c, 1)
        centers.append(((r0 + r1) // 2, (c0 + c1) // 2))
    for i in range(len(centers) - 1):
        (r0, c0), (r1, c1) = centers[i], centers[i + 1]
        for c in range(min(c0, c1), max(c0, c1) + 1):
            state.set_h(r0, c, 1)
        for r in range(min(r0, r1), max(r0, r1) + 1):
            state.set_h(r, c1, 1)


# ── Automaton ─────────────────────────────────────────────────────────

@op("ca_evolve")
def op_ca_evolve(state: MapState, p: dict, rng: random.Random):
    """One step of CA cave smoothing on existing structure (treating
    walkable cells as 'alive')."""
    iterations = int(p.get("iterations", 4))
    birth = int(p.get("birth", 5))
    for _ in range(iterations):
        snap = [row[:] for row in state.structure]
        for r in range(state.rows):
            for c in range(state.cols):
                walls = 0
                for dr in (-1, 0, 1):
                    for dc in (-1, 0, 1):
                        if dr == 0 and dc == 0: continue
                        nr, nc = r + dr, c + dc
                        if not state.in_bounds(nr, nc) or snap[nr][nc] == 0:
                            walls += 1
                state.set_h(r, c, 0 if walls >= birth else max(1, snap[r][c]))


# ── Width / safety ops ────────────────────────────────────────────────

@op("thicken")
def op_thicken(state: MapState, p: dict, rng: random.Random):
    """Dilate walkable cells (h>=min_h) to a minimum width. Without this,
    walks and L-systems produce single-cell paths that are easy to fall
    off. Run with `radius=1` after any walk/lsystem op for 2-cell-wide
    corridors. `axis` ∈ {both, h, v, diag} — controls which direction(s)
    we dilate in."""
    radius = int(p.get("radius", 1))
    min_h = int(p.get("min_h", 1))
    axis = str(p.get("axis", "both"))
    fill = int(p.get("fill", 1))
    # Take a snapshot of current walkable cells then mark neighbours.
    snap = [row[:] for row in state.structure]
    for r in range(state.rows):
        for c in range(state.cols):
            if snap[r][c] < min_h: continue
            for dr in range(-radius, radius + 1):
                for dc in range(-radius, radius + 1):
                    if dr == 0 and dc == 0: continue
                    if axis == "h" and dr != 0: continue
                    if axis == "v" and dc != 0: continue
                    if axis == "diag" and dr * dc == 0: continue
                    nr, nc = r + dr, c + dc
                    if not state.in_bounds(nr, nc): continue
                    if state.get_h(nr, nc) == 0:
                        state.set_h(nr, nc, fill)


@op("safe_borders")
def op_safe_borders(state: MapState, p: dict, rng: random.Random):
    """Keep the player on the map: any walkable cell touching the grid
    edge gets pushed inward, AND any cell adjacent to walkable that's
    on the edge becomes a wall."""
    edge_h = int(p.get("edge_h", 2))
    for r in range(state.rows):
        if state.get_h(r, 0) == 1: state.set_h(r, 0, edge_h)
        if state.get_h(r, state.cols - 1) == 1:
            state.set_h(r, state.cols - 1, edge_h)
    for c in range(state.cols):
        if state.get_h(0, c) == 1: state.set_h(0, c, edge_h)
        if state.get_h(state.rows - 1, c) == 1:
            state.set_h(state.rows - 1, c, edge_h)


@op("corridor")
def op_corridor(state: MapState, p: dict, rng: random.Random):
    """Carve a 2-wide L-shaped corridor between two anchor cells."""
    r0 = int(p.get("from_r", 1)); c0 = int(p.get("from_c", 1))
    r1 = int(p.get("to_r", state.rows - 2)); c1 = int(p.get("to_c", state.cols - 2))
    width = int(p.get("width", 2))
    half = width // 2
    # Horizontal leg first.
    for c in range(min(c0, c1), max(c0, c1) + 1):
        for d in range(-half, width - half):
            state.set_h(r0 + d, c, 1)
    # Then vertical leg at c1.
    for r in range(min(r0, r1), max(r0, r1) + 1):
        for d in range(-half, width - half):
            state.set_h(r, c1 + d, 1)


@op("staircase")
def op_staircase(state: MapState, p: dict, rng: random.Random):
    """Linear ramp of plinths from height min to height max along a row
    or column. The player can step up one cell at a time."""
    r = int(p.get("r", state.rows // 2))
    c = int(p.get("c", state.cols // 2))
    direction = str(p.get("direction", "east"))   # east, west, north, south
    length = int(p.get("length", 5))
    start = int(p.get("start", 1))
    step = int(p.get("step", 1))
    drs = {"east": (0, 1), "west": (0, -1), "north": (-1, 0), "south": (1, 0)}
    dr, dc = drs.get(direction, (0, 1))
    for i in range(length):
        h = min(5, start + i * step)
        rr, cc = r + dr * i, c + dc * i
        state.set_h(rr, cc, h)


@op("circle_room")
def op_circle_room(state: MapState, p: dict, rng: random.Random):
    """Round room of walkable floor with optional wall ring."""
    cr = int(p.get("r", state.rows // 2))
    cc = int(p.get("c", state.cols // 2))
    radius = float(p.get("radius", 4))
    border_h = int(p.get("border", 0))
    fill = int(p.get("fill", 1))
    for r in range(state.rows):
        for c in range(state.cols):
            d = math.hypot(r - cr, c - cc)
            if d <= radius - 0.5:
                state.set_h(r, c, fill)
            elif border_h and d <= radius + 0.5:
                state.set_h(r, c, border_h)


# ── Motif ops ─────────────────────────────────────────────────────────

@op("mirror")
def op_mirror(state: MapState, p: dict, rng: random.Random):
    axis = str(p.get("axis", "horizontal"))     # horizontal | vertical | both
    if axis in ("horizontal", "both"):
        for r in range(state.rows):
            for c in range(state.cols // 2):
                v = state.structure[r][c]
                state.structure[r][state.cols - 1 - c] = v
    if axis in ("vertical", "both"):
        for r in range(state.rows // 2):
            for c in range(state.cols):
                v = state.structure[r][c]
                state.structure[state.rows - 1 - r][c] = v


@op("tile_motif")
def op_tile_motif(state: MapState, p: dict, rng: random.Random):
    """Stamp a small motif (list of lists) across the grid at a step."""
    motif = p.get("motif", [[1, 1, 1], [1, 2, 1], [1, 1, 1]])
    step = int(p.get("step", 4))
    offset_r = int(p.get("offset_r", 1))
    offset_c = int(p.get("offset_c", 1))
    mh = len(motif); mw = len(motif[0]) if mh else 0
    for r in range(offset_r, state.rows - mh + 1, step):
        for c in range(offset_c, state.cols - mw + 1, step):
            for dr in range(mh):
                for dc in range(mw):
                    state.set_h(r + dr, c + dc, int(motif[dr][dc]))


# ── Field / partition ops ─────────────────────────────────────────────

@op("noise_field")
def op_noise_field(state: MapState, p: dict, rng: random.Random):
    """Threshold a value-noise field to floor cells. Cheap noise with no
    library: random per-cell + box blur N times produces smooth blobs."""
    threshold = float(p.get("threshold", 0.5))
    blur_passes = int(p.get("blur", 3))
    fill = int(p.get("fill", 1))
    # Random seed values.
    grid = [[rng.random() for _ in range(state.cols)] for _ in range(state.rows)]
    # Box-blur for smoothness.
    for _ in range(blur_passes):
        snap = [row[:] for row in grid]
        for r in range(state.rows):
            for c in range(state.cols):
                tot = 0.0; n = 0
                for dr in (-1, 0, 1):
                    for dc in (-1, 0, 1):
                        nr, nc = r + dr, c + dc
                        if 0 <= nr < state.rows and 0 <= nc < state.cols:
                            tot += snap[nr][nc]; n += 1
                grid[r][c] = tot / n
    for r in range(state.rows):
        for c in range(state.cols):
            if grid[r][c] >= threshold:
                state.set_h(r, c, fill)


@op("voronoi_cells")
def op_voronoi_cells(state: MapState, p: dict, rng: random.Random):
    """Voronoi-style: drop N seeds, each cell takes the height of its
    nearest seed. Borders between cells stay at h=2 as walls."""
    n_seeds = int(p.get("n_seeds", 5))
    border_h = int(p.get("border", 2))
    seeds: list[tuple[int, int, int]] = []
    for _ in range(n_seeds):
        r = rng.randint(1, state.rows - 2)
        c = rng.randint(1, state.cols - 2)
        h = rng.choice([1, 1, 1, 2])    # mostly floor, sometimes plinth
        seeds.append((r, c, h))
    if not seeds: return
    owner = [[0] * state.cols for _ in range(state.rows)]
    for r in range(state.rows):
        for c in range(state.cols):
            best_d = 1e9; best_i = 0
            for i, (sr, sc, _) in enumerate(seeds):
                d = (r - sr) ** 2 + (c - sc) ** 2
                if d < best_d: best_d = d; best_i = i
            owner[r][c] = best_i
    for r in range(state.rows):
        for c in range(state.cols):
            state.set_h(r, c, seeds[owner[r][c]][2])
    # Borders: mark cells whose 4-neighbour owner differs.
    for r in range(state.rows):
        for c in range(state.cols):
            for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                nr, nc = r + dr, c + dc
                if 0 <= nr < state.rows and 0 <= nc < state.cols:
                    if owner[nr][nc] != owner[r][c]:
                        state.set_h(r, c, border_h); break


@op("subdivide")
def op_subdivide(state: MapState, p: dict, rng: random.Random):
    """Fractal subdivision: recursively split rooms, each leaf gets a
    randomly chosen height. depth controls recursion."""
    depth = int(p.get("depth", 3))
    leaf_heights = p.get("heights", [0, 1, 1, 1, 2])
    def split(r: int, c: int, h: int, w: int, d: int):
        if d == 0 or h < 2 or w < 2:
            v = rng.choice(leaf_heights)
            for rr in range(r, r + h):
                for cc in range(c, c + w):
                    state.set_h(rr, cc, int(v))
            return
        if w >= h:
            cut = rng.randint(1, w - 1)
            split(r, c, h, cut, d - 1); split(r, c + cut, h, w - cut, d - 1)
        else:
            cut = rng.randint(1, h - 1)
            split(r, c, cut, w, d - 1); split(r + cut, c, h - cut, w, d - 1)
    split(0, 0, state.rows, state.cols, depth)


@op("rotate90")
def op_rotate90(state: MapState, p: dict, rng: random.Random):
    """Rotate the grid 90° clockwise (in place if square; else clipped)."""
    if state.rows != state.cols: return
    n = state.rows
    snap = [row[:] for row in state.structure]
    for r in range(n):
        for c in range(n):
            state.structure[c][n - 1 - r] = snap[r][c]


@op("checker")
def op_checker(state: MapState, p: dict, rng: random.Random):
    """Checkerboard pattern of two heights — useful as a starting seed
    for grid_with_motif chains."""
    h_a = int(p.get("h_a", 1))
    h_b = int(p.get("h_b", 2))
    period = int(p.get("period", 1))
    for r in range(state.rows):
        for c in range(state.cols):
            v = h_a if ((r // period) + (c // period)) % 2 == 0 else h_b
            state.set_h(r, c, v)


@op("border_plinths")
def op_border_plinths(state: MapState, p: dict, rng: random.Random):
    """Plinths along the perimeter, stepping at given period."""
    period = int(p.get("period", 3))
    plinth_h = int(p.get("h", 3))
    for c in range(0, state.cols, period):
        state.set_h(0, c, plinth_h)
        state.set_h(state.rows - 1, c, plinth_h)
    for r in range(0, state.rows, period):
        state.set_h(r, 0, plinth_h)
        state.set_h(r, state.cols - 1, plinth_h)


# ── Codex / plate ops (inspired by recent blog work) ──────────────────

@op("petal_ring")
def op_petal_ring(state: MapState, p: dict, rng: random.Random):
    """Stamp N petals radiating from a centre — the flower-from-above.
    Each petal is a 1×len rectangle of plinth (h=2) tilted toward the
    rim. Inspired by the-flower-has-petals + cluster_by_role.

    Reads as a Haeckel plate when seen top-down: spatial position carries
    claim, the diagram is the argument."""
    cr = int(p.get("r", state.rows // 2))
    cc = int(p.get("c", state.cols // 2))
    n = int(p.get("n", 6))
    inner = float(p.get("inner_radius", 1.5))
    outer = float(p.get("outer_radius", 5.0))
    petal_h = int(p.get("petal_h", 2))
    centre_h = int(p.get("centre_h", 3))
    floor_radius = float(p.get("floor_radius", outer + 1))
    # Carve a circular floor under everything so the diagram has ground.
    for r in range(state.rows):
        for c in range(state.cols):
            if math.hypot(r - cr, c - cc) <= floor_radius:
                if state.get_h(r, c) == 0:
                    state.set_h(r, c, 1)
    # Stamp N petals.
    for i in range(n):
        ang = 2 * math.pi * i / n
        steps = int(math.ceil(outer - inner)) + 1
        for s in range(steps):
            t = inner + s * (outer - inner) / max(1, steps - 1)
            pr = int(round(cr + math.cos(ang) * t))
            pc = int(round(cc + math.sin(ang) * t))
            if state.in_bounds(pr, pc):
                state.set_h(pr, pc, petal_h)
    # Centre keystone — pistil of the flower.
    state.set_h(cr, cc, centre_h)


@op("vignette_room")
def op_vignette_room(state: MapState, p: dict, rng: random.Random):
    """A small framed cell in the Haeckel-plate style — wall border, a
    central plinth, and a single approach corridor. The whole map reads
    as ONE specimen on the page."""
    border_h = int(p.get("border", 4))
    centre_h = int(p.get("centre_h", 3))
    margin = int(p.get("margin", 2))
    rows, cols = state.rows, state.cols
    # Inner floor.
    for r in range(margin, rows - margin):
        for c in range(margin, cols - margin):
            state.set_h(r, c, 1)
    # Wall frame just outside the floor.
    for r in range(margin - 1, rows - margin + 1):
        for c in (margin - 1, cols - margin):
            if state.in_bounds(r, c) and state.get_h(r, c) == 0:
                state.set_h(r, c, border_h)
    for c in range(margin - 1, cols - margin + 1):
        for r in (margin - 1, rows - margin):
            if state.in_bounds(r, c) and state.get_h(r, c) == 0:
                state.set_h(r, c, border_h)
    # Centre keystone.
    state.set_h(rows // 2, cols // 2, centre_h)


@op("sequence_banner")
def op_sequence_banner(state: MapState, p: dict, rng: random.Random):
    """The QFEP-formula-banner equivalent: a long narrow entry strip
    with a tall feature wall in the middle. Inspired by the
    `qfep-formula-banner` template in curriculum-shaped-templates."""
    banner_row = int(p.get("row", state.rows // 4))
    banner_h = int(p.get("h", 4))
    pillar_period = int(p.get("pillar_every", 4))
    # Floor strip 3-wide centred on banner_row.
    for c in range(state.cols):
        for dr in (-1, 0, 1):
            rr = banner_row + dr
            if state.in_bounds(rr, c):
                state.set_h(rr, c, 1)
    # Tall feature wall above the strip, with periodic openings.
    for c in range(state.cols):
        if c % pillar_period == pillar_period // 2:
            continue   # opening
        if state.in_bounds(banner_row - 2, c):
            state.set_h(banner_row - 2, c, banner_h)


@op("axis_with_branches")
def op_axis_with_branches(state: MapState, p: dict, rng: random.Random):
    """Spine motif: a central east-west axis with N small chambers
    branching off at regular intervals. The map reads as a vertebrate
    skeleton from top-down — spine plus ribs."""
    axis_row = int(p.get("row", state.rows // 2))
    chambers = int(p.get("chambers", 4))
    chamber_size = int(p.get("size", 3))
    side = str(p.get("side", "alternate"))   # north/south/alternate
    # Carve the axis itself (2-wide).
    for c in range(1, state.cols - 1):
        for dr in (-1, 0, 1):
            rr = axis_row + dr
            if state.in_bounds(rr, c):
                state.set_h(rr, c, 1)
    # Branches.
    if chambers <= 0: return
    step_c = max(1, (state.cols - chamber_size - 2) // chambers)
    for i in range(chambers):
        c0 = 1 + i * step_c
        if side == "north":
            cardinal = -1
        elif side == "south":
            cardinal = 1
        else:
            cardinal = -1 if i % 2 == 0 else 1
        for dr in range(1, chamber_size + 1):
            for dc in range(chamber_size):
                rr = axis_row + cardinal * (1 + dr)
                cc = c0 + dc
                if state.in_bounds(rr, cc):
                    state.set_h(rr, cc, 1)


@op("ca_mask")
def op_ca_mask(state: MapState, p: dict, rng: random.Random):
    """Apply a Wolfram-style 1D CA evolution as a mask over walkable
    cells: each row is the next CA generation. Cells where the CA outputs
    1 stay walkable; 0 become void. Inspired by grid_visibility_mutator
    + Wolfram CA running over the substrate."""
    rule = int(p.get("rule", 90))
    rows, cols = state.rows, state.cols
    # Build CA grid, seeded centred at top.
    ca = [[0] * cols for _ in range(rows)]
    ca[0][cols // 2] = 1
    for r in range(1, rows):
        for c in range(cols):
            l = ca[r - 1][c - 1] if c > 0 else 0
            m = ca[r - 1][c]
            ri = ca[r - 1][c + 1] if c + 1 < cols else 0
            idx = (l << 2) | (m << 1) | ri
            ca[r][c] = (rule >> idx) & 1
    # Mask: cells where ca==0 become void; ca==1 keep (or carve to floor).
    for r in range(rows):
        for c in range(cols):
            if ca[r][c] == 1:
                if state.get_h(r, c) == 0:
                    state.set_h(r, c, 1)
            else:
                state.set_h(r, c, 0)


@op("sierpinski")
def op_sierpinski(state: MapState, p: dict, rng: random.Random):
    """Sierpinski-triangle mask: cells where (row & col) == 0 become
    walkable, rest void. A self-similar fractal floor."""
    fill = int(p.get("fill", 1))
    for r in range(state.rows):
        for c in range(state.cols):
            if (r & c) == 0:
                state.set_h(r, c, fill)
            else:
                state.set_h(r, c, 0)


# ── Spatial-tradition ops ─────────────────────────────────────────────

@op("column_grid")
def op_column_grid(state: MapState, p: dict, rng: random.Random):
    """Mies van der Rohe — Universal Space. A large open hall punctuated
    by structural columns at a regular spacing. The columns provide
    rhythm and visual weight without compartmenting the floor."""
    r0 = int(p.get("r", 1)); c0 = int(p.get("c", 1))
    h = int(p.get("h", state.rows - 2)); w = int(p.get("w", state.cols - 2))
    column_period = int(p.get("period", 4))
    column_h = int(p.get("column_h", 4))
    floor_h = int(p.get("floor", 1))
    for r in range(r0, r0 + h):
        for c in range(c0, c0 + w):
            if state.in_bounds(r, c):
                state.set_h(r, c, floor_h)
    # Columns at regular grid points within the hall.
    for r in range(r0 + column_period // 2, r0 + h, column_period):
        for c in range(c0 + column_period // 2, c0 + w, column_period):
            if state.in_bounds(r, c):
                state.set_h(r, c, column_h)


@op("ulam_spiral")
def op_ulam_spiral(state: MapState, p: dict, rng: random.Random):
    """Walk a square spiral outward from the centre. At each step, mark
    the cell IF its step index is prime (primes-plotted-on-spiral, the
    Ulam original) OR if its step index passes a custom predicate."""
    mode = str(p.get("mode", "primes"))   # primes | fibonacci | mod
    fill = int(p.get("fill", 1))
    cr, cc = state.rows // 2, state.cols // 2
    state.set_h(cr, cc, fill)
    # Generate spiral step sequence: right, up, left, left, down, down, …
    steps = max(state.rows, state.cols) ** 2
    is_prime: dict[int, bool] = {}
    def prime(n: int) -> bool:
        if n < 2: return False
        if n in is_prime: return is_prime[n]
        for d in range(2, int(n ** 0.5) + 1):
            if n % d == 0: is_prime[n] = False; return False
        is_prime[n] = True; return True
    fibs = {1, 2}
    a, b = 1, 2
    while b < steps:
        a, b = b, a + b
        fibs.add(b)
    r, c = cr, cc
    direction = 0
    leg_length = 1
    n = 1
    legs_done_at_length = 0
    dirs = [(0, 1), (-1, 0), (0, -1), (1, 0)]   # right, up, left, down
    while n < steps:
        dr, dc = dirs[direction]
        for _ in range(leg_length):
            r += dr; c += dc
            n += 1
            mark = False
            if mode == "primes": mark = prime(n)
            elif mode == "fibonacci": mark = n in fibs
            elif mode == "mod":
                k = int(p.get("k", 7))
                mark = (n % k == 0)
            if mark and state.in_bounds(r, c):
                state.set_h(r, c, fill)
        direction = (direction + 1) % 4
        legs_done_at_length += 1
        if legs_done_at_length == 2:
            leg_length += 1
            legs_done_at_length = 0


@op("screen_grid")
def op_screen_grid(state: MapState, p: dict, rng: random.Random):
    """Zelda-1 overworld: an N×M grid of small rooms, each separated by
    walls, connected to its neighbours by a single-cell doorway in each
    cardinal direction. Players move screen-by-screen."""
    rows_n = int(p.get("rows_n", 3))
    cols_n = int(p.get("cols_n", 4))
    wall_h = int(p.get("wall_h", 4))
    pad = int(p.get("pad", 1))
    cell_h = (state.rows - pad) // rows_n
    cell_w = (state.cols - pad) // cols_n
    if cell_h < 3 or cell_w < 3: return
    # Fill all walls.
    for r in range(state.rows):
        for c in range(state.cols):
            state.set_h(r, c, wall_h)
    # Carve each screen's interior.
    for ri in range(rows_n):
        for ci in range(cols_n):
            r0 = pad + ri * cell_h
            c0 = pad + ci * cell_w
            for dr in range(1, cell_h - 1):
                for dc in range(1, cell_w - 1):
                    state.set_h(r0 + dr, c0 + dc, 1)
            # Doorway to right neighbour.
            if ci < cols_n - 1:
                door_r = r0 + cell_h // 2
                door_c = c0 + cell_w - 1
                if state.in_bounds(door_r, door_c):
                    state.set_h(door_r, door_c, 1)
                    state.set_h(door_r, door_c + 1, 1)
            # Doorway down.
            if ri < rows_n - 1:
                door_r = r0 + cell_h - 1
                door_c = c0 + cell_w // 2
                if state.in_bounds(door_r, door_c):
                    state.set_h(door_r, door_c, 1)
                    state.set_h(door_r + 1, door_c, 1)


@op("mansion_hub")
def op_mansion_hub(state: MapState, p: dict, rng: random.Random):
    """Resident Evil mansion: a central round/square hall, radial
    corridors out to satellite rooms. Return-to-hub backbone."""
    cr = state.rows // 2; cc = state.cols // 2
    hub_radius = int(p.get("hub_radius", 4))
    n_rooms = int(p.get("n_rooms", 4))
    room_size = int(p.get("room_size", 3))
    arm_length = int(p.get("arm_length", 4))
    # Hub.
    for r in range(state.rows):
        for c in range(state.cols):
            if math.hypot(r - cr, c - cc) <= hub_radius:
                state.set_h(r, c, 1)
    for i in range(n_rooms):
        ang = 2 * math.pi * i / n_rooms
        # Corridor out from hub to satellite.
        for s in range(1, hub_radius + arm_length + 1):
            pr = int(round(cr + math.cos(ang) * s))
            pc = int(round(cc + math.sin(ang) * s))
            if state.in_bounds(pr, pc):
                state.set_h(pr, pc, 1)
                # 2-wide corridor.
                for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    if state.in_bounds(pr + dr, pc + dc) and state.get_h(pr + dr, pc + dc) == 0:
                        # Only thicken if outside hub.
                        if math.hypot(pr - cr, pc - cc) > hub_radius:
                            pass   # stay 1-wide for narrow corridors
        # Satellite room at the tip.
        tip_r = int(round(cr + math.cos(ang) * (hub_radius + arm_length + 1)))
        tip_c = int(round(cc + math.sin(ang) * (hub_radius + arm_length + 1)))
        for dr in range(-(room_size // 2), room_size - room_size // 2):
            for dc in range(-(room_size // 2), room_size - room_size // 2):
                if state.in_bounds(tip_r + dr, tip_c + dc):
                    state.set_h(tip_r + dr, tip_c + dc, 1)


@op("serpentine_path")
def op_serpentine_path(state: MapState, p: dict, rng: random.Random):
    """Capability Brown — picturesque meander. A sinusoidal floor path
    sweeps across the map, with random reveals (small adjacent floor
    patches) at the path's local extrema."""
    amplitude = float(p.get("amplitude", 4.0))
    frequency = float(p.get("frequency", 1.5))
    width = int(p.get("width", 2))
    base_row = int(p.get("base_row", state.rows // 2))
    reveal_chance = float(p.get("reveal_chance", 0.4))
    half = width // 2
    for c in range(state.cols):
        offset = amplitude * math.sin(2 * math.pi * frequency * c / max(1, state.cols))
        path_r = int(round(base_row + offset))
        for d in range(-half, width - half):
            rr = path_r + d
            if state.in_bounds(rr, c):
                state.set_h(rr, c, 1)
        # Reveal patches at local maxima/minima of the sine.
        if rng.random() < reveal_chance / state.cols * 4:
            patch_r = path_r + (3 if offset > 0 else -3)
            for dr in (-1, 0, 1):
                for dc in (-1, 0, 1):
                    if state.in_bounds(patch_r + dr, c + dc):
                        state.set_h(patch_r + dr, c + dc, 1)


# ── Multi-level / hard-to-express ops ─────────────────────────────────

@op("raumplan")
def op_raumplan(state: MapState, p: dict, rng: random.Random):
    """Adolf Loos — Raumplan. Two interlocking half-level volumes with a
    step transition. Half the floor at h=1, the other half at h=2,
    arranged so the boundary creates a usable step (diff=1, walkable)."""
    split = str(p.get("split", "horizontal"))   # horizontal | vertical | quadrant
    low_h = int(p.get("low", 1))
    high_h = int(p.get("high", 2))
    border_h = int(p.get("border", 4))
    # Outer wall.
    for r in range(state.rows):
        state.set_h(r, 0, border_h)
        state.set_h(r, state.cols - 1, border_h)
    for c in range(state.cols):
        state.set_h(0, c, border_h)
        state.set_h(state.rows - 1, c, border_h)
    # Two volumes.
    if split == "horizontal":
        mid = state.rows // 2
        for r in range(1, state.rows - 1):
            for c in range(1, state.cols - 1):
                state.set_h(r, c, low_h if r < mid else high_h)
    elif split == "vertical":
        mid = state.cols // 2
        for r in range(1, state.rows - 1):
            for c in range(1, state.cols - 1):
                state.set_h(r, c, low_h if c < mid else high_h)
    else:  # quadrant
        mr = state.rows // 2; mc = state.cols // 2
        for r in range(1, state.rows - 1):
            for c in range(1, state.cols - 1):
                # Diagonal split: NW + SE = low, NE + SW = high.
                top = (r < mr) ^ (c < mc)
                state.set_h(r, c, high_h if top else low_h)


@op("terraced")
def op_terraced(state: MapState, p: dict, rng: random.Random):
    """Stepped amphitheatre / terraced landscape. Concentric rings of
    descending height, climbable by single-step rule.

    rng-aware: per-call, randomises (a) the centre offset by a few
    cells, (b) the distance metric (Chebyshev/Euclidean/Manhattan), and
    (c) which cardinal direction the radial down-path carves. Two calls
    with the same dims but different seeds produce visibly distinct
    rings — the strategy retains its terraced character while gaining
    per-base personality."""
    center_h = int(p.get("center_h", 1))
    max_h = int(p.get("max_h", 4))
    cr = state.rows // 2 + rng.randint(-1, 1)
    cc = state.cols // 2 + rng.randint(-1, 1)
    cr = max(1, min(state.rows - 2, cr))
    cc = max(1, min(state.cols - 2, cc))
    metric = rng.choice(["chebyshev", "euclidean", "manhattan"])

    def dist(r: int, c: int) -> float:
        dr, dc = abs(r - cr), abs(c - cc)
        if metric == "chebyshev":  return max(dr, dc)
        if metric == "manhattan":  return dr + dc
        return (dr * dr + dc * dc) ** 0.5

    for r in range(state.rows):
        for c in range(state.cols):
            d = dist(r, c)
            h = max(1, min(5, int(max_h - d))) if d <= max_h - center_h else 1
            state.set_h(r, c, h)
    # Carve a single radial path inward toward a random cardinal edge.
    direction = rng.choice([(1, 0), (-1, 0), (0, 1), (0, -1)])
    r = cr; c = cc
    for _ in range(max_h):
        state.set_h(r, c, 1)
        r += direction[0]; c += direction[1]
        if not state.in_bounds(r, c): break


@op("safdie_cluster")
def op_safdie_cluster(state: MapState, p: dict, rng: random.Random):
    """Habitat 67 — modular cube clusters stacked at varying heights.
    Small footprint blocks (1×1 to 2×2) placed by random walk + height
    sampled from a bell-ish distribution so most are h=1-2 with a few
    h=3-4 making rooflines."""
    n_modules = int(p.get("n_modules", 30))
    max_h = int(p.get("max_h", 4))
    r = state.rows // 2; c = state.cols // 2
    for _ in range(n_modules):
        # Bell-ish height: weight toward 1-2.
        weights = [0.0, 0.45, 0.30, 0.15, 0.08, 0.02]
        roll = rng.random(); accum = 0.0; h = 1
        for hh in range(1, min(6, max_h + 1)):
            accum += weights[hh]
            if roll < accum: h = hh; break
        # 1×1 or 2×2.
        size = rng.choice([1, 1, 2])
        for dr in range(size):
            for dc in range(size):
                if state.in_bounds(r + dr, c + dc):
                    state.set_h(r + dr, c + dc, h)
        # Step.
        dr, dc = rng.choice([(-1, 0), (1, 0), (0, -1), (0, 1)])
        r = max(1, min(state.rows - 2, r + dr * size))
        c = max(1, min(state.cols - 2, c + dc * size))


@op("dark_souls_loop")
def op_dark_souls_loop(state: MapState, p: dict, rng: random.Random):
    """Multi-path topology with shortcut loops. Two corridors fork from
    spawn area, descend along separate routes, meet again at an end
    chamber. Plus one shortcut connecting the two halves midway."""
    rows, cols = state.rows, state.cols
    spawn_r = 2; spawn_c = cols // 2
    end_r = rows - 3; end_c = cols // 2
    # Two arcing corridors via different rows.
    arc1_r = rows // 4
    arc2_r = 3 * rows // 4
    width = 2
    half = width // 2
    # Corridor 1: spawn_c → arc1_r far-right → end_c
    for c in range(spawn_c, cols - 2):
        for d in range(-half, width - half):
            if state.in_bounds(spawn_r + d, c): state.set_h(spawn_r + d, c, 1)
    for r in range(spawn_r, arc1_r + 1):
        for d in range(-half, width - half):
            if state.in_bounds(r, cols - 2 + d): state.set_h(r, cols - 2 + d, 1)
    # Corridor 2 via left.
    for c in range(2, spawn_c + 1):
        for d in range(-half, width - half):
            if state.in_bounds(spawn_r + d, c): state.set_h(spawn_r + d, c, 1)
    for r in range(spawn_r, arc2_r + 1):
        for d in range(-half, width - half):
            if state.in_bounds(r, 2 + d): state.set_h(r, 2 + d, 1)
    # Both corridors converge at end_r.
    for c in range(2, cols - 2):
        for d in range(-half, width - half):
            if state.in_bounds(arc2_r + d, c): state.set_h(arc2_r + d, c, 1)
    for r in range(arc1_r, end_r + 1):
        for d in range(-half, width - half):
            if state.in_bounds(r, end_c + d): state.set_h(r, end_c + d, 1)
    # Shortcut: midway between the two arcs, an east-west bridge.
    short_r = (arc1_r + arc2_r) // 2
    for c in range(2, cols - 2):
        for d in range(-half, width - half):
            if state.in_bounds(short_r + d, c): state.set_h(short_r + d, c, 1)


@op("hk_biomes")
def op_hk_biomes(state: MapState, p: dict, rng: random.Random):
    """Hollow Knight — distinct height-zones with thresholds. Three
    horizontal bands at different heights connected by single-cell
    transitions. Each band reads as its own biome."""
    h_a = int(p.get("h_a", 1))
    h_b = int(p.get("h_b", 2))
    h_c = int(p.get("h_c", 1))
    rows, cols = state.rows, state.cols
    third = rows // 3
    # Three horizontal bands.
    for r in range(0, third):
        for c in range(cols): state.set_h(r, c, h_a)
    for r in range(third, 2 * third):
        for c in range(cols): state.set_h(r, c, h_b)
    for r in range(2 * third, rows):
        for c in range(cols): state.set_h(r, c, h_c)
    # Threshold walls at the band boundaries with single openings.
    border_h = int(p.get("border", 4))
    for c in range(cols):
        state.set_h(third, c, border_h)
        state.set_h(2 * third, c, border_h)
    # Openings.
    state.set_h(third, cols // 4, h_a)
    state.set_h(third + 1, cols // 4, h_b)
    state.set_h(2 * third, 3 * cols // 4, h_b)
    state.set_h(2 * third + 1, 3 * cols // 4, h_c)


@op("island_shore")
def op_island_shore(state: MapState, p: dict, rng: random.Random):
    """Animal-Crossing-style island — radial gradient of heights, with a
    coastal void halo. Centre at h=1, eroded perimeter to void."""
    cr = state.rows // 2; cc = state.cols // 2
    radius = float(p.get("radius", min(state.rows, state.cols) / 2 - 1))
    erosion_amp = float(p.get("erosion", 1.5))
    for r in range(state.rows):
        for c in range(state.cols):
            d = math.hypot(r - cr, c - cc)
            # Per-cell erosion noise so the shore is irregular.
            noise = (rng.random() - 0.5) * erosion_amp
            effective = d + noise
            if effective < radius * 0.4:
                state.set_h(r, c, 2)            # interior plateau
            elif effective < radius * 0.8:
                state.set_h(r, c, 1)            # beach
            else:
                state.set_h(r, c, 0)            # ocean


@op("multi_floor")
def op_multi_floor(state: MapState, p: dict, rng: random.Random):
    """Two stacked floors expressed in the height channel: lower half =
    one floor at h=1, upper half = a separate room at h=3 (a mezzanine).
    Connected by a single-step ramp (h=2) at one location."""
    rows, cols = state.rows, state.cols
    mid_c = cols // 2
    # Lower floor (left).
    for r in range(1, rows - 1):
        for c in range(1, mid_c):
            state.set_h(r, c, 1)
    # Upper mezzanine (right) at h=3, surrounded by walls.
    for r in range(1, rows - 1):
        for c in range(mid_c, cols - 1):
            state.set_h(r, c, 3)
    # Step (h=2) at the midline so player can walk up: 1→2→3.
    step_r = rows // 2
    state.set_h(step_r, mid_c - 1, 1)
    state.set_h(step_r, mid_c, 2)
    state.set_h(step_r, mid_c + 1, 3)
    # Outer wall.
    for r in range(rows):
        state.set_h(r, 0, 4); state.set_h(r, cols - 1, 4)
    for c in range(cols):
        state.set_h(0, c, 4); state.set_h(rows - 1, c, 4)


# ── Lineages still missing ─────────────────────────────────────────────

@op("prairie_axis")
def op_prairie_axis(state: MapState, p: dict, rng: random.Random):
    """Frank Lloyd Wright Prairie — long horizontal axis with a hearth at
    centre and cantilevered side rooms. Strong horizontal emphasis."""
    rows, cols = state.rows, state.cols
    axis_r = rows // 2
    width = int(p.get("width", 3))
    half = width // 2
    hearth_r = axis_r; hearth_c = cols // 2
    # Long axis floor (3-wide).
    for c in range(1, cols - 1):
        for d in range(-half, width - half):
            state.set_h(axis_r + d, c, 1)
    # Hearth — central pillar h=4 surrounded by floor.
    for dr in (-1, 0, 1):
        for dc in (-1, 0, 1):
            r, c = hearth_r + dr, hearth_c + dc
            if state.in_bounds(r, c):
                state.set_h(r, c, 1)
    state.set_h(hearth_r, hearth_c, 4)
    # Cantilevered side rooms — 2 to the north, 2 to the south, off-centre.
    for offset_c, side in [(-cols // 4, -1), (cols // 4, 1)]:
        for sr in range(1, 4):
            for sc in range(-2, 3):
                r = axis_r + side * (sr + half)
                c = hearth_c + offset_c + sc
                if state.in_bounds(r, c):
                    state.set_h(r, c, 1)


@op("metroid_gates")
def op_metroid_gates(state: MapState, p: dict, rng: random.Random):
    """Metroidvania — multi-region map with tall pillars (gates) blocking
    direct paths. Player must find detours. Each gate is h=4 — too tall
    to climb without a `wp` ramp, forcing route-finding around it."""
    n_gates = int(p.get("n_gates", 4))
    rows, cols = state.rows, state.cols
    # Carve full floor first.
    for r in range(rows):
        for c in range(cols):
            state.set_h(r, c, 1)
    # Wall border.
    for r in range(rows):
        state.set_h(r, 0, 4); state.set_h(r, cols - 1, 4)
    for c in range(cols):
        state.set_h(0, c, 4); state.set_h(rows - 1, c, 4)
    # Place gates: vertical/horizontal walls of h=4 that don't fully cross.
    for i in range(n_gates):
        if rng.random() < 0.5:
            # Horizontal gate at random row, leaving an opening near one side.
            gate_r = rng.randint(2, rows - 3)
            opening_c = rng.choice([2, cols - 3])
            for c in range(2, cols - 2):
                if c == opening_c: continue
                state.set_h(gate_r, c, 4)
        else:
            gate_c = rng.randint(2, cols - 3)
            opening_r = rng.choice([2, rows - 3])
            for r in range(2, rows - 2):
                if r == opening_r: continue
                state.set_h(r, gate_c, 4)


@op("mirror_break")
def op_mirror_break(state: MapState, p: dict, rng: random.Random):
    """Antichamber-flavoured asymmetry — apply mirror but break N cells
    along the seam, producing a layout that LOOKS symmetric except for a
    small disquieting deviation. The eye notices what it can't quite
    name."""
    breaks = int(p.get("breaks", 4))
    axis = str(p.get("axis", "horizontal"))
    # Apply normal mirror first.
    rows, cols = state.rows, state.cols
    if axis == "horizontal":
        for r in range(rows):
            for c in range(cols // 2):
                v = state.structure[r][c]
                state.structure[r][cols - 1 - c] = v
        # Break N random cells on one half.
        for _ in range(breaks):
            br = rng.randint(0, rows - 1)
            bc = rng.randint(cols // 2 + 1, cols - 1)
            state.set_h(br, bc, rng.choice([0, 2, 3]))
    else:
        for r in range(rows // 2):
            for c in range(cols):
                v = state.structure[r][c]
                state.structure[rows - 1 - r][c] = v
        for _ in range(breaks):
            br = rng.randint(rows // 2 + 1, rows - 1)
            bc = rng.randint(0, cols - 1)
            state.set_h(br, bc, rng.choice([0, 2, 3]))


@op("soane_dense")
def op_soane_dense(state: MapState, p: dict, rng: random.Random):
    """John Soane Museum — collection-as-architecture. Plinths densely
    packed against every wall, leaving narrow walkways between them.
    Reads as a cluttered cabinet from above."""
    period = int(p.get("period", 2))
    plinth_h = int(p.get("plinth_h", 3))
    rows, cols = state.rows, state.cols
    # Carve floor first if empty.
    for r in range(rows):
        for c in range(cols):
            if state.get_h(r, c) == 0:
                state.set_h(r, c, 1)
    # Plinth grid leaving 1-cell gaps.
    for r in range(2, rows - 2, period):
        for c in range(2, cols - 2, period):
            state.set_h(r, c, plinth_h)


@op("borges_garden")
def op_borges_garden(state: MapState, p: dict, rng: random.Random):
    """Borges' Garden of Forking Paths — a tree with N levels of binary
    branching from a single trunk. Each path is 2-wide; each branch
    goes a fixed length before splitting. The player walks one path
    among many, all visible from above."""
    levels = int(p.get("levels", 4))
    branch_len = int(p.get("branch_len", 4))
    width = int(p.get("width", 2))
    half = width // 2
    rows, cols = state.rows, state.cols
    # Recursive: from (r, c) heading dir, draw a 2-wide branch of length
    # `branch_len`, then split into two children if level>0.
    def grow(r: int, c: int, heading: int, level: int):
        # Heading 0=N, 90=E, 180=S, 270=W (turtle convention).
        for step in range(branch_len):
            if heading == 0: r -= 1
            elif heading == 180: r += 1
            elif heading == 90: c += 1
            elif heading == 270: c -= 1
            for d in range(-half, width - half):
                if heading in (0, 180):
                    if state.in_bounds(r, c + d):
                        state.set_h(r, c + d, 1)
                else:
                    if state.in_bounds(r + d, c):
                        state.set_h(r + d, c, 1)
        if level <= 0: return
        # Split into two: turn left and right.
        grow(r, c, (heading + 60) % 360 // 90 * 90 - 90 if False else (heading + 270) % 360, level - 1)
        grow(r, c, (heading + 90) % 360, level - 1)
    start_r = rows - 2; start_c = cols // 2
    state.set_h(start_r, start_c, 1)
    grow(start_r, start_c, 0, levels)   # heading north, levels deep


# ── Algorithm-as-grammar (mining algorithms/ subsystems) ──────────────

@op("hilbert_curve")
def op_hilbert_curve(state: MapState, p: dict, rng: random.Random):
    """Hilbert space-filling curve — a single continuous path that visits
    every cell of a 2^n × 2^n grid exactly once. The MAP IS THE CURVE.
    From algorithms/lsystems/Hilbert3D.gd."""
    order = int(p.get("order", 4))
    side = 1 << order
    # Generate the Hilbert sequence using lindemayer-style rewriting:
    # A → -BF+AFA+FB-, B → +AF-BFB-FA+
    axiom = "A"
    rules = {"A": "-BF+AFA+FB-", "B": "+AF-BFB-FA+"}
    s = axiom
    for _ in range(order):
        s = "".join(rules.get(ch, ch) for ch in s)
    # Walk the turtle to determine cells visited.
    r, c = 0, 0
    heading = 0   # 0 east, 90 south, 180 west, 270 north
    cells: list[tuple[int, int]] = [(r, c)]
    for ch in s:
        if ch == "F":
            if heading == 0:   c += 1
            elif heading == 90: r += 1
            elif heading == 180: c -= 1
            elif heading == 270: r -= 1
            cells.append((r, c))
        elif ch == "+": heading = (heading + 90) % 360
        elif ch == "-": heading = (heading - 90) % 360
    # Centre the curve in the canvas.
    if not cells: return
    rs = [r for r, _ in cells]; cs = [c for _, c in cells]
    minr, maxr = min(rs), max(rs)
    minc, maxc = min(cs), max(cs)
    extent_r = maxr - minr + 1; extent_c = maxc - minc + 1
    off_r = (state.rows - extent_r) // 2 - minr
    off_c = (state.cols - extent_c) // 2 - minc
    for (r, c) in cells:
        rr, cc = r + off_r, c + off_c
        if state.in_bounds(rr, cc):
            state.set_h(rr, cc, 1)


@op("reaction_diffusion")
def op_reaction_diffusion(state: MapState, p: dict, rng: random.Random):
    """Turing-pattern reaction-diffusion: two morphogens (A activator,
    I inhibitor) diffuse and react. Produces stripes, spots, or
    labyrinths depending on rate ratios. From algorithms/proceduralgeneration/ReactionDiffusion."""
    iterations = int(p.get("iterations", 60))
    feed = float(p.get("feed", 0.055))    # F: feed rate
    kill = float(p.get("kill", 0.062))    # k: kill rate
    da = float(p.get("Da", 1.0))          # A diffusion
    di = float(p.get("Di", 0.5))          # I diffusion
    dt = float(p.get("dt", 1.0))
    threshold = float(p.get("threshold", 0.5))
    rows, cols = state.rows, state.cols
    A = [[1.0] * cols for _ in range(rows)]
    I = [[0.0] * cols for _ in range(rows)]
    # Seed with a small noisy patch in the centre.
    for dr in range(-2, 3):
        for dc in range(-2, 3):
            r, c = rows // 2 + dr, cols // 2 + dc
            if 0 <= r < rows and 0 <= c < cols:
                I[r][c] = 1.0
    for _ in range(iterations):
        Anext = [row[:] for row in A]
        Inext = [row[:] for row in I]
        for r in range(1, rows - 1):
            for c in range(1, cols - 1):
                lapA = (A[r - 1][c] + A[r + 1][c] + A[r][c - 1] + A[r][c + 1] - 4 * A[r][c])
                lapI = (I[r - 1][c] + I[r + 1][c] + I[r][c - 1] + I[r][c + 1] - 4 * I[r][c])
                a = A[r][c]; i = I[r][c]
                rate = a * i * i
                Anext[r][c] = a + (da * lapA - rate + feed * (1 - a)) * dt
                Inext[r][c] = i + (di * lapI + rate - (kill + feed) * i) * dt
        A, I = Anext, Inext
    # Threshold: cells where I > threshold become walls (h=4); others floor.
    for r in range(rows):
        for c in range(cols):
            if I[r][c] > threshold:
                state.set_h(r, c, 4)
            else:
                state.set_h(r, c, 1)


@op("gyroid_pattern")
def op_gyroid_pattern(state: MapState, p: dict, rng: random.Random):
    """Gyroid — triply-periodic minimal surface, expressed as a 2D slice.
    sin(x)cos(y) + sin(y)cos(z) + sin(z)cos(x) = 0; we slice at z=k.
    Inspired by algorithms/spacetopology/marchingcubes."""
    scale = float(p.get("scale", 0.45))
    z_slice = float(p.get("z", 1.0))
    threshold = float(p.get("threshold", 0.0))
    rows, cols = state.rows, state.cols
    for r in range(rows):
        for c in range(cols):
            x = (c - cols / 2) * scale
            y = (r - rows / 2) * scale
            z = z_slice
            v = (math.sin(x) * math.cos(y)
                 + math.sin(y) * math.cos(z)
                 + math.sin(z) * math.cos(x))
            state.set_h(r, c, 1 if v > threshold else 0)


@op("lorenz_trail")
def op_lorenz_trail(state: MapState, p: dict, rng: random.Random):
    """Lorenz attractor projected onto the grid. The butterfly trace —
    two lobes connected by a thin transition. From algorithms/chaos/strangeattractors."""
    sigma = float(p.get("sigma", 10.0))
    rho = float(p.get("rho", 28.0))
    beta = float(p.get("beta", 8 / 3))
    dt = float(p.get("dt", 0.01))
    iterations = int(p.get("iterations", 4000))
    scale = float(p.get("scale", 0.4))
    x, y, z = 1.0, 1.0, 1.0
    rows, cols = state.rows, state.cols
    cr, cc = rows // 2, cols // 2
    visited: set[tuple[int, int]] = set()
    for _ in range(iterations):
        dx = sigma * (y - x) * dt
        dy = (x * (rho - z) - y) * dt
        dz = (x * y - beta * z) * dt
        x += dx; y += dy; z += dz
        # Project (x, z) onto grid.
        gr = int(round(cr - z * scale + rho * scale * 0.5))
        gc = int(round(cc + x * scale))
        if state.in_bounds(gr, gc):
            visited.add((gr, gc))
    for (r, c) in visited:
        state.set_h(r, c, 1)


@op("physarum_trail")
def op_physarum_trail(state: MapState, p: dict, rng: random.Random):
    """Physarum slime-mold trails. Drop N "food" points; for each pair,
    walk a straight line carving floor — over many iterations the
    short-distance pairs accumulate the densest trails. From
    algorithms/swarmintelligence/physarum."""
    n_food = int(p.get("n_food", 8))
    n_trails = int(p.get("n_trails", 25))
    rows, cols = state.rows, state.cols
    food: list[tuple[int, int]] = []
    for _ in range(n_food):
        food.append((rng.randint(2, rows - 3), rng.randint(2, cols - 3)))
    for f in food:
        state.set_h(f[0], f[1], 2)   # plinth at each food source
    # Carve trails: pick a random pair, walk a Bresenham line between them.
    for _ in range(n_trails):
        a = rng.choice(food); b = rng.choice(food)
        if a == b: continue
        r0, c0 = a; r1, c1 = b
        dr = abs(r1 - r0); dc = abs(c1 - c0)
        sr = 1 if r0 < r1 else -1; sc = 1 if c0 < c1 else -1
        err = dc - dr
        r, c = r0, c0
        while True:
            if state.in_bounds(r, c) and state.get_h(r, c) == 0:
                state.set_h(r, c, 1)
            if r == r1 and c == c1: break
            e2 = 2 * err
            if e2 > -dr: err -= dr; c += sc
            if e2 < dc: err += dc; r += sr


@op("renaissance_floor")
def op_renaissance_floor(state: MapState, p: dict, rng: random.Random):
    """Renaissance painting floor pattern — radial pavement with a
    central rosette. From algorithms/computationalgeometry/renaissancepaintingfloorrattern."""
    n_petals = int(p.get("n_petals", 8))
    cr, cc = state.rows // 2, state.cols // 2
    rmax = min(state.rows, state.cols) // 2 - 1
    # Concentric rings.
    for r in range(state.rows):
        for c in range(state.cols):
            d = math.hypot(r - cr, c - cc)
            if d > rmax + 0.5: continue
            ring = int(d)
            state.set_h(r, c, 1 if ring % 2 == 0 else 2)
    # Radial spokes.
    for i in range(n_petals):
        ang = 2 * math.pi * i / n_petals
        for s in range(rmax + 1):
            pr = int(round(cr + math.cos(ang) * s))
            pc = int(round(cc + math.sin(ang) * s))
            if state.in_bounds(pr, pc):
                state.set_h(pr, pc, 3)
    # Centre rosette.
    state.set_h(cr, cc, 4)


@op("cantor_dust")
def op_cantor_dust(state: MapState, p: dict, rng: random.Random):
    """Cantor dust / Cantor set product — recursive 1/3 removal in 2D.
    From algorithms/fractals/cantorset."""
    depth = int(p.get("depth", 3))
    fill = int(p.get("fill", 1))
    rows, cols = state.rows, state.cols
    # Start with full floor.
    for r in range(rows):
        for c in range(cols):
            state.set_h(r, c, fill)
    # Recursively erase the centre third on each axis.
    def erase(r0: int, c0: int, h: int, w: int, d: int):
        if d == 0 or h < 3 or w < 3: return
        h_third = h // 3; w_third = w // 3
        # Erase the centre third.
        for r in range(r0 + h_third, r0 + 2 * h_third):
            for c in range(c0 + w_third, c0 + 2 * w_third):
                state.set_h(r, c, 0)
        # Recurse into 8 surrounding subblocks (skip centre).
        for dr in range(3):
            for dc in range(3):
                if dr == 1 and dc == 1: continue
                erase(r0 + dr * h_third, c0 + dc * w_third,
                      h_third, w_third, d - 1)
    erase(0, 0, rows, cols, depth)


# ── Utility-layer ops (use wp / tc to make traversable richness) ──────

@op("archipelago")
def op_archipelago(state: MapState, p: dict, rng: random.Random):
    """Multiple disconnected islands at varying heights, joined by tc
    transport-cube bridges across the void between them. The runtime
    renders each tc as a moving block that carries the player. Uses the
    UTILITY LAYER for traversal, structure heights for relief."""
    n_islands = int(p.get("n_islands", 4))
    island_radius = int(p.get("island_radius", 3))
    rows, cols = state.rows, state.cols
    centers: list[tuple[int, int, int]] = []
    for i in range(n_islands):
        cr = rng.randint(island_radius + 1, rows - island_radius - 2)
        cc = rng.randint(island_radius + 1, cols - island_radius - 2)
        h = rng.choice([1, 1, 2, 2, 3])
        centers.append((cr, cc, h))
        # Carve circular island.
        for r in range(rows):
            for c in range(cols):
                if math.hypot(r - cr, c - cc) <= island_radius - 0.5:
                    state.set_h(r, c, h)
    # Connect successive islands with tc bridges.
    for i in range(len(centers) - 1):
        a = centers[i]; b = centers[i + 1]
        # Walk a Bresenham line; mark void cells along the line as tc.
        r0, c0 = a[0], a[1]; r1, c1 = b[0], b[1]
        dr = abs(r1 - r0); dc = abs(c1 - c0)
        sr = 1 if r0 < r1 else -1; sc = 1 if c0 < c1 else -1
        err = dc - dr; r, c = r0, c0
        while True:
            if state.in_bounds(r, c) and state.get_h(r, c) == 0:
                state.set_h(r, c, 1)
                if not state.utilities[r][c].strip():
                    state.utilities[r][c] = "tc:1:auto:auto"
            if r == r1 and c == c1: break
            e2 = 2 * err
            if e2 > -dr: err -= dr; c += sc
            if e2 < dc: err += dc; r += sr


@op("ramped_terraces")
def op_ramped_terraces(state: MapState, p: dict, rng: random.Random):
    """Stepped terraces at heights 1→4 along the X axis, with `wp` ramp
    utilities on each step so the player can climb up the architecture."""
    rows, cols = state.rows, state.cols
    levels = int(p.get("levels", 4))
    level_w = max(2, cols // levels)
    for r in range(1, rows - 1):
        for c in range(1, cols - 1):
            level = min(levels, c // level_w)
            state.set_h(r, c, level + 1)
    # Place wp ramps on the boundary cells of each step, so the player
    # can climb from height N to height N+1.
    for level in range(1, levels):
        boundary_c = level * level_w
        for r in range(2, rows - 2):
            if state.in_bounds(r, boundary_c):
                state.utilities[r][boundary_c] = "wp:0"
    # Frame.
    for r in range(rows):
        state.set_h(r, 0, 4); state.set_h(r, cols - 1, 4)
    for c in range(cols):
        state.set_h(0, c, 4); state.set_h(rows - 1, c, 4)


@op("floating_platforms")
def op_floating_platforms(state: MapState, p: dict, rng: random.Random):
    """Several 2×2 platforms at varying heights floating in void, linked
    by tc transport cubes. Vertical labyrinth feel — each platform is
    its own tier."""
    n_platforms = int(p.get("n_platforms", 5))
    rows, cols = state.rows, state.cols
    platforms: list[tuple[int, int, int]] = []
    for _ in range(n_platforms):
        pr = rng.randint(2, rows - 4)
        pc = rng.randint(2, cols - 4)
        ph = rng.choice([1, 2, 3, 4])
        platforms.append((pr, pc, ph))
        for dr in range(2):
            for dc in range(2):
                state.set_h(pr + dr, pc + dc, ph)
    # Connect with tc bridges.
    for i in range(len(platforms) - 1):
        a, b = platforms[i], platforms[i + 1]
        r0, c0 = a[0], a[1]; r1, c1 = b[0], b[1]
        dr = abs(r1 - r0); dc = abs(c1 - c0)
        sr = 1 if r0 < r1 else -1; sc = 1 if c0 < c1 else -1
        err = dc - dr; r, c = r0, c0
        while True:
            if state.in_bounds(r, c) and state.get_h(r, c) == 0:
                state.set_h(r, c, 1)
                state.utilities[r][c] = "tc:1:auto:auto"
            if r == r1 and c == c1: break
            e2 = 2 * err
            if e2 > -dr: err -= dr; c += sc
            if e2 < dc: err += dc; r += sr


@op("zigzag_levels")
def op_zigzag_levels(state: MapState, p: dict, rng: random.Random):
    """Alternating high-low strips with wp ramps between them. The map
    reads as a wave in cross-section."""
    rows, cols = state.rows, state.cols
    strip_h = int(p.get("strip_h", 3))
    low_h = int(p.get("low", 1))
    high_h = int(p.get("high", 3))
    for r in range(rows):
        h = high_h if (r // strip_h) % 2 == 0 else low_h
        for c in range(cols):
            state.set_h(r, c, h)
    # Ramp bands between strips.
    for r in range(strip_h - 1, rows, strip_h):
        for c in range(2, cols - 2):
            if state.in_bounds(r, c):
                state.utilities[r][c] = "wp:0"


# ── Finish ops ────────────────────────────────────────────────────────

@op("spawn_at")
def op_spawn_at(state: MapState, p: dict, rng: random.Random):
    r = int(p.get("r", -1)); c = int(p.get("c", -1))
    if r < 0 or c < 0:
        # Pick the first walkable cell.
        for rr in range(state.rows):
            for cc in range(state.cols):
                if state.get_h(rr, cc) >= 1:
                    r, c = rr, cc; break
            if r >= 0: break
    if state.in_bounds(r, c):
        state.utilities[r][c] = "s"
        if state.get_h(r, c) == 0: state.set_h(r, c, 1)


@op("teleport_at")
def op_teleport_at(state: MapState, p: dict, rng: random.Random):
    r = int(p.get("r", -1)); c = int(p.get("c", -1))
    if r < 0 or c < 0:
        # Last walkable cell scanning bottom-up.
        for rr in range(state.rows - 1, -1, -1):
            for cc in range(state.cols - 1, -1, -1):
                if state.get_h(rr, cc) >= 1:
                    r, c = rr, cc; break
            if r >= 0: break
    if state.in_bounds(r, c):
        state.utilities[r][c] = "t"


# ── Noise / variance ─────────────────────────────────────────────────

@op("noise_perturb")
def op_noise_perturb(state: MapState, p: dict, rng: random.Random):
    """Inject small structural noise so two runs of the same strategy
    don't look identical. Random bumps (h+1) and dips (h-1) on existing
    floor cells, plus optional pillar pokes (h=2..3) at scattered spots.

    params:
        bumps:    int     — cells to raise by +1 (capped at h=3)
        dips:     int     — cells to drop by -1 (capped at h=1)
        pillars:  int     — random pillars (h=2..3) on existing floor
        avoid_edge: int   — how many border cells to keep flat
    """
    bumps = int(p.get("bumps", 0))
    dips = int(p.get("dips", 0))
    pillars = int(p.get("pillars", 0))
    avoid_edge = int(p.get("avoid_edge", 1))
    candidates = [
        (r, c) for r in range(state.rows) for c in range(state.cols)
        if state.structure[r][c] == 1
        and r >= avoid_edge and r < state.rows - avoid_edge
        and c >= avoid_edge and c < state.cols - avoid_edge
    ]
    rng.shuffle(candidates)
    i = 0
    for _ in range(min(bumps, len(candidates) - i)):
        r, c = candidates[i]; i += 1
        # only bump if not on the spawn-corner approach
        if r <= 2 and c <= 2: continue
        state.set_h(r, c, 2)
    for _ in range(min(dips, len(candidates) - i)):
        r, c = candidates[i]; i += 1
        # don't dip a cell if doing so leaves no walkable neighbors
        # (cheap heuristic: skip if 3 neighbors are also low)
        low_nbrs = sum(1 for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1))
                       if state.get_h(r + dr, c + dc) < 1)
        if low_nbrs >= 3: continue
        state.set_h(r, c, 0)
    for _ in range(min(pillars, len(candidates) - i)):
        r, c = candidates[i]; i += 1
        if r <= 2 and c <= 2: continue
        state.set_h(r, c, rng.choice([2, 2, 3]))


@op("widen_paths")
def op_widen_paths(state: MapState, p: dict, rng: random.Random):
    """Ensure walkable paths are at least 2 cells wide so the player
    doesn't fall off single-cube bridges.

    Detects two kinds of bottleneck:
        vertical corridor   — walkable cell with walkable up+down,
                              void left+right (a north-south rail)
        horizontal corridor — walkable cell with walkable left+right,
                              void up+down                  (an east-west rail)

    For each bottleneck, dilates one perpendicular neighbour to h=1.
    A `ratio` parameter (0–1) controls the fraction of bottlenecks
    fixed; default 0.9 leaves ~10% intentional 1-wide passes for
    threat/character (a single-file rope bridge is fine, an entire
    map of them is not).

    params:
        ratio:      float 0–1 (default 0.9)
        avoid_edge: int   (default 1) — how many border cells to skip
    """
    ratio = float(p.get("ratio", 0.9))
    avoid_edge = int(p.get("avoid_edge", 1))
    bottlenecks: list[tuple[int, int, bool]] = []
    for r in range(avoid_edge, state.rows - avoid_edge):
        for c in range(avoid_edge, state.cols - avoid_edge):
            if state.structure[r][c] < 1:
                continue
            up = state.get_h(r - 1, c) >= 1
            dn = state.get_h(r + 1, c) >= 1
            lt = state.get_h(r, c - 1) >= 1
            rt = state.get_h(r, c + 1) >= 1
            v_corridor = up and dn and not lt and not rt
            h_corridor = lt and rt and not up and not dn
            if v_corridor or h_corridor:
                bottlenecks.append((r, c, v_corridor))
    rng.shuffle(bottlenecks)
    n_to_fix = int(len(bottlenecks) * ratio)
    for r, c, is_v in bottlenecks[:n_to_fix]:
        if is_v:
            # Try left then right (or random order)
            offsets = [-1, 1]
            rng.shuffle(offsets)
            for dc in offsets:
                if state.in_bounds(r, c + dc) and state.structure[r][c + dc] == 0:
                    state.set_h(r, c + dc, 1)
                    break
        else:
            offsets = [-1, 1]
            rng.shuffle(offsets)
            for dr in offsets:
                if state.in_bounds(r + dr, c) and state.structure[r + dr][c] == 0:
                    state.set_h(r + dr, c, 1)
                    break


# ── Runner ────────────────────────────────────────────────────────────

def run_config(cfg: dict, seed: int = 0) -> MapState:
    rows = int(cfg.get("rows", 16))
    cols = int(cfg.get("cols", 16))
    state = MapState(rows=rows, cols=cols)
    rng = random.Random(seed ^ hash(cfg.get("id", "")) & 0xFFFFFFFF)
    for step in cfg.get("ops", []) or []:
        name = step.get("op")
        params = step.get("params", {}) or {}
        fn = _OPS.get(name)
        if fn is None:
            print(f"  ! unknown op: {name}")
            continue
        fn(state, params, rng)
    # Project convention: spawn at (1, 1), teleporter on a reachable void
    # cell. This guarantees every generated map has a known starting point
    # and a reachable exit, no matter what the operations did.
    _apply_finish(state)
    return state


def _apply_finish(state: MapState):
    """Project convention: every map has its spawn at (1, 1), and a
    reachable teleporter on a void (h=0) cell. We:
      1. Carve (1,1) walkable + place spawn there (overrides ops if needed)
      2. Find the largest existing walkable component and carve a 2-wide
         L-corridor from (1,1) to the nearest cell of that component
      3. Place teleporter on a reachable void cell, farthest from spawn"""
    rows = state.rows; cols = state.cols
    sr, sc = 1, 1
    if rows < 3 or cols < 3:
        return
    # Step 1: spawn at (1,1) plus a small walkable pad.
    for (rr, cc) in [(sr, sc), (sr, sc + 1), (sr + 1, sc), (sr + 1, sc + 1)]:
        if 0 <= rr < rows and 0 <= cc < cols:
            if state.get_h(rr, cc) == 0:
                state.set_h(rr, cc, 1)
    # Clear any prior spawn marker — (1,1) is canonical.
    for r in range(rows):
        for c in range(cols):
            if state.utilities[r][c] in ("s", "sp"):
                state.utilities[r][c] = " "
    state.utilities[sr][sc] = "s"

    # Step 2: ensure (1,1) is connected to the LARGEST walkable component.
    from collections import deque
    walkable = {(r, c) for r in range(rows) for c in range(cols)
                if state.get_h(r, c) >= 1}
    # Compute every connected component.
    components: list[set[tuple[int, int]]] = []
    visited: set[tuple[int, int]] = set()
    for cell in walkable:
        if cell in visited: continue
        comp: set[tuple[int, int]] = {cell}
        q = deque([cell])
        while q:
            r, c = q.popleft()
            for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                n = (r + dr, c + dc)
                if n in walkable and n not in comp:
                    comp.add(n); q.append(n)
        components.append(comp)
        visited |= comp
    spawn_comp = next((c for c in components if (sr, sc) in c), set())
    other_components = [c for c in components if c is not spawn_comp]
    if other_components:
        # Connect to the LARGEST other component (not just the closest).
        largest = max(other_components, key=len)
        target = min(largest, key=lambda p: abs(p[0] - sr) + abs(p[1] - sc))
        tr, tc = target
        # Carve corridor cells to h=1 IF currently void; preserve any
        # existing structure (plinths, walls). A `wp` ramp utility on
        # tall cells along the path lets the player climb them.
        def carve(rr: int, cc: int):
            if not (0 <= rr < rows and 0 <= cc < cols): return
            if state.get_h(rr, cc) == 0:
                state.set_h(rr, cc, 1)   # carve void to floor
            elif state.get_h(rr, cc) >= 2 and not state.utilities[rr][cc].strip():
                state.utilities[rr][cc] = "wp:0"   # climbable ramp
        for c in range(min(sc, tc), max(sc, tc) + 1):
            for d in (0, 1):
                carve(sr + d, c)
        for r in range(min(sr, tr), max(sr, tr) + 1):
            for d in (0, 1):
                carve(r, tc + d)

    # Find spawn position (might have been set by an op or just above).
    spawn_pos: tuple[int, int] | None = None
    for r in range(rows):
        for c in range(cols):
            if state.utilities[r][c] in ("s", "sp"):
                spawn_pos = (r, c); break
        if spawn_pos: break
    if spawn_pos is None: return

    # BFS to find every walkable cell reachable from spawn.
    from collections import deque
    sr, sc = spawn_pos
    if state.get_h(sr, sc) == 0:
        state.set_h(sr, sc, 1)
    seen = {spawn_pos}
    q = deque([spawn_pos])
    while q:
        r, c = q.popleft()
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nr, nc = r + dr, c + dc
            if (0 <= nr < rows and 0 <= nc < cols and (nr, nc) not in seen
                    and state.get_h(nr, nc) >= 1):
                seen.add((nr, nc))
                q.append((nr, nc))

    # Already-placed teleporter wins.
    has_tele = any(any(c == "t" for c in row) for row in state.utilities)
    if has_tele:
        _ensure_walkable_path(state)
        return

    # Look for a void cell adjacent to a reachable walkable cell — drop
    # the teleporter there. Prefer the cell farthest from spawn (so the
    # teleporter sits at the END of the map, not next to the entrance).
    candidates: list[tuple[int, tuple[int, int]]] = []
    for r in range(rows):
        for c in range(cols):
            if state.get_h(r, c) != 0: continue
            for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                nr, nc = r + dr, c + dc
                if (nr, nc) in seen:
                    dist = abs(r - sr) + abs(c - sc)
                    candidates.append((dist, (r, c)))
                    break
    if candidates:
        candidates.sort(reverse=True)
        tr, tc = candidates[0][1]
        state.utilities[tr][tc] = "t"
        # The adjacent walkable cell must be h=1 (step diff to void=1 allowed).
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nr, nc = tr + dr, tc + dc
            if 0 <= nr < rows and 0 <= nc < cols and (nr, nc) in seen:
                if state.get_h(nr, nc) > 1:
                    state.set_h(nr, nc, 1)
        _ensure_walkable_path(state)
        return

    # No void cell exists adjacent to walkable. Carve one at the cell
    # farthest from spawn, then mark it as void+teleporter.
    if seen:
        far = max(seen, key=lambda p: abs(p[0] - sr) + abs(p[1] - sc))
        # Replace `far` itself with void + teleporter.
        fr, fc = far
        state.set_h(fr, fc, 0)
        state.utilities[fr][fc] = "t"
    _ensure_walkable_path(state)


def _ensure_walkable_path(state: MapState):
    """After spawn + teleporter are placed, run a strict pathfinder using
    the runtime's step rules (|h_diff| <= 1, h >= 1 walkable). If the
    teleporter is NOT reachable from spawn, fix the path:

      1. Find a permissive path (any non-extreme cell) toward the goal
      2. For each cell on the path that would block the player due to a
         tall step, insert a ramp utility (`r`) so the runtime renders a
         walkable wedge connecting the heights
      3. Where the path crosses a void gap of 1 cell, drop a `tc`
         transport cube; gaps of 2+ become floor (carved)

    The teleporter itself stays at h=0 — its adjacent cell is always
    made walkable so the player can step onto it."""
    from collections import deque
    rows = state.rows; cols = state.cols
    spawn = None; tele = None
    for r in range(rows):
        for c in range(cols):
            u = state.utilities[r][c]
            if u in ("s", "sp"): spawn = (r, c)
            elif u == "t": tele = (r, c)
    if spawn is None or tele is None: return

    def reachable_strict(start: tuple[int, int]) -> set[tuple[int, int]]:
        """Cells reachable under the project pathfinder's rules:
          - Same height: allowed
          - Drop 1 level: allowed
          - Drop 2+: needs `wp` (we don't place those)
          - Climb UP: ALWAYS needs `wp` ramp
        So the only safe walking transitions for ungated maps are
        same-height or single-step-down."""
        if state.get_h(*start) < 1: return set()
        seen = {start}
        q = deque([start])
        while q:
            r, c = q.popleft()
            ch = state.get_h(r, c)
            for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                nr, nc = r + dr, c + dc
                if not (0 <= nr < rows and 0 <= nc < cols): continue
                nh = state.get_h(nr, nc)
                if nh < 1: continue
                if (nr, nc) in seen: continue
                # Project rules: same height OR step down by 1.
                if nh == ch or ch - nh == 1:
                    seen.add((nr, nc)); q.append((nr, nc))
        return seen

    reach = reachable_strict(spawn)
    # Teleporter is on a void cell. Player is "at" the teleporter when
    # they step onto an adjacent walkable cell.
    tele_neighbours = []
    for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        nr, nc = tele[0] + dr, tele[1] + dc
        if 0 <= nr < rows and 0 <= nc < cols:
            tele_neighbours.append((nr, nc))
    if any(n in reach for n in tele_neighbours):
        return   # already reachable, nothing to fix

    # Permissive BFS — treat every cell as candidate. Find the shortest
    # path from spawn-cell to ANY adjacent-of-teleporter.
    came_from: dict[tuple[int, int], tuple[int, int] | None] = {spawn: None}
    q = deque([spawn])
    goal = None
    goal_set = set(tele_neighbours)
    while q:
        cur = q.popleft()
        if cur in goal_set: goal = cur; break
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            n = (cur[0] + dr, cur[1] + dc)
            if not (0 <= n[0] < rows and 0 <= n[1] < cols): continue
            if n in came_from: continue
            came_from[n] = cur
            q.append(n)
    if goal is None: return    # truly disconnected; no fix possible
    # Reconstruct path.
    path: list[tuple[int, int]] = [goal]
    while came_from[path[-1]] is not None:
        path.append(came_from[path[-1]])  # type: ignore
    path.reverse()

    # Walk the path. Use the UTILITY LAYER to make height transitions
    # walkable instead of flattening the structure:
    #   - `wp` (walkable prism / ramp) — placed on cells where the player
    #     climbs UP (project rules forbid climb-up without wp).
    #   - `tc` (transport cube) — placed on cells where the player crosses
    #     a void gap (cell at h=0 between walkable cells).
    # Heights stay intact; the architecture is preserved.
    prev_cell: tuple[int, int] | None = None
    for (r, c) in path:
        if (r, c) == tele:
            continue
        # If the cell is currently void, carve to floor (h=1); structure
        # data needs SOMETHING walkable, and a tc utility doesn't carve
        # for us — but we add the tc marker so the player traverses it.
        cur_h = state.get_h(r, c)
        if cur_h == 0:
            state.set_h(r, c, 1)
            # Mark tc on this cell — the runtime renders a transport cube
            # so the player can cross the originally-void gap.
            if not state.utilities[r][c].strip():
                state.utilities[r][c] = "tc:1:auto:auto"
        if prev_cell is not None:
            ph = state.get_h(*prev_cell)
            ch = state.get_h(r, c)
            if ch > ph + 1:
                # Player would need to climb >1 cell up — place a wp ramp
                # on the higher cell so the runtime renders a walkable
                # prism connecting the two heights.
                if not state.utilities[r][c].strip():
                    state.utilities[r][c] = "wp:0"
            elif ch == ph + 1 and cur_h >= 2:
                # Single-step climb up to a plinth — wp is also required
                # under project rules ("climbing up always requires wp").
                if not state.utilities[r][c].strip():
                    state.utilities[r][c] = "wp:0"
        prev_cell = (r, c)

    # Verify by running the strict reach again. If the teleporter is now
    # reachable (via an adjacent walkable cell), we're done.
    reach2 = reachable_strict(spawn)
    if any(n in reach2 for n in tele_neighbours):
        return
    # Fallback: brute-force flatten the path to floor (h=1) — guarantees
    # walkability at the cost of erasing geometry along the path. We
    # prefer this over leaving the map unwalkable.
    for (r, c) in path:
        if (r, c) != tele:
            state.set_h(r, c, 1)


def list_ops() -> list[str]:
    return sorted(_OPS.keys())
