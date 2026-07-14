#!/usr/bin/env python3
"""gen_lsystem.py — THE L-SYSTEM TRUNK strategy (the grammar grows the map).

Palle (the map strategy family, "grammar-first"): "the turtle path IS the
corridor skeleton — trunk = main walk, branches = side pools, beat rooms attach
at branch TIPS in derivation order (derivation order = walk order = teaching
order). The lsystems chapter literally grows its own habitat."

A bracketed L-system is derived ITERATIONS times (one seeded rule per iteration)
and walked as a GRID TURTLE with 90-degree turns. Every F carves SEG_LEN cells
of 3-wide corridor forward; [ pushes turtle state, ] pops it (ending a branch).
The whole carved path is the corridor skeleton — connected by construction, one
4-connected floor component, because every segment continues from the turtle's
current position and every branch grows out of its parent.

  grammar   -> skeleton   axiom "F" rewritten ITERATIONS times; the turtle draws
                          the corridors (trunk + bracketed side branches)
  collision -> pruning    a branch that would carve within COLLIDE cells of a
                          FOREIGN corridor (not one of its ancestors) STOPS early
                          — grammar-legal pruning keeps the map planar-ish
  tips      -> rooms       the n most-distal branch tips grow beat rooms (inner =
                          hero footprint + 4); voltage chapels hang on side-twigs
  walls     -> after       ONE boundary pass: a wall faces every void; the room
                          and chapel mouths are the doors
  finish    -> curation    dimensions/settings/palettes/spawn/exit/runs/props

A STRATEGY file (tools/gen_*.py): it only invents the floor idea and calls
map_principal.finish for every shared layer. The wild strategy, the standard
meeting point.

DETERMINISM: one random.Random(seed), drawn in a fixed order — ONLY the
ITERATIONS rule selections consume it; everything downstream (turtle, tips,
rooms, chapels, staffing) is a pure function of that derivation. No set/dict
iteration touches the output. Same seed -> byte-identical map.

Usage:
  python tools/gen_lsystem.py --seq=lsystems [--seed=7] [--name=MissionLsys_Lsystems]
  python tools/gen_lsystem.py --seq=randomness --set SEG_LEN=8
"""
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

# ── knobs (the rule box: --set KNOB=value overrides these module constants) ──
ITERATIONS = 3          # grammar derivation depth (F -> ... applied this often)
SEG_LEN = 7             # cells an F carves forward (the corridor is 3-wide)
CANVAS = 72             # the turtle's square region (cropped honest before finish)
COLLIDE = 2             # stop a branch coming within this many cells of a FOREIGN
                        # corridor (not an ancestor) — the grammar-legal prune
EXEMPT = 4              # ...but ignore foreign cells this close to a branch's
                        # birth fork (siblings emanate from the same point)
MIN_INNER = 7           # smallest beat-room inner floor
CAP_INNER = 14          # largest beat-room inner floor
CHAPEL_INNER = 6        # voltage chapel inner floor
MAX_BEATS = 9           # up to ~9 beat rooms
BUDGET_FP = 8.0         # resolve_cast footprint budget (the room hugs its hero)
BUDGET_H = 3.4          # resolve_cast height budget
PAD = 20                # working margin around CANVAS so edge rooms never clip

# the production set — one rule chosen (seeded) per iteration, applied to every
# F at once. Each keeps 3 F's (steady branching) and 1-2 brackets (side pools).
RULESET = ["F[+F]F", "F[-F][+F]", "FF[+F]"]

HEADINGS = [(-1, 0), (0, 1), (1, 0), (0, -1)]   # N E S W (clockwise; + left, - right)


# ── the grammar ──────────────────────────────────────────────────────────────

def _derive(seed):
    """expand the axiom ITERATIONS times, one seeded rule per iteration.
    THE only consumer of randomness — everything after is deterministic."""
    rng = random.Random(seed)
    s = "F"
    rules_used = []
    for _ in range(ITERATIONS):
        rule = RULESET[rng.randrange(len(RULESET))]
        rules_used.append(rule)
        s = "".join(rule if ch == "F" else ch for ch in s)
    return s, rules_used


# ── the grid turtle ──────────────────────────────────────────────────────────

def _region(r, c):
    return PAD <= r < PAD + CANVAS and PAD <= c < PAD + CANVAS


def _cross(r, c, hidx):
    """the 3-wide cross-section at (r,c) perpendicular to the heading."""
    if HEADINGS[hidx][0] != 0:                 # vertical heading -> spread E-W
        return ((r, c - 1), (r, c), (r, c + 1))
    return ((r - 1, c), (r, c), (r + 1, c))    # horizontal heading -> spread N-S


def _carve(cell, hidx, bid, floor, owner):
    for (rr, cc) in _cross(cell[0], cell[1], hidx):
        floor.add((rr, cc))
        if (rr, cc) not in owner:
            owner[(rr, cc)] = bid


def _collides(cand, safe, origin, owner):
    """True if a FOREIGN corridor cell (owner not an ancestor) lies within
    COLLIDE of cand — ignoring foreign cells within EXEMPT of the branch's
    birth fork, where siblings legitimately share the same origin point."""
    er, ec = origin
    for dr in range(-COLLIDE, COLLIDE + 1):
        for dc in range(-COLLIDE, COLLIDE + 1):
            o = owner.get((cand[0] + dr, cand[1] + dc))
            if o is not None and o not in safe:
                if abs(cand[0] + dr - er) + abs(cand[1] + dc - ec) <= EXEMPT:
                    continue
                return True
    return False


def _turtle(deriv):
    """walk the derivation. Returns (floor set, owner map, tips, start). tips =
    ordered (derivation_order, pos, heading) at every branch end that moved."""
    floor, owner = set(), {}
    start = (PAD + CANVAS - 4, PAD + CANVAS // 2)     # center-south, heading N
    pos, hidx, bid, alive = start, 0, 0, True
    origin = {0: start}
    moved = {0: False}
    nxt = 1
    stack = []
    tips, order = [], 0
    for ch in deriv:
        if ch == "F":
            if not alive:
                continue
            safe = {bid} | {fr[2] for fr in stack}   # this branch + its ancestors
            _carve(pos, hidx, bid, floor, owner)     # the corner (segment start)
            dr, dc = HEADINGS[hidx]
            cur = pos
            for _ in range(SEG_LEN):
                cand = (cur[0] + dr, cur[1] + dc)
                if not _region(*cand) or _collides(cand, safe, origin[bid], owner):
                    alive = False                    # STOP the branch early
                    break
                _carve(cand, hidx, bid, floor, owner)
                cur = cand
                moved[bid] = True
            pos = cur
        elif ch == "+":
            hidx = (hidx - 1) % 4                     # turn left
        elif ch == "-":
            hidx = (hidx + 1) % 4                     # turn right
        elif ch == "[":
            stack.append((pos, hidx, bid, alive))
            origin[nxt] = pos                         # the child's birth fork
            moved[nxt] = False
            bid, nxt = nxt, nxt + 1
        elif ch == "]":
            if moved.get(bid) and pos != origin[bid]:
                tips.append((order, pos, hidx))
                order += 1
            pos, hidx, bid, alive = stack.pop()
    if moved.get(bid) and pos != origin[bid]:        # the root branch's own tip
        tips.append((order, pos, hidx))
    return floor, owner, tips, start


def _extend(pos, hidx, floor, owner):
    """straight-extend a tip forward by up to SEG_LEN cells (the deterministic
    'make more tips' move when the grammar yielded fewer branches than rooms)."""
    dr, dc = HEADINGS[hidx]
    cur = pos
    for _ in range(SEG_LEN):
        cand = (cur[0] + dr, cur[1] + dc)
        if not _region(*cand):
            break
        _carve(cand, hidx, -1, floor, owner)
        cur = cand
    return cur


# ── rooms + chapels ──────────────────────────────────────────────────────────

def _hero_cells(name):
    s = mg._sizes().get(name, {}) or {}
    gc = s.get("grid_cells")
    if not gc:
        return 2
    return max(1, int(round(max(float(gc[0]), float(gc[1])))))


def _fill(x0, y0, side, floor):
    for r in range(y0, y0 + side):
        for c in range(x0, x0 + side):
            floor.add((r, c))


def _carve_line(a, b, floor):
    """a 3-wide (plus-shaped) L path from a to b — guarantees a connected twig
    from the beat tip to a chapel that landed on void."""
    r, c = a
    tr, tc = b

    def plus(pr, pc):
        for (rr, cc) in ((pr, pc), (pr - 1, pc), (pr + 1, pc), (pr, pc - 1), (pr, pc + 1)):
            floor.add((rr, cc))

    plus(r, c)
    while r != tr:
        r += 1 if tr > r else -1
        plus(r, c)
    while c != tc:
        c += 1 if tc > c else -1
        plus(r, c)


def _place_hero(layers, st, cr, cc, y0, token, integ_of):
    """the integration block (self/field bare; cube/wrap/plinth/frame -> housing;
    else a staging bed, wall beds hung one row below the room's north wall)."""
    integ, cfam = integ_of.get(token, (None, None))
    if integ in ("self", "field"):
        layers["interactables"][cr][cc] = token
    elif integ in ("cube", "wrap", "plinth", "frame"):
        fam = cfam if integ in ("cube", "wrap") else integ
        layers["interactables"][cr][cc] = f"sim_cube#family:{fam}#mount:{token}"
    else:
        bed = sb.select_bed(token)
        if bed["is_wall"]:
            layers["interactables"][y0 + 1][cc] = f"{bed['bed']}:180#mount:{token}"
        else:
            layers["interactables"][cr][cc] = f"{bed['bed']}#mount:{token}"


# ── the build ────────────────────────────────────────────────────────────────

def build(seq, name, seed):
    beats, volt = mg.load_mission(seq)
    if not beats:
        print(f"gen_lsystem: no beats in baseline for {seq}")
        return 1
    n = min(MAX_BEATS, len(beats))             # up to ~9 heroes (all beats if fewer)

    # 1. resolve the casts (budget_fp 8, h 3.4), size each room to its hero
    casts, swaps, inners = [], [], []
    for i in range(n):
        chosen, swapped = mg.resolve_cast(beats[i]["cast"], beats[i].get("alts", []),
                                          BUDGET_FP, BUDGET_H)
        casts.append(chosen)
        if swapped:
            swaps.append(f"{swapped}->{chosen}")
        inners.append(max(MIN_INNER, min(CAP_INNER, _hero_cells(chosen) + 4)))

    # 2. GRAMMAR: derive, then walk the turtle (the corridor skeleton)
    deriv, rules_used = _derive(seed)
    floor, owner, raw_tips, start = _turtle(deriv)

    # 3. TIPS: dedupe by position, rank by distance from the root; extend the
    # last-derived branches straight if the grammar yielded fewer tips than rooms
    uniq, seen = [], set()
    for (o, pos, h) in raw_tips:
        if pos in seen:
            continue
        seen.add(pos)
        d = abs(pos[0] - start[0]) + abs(pos[1] - start[1])
        uniq.append([o, pos, h, d])
    uniq.sort(key=lambda t: t[0])              # derivation order
    ei = len(uniq) - 1
    while len(uniq) < n and ei >= 0:
        _, pos, h, _ = uniq[ei]
        newpos = _extend(pos, h, floor, owner)
        if newpos != pos and newpos not in seen:
            seen.add(newpos)
            d = abs(newpos[0] - start[0]) + abs(newpos[1] - start[1])
            uniq.append([(uniq[-1][0] + 1), newpos, h, d])
        ei -= 1
    if len(uniq) < n:                          # still short: fewer rooms, honest
        n = len(uniq)
        casts, inners = casts[:n], inners[:n]

    # the n most-distal tips grow the beat rooms; re-order them by derivation
    # (derivation order = walk order = teaching order) for beat assignment
    uniq.sort(key=lambda t: (-t[3], t[0]))
    chosen = uniq[:n]
    chosen.sort(key=lambda t: t[0])
    beat_tips = [(t[1], t[2]) for t in chosen]
    mi = max(range(n), key=lambda i: chosen[i][3]) if n else 0   # the far room = exit

    # 4. rooms at the tips (each room covers its tip -> connected, no door needed)
    rooms = []
    for i, (pos, _h) in enumerate(beat_tips):
        rs = inners[i] + 2
        y0, x0 = pos[0] - rs // 2, pos[1] - rs // 2
        _fill(x0, y0, rs, floor)
        rooms.append((x0, y0, rs))

    # 5. voltage chapels on short side-twigs nearest their target beat's tip
    chapels = []
    cs = CHAPEL_INNER + 2
    G = CANVAS + 2 * PAD
    for k, piece in enumerate(volt):
        if n == 0:
            break
        t = (round(k * (n - 1) / (len(volt) - 1)) if len(volt) > 1 else n // 2)
        t = max(0, min(n - 1, t))
        tp = beat_tips[t][0]
        off = inners[t] // 2 + 3 + cs // 2
        best = None
        for (dr, dc) in ((0, 1), (0, -1), (-1, 0), (1, 0)):
            cy, cx = tp[0] + dr * off, tp[1] + dc * off
            y0, x0 = cy - cs // 2, cx - cs // 2
            if not (0 <= y0 and y0 + cs <= G and 0 <= x0 and x0 + cs <= G):
                continue
            void = sum(1 for r in range(y0, y0 + cs) for c in range(x0, x0 + cs)
                       if (r, c) not in floor)
            if best is None or void > best[0]:
                best = (void, x0, y0, cy, cx)
        if best is None:
            continue
        _, x0, y0, cy, cx = best
        _carve_line(tp, (cy, cx), floor)       # the twig
        _fill(x0, y0, cs, floor)               # the chapel
        chapels.append((x0, y0, cs, piece, t))

    # 6. crop to used cells + 1 margin (dimensions honest)
    rows = [p[0] for p in floor]
    cols = [p[1] for p in floor]
    off_r, off_c = min(rows) - 1, min(cols) - 1
    H = (max(rows) - min(rows)) + 3
    W = (max(cols) - min(cols)) + 3
    layers = mp.blank_layers(W, H)
    st = layers["structure"]
    for (r, c) in floor:
        st[r - off_r][c - off_c] = SEA
    rooms_t = [(x0 - off_c, y0 - off_r, rs) for (x0, y0, rs) in rooms]
    chapels_t = [(x0 - off_c, y0 - off_r, sc, pc, tb)
                 for (x0, y0, sc, pc, tb) in chapels]
    start_t = (start[0] - off_r, start[1] - off_c)

    # 7. WALLS — ONE boundary pass: a floor cell walls every side facing void.
    # Room/corridor/chapel junctions are floor-to-floor, so no wall is laid there
    # — those gaps are the doors.
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

    # 8. HEROES centred in their rooms (the integration block)
    integ_of = mg._integration()
    for i in range(n):
        x0, y0, rs = rooms_t[i]
        _place_hero(layers, st, y0 + rs // 2, x0 + rs // 2, y0, casts[i], integ_of)

    # 8b. voltage pieces in their chapels (nearest free cell to the chapel centre)
    for (x0, y0, sc, piece, _tb) in chapels_t:
        cr, cc = y0 + sc // 2, x0 + sc // 2
        integ, cfam = integ_of.get(piece, (None, None))
        if integ in ("self", "field"):
            token = piece
        elif integ in ("cube", "wrap", "plinth", "frame"):
            fam = cfam if integ in ("cube", "wrap") else integ
            token = f"sim_cube#family:{fam}#mount:{piece}"
        else:
            token = f"{sb.select_bed(piece)['bed']}#mount:{piece}"
        for (dr, dc) in ((0, 0), (0, 1), (1, 0), (0, -1), (-1, 0)):
            rr, ccx = cr + dr, cc + dc
            if 0 <= rr < H and 0 <= ccx < W and st[rr][ccx] == SEA \
                    and layers["interactables"][rr][ccx] == " ":
                layers["interactables"][rr][ccx] = token
                break

    # 9. spawn at the trunk ROOT; exit t:restart in the most-distal room's corner
    spawn_cell = None
    for (dr, dc) in ((0, 0), (0, 1), (1, 0), (0, -1), (-1, 0), (0, 2), (2, 0)):
        r, c = start_t[0] + dr, start_t[1] + dc
        if 0 <= r < H and 0 <= c < W and st[r][c] == SEA \
                and layers["interactables"][r][c] == " ":
            spawn_cell = (r, c)
            break
    if spawn_cell is None:
        spawn_cell = start_t
    xe, ye, rse = rooms_t[mi]
    exit_cell = None
    for (dr, dc) in ((rse - 2, rse - 2), (rse - 2, 1), (1, rse - 2),
                     (rse // 2, 1), (1, rse // 2)):
        r, c = ye + dr, xe + dc
        if 0 <= r < H and 0 <= c < W and st[r][c] == SEA \
                and layers["interactables"][r][c] == " ":
            exit_cell = (r, c)
            break
    if exit_cell is None:
        exit_cell = (ye + rse - 2, xe + rse - 2)
    assert st[spawn_cell[0]][spawn_cell[1]] == SEA, "spawn not on floor"
    assert st[exit_cell[0]][exit_cell[1]] == SEA, "exit not on floor"
    # reserve them so the supporting cast respects the occupancy
    layers["utilities"][spawn_cell[0]][spawn_cell[1]] = "s"
    layers["utilities"][exit_cell[0]][exit_cell[1]] = "t:restart"

    # 10. supporting cast — same-domain benches staff the roomier beats (inner
    # >= 8); register thirds by derivation order (arrival / work / depth)
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

    # 11. palette bands — three horizontal thirds (arrival / work / depth)
    t1, t2 = H // 3, 2 * H // 3
    bands = [{"rect": [0, 0, W - 1, t1 - 1], "register": "arrival"},
             {"rect": [0, t1, W - 1, t2 - 1], "register": "work"},
             {"rect": [0, t2, W - 1, H - 1], "register": "depth"}]

    # 12. the mission metadata (strategy facts for the verdict loop)
    mission = {"beats": n, "rules_used": rules_used, "iterations": ITERATIONS,
               "tips": len(uniq),
               "rooms": [{"cast": casts[i], "rect": list(rooms_t[i]),
                          "inner": inners[i]} for i in range(n)],
               "seed": seed, "swaps": swaps, "supporting_cast": staffed}

    # the contract — dimensions/settings/palettes/spawn/exit/wall runs/props
    mp.finish(name, seq, "lsystem-trunk", layers, mission, bands,
              spawn=spawn_cell, exit_cell=exit_cell, lod_radius=14.0)

    # 13. the report — the grammar, the tips, the room rects, the floor budget
    total_floor = len(floor)
    budget = "OK" if total_floor < 1800 else "OVER"
    print(f"{name}: {n} beat rooms + {len(chapels)} chapels -> {W}x{H} cells "
          f"(canvas {CANVAS}, cropped)")
    print(f"  grammar: axiom F, {ITERATIONS} iterations, rules {rules_used}")
    print(f"  tips: {len(uniq)} distinct branch tips; floor cells: {total_floor} "
          f"(<1800 target: {budget})")
    for i in range(n):
        x0, y0, rs = rooms_t[i]
        star = " [EXIT]" if i == mi else ""
        print(f"  room {i + 1:2d} <{casts[i]}>  inner={inners[i]} "
              f"rect=[x{x0},y{y0},{rs}x{rs}]{star}")
    if chapels_t:
        print("  chapels:", ", ".join(f"<{pc}>(beat {tb + 1})"
                                       for (_x, _y, _s, pc, tb) in chapels_t))
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
    name = arg("name", f"MissionLsys_{seq.title().replace('_', '')}")
    return build(seq, name, seed)


if __name__ == "__main__":
    sys.exit(main())
