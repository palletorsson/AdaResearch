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


def thread_3wide(struct, D, W, spawn, anchors, tele, foot):
    """Rewrite structure to a 3-wide walk: spawn -> every artifact (nearest-neighbour order) -> teleporter.
    Each artifact sits on a platform of its footprint; everything else becomes void ('0'). Floor = '1'."""
    floor = set()

    def add(z, x):
        if 0 <= z < D and 0 <= x < W:
            floor.add((z, x))

    def plat(cz, cx, w, h):
        for z in range(cz - h // 2, cz - h // 2 + h):
            for x in range(cx - w // 2, cx - w // 2 + w):
                add(z, x)

    def seg(a, b):                                            # 3-wide L-corridor a -> b
        (z1, x1), (z2, x2) = a, b
        for x in range(min(x1, x2), max(x1, x2) + 1):
            for dz in (-1, 0, 1):
                add(z1 + dz, x)
        for z in range(min(z1, z2), max(z1, z2) + 1):
            for dx in (-1, 0, 1):
                add(z, x2 + dx)

    route = [spawn] if spawn else []
    cur = spawn or (anchors[0] if anchors else None)
    rem = list(anchors)
    while rem and cur:
        nxt = min(rem, key=lambda c: abs(c[0] - cur[0]) + abs(c[1] - cur[1]))
        route.append(nxt)
        rem.remove(nxt)
        cur = nxt
    if tele:
        route.append(tele)
    for a, b in zip(route, route[1:]):
        seg(a, b)
    for (cz, cx), (w, h) in foot.items():
        plat(cz, cx, max(w, 3), max(h, 3))
    if spawn:
        plat(spawn[0], spawn[1], 3, 3)
    if tele:
        plat(tele[0], tele[1], 3, 3)
    new = [["0" for _ in range(W)] for _ in range(D)]
    for (z, x) in floor:
        new[z][x] = "1"
    return new


def _metrics(struct, D, W, spawn, anchors, foot):
    """Reachability (BFS from spawn over floor) + footprint usage (cells under artifact platforms)."""
    from collections import deque
    floor = {(z, x) for z in range(D) for x in range(min(W, len(struct[z])))
             if str(struct[z][x]).strip() == "1"}
    reach = set()
    if spawn and spawn in floor:
        dq = deque([spawn])
        reach.add(spawn)
        while dq:
            z, x = dq.popleft()
            for dz, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (z + dz, x + dx)
                if n in floor and n not in reach:
                    reach.add(n)
                    dq.append(n)
    reserved = set()
    for (cz, cx) in anchors:
        w, h = foot.get((cz, cx), (3, 3))
        w, h = max(w, 3), max(h, 3)
        for z in range(cz - h // 2, cz - h // 2 + h):
            for x in range(cx - w // 2, cx - w // 2 + w):
                if (z, x) in floor:
                    reserved.add((z, x))
    fc = max(1, len(floor))
    return {
        "reachablePct": round(100 * len(reach) / fc),
        "unreachable": [[z, x] for (z, x) in sorted(floor - reach)],
        "reserved": [[z, x] for (z, x) in sorted(reserved)],
        "floorCells": len(floor),
        "reservedCells": len(reserved),
        "freePct": round(100 * (len(floor) - len(reserved)) / fc),
    }


def fold(map_name, cap=3, thread_path=True):
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
                ww = min(w, W - 4)
                spot = land(ww, h)
                if spot:
                    return spot[0], spot[1], ww, h
        return None

    placed, unplaced, footprints = [], [], {}
    for reg, chunk in clusters:
        ids = [b for b, _, _ in chunk]
        res = land_flex(len(ids))
        if res:
            cz, cx, w, h = res
            token = ("curation_station#artifacts:" + ",".join(ids)
                     + "#with_wall:true#with_pillars:false#with_barrier:true")
            new_inter[cz][cx] = token
            placed.append((reg, ids, (cz, cx)))
            footprints[(cz, cx)] = (w, h)
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

    # locate spawn / teleporter / artifact anchors (+ footprints) for the walk and the metrics
    spawn_cell = tele_cell = None
    for z in range(D):
        for x in range(min(W, len(util[z]))):
            u = str(util[z][x]).strip()
            if u[:1] == "s" and u[:2] not in ("su",):
                spawn_cell = (z, x)
            elif u[:1] == "t":
                tele_cell = (z, x)
    anchors, foot = [], {}
    for z in range(D):
        for x in range(min(W, len(new_inter[z]))):
            c = str(new_inter[z][x]).strip()
            if c and not c.startswith("#"):
                anchors.append((z, x))
                foot[(z, x)] = footprints.get((z, x), (3, 3))
    if thread_path:
        # 3-wide walk: spawn -> every artifact -> teleporter; the rest of the grid becomes void.
        m["layers"]["structure"] = thread_3wide(struct, D, W, spawn_cell, anchors, tele_cell, foot)
    metrics = _metrics(m["layers"]["structure"] if thread_path else struct, D, W, spawn_cell, anchors, foot)

    m["layers"]["interactables"] = new_inter
    m["map_info"]["name"] = map_name + "_Folded"
    m["map_info"]["lookup_name"] = map_name + "_Folded"
    m["map_info"]["description"] = ("Augmented %s: %d small artifacts folded into %d wall sections on the "
                                    "clear floor; %d large artifacts kept as landmarks." %
                                    (map_name, sum(len(c) for _, c, _ in placed), len(placed),
                                     sum(1 for z in range(D) for x in range(W)
                                         if str(new_inter[z][x]).strip() and "curation_station" not in str(new_inter[z][x])
                                         and is_large(str(new_inter[z][x]).split(":")[0].split("#")[0]))))
    return m, placed, unplaced, metrics


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", required=True)
    ap.add_argument("--no-path", action="store_true", help="keep the authored floor instead of the 3-wide walk")
    ap.add_argument("--stdout", action="store_true", help="print folded map JSON to stdout, no file write")
    args = ap.parse_args()
    res = fold(args.map, thread_path=not args.no_path)
    if not res:
        return
    m, placed, unplaced, metrics = res
    if args.stdout:
        print(json.dumps({"folded": m, "placed": placed, "unplaced": unplaced, "metrics": metrics}))
        return
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
