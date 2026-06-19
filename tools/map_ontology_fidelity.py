"""Measure how close every EXISTING map already is to the ontological q-map.

The synthetic MindMap_<Domain> corridor was a proof; the real goal is the curated maps. This
scores each real map by how well the physical arrangement of its artifacts matches the
ontological concept-distance (Spearman correlation of pairwise physical vs conceptual distance).
High = already the q-map (curated); low = uncurated, the work to do. Emits
doc/<domain>_map_fidelity.json (scores + artifact positions) for the /q-maps side-by-side view.

Run:  python tools/map_ontology_fidelity.py            # every domain with a mindmap
      python tools/map_ontology_fidelity.py transformation
"""
import json, glob, os, math, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(ROOT, "doc")
MAPS = os.path.join(ROOT, "commons", "maps")


def spearman(a, b):
    n = len(a)
    if n < 3:
        return None
    def rank(v):
        o = sorted(range(n), key=lambda i: v[i])
        r = [0.0] * n
        i = 0
        while i < n:
            j = i
            while j + 1 < n and v[o[j + 1]] == v[o[i]]:
                j += 1
            for k in range(i, j + 1):
                r[o[k]] = (i + j) / 2.0
            i = j + 1
        return r
    ra, rb = rank(a), rank(b)
    ma, mb = sum(ra) / n, sum(rb) / n
    num = sum((ra[i] - ma) * (rb[i] - mb) for i in range(n))
    da = math.sqrt(sum((ra[i] - ma) ** 2 for i in range(n)))
    db = math.sqrt(sum((rb[i] - mb) ** 2 for i in range(n)))
    return round(num / (da * db), 3) if da and db else None


def tag(s):
    if s is None:
        return "sparse"
    return "curated" if s >= 0.5 else ("partial" if s >= 0.15 else "uncurated")


def build(domain):
    mm = json.load(open(os.path.join(DOC, domain + "_mindmap.json"), encoding="utf-8"))
    lk2c = {a["lookup"]: a["concept_order"] for a in mm["artifacts"]}
    lk2t = {a["lookup"]: a["tier"] for a in mm["artifacts"]}
    CD = mm.get("concept_distance")
    acts = []
    for c in mm["concepts"]:
        if c["act"] not in acts:
            acts.append(c["act"])
    actIdx = {a: i for i, a in enumerate(acts)}
    c2act = {c["order"]: actIdx[c["act"]] for c in mm["concepts"]}

    # when the sequence has a beat score, only score ITS OWN maps — otherwise a sequence whose
    # artifacts are shared (generic primitives/transforms) matches unrelated maps and scores them.
    seq_maps = None
    bp = os.path.join(MAPS, "sequences", domain + ".beats.json")
    if os.path.exists(bp):
        seq_maps = set()
        for b in json.load(open(bp, encoding="utf-8")).get("beats", []):
            for m in b.get("maps") or []:
                seq_maps.add(m)

    maps = []
    for p in glob.glob(os.path.join(MAPS, "*", "map_data.json")):
        name = os.path.basename(os.path.dirname(p))
        if name.startswith("MindMap_"):
            continue
        if seq_maps is not None and name not in seq_maps:
            continue
        try:
            d = json.load(open(p, encoding="utf-8"))
        except Exception:
            continue
        inter = d.get("layers", {}).get("interactables")
        if not inter:
            continue
        GZ = len(inter)
        GX = max((len(r) for r in inter if r), default=0)
        arts = []
        for r, row in enumerate(inter):
            for c, cell in enumerate(row or []):
                if isinstance(cell, str) and cell.strip():
                    lk = cell.split(":")[0].strip()
                    if lk in lk2c:
                        co = lk2c[lk]
                        arts.append({"co": co, "col": c, "row": r, "lk": lk,
                                     "ai": c2act.get(co, 0), "t": lk2t.get(lk, "medium")[0]})
        if not arts:
            continue
        # concept-averaged positions -> fidelity
        byc = {}
        for a in arts:
            byc.setdefault(a["co"], []).append((a["row"], a["col"]))
        cs = sorted(byc)
        score = None
        if len(cs) >= 3:
            pos = {co: (sum(x[0] for x in v) / len(v), sum(x[1] for x in v) / len(v)) for co, v in byc.items()}
            phys, conc = [], []
            for i in range(len(cs)):
                for j in range(i + 1, len(cs)):
                    x, y = cs[i], cs[j]
                    phys.append(math.hypot(pos[x][0] - pos[y][0], pos[x][1] - pos[y][1]))
                    conc.append(CD[x][y] if CD and x < len(CD) and y < len(CD[0]) else abs(x - y))
            score = spearman(phys, conc)
        maps.append({"name": name, "score": score, "tag": tag(score),
                     "grid": [GX, GZ], "n_concepts": len(cs), "n_artifacts": len(arts), "arts": arts})
    maps.sort(key=lambda m: (m["score"] is None, -(m["score"] or -9)))
    return {"domain": domain, "title": mm.get("title", domain), "acts": acts, "maps": maps,
            "total_maps": len(maps)}


def main():
    which = sys.argv[1] if len(sys.argv) > 1 else None
    mms = sorted(glob.glob(os.path.join(DOC, "*_mindmap.json")))
    domains = [os.path.basename(m)[:-len("_mindmap.json")] for m in mms]
    if which:
        domains = [d for d in domains if d == which]
    for dm in domains:
        out = build(dm)
        json.dump(out, open(os.path.join(DOC, dm + "_map_fidelity.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
        scored = [m for m in out["maps"] if m["score"] is not None]
        print("%s: %d maps (%d scored) -> doc/%s_map_fidelity.json" % (dm, out["total_maps"], len(scored), dm))


if __name__ == "__main__":
    main()
