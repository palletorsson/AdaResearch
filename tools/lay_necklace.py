#!/usr/bin/env python3
"""lay_necklace.py - the generator (#4): a sequence's three orders -> a 2D map.

three_orders gives the weighted optimized order + SPINE (orders agree) vs BRANCH (orders fight); the
size oracle gives footprints. Spine -> a path spawn->teleport spaced by size; branches -> alcoves.

  default  : a straight central corridor.
  --curve  : a SINE-MEANDER where the arc-length between consecutive pearls = their concept-distance
             (atlas embedding) AND their footprint clearance. The 1D order becomes a 2D curve whose
             geometry shows where the order strains - two conceptually distant pearls forced adjacent
             get a long stretch; big pearls (large/applied tier) claim more arc than small ones.

Usage:  python tools/lay_necklace.py <sequence> [--curve] [--max N] [--wp/--wo/--wc W]
Writes  commons/maps/<Seq>_Necklace/map_data.json
"""
import json, os, sys, argparse, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from three_orders import compute

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRANCH = 0.45
ALCOVE = 4
MARGIN = 3
GAP = 2
TIER_ORDER = {"small": 0, "medium": 1, "large": 2, "applied": 3}


def load_concept_tiers(seq):
    """artifact -> (concept, tier) from doc/<seq>_concept_map.json's concept_meta."""
    for fn in ("%s_concept_map.json" % seq, "%ss_concept_map.json" % seq,
               "%s_concept_map.json" % seq.rstrip("s")):
        p = os.path.join(ROOT, "doc", fn)
        if os.path.exists(p):
            cm = json.load(open(p, encoding="utf-8")).get("concept_meta", {})
            a2c = {}
            for cn, meta in cm.items():
                for tier, arts in (meta.get("tiers") or {}).items():
                    for art in arts:
                        a2c[art] = (cn, tier)
            return a2c
    return {}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("seq")
    ap.add_argument("--concepts", action="store_true", help="pearls = concepts; tiers fan out by scale")
    ap.add_argument("--curve", action="store_true", help="sine-meander spaced by concept-distance")
    ap.add_argument("--dscale", type=float, default=11.0, help="cells per unit concept-distance (stretch)")
    ap.add_argument("--max", type=int, default=16)
    ap.add_argument("--wp", type=float, default=1.0)
    ap.add_argument("--wo", type=float, default=1.0)
    ap.add_argument("--wc", type=float, default=1.0)
    a = ap.parse_args()

    d = compute(a.seq, min_pearls=3)
    if not d:
        print("no data for", a.seq)
        return
    n = d["n"]
    ws = (a.wp + a.wo + a.wc) or 1.0
    consensus = [(a.wp * d["ped"][i] + a.wo * d["onto"][i] + a.wc * d["crit"][i]) / ws for i in range(n)]
    order = sorted(range(n), key=lambda i: consensus[i])
    pearls = [d["pearls"][i] for i in order][: a.max]
    spread = {d["pearls"][i]: d["spread"][i] for i in range(n)}

    sz = json.load(open(os.path.join(ROOT, "commons", "data", "artifact_sizes.json"), encoding="utf-8")).get("sizes", {})

    def base(p):
        return float((sz.get(p) or {}).get("base_m", 1.0) or 1.0)

    emb = {}
    if a.curve:
        import numpy as np
        z = np.load(os.path.join(ROOT, "doc", "atlas", "artifact_embeddings.npz"), allow_pickle=True)
        emb = {str(i): v for i, v in zip(z["ids"], z["vectors"])}

    occupied = set()
    cells = {}

    def place(x, z, tok):
        z = max(z, 0)  # x may go negative; the bounding-box shift pulls it into the room
        while (x, z) in occupied:
            z += 1
        occupied.add((x, z))
        cells.setdefault(z, {})[x] = tok
        return (x, z)

    spine_xz = []
    dists = []
    cons = {d["pearls"][i]: consensus[i] for i in range(n)}

    def fold_path(total, amp, drop):
        cxc = amp + ALCOVE + MARGIN
        pts, arc, phi = [(cxc, 3.0)], [0.0], 0.0
        while arc[-1] < total + 3:
            x0, z0 = cxc + amp * math.sin(phi), 3.0 + (phi / (2 * math.pi)) * drop
            phi += 0.06
            x1, z1 = cxc + amp * math.sin(phi), 3.0 + (phi / (2 * math.pi)) * drop
            pts.append((x1, z1))
            arc.append(arc[-1] + math.hypot(x1 - x0, z1 - z0))
        return pts, arc

    if a.concepts:
        import numpy as np
        import bisect
        a2c = load_concept_tiers(a.seq)
        groups = {}
        for p in d["pearls"]:
            if p in a2c:
                cn, tier = a2c[p]
                groups.setdefault(cn, []).append((TIER_ORDER.get(tier, 9), tier, p))
        for cn in groups:
            groups[cn].sort()

        def crank(cn):
            rs = [cons[x] for _, _, x in groups[cn] if x in cons]
            return sum(rs) / len(rs) if rs else 1.0

        def centroid(cn):
            vs = [emb[x] for _, _, x in groups[cn] if x in emb]
            return np.mean(vs, axis=0) if vs else None

        corder = sorted(groups, key=crank)[: a.max]
        hero = {cn: max(groups[cn], key=lambda t: base(t[2]))[2] for cn in corder}  # top-scale = the hero
        small = {cn: [x for _, _, x in groups[cn] if x != hero[cn] and base(x) <= 2.0] for cn in corder}
        cumS = [0.0]
        for i in range(1, len(corder)):
            c0, c1 = centroid(corder[i - 1]), centroid(corder[i])
            if c0 is not None and c1 is not None:
                dd = max(0.0, 1.0 - float(np.dot(c1, c0) / (np.linalg.norm(c1) * np.linalg.norm(c0) + 1e-9)))
            else:
                dd = 0.3
            dists.append(dd)
            h0, h1 = hero[corder[i - 1]], hero[corder[i]]
            cumS.append(cumS[-1] + max(a.dscale * dd, base(h1) / 2 + base(h0) / 2 + GAP + 1))
        pts, arc = fold_path(cumS[-1] if cumS else 0.0, 9.0, 8.0)
        n_arts = 0
        for ci, (cn, s) in enumerate(zip(corder, cumS)):
            k = min(bisect.bisect_left(arc, s), len(pts) - 1)
            ox, oz = int(round(pts[k][0])), int(round(pts[k][1]))
            spine_xz.append(place(ox, oz, hero[cn]))      # the concept's hero on the curve
            n_arts += 1
            sd = 1 if ci % 2 == 0 else -1                 # its small tiers tuck in beside it (they're small)
            for j, art in enumerate(small[cn][:3]):
                place(ox + sd * (int(round(base(hero[cn]) / 2)) + 1 + j), oz, art)
                n_arts += 1
        layout_desc = "%d concepts (hero on the curve + small tiers beside; footprint = scale)" % len(corder)
    else:
        cx = ALCOVE + MARGIN
        spine = [p for p in pearls if spread[p] < BRANCH]
        branch = [p for p in pearls if spread[p] >= BRANCH]
        if a.curve:
            import numpy as np
            import bisect
            cumS = [0.0]
            for i in range(1, len(spine)):
                a0, a1 = spine[i - 1], spine[i]
                ev, lv = emb.get(a1), emb.get(a0)
                dd = max(0.0, 1.0 - float(np.dot(ev, lv))) if (ev is not None and lv is not None) else 0.3
                dists.append(dd)
                cumS.append(cumS[-1] + max(a.dscale * dd, base(a1) / 2 + base(a0) / 2 + GAP))
            pts, arc = fold_path(cumS[-1] if cumS else 0.0, 8.0, 7.0)
            for p, s in zip(spine, cumS):
                k = min(bisect.bisect_left(arc, s), len(pts) - 1)
                spine_xz.append(place(int(round(pts[k][0])), int(round(pts[k][1])), p))
        else:
            z, lb = 2, 0.0
            for p in spine:
                z += max(1, int(round(lb / 2 + base(p) / 2))) + GAP
                spine_xz.append(place(cx, z, p))
                z = spine_xz[-1][1]
                lb = base(p)
        sd = 1
        for i, p in enumerate(branch):
            anchor = spine_xz[min(len(spine_xz) - 1, i * len(spine_xz) // max(1, len(branch)))] if spine_xz else (cx, 3)
            place(anchor[0] + sd * ALCOVE, anchor[1], p)
            sd = -sd
        layout_desc = "%d spine + %d alcoves" % (len(spine), len(branch))

    # size the grid to the bounding box, shift so everything sits inside the margin
    allx = [x for row in cells.values() for x in row]
    allz = list(cells)
    minx, maxx = min(allx), max(allx)
    shift = MARGIN - minx
    W = (maxx - minx) + 2 * MARGIN + 1
    depth = max(allz) + MARGIN + 2
    inter = [[" "] * W for _ in range(depth)]
    struct = [["1"] * W for _ in range(depth)]
    util = [[" "] * W for _ in range(depth)]
    for z, row in cells.items():
        for x, tok in row.items():
            inter[z][x + shift] = tok

    sx = (spine_xz[0][0] + shift) if spine_xz else W // 2
    ex, ez = (spine_xz[-1][0] + shift, spine_xz[-1][1]) if spine_xz else (W // 2, depth - 3)
    util[1][min(sx, W - 1)] = "s"
    tz = min(ez + 1, depth - 2)
    util[tz][min(ex, W - 1)] = "t"
    struct[tz][min(ex, W - 1)] = "0"

    stretch = ("  |  curve: arc-length = concept-distance, %.2f..%.2f" % (min(dists), max(dists))) if dists else ""
    md = {
        "layers": {"interactables": inter, "structure": struct, "utilities": util},
        "lighting": {"ambient_color": [0.6, 0.62, 0.68], "ambient_energy": 1.2,
                     "directional_light": {"color": [1.0, 0.97, 0.92], "direction": [-0.4, -0.8, -0.3],
                                           "enabled": True, "energy": 1.0}},
        "map_info": {
            "description": "Generated by lay_necklace.py --%s from the three orders of '%s'. %s. Pearls "
                           "sized by footprint (= the small/medium/large tier)."
                           % ("concepts" if a.concepts else "curve" if a.curve else "corridor", a.seq,
                              "Each node is a CONCEPT; its toy->applied tier-ladder fans out by scale" if a.concepts
                              else "Spine is a folded sine-meander (arc-length = concept-distance); branches alcove off it"
                              if a.curve else "Spine is a central corridor; branches alcove off it"),
            "dimensions": {"width": float(W), "depth": float(depth), "max_height": 3.0},
            "format": "json", "lookup_name": "%s_Necklace" % a.seq.capitalize(),
            "name": "%s Necklace" % d.get("name", a.seq), "title": "%s - necklace" % a.seq, "version": "1.1"},
        "settings": {"background": {"color": [0.18, 0.2, 0.28], "type": "sky"},
                     "cube_size": 1.0, "enable_physics": True, "gutter": 0.0, "show_grid": True},
        "utility_definitions": {"t": {"description": "Return to the lab", "name": "Exit",
                                      "properties": {"action": "next_in_sequence"}, "type": "teleporter"}},
    }
    name = "%s_Necklace" % a.seq.capitalize()
    out = os.path.join(ROOT, "commons", "maps", name)
    os.makedirs(out, exist_ok=True)
    json.dump(md, open(os.path.join(out, "map_data.json"), "w", encoding="utf-8"), indent="\t")
    print("wrote %s : %dx%d  |  %s%s" % (name, W, depth, layout_desc, stretch))


if __name__ == "__main__":
    main()
