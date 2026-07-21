"""germinate.py — the germination composer pilot (the connective-tissue bet).

The other strategy: composition as DEVELOPMENT, not search. Where
script_compose generates N candidate layouts and keeps the champion,
this grows ONE map the way the biome grows the living layer:

  1. FOOD    — the text-compiled desire target becomes a nutrient field
               laid along walk-time (the desire curve IS a food map).
  2. GROWTH  — a space-colonization pass (mycelium's ruled generator)
               grows the corridor from the spawn toward the food;
               floor thickness follows consumed food (subtree-weight law).
  3. SEEDS   — the hero is planted on the trunk at the register's climax;
               pins are planted; every other artifact attaches to the
               trunk in cast order and accretes a habitat sized by its
               desire kind (instrument in reach, performer gets a dwell
               bay, specimen/tableau at the visible wing).

The judge is unchanged: score_candidate from script_compose (pathfinder
gate, gaze_ride observation, experience fitness + FIT). Same court as the
search family — if a grown map stands, the strategy has proven itself.

  python tools/germinate.py --map Trans_Pit \
      --scripts doc/book/look_scripts/transformation.json --seeds 3

Sibling-only: writes commons/maps/Germ_<Map>/. Proposed edge e-germination
in doc/systems_fold.json is the design note.
"""
import argparse
import json
import math
import os
import random
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAPS_DIR = os.path.join(ROOT, "commons", "maps")
sys.path.insert(0, os.path.join(ROOT, "tools"))

import desire_timeline as dt  # noqa: E402
from script_compose import (  # noqa: E402 — same cast, pins, target, judge
    base_of, cells_of, load_target, pick, read_cast, score_candidate,
    set_rotation, size_of, write_map)

INFLUENCE = 6.0   # attractor pull radius
KILL = 1.3        # food is consumed within this radius
STEP = 1.0        # node growth step
DRIFT = 0.18      # forward bias: the walk must keep moving into the world
N_SAMPLES = 16    # desire targets are 16 samples over walk-time


# ── 1. the food map ──────────────────────────────────────────────────────

def sow_food(target, depth_span, cx, rng):
    """Desire target -> attractor points. Attention density along walk-time
    becomes nutrient density along z; lateral jitter makes the wings."""
    visual = [float(v) for v in target["visual"]] if target else [30.0] * N_SAMPLES
    food = []
    for i, v in enumerate(visual):
        z = 3.0 + (depth_span - 6.0) * i / (N_SAMPLES - 1)
        for _ in range(max(1, int(round(v / 12.0)))):
            food.append([cx + rng.gauss(0, 2.2), z + rng.gauss(0, 0.8)])
    return food


# ── 2. growth (space colonization, the mycelium generator) ───────────────

def grow(food, cx, rng):
    """Grow nodes from the root toward the food. Returns (nodes, parents,
    consumed) where consumed maps each food point to the z it fed."""
    nodes = [(float(cx), 1.0)]
    parents = [-1]
    consumed = []
    alive = [list(f) for f in food]
    for _ in range(500):
        if not alive:
            break
        pulls = {}
        for f in alive:
            best, bd = None, INFLUENCE
            for i, (nx, nz) in enumerate(nodes):
                d = math.hypot(f[0] - nx, f[1] - nz)
                if d < bd:
                    best, bd = i, d
            if best is not None:
                pulls.setdefault(best, []).append(f)
        if not pulls:
            # food out of reach: extend the deepest tip forward (the walk goes on)
            i = max(range(len(nodes)), key=lambda k: nodes[k][1])
            nodes.append((nodes[i][0], nodes[i][1] + STEP))
            parents.append(i)
            continue
        for i, fs in pulls.items():
            nx, nz = nodes[i]
            dx = sum(f[0] - nx for f in fs)
            dz = sum(f[1] - nz for f in fs)
            n = math.hypot(dx, dz) or 1.0
            nodes.append((nx + STEP * dx / n + rng.gauss(0, 0.05),
                          nz + STEP * (dz / n + DRIFT)))
            parents.append(i)
        kept = []
        for f in alive:
            eaten = False
            for nx, nz in nodes[-len(pulls):]:
                if math.hypot(f[0] - nx, f[1] - nz) <= KILL:
                    consumed.append(f)
                    eaten = True
                    break
            if not eaten:
                kept.append(f)
        alive = kept
    return nodes, parents, consumed


def trunk_of(nodes, parents):
    """Root -> deepest tip: the walk's spine."""
    tip = max(range(len(nodes)), key=lambda i: nodes[i][1])
    path, i = [], tip
    while i != -1:
        path.append(nodes[i])
        i = parents[i]
    return list(reversed(path))


# ── 3. the body: floor from growth, habitats from staging kinds ──────────

KIND_OFFSET = {"instrument": 1, "performer": 2, "specimen": 2,
               "tableau": 2, "terrain": 0}


def germinate(cast, hero_i, counter_i, script, target, seed, axis=False):
    rng = random.Random(seed)
    n_art = len(cast)
    depth_span = max(26.0, 2.0 * n_art + 14.0)
    cx = 8.0
    food = sow_food(target, depth_span, cx, rng)
    nodes, parents, consumed = grow(food, cx, rng)
    if axis:
        # the hybrid (ruled 2026-07-21): the flesh grows toward the food,
        # but the SPINE is the reading line (L-010) — a straight view
        # corridor, so the vanishing point always shows the promise.
        max_z = max(n[1] for n in nodes)
        trunk = [(cx, float(z)) for z in range(1, int(max_z) + 1)]
    else:
        trunk = trunk_of(nodes, parents)

    # bounding box -> grid
    xs = [n[0] for n in nodes]
    minx = min(xs) - 4
    width = int(max(xs) - minx + 5)
    depth = int(max(n[1] for n in nodes) + 4)
    if width % 2 == 0:
        width += 1

    def cell(p):
        return (max(0, min(width - 1, int(round(p[0] - minx)))),
                max(0, min(depth - 1, int(round(p[1])))))

    floor = [["0"] * width for _ in range(depth)]

    # consumed-food weight per z-band: thickness follows the food (mycelium law)
    weight = [0] * depth
    for f in consumed:
        z = max(0, min(depth - 1, int(round(f[1]))))
        weight[z] += 1

    def stamp(x, z, r):
        for dz in range(-r, r + 1):
            for dx in range(-r, r + 1):
                zz, xx = z + dz, x + dx
                if 0 <= zz < depth and 0 <= xx < width:
                    floor[zz][xx] = "1"

    # every node is floor; the trunk is stamped wide where food was dense
    for p in nodes:
        x, z = cell(p)
        floor[z][x] = "1"
    for p in trunk:
        x, z = cell(p)
        stamp(x, z, 2 if weight[z] >= 3 else 1)

    # ── seeds: hero on the trunk at the register's climax ──
    climax = {"arrival": 0.62, "close": 0.93}.get(script["register"], 0.74)

    def trunk_at(frac):
        return cell(trunk[max(0, min(len(trunk) - 1,
                                     int(round(frac * (len(trunk) - 1)))))])

    placements = []
    hx, hz = trunk_at(climax)
    placements.append((hx, hz, cast[hero_i]))
    stamp(hx, hz, max(1, cells_of(cast[hero_i]) // 2 + 1))
    if counter_i is not None:
        cxx, cz = trunk_at(max(0.0, climax - 0.12))
        side = 1 if rng.random() < 0.5 else -1
        placements.append((cxx + 2 * side, cz, set_rotation(cast[counter_i], 0)))
        stamp(cxx + 2 * side, cz, 1)

    # ── accretion: the rest attach in cast order; habitat by desire kind ──
    rest = [i for i in range(len(cast)) if i not in (hero_i, counter_i)]
    lo, hi = (0.12, climax - 0.18) if script["register"] != "arrival" else (climax + 0.1, 0.95)
    side = 1
    for k, i in enumerate(rest):
        frac = lo + (hi - lo) * (k / max(1, len(rest) - 1))
        tx, tz = trunk_at(frac)
        kind = dt.kind_of(base_of(cast[i]))
        off = KIND_OFFSET.get(kind, 2) + max(0, cells_of(cast[i]) // 2)
        x = tx + off * side
        placements.append((x, tz, cast[i]))
        r = max(1, cells_of(cast[i]) // 2)
        stamp(x, tz, r)
        if kind == "performer":            # the dwell bay: a pocket to stand in
            stamp(tx + (off - 1) * side, tz, 1)
        side = -side

    # spawn at the root, exit past the deepest tip (Rule 5: exit cell void)
    sx, sz = cell(trunk[0])
    stamp(sx, sz, 1)
    ex, ez = cell(trunk[-1])
    ez = min(depth - 1, ez + 1)
    for zz in range(cell(trunk[-1])[1], ez):
        floor[zz][ex] = "1"
    floor[ez][ex] = "0"

    stats = {"food": len(food), "consumed": len(consumed), "nodes": len(nodes),
             "trunk": len(trunk), "width": width, "depth": depth}
    return width, depth, floor, placements, (sx, sz), (ex, ez), stats


# ── assembly (sibling-only) ──────────────────────────────────────────────

def build(source, name, width, depth, floor, placements, spawn, exit_xy,
          exit_tok, script, seed, stats, axis=False):
    utils = [[" "] * width for _ in range(depth)]
    inter = [[" "] * width for _ in range(depth)]
    utils[spawn[1]][spawn[0]] = "s"
    utils[exit_xy[1]][exit_xy[0]] = exit_tok
    dropped = []
    for x, z, tok in placements:
        if 0 <= x < width and 0 <= z < depth and inter[z][x].strip() == "":
            inter[z][x] = tok
            if floor[z][x] == "0":
                floor[z][x] = "1"
        else:
            dropped.append(base_of(tok))
    return {
        "documentation": {
            "composer": {
                "tool": "germinate.py",
                "strategy": ("germination+axis — grown flesh, straight spine (the hybrid)" if axis else "germination — grown, not searched (edge e-germination)"),
                "register": script["register"],
                "seed": seed,
                "growth": stats,
                "dropped": dropped,
            },
            "authored_by": "text (food map) + space colonization (growth) + "
                           "staging kinds (habitats) + gaze_ride (observation)",
        },
        "layers": {"structure": floor, "utilities": utils, "interactables": inter},
        "lighting": source.get("lighting", {}),
        "map_info": {"dimensions": {"width": float(width), "depth": float(depth),
                                    "max_height": 4.0},
                     "lookup_name": name, "name": name, "format": "json"},
        "settings": source.get("settings", {}),
        "utility_definitions": source.get("utility_definitions", {}),
    }, dropped


def germinate_map(map_name, scripts, seeds, prefix, axis=False):
    script = scripts["maps"][map_name]
    source, cast, exit_tok = read_cast(map_name)
    for pin in script.get("pins", []):
        if not any(base_of(t) == base_of(pin) for t in cast):
            cast.append(pin)
            print(f"  pinned: {base_of(pin)}")
    hero_i = pick(cast, script["hero"])
    if hero_i is None:
        hero_i = max(range(len(cast)), key=lambda i: size_of(cast[i]))
    counter_i = pick(cast, script.get("counter", []), exclude=hero_i)
    target = load_target(map_name)
    print(f"  food map: {'text-compiled desire target' if target else 'flat (no target)'}")
    best = None
    cand = f"GermCand_{map_name}"
    for seed in range(seeds):
        w, dep, floor, pl, sp, ex, stats = germinate(
            cast, hero_i, counter_i, script, target, seed, axis=axis)
        data, dropped = build(source, cand, w, dep, floor, pl, sp, ex,
                              exit_tok, script, seed, stats, axis=axis)
        write_map(cand, data)
        s, detail = score_candidate(cand, cast, hero_i, dropped, target)
        g = f"{stats['consumed']}/{stats['food']} food, {stats['trunk']} trunk"
        print(f"  seed {seed}: {'--' if s is None else f'{s:.2f}'}  {detail}  [{g}]")
        if s is not None and (best is None or s > best[0]):
            best = (s, seed, data, detail)
    shutil.rmtree(os.path.join(MAPS_DIR, cand), ignore_errors=True)
    if best is None:
        print(f"{map_name}: no grown map passed the gate")
        return False
    s, seed, data, detail = best
    out = f"{prefix}{map_name}"
    data["map_info"]["lookup_name"] = out
    data["map_info"]["name"] = out
    data["documentation"]["composer"]["score"] = round(s, 3)
    data["documentation"]["composer"]["ride"] = detail
    write_map(out, data)
    print(f"{map_name} -> {out}  seed {seed}  score {s:.2f}  ({detail})")
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", help="single map; omit for every map in the script file")
    ap.add_argument("--scripts", default="doc/book/look_scripts/transformation.json")
    ap.add_argument("--seeds", type=int, default=3)
    ap.add_argument("--prefix", default="Germ_")
    ap.add_argument("--axis", action="store_true",
                    help="hybrid: grown flesh, straight view-corridor spine (L-010)")
    args = ap.parse_args()
    scripts = json.load(open(os.path.join(ROOT, args.scripts), encoding="utf-8"))
    targets = [args.map] if args.map else list(scripts["maps"].keys())
    ok = 0
    for m in targets:
        print(f"== {m} ==")
        ok += germinate_map(m, scripts, args.seeds, args.prefix, axis=args.axis)
    print(f"done: {ok}/{len(targets)} germinated")


if __name__ == "__main__":
    main()
