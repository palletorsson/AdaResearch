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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("seq")
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
        x = max(x, 0)
        z = max(z, 0)
        while (x, z) in occupied:
            z += 1
        occupied.add((x, z))
        cells.setdefault(z, {})[x] = tok
        return (x, z)

    spine = [p for p in pearls if spread[p] < BRANCH]
    branch = [p for p in pearls if spread[p] >= BRANCH]
    spine_xz = []
    dists = []

    if a.curve:
        import numpy as np
        AMP, WAVELEN, DSCALE = 5, 13.0, a.dscale
        cx = AMP + ALCOVE + MARGIN
        s, last = 0.0, None
        for p in spine:
            if last is not None:
                ev, lv = emb.get(p), emb.get(last)
                dd = max(0.0, 1.0 - float(np.dot(ev, lv))) if (ev is not None and lv is not None) else 0.3
                dists.append(dd)
                s += max(DSCALE * dd, base(p) / 2 + base(last) / 2 + GAP)
            x = cx + int(round(AMP * math.sin(s / WAVELEN * 2 * math.pi)))
            spine_xz.append(place(x, 3 + int(round(s)), p))
            last = p
    else:
        cx = ALCOVE + MARGIN
        z, lb = 2, 0.0
        for p in spine:
            z += max(1, int(round(lb / 2 + base(p) / 2))) + GAP
            spine_xz.append(place(cx, z, p))
            z = spine_xz[-1][1]
            lb = base(p)

    side = 1
    for i, p in enumerate(branch):
        anchor = spine_xz[min(len(spine_xz) - 1, i * len(spine_xz) // max(1, len(branch)))] if spine_xz else (cx, 3)
        place(anchor[0] + side * ALCOVE, anchor[1], p)
        side = -side

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
            "description": "Generated by lay_necklace.py --%s from the three orders of '%s'. Spine -> the "
                           "%s; branches -> alcoves. Pearls sized by footprint (= the small/medium/large tier)."
                           % ("curve" if a.curve else "corridor", a.seq,
                              "sine-meander (arc-length = concept-distance + footprint)" if a.curve else "corridor"),
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
    print("wrote %s : %dx%d  |  %d spine + %d alcoves%s" % (name, W, depth, len(spine), len(branch), stretch))


if __name__ == "__main__":
    main()
