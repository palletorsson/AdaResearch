#!/usr/bin/env python3
"""three_orders.py - the pedagogical, ontological and critical orders of a sequence's pearls,
and WHERE THEY DIVERGE. The divergence is the map's topology.

A 1D 'book order' has to flatten three different orders of the same fact-space. Where the three
agree -> a straight run of necklace; where they disagree -> a branch, an alcove, a side-pool.

  pedagogical = the teaching order      (maps in content order, artifacts within)
  ontological = concept-similarity      (atlas 128-D embeddings, 1D principal axis)
  critical    = QFEP salience           (TF-IDF resonance of each pearl's card with the
                                         sequence's qfep_connection)  [PROXY - vocabulary, not graph]

Each order is oriented to best-align with pedagogy first; the divergence that REMAINS is real.

Usage:
  python tools/three_orders.py <sequence>            human report
  python tools/three_orders.py <sequence> --json     one sequence as JSON
  python tools/three_orders.py --all                 every sequence as JSON {"sequences":[...]}
"""
import json, os, sys
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SEQ_DIR = os.path.join(ROOT, "commons", "maps", "sequences")
_CACHE = {}


def load(p):
    return json.load(open(p, encoding="utf-8"))


def _atlas():
    if "id2vec" not in _CACHE:
        z = np.load(os.path.join(ROOT, "doc", "atlas", "artifact_embeddings.npz"), allow_pickle=True)
        _CACHE["id2vec"] = {str(i): v for i, v in zip(z["ids"], z["vectors"])}
        cards = {}
        cp = os.path.join(ROOT, "doc", "atlas", "artifact_cards.json")
        if os.path.exists(cp):
            raw = load(cp)
            if isinstance(raw, dict):
                cards = {k: (v if isinstance(v, str) else json.dumps(v)) for k, v in raw.items()}
            elif isinstance(raw, list):
                for e in raw:
                    cards[str(e.get("id", e.get("lookup_name", "")))] = str(e.get("card", e.get("text", "")))
        _CACHE["cards"] = cards
    return _CACHE["id2vec"], _CACHE["cards"]


def ranks(values, reverse=False):
    order = np.argsort(-np.asarray(values) if reverse else np.asarray(values))
    r = np.empty(len(order), dtype=float)
    r[order] = np.arange(len(order))
    return r / max(len(order) - 1, 1)


def spearman(a, b):
    a, b = np.asarray(a), np.asarray(b)
    if a.std() == 0 or b.std() == 0:
        return 0.0
    return float(np.corrcoef(a, b)[0, 1])


def band(r):
    return "early" if r < 0.34 else "mid" if r < 0.67 else "late"


def compute(seq, min_pearls=8):
    p = os.path.join(SEQ_DIR, seq + ".json")
    if not os.path.exists(p):
        return None
    sd = load(p).get("sequences", {}).get(seq)
    if not sd:
        return None
    maps = sd.get("maps", [])
    qfep_text = " ".join(str(sd.get(k, "")) for k in ("qfep_connection", "qfep_term", "truth", "description"))

    ped, seen = [], set()
    for m in maps:
        mp = os.path.join(ROOT, "commons", "maps", m, "map_data.json")
        if not os.path.exists(mp):
            continue
        for row in load(mp).get("layers", {}).get("interactables", []):
            if not isinstance(row, list):
                continue
            for cell in row:
                t = str(cell).split("#")[0].split(":")[0].strip()
                if t and t != " " and not t.startswith("cluster") and t not in seen:
                    seen.add(t)
                    ped.append(t)

    id2vec, cards = _atlas()
    pearls = [a for a in ped if a in id2vec]
    if len(pearls) < min_pearls:
        return None

    V = np.array([id2vec[a] for a in pearls])
    Vc = V - V.mean(0)
    _, _, vt = np.linalg.svd(Vc, full_matrices=False)
    onto = Vc @ vt[0]

    texts = [cards.get(a, a.replace("_", " ")) for a in pearls] + [qfep_text]
    try:
        from sklearn.feature_extraction.text import TfidfVectorizer
        X = TfidfVectorizer(stop_words="english", min_df=1).fit_transform(texts)
        crit = np.asarray((X[:-1] @ X[-1].T).todense()).ravel()
    except Exception:
        crit = np.zeros(len(pearls))

    ped_r = ranks(range(len(pearls)))
    onto_r = ranks(onto)
    if spearman(onto_r, ped_r) < 0:
        onto_r = 1 - onto_r
    crit_r = ranks(crit, reverse=True)
    if spearman(crit_r, ped_r) < 0:
        crit_r = 1 - crit_r

    spread = np.maximum.reduce([ped_r, onto_r, crit_r]) - np.minimum.reduce([ped_r, onto_r, crit_r])
    branches = []
    for i in range(len(pearls)):
        if spread[i] >= 0.45:
            pulls = sorted([("pedagogy", ped_r[i]), ("ontology", onto_r[i]), ("criticality", crit_r[i])], key=lambda t: t[1])
            branches.append({"pearl": pearls[i], "spread": round(float(spread[i]), 3),
                             "early": pulls[0][0], "late": pulls[-1][0]})
    branches.sort(key=lambda b: -b["spread"])

    return {
        "seq": seq, "name": sd.get("name", seq), "n": len(pearls),
        "pearls": pearls,
        "ped": [round(float(x), 3) for x in ped_r],
        "onto": [round(float(x), 3) for x in onto_r],
        "crit": [round(float(x), 3) for x in crit_r],
        "spread": [round(float(x), 3) for x in spread],
        "agreement": {"po": round(spearman(ped_r, onto_r), 2),
                      "pc": round(spearman(ped_r, crit_r), 2),
                      "oc": round(spearman(onto_r, crit_r), 2)},
        "branches": branches,
    }


def report(d):
    print("# three orders of '%s'  -  %d pearls\n" % (d["seq"], d["n"]))
    print("ORDER AGREEMENT (Spearman):  ped<->onto %+.2f   ped<->crit %+.2f   onto<->crit %+.2f\n"
          % (d["agreement"]["po"], d["agreement"]["pc"], d["agreement"]["oc"]))
    rows = sorted(range(d["n"]), key=lambda i: (d["ped"][i] + d["onto"][i] + d["crit"][i]) / 3)
    print("THE NECKLACE  (consensus order; * = branch point):")
    for i in rows:
        star = "*" if d["spread"][i] >= 0.45 else " "
        print("  %s %-34s  ped:%-5s onto:%-5s crit:%-5s  spread %.2f"
              % (star, d["pearls"][i][:34], band(d["ped"][i]), band(d["onto"][i]), band(d["crit"][i]), d["spread"][i]))
    print("\nBRANCH POINTS (%d) - where the 1D necklace wants to become 2D:" % len(d["branches"]))
    for b in d["branches"]:
        print("  %-32s  %s pulls it early, %s pulls it late  -> a side-pool" % (b["pearl"][:32], b["early"], b["late"]))


def main():
    args = sys.argv[1:]
    if "--all" in args:
        seqs = sorted(f[:-5] for f in os.listdir(SEQ_DIR) if f.endswith(".json"))
        out = []
        for s in seqs:
            try:
                d = compute(s)
                if d:
                    out.append(d)
            except Exception:
                pass
        out.sort(key=lambda d: -d["n"])
        print(json.dumps({"sequences": out}))
        return
    seq = args[0] if args and not args[0].startswith("--") else "fractals"
    d = compute(seq, min_pearls=3)
    if d is None:
        print("no data for '%s'" % seq)
        return
    if "--json" in args:
        print(json.dumps(d))
    else:
        report(d)


if __name__ == "__main__":
    main()
