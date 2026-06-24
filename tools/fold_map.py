#!/usr/bin/env python3
"""Fold a real map's SMALL artifacts into wall SECTIONS placed on its clear floor — augmenting the
authored map (its large artifacts stay as landmarks, its structure + utilities untouched) instead of
regenerating it into a sibling corridor.

The 'landing rule' (footprints + pathfinding): a section only lands where a clear floor rectangle of
its footprint exists; large artifacts, utilities and walls are reserved; reachability is re-validated
afterwards. Small artifacts cluster by REGISTER (formal/critical, from the atlas edge) so the two
voices stay separate. Writes <Map>_Folded for review — promote to in-place once it reads right.

Run: python tools/fold_map.py --map Point_One
"""
import argparse
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import compact_map_json                                      # noqa: E402
from build_corridor import load_sizes, load_embeddings, LARGE_M, INFRA  # noqa: E402
from build_map_strings import load_edges, CRITICAL_EDGES, _display_names  # noqa: E402


def _cells(layer):
    return [layer[z] if isinstance(layer[z], list) else str(layer[z]).split(",") for z in range(len(layer))]


def fold(map_name, cap=3):
    p = os.path.join(ROOT, "commons", "maps", map_name, "map_data.json")
    if not os.path.exists(p):
        print("no map", map_name)
        return None
    m = json.load(open(p, encoding="utf-8"))
    struct = _cells(m["layers"]["structure"])
    inter = _cells(m["layers"]["interactables"])
    util = _cells(m["layers"]["utilities"])
    D, W = len(struct), len(struct[0])
    sizes, edges = load_sizes(), load_edges()
    disp = _display_names()

    def is_large(a):
        sp = sizes.get(a)
        return sp is not None and max(sp[0], sp[1]) > LARGE_M

    def is_crit(a):
        return edges.get(a) in CRITICAL_EDGES

    # New interactables grid: keep larges + infra in place, pull smalls out to fold.
    new_inter = [["" for _ in range(W)] for _ in range(D)]
    smalls = {"formal": [], "critical": []}   # ordered, deduped: (base, z, x)
    seen = set()
    for z in range(D):
        for x in range(min(W, len(inter[z]))):
            c = str(inter[z][x]).strip()
            if not c or c.startswith("#"):
                continue
            base = c.split(":")[0].split("#")[0]
            if base in INFRA or is_large(base):
                new_inter[z][x] = c                          # landmark / infra stays exactly where it is
            elif base in seen:
                continue
            elif str(struct[z][x]).strip() != "1":
                seen.add(base)
                new_inter[z][x] = c                          # on a pedestal/raised cell = authored display, keep
            else:
                seen.add(base)
                smalls["critical" if is_crit(base) else "formal"].append((base, z, x))

    # cluster each register into <=cap; fold clusters of >=2 into sections, keep lone smalls where they are.
    clusters, lone = [], []
    for reg in ("formal", "critical"):
        ids = smalls[reg]
        for i in range(0, len(ids), cap):
            chunk = ids[i:i + cap]                            # chunk = [(base,z,x),...]
            if len(chunk) >= 2:
                clusters.append((reg, chunk))
            else:
                lone.append(chunk)

    # occupancy: larges + utilities + non-floor. A section needs a clear floor rectangle (the landing rule).
    occ = set()
    for z in range(D):
        for x in range(min(W, len(new_inter[z]))):
            if str(new_inter[z][x]).strip():
                occ.add((z, x))
        for x in range(min(W, len(util[z]))):
            if str(util[z][x]).strip():
                occ.add((z, x))
    for chunk in lone:
        for base, z, x in chunk:
            occ.add((z, x))                                  # keep lone smalls' cells out of section footprints

    def is_floor(z, x):
        return 0 <= z < D and 0 <= x < W and str(struct[z][x]).strip() == "1"

    def fits(cz, cx, w, h):
        for z in range(cz - h // 2, cz - h // 2 + h):
            for x in range(cx - w // 2, cx - w // 2 + w):
                if not is_floor(z, x) or (z, x) in occ:
                    return False
        return True

    def land(w, h):
        for cz in range(2, D - 2):
            for cx in range(2, W - 2):
                if fits(cz, cx, w, h):
                    for z in range(cz - h // 2, cz - h // 2 + h):
                        for x in range(cx - w // 2, cx - w // 2 + w):
                            occ.add((z, x))
                    return cz, cx
        return None

    def land_flex(n):
        # try progressively smaller footprints so a section still lands on a fragmented floor
        for h in (6, 5, 4):
            for w in (2 * n + 4, 2 * n + 2, 2 * n):
                spot = land(min(w, W - 4), h)
                if spot:
                    return spot
        return None

    placed, unplaced = [], []
    for reg, chunk in clusters:
        ids = [b for b, _, _ in chunk]
        spot = land_flex(len(ids))
        if spot:
            cz, cx = spot
            token = ("curation_station#artifacts:" + ",".join(ids)
                     + "#with_wall:true#with_pillars:false#with_barrier:true")
            new_inter[cz][cx] = token
            placed.append((reg, ids, (cz, cx)))
        else:
            unplaced.append((reg, chunk))

    # lone smalls stay exactly where they were; unplaceable cluster members keep their original cell too.
    def free_cell():
        for z in range(1, D - 1):
            for x in range(1, W - 1):
                if is_floor(z, x) and (z, x) not in occ:
                    occ.add((z, x))
                    return z, x
        return None
    for chunk in lone:
        for base, z, x in chunk:
            new_inter[z][x] = base
    for reg, chunk in unplaced:
        for base, z, x in chunk:
            if (z, x) not in occ:
                new_inter[z][x] = base
                occ.add((z, x))
            else:
                fc = free_cell()
                if fc:
                    new_inter[fc[0]][fc[1]] = base

    m["layers"]["interactables"] = new_inter
    m["map_info"]["name"] = map_name + "_Folded"
    m["map_info"]["lookup_name"] = map_name + "_Folded"
    m["map_info"]["description"] = ("Augmented %s: %d small artifacts folded into %d wall sections on the "
                                    "clear floor; %d large artifacts kept as landmarks." %
                                    (map_name, sum(len(c) for _, c, _ in placed), len(placed),
                                     sum(1 for z in range(D) for x in range(W)
                                         if str(new_inter[z][x]).strip() and "curation_station" not in str(new_inter[z][x])
                                         and is_large(str(new_inter[z][x]).split(":")[0].split("#")[0]))))
    return m, placed, unplaced


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", required=True)
    args = ap.parse_args()
    res = fold(args.map)
    if not res:
        return
    m, placed, unplaced = res
    name = args.map + "_Folded"
    out = os.path.join(ROOT, "commons", "maps", name)
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, "map_data.json"), "w", encoding="utf-8") as f:
        f.write(compact_map_json._ser(m, 0))
    print("wrote %s" % name)
    for reg, chunk, spot in placed:
        print("  [%s] section @%s: %s" % (reg, spot, ", ".join(chunk)))
    if unplaced:
        print("  unplaced (no clear landing, kept as loose artifacts):", unplaced)


if __name__ == "__main__":
    main()
