#!/usr/bin/env python3
"""gen_physarum.py — the PHYSARUM TRUNKS strategy (Palle's principal).

Palle: "perfect close rooms; slime-mould agents find the circulation; corridor
width follows flow." The rooms-first family's strongest network-finder. Rooms
are declared (footprint + breathing margin); the SPACE BETWEEN is searched by a
classic Jones-model slime mould — agents sense a trail field ahead / +-22.5deg,
turn toward the strongest, step, deposit; the field diffuses and decays each
step; room centres emit food. Over ~400 steps the agents converge to efficient
TRUNK networks with loops (the Tokyo-rail experiment at map scale).

Emergence married to a guarantee: after the sim, every beat-order pair (i, i+1)
is joined by an A* whose cost is 1/(0.2 + normalized trail) — the least-cost
walk FOLLOWS the slime trunks, so the discovered network carries the connectiv-
ity, but the walk order is never left to chance. Corridor width then follows
flow: path cells on strong trail become 4-wide TRUNKS, the rest 2-wide TWIGS,
and the very strongest veins (>=92nd pct) show as floor even off the path. The
width hierarchy IS the wayfinding.

  rooms      -> perfect close    footprint + 4 (min 7, cap 14), scattered
  physarum   -> the circulation  120 agents, 400 steps, seeded, deterministic
  A*         -> the guarantee    trail-cost path per beat pair -> always walkable
  width      -> the wayfinding   trunk 4-wide / twig 2-wide / vein floor
  finish     -> curation         dimensions/settings/palettes/spawn/exit/runs

A STRATEGY file (tools/gen_*.py): it only invents the floor idea and calls
map_principal.finish for every shared layer.

DETERMINISM: one random.Random(seed), drawn in a fixed order (room scatter ->
agent headings). The sim's motor/sensor/diffuse stages are pure functions of the
field (no rng); A* tie-breaks on an insertion counter. Same seed, same machine
-> byte-identical map. Connectivity is guaranteed by construction: cost is
finite on every cell, so the A* between consecutive rooms always exists and is
carved wide enough to walk.

Usage:
  python tools/gen_physarum.py --seq=randomness [--seed=7] [--name=MissionPhysarum_Randomness]
  python tools/gen_physarum.py --seq=lsystems
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
CANVAS = 64                      # working canvas (~64); cropped honest before finish

# ── the slime mould (classic Jones model) ───────────────────────────────────
AGENTS = 120                     # the finding — 120 agents released between rooms
STEPS = 400                      # the run — 400 sense/move/deposit/diffuse steps
SENSE_DIST = 3                   # probe distance ahead
SENSE_ANGLE = math.radians(22.5)  # the +-22.5deg side probes
TURN_ANGLE = math.radians(22.5)  # rotate toward the strongest probe
DECAY = 0.92                     # trail field decay per step
AGENT_DEPOSIT = 1.0              # trail laid on each stepped cell
FOOD = 8.0                       # constant emitted at each room centre per step

# ── width hierarchy ──────────────────────────────────────────────────────────
TRUNK_PCTL = 60.0                # path cells >= this pct (of path trail) -> trunk
VEIN_PCTL = 92.0                 # any cell >= this pct (of the field) -> floor
TRUNK_W = 4                      # trunk corridor width
TWIG_W = 2                       # twig corridor width (min walkable)


# ── the room (perfect close) ─────────────────────────────────────────────────

def _hero_cells(name: str) -> int:
    """honest max grid-cell side of a cast (default 2 when unmeasured)."""
    s = mg._sizes().get(name, {}) or {}
    gc = s.get("grid_cells") or [2, 2]
    return max(2, int(round(max(float(gc[0]), float(gc[1])))))


def _inner(hero_cells: int) -> int:
    """room inner = hero footprint + 4 cells of breathing (min 7, cap 14)."""
    return min(14, max(7, hero_cells + 4))


def _overlaps(rect, placed, pad):
    x0, y0, x1, y1 = rect
    for (px0, py0, px1, py1) in placed:
        if not (x1 + pad < px0 or px1 + pad < x0
                or y1 + pad < py0 or py1 + pad < y0):
            return True
    return False


def _place_rooms(inners, rng):
    """scatter square rooms by max-min-distance greedy: each room lands at the
    seeded-shuffled candidate that maximises min-distance to placed centres,
    >= 12 apart (relax 10/8/0). Perfect close — 2-void pad between rects."""
    cands = [(ax, ay) for ay in range(1, CANVAS, 3) for ax in range(1, CANVAS, 3)]
    rng.shuffle(cands)
    placed, centers, rooms = [], [], []
    for s in inners:
        best = None
        for thresh in (12.0, 10.0, 8.0, 0.0):
            pick, pick_d, pick_c = None, -1.0, None
            for (ax, ay) in cands:
                x1, y1 = ax + s - 1, ay + s - 1
                if ax < 1 or ay < 1 or x1 > CANVAS - 2 or y1 > CANVAS - 2:
                    continue
                if _overlaps((ax, ay, x1, y1), placed, pad=2):
                    continue
                cen = (ay + s // 2, ax + s // 2)
                d = (min(math.hypot(cen[0] - pc[0], cen[1] - pc[1])
                         for pc in centers) if centers else float("inf"))
                if d >= thresh and d > pick_d:
                    pick, pick_d, pick_c = (ax, ay, x1, y1), d, cen
            if pick:
                best = (pick, pick_c, s)
                break
        if best is None:
            raise RuntimeError("gen_physarum: could not fit a room on the canvas")
        (x0, y0, x1, y1), cen, s = best
        placed.append((x0, y0, x1, y1))
        centers.append(cen)
        rooms.append((x0, y0, s))
    return rooms, centers


# ── the sim (the trunk finder) ───────────────────────────────────────────────

def _diffuse(field, W, H, inv9, decay):
    """3x3 mean * decay, done as a separable box blur with edge replication —
    two 3-tap passes built with zip/comprehension so it runs at C speed."""
    hs = []
    for r in range(H):
        row = field[r]
        left = [row[0]]
        left.extend(row[:W - 1])
        right = row[1:]
        right.append(row[W - 1])
        hs.append([a + b + c for a, b, c in zip(left, row, right)])
    out = []
    fac = inv9 * decay
    for r in range(H):
        up = hs[r - 1] if r > 0 else hs[0]
        mid = hs[r]
        dn = hs[r + 1] if r < H - 1 else hs[H - 1]
        out.append([(u + m + d) * fac for u, m, d in zip(up, mid, dn)])
    return out


def _physarum(centers, rng):
    """release AGENTS across the room centres; run the Jones model STEPS times.
    Returns the trail field (H x W floats). Deterministic: the only rng is the
    per-agent initial heading; sensing/turning/diffusion are pure."""
    W = H = CANVAS
    field = [[0.0] * W for _ in range(H)]
    inv9 = 1.0 / 9.0
    n = len(centers)
    # agents: [x(col), y(row), heading] spawned at the room centres, heading rng
    agents = []
    for i in range(AGENTS):
        crow, ccol = centers[i % n]
        agents.append([float(ccol), float(crow), rng.uniform(0.0, 2.0 * math.pi)])

    def sense(x, y, a):
        px = x + SENSE_DIST * math.cos(a)
        py = y + SENSE_DIST * math.sin(a)
        ci = int(round(px))
        cj = int(round(py))
        if 0 <= cj < H and 0 <= ci < W:
            return field[cj][ci]
        return -1.0                              # off-canvas: strongly avoid

    for _step in range(STEPS):
        for ag in agents:
            x, y, th = ag
            sl = sense(x, y, th - SENSE_ANGLE)
            sc = sense(x, y, th)
            sr = sense(x, y, th + SENSE_ANGLE)
            if sc >= sl and sc >= sr:
                pass                             # straight on the strongest
            elif sl > sr:
                th -= TURN_ANGLE
            else:
                th += TURN_ANGLE
            dx = math.cos(th)
            dy = math.sin(th)
            nx = x + dx
            ny = y + dy
            if nx < 0.0 or nx > W - 1:           # reflect off the vertical walls
                th = math.pi - th
                nx = x + math.cos(th)
            if ny < 0.0 or ny > H - 1:           # reflect off the horizontal walls
                th = -th
                ny = y + math.sin(th)
            nx = 0.0 if nx < 0.0 else (float(W - 1) if nx > W - 1 else nx)
            ny = 0.0 if ny < 0.0 else (float(H - 1) if ny > H - 1 else ny)
            field[int(round(ny))][int(round(nx))] += AGENT_DEPOSIT
            ag[0], ag[1], ag[2] = nx, ny, th
        for (crow, ccol) in centers:             # the food sources stay bright
            field[crow][ccol] += FOOD
        field = _diffuse(field, W, H, inv9, DECAY)
    return field


# ── the guarantee (A* along the trunks) ──────────────────────────────────────

def _astar(cost, start, goal, W, H):
    """least-cost 4-connected path over cost = 1/(0.2 + norm trail). The path
    FOLLOWS the strongest trail; cost is finite everywhere so it always exists.
    Deterministic: heap ties break on an insertion counter."""
    openh = [(0.0, 0, start)]
    g = {start: 0.0}
    came = {start: None}
    closed = set()
    cnt = 1
    mincost = 1.0 / (0.2 + 1.0)                   # admissible heuristic scale
    gr, gc = goal
    while openh:
        _f, _c, cur = heapq.heappop(openh)
        if cur in closed:
            continue
        closed.add(cur)
        if cur == goal:
            break
        cg = g[cur]
        r, c = cur
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nr, nc = r + dr, c + dc
            if 0 <= nr < H and 0 <= nc < W:
                ng = cg + cost[nr][nc]
                nb = (nr, nc)
                if nb not in g or ng < g[nb]:
                    g[nb] = ng
                    came[nb] = cur
                    h = (abs(nr - gr) + abs(nc - gc)) * mincost
                    heapq.heappush(openh, (ng + h, cnt, nb))
                    cnt += 1
    if goal not in came:
        return []
    path, node = [], goal
    while node is not None:
        path.append(node)
        node = came[node]
    path.reverse()
    return path


def _percentile(vals, p):
    if not vals:
        return 0.0
    s = sorted(vals)
    if len(s) == 1:
        return s[0]
    idx = (p / 100.0) * (len(s) - 1)
    lo = int(math.floor(idx))
    hi = int(math.ceil(idx))
    if lo == hi:
        return s[lo]
    return s[lo] + (s[hi] - s[lo]) * (idx - lo)


def _brush(width):
    lo = -(width // 2)
    return range(lo, lo + width)                  # a width x width square brush


# ── the build ────────────────────────────────────────────────────────────────

def build(seq, name, seed):
    beats, _volt = mg.load_mission(seq)
    if not beats:
        print(f"gen_physarum: no beats in baseline for {seq}")
        return 1
    n = min(8, len(beats))                        # up to ~8 heroes

    # 1. resolve the casts, size each room to its chosen hero's footprint
    casts, swaps, inners = [], [], []
    for i in range(n):
        chosen, swapped = mg.resolve_cast(beats[i]["cast"], beats[i].get("alts", []),
                                          8.0, 3.4)
        casts.append(chosen)
        if swapped:
            swaps.append(f"{swapped}->{chosen}")
        inners.append(_inner(_hero_cells(chosen)))

    rng = random.Random(seed)                     # the ONLY randomness

    # 2. scatter the perfect-close rooms, then release the slime mould
    rooms, centers = _place_rooms(inners, rng)
    field = _physarum(centers, rng)

    # 3. normalize; A* every beat pair along the trunks; collect path cells
    fmax = max(max(row) for row in field) or 1.0
    norm = [[v / fmax for v in row] for row in field]
    cost = [[1.0 / (0.2 + norm[r][c]) for c in range(CANVAS)] for r in range(CANVAS)]
    path_cells = set()
    for i in range(n - 1):                        # the WALK ORDER: i -> i+1
        for cell in _astar(cost, centers[i], centers[i + 1], CANVAS, CANVAS):
            path_cells.add(cell)

    # 4. width follows flow — trunk (>=60th pct of path trail) vs twig
    path_thresh = _percentile([norm[r][c] for (r, c) in path_cells], TRUNK_PCTL)
    trunk_brush, twig_brush = set(), set()
    for (r, c) in path_cells:
        w = TRUNK_W if norm[r][c] >= path_thresh else TWIG_W
        dst = trunk_brush if w == TRUNK_W else twig_brush
        for dr in _brush(w):
            for dc in _brush(w):
                rr, cc = r + dr, c + dc
                if 0 <= rr < CANVAS and 0 <= cc < CANVAS:
                    dst.add((rr, cc))

    # the strongest veins show even off-path (>=92nd pct of the whole field)
    vein_thresh = _percentile([norm[r][c] for r in range(CANVAS)
                               for c in range(CANVAS) if field[r][c] > 0.0], VEIN_PCTL)
    vein_brush = {(r, c) for r in range(CANVAS) for c in range(CANVAS)
                  if norm[r][c] >= vein_thresh}

    # rooms are perfect-close floor plates
    room_floor = set()
    for (x0, y0, s) in rooms:
        for r in range(y0, y0 + s):
            for c in range(x0, x0 + s):
                room_floor.add((r, c))

    floor = room_floor | trunk_brush | twig_brush | vein_brush
    trunk_cells = len(trunk_brush - room_floor)
    twig_cells = len(twig_brush - room_floor - trunk_brush)
    vein_cells = len(vein_brush - room_floor - trunk_brush - twig_brush)

    # 5. crop to used cells + 1 margin (dimensions honest)
    rows = [p[0] for p in floor]
    cols = [p[1] for p in floor]
    off_r, off_c = min(rows) - 1, min(cols) - 1
    H = (max(rows) - min(rows)) + 3
    W = (max(cols) - min(cols)) + 3
    layers = mp.blank_layers(W, H)
    st = layers["structure"]
    for (r, c) in floor:
        st[r - off_r][c - off_c] = SEA
    rooms_t = [(x0 - off_c, y0 - off_r, s) for (x0, y0, s) in rooms]
    centers_t = [(r - off_r, c - off_c) for (r, c) in centers]

    # 6. walls — one boundary pass (the floor/void edge carries the wall code)
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

    # 7. heroes centred per room (the integration block)
    integ_of = mg._integration()
    for i in range(n):
        x0, y0, s = rooms_t[i]
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

    # 8. spawn in the first room (offset off its hero), exit in the last room
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
    xL, yL, sL = rooms_t[n - 1]
    exit_cell = (yL + sL - 2, xL + sL - 2)        # interior corner (floor behind)
    if st[exit_cell[0]][exit_cell[1]] != SEA:
        exit_cell = centers_t[n - 1]
    assert st[spawn_cell[0]][spawn_cell[1]] == SEA, "spawn not on floor"
    assert st[exit_cell[0]][exit_cell[1]] == SEA, "exit not on floor"
    layers["utilities"][spawn_cell[0]][spawn_cell[1]] = "s"
    layers["utilities"][exit_cell[0]][exit_cell[1]] = "t:restart"

    # 9. supporting cast — same-domain benches staff rooms with inner >= 8
    n_acts = (n + 2) // 3

    def register_of(a):
        if a == 0:
            return "arrival"
        return "depth" if a == n_acts - 1 else "work"

    slots = [{"act": i // 3, "kind": "beat", "cast": casts[i],
              "oy": rooms_t[i][1] + 1, "ox": rooms_t[i][0] + 1,
              "F": rooms_t[i][2] - 2}
             for i in range(n) if inners[i] >= 8]
    staffed = mg.staff_supporting_cast(layers, slots, mg._bench_library(seq), register_of)
    kept = []
    for sc in staffed:
        r, c = sc["cell"]
        if layers["structure"][r][c] == SEA:
            kept.append(sc)
        else:
            layers["interactables"][r][c] = " "   # never a bench floating on void
    staffed = kept

    # 10. palette bands — three horizontal thirds (arrival / work / depth)
    t1, t2 = H // 3, 2 * H // 3
    bands = [{"rect": [0, 0, W - 1, t1 - 1], "register": "arrival"},
             {"rect": [0, t1, W - 1, t2 - 1], "register": "work"},
             {"rect": [0, t2, W - 1, H - 1], "register": "depth"}]

    # 11. the mission metadata (strategy facts for the verdict loop)
    mission = {"beats": n,
               "rooms": [{"cast": casts[i], "rect": list(rooms_t[i])} for i in range(n)],
               "agents": AGENTS, "steps": STEPS,
               "trunk_cells": trunk_cells, "twig_cells": twig_cells,
               "seed": seed, "swaps": swaps, "supporting_cast": staffed}

    # the contract — dimensions/settings/palettes/spawn/exit/wall runs/props
    mp.finish(name, seq, "physarum-trunks", layers, mission, bands,
              spawn=spawn_cell, exit_cell=exit_cell, lod_radius=14.0)

    # 12. the report
    print(f"{name}: {n} heroes, {AGENTS} agents x {STEPS} steps "
          f"-> {W}x{H} cells (canvas {CANVAS}, cropped)")
    print(f"  floor cells: {len(floor)}  |  trunk: {trunk_cells}  twig: {twig_cells}  "
          f"vein(off-path): {vein_cells}  |  path cells: {len(path_cells)}")
    for i in range(n):
        x0, y0, s = rooms_t[i]
        print(f"  room {i + 1:2d} <{casts[i]}>  rect=[x{x0},y{y0},{s}x{s}]")
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
    name = arg("name", f"MissionPhysarum_{seq.title().replace('_', '')}")
    return build(seq, name, seed)


if __name__ == "__main__":
    sys.exit(main())
