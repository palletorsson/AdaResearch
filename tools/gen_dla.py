#!/usr/bin/env python3
"""gen_dla.py — the DLA DENDRITES strategy (the fractals chapter's map).

Palle's map-strategy family, spec in doc/MAP_STRATEGY_FAMILY.md ("DLA dendrites"):
"Rooms as aggregation seeds; seeded random walkers stick on contact -> dendritic
corridors radiating and joining between rooms."

Diffusion-Limited Aggregation grows the FLOOR. The rooms are the initial
AGGREGATE — every room rect is a block of STUCK cells. Then WALKERS are released
one at a time from the perimeter of a circle around the aggregate's bounding
box; each takes a seeded random 4-neighbour walk and STICKS the instant it is
4-adjacent to a stuck cell. Sticking grows the aggregate outward toward the
launch circle, so dendrites RADIATE from the rooms and, where two rooms' fronts
meet, JOIN. Dendrites are naturally 1-wide (dilate to ~3) and naturally treelike
(loops are added by the connectivity repair). Fractal register: this is the
chapter walking inside its own algorithm.

  rooms      -> the seed      one close, hero-sized aggregate per beat (+voltage)
  walkers    -> the floor     DLA sticks a dendrite lattice between the seeds
  dilate     -> 3-wide        plus-dilation opens the 1-wide dendrites to walk
  repair     -> the guarantee A* over noise carves any beat pair DLA left apart
  prune      -> tightness     dead twigs (degree-1 tips) shorten to a fixpoint
  finish     -> curation      dimensions/settings/palettes/spawn/exit/runs/props

A STRATEGY file (tools/gen_*.py): it only invents the floor idea and calls
map_principal.finish for every shared layer. The wild strategy, the standard
meeting point.

DETERMINISM: one random.Random(seed), drawn in a fixed order (room scatter ->
DLA walkers -> noise field). Every walker's launch angle, step direction, and
stickiness roll come from that one stream; the A* repair is a consistent-
heuristic search over the seeded noise with a monotone tie-break, so it is a
pure function of the noise. Same seed -> byte-identical map. Connectivity is
GUARANTEED by construction: the beat-order chain is repaired with an A* carve
for any pair DLA failed to join, then unreachable islands are removed, then
degree-1 pruning can only drop leaves (a leaf never disconnects a graph).

Usage:
  python tools/gen_dla.py --seq=randomness [--seed=7] [--name=MissionDLA_Randomness]
  python tools/gen_dla.py --seq=lsystems
  python tools/gen_dla.py --seq=randomness --set=WALKERS=600 --set=PRUNE_ROUNDS=8
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
import mission_graph as mg        # load_mission/resolve_cast/_sizes/_integration/staff/bench
import staging_beds as sb         # select_bed (the marriage-1 body)

SEA = mg.SEA                      # "2" — the walkable floor height
CANVAS = 64                       # scatter canvas (~64) for the room seeds
# WALKERS is THE tightness/character knob. The spec ceiling is 900, but under
# DLA screening interior seeds are shadowed and never reach the 2 attachments
# the early-stop needs, so 900 runs to exhaustion and over-grows a ~2900-cell
# halo (well past the <1800 target). Spread max-min seeds keep dendrites a
# texture that repairs — not dendrites — join, so tightness is bought only by
# fewer walkers. Default 110 keeps both validation maps (seed 7) under 1800
# while still drawing a visible dendrite lattice; --set=WALKERS=900 restores the
# spec ceiling (the dense fractal look, looser floor). (spec point 8: "downsize
# WALKERS if needed, note it".)
WALKERS = 110                     # DLA walkers released one at a time (knob)
STICKINESS = 1.0                  # P(stick) when 4-adjacent to the aggregate (knob)
DILATION = 1                      # plus-dilation rounds on dendrites (knob, 1 -> ~3-wide)
STEP_CAP = 4000                   # max steps a walker takes before it is abandoned
PRUNE_ROUNDS = 6                  # dead-twig pruning passes (knob)
BUDGET_FP = 8.0                   # resolve_cast footprint budget (the seed is close)
BUDGET_H = 3.4                    # resolve_cast height budget
MIN_INNER = 7                     # smallest inner floor a beat seed may have
CAP_INNER = 14                    # largest inner floor a beat seed may have
VOLT_INNER = 6                    # voltage-chapel seeds are small
SCATTER_MIN = 12                  # max-min-distance scatter threshold (relax 10/8/0)
NOISE_LO, NOISE_HI = 1.0, 1.5     # repair cost(cell) = NOISE_LO + NOISE_HI * noise
REUSE_COST = 0.1                  # repair cost to re-enter existing floor (thread the lattice)

PLUS = ((-1, 0), (1, 0), (0, -1), (0, 1))
TAU = 2.0 * math.pi


# ── the close seed (sized to its hero) ──────────────────────────────────────

def _cast_cells(name: str) -> int:
    """max grid_cells of a cast (default 2 when unmeasured)."""
    s = mg._sizes().get(name, {}) or {}
    gc = s.get("grid_cells")
    if not gc:
        return 2
    return max(1, int(max(int(gc[0]), int(gc[1]))))


def _beat_inner(cells: int) -> int:
    """inner floor = hero footprint + 4 cells of close walk, clamped [7, 14]."""
    return max(MIN_INNER, min(CAP_INNER, cells + 4))


# ── step 1b: scatter the seeds (max-min-distance greedy, like gen_antrooms) ──

def _overlaps(rect, placed, pad=1):
    x0, y0, x1, y1 = rect
    for (px0, py0, px1, py1) in placed:
        if not (x1 + pad < px0 or px1 + pad < x0
                or y1 + pad < py0 or py1 + pad < y0):
            return True
    return False


def _place_seeds(sizes, rng):
    """place each seed at the candidate (seeded-shuffled every-3rd grid) that
    maximises min-distance to the placed centres, >= SCATTER_MIN apart
    (relax 10/8/0). Returns [(x0, y0, side)], [(cy, cx)] in canvas coords."""
    cands = [(ax, ay) for ay in range(1, CANVAS, 3) for ax in range(1, CANVAS, 3)]
    rng.shuffle(cands)
    placed, centers, rects = [], [], []
    for rs in sizes:
        best = None
        for thresh in (float(SCATTER_MIN), 10.0, 8.0, 0.0):
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
            raise RuntimeError("gen_dla: could not fit a seed on the canvas")
        (x0, y0, x1, y1), cen = best
        placed.append((x0, y0, x1, y1))
        centers.append(cen)
        rects.append((x0, y0, rs))
    return rects, centers


# ── step 2: the DLA aggregation (walkers stick on contact) ──────────────────

def _aggregate(rects_g, centers_g, n_rooms, G, cen_row, cen_col, R, rng):
    """release WALKERS seeded random walkers from the launch circle; each sticks
    the instant it is 4-adjacent to a stuck cell. Rooms are the initial stuck
    aggregate. Stops early once every room rect has >= 2 dendrite attachments.
    Returns (dendrite cells in stick order, walkers released)."""
    stuck = bytearray(G * G)
    room_of = [-1] * (G * G)                    # -1 sentinel = not a room cell
    for i, (x0, y0, s) in enumerate(rects_g):
        for r in range(y0, y0 + s):
            base = r * G
            for c in range(x0, x0 + s):
                idx = base + c
                stuck[idx] = 1
                room_of[idx] = i

    attachments = [0] * n_rooms
    need = n_rooms                              # rooms still short of 2 attachments
    dendrite = []
    released = 0
    lo, hi = 1, G - 2
    rnd = rng.random
    rr = rng.randrange
    sin, cos, rnd2 = math.sin, math.cos, round
    dr_t, dc_t = (-1, 1, 0, 0), (0, 0, -1, 1)
    sticky_always = STICKINESS >= 1.0

    for _ in range(WALKERS):
        released += 1
        ang = rnd() * TAU
        r = int(rnd2(cen_row + R * sin(ang)))
        c = int(rnd2(cen_col + R * cos(ang)))
        if r < lo:
            r = lo
        elif r > hi:
            r = hi
        if c < lo:
            c = lo
        elif c > hi:
            c = hi
        steps = 0
        while steps < STEP_CAP:
            i = r * G + c
            if stuck[i - G] or stuck[i + G] or stuck[i - 1] or stuck[i + 1]:
                if sticky_always or rnd() < STICKINESS:
                    stuck[i] = 1
                    dendrite.append((r, c))
                    touched = set()
                    rid = room_of[i - G]
                    if rid >= 0:
                        touched.add(rid)
                    rid = room_of[i + G]
                    if rid >= 0:
                        touched.add(rid)
                    rid = room_of[i - 1]
                    if rid >= 0:
                        touched.add(rid)
                    rid = room_of[i + 1]
                    if rid >= 0:
                        touched.add(rid)
                    for rid in touched:
                        attachments[rid] += 1
                        if attachments[rid] == 2:
                            need -= 1
                    break
            d = rr(4)
            r += dr_t[d]
            c += dc_t[d]
            steps += 1
            if r < lo or r > hi or c < lo or c > hi:
                ang = rnd() * TAU               # wandered out -> respawn on circle
                r = int(rnd2(cen_row + R * sin(ang)))
                c = int(rnd2(cen_col + R * cos(ang)))
                if r < lo:
                    r = lo
                elif r > hi:
                    r = hi
                if c < lo:
                    c = lo
                elif c > hi:
                    c = hi
        if need <= 0:
            break
    return dendrite, released


# ── step 3: connectivity repair (A* over noise, like gen_antrooms) ──────────

def _components(floor):
    """4-connected components of the floor set. Returns {cell: comp_id}."""
    comp = {}
    cid = 0
    for cell in sorted(floor):
        if cell in comp:
            continue
        stack = [cell]
        comp[cell] = cid
        while stack:
            r, c = stack.pop()
            for dr, dc in PLUS:
                nb = (r + dr, c + dc)
                if nb in floor and nb not in comp:
                    comp[nb] = cid
                    stack.append(nb)
        cid += 1
    return comp


def _astar(start, target, noise, floor, G):
    """least-cost 4-neighbour path start->target. An EXISTING floor cell (room,
    dendrite, or an earlier repair) is near-free (REUSE_COST) so the search
    threads the dendrite lattice and only pays real cost across void, where
    entering costs NOISE_LO + NOISE_HI*noise. Heuristic REUSE_COST*manhattan is
    consistent (min step cost == REUSE_COST), so pop-once A* is optimal and a
    pure function of the seeded noise — the repair merges into the aggregate."""
    tr, tc = target

    def enter_cost(cell):
        if cell in floor:
            return REUSE_COST
        return NOISE_LO + NOISE_HI * noise[cell[0]][cell[1]]

    openh = [(REUSE_COST * (abs(start[0] - tr) + abs(start[1] - tc)), 0, start)]
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
        for dr, dc in PLUS:
            nb = (r + dr, c + dc)
            if not (0 <= nb[0] < G and 0 <= nb[1] < G) or nb in visited:
                continue
            ng = g[cur] + enter_cost(nb)
            if nb not in g or ng < g[nb]:
                g[nb] = ng
                parent[nb] = cur
                h = REUSE_COST * (abs(nb[0] - tr) + abs(nb[1] - tc))
                heapq.heappush(openh, (ng + h, counter, nb))
                counter += 1
    path = [target]
    cur = target
    while cur in parent:
        cur = parent[cur]
        path.append(cur)
    path.reverse()
    return path


def _carve(path, floor, repair_cells, room_floor, G):
    """lay a 3-wide corridor along path; carved non-room cells join floor and
    the protected repair set."""
    for k, cell in enumerate(path):
        if k + 1 < len(path):
            dr, dc = path[k + 1][0] - cell[0], path[k + 1][1] - cell[1]
        else:
            dr, dc = cell[0] - path[k - 1][0], cell[1] - path[k - 1][1]
        perps = [(0, -1), (0, 1)] if dr != 0 else [(-1, 0), (1, 0)]
        for (pr, pc) in [(0, 0)] + perps:
            rr, cc = cell[0] + pr, cell[1] + pc
            if 0 <= rr < G and 0 <= cc < G and (rr, cc) not in room_floor:
                floor.add((rr, cc))
                repair_cells.add((rr, cc))


# ── the build ────────────────────────────────────────────────────────────────

def build(seq, name, seed):
    beats, volt = mg.load_mission(seq)
    if not beats:
        print(f"gen_dla: no beats in baseline for {seq}")
        return 1
    n = min(8, len(beats))                     # up to ~8 heroes (all beats if fewer)

    # 1. resolve the beat casts, size each seed to its hero's footprint
    casts, swaps, inners, kinds = [], [], [], []
    for i in range(n):
        chosen, swapped = mg.resolve_cast(beats[i]["cast"], beats[i].get("alts", []),
                                          BUDGET_FP, BUDGET_H)
        casts.append(chosen)
        if swapped:
            swaps.append(f"{swapped}->{chosen}")
        inners.append(_beat_inner(_cast_cells(chosen)))
        kinds.append("beat")
    # voltage pieces become small seeds (deduped against the beat casts)
    seen = set(casts)
    for piece in volt:
        chosen, swapped = mg.resolve_cast(piece, [], BUDGET_FP, BUDGET_H)
        if chosen in seen:
            continue
        seen.add(chosen)
        casts.append(chosen)
        if swapped:
            swaps.append(f"{swapped}->{chosen}")
        inners.append(VOLT_INNER)
        kinds.append("volt")
    n_rooms = len(casts)
    sizes = [inner + 2 for inner in inners]    # seed rect side = inner + 2 (1-cell rim)

    rng = random.Random(seed)                  # the ONLY randomness — fixed draw order

    # 2. scatter the seeds, then frame the DLA grid around their bounding box
    rects_w, centers_w = _place_seeds(sizes, rng)
    minx = min(x0 for x0, _, _ in rects_w)
    maxx = max(x0 + s - 1 for x0, _, s in rects_w)
    miny = min(y0 for _, y0, _ in rects_w)
    maxy = max(y0 + s - 1 for _, y0, s in rects_w)
    cen_r, cen_c = (miny + maxy) // 2, (minx + maxx) // 2
    R = 0.5 * math.hypot(maxx - minx + 1, maxy - miny + 1) + 4.0   # launch radius (+4)
    M = int(math.ceil(R + 6.0)) + 1            # roam half-extent (out of canvas+6 respawns)
    G = 2 * M + 3
    goff_r, goff_c = M + 1 - cen_r, M + 1 - cen_c
    rects_g = [(x0 + goff_c, y0 + goff_r, s) for (x0, y0, s) in rects_w]
    centers_g = [(cy + goff_r, cx + goff_c) for (cy, cx) in centers_w]

    # 3. DLA — the walkers grow the dendrite lattice off the seed aggregate
    dendrite, released = _aggregate(rects_g, centers_g, n_rooms, G,
                                    M + 1, M + 1, R, rng)

    # 4. FLOOR — seeds are floor; dendrites plus-dilate to ~3-wide corridors
    room_floor = set()
    for (x0, y0, s) in rects_g:
        for r in range(y0, y0 + s):
            for c in range(x0, x0 + s):
                room_floor.add((r, c))
    floor = set(room_floor)
    frontier = set(dendrite)
    floor |= frontier
    for _ in range(DILATION):
        nxt = set()
        for (r, c) in frontier:
            for dr, dc in PLUS:
                nxt.add((r + dr, c + dc))
        floor |= nxt
        frontier = nxt

    # 5. CONNECTIVITY GUARANTEE — repair any beat-order pair DLA left apart with
    # one A* carve over the noise field (seeded, like gen_antrooms)
    noise = [[rng.random() for _ in range(G)] for _ in range(G)]
    repair_cells = set()
    repairs = 0
    for i in range(n_rooms - 1):
        comp = _components(floor)
        a, b = centers_g[i], centers_g[i + 1]
        if comp.get(a) != comp.get(b):
            path = _astar(a, b, noise, floor, G)
            _carve(path, floor, repair_cells, room_floor, G)
            repairs += 1

    # 6. remove unreachable floor islands (flood from the first seed centre)
    comp = _components(floor)
    keep = comp.get(centers_g[0])
    floor = {cell for cell in floor if comp.get(cell) == keep}
    repair_cells &= floor

    # 7. TIGHTNESS — prune dead twigs: a floor cell with exactly one floor
    # neighbour, not a room or repair cell, becomes void; repeat to a fixpoint
    protected = room_floor | repair_cells
    pruned = 0
    for _ in range(PRUNE_ROUNDS):
        tips = []
        for (r, c) in sorted(floor):
            if (r, c) in protected:
                continue
            deg = 0
            for dr, dc in PLUS:
                if (r + dr, c + dc) in floor:
                    deg += 1
                    if deg > 1:
                        break
            if deg == 1:
                tips.append((r, c))
        if not tips:
            break
        for t in tips:
            floor.discard(t)
        pruned += len(tips)

    # 8. crop to used cells + 1 margin (dimensions honest)
    rows = [p[0] for p in floor]
    cols = [p[1] for p in floor]
    off_r, off_c = min(rows) - 1, min(cols) - 1
    H = (max(rows) - min(rows)) + 3
    W = (max(cols) - min(cols)) + 3
    layers = mp.blank_layers(W, H)
    st = layers["structure"]
    for (r, c) in floor:
        st[r - off_r][c - off_c] = SEA
    rects_t = [(x0 - off_c, y0 - off_r, s) for (x0, y0, s) in rects_g]
    centers_t = [(r - off_r, c - off_c) for (r, c) in centers_g]

    # 9. WALLS — one boundary pass: a floor cell walls every side facing void.
    # Where a dendrite meets a seed both cells are floor, so no wall is laid —
    # that gap is the corridor mouth.
    for r in range(H):
        row = st[r]
        for c in range(W):
            if row[c] != SEA:
                continue
            if r - 1 < 0 or st[r - 1][c] != SEA:
                mp.wall(layers, r, c, "n")
            if c + 1 >= W or row[c + 1] != SEA:
                mp.wall(layers, r, c, "e")
            if r + 1 >= H or st[r + 1][c] != SEA:
                mp.wall(layers, r, c, "s")
            if c - 1 < 0 or row[c - 1] != SEA:
                mp.wall(layers, r, c, "w")

    # 10. HEROES centred on their seeds (the integration block: self/field bare;
    # cube/wrap/plinth/frame -> sim_cube housing; else a staging bed)
    integ_of = mg._integration()
    for i in range(n_rooms):
        x0, y0, s = rects_t[i]
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

    # 11. spawn on the first seed (2 from centre); exit teleporter in the last
    # BEAT seed's inner corner (surrounded by floor, so it stays a clean door)
    cr0, cc0 = centers_t[0]
    spawn_cell = None
    for dr, dc in ((0, 2), (2, 0), (0, -2), (-2, 0), (2, 2), (-2, -2)):
        r, c = cr0 + dr, cc0 + dc
        if 0 <= r < H and 0 <= c < W and st[r][c] == SEA \
                and layers["interactables"][r][c] == " ":
            spawn_cell = (r, c)
            break
    if spawn_cell is None:
        spawn_cell = (cr0, cc0)
    xL, yL, sL = rects_t[n - 1]
    exit_cell = (yL + sL - 2, xL + sL - 2)
    assert st[spawn_cell[0]][spawn_cell[1]] == SEA, "spawn not on floor"
    assert st[exit_cell[0]][exit_cell[1]] == SEA, "exit not on floor"
    layers["utilities"][spawn_cell[0]][spawn_cell[1]] = "s"
    layers["utilities"][exit_cell[0]][exit_cell[1]] = "t:restart"

    # 12. SUPPORTING CAST — same-domain benches staff the roomier seeds (inner
    # >= 8); tight and voltage seeds keep their single hero. Register by thirds.
    n_acts = (n_rooms + 2) // 3

    def register_of(a):
        if a == 0:
            return "arrival"
        return "depth" if a == n_acts - 1 else "work"

    slots = [{"act": i // 3, "kind": "beat", "cast": casts[i],
              "oy": rects_t[i][1] + 1, "ox": rects_t[i][0] + 1, "F": inners[i]}
             for i in range(n_rooms) if inners[i] >= 8]
    staffed = mg.staff_supporting_cast(layers, slots, mg._bench_library(seq), register_of)
    kept = []
    for scast in staffed:
        r, c = scast["cell"]
        if layers["structure"][r][c] == SEA:
            kept.append(scast)
        else:
            layers["interactables"][r][c] = " "     # never a bench floating on void
    staffed = kept

    # 13. palette bands — three horizontal thirds (arrival / work / depth)
    t1, t2 = H // 3, 2 * H // 3
    bands = [{"rect": [0, 0, W - 1, t1 - 1], "register": "arrival"},
             {"rect": [0, t1, W - 1, t2 - 1], "register": "work"},
             {"rect": [0, t2, W - 1, H - 1], "register": "depth"}]

    stuck_cells = len(dendrite)
    # 14. the mission metadata (strategy facts for the verdict loop)
    mission = {"beats": n,
               "rooms": [{"cast": casts[i], "kind": kinds[i],
                          "rect": [rects_t[i][0], rects_t[i][1], rects_t[i][2],
                                   rects_t[i][2]], "inner": inners[i]}
                         for i in range(n_rooms)],
               "walkers": released, "stuck_cells": stuck_cells,
               "repairs": repairs, "pruned": pruned, "seed": seed,
               "swaps": swaps, "supporting_cast": staffed}

    # the contract — dimensions/settings/palettes/spawn/exit/wall runs/props
    mp.finish(name, seq, "dla-dendrites", layers, mission, bands,
              spawn=spawn_cell, exit_cell=exit_cell, lod_radius=14.0)

    # 15. report — the seed sizes, the aggregation, the repairs, the tightness
    n_volt = n_rooms - n
    print(f"{name}: {n} heroes + {n_volt} voltage seeds -> {W}x{H} cells "
          f"(DLA grid {G}, cropped)")
    print(f"  walkers released: {released}/{WALKERS}; dendrite cells stuck: "
          f"{stuck_cells}; repairs: {repairs}; pruned tips: {pruned}; "
          f"floor cells: {len(floor)}")
    for i in range(n_rooms):
        x0, y0, s = rects_t[i]
        tag = "volt" if kinds[i] == "volt" else "beat"
        print(f"  seed {i + 1:2d} [{tag}] <{casts[i]}>  inner={inners[i]} "
              f"rect=[x{x0},y{y0},{s}x{s}]")
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
    name = arg("name", f"MissionDLA_{seq.title().replace('_', '')}")
    return build(seq, name, seed)


if __name__ == "__main__":
    sys.exit(main())
