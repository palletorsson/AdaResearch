#!/usr/bin/env python3
"""gen_rd.py — the REACTION-DIFFUSION PLATE strategy (Gray-Scott labyrinth).

Palle (the map strategy family): "the map is a chemistry." A Gray-Scott
reaction-diffusion pattern becomes the FLOOR. Two chemicals U and V diffuse and
react on the canvas; V is seeded at every room site (a small square) plus a few
free specks, and the feed/kill rates are set per REGISTER band (three horizontal
thirds): arrival = spot regime (chambers), work = stripe/labyrinth regime
(corridors), depth = sparse regime. Threshold the settled V and the pattern IS
the walkable plate — the softbody/morphogenesis chapters' own image at map scale.

  beats     -> rooms      one close, hero-sized room per beat (inner = fp + 4);
                          voltage pieces become inner-6 chapels after their
                          spread targets
  scatter   -> apart      max-min-distance on a ~64 canvas (>= 12 apart)
  Gray-Scott-> the floor  V seeded at each room + specks; F/k per register band;
                          steady-ish V >= VTHRESH is floor
  rooms     -> stamped    the room rects are stamped floor OVER the chemistry
                          (perfect close rooms), so heroes always stand solid
  repair    -> A* ants    any beat-order pair the pattern failed to join gets ONE
                          A*-over-noise 3-wide corridor (the pattern's own
                          connectivity is the interesting stat)
  islands   -> voided     floor puddles not reachable from the room network are
                          removed (no orphan chemistry)
  walls     -> after      ONE boundary pass: a wall faces every void
  finish    -> curation   dimensions/settings/palettes/spawn/exit/runs/props

A STRATEGY file (tools/gen_*.py): it only invents the floor idea and calls
map_principal.finish for every shared layer. The wild strategy, the standard
meeting point.

DETERMINISM: one random.Random(seed), drawn in a FIXED order (room scatter ->
specks -> noise field). The Gray-Scott integration is pure float arithmetic with
no wall-clock and no rng, so the settled field is a pure function of the seeded
layout. The repair A* is a consistent-heuristic Dijkstra/A* with a monotone
tie-break counter. Same seed + same environment -> byte-identical map.

PERFORMANCE: if numpy is importable the laplacian is vectorized (canvas 64,
2500 steps, a few seconds). Without numpy it falls back to a pure-python
double-buffered integrator on a smaller 48 canvas / 1200 steps with a
normalized 5-point laplacian (the numpy path uses the isotropic 9-point) — the
regime is the same, the pattern a touch coarser. Budget < 30s per map either way.

Usage:
  python tools/gen_rd.py --seq=randomness [--seed=7] [--name=MissionRD_Randomness]
  python tools/gen_rd.py --seq=lsystems
  python tools/gen_rd.py --seq=randomness --set=STEPS=3000 --set=VTHRESH=0.3
"""
import heapq
import math
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

import map_principal as mp        # THE finisher — must call mp.finish
import mission_graph as mg        # load_mission/resolve_cast/_integration/staff/bench
import staging_beds as sb         # select_bed (the marriage-1 body)

try:                              # numpy = the fast vectorized laplacian
    import numpy as _np
    HAVE_NUMPY = True
except ImportError:               # pure-python fallback (smaller/shorter)
    _np = None
    HAVE_NUMPY = False

SEA = mg.SEA                      # "2" — the walkable floor height
CANVAS = 64 if HAVE_NUMPY else 48         # working canvas; cropped honest before finish
STEPS = 2500 if HAVE_NUMPY else 1200      # Gray-Scott iterations (knob)
BUDGET_FP = 8.0                  # resolve_cast footprint budget (the room is close)
BUDGET_H = 3.4                   # resolve_cast height budget
MIN_INNER = 7                    # smallest inner floor a beat room may have
CAP_INNER = 14                   # largest inner floor a beat room may have
VOLT_INNER = 6                   # voltage chapels are inner-6 side rooms

# Gray-Scott integration constants
DU = 0.16                        # U diffusion rate
DV = 0.08                        # V diffusion rate (ratio DU/DV = 2, the canon)
DT = 1.0                         # timestep
VTHRESH = 0.25                   # V >= VTHRESH -> floor (knob)
SEED_HALF = 2                    # room V-seed square half-extent (5x5)
SPECK_HALF = 1                   # free-speck V-seed square half-extent (3x3)
N_SPECKS = 8                     # a few seeded specks in the void (knob)

# feed (F) / kill (k) per REGISTER band — three horizontal canvas thirds
F_ARRIVAL, K_ARRIVAL = 0.0367, 0.0649    # spots (chambers)
F_WORK,    K_WORK     = 0.0545, 0.0620    # stripes / labyrinth (corridors)
F_DEPTH,   K_DEPTH    = 0.0300, 0.0620    # sparse (depth)

# repair A* wobble field (only touched when the pattern fails to connect a pair)
NOISE_LO, NOISE_HI = 1.0, 1.5    # void cost = NOISE_LO + NOISE_HI * noise(cell)
REUSE = 0.35                     # existing-floor cost (the corridor hugs the pattern)


# ── the close room (sized to its hero) ──────────────────────────────────────

def _cast_cells(name: str) -> int:
    """max grid_cells of a cast (default 2 when unmeasured)."""
    s = mg._sizes().get(name, {}) or {}
    gc = s.get("grid_cells")
    if not gc:
        return 2
    return max(1, int(max(int(gc[0]), int(gc[1]))))


def _beat_inner(cells: int) -> int:
    """inner floor size — the hero's footprint plus 4 cells of close walk,
    clamped to [MIN_INNER, CAP_INNER]."""
    return max(MIN_INNER, min(CAP_INNER, cells + 4))


# ── step 1b: scatter the rooms (max-min-distance greedy, gen_antrooms style) ──

def _overlaps(rect, placed, pad=1):
    x0, y0, x1, y1 = rect
    for (px0, py0, px1, py1) in placed:
        if not (x1 + pad < px0 or px1 + pad < x0
                or y1 + pad < py0 or py1 + pad < y0):
            return True
    return False


def _place_rooms(sizes, rng):
    """place each room at the candidate (seeded-shuffled every-3rd grid) that
    maximises min-distance to the placed centres, >= 12 apart (relax 10/8/0)."""
    cands = [(ax, ay) for ay in range(1, CANVAS, 3) for ax in range(1, CANVAS, 3)]
    rng.shuffle(cands)
    placed, centers, rooms = [], [], []
    for rs in sizes:
        best = None
        for thresh in (12.0, 10.0, 8.0, 0.0):
            pick, pick_d, pick_c = None, -1.0, None
            for (ax, ay) in cands:
                x1, y1 = ax + rs - 1, ay + rs - 1
                if ax < 1 or ay < 1 or x1 > CANVAS - 2 or y1 > CANVAS - 2:
                    continue
                if _overlaps((ax, ay, x1, y1), placed, pad=1):
                    continue
                cen = (ay + rs // 2, ax + rs // 2)
                d = (min(math.hypot(cen[0] - pc[0], cen[1] - pc[1])
                         for pc in centers) if centers else float("inf"))
                if d >= thresh and d > pick_d:
                    pick, pick_d, pick_c = (ax, ay, x1, y1), d, cen
            if pick:
                best = (pick, pick_c)
                break
        if best is None:
            raise RuntimeError("gen_rd: could not fit a room on the canvas")
        (x0, y0, x1, y1), cen = best
        placed.append((x0, y0, x1, y1))
        centers.append(cen)
        rooms.append((x0, y0, rs))
    return rooms, centers


# ── step 2: Gray-Scott reaction-diffusion (the chemistry that is the floor) ───

def _seed_cells(centers, specks):
    """the cells where V is seeded: a SEED_HALF square at each room centre and a
    SPECK_HALF square at each free speck."""
    cells = []
    for pts, half in ((centers, SEED_HALF), (specks, SPECK_HALF)):
        for (r, c) in pts:
            for dr in range(-half, half + 1):
                for dc in range(-half, half + 1):
                    rr, cc = r + dr, c + dc
                    if 0 <= rr < CANVAS and 0 <= cc < CANVAS:
                        cells.append((rr, cc))
    return cells


def _band_fk():
    """(F_row, k_row) lists — feed/kill per canvas row (three register thirds)."""
    t1, t2 = CANVAS // 3, 2 * CANVAS // 3
    F_row, k_row = [], []
    for r in range(CANVAS):
        if r < t1:
            F_row.append(F_ARRIVAL); k_row.append(K_ARRIVAL)
        elif r < t2:
            F_row.append(F_WORK); k_row.append(K_WORK)
        else:
            F_row.append(F_DEPTH); k_row.append(K_DEPTH)
    return F_row, k_row


def _grayscott_np(seed_cells, F_row, k_row):
    """vectorized Gray-Scott. U=1/V=0 background; seeds lower U, raise V; the
    isotropic 9-point laplacian (roll-wrapped) integrated STEPS times."""
    N = CANVAS
    U = _np.ones((N, N), dtype=_np.float64)
    V = _np.zeros((N, N), dtype=_np.float64)
    for (r, c) in seed_cells:
        U[r, c] = 0.5
        V[r, c] = 0.25
    F = _np.array(F_row, dtype=_np.float64)[:, None] * _np.ones((1, N))
    k = _np.array(k_row, dtype=_np.float64)[:, None] * _np.ones((1, N))
    fk = F + k

    def lap(Z):
        return (0.2 * (_np.roll(Z, 1, 0) + _np.roll(Z, -1, 0)
                       + _np.roll(Z, 1, 1) + _np.roll(Z, -1, 1))
                + 0.05 * (_np.roll(_np.roll(Z, 1, 0), 1, 1)
                          + _np.roll(_np.roll(Z, 1, 0), -1, 1)
                          + _np.roll(_np.roll(Z, -1, 0), 1, 1)
                          + _np.roll(_np.roll(Z, -1, 0), -1, 1))
                - Z)

    for _ in range(STEPS):
        uvv = U * V * V
        U += DT * (DU * lap(U) - uvv + F * (1.0 - U))
        V += DT * (DV * lap(V) + uvv - fk * V)
    return {(int(r), int(c)) for r, c in _np.argwhere(V >= VTHRESH)}


def _grayscott_py(seed_cells, F_row, k_row):
    """pure-python fallback: double-buffered, normalized 5-point laplacian
    (wrap boundaries). Same regime as the numpy path, a touch coarser."""
    N = CANVAS
    U = [1.0] * (N * N)
    V = [0.0] * (N * N)
    for (r, c) in seed_cells:
        U[r * N + c] = 0.5
        V[r * N + c] = 0.25
    for _ in range(STEPS):
        U2 = U[:]
        V2 = V[:]
        for r in range(N):
            b = r * N
            up = ((r - 1) % N) * N
            dn = ((r + 1) % N) * N
            F = F_row[r]
            fk = F_row[r] + k_row[r]
            for c in range(N):
                i = b + c
                le = b + ((c - 1) % N)
                ri = b + ((c + 1) % N)
                u = U[i]
                v = V[i]
                lu = (U[up + c] + U[dn + c] + U[le] + U[ri]) * 0.25 - u
                lv = (V[up + c] + V[dn + c] + V[le] + V[ri]) * 0.25 - v
                uvv = u * v * v
                U2[i] = u + DT * (DU * lu - uvv + F * (1.0 - u))
                V2[i] = v + DT * (DV * lv + uvv - fk * v)
        U, V = U2, V2
    return {(i // N, i % N) for i in range(N * N) if V[i] >= VTHRESH}


def _run_rd(centers, specks):
    """settle the chemistry, return the set of floor cells (V >= VTHRESH)."""
    seeds = _seed_cells(centers, specks)
    F_row, k_row = _band_fk()
    if HAVE_NUMPY:
        return _grayscott_np(seeds, F_row, k_row)
    return _grayscott_py(seeds, F_row, k_row)


# ── step 3b: connectivity — flood-fill test + A*-over-noise repair carve ──────

def _connected(floor, a, b):
    """flood-fill from a over the floor set; True if b is reached."""
    if a not in floor or b not in floor:
        return False
    seen = {a}
    stack = [a]
    while stack:
        r, c = stack.pop()
        if (r, c) == b:
            return True
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nb = (r + dr, c + dc)
            if nb in floor and nb not in seen:
                seen.add(nb)
                stack.append(nb)
    return b in seen


def _astar(start, target, noise, floor):
    """least-cost 4-neighbour path start->target. An existing-floor cell costs
    REUSE (the corridor hugs the chemistry it can); void costs NOISE_LO +
    NOISE_HI*noise. Heuristic REUSE*manhattan is consistent (min step == REUSE),
    so the pop-once A* is optimal AND a pure function of the seeded noise."""
    tr, tc = target

    def enter_cost(cell):
        if cell in floor:
            return REUSE
        return NOISE_LO + NOISE_HI * noise[cell[0]][cell[1]]

    openh = [(REUSE * (abs(start[0] - tr) + abs(start[1] - tc)), 0, start)]
    g = {start: 0.0}
    parent = {}
    counter = 1
    visited = set()
    while openh:
        _, _, cur = heapq.heappop(openh)
        if cur in visited:
            continue
        visited.add(cur)
        if cur == target:
            break
        r, c = cur
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nb = (r + dr, c + dc)
            if not (0 <= nb[0] < CANVAS and 0 <= nb[1] < CANVAS) or nb in visited:
                continue
            ng = g[cur] + enter_cost(nb)
            if nb not in g or ng < g[nb]:
                g[nb] = ng
                parent[nb] = cur
                h = REUSE * (abs(nb[0] - tr) + abs(nb[1] - tc))
                heapq.heappush(openh, (ng + h, counter, nb))
                counter += 1
    path = [target]
    cur = target
    while cur in parent:
        cur = parent[cur]
        path.append(cur)
    path.reverse()
    return path


def _carve(path, floor):
    """lay the path 3-wide into the floor set (spine + one cell each side)."""
    for k, cell in enumerate(path):
        if k + 1 < len(path):
            dr, dc = path[k + 1][0] - cell[0], path[k + 1][1] - cell[1]
        elif k > 0:
            dr, dc = cell[0] - path[k - 1][0], cell[1] - path[k - 1][1]
        else:
            dr, dc = 0, 1
        perps = [(0, -1), (0, 1)] if dr != 0 else [(-1, 0), (1, 0)]
        for (pr, pc) in [(0, 0)] + perps:
            rr, cc = cell[0] + pr, cell[1] + pc
            if 0 <= rr < CANVAS and 0 <= cc < CANVAS:
                floor.add((rr, cc))


# ── step 4: remove orphan islands (flood from the room network) ──────────────

def _reachable_from(floor, seeds):
    """flood-fill from every seed cell; return the reached floor subset."""
    seen = set(s for s in seeds if s in floor)
    stack = list(seen)
    while stack:
        r, c = stack.pop()
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nb = (r + dr, c + dc)
            if nb in floor and nb not in seen:
                seen.add(nb)
                stack.append(nb)
    return seen


# ── the build ────────────────────────────────────────────────────────────────

def build(seq, name, seed):
    beats, volt = mg.load_mission(seq)
    if not beats:
        print(f"gen_rd: no beats in baseline for {seq}")
        return 1
    n_beats = len(beats)

    # 1. the mission: beats, each voltage chapel inserted after its spread target
    entries = [{"kind": "beat", "i": i, "role": b["role"], "cast": b["cast"],
                "alts": b.get("alts", [])} for i, b in enumerate(beats)]
    for k, piece in enumerate(volt):
        t = round(k * (n_beats - 1) / max(1, len(volt) - 1)) if len(volt) > 1 else n_beats // 2
        for j, e in enumerate(entries):
            if e["kind"] == "beat" and e["i"] == t:
                entries.insert(j + 1, {"kind": "chapel", "i": k,
                                       "role": "voltage: " + piece,
                                       "cast": piece, "alts": []})
                break

    # 1b. resolve each cast, size its room (beats fp+4; chapels inner 6)
    casts, swaps, inners = [], [], []
    for e in entries:
        chosen, swapped = mg.resolve_cast(e["cast"], e["alts"], BUDGET_FP, BUDGET_H)
        casts.append(chosen)
        if swapped:
            swaps.append(f"{swapped}->{chosen}")
        inners.append(VOLT_INNER if e["kind"] == "chapel"
                      else _beat_inner(_cast_cells(chosen)))
    sides = [inner + 2 for inner in inners]      # room rect side = inner + 2
    n = len(entries)

    rng = random.Random(seed)              # the ONLY randomness — fixed draw order

    # 2a. scatter the rooms, then draw the specks + the repair noise (fixed order)
    rooms, centers = _place_rooms(sides, rng)
    specks = [(rng.randrange(2, CANVAS - 2), rng.randrange(2, CANVAS - 2))
              for _ in range(N_SPECKS)]
    noise = [[rng.random() for _ in range(CANVAS)] for _ in range(CANVAS)]

    # 2b. the chemistry: settle Gray-Scott, threshold V -> the pattern floor
    floor = _run_rd(centers, specks)

    # 3. stamp the room rects as floor OVER the chemistry (perfect close rooms)
    for (x0, y0, rs) in rooms:
        for r in range(y0, y0 + rs):
            for c in range(x0, x0 + rs):
                floor.add((r, c))

    # 3b. connectivity repair — carve one 3-wide A* corridor per beat-order pair
    # the pattern failed to join (the pattern's own connectivity is the stat)
    repairs = 0
    for i in range(n - 1):
        a, b = centers[i], centers[i + 1]
        if not _connected(floor, a, b):
            _carve(_astar(a, b, noise, floor), floor)
            repairs += 1

    # 4. remove orphan islands — void any floor not reachable from the room network
    room_cells = set()
    for (x0, y0, rs) in rooms:
        for r in range(y0, y0 + rs):
            for c in range(x0, x0 + rs):
                room_cells.add((r, c))
    floor = _reachable_from(floor, room_cells)
    floor_cells = len(floor)

    # 5. crop to used cells + 1 margin (dimensions honest)
    rows_ = [p[0] for p in floor]
    cols_ = [p[1] for p in floor]
    off_r, off_c = min(rows_) - 1, min(cols_) - 1
    H = (max(rows_) - min(rows_)) + 3
    W = (max(cols_) - min(cols_)) + 3
    layers = mp.blank_layers(W, H)
    st = layers["structure"]
    for (r, c) in floor:
        st[r - off_r][c - off_c] = SEA
    rooms_t = [(x0 - off_c, y0 - off_r, rs) for (x0, y0, rs) in rooms]
    centers_t = [(r - off_r, c - off_c) for (r, c) in centers]

    # 5b. WALLS — ONE boundary pass: a floor cell walls every side facing void
    for r in range(H):
        for c in range(W):
            if st[r][c] != SEA:
                continue
            if r - 1 < 0 or st[r - 1][c] != SEA:
                mp.wall(layers, r, c, "n")
            if c + 1 >= W or st[r][c + 1] != SEA:
                mp.wall(layers, r, c, "e")
            if r + 1 >= H or st[r + 1][c] != SEA:
                mp.wall(layers, r, c, "s")
            if c - 1 < 0 or st[r][c - 1] != SEA:
                mp.wall(layers, r, c, "w")

    # 5c. HEROES centred in their rooms (integration block: self/field bare;
    # cube/wrap/plinth/frame -> sim_cube housing; else a staging bed)
    integ_of = mg._integration()
    for i in range(n):
        x0, y0, rs = rooms_t[i]
        cr, cc = centers_t[i]
        chosen = casts[i]
        integ, cfam = integ_of.get(chosen, (None, None))
        if integ in ("self", "field"):
            layers["interactables"][cr][cc] = chosen
        elif integ in ("cube", "wrap", "plinth", "frame"):
            fam = cfam if integ in ("cube", "wrap") else integ
            layers["interactables"][cr][cc] = f"sim_cube#family:{fam}#mount:{chosen}"
        else:
            bed = sb.select_bed(chosen)
            if bed["is_wall"]:
                layers["interactables"][y0 + 1][cc] = f"{bed['bed']}:180#mount:{chosen}"
            else:
                layers["interactables"][cr][cc] = f"{bed['bed']}#mount:{chosen}"

    # 5d. spawn on the first room floor (2 from centre); exit teleporter in the
    # last room's inner corner (surrounded by floor, so it stays a clean door)
    cr0, cc0 = centers_t[0]
    spawn_cell = None
    for dr, dc in ((0, -2), (-2, 0), (0, 2), (2, 0), (-2, -2), (2, 2)):
        r, c = cr0 + dr, cc0 + dc
        if 0 <= r < H and 0 <= c < W and st[r][c] == SEA \
                and layers["interactables"][r][c] == " ":
            spawn_cell = (r, c)
            break
    if spawn_cell is None:
        spawn_cell = (cr0, cc0)
    xL, yL, rsL = rooms_t[n - 1]
    exit_cell = (yL + rsL - 2, xL + rsL - 2)
    assert st[spawn_cell[0]][spawn_cell[1]] == SEA, "spawn not on floor"
    assert st[exit_cell[0]][exit_cell[1]] == SEA, "exit not on floor"
    layers["utilities"][spawn_cell[0]][spawn_cell[1]] = "s"
    layers["utilities"][exit_cell[0]][exit_cell[1]] = "t:restart"

    # 5e. SUPPORTING CAST — same-domain benches staff the roomier beats (inner
    # >= 8); register thirds (arrival / work / depth) drive density.
    n_acts = (n + 2) // 3

    def register_of(a):
        if a == 0:
            return "arrival"
        return "depth" if a == n_acts - 1 else "work"

    slots = [{"act": i // 3, "kind": "beat", "cast": casts[i],
              "oy": rooms_t[i][1] + 1, "ox": rooms_t[i][0] + 1, "F": inners[i]}
             for i in range(n) if entries[i]["kind"] == "beat" and inners[i] >= 8]
    staffed = mg.staff_supporting_cast(layers, slots, mg._bench_library(seq), register_of)
    kept = []
    for s in staffed:
        r, c = s["cell"]
        if layers["structure"][r][c] == SEA:
            kept.append(s)
        else:
            layers["interactables"][r][c] = " "     # never a bench floating on void
    staffed = kept

    # palette bands — three horizontal thirds (arrival / work / depth)
    t1, t2 = H // 3, 2 * H // 3
    bands = [{"rect": [0, 0, W - 1, t1 - 1], "register": "arrival"},
             {"rect": [0, t1, W - 1, t2 - 1], "register": "work"},
             {"rect": [0, t2, W - 1, H - 1], "register": "depth"}]

    # 6. the mission metadata (strategy facts for the verdict loop)
    mission = {"beats": n_beats,
               "rooms": [{"cast": casts[i], "kind": entries[i]["kind"],
                          "rect": [rooms_t[i][0], rooms_t[i][1], sides[i], sides[i]],
                          "inner": inners[i]} for i in range(n)],
               "F_k_per_register": {"arrival": [F_ARRIVAL, K_ARRIVAL],
                                    "work": [F_WORK, K_WORK],
                                    "depth": [F_DEPTH, K_DEPTH]},
               "steps": STEPS,
               "repairs": repairs,
               "floor_cells": floor_cells,
               "seed": seed,
               "swaps": swaps,
               "supporting_cast": staffed,
               "engine": "numpy" if HAVE_NUMPY else "python",
               "canvas": CANVAS}

    # the contract — dimensions/settings/palettes/spawn/exit/wall runs/props
    mp.finish(name, seq, "reaction-diffusion", layers, mission, bands,
              spawn=spawn_cell, exit_cell=exit_cell, lod_radius=14.0)

    # report — floor cells + the repair count (the interesting stat)
    engine = "numpy 9-point" if HAVE_NUMPY else "pure-python 5-point"
    print(f"{name}: {n_beats} beats + {len(volt)} voltage -> {n} rooms, "
          f"{W}x{H} cells (canvas {CANVAS}, {engine}, {STEPS} steps)")
    print(f"  floor cells: {floor_cells}; connectivity repairs (A* carves): {repairs}")
    for i in range(n):
        x0, y0, rs = rooms_t[i]
        print(f"  room {i + 1:2d} <{casts[i]}> [{entries[i]['kind']}] "
              f"inner={inners[i]} rect=[x{x0},y{y0},{rs}x{rs}]")
    if swaps:
        print("  size-governed swaps:", ", ".join(swaps))
    if staffed:
        print("  supporting cast:", ", ".join(
            f"{s['name']} (beside {s['beside']})" for s in staffed))
    print(f"view: /map-viewer?map={name}")
    return 0


def main():
    arg = lambda k, d: next((a.split("=", 1)[1] for a in sys.argv
                             if a.startswith(f"--{k}=")), d)
    seq = arg("seq", None)
    if not seq:
        print(__doc__)
        return 1
    # the rule box: --set KNOB=value overrides a module constant
    # (pearl_factory.py — the additional parameters we can change)
    for a in sys.argv:
        if a.startswith("--set="):
            k, _, v = a[6:].partition("=")
            if k in globals() and not k.startswith("_"):
                globals()[k] = type(globals()[k])(v)
                print(f"knob {k} = {globals()[k]}")
    seed = int(arg("seed", "7"))
    name = arg("name", f"MissionRD_{seq.title().replace('_', '')}")
    return build(seq, name, seed)


if __name__ == "__main__":
    sys.exit(main())
