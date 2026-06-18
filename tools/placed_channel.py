"""The reverse half of the loop: measure a BUILT map back into a distance channel.

mindmap_to_map.py turns the conceptual arrangement into a level. This reads that level back:
it measures the real grid distance between where each concept's artifact actually landed, and
compares it to the conceptual distance the mind-map intended. The comparison is the feedback —
it names where the built level AGREES with the order of things and where it pulled apart things
that belong together (or jammed together things that are far apart).

Writes doc/<domain>_placed.json and injects a `placed` block (normalised positions + matrix +
correlation) into doc/<domain>_mindmap.json, so the /mind-map page can show an "as built" basis
beside the conceptual one — the loop made visible.

Run:  python tools/placed_channel.py transformation [--map=MindMap_Transformation]
"""
import json, os, sys, math

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(ROOT, "doc")
MAPS = os.path.join(ROOT, "commons", "maps")


def read_placements(mapname):
    d = json.load(open(os.path.join(MAPS, mapname, "map_data.json"), encoding="utf-8"))
    rows = d["layers"]["interactables"]
    GZ, GX = len(rows), len(rows[0]) if rows else 0
    placed = {}
    for r, row in enumerate(rows):
        for c, cell in enumerate(row or []):
            if isinstance(cell, str) and cell.strip():
                lk = cell.split(":")[0].strip()
                if lk:
                    placed[lk] = (r, c)
    return placed, GX, GZ


def spearman(a, b):
    n = len(a)
    if n < 3:
        return 0.0
    def ranks(v):
        order = sorted(range(n), key=lambda i: v[i])
        rk = [0.0] * n
        i = 0
        while i < n:
            j = i
            while j + 1 < n and v[order[j + 1]] == v[order[i]]:
                j += 1
            avg = (i + j) / 2.0
            for k in range(i, j + 1):
                rk[order[k]] = avg
            i = j + 1
        return rk
    ra, rb = ranks(a), ranks(b)
    ma, mb = sum(ra) / n, sum(rb) / n
    num = sum((ra[i] - ma) * (rb[i] - mb) for i in range(n))
    da = math.sqrt(sum((ra[i] - ma) ** 2 for i in range(n)))
    db = math.sqrt(sum((rb[i] - mb) ** 2 for i in range(n)))
    return round(num / (da * db), 3) if da and db else 0.0


def build(domain, mapname):
    mm = json.load(open(os.path.join(DOC, domain + "_mindmap.json"), encoding="utf-8"))
    concepts = sorted(mm["concepts"], key=lambda c: c["order"])
    # representative lookup per concept_order = the one mindmap_to_map placed (first found in map)
    placed, GX, GZ = read_placements(mapname)
    lk2concept = {}
    for a in mm["artifacts"]:
        lk2concept.setdefault(a["lookup"], a["concept_order"])
    # concept_order -> (row,col) for whichever of its artifacts is in the map
    cpos = {}
    cn_lookup = {}
    for lk, (r, c) in placed.items():
        o = lk2concept.get(lk)
        if o is not None and o not in cpos:
            cpos[o] = (r, c)
            cn_lookup[o] = lk
    orders = [c["order"] for c in concepts if c["order"] in cpos]
    n = len(orders)
    # placed grid-distance matrix over the placed concepts
    M = [[0.0] * n for _ in range(n)]
    mx = 1e-9
    for i in range(n):
        for j in range(i + 1, n):
            ri, ci = cpos[orders[i]]
            rj, cj = cpos[orders[j]]
            d = math.hypot(ri - rj, ci - cj)
            M[i][j] = M[j][i] = d
            mx = max(mx, d)
    M = [[round(M[i][j] / mx, 4) for j in range(n)] for i in range(n)]

    # conceptual distance restricted to the same placed concepts (mindmap concept_distance is by order)
    cd = mm.get("concept_distance")
    concd = [[cd[orders[i]][orders[j]] if cd and orders[i] < len(cd) and orders[j] < len(cd[0]) else
              abs(orders[i] - orders[j]) / max(1, len(concepts) - 1) for j in range(n)] for i in range(n)]

    # compare upper triangles
    pv, cvv, pairs = [], [], []
    for i in range(n):
        for j in range(i + 1, n):
            pv.append(M[i][j]); cvv.append(concd[i][j])
            pairs.append((M[i][j] - concd[i][j], orders[i], orders[j]))
    corr = spearman(pv, cvv)
    key_of = {c["order"]: c["key"] for c in concepts}
    pairs.sort()
    pulled_apart = [{"a": key_of[b], "b": key_of[c], "placed": round(M[orders.index(b)][orders.index(c)], 2),
                     "conceptual": round(concd[orders.index(b)][orders.index(c)], 2)} for _, b, c in pairs[-3:][::-1]]
    jammed = [{"a": key_of[b], "b": key_of[c], "placed": round(M[orders.index(b)][orders.index(c)], 2),
               "conceptual": round(concd[orders.index(b)][orders.index(c)], 2)} for _, b, c in pairs[:3]]

    positions = [{"concept": key_of[o], "order": o, "lookup": cn_lookup[o],
                  "row": cpos[o][0], "col": cpos[o][1],
                  "x": round(cpos[o][1] / max(1, GX - 1), 4), "y": round(cpos[o][0] / max(1, GZ - 1), 4)}
                 for o in orders]
    placed_block = {"map": mapname, "grid": [GX, GZ], "positions": positions, "matrix": M,
                    "conceptual_corr": corr, "pulled_apart": pulled_apart, "jammed_together": jammed}
    return mm, placed_block


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    domain = args[0] if args else "transformation"
    mapname = opts.get("map", "MindMap_" + domain.title().replace("_", ""))
    mm, placed = build(domain, mapname)
    json.dump(placed, open(os.path.join(DOC, domain + "_placed.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    mm["placed"] = placed
    json.dump(mm, open(os.path.join(DOC, domain + "_mindmap.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    print("%s  <-  %s : %d concepts measured" % (domain, mapname, len(placed["positions"])))
    print("  built-vs-conceptual correlation (Spearman): %.3f" % placed["conceptual_corr"])
    print("  pulled apart (built far, conceptually near):")
    for p in placed["pulled_apart"]:
        print("    %-24s ~ %-24s  placed %.2f  vs concept %.2f" % (p["a"], p["b"], p["placed"], p["conceptual"]))
    print("  jammed together (built near, conceptually far):")
    for p in placed["jammed_together"]:
        print("    %-24s ~ %-24s  placed %.2f  vs concept %.2f" % (p["a"], p["b"], p["placed"], p["conceptual"]))
    print("-> wrote doc/%s_placed.json + injected 'placed' into doc/%s_mindmap.json" % (domain, domain))


if __name__ == "__main__":
    main()
