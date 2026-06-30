#!/usr/bin/env python3
"""three_orders.py - the pedagogical, ontological and critical orders of a sequence's pearls,
and WHERE THEY DIVERGE. The divergence is the map's topology.

A 1D 'book order' has to flatten three different orders of the same fact-space. Where the three
agree -> a straight run of necklace; where they disagree -> a branch, an alcove, a side-pool.
This computes all three from real data and reports the consensus spine + the branch points.

  pedagogical = the teaching order      (maps in content order, artifacts within)
  ontological = concept-similarity      (atlas 128-D embeddings, 1D principal axis)
  critical    = QFEP salience           (TF-IDF resonance of each pearl's text with the
                                         sequence's qfep_connection)

Each order is oriented to best-align with pedagogy first; the divergence that REMAINS is real.

Usage:  python tools/three_orders.py <sequence>      e.g.  fractals
"""
import json, os, sys
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load(p):
    return json.load(open(p, encoding="utf-8"))


def ranks(values, reverse=False):
    order = np.argsort(-np.asarray(values) if reverse else np.asarray(values))
    r = np.empty(len(order), dtype=float)
    r[order] = np.arange(len(order))
    return r / max(len(order) - 1, 1)  # normalised 0..1


def spearman(a, b):
    a, b = np.asarray(a), np.asarray(b)
    if a.std() == 0 or b.std() == 0:
        return 0.0
    return float(np.corrcoef(a, b)[0, 1])


def main():
    seq = sys.argv[1] if len(sys.argv) > 1 else "fractals"
    sd = load(os.path.join(ROOT, "commons", "maps", "sequences", seq + ".json"))["sequences"][seq]
    maps = sd.get("maps", [])
    qfep_text = " ".join(str(sd.get(k, "")) for k in ("qfep_connection", "qfep_term", "truth", "description"))

    # --- pedagogical order: walk maps in teaching order, artifacts in reading order, dedup first-seen
    ped, seen = [], set()
    for m in maps:
        mp = os.path.join(ROOT, "commons", "maps", m, "map_data.json")
        if not os.path.exists(mp):
            continue
        for row in load(mp)["layers"].get("interactables", []):
            if not isinstance(row, list):
                continue
            for cell in row:
                t = str(cell).split("#")[0].split(":")[0].strip()
                if t and t != " " and not t.startswith("cluster") and t not in seen:
                    seen.add(t)
                    ped.append(t)

    # --- ontological: atlas embeddings
    z = np.load(os.path.join(ROOT, "doc", "atlas", "artifact_embeddings.npz"), allow_pickle=True)
    id2vec = {str(i): v for i, v in zip(z["ids"], z["vectors"])}
    pearls = [a for a in ped if a in id2vec]
    if len(pearls) < 3:
        print("not enough embeddable artifacts in '%s' (%d) - try a fuller sequence" % (seq, len(pearls)))
        return
    V = np.array([id2vec[a] for a in pearls])
    Vc = V - V.mean(0)
    _, _, vt = np.linalg.svd(Vc, full_matrices=False)
    onto = Vc @ vt[0]  # projection on principal concept axis

    # --- critical: TF-IDF resonance of each pearl's card with the sequence's QFEP framing
    cards = {}
    cp = os.path.join(ROOT, "doc", "atlas", "artifact_cards.json")
    if os.path.exists(cp):
        raw = load(cp)
        if isinstance(raw, dict):
            cards = {k: (v if isinstance(v, str) else json.dumps(v)) for k, v in raw.items()}
        elif isinstance(raw, list):
            for e in raw:
                cards[str(e.get("id", e.get("lookup_name", "")))] = str(e.get("card", e.get("text", "")))
    texts = [cards.get(a, a.replace("_", " ")) for a in pearls] + [qfep_text]
    try:
        from sklearn.feature_extraction.text import TfidfVectorizer
        X = TfidfVectorizer(stop_words="english", min_df=1).fit_transform(texts)
        crit = np.asarray((X[:-1] @ X[-1].T).todense()).ravel()
    except Exception as e:
        print("critical order unavailable (%s); showing pedagogy vs ontology only" % e)
        crit = np.zeros(len(pearls))

    # --- ranks (pedagogy is the reference; orient onto/crit to best-align, so residual = real divergence)
    ped_r = ranks(range(len(pearls)))
    onto_r = ranks(onto)
    if spearman(onto_r, ped_r) < 0:
        onto_r = 1 - onto_r
    crit_r = ranks(crit, reverse=True)  # high QFEP salience = early
    if spearman(crit_r, ped_r) < 0:
        crit_r = 1 - crit_r

    spread = np.maximum.reduce([ped_r, onto_r, crit_r]) - np.minimum.reduce([ped_r, onto_r, crit_r])
    if "--json" in sys.argv:
        print(json.dumps({"seq": seq, "pearls": pearls,
                          "ped": [round(float(x), 3) for x in ped_r],
                          "onto": [round(float(x), 3) for x in onto_r],
                          "crit": [round(float(x), 3) for x in crit_r],
                          "spread": [round(float(x), 3) for x in spread]}))
        return

    print("# three orders of '%s'  -  %d pearls (embeddable; clusters skipped)\n" % (seq, len(pearls)))
    print("ORDER AGREEMENT (Spearman, after best-alignment):")
    print("  pedagogy <-> ontology : %+.2f" % spearman(ped_r, onto_r))
    print("  pedagogy <-> critical : %+.2f" % spearman(ped_r, crit_r))
    print("  ontology <-> critical : %+.2f" % spearman(onto_r, crit_r))
    print()

    consensus = (ped_r + onto_r + crit_r) / 3.0
    rows = sorted(range(len(pearls)), key=lambda i: consensus[i])

    def band(r):
        return "early" if r < 0.34 else "mid" if r < 0.67 else "late "

    BR = 0.45  # branch threshold: the three orders disagree by ~half the necklace
    print("THE NECKLACE  (consensus order; * = branch point where the orders disagree):")
    for i in rows:
        star = "*" if spread[i] >= BR else " "
        print("  %s %-34s  ped:%-5s onto:%-5s crit:%-5s  spread %.2f"
              % (star, pearls[i][:34], band(ped_r[i]), band(onto_r[i]), band(crit_r[i]), spread[i]))

    branches = [i for i in rows if spread[i] >= BR]
    print("\nBRANCH POINTS  (%d) - where the 1D necklace wants to become 2D:" % len(branches))
    if not branches:
        print("  none above %.2f - the three orders run nearly parallel here (a straight necklace)." % BR)
    for i in sorted(branches, key=lambda i: -spread[i]):
        pulls = sorted([("pedagogy", ped_r[i]), ("ontology", onto_r[i]), ("criticality", crit_r[i])], key=lambda t: t[1])
        lo, hi = pulls[0], pulls[-1]
        print("  %-32s  %s pulls it %s, %s pulls it %s  -> a side-pool off the spine"
              % (pearls[i][:32], lo[0], band(lo[1]).strip(), hi[0], band(hi[1]).strip()))


if __name__ == "__main__":
    main()
