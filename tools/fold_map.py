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


def thread_walk(struct, D, W, spawn, anchors, tele, foot, width=3, order="nearest"):
    """Rewrite structure to a `width`-wide walk: spawn -> every artifact -> teleporter. Each artifact sits
    on a platform of its footprint; everything else becomes void ('0'). Floor = '1'.
    order='nearest' = greedy shortest hop; order='sequence' = visit anchors in the given (list) order."""
    floor = set()
    band = list(range(-((width - 1) // 2), width // 2 + 1))   # 3:[-1,0,1] 2:[0,1] 1:[0] 4:[-1,0,1,2]

    def add(z, x):
        if 0 <= z < D and 0 <= x < W:
            floor.add((z, x))

    def plat(cz, cx, w, h):
        for z in range(cz - h // 2, cz - h // 2 + h):
            for x in range(cx - w // 2, cx - w // 2 + w):
                add(z, x)

    def seg(a, b):                                            # width-wide L-corridor a -> b
        (z1, x1), (z2, x2) = a, b
        for x in range(min(x1, x2), max(x1, x2) + 1):
            for d in band:
                add(z1 + d, x)
        for z in range(min(z1, z2), max(z1, z2) + 1):
            for d in band:
                add(z, x2 + d)

    route = [spawn] if spawn else []
    if order == "sequence":
        route += list(anchors)                               # caller pre-orders anchors by roster rank
    else:
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


def fold(map_name, cap=3, thread_path=True, artifacts=None, walk_width=3, walk_order="nearest"):
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

    def is_large(a):
        sp = sizes.get(a)
        return sp is not None and max(sp[0], sp[1]) > LARGE_M

    def is_crit(a):
        return edges.get(a) in CRITICAL_EDGES

    # New interactables grid. MAP MODE keeps larges + raised displays in place and pulls floor smalls
    # out to fold; LIST MODE folds an arbitrary roster (the edited table of contents).
    new_inter = [["" for _ in range(W)] for _ in range(D)]
    smalls = {"formal": [], "critical": []}   # (base, z|None, x|None)
    roster = []
    grid_ids = []                              # list-mode landmarks, placed once the helpers exist
    seen = set()
    if artifacts is None:
        for z in range(D):
            for x in range(min(W, len(inter[z]))):
                c = str(inter[z][x]).strip()
                if not c or c.startswith("#"):
                    continue
                base = c.split(":")[0].split("#")[0]
                reg = "critical" if is_crit(base) else "formal"
                if base in INFRA or is_large(base):
                    new_inter[z][x] = c                      # landmark / infra stays exactly where it is
                    if base not in INFRA and base not in seen:
                        seen.add(base)
                        roster.append({"id": base, "role": "grid", "register": reg})
                elif base in seen:
                    continue
                elif str(struct[z][x]).strip() != "1":
                    seen.add(base)
                    new_inter[z][x] = c                      # raised/pedestal = authored display, keep it
                    roster.append({"id": base, "role": "wall", "register": reg})
                else:
                    seen.add(base)
                    smalls[reg].append((base, z, x))
                    roster.append({"id": base, "role": "wall", "register": reg})
    else:
        for a in artifacts:
            aid = str(a.get("id", "")).strip()
            if not aid or aid in seen or aid in INFRA:
                continue
            seen.add(aid)
            role = a.get("role") or ("grid" if is_large(aid) else "wall")
            reg = a.get("register") or ("critical" if is_crit(aid) else "formal")
            roster.append({"id": aid, "role": role, "register": reg})
            if role == "grid":
                grid_ids.append(aid)
            else:
                smalls[reg].append((aid, None, None))

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
            if z is not None:
                occ.add((z, x))                              # keep lone smalls' cells out of section footprints

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

    def land_landmark():
        for w, h in ((5, 5), (4, 4), (3, 3)):
            spot = land(w, h)
            if spot:
                return spot[0], spot[1], w, h
        return None

    footprints, stray = {}, []
    for aid in grid_ids:                                     # list-mode landmarks placed on clear floor
        res = land_landmark()
        if res:
            cz, cx, w, h = res
            new_inter[cz][cx] = aid
            footprints[(cz, cx)] = (w, h)
        else:
            stray.append(aid)

    placed, unplaced = [], []
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
            if z is not None:
                new_inter[z][x] = base                       # map mode: keep its authored cell
            else:
                fc = free_cell()
                if fc:
                    new_inter[fc[0]][fc[1]] = base           # list mode: drop on a clear cell
    for reg, chunk in unplaced:
        for base, z, x in chunk:
            if z is not None and (z, x) not in occ:
                new_inter[z][x] = base
                occ.add((z, x))
            else:
                fc = free_cell()
                if fc:
                    new_inter[fc[0]][fc[1]] = base
    for aid in stray:
        fc = free_cell()
        if fc:
            new_inter[fc[0]][fc[1]] = aid

    # detect teleporter (+ the authored spawn, used only when not threading a walk)
    orig_spawn = tele_cell = None
    for z in range(D):
        for x in range(min(W, len(util[z]))):
            u = str(util[z][x]).strip()
            if u[:1] == "s" and u[:2] not in ("su",):
                orig_spawn = (z, x)
            elif u[:1] == "t":
                tele_cell = (z, x)
    anchors, foot = [], {}
    for z in range(D):
        for x in range(min(W, len(new_inter[z]))):
            c = str(new_inter[z][x]).strip()
            if c and not c.startswith("#"):
                anchors.append((z, x))
                foot[(z, x)] = footprints.get((z, x), (3, 3))
    if walk_order == "sequence":
        # visit anchors in the order they appear in the roster (a section ranks by its earliest member)
        order_rank = {p["id"]: i for i, p in enumerate(roster)}

        def _rank(cell):
            tok = str(new_inter[cell[0]][cell[1]]).strip()
            if "curation_station#artifacts:" in tok:
                mids = tok.split("#artifacts:")[1].split("#")[0].split(",")
                return min((order_rank.get(a.strip(), 9999) for a in mids), default=9999)
            base = tok.split(":")[0].split("#")[0]
            return order_rank.get(base, 9999)

        anchors = sorted(anchors, key=_rank)
    if thread_path:
        # the walk starts at the (0,0) corner, touches every artifact, ends at the teleporter.
        start = (0, 0)
        m["layers"]["structure"] = thread_walk(struct, D, W, start, anchors, tele_cell, foot,
                                                width=walk_width, order=walk_order)
        new_util = [["" for _ in range(W)] for _ in range(D)]
        for z in range(D):
            for x in range(min(W, len(util[z]))):
                u = str(util[z][x]).strip()
                if u and not (u[:1] == "s" and u[:2] not in ("su",)):
                    new_util[z][x] = u                       # keep teleporter + everything but the old spawn
        new_util[0][0] = "s"                                 # spawn at the corner where the walk begins
        m["layers"]["utilities"] = new_util
    else:
        start = orig_spawn
    metrics = _metrics(m["layers"]["structure"] if thread_path else struct, D, W, start, anchors, foot)

    m["layers"]["interactables"] = new_inter
    m["map_info"]["name"] = map_name + "_Folded"
    m["map_info"]["lookup_name"] = map_name + "_Folded"
    m["map_info"]["description"] = ("Folded %s: %d wall sections + %d landmarks on a 3-wide walk." %
                                    (map_name, len(placed), sum(1 for r in roster if r["role"] == "grid")))
    return m, placed, unplaced, metrics, roster


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", required=True)
    ap.add_argument("--no-path", action="store_true", help="keep the authored floor instead of the 3-wide walk")
    ap.add_argument("--stdout", action="store_true", help="print folded map JSON to stdout, no file write")
    ap.add_argument("--artifacts", help="JSON list of {id,role,register} to fold instead of the map's own")
    ap.add_argument("--walk-width", type=int, default=3, help="walk corridor width in cells (default 3)")
    ap.add_argument("--walk-order", choices=["nearest", "sequence"], default="nearest",
                    help="nearest = shortest hop; sequence = visit in table-of-contents order")
    args = ap.parse_args()
    artifacts = json.loads(args.artifacts) if args.artifacts else None
    res = fold(args.map, thread_path=not args.no_path, artifacts=artifacts,
               walk_width=args.walk_width, walk_order=args.walk_order)
    if not res:
        return
    m, placed, unplaced, metrics, roster = res
    if args.stdout:
        print(json.dumps({"folded": m, "placed": placed, "unplaced": unplaced,
                          "metrics": metrics, "roster": roster}))
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
