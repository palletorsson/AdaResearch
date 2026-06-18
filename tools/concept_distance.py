"""Generic concept-distance engine — the graph distance that maps can walk.

Reads a domain spec (artifacts + hand-authored feature embeddings + a tutorial order),
computes the cosine-distance graph between every pair, and emits a game-facing
doc/<domain>_distance.json that the placement / generation pipeline can read so that,
inside a VR map, *walking distance = conceptual distance*: the bigger the leap between
two ideas, the longer the floor of text the player crosses to reach the next artifact.

First built for Vectors & Forces (the Obsidian mental-model graph). This engine
generalises that single domain to any: each domain is one self-contained spec file.

Spec format — doc/concept_distance/<domain>.spec.json:
{
  "domain": "transformation",
  "title":  "Transformations - Mental Model",
  "note":   "what the embedding axes mean",
  "feature_names": ["translation", "rotation", ...],   # the embedding axes, in order
  "spacing": {"base": 2, "k": 10},                       # gap_cells = base + round(k * distance)
  "order": [                                             # the tutorial path; index = walk order
    {"id": "T2", "lookup": "translation_cube_demo", "name": "translation",
     "embedding": [1,0,0,0,0,0,0,0.2,0.7,1]},
    ...
  ]
}

Run:  python tools/concept_distance.py                # every spec in doc/concept_distance/
      python tools/concept_distance.py transformation # just the one whose file starts with it
"""
import json, glob, os, math, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC_DIR = os.path.join(ROOT, "doc", "concept_distance")
OUT_DIR = os.path.join(ROOT, "doc")


def cos_d(a, b):
    """Cosine distance in [0,1]; 1.0 if either vector is degenerate (zero norm)."""
    dot = sum(x * y for x, y in zip(a, b))
    na = math.sqrt(sum(x * x for x in a))
    nb = math.sqrt(sum(x * x for x in b))
    if na == 0 or nb == 0:
        return 1.0
    return max(0.0, 1.0 - dot / (na * nb))


def build(spec):
    nodes = spec["order"]
    n = len(nodes)
    dim = len(spec["feature_names"])
    for x in nodes:                                       # fail loud on a mis-authored embedding
        assert len(x["embedding"]) == dim, "%s embedding has %d dims, expected %d" % (
            x["lookup"], len(x["embedding"]), dim)
    emb = [x["embedding"] for x in nodes]
    M = [[round(cos_d(emb[i], emb[j]), 4) for j in range(n)] for i in range(n)]

    base = spec.get("spacing", {}).get("base", 2)
    k = spec.get("spacing", {}).get("k", 10)
    consec, total = [], 0
    for i in range(n - 1):
        d = M[i][i + 1]
        gap = base + round(k * d)
        total += gap
        consec.append({"from": nodes[i]["lookup"], "to": nodes[i + 1]["lookup"],
                       "id_from": nodes[i].get("id"), "id_to": nodes[i + 1].get("id"),
                       "d": d, "gap": gap})

    pairs = sorted((M[i][j], i, j) for i in range(n) for j in range(i + 1, n))
    closest, farthest = pairs[0], pairs[-1]
    nearest = {}
    for i in range(n):
        ranked = sorted((M[i][j], j) for j in range(n) if j != i)
        nearest[nodes[i]["lookup"]] = [{"lookup": nodes[j]["lookup"], "d": d} for d, j in ranked[:3]]

    return {
        "domain": spec["domain"],
        "title": spec.get("title", spec["domain"]),
        "note": spec.get("note", ""),
        "feature_names": spec["feature_names"],
        "spacing": {"base": base, "k": k},
        "order": [x["lookup"] for x in nodes],
        "nodes": [{"id": x.get("id"), "lookup": x["lookup"], "name": x.get("name", x["lookup"])} for x in nodes],
        "matrix": M,
        "consecutive": consec,
        "corridor_cells": total,
        "uniform_cells": base * (n - 1),
        "extremes": {
            "closest": {"a": nodes[closest[1]]["lookup"], "b": nodes[closest[2]]["lookup"], "d": closest[0]},
            "farthest": {"a": nodes[farthest[1]]["lookup"], "b": nodes[farthest[2]]["lookup"], "d": farthest[0]},
        },
        "nearest": nearest,
    }


def report(out):
    print("\n=== %s: %s ===" % (out["domain"], out["title"]))
    print("%d nodes, %d-D features" % (len(out["order"]), len(out["feature_names"])))
    print("STEP                from -> to                              d     gap   walk")
    for c in out["consecutive"]:
        print("  %-4s->%-4s  %-20s -> %-20s %5.3f  %3d   %s" % (
            str(c["id_from"]), str(c["id_to"]), c["from"][:20], c["to"][:20], c["d"], c["gap"], "#" * c["gap"]))
    e = out["extremes"]
    print("corridor: %d cells of text-floor (uniform spacing would be %d)" % (out["corridor_cells"], out["uniform_cells"]))
    print("closest:  %s ~ %s  d=%.3f" % (e["closest"]["a"], e["closest"]["b"], e["closest"]["d"]))
    print("farthest: %s ~ %s  d=%.3f" % (e["farthest"]["a"], e["farthest"]["b"], e["farthest"]["d"]))


def main():
    which = sys.argv[1] if len(sys.argv) > 1 else None
    specs = sorted(glob.glob(os.path.join(SPEC_DIR, "*.spec.json")))
    if which:
        specs = [s for s in specs if os.path.basename(s).startswith(which)]
    if not specs:
        print("no specs found in", SPEC_DIR)
        return
    for sp in specs:
        spec = json.load(open(sp, encoding="utf-8"))
        out = build(spec)
        outpath = os.path.join(OUT_DIR, spec["domain"] + "_distance.json")
        json.dump(out, open(outpath, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
        report(out)
        print("-> wrote %s" % os.path.relpath(outpath, ROOT))


if __name__ == "__main__":
    main()
