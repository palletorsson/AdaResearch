#!/usr/bin/env python3
"""gen_flocking.py — the FLOCKING ROOMS strategy (Palle's principal).

Palle: "rooms are BOIDS. Separation is the layout force." Each beat's room is
an agent on a continuous plane; the map falls out of a flock relaxation:

  separation  the LAYOUT force — rooms repel inside r_sep = (s_i+s_j)/2 + 3
              (the honest aisle); strong. Nothing overlaps; spacing is exact.
  cohesion    toward SEQUENCE NEIGHBOURS only — room i is pulled to i-1/i+1,
              so the walk order becomes physical adjacency (chapters cluster);
              medium.
  alignment   weak +x drift scaled by teaching index, so the flock ELONGATES
              along the teaching order instead of balling up.

The separation/cohesion tension IS the map: too much separation -> archipelago;
too much cohesion -> one clump. The readable middle — clustered-but-spaced
rooms along the walk — is the design space. Run N seeded steps from a random
scatter, FREEZE, snap to the integer grid, resolve residual overlap. Fill each
rect with SEA; bridge sequence neighbours (straight gate where they nearly
touch, else an L-corridor) plus one seeded loop; one boundary pass grows the
walls, and doors emerge where corridors meet rooms.

A STRATEGY file (tools/gen_*.py): it only invents the FLOOR IDEA and calls
map_principal.finish for every shared layer (dimensions/settings/palettes/
spawn/exit/wall runs/props). The wild strategy, the standard meeting point.

DETERMINISM: one random.Random(seed), drawn in a fixed order (scatter start ->
extra loop pick). The relaxation itself is pure (forces are a function of
positions), so same seed -> byte-identical map. Connectivity is guaranteed by
construction: the sequence chain wires every room into one path, and every
corridor is carved through SEA room interiors so it cannot strand floor.

Usage:
  python tools/gen_flocking.py --seq=randomness [--seed=7] [--name=MissionFlock_Randomness]
  python tools/gen_flocking.py --seq=lsystems
"""
import math
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

import map_principal as mp        # THE finisher — must call mp.finish
import mission_graph as mg        # load_mission/resolve_cast/_cast_cells/integration/staff/bench
import staging_beds as sb         # select_bed (the marriage-1 body)

SEA = mg.SEA                      # "2" — the walkable floor height
PLANE = 72.0                     # the continuous flocking plane (~72x72)
STEPS = 200                      # seeded relaxation steps
MAX_HEROES = 9                   # up to ~9 heroes

# the three forces (separation strong, cohesion medium, alignment weak) — the
# whole design lives in this ratio. Tuned so sequence neighbours settle at the
# honest aisle (~0.83 r_sep) and the flock reads clustered-but-spaced.
SEP = 0.11                       # the LAYOUT force (repel below r_sep)
COH = 0.021                      # cohesion toward sequence neighbours
ALIGN = 0.003                    # weak +x elongation, scaled by teaching index
DAMP = 0.86                      # velocity damping per step
AISLE = 3                        # the honest gap baked into r_sep

VOLT_SIZE = 6                    # voltage rooms are SMALL
ROOM_MIN, ROOM_MAX = 7, 14       # beat room size clamp (hero_cells + 4)


# ── the mission: beats + voltage as an ordered ROOM list ─────────────────────

def _room_list(seq):
    """the ordered rooms: up to ~9 beat heroes (cast resolved), each voltage
    piece inserted as a SMALL room after its spread-out target beat."""
    beats, volt = mg.load_mission(seq)
    if not beats:
        return None, None, None
    n = min(MAX_HEROES, len(beats))
    rooms, swaps = [], []
    for i in range(n):
        chosen, swapped = mg.resolve_cast(beats[i]["cast"], beats[i].get("alts", []),
                                          8.0, 3.4)
        if swapped:
            swaps.append(f"{swapped}->{chosen}")
        s = max(ROOM_MIN, min(ROOM_MAX, mg._cast_cells(chosen) + 4))
        rooms.append({"kind": "beat", "ord": i, "cast": chosen, "s": s})
    # voltage k attaches to its spread-out target beat (same rule as the halls)
    for k, piece in enumerate(volt):
        t = round(k * (n - 1) / max(1, len(volt) - 1)) if len(volt) > 1 else n // 2
        t = max(0, min(n - 1, t))
        for j, e in enumerate(rooms):
            if e["kind"] == "beat" and e["ord"] == t:
                rooms.insert(j + 1, {"kind": "voltage", "ord": None,
                                     "cast": piece, "s": VOLT_SIZE})
                break
    for e in rooms:
        e["inner"] = e["s"] - 2
    return rooms, n, swaps


# ── step 2: rooms as boids (separation / cohesion / alignment) ───────────────

def _flock(rooms, rng):
    """N seeded relaxation steps from a random scatter. Returns float centres."""
    N = len(rooms)
    sizes = [e["s"] for e in rooms]
    lo, hi = PLANE * 0.22, PLANE * 0.78
    pos = [[rng.uniform(lo, hi), rng.uniform(lo, hi)] for _ in range(N)]
    vel = [[0.0, 0.0] for _ in range(N)]
    mid = (N - 1) / 2.0
    for _step in range(STEPS):
        force = [[0.0, 0.0] for _ in range(N)]
        for i in range(N):
            fx = fy = 0.0
            # SEPARATION (strong): repel from every room inside r_sep
            for j in range(N):
                if j == i:
                    continue
                dx = pos[i][0] - pos[j][0]
                dy = pos[i][1] - pos[j][1]
                d = math.hypot(dx, dy)
                r_sep = (sizes[i] + sizes[j]) / 2.0 + AISLE
                if d > 1e-6:
                    if d < r_sep:
                        mag = SEP * (r_sep - d)
                        fx += mag * dx / d
                        fy += mag * dy / d
                else:                       # coincident — deterministic split
                    fx += SEP * (1.0 if i > j else -1.0)
            # COHESION (medium): toward sequence neighbours i-1, i+1 only
            for j in (i - 1, i + 1):
                if 0 <= j < N:
                    fx += COH * (pos[j][0] - pos[i][0])
                    fy += COH * (pos[j][1] - pos[i][1])
            # ALIGNMENT (weak): +x drift scaled by teaching index (elongate)
            fx += ALIGN * (i - mid)
            force[i] = [fx, fy]
        for i in range(N):
            vel[i][0] = (vel[i][0] + force[i][0]) * DAMP
            vel[i][1] = (vel[i][1] + force[i][1]) * DAMP
            pos[i][0] += vel[i][0]
            pos[i][1] += vel[i][1]
    return pos


# ── step 2b: freeze -> snap -> resolve residual overlap ──────────────────────

def _snap(rooms, pos):
    """snap each float centre to an integer rect (world coords, may be < 0)."""
    rects = []
    for e, (cx, cy) in zip(rooms, pos):
        s = e["s"]
        x0 = int(round(cx - s / 2.0))
        y0 = int(round(cy - s / 2.0))
        rects.append([x0, y0, x0 + s - 1, y0 + s - 1])
    return rects


def _resolve(rects):
    """nudge apart any rects closer than a 1-cell gap, along the minimum-
    translation axis, pushing the higher-index rect (deterministic order)."""
    N = len(rects)
    for _pass in range(200):
        moved = False
        for i in range(N):
            for j in range(i + 1, N):
                xi0, yi0, xi1, yi1 = rects[i]
                xj0, yj0, xj1, yj1 = rects[j]
                sep_x = max(xi0, xj0) - min(xi1, xj1) - 1   # empty cols between
                sep_y = max(yi0, yj0) - min(yi1, yj1) - 1   # empty rows between
                if sep_x >= 1 or sep_y >= 1:
                    continue                                # gap in some axis: ok
                need_x = 1 - sep_x
                need_y = 1 - sep_y
                ci = (xi0 + xi1) / 2.0
                cj = (xj0 + xj1) / 2.0
                ri = (yi0 + yi1) / 2.0
                rj = (yj0 + yj1) / 2.0
                if need_x <= need_y:                        # push along x
                    dirn = 1 if cj >= ci else -1
                    rects[j][0] += dirn * need_x
                    rects[j][2] += dirn * need_x
                else:                                       # push along y
                    dirn = 1 if rj >= ri else -1
                    rects[j][1] += dirn * need_y
                    rects[j][3] += dirn * need_y
                moved = True
        if not moved:
            break
    return rects


# ── step 3: the corridors (straight gate when near-touching, else L) ─────────

def _gap_and_axis(a, b):
    """(sep_x, sep_y) empty-cell gaps between rects a and b (neg = overlap)."""
    ax0, ay0, ax1, ay1 = a
    bx0, by0, bx1, by1 = b
    sep_x = max(ax0, bx0) - min(ax1, bx1) - 1
    sep_y = max(ay0, by0) - min(ay1, by1) - 1
    return sep_x, sep_y


def _carve_gate(sea, a, b, sep_x, sep_y):
    """straight 3-wide gate at the facing midpoint. Returns True if carved."""
    ax0, ay0, ax1, ay1 = a
    bx0, by0, bx1, by1 = b
    if sep_y < 1 and 0 <= sep_x <= 2:               # side by side -> vertical gate
        ov0, ov1 = max(ay0, by0), min(ay1, by1)     # shared rows
        ym = (ov0 + ov1) // 2
        rows = [r for r in (ym - 1, ym, ym + 1) if ov0 <= r <= ov1]
        c_lo = min(ax1, bx1) + 1
        c_hi = max(ax0, bx0) - 1
        for c in range(c_lo, c_hi + 1):
            for r in rows:
                sea.add((r, c))
        return True
    if sep_x < 1 and 0 <= sep_y <= 2:               # stacked -> horizontal gate
        ov0, ov1 = max(ax0, bx0), min(ax1, bx1)     # shared cols
        xm = (ov0 + ov1) // 2
        cols = [c for c in (xm - 1, xm, xm + 1) if ov0 <= c <= ov1]
        r_lo = min(ay1, by1) + 1
        r_hi = max(ay0, by0) - 1
        for r in range(r_lo, r_hi + 1):
            for c in cols:
                sea.add((r, c))
        return True
    return False


def _carve_L(sea, a, b):
    """3-wide L-corridor (x-first elbow) between the two rect centres. Centres
    are inside SEA rooms, so the corridor always joins both."""
    acr = (a[1] + a[3]) // 2
    acc = (a[0] + a[2]) // 2
    bcr = (b[1] + b[3]) // 2
    bcc = (b[0] + b[2]) // 2
    for c in range(min(acc, bcc), max(acc, bcc) + 1):        # horizontal first
        for r in (acr - 1, acr, acr + 1):
            sea.add((r, c))
    for r in range(min(acr, bcr), max(acr, bcr) + 1):        # then vertical
        for c in (bcc - 1, bcc, bcc + 1):
            sea.add((r, c))


def _connect(sea, a, b):
    """bridge rects a,b: a straight gate if within 2 cells of touching, else L."""
    sep_x, sep_y = _gap_and_axis(a, b)
    if not _carve_gate(sea, a, b, sep_x, sep_y):
        _carve_L(sea, a, b)


# ── the build ────────────────────────────────────────────────────────────────

def build(seq, name, seed):
    rooms, n, swaps = _room_list(seq)
    if rooms is None:
        print(f"gen_flocking: no beats in baseline for {seq}")
        return 1
    N = len(rooms)

    rng = random.Random(seed)              # the ONLY randomness — fixed draw order

    # 2. rooms as boids, then freeze -> snap -> resolve overlap
    pos = _flock(rooms, rng)               # (scatter start consumes rng first)
    rects = _resolve(_snap(rooms, pos))

    # 3. floor: every room rect is SEA; corridors join sequence neighbours
    sea = set()
    for (x0, y0, x1, y1) in rects:
        for r in range(y0, y1 + 1):
            for c in range(x0, x1 + 1):
                sea.add((r, c))
    for i in range(N - 1):
        _connect(sea, rects[i], rects[i + 1])
    # + one seeded extra loop connection (a non-adjacent pair -> a cycle)
    n_conn = N - 1
    if N >= 3:
        pool = [(i, j) for i in range(N) for j in range(i + 2, N)]
        a, b = pool[rng.randrange(len(pool))]
        _connect(sea, rects[a], rects[b])
        n_conn += 1

    # crop to used cells + 1 margin (dimensions honest)
    rs = [p[0] for p in sea]
    cs = [p[1] for p in sea]
    off_r, off_c = min(rs) - 1, min(cs) - 1
    H = (max(rs) - min(rs)) + 3
    W = (max(cs) - min(cs)) + 3
    layers = mp.blank_layers(W, H)
    st = layers["structure"]
    for (r, c) in sea:
        st[r - off_r][c - off_c] = SEA
    # rooms in cropped coords: (tx0, ty0, tx1, ty1) + centre (row, col)
    trects, tcent = [], []
    for (x0, y0, x1, y1) in rects:
        tx0, ty0, tx1, ty1 = x0 - off_c, y0 - off_r, x1 - off_c, y1 - off_r
        trects.append((tx0, ty0, tx1, ty1))
        tcent.append(((ty0 + ty1) // 2, (tx0 + tx1) // 2))

    # 4. walls: one boundary pass — a floor cell walls each side facing void
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

    # 5. heroes centred per room (the integration block: self/field bare;
    # cube/wrap/plinth/frame -> sim_cube; else a staging bed)
    integ_of = mg._integration()
    for i, e in enumerate(rooms):
        (tx0, ty0, tx1, ty1) = trects[i]
        cr, cc = tcent[i]
        chosen = e["cast"]
        integ, cfam = integ_of.get(chosen, (None, None))
        if integ in ("self", "field"):
            layers["interactables"][cr][cc] = chosen
        elif integ in ("cube", "wrap", "plinth", "frame"):
            fam = cfam if integ in ("cube", "wrap") else integ
            layers["interactables"][cr][cc] = f"sim_cube#family:{fam}#mount:{chosen}"
        else:
            bed = sb.select_bed(chosen)
            if bed["is_wall"]:
                layers["interactables"][ty0 + 1][cc] = f"{bed['bed']}:180#mount:{chosen}"
            else:
                layers["interactables"][cr][cc] = f"{bed['bed']}#mount:{chosen}"

    # 6. spawn on the first room; exit t:restart on the last room
    fr, fc = tcent[0]
    spawn_cell = None
    for dr, dc in ((0, 2), (2, 0), (0, -2), (-2, 0), (2, 2), (-2, -2), (0, 1), (1, 0)):
        r, c = fr + dr, fc + dc
        if 0 <= r < H and 0 <= c < W and st[r][c] == SEA \
                and layers["interactables"][r][c] == " ":
            spawn_cell = (r, c)
            break
    if spawn_cell is None:
        spawn_cell = (fr, fc)
    lx0, ly0, lx1, ly1 = trects[N - 1]
    exit_cell = None
    for (r, c) in ((ly1 - 1, lx1 - 1), (ly0 + 1, lx1 - 1), (ly1 - 1, lx0 + 1),
                   (ly0 + 1, lx0 + 1), (ly1 - 1, lx1)):
        if 0 <= r < H and 0 <= c < W and st[r][c] == SEA \
                and layers["interactables"][r][c] == " " and (r, c) != spawn_cell:
            exit_cell = (r, c)
            break
    if exit_cell is None:
        exit_cell = ((ly0 + ly1) // 2, (lx0 + lx1) // 2)
    assert st[spawn_cell[0]][spawn_cell[1]] == SEA, "spawn not on floor"
    assert st[exit_cell[0]][exit_cell[1]] == SEA, "exit not on floor"
    # reserve them so the supporting cast respects occupancy
    layers["utilities"][spawn_cell[0]][spawn_cell[1]] = "s"
    layers["utilities"][exit_cell[0]][exit_cell[1]] = "t:restart"

    # 5b. supporting cast — same-domain benches on the roomy beat rooms only
    n_acts = (n + 2) // 3

    def register_of(a):
        if a == 0:
            return "arrival"
        return "depth" if a == n_acts - 1 else "work"

    slots = [{"act": e["ord"] // 3, "kind": "beat", "cast": e["cast"],
              "oy": trects[i][1] + 1, "ox": trects[i][0] + 1, "F": e["inner"]}
             for i, e in enumerate(rooms)
             if e["kind"] == "beat" and e["inner"] >= 8]
    staffed = mg.staff_supporting_cast(layers, slots, mg._bench_library(seq), register_of)
    kept = []
    for s in staffed:
        r, c = s["cell"]
        if layers["structure"][r][c] == SEA:
            kept.append(s)
        else:
            layers["interactables"][r][c] = " "     # never a bench on void
    staffed = kept

    # 7. palette bands — three horizontal thirds (arrival / work / depth)
    t1, t2 = H // 3, 2 * H // 3
    bands = [{"rect": [0, 0, W - 1, t1 - 1], "register": "arrival"},
             {"rect": [0, t1, W - 1, t2 - 1], "register": "work"},
             {"rect": [0, t2, W - 1, H - 1], "register": "depth"}]

    # the mission metadata (strategy facts for the verdict loop)
    mission = {"beats": n,
               "rooms": [{"cast": e["cast"],
                          "rect": [trects[i][0], trects[i][1], e["s"], e["s"]],
                          "inner": e["inner"]} for i, e in enumerate(rooms)],
               "steps": STEPS, "forces": {"sep": SEP, "coh": COH, "align": ALIGN},
               "connections": n_conn, "seed": seed, "swaps": swaps,
               "supporting_cast": staffed}

    # the contract — dimensions/settings/palettes/spawn/exit/wall runs/props
    mp.finish(name, seq, "flocking-rooms", layers, mission, bands,
              spawn=spawn_cell, exit_cell=exit_cell, lod_radius=14.0)

    # report — the room rects (so clustered-but-spaced is checkable) + floor count
    n_volt = sum(1 for e in rooms if e["kind"] == "voltage")
    print(f"{name}: {n} heroes + {n_volt} voltage = {N} rooms, {n_conn} connections "
          f"-> {W}x{H} cells (plane {int(PLANE)}, {STEPS} steps)")
    print(f"  floor cells total: {len(sea)}  (target < 1800)")
    print(f"  forces: sep={SEP} coh={COH} align={ALIGN} damp={DAMP}")
    for i, e in enumerate(rooms):
        tx0, ty0, tx1, ty1 = trects[i]
        tag = "volt" if e["kind"] == "voltage" else f"beat{e['ord']}"
        print(f"  room {i + 1:2d} [{tag:5s}] <{e['cast']:26s}> "
              f"rect=[x{tx0},y{ty0},s{e['s']}] inner={e['inner']}")
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
    name = arg("name", f"MissionFlock_{seq.title().replace('_', '')}")
    return build(seq, name, seed)


if __name__ == "__main__":
    sys.exit(main())
