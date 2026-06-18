"""The meta layer — distance as a PROJECTION across an artifact's several relations.

Distance is not one scalar. An artifact relates to the tutorial in more than one way, and
the final map is a feedback loop between the conceptual order, what the artifact *is*, and the
spatial poetics of where it lives. So instead of choosing lexical-vs-semantic (that is only one
channel's *method*), this layer holds each relation as its own channel and lets you PROJECT
(blend by weight) or DECIDE (pin an override) the current vector distance:

  order   — the order of things: distance in the tutorial/QFEP sequence (the conceptual order)
  concept — what the artifact IS: TF-IDF over its teaching text (intent.md / tutorial prose)
  spatial — the spatial poetics: TF-IDF over its blurb.md (how the space is written / felt)

    current_distance(i,j) = Σ w_c · channel_c(i,j) / Σ w_c     (then overrides pin chosen pairs)

A channel is just a matrix; how it's computed is pluggable (swap the TF-IDF for semantic
embeddings later without touching the meta layer). The resolved doc/<domain>_distance.json
stays drop-in for placement/generation, but now carries every channel + the weights + overrides,
so a projector UI can re-blend live and the human can see the two relations pull apart.

Spec — doc/concept_distance/<domain>.meta.json:
  { "domain":"transformation", "title":"...", "nodes_from":"transformation.textspec.json",
    "spacing":{"base":2,"k":10},
    "channels":{ "order":{"weight":0.34}, "concept":{"weight":0.33,"sources":["intent.md"]},
                 "spatial":{"weight":0.33,"sources":["blurb.md"]} },
    "overrides":[ {"a":"scaleme","b":"spin","d":0.15,"why":"both single-motion dials"} ] }

Run:  python tools/concept_distance_meta.py
      python tools/concept_distance_meta.py transformation --weights order=0 concept=1 spatial=0
"""
import json, glob, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import concept_distance_text as T   # reuse tokens / tfidf / cos_d

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC_DIR = os.path.join(ROOT, "doc", "concept_distance")
OUT_DIR = os.path.join(ROOT, "doc")


def resolve_nodes(spec):
    if "nodes" in spec:
        return spec["nodes"]
    ts = json.load(open(os.path.join(SPEC_DIR, spec["nodes_from"]), encoding="utf-8"))
    return ts["nodes"]


def map_text(node, filenames):
    md_dir = os.path.join(ROOT, "commons", "maps", node["map"])
    txt = node.get("name", "") + " "
    for fn in filenames:
        p = os.path.join(md_dir, fn)
        if os.path.exists(p):
            txt += "\n" + open(p, encoding="utf-8").read()
    return txt


def rescale(M):
    n = len(M)
    raw = [M[i][j] for i in range(n) for j in range(i + 1, n)]
    if not raw:
        return M, (0.0, 0.0)
    lo, hi = min(raw), max(raw)
    if hi <= lo:
        return M, (lo, hi)
    return [[(0.0 if i == j else round((M[i][j] - lo) / (hi - lo), 4)) for j in range(n)] for i in range(n)], (lo, hi)


def text_channel(nodes, sources):
    passages = [map_text(nd, sources) for nd in nodes]
    vecs, tops = T.tfidf(passages)
    n = len(nodes)
    M = [[(0.0 if i == j else T.cos_d(vecs[i], vecs[j])) for j in range(n)] for i in range(n)]
    M, rng = rescale(M)
    return M, tops, rng


def order_channel(nodes):
    n = len(nodes)
    return [[round(abs(i - j) / (n - 1), 4) if n > 1 else 0.0 for j in range(n)] for i in range(n)]


def extremes(nodes, M):
    n = len(nodes)
    pairs = sorted((M[i][j], i, j) for i in range(n) for j in range(i + 1, n))
    c, f = pairs[0], pairs[-1]
    return ({"a": nodes[c[1]]["lookup"], "b": nodes[c[2]]["lookup"], "d": c[0]},
            {"a": nodes[f[1]]["lookup"], "b": nodes[f[2]]["lookup"], "d": f[0]})


def spacing_block(nodes, M, base, k):
    n = len(nodes)
    consec, total = [], 0
    for i in range(n - 1):
        d = M[i][i + 1]
        gap = base + round(k * d)
        total += gap
        consec.append({"from": nodes[i]["lookup"], "to": nodes[i + 1]["lookup"],
                       "id_from": nodes[i].get("id"), "id_to": nodes[i + 1].get("id"),
                       "d": round(d, 4), "gap": gap})
    nearest = {}
    for i in range(n):
        ranked = sorted((M[i][j], j) for j in range(n) if j != i)
        nearest[nodes[i]["lookup"]] = [{"lookup": nodes[j]["lookup"], "d": round(d, 4)} for d, j in ranked[:3]]
    cl, fr = extremes(nodes, M)
    return {"consecutive": consec, "corridor_cells": total, "uniform_cells": base * (n - 1),
            "extremes": {"closest": cl, "farthest": fr}, "nearest": nearest}


def project(spec, weight_override=None):
    nodes = resolve_nodes(spec)
    n = len(nodes)
    ch_cfg = spec["channels"]
    weights = {c: (weight_override.get(c) if weight_override and c in weight_override else ch_cfg[c].get("weight", 0.0))
               for c in ch_cfg}
    channels, tops, ranges = {}, None, {}
    for c, cfg in ch_cfg.items():
        if c == "order":
            channels[c] = order_channel(nodes)
        else:
            M, t, rng = text_channel(nodes, cfg.get("sources", ["blurb.md"]))
            channels[c] = M
            ranges[c] = [round(rng[0], 3), round(rng[1], 3)]
            if c == "concept":
                tops = t
    # blend
    wsum = sum(weights.values()) or 1.0
    blend = [[sum(weights[c] * channels[c][i][j] for c in channels) / wsum for j in range(n)] for i in range(n)]
    blend = [[round(blend[i][j], 4) for j in range(n)] for i in range(n)]
    # overrides (human DECIDES specific pairs)
    idx = {nd["lookup"]: i for i, nd in enumerate(nodes)}
    applied = []
    for ov in spec.get("overrides", []):
        if ov["a"] in idx and ov["b"] in idx:
            i, j = idx[ov["a"]], idx[ov["b"]]
            blend[i][j] = blend[j][i] = round(float(ov["d"]), 4)
            applied.append(ov)

    base = spec.get("spacing", {}).get("base", 2)
    k = spec.get("spacing", {}).get("k", 10)
    out = {"domain": spec["domain"], "title": spec.get("title", spec["domain"]),
           "note": spec.get("note", ""), "method": "meta-projection",
           "weights": weights, "channel_raw_cosine_ranges": ranges,
           "overrides": applied, "spacing": {"base": base, "k": k},
           "order": [x["lookup"] for x in nodes],
           "nodes": [{"id": x.get("id"), "lookup": x["lookup"], "name": x.get("name", x["lookup"]),
                      "map": x.get("map"), "top_terms": (tops[i] if tops else [])} for i, x in enumerate(nodes)],
           "matrix": blend}
    out.update(spacing_block(nodes, blend, base, k))
    # keep each channel + its own extremes so the divergence is legible and the UI can re-blend
    out["channels"] = {c: {"weight": weights[c], "matrix": channels[c],
                           "extremes": dict(zip(("closest", "farthest"), extremes(nodes, channels[c])))}
                       for c in channels}
    return nodes, out


def report(out):
    print("\n=== %s: %s  (weights %s) ===" % (out["domain"], out["title"],
          " ".join("%s=%.2f" % (c, w) for c, w in out["weights"].items())))
    for c, ch in out["channels"].items():
        e = ch["extremes"]
        print("  channel %-8s closest %s~%s (%.2f)   farthest %s~%s (%.2f)" % (
            c, e["closest"]["a"][:14], e["closest"]["b"][:14], e["closest"]["d"],
            e["farthest"]["a"][:14], e["farthest"]["b"][:14], e["farthest"]["d"]))
    print("  PROJECTED corridor: %d cells (uniform %d)" % (out["corridor_cells"], out["uniform_cells"]))
    ce = out["extremes"]
    print("  projected closest %s~%s (%.2f)  farthest %s~%s (%.2f)" % (
        ce["closest"]["a"], ce["closest"]["b"], ce["closest"]["d"],
        ce["farthest"]["a"], ce["farthest"]["b"], ce["farthest"]["d"]))


def parse_weights(argv):
    w = {}
    for a in argv:
        if a.startswith("--weights"):
            continue
        if "=" in a:
            k, v = a.split("=", 1)
            w[k] = float(v)
    return w or None


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    which = args[0] if args else None
    wover = parse_weights(sys.argv[1:]) if "--weights" in sys.argv else None
    specs = sorted(glob.glob(os.path.join(SPEC_DIR, "*.meta.json")))
    if which:
        specs = [s for s in specs if os.path.basename(s).startswith(which)]
    if not specs:
        print("no *.meta.json in", SPEC_DIR)
        return
    for sp in specs:
        spec = json.load(open(sp, encoding="utf-8"))
        nodes, out = project(spec, wover)
        json.dump(out, open(os.path.join(OUT_DIR, spec["domain"] + "_distance.json"), "w", encoding="utf-8"),
                  indent=2, ensure_ascii=False)
        report(out)
        print("-> wrote doc/%s_distance.json" % spec["domain"])


if __name__ == "__main__":
    main()
