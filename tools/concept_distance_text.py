"""Concept distance derived from the EXISTING .md tutorials — not hand-authored features.

The companion tools/concept_distance.py reads embeddings someone assigned by judgment.
This one removes the judgment: each node's vector is the TF-IDF of its own tutorial prose,
and the distance between two artifacts is the cosine distance of how the tutorials talk
about them. Two ideas are "close" iff the existing teaching text uses the same words.

Source text per domain, set in a textspec (doc/concept_distance/<domain>.textspec.json):
  - mode "doc_headings": one tutorial doc split into sections by a heading regex; the artifact
       token is read from the first `backtick` span in each heading. (Vectors & Forces:
       vector_forces_tutorial_scripts.md, the ### NN. concept sections.)
  - mode "maps": a list of sequence maps in tutorial order; each node's text is that map's
       blurb.md + intent.md. (Primitives: Point_*/Primitives_* maps. Transformations: Trans_*.)

Emits the SAME doc/<domain>_distance.json shape as concept_distance.py (matrix + per-step
corridor spacing + nearest + extremes) so downstream placement/generation can't tell which
method produced it — but adds method/derived_from and per-node top_terms for legibility.

Run:  python tools/concept_distance_text.py                 # every *.textspec.json
      python tools/concept_distance_text.py transformation  # just one
"""
import json, glob, os, re, math, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC_DIR = os.path.join(ROOT, "doc", "concept_distance")
OUT_DIR = os.path.join(ROOT, "doc")

STOP = set("""a an the this that these those of to in on at by for with from into over under
and or but if then else than so as is are was were be been being am do does did doing have has
had having it its it's they them their there here what which who whom whose when where why how
not no nor only own same too very can will just should now i you he she we me my your our he's
not also more most other some such own off out up down again once because about against between
during before after above below only then there here all any both each few will would could
shall may might must like get got make makes made one two three first second thing things way
ways something anything everything not nothing into onto upon""".split())


def tokens(text):
    text = re.sub(r"`[^`]*`", " ", text)          # drop code spans (artifact tokens, scene names)
    text = re.sub(r"\*\*|\*|_|#|>|\[|\]|\(|\)", " ", text)
    out = []
    for w in re.findall(r"[a-z][a-z']{2,}", text.lower()):
        w = w.rstrip("'s")
        if len(w) > 3 and w.endswith("s") and not w.endswith("ss"):
            w = w[:-1]                              # crude singularise so plural≈singular
        if w and w not in STOP:
            out.append(w)
    return out


def tfidf(passages):
    """passages: list[str] -> (list of L2-normalised tf-idf dicts, list of top-term lists)."""
    docs = [tokens(p) for p in passages]
    n = len(docs)
    df = {}
    for d in docs:
        for t in set(d):
            df[t] = df.get(t, 0) + 1
    vecs, tops = [], []
    for d in docs:
        tf = {}
        for t in d:
            tf[t] = tf.get(t, 0) + 1
        w = {}
        for t, c in tf.items():
            idf = math.log((n + 1) / (df[t] + 1)) + 1.0
            w[t] = (1.0 + math.log(c)) * idf
        norm = math.sqrt(sum(v * v for v in w.values())) or 1.0
        w = {t: v / norm for t, v in w.items()}
        vecs.append(w)
        tops.append([t for t, _ in sorted(w.items(), key=lambda kv: -kv[1])[:6]])
    return vecs, tops


def cos_d(a, b):
    common = set(a) & set(b)
    dot = sum(a[t] * b[t] for t in common)
    return max(0.0, round(1.0 - dot, 4))           # a,b already L2-normalised


def load_passages(spec):
    """Return (nodes, passages) where nodes carry id/lookup/name/source."""
    mode = spec["mode"]
    nodes, passages = [], []
    if mode == "doc_headings":
        md = open(os.path.join(ROOT, spec["source_md"]), encoding="utf-8").read()
        rx = re.compile(spec["heading_regex"], re.M)
        marks = list(rx.finditer(md))
        for i, m in enumerate(marks):
            head = m.group(0)
            body = md[m.end(): marks[i + 1].start() if i + 1 < len(marks) else len(md)]
            tok = re.search(r"`([^`]+)`", head)
            lookup = (tok.group(1) if tok else head.strip().split()[-1])
            lookup = re.sub(r"[^A-Za-z0-9_]", "", lookup).lower()
            name = re.sub(r"^#+\s*\d*\.?\s*", "", head).split("—")[0].split("`")[0].strip(" -")
            nodes.append({"id": m.group(1) if rx.groups else str(i), "lookup": lookup, "name": name, "source": head.strip()})
            passages.append(head + "\n" + body)
    elif mode == "maps":
        for nd in spec["nodes"]:
            md_dir = os.path.join(ROOT, "commons", "maps", nd["map"])
            txt = nd.get("name", "") + " "
            for fn in ("blurb.md", "intent.md", "technical.md"):
                p = os.path.join(md_dir, fn)
                if os.path.exists(p):
                    txt += "\n" + open(p, encoding="utf-8").read()
            nodes.append({"id": nd.get("id"), "lookup": nd["lookup"], "name": nd.get("name", nd["lookup"]),
                          "source": nd["map"]})
            passages.append(txt)
    else:
        raise SystemExit("unknown mode: " + mode)
    return nodes, passages


def assemble(spec, nodes, M, tops):
    n = len(nodes)
    base = spec.get("spacing", {}).get("base", 2)
    k = spec.get("spacing", {}).get("k", 10)
    consec, total = [], 0
    for i in range(n - 1):
        d = M[i][i + 1]
        gap = base + round(k * d)
        total += gap
        consec.append({"from": nodes[i]["lookup"], "to": nodes[i + 1]["lookup"],
                       "id_from": nodes[i].get("id"), "id_to": nodes[i + 1].get("id"), "d": d, "gap": gap})
    pairs = sorted((M[i][j], i, j) for i in range(n) for j in range(i + 1, n))
    closest, farthest = pairs[0], pairs[-1]
    nearest = {}
    for i in range(n):
        ranked = sorted((M[i][j], j) for j in range(n) if j != i)
        nearest[nodes[i]["lookup"]] = [{"lookup": nodes[j]["lookup"], "d": d} for d, j in ranked[:3]]
    for i, nd in enumerate(nodes):
        nd["top_terms"] = tops[i]
    return {
        "domain": spec["domain"], "title": spec.get("title", spec["domain"]),
        "note": spec.get("note", ""), "method": "tfidf-cosine",
        "derived_from": spec.get("source_md") or ("maps: " + ", ".join(x["source"] for x in nodes)),
        "spacing": {"base": base, "k": k},
        "order": [x["lookup"] for x in nodes], "nodes": nodes, "matrix": M,
        "consecutive": consec, "corridor_cells": total, "uniform_cells": base * (n - 1),
        "extremes": {
            "closest": {"a": nodes[closest[1]]["lookup"], "b": nodes[closest[2]]["lookup"], "d": closest[0]},
            "farthest": {"a": nodes[farthest[1]]["lookup"], "b": nodes[farthest[2]]["lookup"], "d": farthest[0]}},
        "nearest": nearest,
    }


def report(out):
    print("\n=== %s: %s  (%s) ===" % (out["domain"], out["title"], out["method"]))
    print("%d nodes, derived from %s" % (len(out["order"]), out["derived_from"]))
    print("STEP        from -> to                              d     gap   walk")
    for c in out["consecutive"]:
        print("  %-4s->%-4s %-18s -> %-18s %5.3f  %3d   %s" % (
            str(c["id_from"]), str(c["id_to"]), c["from"][:18], c["to"][:18], c["d"], c["gap"], "#" * c["gap"]))
    e = out["extremes"]
    print("corridor: %d cells (uniform %d)" % (out["corridor_cells"], out["uniform_cells"]))
    print("closest:  %s ~ %s  d=%.3f" % (e["closest"]["a"], e["closest"]["b"], e["closest"]["d"]))
    print("farthest: %s ~ %s  d=%.3f" % (e["farthest"]["a"], e["farthest"]["b"], e["farthest"]["d"]))


def main():
    which = sys.argv[1] if len(sys.argv) > 1 else None
    specs = sorted(glob.glob(os.path.join(SPEC_DIR, "*.textspec.json")))
    if which:
        specs = [s for s in specs if os.path.basename(s).startswith(which)]
    if not specs:
        print("no textspecs in", SPEC_DIR)
        return
    for sp in specs:
        spec = json.load(open(sp, encoding="utf-8"))
        nodes, passages = load_passages(spec)
        vecs, tops = tfidf(passages)
        n = len(nodes)
        M = [[(0.0 if i == j else cos_d(vecs[i], vecs[j])) for j in range(n)] for i in range(n)]
        # raw lexical cosine compresses into a narrow high band (short, deliberately-varied prose
        # shares few exact words). The *relative* order is the real signal, so stretch the
        # off-diagonal band to [0,1] per domain — closest pair -> 0, farthest -> 1.
        raw = [M[i][j] for i in range(n) for j in range(i + 1, n)]
        lo, hi = min(raw), max(raw)
        rescaled = spec.get("rescale", True) and hi > lo
        if rescaled:
            M = [[(0.0 if i == j else round((M[i][j] - lo) / (hi - lo), 4)) for j in range(n)] for i in range(n)]
        out = assemble(spec, nodes, M, tops)
        out["raw_cosine_range"] = [round(lo, 3), round(hi, 3)]
        out["rescaled"] = rescaled
        outpath = os.path.join(OUT_DIR, spec["domain"] + "_distance.json")
        json.dump(out, open(outpath, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
        report(out)
        print("-> wrote %s" % os.path.relpath(outpath, ROOT))


if __name__ == "__main__":
    main()
