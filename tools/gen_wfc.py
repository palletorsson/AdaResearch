#!/usr/bin/env python3
"""gen_wfc.py — WFC OVER WALL-KIT BLOCKS (Palle's grammar-first principal).

Spec (doc/MAP_STRATEGY_FAMILY.md, "WFC over wall-kit blocks"): the original 8x8
wang blocks, wave-function-collapsed with enclosure weights per register; the
mission constrains the wave (beat cells PINNED before collapse); guaranteed edge
contract by construction; spanning-tree unseal after.

  beats     -> PINNED along a serpentine spine in teaching order, feature by role
  voltage   -> PINNED as chapel blocks, adjacent to their beat (the next serpentine
               cell, always 4-adjacent — the critical compression hut)
  the rest  -> UNPINNED cells the WAVE collapses: wall_kit enclosure/feature classes
               drawn by REGISTER weights (row thirds arrival/work/depth), honest WFC
               (minimum-entropy cell + constraint propagation), not plain sampling
  connect   -> spanning-tree unseal (wall_kit.spanning_tree) forces a gate on both
               sides of every tree seam -> 100% reachable BY CONSTRUCTION

The wave's rule (the entropy heuristic): collapse the lowest-entropy cell first
(fewest candidates after constraints). Constraints propagate: no two fully-enclosed
classes 4-adjacent (the map keeps breathing); border cells prefer open classes.
Because "none" (0-solid) lives in every register, no domain can ever empty — the
wave never contradicts.

A STRATEGY file: it only invents the FLOOR IDEA (which block sits where) and calls
map_principal.finish for every shared layer (dimensions, palettes, proximity_lod,
spawn/exit, wall runs, wall props). mission_graph supplies the mission (beats +
voltage), the size oracle (resolve_cast), feature_for, the integration wrapper,
and the supporting-cast staffer. wall_kit supplies the blocks, the edge contract,
enclosure classes, and the spanning-tree unseal.

DETERMINISM: one random.Random(seed), drawn in a fixed order (WFC collapse ->
rotations -> spanning tree). Same seed -> byte-identical map.

Usage:
  python tools/gen_wfc.py --seq=randomness [--seed=7] [--name=MissionWFC_Randomness]
  python tools/gen_wfc.py --seq=lsystems --set COLS=5 --set W:work:street=5
"""
import math
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

import wall_kit as wk               # THE block kit: KIT, ENCLOSURES, perimeter, spanning_tree
import mission_graph as mg          # mission / resolve_cast / feature_for / integration / staffing
import staging_beds as sb           # the bed a hero stands on (marriage 1)
import map_principal as mp          # THE finisher — every strategy ends in mp.finish

B, SEA = wk.B, wk.SEA               # 8, "2" — block size and the walkable floor height

# ── the knobs (rule box: --set KNOB=value, copied from gen_ants) ──────────────
COLS = 4                 # blocks across (Palle's "e.g. 4 cols")
BREATHING = 0.30         # extra unpinned fraction the wave gets to collapse (~30%)
BORDER_OPEN_BOOST = 3    # border cells prefer open classes (weight multiplier)

# REGISTER weights: the wave's bias per row-third. Knob-able per class via
# --set W:<register>:<class>=<int> (e.g. --set W:work:street=5).
REG_WEIGHTS = {
    "arrival": {"none": 5, "open": 3, "one": 2},
    "work":    {"street": 3, "colonnade": 3, "corner": 2, "none": 2},
    "depth":   {"three": 3, "channel": 2, "none": 2, "veil": 1},
}

# each WFC class -> (interior feature, perimeter enclosure). The enclosure names
# come straight from wall_kit.ENCLOSURES; the two feature classes (street,
# colonnade) carry the "open" all-gated perimeter and add their interior wall.
CLASS_REALIZE = {
    "none":      ("field", "none"),
    "open":      ("field", "open"),
    "one":       ("field", "one"),
    "corner":    ("field", "corner"),
    "channel":   ("field", "channel"),
    "three":     ("field", "three"),
    "veil":      ("field", "veil"),
    "street":    ("street", "open"),
    "colonnade": ("colonnade", "open"),
}
FULLY_ENCLOSED = {"corner", "channel", "three"}   # >= 2 solid sides — the constraint
OPEN_CLASSES = {"none", "open", "veil"}           # 0-solid field rooms — border-preferred

DIRS = {(-1, 0): 0, (0, 1): 1, (1, 0): 2, (0, -1): 3}   # n e s w -> perimeter index


# ── the build ────────────────────────────────────────────────────────────────

def build(seq, name, seed):
    beats, volt = mg.load_mission(seq)
    if not beats:
        print(f"gen_wfc: no beats in baseline for {seq}")
        return 1
    n_beats = len(beats)

    # 1. resolve the beat casts against the block budget (a block interior is
    #    ~6x6 clear of its perimeter; budget_fp 6, h 3.4)
    casts, swaps = [], []
    for b in beats:
        chosen, swapped = mg.resolve_cast(b["cast"], b.get("alts", []), 6.0, 3.4)
        casts.append(chosen)
        if swapped:
            swaps.append(f"{swapped}->{chosen}")

    # 2. the walk sequence: beats, each voltage chapel inserted right after its
    #    target beat (build_halls' spreading rule). Consecutive serpentine cells
    #    are 4-adjacent, so an inserted chapel is always adjacent to its beat.
    entries = [{"kind": "beat", "i": i, "role": beats[i]["role"], "cast": casts[i]}
               for i in range(n_beats)]
    for k, piece in enumerate(volt):
        t = round(k * (n_beats - 1) / max(1, len(volt) - 1)) if len(volt) > 1 else n_beats // 2
        for j, e in enumerate(entries):
            if e["kind"] == "beat" and e["i"] == t:
                entries.insert(j + 1, {"kind": "chapel", "i": k,
                                       "role": "voltage: " + piece, "cast": piece})
                break
    n_entries = len(entries)

    # 3. the block grid: cols x rows sized so pinned + ~30% breathing fits
    cols = max(1, COLS)
    rows = max(3, math.ceil(n_entries * (1.0 + BREATHING) / cols))
    order = []                                   # serpentine cell order
    for br in range(rows):
        cs = range(cols) if br % 2 == 0 else range(cols - 1, -1, -1)
        order += [(br, bc) for bc in cs]
    placed = {order[idx]: entries[idx] for idx in range(n_entries)}
    pinned_cells = set(placed)
    unpinned_cells = [order[idx] for idx in range(n_entries, rows * cols)]

    # register by block-row third (the palette bands align to these boundaries)
    rt1 = max(1, rows // 3)
    rt2 = max(rt1 + 1, 2 * rows // 3)

    def reg_of(br):
        if br < rt1:
            return "arrival"
        return "depth" if br >= rt2 else "work"

    def is_border(br, bc):
        return br == 0 or br == rows - 1 or bc == 0 or bc == cols - 1

    rng = random.Random(seed)                    # the ONLY randomness — fixed draw order

    # 4. WFC COLLAPSE of the unpinned cells (the entropy rule + propagation).
    domains = {cell: set(k for k, w in REG_WEIGHTS[reg_of(cell[0])].items() if w > 0)
               for cell in unpinned_cells}
    collapsed = {}

    def weight_for(cell, cls):
        br, bc = cell
        w = REG_WEIGHTS[reg_of(br)].get(cls, 0)
        if w and is_border(br, bc) and cls in OPEN_CLASSES:
            w *= BORDER_OPEN_BOOST
        return w

    while domains:
        # lowest entropy = fewest candidates after constraints (ties -> seeded)
        min_e = min(len(d) for d in domains.values())
        tied = sorted(c for c, d in domains.items() if len(d) == min_e)
        cell = rng.choice(tied)
        dom = sorted(domains[cell])
        wts = [weight_for(cell, c) for c in dom]
        cls = rng.choices(dom, weights=wts)[0] if sum(wts) > 0 else rng.choice(dom)
        collapsed[cell] = cls
        del domains[cell]
        # propagate: a fully-enclosed cell forbids fully-enclosed neighbours
        # ("none" is always in every register, so no domain can empty)
        if cls in FULLY_ENCLOSED:
            for (dr, dc) in DIRS:
                nb = (cell[0] + dr, cell[1] + dc)
                if nb in domains:
                    domains[nb] -= FULLY_ENCLOSED
                    if not domains[nb]:
                        domains[nb] = {"none"}

    # 4b. a seeded rotation per unpinned enclosure (aesthetic; connectivity is
    #     guaranteed by the unseal regardless of which way a solid side faces)
    rotations = {cell: rng.randrange(4) for cell in sorted(unpinned_cells)}

    # 5. per-block feature + perimeter sides.
    block_feature, block_sides = {}, {}
    #    pinned: gates toward the walk neighbours (serpentine prev/next)
    gates = {cell: set() for cell in pinned_cells}
    for idx in range(n_entries):
        cell = order[idx]
        for adj in (idx - 1, idx + 1):
            if 0 <= adj < n_entries:
                gates[cell].add(order[adj])
    for cell in pinned_cells:
        br, bc = cell
        sides = ["s", "s", "s", "s"]
        for (dr, dc), i in DIRS.items():
            if (br + dr, bc + dc) in gates[cell]:
                sides[i] = "g"
        e = placed[cell]
        block_sides[cell] = sides
        block_feature[cell] = ("chapel" if e["kind"] == "chapel"
                               else mg.feature_for(e["role"], e["i"]))
    #    unpinned: the collapsed class -> (feature, enclosure), rotated
    for cell in unpinned_cells:
        feature, enc = CLASS_REALIZE[collapsed[cell]]
        block_sides[cell] = list(wk.rot_sides(wk.ENCLOSURES[enc], rotations[cell]))
        block_feature[cell] = feature

    # 6. the connectivity guarantee — spanning-tree unseal (study wall_kit.build):
    #    a random DFS tree over the block grid; every tree seam is forced to a
    #    gate on BOTH incident blocks, so the whole map is one connected component
    #    however solid the other seams get.
    tree = wk.spanning_tree(cols, rows, rng)
    for br in range(rows):
        for bc in range(cols):
            for (dr, dc), i in DIRS.items():
                nb = (br + dr, bc + dc)
                if 0 <= nb[0] < rows and 0 <= nb[1] < cols \
                        and frozenset({(br, bc), nb}) in tree:
                    if block_sides[(br, bc)][i] == "s":     # unseal solids only —
                        block_sides[(br, bc)][i] = "g"      # never wall an open side

    # 7. ASSEMBLY — each block built by wall_kit, stitched into the map layers.
    W, H = cols * B, rows * B
    layers = mp.blank_layers(W, H)
    for (br, bc), feature in block_feature.items():
        bl = wk.KIT[feature]()
        wk.perimeter(bl, tuple(block_sides[(br, bc)]))
        for r in range(B):
            for c in range(B):
                R, C = br * B + r, bc * B + c
                layers["structure"][R][C] = bl["structure"][r][c]
                layers["utilities"][R][C] = bl["utilities"][r][c]
                layers["walls"][R][C] = bl["walls"][r][c]
    # seal the hull (the map boundary) so no cell leaks off the edge
    for c in range(W):
        mp.wall(layers, 0, c, "n")
        mp.wall(layers, H - 1, c, "s")
    for r in range(H):
        mp.wall(layers, r, 0, "w")
        mp.wall(layers, r, W - 1, "e")

    # 8. heroes in their blocks (the integration block, reused from mission_graph):
    #    self/field stand bare; cube/wrap/plinth/frame get sim_cube housing; else a
    #    staging bed (wall beds hang on the north wall — but never inside a chapel
    #    hut, where the hero stands at the compression centre).
    integ_of = mg._integration()

    def place_hero(token, br, bc, allow_wall):
        cr, cc = br * B + B // 2, bc * B + B // 2       # block / hut centre
        integ, cfam = integ_of.get(token, (None, None))
        if integ in ("self", "field"):
            layers["interactables"][cr][cc] = token
        elif integ in ("cube", "wrap", "plinth", "frame"):
            fam = cfam if integ in ("cube", "wrap") else integ
            layers["interactables"][cr][cc] = f"sim_cube#family:{fam}#mount:{token}"
        else:
            bed = sb.select_bed(token)
            if bed["is_wall"] and allow_wall:
                layers["interactables"][br * B + 1][cc] = f"{bed['bed']}:180#mount:{token}"
            else:
                layers["interactables"][cr][cc] = f"{bed['bed']}#mount:{token}"

    for cell in pinned_cells:
        e = placed[cell]
        place_hero(e["cast"], cell[0], cell[1], allow_wall=(e["kind"] == "beat"))

    # 9. spawn in the first beat block, exit teleporter in the last beat block
    #    (reserve them before staffing so the supporting cast respects occupancy)
    beat_cells = [order[idx] for idx in range(n_entries) if entries[idx]["kind"] == "beat"]
    fbr, fbc = beat_cells[0]
    lbr, lbc = beat_cells[-1]
    spawn_cell = (fbr * B + 1, fbc * B + 1)
    exit_cell = (lbr * B + B - 2, lbc * B + B - 2)
    layers["utilities"][spawn_cell[0]][spawn_cell[1]] = "s"
    layers["utilities"][exit_cell[0]][exit_cell[1]] = "t:restart"

    # 10. supporting cast — same-domain benches staff the beat blocks (register
    #     thirds; F = B-2 inner span). Density: arrival sparse, work dense, depth
    #     sparse+charged (the staffer's QUOTA).
    slots = []
    for idx in range(n_entries):
        if entries[idx]["kind"] != "beat":
            continue
        br, bc = order[idx]
        slots.append({"act": br, "kind": "beat", "cast": entries[idx]["cast"],
                      "oy": br * B + 1, "ox": bc * B + 1, "F": B - 2})
    staffed = mg.staff_supporting_cast(layers, slots, mg._bench_library(seq), reg_of)
    kept = []                                    # never a bench floating on void
    for s in staffed:
        r, c = s["cell"]
        if str(layers["structure"][r][c]).strip() not in ("", "0"):
            kept.append(s)
        else:
            layers["interactables"][r][c] = " "
    staffed = kept

    # 11. palette bands = the three row thirds (aligned to the block-row register)
    bands = [{"rect": [0, 0, W - 1, rt1 * B - 1], "register": "arrival"},
             {"rect": [0, rt1 * B, W - 1, rt2 * B - 1], "register": "work"},
             {"rect": [0, rt2 * B, W - 1, H - 1], "register": "depth"}]

    # 12. mission metadata (the verdict loop reads these) + the finisher contract
    hist = {}
    for cls in collapsed.values():
        hist[cls] = hist.get(cls, 0) + 1
    mission = {"beats": n_beats, "grid": [cols, rows], "pinned": n_entries,
               "collapsed": dict(sorted(hist.items())), "weights_used": REG_WEIGHTS,
               "seed": seed, "swaps": swaps, "supporting_cast": staffed}
    mp.finish(name, seq, "wfc-blocks", layers, mission, bands,
              spawn=spawn_cell, exit_cell=exit_cell, lod_radius=14.0)

    # 13. the report — the pinned spine, the collapsed histogram, the block grid
    print(f"{name}: {n_beats} beats + {len(volt)} voltage -> {n_entries} pinned "
          f"on {cols}x{rows} blocks ({W}x{H} cells), {len(unpinned_cells)} collapsed")
    print("  collapsed classes: "
          + (", ".join(f"{k}:{v}" for k, v in sorted(hist.items())) or "(none)"))
    for br in range(rows):
        cellstr = []
        for bc in range(cols):
            e = placed.get((br, bc))
            if e:
                tag = "V" if e["kind"] == "chapel" else "B"
                cellstr.append(f"{tag} {block_feature[(br, bc)]}")
            else:
                cellstr.append(f". {collapsed[(br, bc)]}")
        print("  " + " | ".join(f"{s:12s}" for s in cellstr))
    if swaps:
        print("  size-governed swaps: " + ", ".join(swaps))
    if staffed:
        print("  supporting cast: " + ", ".join(
            f"{s['name']} (beside {s['beside']}, {s['register']})" for s in staffed))
    print(f"view: /map-viewer?map={name}")
    return 0


def main():
    arg = lambda k, d: next((a.split("=", 1)[1] for a in sys.argv
                             if a.startswith(f"--{k}=")), d)
    seq = arg("seq", None)
    if not seq:
        print(__doc__)
        return 1
    # the rule box: --set KNOB=value overrides a module constant (copied from
    # gen_ants.main), extended with --set W:<register>:<class>=<int> weight knobs
    for a in sys.argv:
        if a.startswith("--set="):
            k, _, v = a[6:].partition("=")
            if k.startswith("W:") and k.count(":") == 2:
                _, reg, cls = k.split(":")
                REG_WEIGHTS.setdefault(reg, {})[cls] = int(v)
                print(f"knob {k} = {v}")
            elif k in globals() and not k.startswith("_"):
                globals()[k] = type(globals()[k])(v)
                print(f"knob {k} = {globals()[k]}")
    seed = int(arg("seed", "7"))
    name = arg("name", f"MissionWFC_{seq.title().replace('_', '')}")
    return build(seq, name, seed)


if __name__ == "__main__":
    sys.exit(main())
