#!/usr/bin/env python3
"""gen_antrooms.py — the ANT-ROOMS strategy (Palle's principal).

Palle: "first create the perfect but close rooms for each artifact, then let
ants open the space between the rooms with pathfinding."

The inversion of gen_ants. There the floor is FOUND first (ants scatter, plates
follow); here the rooms are BUILT first — one perfect, close, hero-sized room per
beat — and the ANTS come second, opening the space *between* the sealed rooms.
Each ant is an A* run over a wobbly noise field: least-cost, never straight, and
it pays a fraction of the cost to walk a corridor an earlier ant already carved
(stigmergy priced as discount) — so later paths merge into shared trunks. The
rooms come out sealed by the one boundary-wall pass; the corridors punch the only
openings, and those openings ARE the doors.

  beats     -> rooms      one close, hero-sized room per beat (inner = fp + 4)
  scatter   -> apart       max-min-distance on a ~64 canvas (>= 12 apart)
  A* ants   -> the space   chain (i->i+1) + 2 loops; cost = 1 + 1.5*noise, and
                           x0.35 on already-carved floor (the trunk merge)
  walls     -> after       ONE boundary pass: a wall faces every void; the
                           corridor mouths are the doors
  finish    -> curation    dimensions/settings/palettes/spawn/exit/runs/props

A STRATEGY file (tools/gen_*.py): it only invents the floor idea and calls
map_principal.finish for every shared layer. The wild strategy, the standard
meeting point.

DETERMINISM: one random.Random(seed), drawn in a fixed order (room scatter ->
loop pairs -> noise field). The A* is a consistent-heuristic Dijkstra/A* with a
monotone tie-break counter, so it is a pure function of the seeded noise. Same
seed -> byte-identical map. Connectivity is guaranteed by construction: the
beat-order chain wires room i to room i+1 for every i, every A* run terminates
on the fully-connected grid (void is passable, just dear), and every carved
corridor touches the floor of both its endpoint rooms.

Usage:
  python tools/gen_antrooms.py --seq=randomness [--seed=7] [--name=MissionAntRooms_Randomness]
  python tools/gen_antrooms.py --seq=lsystems
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

SEA = mg.SEA                      # "2" — the walkable floor height
CANVAS = 64                       # working canvas (~64); cropped honest before finish
BUDGET_FP = 8.0                   # resolve_cast footprint budget (the room is close)
BUDGET_H = 3.4                    # resolve_cast height budget
MIN_INNER = 7                     # smallest inner floor a room may have
CAP_INNER = 14                    # largest inner floor a room may have
N_EXTRA = 2                       # loop connections beyond the beat-order chain
SPACING = 12                      # artifact distance: room min-spacing (relaxes -2/-4/0)
CORRIDOR_W = 3                    # carved corridor width (spine + perpendicular cells)
NOISE_LO, NOISE_HI = 1.0, 1.5     # cost(cell) = NOISE_LO + NOISE_HI * noise(cell)
REUSE = 0.35                      # cost multiplier on already-carved corridor floor


# ── the close room (sized to its hero) ──────────────────────────────────────

def _cast_cells(name: str) -> int:
    """max grid_cells of a cast (default 2 when unmeasured)."""
    s = mg._sizes().get(name, {}) or {}
    gc = s.get("grid_cells")
    if not gc:
        return 2
    return max(1, int(max(int(gc[0]), int(gc[1]))))


def _room_inner(cells: int) -> int:
    """inner floor size — the hero's footprint plus 4 cells of close walk,
    clamped to [MIN_INNER, CAP_INNER]. The room rect is inner + 2 (a 1-cell rim
    the boundary pass turns to wall on the void-facing sides)."""
    return max(MIN_INNER, min(CAP_INNER, cells + 4))


# ── step 1b: scatter the close rooms (max-min-distance greedy) ───────────────

def _overlaps(rect, placed, pad=1):
    x0, y0, x1, y1 = rect
    for (px0, py0, px1, py1) in placed:
        if not (x1 + pad < px0 or px1 + pad < x0
                or y1 + pad < py0 or py1 + pad < y0):
            return True
    return False


def _place_rooms(sizes, rng):
    """place each room at the candidate (seeded-shuffled every-3rd grid) whose
    min-distance to the placed centres is CLOSEST TO SPACING (target-seeking —
    the slider is the artifact distance, not just a floor), never closer than
    SPACING - 4."""
    cands = [(ax, ay) for ay in range(1, CANVAS, 3) for ax in range(1, CANVAS, 3)]
    rng.shuffle(cands)
    placed, centers, rooms = [], [], []
    for rs in sizes:
        best = None
        for floor_d in (SPACING - 4.0, SPACING - 6.0, 0.0):
            pick, pick_err, pick_c = None, float("inf"), None
            for (ax, ay) in cands:
                x1, y1 = ax + rs - 1, ay + rs - 1
                if ax < 1 or ay < 1 or x1 > CANVAS - 2 or y1 > CANVAS - 2:
                    continue
                if _overlaps((ax, ay, x1, y1), placed, pad=1):
                    continue
                cen = (ay + rs // 2, ax + rs // 2)
                d = (min(math.hypot(cen[0] - pc[0], cen[1] - pc[1])
                         for pc in centers) if centers else float(SPACING))
                err = abs(d - float(SPACING))
                if d >= max(floor_d, 0.0) and err < pick_err:
                    pick, pick_err, pick_c = (ax, ay, x1, y1), err, cen
            if pick:
                best = (pick, pick_c)
                break
        if best is None:
            raise RuntimeError("gen_antrooms: could not fit a room on the canvas")
        (x0, y0, x1, y1), cen = best
        placed.append((x0, y0, x1, y1))
        centers.append(cen)
        rooms.append((x0, y0, rs))
    return rooms, centers


# ── step 2a: the connection plan (chain in beat order + a few loops) ─────────

def _connections(n, rng):
    conns = [(i, i + 1) for i in range(n - 1)]     # the WALK ORDER: i -> i+1
    if n >= 3:
        pool = [(i, j) for i in range(n) for j in range(i + 2, n)]   # non-adjacent
        rng.shuffle(pool)
        conns += pool[:N_EXTRA]
    return conns


# ── step 2b: the wobble field (the ants walk least-cost, never straight) ─────

def _noise_grid(rng):
    """a seeded noise value in [0, 1) per canvas cell, drawn row-major."""
    return [[rng.random() for _ in range(CANVAS)] for _ in range(CANVAS)]


# ── step 2c: one ant = one A* run (stigmergy priced as a reuse discount) ─────

def _astar(start, target, noise, room_floor, carved):
    """least-cost 4-neighbour path start->target. Entering a cell costs
    NOISE_LO + NOISE_HI*noise; a room-floor cell is a flat 1.0; an already-
    carved corridor cell is discounted by REUSE (later ants merge onto the
    trunk). Heuristic 0.35*manhattan is consistent (min step cost == 0.35), so
    the pop-once A* is optimal AND a pure function of the seeded noise."""
    tr, tc = target

    def enter_cost(cell):
        if cell in room_floor:
            return 1.0
        v = NOISE_LO + NOISE_HI * noise[cell[0]][cell[1]]
        if cell in carved:
            v *= REUSE
        return v

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


# ── the build ────────────────────────────────────────────────────────────────

def build(seq, name, seed):
    beats, volt = mg.load_mission(seq)
    if not beats:
        print(f"gen_antrooms: no beats in baseline for {seq}")
        return 1
    n = min(8, len(beats))                 # up to ~8 heroes (all beats if fewer)

    # 1. PERFECT CLOSE ROOMS — resolve each cast, size its room to the hero
    casts, swaps, inners = [], [], []
    for i in range(n):
        chosen, swapped = mg.resolve_cast(beats[i]["cast"], beats[i].get("alts", []),
                                          BUDGET_FP, BUDGET_H)
        casts.append(chosen)
        if swapped:
            swaps.append(f"{swapped}->{chosen}")
        inners.append(_room_inner(_cast_cells(chosen)))
    sizes = [inner + 2 for inner in inners]      # room rect side = inner + 2

    rng = random.Random(seed)              # the ONLY randomness — fixed draw order

    rooms, centers = _place_rooms(sizes, rng)    # scatter the close rooms
    conns = _connections(n, rng)                 # chain + 2 loop pairs
    noise = _noise_grid(rng)                     # the wobble field the ants walk

    room_floor = set()
    for (x0, y0, rs) in rooms:
        for r in range(y0, y0 + rs):
            for c in range(x0, x0 + rs):
                room_floor.add((r, c))

    # 2. ANTS OPEN THE SPACE — A* least-cost trails, carved 3-wide, reuse merges
    carved = set()
    trunk_merges = 0
    for (a, b) in conns:
        path = _astar(centers[a], centers[b], noise, room_floor, carved)
        # a path cell already carved by an EARLIER connection == a trunk merge
        trunk_merges += sum(1 for cell in path if cell in carved)
        for k, cell in enumerate(path):
            if k + 1 < len(path):
                dr, dc = path[k + 1][0] - cell[0], path[k + 1][1] - cell[1]
            else:
                dr, dc = cell[0] - path[k - 1][0], cell[1] - path[k - 1][1]
            perps = [(0, -1), (0, 1)] if dr != 0 else [(-1, 0), (1, 0)]
            # spine + (CORRIDOR_W - 1) perpendicular cells, alternating sides
            side = [(0, 0)]
            for w in range(1, CORRIDOR_W):
                p = perps[(w - 1) % 2]
                k2 = (w + 1) // 2
                side.append((p[0] * k2, p[1] * k2))
            for (pr, pc) in side:
                rr, cc = cell[0] + pr, cell[1] + pc
                if 0 <= rr < CANVAS and 0 <= cc < CANVAS and (rr, cc) not in room_floor:
                    carved.add((rr, cc))           # skip cells already room floor

    floor = set(room_floor) | carved

    # crop to used cells + 1 margin (dimensions honest)
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

    # 3. WALLS — ONE boundary pass: a floor cell walls every side facing void.
    # Where a corridor meets a room both cells are floor, so no wall is laid —
    # that gap is the door. The rooms come out sealed but for their corridors.
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

    # 4. HEROES centred in their rooms (the integration block: self/field bare;
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

    # 5. spawn on the first room floor (2 from centre); exit teleporter in the
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
    # reserve them so the supporting cast respects the occupancy
    layers["utilities"][spawn_cell[0]][spawn_cell[1]] = "s"
    layers["utilities"][exit_cell[0]][exit_cell[1]] = "t:restart"

    # 4b. SUPPORTING CAST — same-domain benches staff the roomier beats only
    # (inner >= 8); the tight rooms keep their single hero.
    n_acts = (n + 2) // 3

    def register_of(a):
        if a == 0:
            return "arrival"
        return "depth" if a == n_acts - 1 else "work"

    slots = [{"act": i // 3, "kind": "beat", "cast": casts[i],
              "oy": rooms_t[i][1] + 1, "ox": rooms_t[i][0] + 1, "F": inners[i]}
             for i in range(n) if inners[i] >= 8]
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
    mission = {"beats": n,
               "rooms": [{"cast": casts[i], "rect": [rooms_t[i][0], rooms_t[i][1],
                                                     rooms_t[i][2], rooms_t[i][2]],
                          "inner": inners[i]} for i in range(n)],
               "connections": len(conns),
               "corridor_cells": len(carved),
               "trunk_merges": trunk_merges,
               "seed": seed, "swaps": swaps, "supporting_cast": staffed}

    # the contract — dimensions/settings/palettes/spawn/exit/wall runs/props
    mp.finish(name, seq, "ant-rooms", layers, mission, bands,
              spawn=spawn_cell, exit_cell=exit_cell, lod_radius=14.0)

    # report — the room sizes, the corridor cell count, the trunk merges
    print(f"{name}: {n} rooms, {len(conns)} connections -> {W}x{H} cells "
          f"(canvas {CANVAS}, cropped)")
    print(f"  corridor cells carved: {len(carved)}; trunk merges (reused path "
          f"cells): {trunk_merges}; floor cells total: {len(floor)}")
    for i in range(n):
        x0, y0, rs = rooms_t[i]
        print(f"  room {i + 1:2d} <{casts[i]}>  inner={inners[i]} "
              f"rect=[x{x0},y{y0},{rs}x{rs}]")
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
    name = arg("name", f"MissionAntRooms_{seq.title().replace('_', '')}")
    return build(seq, name, seed)


if __name__ == "__main__":
    sys.exit(main())
