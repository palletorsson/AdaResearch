#!/usr/bin/env python3
"""gen_ants.py — the ANT-FOUND PLATE strategy (Palle's principal).

Palle: "start with an artifact footprint and have 30 ants do the finding. That
is the room base plate, then add wang tiles for interior wall and curation."

The floor is not drawn — it is FOUND. Each hero beat gets a base PLATE sized to
its honest footprint (+3 cells of margin). 30 stigmergic ants walk between the
plate centres along the beat-order chain (plus a few loop edges); every cell an
ant treads is laid as floor and widened to >= 3 wide so the pathfinder can walk
it. The organic wobble of the trails is the aesthetic — it is not straightened.
Interior walls come AFTER the plate exists (the floor/void boundary, plus a
wang-ish chapel enclosure around two plates). Curation — wall runs and props —
is the finisher's job (map_principal.finish).

  footprint -> plate      the room base plate (honest cells + 3 margin)
  30 ants   -> the floor  stigmergy finds the paths between the plates
  walls     -> after      floor/void boundary + chapel enclosures (opening
                          faces the nearest trail)
  finish    -> curation   dimensions/settings/palettes/spawn/exit/runs/props

A STRATEGY file (tools/gen_*.py): it only invents the floor idea and calls
map_principal.finish for every shared layer. The wild strategy, the standard
meeting point.

DETERMINISM: one random.Random(seed), drawn in a fixed order (plate scatter ->
loop edges -> chapel choice -> ants). Same seed -> byte-identical map. Connect-
ivity is guaranteed by construction: ant 0 of every connection walks a monotone
staircase that always reaches its target, and every ant's trail is one contig-
uous blob anchored to its start plate, so no ant can ever strand floor.

Usage:
  python tools/gen_ants.py --seq=randomness [--seed=7] [--name=MissionAnts_Randomness]
  python tools/gen_ants.py --seq=lsystems
"""
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
CANVAS = 64                       # working canvas (~64); cropped honest before finish
ANTS = 30                         # the finding — 30 ants across all connections
MARGIN = 2                        # plate margin each side (Palle: keep it tight)


# ── the footprint (the plate seed) ──────────────────────────────────────────

def _footprint(name: str):
    """honest footprint cells (min 2x2) from the size oracle."""
    s = mg._sizes().get(name, {}) or {}
    gc = s.get("grid_cells") or [2, 2]
    fw = max(2, int(round(float(gc[0]))))
    fh = max(2, int(round(float(gc[1]))))
    return fw, fh


# ── step 2: scatter the base plates (max-min-distance greedy) ────────────────

def _overlaps(rect, placed, pad=1):
    x0, y0, x1, y1 = rect
    for (px0, py0, px1, py1) in placed:
        if not (x1 + pad < px0 or px1 + pad < x0
                or y1 + pad < py0 or py1 + pad < y0):
            return True
    return False


def _place_plates(fps, rng):
    """place each plate at the candidate (seeded-shuffled every-4th grid) that
    maximises min-distance to the placed centres, >= 14 apart (relax 12/10/0)."""
    cands = [(ax, ay) for ay in range(1, CANVAS, 4) for ax in range(1, CANVAS, 4)]
    rng.shuffle(cands)
    placed, centers, plates = [], [], []
    for (fw, fh) in fps:
        pw, ph = fw + 2 * MARGIN, fh + 2 * MARGIN
        best = None
        for thresh in (14.0, 12.0, 10.0, 0.0):
            pick, pick_d, pick_c = None, -1.0, None
            for (ax, ay) in cands:
                x1, y1 = ax + pw - 1, ay + ph - 1
                if ax < 1 or ay < 1 or x1 > CANVAS - 2 or y1 > CANVAS - 2:
                    continue
                if _overlaps((ax, ay, x1, y1), placed, pad=1):
                    continue
                cen = (ay + ph // 2, ax + pw // 2)
                d = (min(math.hypot(cen[0] - pc[0], cen[1] - pc[1])
                         for pc in centers) if centers else float("inf"))
                if d >= thresh and d > pick_d:
                    pick, pick_d, pick_c = (ax, ay, x1, y1), d, cen
            if pick:
                best = (pick, pick_c)
                break
        if best is None:
            raise RuntimeError("gen_ants: could not fit a plate on the canvas")
        (x0, y0, x1, y1), cen = best
        placed.append((x0, y0, x1, y1))
        centers.append(cen)
        plates.append((x0, y0, pw, ph))
    return plates, centers


# ── step 3: the connection plan (chain in beat order + a few loops) ──────────

def _connections(n, rng):
    chain = [(i, i + 1) for i in range(n - 1)]     # the WALK ORDER: i -> i+1
    conns = list(chain)
    if n >= 3:
        n_extra = rng.choice([2, 3])
        pool = [(i, j) for i in range(n) for j in range(i + 2, n)]   # non-adjacent
        rng.shuffle(pool)
        conns += pool[:n_extra]
    return conns


def _ant_counts(conns):
    """30 ants across all connections, >= 2 each (round-robin remainder)."""
    c = len(conns)
    if c == 0:
        return []
    counts = [2] * c
    i = 0
    while sum(counts) < ANTS:
        counts[i % c] += 1
        i += 1
    return counts


# ── step 3: the ant walk (stigmergy) ────────────────────────────────────────

def _sign(x):
    return 1 if x > 0 else (-1 if x < 0 else 0)


def _walk(phero, start, target, rng, monotone):
    """one ant from start to target, 4-neighbour steps, depositing pheromone.
    With prob 0.65 it steps toward B (reduces distance); else a lateral veer
    perpendicular to its heading, never immediately backward. A monotone ant
    (ant 0 of every connection) always steps toward B, so it is GUARANTEED to
    reach the target — that is what wires the plates together."""
    r, c = start
    tr, tc = target
    phero[r][c] += 1
    prev = None
    steps = 0
    while (r, c) != (tr, tc) and steps < 400:
        dr, dc = tr - r, tc - c
        toward = []
        if dr:
            toward.append((r + _sign(dr), c))
        if dc:
            toward.append((r, c + _sign(dc)))
        roll = rng.random()
        if toward and (monotone or roll < 0.65):
            nxt = toward[rng.randrange(len(toward))]
        else:
            lat = ([(r, c - 1), (r, c + 1)] if abs(dr) >= abs(dc)
                   else [(r - 1, c), (r + 1, c)])
            lat = [p for p in lat
                   if 0 <= p[0] < CANVAS and 0 <= p[1] < CANVAS and p != prev]
            if lat:
                nxt = lat[rng.randrange(len(lat))]
            elif toward:
                nxt = toward[rng.randrange(len(toward))]
            else:
                break
        prev = (r, c)
        r, c = nxt
        phero[r][c] += 1
        steps += 1


# ── step 4: the chapel enclosure (wang pressure on two plates) ───────────────

def _opening_cells(ix0, iy0, ix1, iy1, sd):
    if sd in ("n", "s"):
        r = iy0 if sd == "n" else iy1
        cm = (ix0 + ix1) // 2
        return [(r, cm), (r, cm + 1 if cm + 1 <= ix1 else cm - 1)]
    c = ix0 if sd == "w" else ix1
    rm = (iy0 + iy1) // 2
    return [(rm, c), (rm + 1 if rm + 1 <= iy1 else rm - 1, c)]


def _outward(r, c, sd):
    return {"n": (r - 1, c), "s": (r + 1, c),
            "w": (r, c - 1), "e": (r, c + 1)}[sd]


def _chapel(layers, plate, center, toward_center):
    """partial enclosure on the plate's inner rect, a 2-cell opening facing the
    nearest trail. The ring (the 2-cell plate border) stays a connected loop, so
    the hero inside is always reachable via the opening — verified below."""
    st = layers["structure"]
    H, W = len(st), len(st[0])
    x0, y0, pw, ph = plate
    ix0, iy0 = x0 + 2, y0 + 2
    ix1, iy1 = x0 + pw - 3, y0 + ph - 3
    if ix1 - ix0 < 2 or iy1 - iy0 < 2:
        return None
    dr, dc = toward_center[0] - center[0], toward_center[1] - center[1]
    pref = ("s" if dr > 0 else "n") if abs(dr) >= abs(dc) else ("e" if dc > 0 else "w")
    order = [pref] + [s for s in ("n", "e", "s", "w") if s != pref]
    chosen = None
    for sd in order:
        cells = _opening_cells(ix0, iy0, ix1, iy1, sd)
        ok = True
        for (orow, ocol) in cells:
            nr, nc = _outward(orow, ocol, sd)
            if not (0 <= nr < H and 0 <= nc < W and st[nr][nc] == SEA):
                ok = False
                break
        if ok:
            chosen = (sd, set(cells))
            break
    if chosen is None:
        return None                       # no opening faces floor — skip (rare)
    sd, opencells = chosen
    for c in range(ix0, ix1 + 1):
        if not (sd == "n" and (iy0, c) in opencells):
            mp.wall(layers, iy0, c, "n")
        if not (sd == "s" and (iy1, c) in opencells):
            mp.wall(layers, iy1, c, "s")
    for r in range(iy0, iy1 + 1):
        if not (sd == "w" and (r, ix0) in opencells):
            mp.wall(layers, r, ix0, "w")
        if not (sd == "e" and (r, ix1) in opencells):
            mp.wall(layers, r, ix1, "e")
    return sd


def _select_chapels(n, rng):
    eligible = list(range(1, n - 1))       # middle plates only (keep spawn/exit clean)
    k = min(2, len(eligible))
    return sorted(rng.sample(eligible, k)) if k else []


# ── the build ────────────────────────────────────────────────────────────────

def build(seq, name, seed):
    beats, volt = mg.load_mission(seq)
    if not beats:
        print(f"gen_ants: no beats in baseline for {seq}")
        return 1
    n = min(8, len(beats))                 # up to ~8 heroes (all beats if fewer)

    # 1. resolve the casts, size each plate to its chosen hero's footprint
    casts, swaps, fps = [], [], []
    for i in range(n):
        chosen, swapped = mg.resolve_cast(beats[i]["cast"], beats[i].get("alts", []),
                                          8.0, 3.4)
        casts.append(chosen)
        if swapped:
            swaps.append(f"{swapped}->{chosen}")
        fps.append(_footprint(chosen))

    rng = random.Random(seed)              # the ONLY randomness — fixed draw order

    # 2. scatter the base plates
    plates, centers = _place_plates(fps, rng)

    # 3. the connection plan, then the 30 ants find the floor
    conns = _connections(n, rng)
    chapel_idx = _select_chapels(n, rng)
    counts = _ant_counts(conns)
    phero = [[0] * CANVAS for _ in range(CANVAS)]
    for (a, b), k in zip(conns, counts):
        for ai in range(k):
            _walk(phero, centers[a], centers[b], rng, monotone=(ai == 0))

    # plates are floor; every pheromone cell is floor, widened to >= 3 wide
    floor = set()
    for (x0, y0, pw, ph) in plates:
        for r in range(y0, y0 + ph):
            for c in range(x0, x0 + pw):
                floor.add((r, c))
    trail_cells = 0
    for r in range(CANVAS):
        for c in range(CANVAS):
            if phero[r][c] >= 1:
                trail_cells += 1
                floor.add((r, c))
                for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    nr, nc = r + dr, c + dc
                    if 0 <= nr < CANVAS and 0 <= nc < CANVAS:
                        floor.add((nr, nc))

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
    plates_t = [(x0 - off_c, y0 - off_r, pw, ph) for (x0, y0, pw, ph) in plates]
    centers_t = [(r - off_r, c - off_c) for (r, c) in centers]

    # 4. interior walls — the floor/void boundary carries the wall code on that side
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
    # 4b. chapel enclosures on two chosen plates (opening toward the next plate)
    chapels = []
    for idx in chapel_idx:
        nb = idx + 1 if idx + 1 < n else idx - 1
        sd = _chapel(layers, plates_t[idx], centers_t[idx], centers_t[nb])
        if sd:
            chapels.append((idx, sd))

    # 5. heroes centred on their plates (the integration block)
    integ_of = mg._integration()
    for i in range(n):
        x0, y0, pw, ph = plates_t[i]
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

    # 8. spawn on the first plate (2 from centre), exit on the last plate corner
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
    xL, yL, pwL, phL = plates_t[n - 1]
    exit_cell = (yL + phL - 2, xL + pwL - 2)
    assert st[spawn_cell[0]][spawn_cell[1]] == SEA, "spawn not on floor"
    assert st[exit_cell[0]][exit_cell[1]] == SEA, "exit not on floor"
    # reserve them so the supporting cast respects the occupancy
    layers["utilities"][spawn_cell[0]][spawn_cell[1]] = "s"
    layers["utilities"][exit_cell[0]][exit_cell[1]] = "t:restart"

    # 5b. supporting cast — same-domain benches staff the plates
    n_acts = (n + 2) // 3

    def register_of(a):
        if a == 0:
            return "arrival"
        return "depth" if a == n_acts - 1 else "work"

    slots = [{"act": i // 3, "kind": "beat", "cast": casts[i],
              "oy": plates_t[i][1] + 1, "ox": plates_t[i][0] + 1,
              "F": min(plates_t[i][2], plates_t[i][3]) - 2}
             for i in range(n)]
    staffed = mg.staff_supporting_cast(layers, slots, mg._bench_library(seq), register_of)
    kept = []
    for s in staffed:
        r, c = s["cell"]
        if layers["structure"][r][c] == SEA:
            kept.append(s)
        else:
            layers["interactables"][r][c] = " "     # never a bench floating on void
    staffed = kept

    # 7. palette bands — three horizontal thirds (arrival / work / depth)
    t1, t2 = H // 3, 2 * H // 3
    bands = [{"rect": [0, 0, W - 1, t1 - 1], "register": "arrival"},
             {"rect": [0, t1, W - 1, t2 - 1], "register": "work"},
             {"rect": [0, t2, W - 1, H - 1], "register": "depth"}]

    # 9. the mission metadata (strategy facts for the verdict loop)
    mission = {"beats": n,
               "seeds": [{"cast": casts[i], "rect": list(plates_t[i])} for i in range(n)],
               "ants": ANTS, "seed": seed, "connections": len(conns),
               "swaps": swaps, "supporting_cast": staffed}

    # the contract — dimensions/settings/palettes/spawn/exit/wall runs/props
    mp.finish(name, seq, "ants-found", layers, mission, bands,
              spawn=spawn_cell, exit_cell=exit_cell, lod_radius=14.0)

    # 11. report — the plate rects + the trail cell count
    print(f"{name}: {n} heroes, {len(conns)} connections, {ANTS} ants "
          f"-> {W}x{H} cells (canvas {CANVAS}, cropped)")
    print(f"  trail cells (pheromone>=1): {trail_cells}; floor cells total: {len(floor)}")
    for i in range(n):
        x0, y0, pw, ph = plates_t[i]
        print(f"  plate {i + 1:2d} <{casts[i]}>  rect=[x{x0},y{y0},w{pw},h{ph}]")
    if swaps:
        print("  size-governed swaps:", ", ".join(swaps))
    if chapels:
        print("  chapel plates:", ", ".join(
            f"{idx + 1}(<{casts[idx]}> open {sd})" for idx, sd in chapels))
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
    seed = int(arg("seed", "7"))
    name = arg("name", f"MissionAnts_{seq.title().replace('_', '')}")
    return build(seq, name, seed)


if __name__ == "__main__":
    sys.exit(main())
