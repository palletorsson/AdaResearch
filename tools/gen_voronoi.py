#!/usr/bin/env python3
"""gen_voronoi.py — the VORONOI TERRITORIES strategy (Palle's principal).

The computational-geometry chapter's own map. Scatter the beats (and the
voltage pieces) as SITES across the canvas, max-min-distance apart; every cell
belongs to its nearest site — the Voronoi partition. Each territory is eroded to
a rounded island (a cell is floor only within ERODE_R of its site), so distant
territories float apart with void between them and near territories touch along
their bisector. The walls are the WANG MOVE at map scale: where two floor cells
of DIFFERENT territories meet, a wall goes on the meeting edge — every territory
seals itself. The lesson order threads back through: for each beat-order pair a
DOOR (a centred 3-cell gap in the boundary wall) if the territories touch, else
an L-shaped 3-wide CORRIDOR carved between the two sites. One seeded loop door
adds a cycle. A flood-fill from spawn wires up any island the chain missed (the
voltage territories) with one more corridor each, and any floor it still can't
reach is pruned — so the map is 100% reachable by construction + repair.

  sites      -> scatter    beats + voltage, max-min-distance >= MIN_DIST
  territory  -> partition   nearest site (euclidean; ties to lower index)
  erosion    -> islands     floor only within ERODE_R of the site (tightness)
  room core  -> the hero    inner = footprint + 4 (voltage 6) stamped at site
  walls      -> boundaries   floor/void seal + territory walls at every meeting
  doors      -> the walk     beat-order gaps where territories touch
  corridors  -> the reach    L-carve where they don't; repair wires the rest
  finish     -> curation     dimensions/settings/palettes/spawn/exit/runs/props

A STRATEGY file (tools/gen_*.py): it only invents the floor idea and calls
map_principal.finish for every shared layer. The wild strategy, the standard
meeting point.

DETERMINISM: one random.Random(seed) scatters the sites; a derived
random.Random(seed + 1) picks the loop door. Everything else — the partition,
the erosion, the boundary/door geometry, the corridors, the connectivity repair
— is a pure function of the sites. Same seed -> byte-identical map. Erosion
auto-tightens (ERODE_R steps down) until the floor is under FLOOR_TARGET, so the
tightness knob never blows the cell budget.

Usage:
  python tools/gen_voronoi.py --seq=randomness [--seed=7] [--name=MissionVoronoi_Randomness]
  python tools/gen_voronoi.py --seq=lsystems [--set ERODE_R=8]
"""
import math
import random
import sys
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

import map_principal as mp        # THE finisher — must call mp.finish
import mission_graph as mg        # load_mission/resolve_cast/_integration/staff/bench
import staging_beds as sb         # select_bed (the marriage-1 body)

SEA = mg.SEA                      # "2" — the walkable floor height
CANVAS = 56                       # working canvas (~56); cropped honest before finish
MIN_DIST = 13                     # scatter max-min-distance target (relaxes to 0)
ERODE_R = 9                       # THE TIGHTNESS KNOB: floor only within R of its site
BUDGET_FP = 8.0                   # resolve_cast footprint budget
BUDGET_H = 3.4                    # resolve_cast height budget
MIN_INNER = 7                     # smallest beat room core
CAP_INNER = 14                    # largest beat room core
VOLT_INNER = 6                    # voltage room core (always small)
DOOR_W = 3                        # centred door opening width (edges left un-walled)
CORR_W = 3                        # L-corridor width
FLOOR_TARGET = 2200               # erode tighter until the floor is under this
MIN_ERODE = 5                     # never tighten erosion below this
MAX_SITES = 18                    # cap total sites the canvas must hold


# ── site sizing (the room the hero stands in) ───────────────────────────────

def _cast_cells(name: str) -> int:
    """max grid_cells of a cast (default 2 when unmeasured)."""
    s = mg._sizes().get(name, {}) or {}
    gc = s.get("grid_cells")
    if not gc:
        return 2
    return max(1, int(max(int(gc[0]), int(gc[1]))))


def _beat_inner(cells: int) -> int:
    """beat room core — footprint + 4 cells of close walk, clamped."""
    return max(MIN_INNER, min(CAP_INNER, cells + 4))


# ── step 1: scatter the sites (max-min-distance greedy) ──────────────────────

def _scatter(n, rng):
    """POISSON-DISK dart-throwing on a seeded-shuffled every-2nd grid: accept a
    candidate iff it is >= MIN_DIST from every placed site (relax by 2 twice,
    then 1). This packs the sites at ~MIN_DIST so the territories TESSELLATE and
    touch — the farthest-point 'max-min' greedy spreads sites to the canvas
    edges and the territories never meet, so there are no shared edges to door."""
    lo, hi = 3, CANVAS - 3
    cands = [(r, c) for r in range(lo, hi, 2) for c in range(lo, hi, 2)]
    rng.shuffle(cands)
    sites = []
    for thr in (float(MIN_DIST), MIN_DIST - 2.0, MIN_DIST - 4.0, 1.0):
        for (r, c) in cands:
            if len(sites) >= n:
                break
            if all(math.hypot(r - sr, c - sc) >= thr for (sr, sc) in sites):
                sites.append((r, c))
        if len(sites) >= n:
            break
    if len(sites) < n:
        raise RuntimeError("gen_voronoi: could not place all sites on the canvas")
    return sites[:n]


# ── step 2: the partition + erosion (the territories become islands) ─────────

def _dist2(a, b):
    return (a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2


def _territories(sites):
    """terr[r][c] = index of nearest site (euclidean; ties -> lower index)."""
    terr = [[0] * CANVAS for _ in range(CANVAS)]
    n = len(sites)
    for r in range(CANVAS):
        row = terr[r]
        for c in range(CANVAS):
            best_i, best_d = 0, _dist2((r, c), sites[0])
            for i in range(1, n):
                d = _dist2((r, c), sites[i])
                if d < best_d:                 # strict < keeps the lower index on ties
                    best_d, best_i = d, i
            row[c] = best_i
    return terr


def _base_floor(sites, inners, erode_r):
    """floor = union of erosion disks (radius erode_r) + room cores. A cell is
    floor iff it is within erode_r of ANY site (== within erode_r of its nearest
    site) OR inside some site's room core rect."""
    floor = set()
    er2 = erode_r * erode_r
    for (sr, sc) in sites:
        for r in range(max(0, sr - erode_r), min(CANVAS, sr + erode_r + 1)):
            dr2 = (r - sr) ** 2
            for c in range(max(0, sc - erode_r), min(CANVAS, sc + erode_r + 1)):
                if dr2 + (c - sc) ** 2 <= er2:
                    floor.add((r, c))
    for (sr, sc), inner in zip(sites, inners):
        h = inner // 2
        for r in range(max(0, sr - h), min(CANVAS, sr - h + inner)):
            for c in range(max(0, sc - h), min(CANVAS, sc - h + inner)):
                floor.add((r, c))
    return floor


# ── step 4: doors on touching boundaries, L-corridors where they float apart ─

def _l_corridor(a, b):
    """cells of a CORR_W-wide L from a to b, x-first (horizontal, then down the
    target column) — deterministic elbow. Clipped to the canvas."""
    ar, ac = a
    br, bc = b
    w = CORR_W // 2
    cells = set()
    for c in range(min(ac, bc), max(ac, bc) + 1):      # horizontal run at row ar
        for dr in range(-w, w + 1):
            rr = ar + dr
            if 0 <= rr < CANVAS and 0 <= c < CANVAS:
                cells.add((rr, c))
    for r in range(min(ar, br), max(ar, br) + 1):      # vertical run at col bc
        for dc in range(-w, w + 1):
            cc = bc + dc
            if 0 <= r < CANVAS and 0 <= cc < CANVAS:
                cells.add((r, cc))
    return cells


def _boundary_edges(floor, terr):
    """pair_key (i<j) -> sorted list of floor-floor edges between territory i,j.
    Each edge is (cellA, cellB) with cellA < cellB; counted once (east/south)."""
    edges = {}
    for (r, c) in floor:
        for dr, dc in ((0, 1), (1, 0)):
            nb = (r + dr, c + dc)
            if nb in floor:
                ti, tj = terr[r][c], terr[nb[0]][nb[1]]
                if ti != tj:
                    key = (ti, tj) if ti < tj else (tj, ti)
                    edges.setdefault(key, []).append(((r, c), nb))
    return edges


def _door_opening(edge_list):
    """the centred DOOR_W edges of a boundary (sorted, middle slice)."""
    es = sorted(edge_list)
    if len(es) <= DOOR_W:
        return set(es)
    mid = len(es) // 2
    half = DOOR_W // 2
    return set(es[mid - half: mid - half + DOOR_W])


def _reachable(seed_cell, floor, terr, door_edges, corridor):
    """flood-fill mirroring the wall-aware pathfinder EXACTLY: a step between two
    floor cells is blocked only by a territory wall — allowed iff same territory,
    or the edge is a door, or either cell is a corridor cell."""
    seen = {seed_cell}
    q = deque([seed_cell])
    while q:
        r, c = q.popleft()
        ti = terr[r][c]
        cin = (r, c) in corridor
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nb = (r + dr, c + dc)
            if nb in seen or nb not in floor:
                continue
            if ti == terr[nb[0]][nb[1]] or cin or nb in corridor \
                    or (((r, c), nb) if (r, c) < nb else (nb, (r, c))) in door_edges:
                seen.add(nb)
                q.append(nb)
    return seen


def _plan(sites, inners, n_beats, erode_r, seed):
    """the floor idea: partition, erode, wire the beat chain (doors/corridors) +
    a loop door, repair every stranded island, prune what stays unreachable."""
    terr = _territories(sites)
    floor = _base_floor(sites, inners, erode_r)
    bedges = _boundary_edges(floor, terr)

    door_edges, corridor = set(), set()
    n_doors, n_corr = 0, 0
    beat_pairs = set()
    for i in range(n_beats - 1):
        key = (i, i + 1)
        beat_pairs.add(key)
        el = bedges.get(key)
        if el:                                     # territories touch -> a door
            door_edges |= _door_opening(el)
            n_doors += 1
        else:                                      # float apart -> an L-corridor
            corr = _l_corridor(sites[i], sites[i + 1])
            corridor |= corr
            floor |= corr
            n_corr += 1

    # one seeded extra loop door (a cycle) on any other touching pair
    rng_door = random.Random(seed + 1)
    eligible = sorted(k for k in bedges if k not in beat_pairs)
    if eligible:
        door_edges |= _door_opening(bedges[eligible[rng_door.randrange(len(eligible))]])
        n_doors += 1

    # connectivity + repair: wire any site the chain left stranded (the voltage
    # territories) with one more corridor each, from the nearest reachable site
    seed_cell = sites[0]
    reach = _reachable(seed_cell, floor, terr, door_edges, corridor)
    repairs = 0
    guard = 0
    while guard < len(sites) + 5:
        guard += 1
        unreached = [i for i in range(len(sites)) if sites[i] not in reach]
        if not unreached:
            break
        best = None                                # (dist2, reachable j, stranded i)
        for i in unreached:
            for j in range(len(sites)):
                if sites[j] in reach:
                    d = _dist2(sites[i], sites[j])
                    if best is None or d < best[0]:
                        best = (d, j, i)
        if best is None:
            break
        _, j, i = best
        corr = _l_corridor(sites[j], sites[i])
        corridor |= corr
        floor |= corr
        repairs += 1
        reach = _reachable(seed_cell, floor, terr, door_edges, corridor)

    # prune any floor still unreachable (territory-boundary slivers) -> 100%
    reach = _reachable(seed_cell, floor, terr, door_edges, corridor)
    floor &= reach
    return {"terr": terr, "floor": floor, "door_edges": door_edges,
            "corridor": corridor, "doors": n_doors, "corridors": n_corr,
            "repairs": repairs}


# ── the build ────────────────────────────────────────────────────────────────

def build(seq, name, seed):
    beats, volt = mg.load_mission(seq)
    if not beats:
        print(f"gen_voronoi: no beats in baseline for {seq}")
        return 1
    n_beats = min(MAX_SITES, len(beats))

    # 1. resolve the beat casts, size each room; then the deduped voltage sites
    casts, swaps, inners, is_volt = [], [], [], []
    for i in range(n_beats):
        chosen, swapped = mg.resolve_cast(beats[i]["cast"], beats[i].get("alts", []),
                                          BUDGET_FP, BUDGET_H)
        casts.append(chosen)
        if swapped:
            swaps.append(f"{swapped}->{chosen}")
        inners.append(_beat_inner(_cast_cells(chosen)))
        is_volt.append(False)
    seen = set(casts)
    for piece in volt:
        if len(casts) >= MAX_SITES:
            break
        if not piece or piece in seen:
            continue
        seen.add(piece)
        casts.append(piece)
        inners.append(VOLT_INNER)
        is_volt.append(True)
    n_sites = len(casts)

    rng = random.Random(seed)              # the ONLY scatter randomness
    sites = _scatter(n_sites, rng)

    # 2-5. the floor idea, erosion auto-tightening until under the cell budget
    er = ERODE_R
    plan = _plan(sites, inners, n_beats, er, seed)
    tightened = []
    while len(plan["floor"]) >= FLOOR_TARGET and er > MIN_ERODE:
        er -= 1
        tightened.append(er)
        plan = _plan(sites, inners, n_beats, er, seed)
    terr = plan["terr"]
    floor = plan["floor"]
    door_edges = plan["door_edges"]
    corridor = plan["corridor"]

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
    sites_t = [(r - off_r, c - off_c) for (r, c) in sites]

    # WALLS pass A — the floor/void boundary carries the wall on the void side
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
    # WALLS pass B — the wang move: a wall at every different-territory meeting,
    # EXCEPT on door segments and along corridor cells (checked in canvas coords)
    for r in range(H):
        for c in range(W):
            if st[r][c] != SEA:
                continue
            cr, cc = r + off_r, c + off_c
            if c + 1 < W and st[r][c + 1] == SEA:                  # east neighbour
                ncr, ncc = cr, cc + 1
                if terr[cr][cc] != terr[ncr][ncc]:
                    e = ((cr, cc), (ncr, ncc))
                    if e not in door_edges and (cr, cc) not in corridor \
                            and (ncr, ncc) not in corridor:
                        mp.wall(layers, r, c, "e")
                        mp.wall(layers, r, c + 1, "w")
            if r + 1 < H and st[r + 1][c] == SEA:                  # south neighbour
                ncr, ncc = cr + 1, cc
                if terr[cr][cc] != terr[ncr][ncc]:
                    e = ((cr, cc), (ncr, ncc))
                    if e not in door_edges and (cr, cc) not in corridor \
                            and (ncr, ncc) not in corridor:
                        mp.wall(layers, r, c, "s")
                        mp.wall(layers, r + 1, c, "n")

    # 7. heroes centred in their rooms (the integration block: self/field bare;
    # cube/wrap/plinth/frame -> sim_cube housing; else a staging bed)
    integ_of = mg._integration()
    for i in range(n_sites):
        cr, cc = sites_t[i]
        if not (0 <= cr < H and 0 <= cc < W) or st[cr][cc] != SEA:
            continue                                   # hero cell pruned (rare) — skip
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
                hr = max(0, cr - inners[i] // 2 + 1)
                if 0 <= hr < H and st[hr][cc] == SEA:
                    layers["interactables"][hr][cc] = f"{bed['bed']}:180#mount:{chosen}"
                else:
                    layers["interactables"][cr][cc] = f"{bed['bed']}#mount:{chosen}"
            else:
                layers["interactables"][cr][cc] = f"{bed['bed']}#mount:{chosen}"

    # 8. spawn in the first room (2 from centre); exit in the last BEAT room corner
    cr0, cc0 = sites_t[0]
    spawn_cell = None
    for dr, dc in ((0, 2), (2, 0), (0, -2), (-2, 0), (2, 2), (-2, -2)):
        r, c = cr0 + dr, cc0 + dc
        if 0 <= r < H and 0 <= c < W and st[r][c] == SEA \
                and layers["interactables"][r][c] == " ":
            spawn_cell = (r, c)
            break
    if spawn_cell is None:
        spawn_cell = (cr0, cc0)
    lr, lc = sites_t[n_beats - 1]
    hL = inners[n_beats - 1] // 2 - 1
    exit_cell = None
    for dr, dc in ((hL, hL), (1, 1), (-1, -1), (1, -1), (-1, 1), (0, 0)):
        r, c = lr + dr, lc + dc
        if 0 <= r < H and 0 <= c < W and st[r][c] == SEA and (r, c) != spawn_cell:
            exit_cell = (r, c)
            break
    if exit_cell is None:
        exit_cell = (lr, lc)
    assert st[spawn_cell[0]][spawn_cell[1]] == SEA, "spawn not on floor"
    assert st[exit_cell[0]][exit_cell[1]] == SEA, "exit not on floor"
    # reserve them so the supporting cast respects the occupancy
    layers["utilities"][spawn_cell[0]][spawn_cell[1]] = "s"
    layers["utilities"][exit_cell[0]][exit_cell[1]] = "t:restart"

    # 9. supporting cast — same-domain benches staff the roomier BEATS (inner>=8);
    # registers by beat-order thirds
    n_acts = (n_beats + 2) // 3

    def register_of(a):
        if a == 0:
            return "arrival"
        return "depth" if a == n_acts - 1 else "work"

    slots = []
    for i in range(n_beats):
        if inners[i] >= 8:
            cr, cc = sites_t[i]
            slots.append({"act": i // 3, "kind": "beat", "cast": casts[i],
                          "oy": cr - inners[i] // 2 + 1, "ox": cc - inners[i] // 2 + 1,
                          "F": inners[i] - 2})
    staffed = mg.staff_supporting_cast(layers, slots, mg._bench_library(seq), register_of)
    kept = []
    for s in staffed:
        r, c = s["cell"]
        if 0 <= r < H and 0 <= c < W and layers["structure"][r][c] == SEA:
            kept.append(s)
        else:
            layers["interactables"][r][c] = " "     # never a bench floating on void
    staffed = kept

    # palette bands — three horizontal thirds (arrival / work / depth)
    t1, t2 = H // 3, 2 * H // 3
    bands = [{"rect": [0, 0, W - 1, t1 - 1], "register": "arrival"},
             {"rect": [0, t1, W - 1, t2 - 1], "register": "work"},
             {"rect": [0, t2, W - 1, H - 1], "register": "depth"}]

    # 7 (metadata). the strategy facts for the verdict loop
    mission = {"beats": n_beats, "sites": n_sites, "erode_r": er,
               "doors": plan["doors"], "corridors": plan["corridors"],
               "repairs": plan["repairs"], "seed": seed, "swaps": swaps,
               "supporting_cast": staffed}

    # the contract — dimensions/settings/palettes/spawn/exit/wall runs/props
    mp.finish(name, seq, "voronoi-territories", layers, mission, bands,
              spawn=spawn_cell, exit_cell=exit_cell, lod_radius=14.0)

    # report — the sites, doors, corridors, repairs, erosion, floor budget
    floor_n = len(floor)
    print(f"{name}: {n_sites} sites ({n_beats} beats + {n_sites - n_beats} voltage), "
          f"{plan['doors']} doors, {plan['corridors']} corridors, "
          f"{plan['repairs']} repairs -> {W}x{H} cells (canvas {CANVAS}, cropped)")
    print(f"  erode_r={er}"
          + (f" (tightened from {ERODE_R} via {tightened})" if tightened else "")
          + f"; floor cells: {floor_n}"
          + ("  [OVER FLOOR_TARGET]" if floor_n >= FLOOR_TARGET else f" (< {FLOOR_TARGET})"))
    for i in range(n_sites):
        cr, cc = sites_t[i]
        tag = "volt" if is_volt[i] else "beat"
        print(f"  site {i + 1:2d} [{tag}] <{casts[i]}>  inner={inners[i]} "
              f"at (r{cr},c{cc})")
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
    name = arg("name", f"MissionVoronoi_{seq.title().replace('_', '')}")
    return build(seq, name, seed)


if __name__ == "__main__":
    sys.exit(main())
