#!/usr/bin/env python3
"""template_vertical_repair.py — round 3: connectivity repair for generated rooms.

VERDICT (2026-07-09, see doc/reports/template_vertical_research.md): the
original premise — "terraced genomes are systematically penalized" — was
FALSE. Survey of 400 genomes: flat 224/224 pass, terraced 174/176; the
migration champions were already terraced. The ~1% real failures are
WALL-SEALED pockets (same-height cells closed by route/hull wall edges),
and this file's repair operator fixes them (2/2 in the survey, by doors).

THE REPAIR OPERATOR: after compile, flood from spawn; for each unreached
component find its lowest-|dh| boundary to reached floor and bridge it —
  dh == 0 : carve a DOOR (uppercase the wall code on the blocking edge)
  dh == 1 : place a wp wedge on the lower cell, rotated to rise toward the high side
  dh >= 2 : carve the component-side boundary cell into an intermediate step
            (height hi-1) + wedge, then recurse (the next pass sees a 1-step)
Iterate flood->repair until 100% of floor is reached (cap 12 passes).

Modes:
  --survey [--n=120]     how much of the terraced genome space does repair open?
  --evolve [--seeds=..]  migration evolution WITH repair — do terraced rooms
                         now reach the champion table? Champion -> TemplateLab_VERT_GEN
Report: doc/reports/template_vertical_repair.md
"""
import json
import random
import sys
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

import gallery_evolve as ge
import map_pathfinder as mp

# wedge rotation by rise-direction (anchor: wp:-90 rises WEST, walked-verified
# by Palle; family inferred — the pathfinder is rotation-agnostic, VR walk may
# flip N/S and that is a one-line fix here)
RISE_ROT = {(-1, 0): "180", (1, 0): "0", (0, -1): "-90", (0, 1): "90"}


def flood_state(data):
    graph = mp.MapGraph(data)
    reach = graph.bfs_flood()
    st = data["layers"]["structure"]
    floor = {(r, c) for r, row in enumerate(st) for c, v in enumerate(row) if str(v) != "0"}
    return graph, reach, floor


def components(cells):
    cells = set(cells)
    comps = []
    while cells:
        seed = next(iter(cells))
        comp = {seed}
        q = deque([seed])
        cells.discard(seed)
        while q:
            r, c = q.popleft()
            for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                nb = (r + dr, c + dc)
                if nb in cells:
                    cells.discard(nb)
                    comp.add(nb)
                    q.append(nb)
        comps.append(comp)
    return comps


def repair(data, max_passes=12):
    """bridge every unreached floor component; returns (data, log)."""
    log = {"wedges": 0, "carves": 0, "doors": 0, "passes": 0, "fixed": True}
    util = data["layers"]["utilities"]
    st = data["layers"]["structure"]
    walls = data["layers"]["walls"]

    def carve_door(cell_a, cell_b):
        """make the shared edge passable: uppercase the wall char on whichever
        cell declares it (either cell can hold the code)."""
        (ra, ca), (rb, cb) = cell_a, cell_b
        # edge direction from a's perspective
        if rb == ra - 1: pair = [("n", ra, ca), ("s", rb, cb)]
        elif rb == ra + 1: pair = [("s", ra, ca), ("n", rb, cb)]
        elif cb == ca - 1: pair = [("w", ra, ca), ("e", rb, cb)]
        else: pair = [("e", ra, ca), ("w", rb, cb)]
        done = False
        for ch, r, c in pair:
            cell = str(walls[r][c])
            if ch in cell:
                walls[r][c] = cell.replace(ch, ch.upper())
                done = True
        return done

    def h(r, c):
        try:
            return int(str(st[r][c]))
        except (ValueError, IndexError):
            return 0

    for _ in range(max_passes):
        graph, reach, floor = flood_state(data)
        unreached = floor - reach
        if not unreached:
            log["passes"] = _ + 1 if _ else log["passes"]
            return data, log
        log["passes"] += 1
        progressed = False
        for comp in components(unreached):
            # all (comp_cell, reached_nbr, dh, direction) boundary options
            options = []
            for (r, c) in comp:
                for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    nb = (r + dr, c + dc)
                    if nb in reach:
                        options.append((abs(h(*nb) - h(r, c)), (r, c), nb, (dr, dc)))
            if not options:
                continue  # sealed by void — not a height problem
            options.sort(key=lambda x: x[0])
            dh, low_cell, high_cell, d = options[0]
            lr, lc = low_cell
            hh, lh = h(*high_cell), h(lr, lc)
            if hh < lh:  # component is the HIGH side; swap roles
                low_cell, high_cell = high_cell, low_cell
                lr, lc = low_cell
                hh, lh = h(*high_cell), h(lr, lc)
                d = (-d[0], -d[1])
            if dh == 0:
                # same height, blocked by a wall edge -> carve a door
                if carve_door(low_cell, high_cell):
                    log["doors"] += 1
                    progressed = True
                continue
            if dh == 1:
                if not str(util[lr][lc]).strip().startswith("wp"):
                    util[lr][lc] = f"wp:{RISE_ROT[d]}"
                    log["wedges"] += 1
                    progressed = True
                # a wall edge may block the wedge crossing too
                if carve_door(low_cell, high_cell):
                    log["doors"] += 1
                    progressed = True
                continue
            # dh >= 2: carve the low cell into an intermediate step + wedge
            st[lr][lc] = str(hh - 1)
            if not str(util[lr][lc]).strip().startswith("wp"):
                util[lr][lc] = f"wp:{RISE_ROT[d]}"
                log["wedges"] += 1
            log["carves"] += 1
            progressed = True
        if not progressed:
            break
    graph, reach, floor = flood_state(data)
    log["fixed"] = not (floor - reach)
    return data, log


def scores_of(genome, use_repair):
    data, slots = ge.compile_gallery(dict(genome), gid="vert")
    rlog = None
    if use_repair:
        data, rlog = repair(data)
    m = ge.measure(data, slots)
    return {p: ge.fitness(p, m) for p in ("capacity", "drama", "intimacy")}, data, rlog


def survey(n, rng):
    rows = {"flat": [0, 0], "terraced_before": [0, 0], "terraced_after": [0, 0]}
    fixes = {"wedges": 0, "carves": 0}
    for _ in range(n):
        g = ge.make_genome(rng)
        terr = g["height"] == "step_down" or g["form"] == "terrace"
        data, slots = ge.compile_gallery(dict(g), gid="sv")
        ok_before = ge.measure(data, slots)["reachable"]
        key = "terraced_before" if terr else "flat"
        rows[key][0] += 1 if ok_before else 0
        rows[key][1] += 1
        if terr:
            data2, slots2 = ge.compile_gallery(dict(g), gid="sv")
            data2, rlog = repair(data2)
            ok_after = ge.measure(data2, slots2)["reachable"]
            rows["terraced_after"][0] += 1 if ok_after else 0
            rows["terraced_after"][1] += 1
            fixes["wedges"] += rlog["wedges"]
            fixes["carves"] += rlog["carves"]
    return rows, fixes


def evolve_with_repair(rng):
    """migration evolution (round-2 winner rule) with repair inside scoring."""
    POP, GENS, ELITE, MIG = 14, 5, 3, 2
    TASTES = ("capacity", "intimacy")
    pops = {t: [ge.make_genome(rng) for _ in range(POP)] for t in TASTES}
    best = (None, -1e9)
    for gen in range(GENS):
        scored = {}
        for t in TASTES:
            rows = []
            for g in pops[t]:
                sc, _d, _r = scores_of(g, use_repair=True)
                rows.append((sc[t], g, sc))
                gs = min(sc.values())
                if gs > best[1]:
                    best = (g, gs)
            rows.sort(key=lambda x: -x[0])
            scored[t] = rows
        for t in TASTES:
            rows = scored[t]
            nxt = [dict(r[1]) for r in rows[:ELITE]]
            while len(nxt) < POP - MIG:
                a = max(rng.sample(rows, 3), key=lambda x: x[0])[1]
                b = max(rng.sample(rows, 3), key=lambda x: x[0])[1]
                child = ge.crossover(rng, dict(a), dict(b))
                if rng.random() < 0.7:
                    child = ge.mutate(rng, child)
                nxt.append(child)
            pops[t] = nxt
        top_c = [r[1] for r in scored["capacity"][:MIG]]
        top_i = [r[1] for r in scored["intimacy"][:MIG]]
        for t in TASTES:
            for k in range(MIG):
                child = ge.crossover(rng, dict(top_c[k % MIG]), dict(top_i[k % MIG]))
                if rng.random() < 0.5:
                    child = ge.mutate(rng, child)
                pops[t].append(child)
    return best


def main() -> int:
    if "--survey" in sys.argv:
        n = int(next((a.split("=")[1] for a in sys.argv if a.startswith("--n=")), "120"))
        rng = random.Random(41)
        rows, fixes = survey(n, rng)
        fb, tb = rows["terraced_before"], rows["terraced_after"]
        fl = rows["flat"]
        print(f"flat            : {fl[0]}/{fl[1]} pass")
        print(f"terraced BEFORE : {fb[0]}/{fb[1]} pass")
        print(f"terraced AFTER  : {tb[0]}/{tb[1]} pass  (+{fixes['wedges']} wedges, {fixes['carves']} carves total)")
        json.dump({"rows": rows, "fixes": fixes},
                  open(ROOT / "doc" / "reports" / "template_vertical_survey.json", "w"), indent=1)
        return 0

    if "--evolve" in sys.argv:
        seeds = [int(s) for s in next((a.split("=")[1] for a in sys.argv
                 if a.startswith("--seeds=")), "11,23,37").split(",")]
        results = []
        overall = (None, -1e9)
        for seed in seeds:
            g, s = evolve_with_repair(random.Random(seed))
            terr = g["height"] == "step_down" or g["form"] == "terrace"
            results.append({"seed": seed, "generalist": round(s, 2),
                            "form": g["form"], "height": g["height"], "terraced": terr})
            print(f"seed {seed}: generalist {round(s,2)} form={g['form']} height={g['height']}"
                  f"{' <-- TERRACED' if terr else ''}")
            if s > overall[1]:
                overall = (g, s)
        # write + REPAIR the champion so the walkable map is actually whole
        data, _ = ge.compile_gallery(dict(overall[0]), gid="TemplateLab_VERT_GEN")
        data, rlog = repair(data)
        data["map_info"]["name"] = "TemplateLab_VERT_GEN"
        data["map_info"]["lookup_name"] = "TemplateLab_VERT_GEN"
        out = ROOT / "commons" / "maps" / "TemplateLab_VERT_GEN"
        out.mkdir(parents=True, exist_ok=True)
        with open(out / "map_data.json", "w", encoding="utf-8", newline="\n") as f:
            json.dump(data, f, indent=1)
        json.dump({"results": results, "champion": overall[0], "repair": rlog},
                  open(ROOT / "doc" / "reports" / "template_vertical_evolve.json", "w"), indent=1)
        print(f"champion -> TemplateLab_VERT_GEN (repair: {rlog})")
        return 0

    print(__doc__)
    return 1


if __name__ == "__main__":
    sys.exit(main())
