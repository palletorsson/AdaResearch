#!/usr/bin/env python3
"""gen_erosion.py — the EROSION VALLEYS strategy (Palle's principal).

The terrain/noise chapters' own map. A seeded heightfield is laid over the
canvas; the beat rooms are stamped as flat PLATEAUS at their scattered sites;
then water finds the low route between them — for every beat-order pair (plus a
couple of seeded loops, plus each voltage room to its nearest beat) an A* path
is carved along the least-cost line of the terrain (cost = 1 + 6*height), so the
corridor prefers the valleys, not the ridges. The carved valley floor is the
walk; the rooms are its plateaus.

  heightfield -> value-noise (2-3 octaves, bilinear lattice), normalized 0..1
  rooms       -> plateaus stamped flat at scattered beat sites (max-min apart)
  valleys     -> A* least-cost paths (water finds the low route), carved 3-wide
  relief      -> berms: high-noise cells flanking the floor rise to height 3,
                 so the valley reads as CUT BETWEEN BANKS (else the edge is void)
  walls       -> floor/void boundary (berm edges carry no wall — the berm IS
                 the bank); finish adds runs + props
  finish      -> dimensions/settings/palettes/spawn/exit/wall runs/props

APPROACH — FLAT floor, not walkable height steps. VERIFIED against the pathfinder
(tools/map_pathfinder.py MapGraph.neighbors): a ramp is recognised ONLY by the
'wp' prefix (self.wp_cells = {... if cell.startswith("wp")}) — NOT 'r'; and
climbing UP a height (nb_h > cur_h) is impossible without a wp cell on either
side. Real height-step rooms would therefore need a correct wp at every door and
would risk unreachable heroes. So the WALK STAYS FLAT: every floor cell is SEA
("2"), same height -> always mutually walkable. Heights appear ONLY on non-walk
BERM cells (structure "3") flanking the valleys — visual relief the player never
steps onto (a climb-up with no wp is simply never traversed by the pathfinder,
so berms are inert, artifact-free, and cannot break reachability).

DETERMINISM: two derived random streams from the master seed — noise_rng
(heightfield lattice) and layout_rng (room scatter + extra loops) — each drawn in
a fixed order; A* is rng-free with counter-tie-broken heapq. Same seed ->
byte-identical map. Connectivity is guaranteed by construction: the A* over a
fully-connected grid always reaches its target and every carved path is 4-
connected floor, so the beat chain welds every hero into one component and each
voltage room hangs off its nearest hero.

A STRATEGY file (tools/gen_*.py): it only invents the floor idea and calls
map_principal.finish for every shared layer. The wild strategy, the standard
meeting point.

Usage:
  python tools/gen_erosion.py --seq=randomness [--seed=7] [--name=MissionErosion_Randomness]
  python tools/gen_erosion.py --seq=lsystems
  python tools/gen_erosion.py --seq=randomness --set=OCTAVES=2 --set=BERM_NOISE=0.5
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
BERM = "3"                       # non-walk relief height (flanks the valleys)

# ── the rule box: --set KNOB=value overrides any of these (pearl_factory) ────
CANVAS = 64                      # working canvas (~64); cropped honest before finish
OCTAVES = 3                      # value-noise octaves (2-3)
NOISE_BASE = 3                   # octave 0 lattice = NOISE_BASE cells; doubles per octave
SCATTER_MIN = 12.0               # room scatter max-min-distance target (relaxes 12/10/8/0)
GRID_STEP = 3                    # scatter candidate density (every-Nth cell)
HERO_CAP = 8                     # max hero rooms (beats beyond are at depth)
INNER_MIN = 7                    # hero plateau inner floor, clamp low
INNER_CAP = 14                   # hero plateau inner floor, clamp high
VOLT_INNER = 6                   # voltage plateau inner floor (fixed, small)
HEIGHT_COST = 6.0                # A* cost of a cell = 1 + HEIGHT_COST * height(cell)
VALLEY_WIDTH = 3                 # carve width (radius = WIDTH//2 Manhattan disk)
EXTRA_VALLEYS = 2                # seeded extra loop connections among the heroes
BERM_NOISE = 0.55                # a floor-flanking non-floor cell rises to a berm
                                 # only where the noise height exceeds this


# ── the footprint oracle (sizes the plateau) ────────────────────────────────

def _hero_cells(name: str) -> int:
    """max grid-cell footprint of a cast (default 2 when unmeasured)."""
    s = mg._sizes().get(name, {}) or {}
    gc = s.get("grid_cells")
    if not gc:
        return 2
    return max(1, int(max(int(gc[0]), int(gc[1]))))


def _inner_for(name: str) -> int:
    """hero plateau inner floor = hero_cells + 4, clamped [INNER_MIN, INNER_CAP]."""
    return max(INNER_MIN, min(INNER_CAP, _hero_cells(name) + 4))


# ── step 2: the heightfield (seeded value-noise, bilinear lattice) ───────────

def _octave_noise(grid: int, rng) -> list:
    """one octave: a (grid+1)^2 random lattice, bilinearly sampled to the canvas."""
    lat = [[rng.random() for _ in range(grid + 1)] for _ in range(grid + 1)]
    out = [[0.0] * CANVAS for _ in range(CANVAS)]
    scale = grid / CANVAS
    for r in range(CANVAS):
        fy = r * scale
        y0 = int(fy)
        ty = fy - y0
        y1 = min(y0 + 1, grid)
        row0, row1 = lat[y0], lat[y1]
        for c in range(CANVAS):
            fx = c * scale
            x0 = int(fx)
            tx = fx - x0
            x1 = min(x0 + 1, grid)
            top = row0[x0] + (row0[x1] - row0[x0]) * tx
            bot = row1[x0] + (row1[x1] - row1[x0]) * tx
            out[r][c] = top + (bot - top) * ty
    return out


def _heightfield(rng) -> list:
    """sum OCTAVES of value-noise (amplitude halving), normalized 0..1."""
    field = [[0.0] * CANVAS for _ in range(CANVAS)]
    amp = 1.0
    for o in range(OCTAVES):
        grid = NOISE_BASE * (2 ** o)
        oct_f = _octave_noise(grid, rng)
        for r in range(CANVAS):
            fr, orow = field[r], oct_f[r]
            for c in range(CANVAS):
                fr[c] += amp * orow[c]
        amp *= 0.5
    lo = min(min(row) for row in field)
    hi = max(max(row) for row in field)
    span = (hi - lo) or 1.0
    for r in range(CANVAS):
        fr = field[r]
        for c in range(CANVAS):
            fr[c] = (fr[c] - lo) / span
    return field


# ── step 1/3: scatter the plateaus (max-min-distance greedy, gen_ants kin) ───

def _overlaps(rect, placed, pad=1):
    x0, y0, x1, y1 = rect
    for (px0, py0, px1, py1) in placed:
        if not (x1 + pad < px0 or px1 + pad < x0
                or y1 + pad < py0 or py1 + pad < y0):
            return True
    return False


def _scatter(inners, rng):
    """place each square plateau at the candidate maximising min-distance to the
    placed centres, >= SCATTER_MIN apart (relax by 2/4 then 0). Returns
    (rooms=[(x0,y0,inner)], centers=[(cr,cc)])."""
    cands = [(ax, ay) for ay in range(1, CANVAS, GRID_STEP)
             for ax in range(1, CANVAS, GRID_STEP)]
    rng.shuffle(cands)
    placed, centers, rooms = [], [], []
    for inner in inners:
        best = None
        for thresh in (SCATTER_MIN, SCATTER_MIN - 2, SCATTER_MIN - 4, 0.0):
            pick, pick_d, pick_c = None, -1.0, None
            for (ax, ay) in cands:
                x1, y1 = ax + inner - 1, ay + inner - 1
                if ax < 1 or ay < 1 or x1 > CANVAS - 2 or y1 > CANVAS - 2:
                    continue
                if _overlaps((ax, ay, x1, y1), placed, pad=1):
                    continue
                cen = (ay + inner // 2, ax + inner // 2)
                d = (min(math.hypot(cen[0] - pc[0], cen[1] - pc[1])
                         for pc in centers) if centers else float("inf"))
                if d >= thresh and d > pick_d:
                    pick, pick_d, pick_c = (ax, ay, x1, y1), d, cen
            if pick:
                best = (pick, pick_c)
                break
        if best is None:
            raise RuntimeError("gen_erosion: could not fit a plateau on the canvas")
        (x0, y0, x1, y1), cen = best
        placed.append((x0, y0, x1, y1))
        centers.append(cen)
        rooms.append((x0, y0, inner))
    return rooms, centers


# ── step 3: the valleys (A* least-cost over the terrain, water's route) ──────

def _astar(hf, start, target):
    """least-cost 4-neighbour path; cost of ENTERING a cell = 1 + HEIGHT_COST*
    height(cell). Manhattan heuristic (admissible, step cost >= 1). Deterministic:
    a monotone counter breaks heap ties so no coordinate comparison is needed."""
    if start == target:
        return [start]
    tr, tc = target
    openh = []
    cnt = 0
    heapq.heappush(openh, (abs(start[0] - tr) + abs(start[1] - tc), cnt, start))
    g = {start: 0.0}
    came = {}
    while openh:
        _, _, cur = heapq.heappop(openh)
        if cur == target:
            break
        cr, cc = cur
        gc = g[cur]
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nr, nc = cr + dr, cc + dc
            if not (0 <= nr < CANVAS and 0 <= nc < CANVAS):
                continue
            ng = gc + 1.0 + HEIGHT_COST * hf[nr][nc]
            nb = (nr, nc)
            if ng < g.get(nb, float("inf")):
                g[nb] = ng
                came[nb] = cur
                cnt += 1
                heapq.heappush(openh, (ng + abs(nr - tr) + abs(nc - tc), cnt, nb))
    if target not in came:
        return [start, target]              # defensive — grid is always connected
    path, c = [target], target
    while c != start:
        c = came[c]
        path.append(c)
    path.reverse()
    return path


def _carve(valley: set, path, radius: int):
    """lay the path as floor, widened to a Manhattan disk of the given radius
    (radius 1 -> a 3-wide corridor along a 4-connected path)."""
    for (r, c) in path:
        for dr in range(-radius, radius + 1):
            span = radius - abs(dr)
            for dc in range(-span, span + 1):
                nr, nc = r + dr, c + dc
                if 0 <= nr < CANVAS and 0 <= nc < CANVAS:
                    valley.add((nr, nc))


# ── step 4: the relief (berms bank the high-noise floor edges) ───────────────

def _berms(floor: set, hf) -> set:
    """non-floor cells flanking the floor (8-neighbour) rise to a berm where the
    noise height exceeds BERM_NOISE; elsewhere the floor edge stays open void."""
    berm = set()
    for (r, c) in floor:
        for dr in (-1, 0, 1):
            for dc in (-1, 0, 1):
                if dr == 0 and dc == 0:
                    continue
                nr, nc = r + dr, c + dc
                nb = (nr, nc)
                if nb in floor or nb in berm:
                    continue
                if not (0 <= nr < CANVAS and 0 <= nc < CANVAS):
                    continue
                if hf[nr][nc] > BERM_NOISE:
                    berm.add(nb)
    return berm


# ── the artifact seating (the integration block, shared with gen_ants) ───────

def _place_artifact(layers, integ_of, chosen, x0, y0, cr, cc):
    """self/field stand bare; cube/wrap/plinth/frame get sim_cube housing; the
    rest fall to a staging bed (wall beds hang on the plateau's north row)."""
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


# ── the build ────────────────────────────────────────────────────────────────

def build(seq, name, seed):
    beats, volt = mg.load_mission(seq)
    if not beats:
        print(f"gen_erosion: no beats in baseline for {seq}")
        return 1
    n = min(HERO_CAP, len(beats))            # heroes (beats beyond the cap at depth)

    # 1. resolve the hero casts, size each plateau to its chosen hero footprint
    hero_cast, swaps, inners = [], [], []
    for i in range(n):
        chosen, swapped = mg.resolve_cast(beats[i]["cast"], beats[i].get("alts", []),
                                          8.0, 3.4)
        hero_cast.append(chosen)
        if swapped:
            swaps.append(f"{swapped}->{chosen}")
        inners.append(_inner_for(chosen))

    # voltage pieces -> small plateaus (inner VOLT_INNER); kept in mission order
    volt_cast = [p for p in volt if p]
    kinds = ["hero"] * n + ["volt"] * len(volt_cast)
    casts = hero_cast + volt_cast
    all_inner = inners + [VOLT_INNER] * len(volt_cast)
    hero_ix = list(range(n))
    volt_ix = list(range(n, n + len(volt_cast)))

    # the two deterministic streams (orthogonal: OCTAVES cannot shift the layout)
    noise_rng = random.Random(seed + 101)
    layout_rng = random.Random(seed)

    # 2. the heightfield
    hf = _heightfield(noise_rng)

    # 3a. scatter every plateau (heroes first, then voltage)
    rooms, centers = _scatter(all_inner, layout_rng)

    # 3b. the connection plan: beat-order chain + EXTRA_VALLEYS loops + each
    #     voltage plateau to its NEAREST hero (so every room joins the network)
    conns = [(hero_ix[i], hero_ix[i + 1]) for i in range(n - 1)]
    if n >= 3 and EXTRA_VALLEYS > 0:
        pool = [(i, j) for i in range(n) for j in range(i + 2, n)]
        layout_rng.shuffle(pool)
        conns += pool[:EXTRA_VALLEYS]
    n_extra = len(conns) - max(0, n - 1)
    for vi in volt_ix:
        vc = centers[vi]
        nearest = min(hero_ix, key=lambda hi: math.hypot(vc[0] - centers[hi][0],
                                                         vc[1] - centers[hi][1]))
        conns.append((vi, nearest))

    # 3c. water finds the low route — carve each valley 3-wide
    valley = set()
    radius = max(1, VALLEY_WIDTH // 2)
    for (a, b) in conns:
        _carve(valley, _astar(hf, centers[a], centers[b]), radius)

    # the plateaus are floor; floor = plateaus ∪ valleys
    room_floor = set()
    for (x0, y0, inner) in rooms:
        for r in range(y0, y0 + inner):
            for c in range(x0, x0 + inner):
                room_floor.add((r, c))
    floor = room_floor | valley

    # 4. the relief: berms bank the high-noise floor edges
    berm = _berms(floor, hf)

    # 6a. crop to used cells (floor ∪ berm) + 1 margin (dimensions honest)
    struct_cells = floor | berm
    rows = [p[0] for p in struct_cells]
    cols = [p[1] for p in struct_cells]
    off_r, off_c = min(rows) - 1, min(cols) - 1
    H = (max(rows) - min(rows)) + 3
    W = (max(cols) - min(cols)) + 3
    layers = mp.blank_layers(W, H)
    st = layers["structure"]
    for (r, c) in floor:
        st[r - off_r][c - off_c] = SEA
    for (r, c) in berm:
        rr, cc = r - off_r, c - off_c
        if 0 <= rr < H and 0 <= cc < W and st[rr][cc] == "0":
            st[rr][cc] = BERM
    rooms_t = [(x0 - off_c, y0 - off_r, inner) for (x0, y0, inner) in rooms]
    centers_t = [(r - off_r, c - off_c) for (r, c) in centers]

    # 5. the walls — floor cells facing VOID carry the wall; floor facing a BERM
    #    carries none (the berm IS the bank), floor facing floor is open
    for r in range(H):
        for c in range(W):
            if st[r][c] != SEA:
                continue
            for dr, dc, code in ((-1, 0, "n"), (0, 1, "e"), (1, 0, "s"), (0, -1, "w")):
                nr, nc = r + dr, c + dc
                if not (0 <= nr < H and 0 <= nc < W) or st[nr][nc] == "0":
                    mp.wall(layers, r, c, code)

    # 6b. the heroes and voltage stand on their plateaus (integration block)
    integ_of = mg._integration()
    for idx in range(len(rooms_t)):
        x0, y0, inner = rooms_t[idx]
        cr, cc = centers_t[idx]
        _place_artifact(layers, integ_of, casts[idx], x0, y0, cr, cc)

    # 8. spawn on the first hero plateau, exit on the last hero plateau corner
    x0, y0, inner0 = rooms_t[hero_ix[0]]
    cr0, cc0 = centers_t[hero_ix[0]]
    spawn_cell = None
    for dr, dc in ((0, 2), (2, 0), (0, -2), (-2, 0), (2, 2), (-2, -2), (0, 0)):
        r, c = cr0 + dr, cc0 + dc
        if 0 <= r < H and 0 <= c < W and st[r][c] == SEA \
                and layers["interactables"][r][c] == " ":
            spawn_cell = (r, c)
            break
    if spawn_cell is None:
        spawn_cell = (cr0, cc0)
    xL, yL, innerL = rooms_t[hero_ix[-1]]
    exit_cell = (yL + innerL - 2, xL + innerL - 2)
    assert st[spawn_cell[0]][spawn_cell[1]] == SEA, "spawn not on floor"
    assert st[exit_cell[0]][exit_cell[1]] == SEA, "exit not on floor"
    # reserve them so the supporting cast respects the occupancy
    layers["utilities"][spawn_cell[0]][spawn_cell[1]] = "s"
    layers["utilities"][exit_cell[0]][exit_cell[1]] = "t:restart"

    # 6c. the supporting cast staffs the roomy hero plateaus (inner >= 8)
    n_acts = (n + 2) // 3

    def register_of(a):
        if a == 0:
            return "arrival"
        return "depth" if a == n_acts - 1 else "work"

    slots = []
    for j, idx in enumerate(hero_ix):
        x0, y0, inner = rooms_t[idx]
        if inner < 8:
            continue
        slots.append({"act": j // 3, "kind": "beat", "cast": casts[idx],
                      "oy": y0 + 1, "ox": x0 + 1, "F": inner - 2})
    staffed = mg.staff_supporting_cast(layers, slots, mg._bench_library(seq), register_of)
    kept = []
    for s in staffed:
        r, c = s["cell"]
        if layers["structure"][r][c] == SEA:
            kept.append(s)
        else:
            layers["interactables"][r][c] = " "     # never a bench on void/berm
    staffed = kept

    # 7. palette bands — three horizontal thirds (arrival / work / depth)
    t1, t2 = H // 3, 2 * H // 3
    bands = [{"rect": [0, 0, W - 1, t1 - 1], "register": "arrival"},
             {"rect": [0, t1, W - 1, t2 - 1], "register": "work"},
             {"rect": [0, t2, W - 1, H - 1], "register": "depth"}]

    # the mission metadata (strategy facts for the verdict loop)
    mission = {"beats": n, "rooms": len(rooms_t), "octaves": OCTAVES,
               "valley_cells": len(valley), "berm_cells": len(berm),
               "approach": "flat", "seed": seed, "swaps": swaps,
               "supporting_cast": staffed}

    # the contract — dimensions/settings/palettes/spawn/exit/wall runs/props
    mp.finish(name, seq, "erosion-valleys", layers, mission, bands,
              spawn=spawn_cell, exit_cell=exit_cell, lod_radius=14.0)

    # the report — plateau rects + the valley/berm cell counts
    print(f"{name}: {n} heroes + {len(volt_cast)} voltage -> {len(rooms_t)} plateaus, "
          f"{len(conns)} valleys ({n - 1} chain + {n_extra} loop + {len(volt_ix)} volt) "
          f"-> {W}x{H} cells (canvas {CANVAS}, cropped)")
    print(f"  heightfield: {OCTAVES} octaves; floor cells {len(floor)}; "
          f"valley cells {len(valley)}; berm cells {len(berm)}; approach=flat")
    for i in range(len(rooms_t)):
        x0, y0, inner = rooms_t[i]
        print(f"  plateau {i + 1:2d} [{kinds[i]:4s}] <{casts[i]}>  "
              f"rect=[x{x0},y{y0},{inner}x{inner}]")
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
    name = arg("name", f"MissionErosion_{seq.title().replace('_', '')}")
    return build(seq, name, seed)


if __name__ == "__main__":
    sys.exit(main())
