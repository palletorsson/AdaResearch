"""handoff_score.py — does each map hand its question to the next map?

The dialectic claim (heroes.json): the ANTI-HERO of map N is the question map
N+1 opens with. In a told chapter the handoffs connect (Cantor's dust hands
Koch its question); in an inventory they don't.

v2 — two fixes over the lexical draft (which stubs beat by repeating text):

  · SEMANTICS: texts are embedded with the Atlas recipe (TF-IDF -> TruncatedSVD
    LSA), fit on the artifact-cards corpus + all heroes texts, so related
    concepts score near even when the words differ.
  · LIFT, not level: the score is  mean(adjacent handoff) − mean(shuffled
    handoff)  over K within-sequence shuffles. Repetition inflates both terms
    equally and cancels; only genuine ORDER survives. A chapter whose chain
    beats its own shuffle is told; one that doesn't is an inventory.

Validation: the six WRITTEN chapters should show higher lift than the stubs.

Output: doc/book/handoff_scores.json  (+ printed table)

Usage:
  python tools/handoff_score.py [--seq=<id>] [--shuffles=K]
"""

import json
import random
import sys
from pathlib import Path

import numpy as np
from sklearn.decomposition import TruncatedSVD
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import normalize

ROOT = Path(__file__).resolve().parent.parent
HEROES = ROOT / "doc" / "book" / "heroes.json"
CARDS = ROOT / "doc" / "atlas" / "artifact_cards.json"
OUT = ROOT / "doc" / "book" / "handoff_scores.json"

WRITTEN = {"primitives", "array_tutorial", "softbodies", "fractals",
           "qfeplaboratory", "postfoundationscrisis"}
SEED = 461  # deterministic shuffles


def card_text(c):
    return " ".join(str(c.get(k, "")) for k in
                    ("lookup_name", "description", "essence", "truth", "family"))


def main():
    only, k_shuffles = None, 50
    for a in sys.argv[1:]:
        if a.startswith("--seq="):
            only = a.split("=", 1)[1]
        if a.startswith("--shuffles="):
            k_shuffles = int(a.split("=", 1)[1])

    heroes = json.loads(HEROES.read_text(encoding="utf-8"))["sequences"]

    # ── corpus: atlas cards + every heroes text → LSA space ────────────────
    corpus = []
    if CARDS.exists():
        corpus += [card_text(c) for c in json.loads(CARDS.read_text(encoding="utf-8"))]
    q_texts, a_texts, keys = [], [], []   # question side / answer side per map
    for seq, maps in heroes.items():
        for name, m in maps.items():
            if not isinstance(m, dict):
                continue
            q = " ".join([m.get("anti", ""), m.get("tension", "")]).strip()
            ans = " ".join([m.get("hero", ""), m.get("tension", "")]).strip()
            keys.append((seq, name))
            q_texts.append(q)
            a_texts.append(ans)
    corpus += [t for t in q_texts + a_texts if t]

    vec = TfidfVectorizer(min_df=2, max_df=0.5, sublinear_tf=True,
                          token_pattern=r"[a-zA-Zφλ]{3,}")
    X = vec.fit_transform(corpus)
    svd = TruncatedSVD(n_components=min(128, X.shape[1] - 1), random_state=SEED)
    svd.fit(X)

    def embed(texts):
        M = svd.transform(vec.transform(texts))
        return normalize(M)

    Q = embed(q_texts)
    A = embed(a_texts)
    qv = {k: Q[i] for i, k in enumerate(keys) if q_texts[i]}
    av = {k: A[i] for i, k in enumerate(keys) if a_texts[i]}

    # ── per sequence: adjacent handoff vs shuffled baseline → lift ─────────
    rng = random.Random(SEED)
    out = {"generated_by": "tools/handoff_score.py",
           "metric": "LSA cosine handoff anti(N)->hero(N+1); LIFT = adjacent − shuffled(K)",
           "shuffles": k_shuffles, "sequences": {}}
    rows = []
    for seq, maps in heroes.items():
        if only and seq != only:
            continue
        names = [n for n in maps if isinstance(maps[n], dict)]

        def chain_score(order):
            vals = []
            for i in range(len(order) - 1):
                q = qv.get((seq, order[i]))
                ans = av.get((seq, order[i + 1]))
                if q is not None and ans is not None:
                    vals.append(float(np.dot(q, ans)))
            return (sum(vals) / len(vals), len(vals)) if vals else (None, 0)

        adjacent, n_pairs = chain_score(names)
        shuffled_means = []
        for _ in range(k_shuffles):
            perm = names[:]
            rng.shuffle(perm)
            s, _ = chain_score(perm)
            if s is not None:
                shuffled_means.append(s)
        base = sum(shuffled_means) / len(shuffled_means) if shuffled_means else None
        lift = (round(adjacent - base, 4)
                if adjacent is not None and base is not None else None)

        pairs = []
        for i in range(len(names) - 1):
            q = qv.get((seq, names[i]))
            ans = av.get((seq, names[i + 1]))
            s = round(float(np.dot(q, ans)), 3) if q is not None and ans is not None else None
            pairs.append({"from": names[i], "to": names[i + 1], "score": s})

        out["sequences"][seq] = {
            "adjacent": round(adjacent, 4) if adjacent is not None else None,
            "shuffled": round(base, 4) if base is not None else None,
            "lift": lift, "pairs_scored": n_pairs,
            "written": seq in WRITTEN, "pairs": pairs,
        }
        rows.append((seq, lift, adjacent, base, n_pairs, seq in WRITTEN))

    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=1), encoding="utf-8")

    rows.sort(key=lambda r: -(r[1] if r[1] is not None else -9))
    print(f"{'sequence':26} {'lift':>8} {'adjacent':>9} {'shuffled':>9} {'pairs':>6}  written")
    for seq, lift, adj, base, n, w in rows:
        f = lambda x: f"{x:.3f}" if x is not None else "—"
        print(f"{seq:26} {f(lift):>8} {f(adj):>9} {f(base):>9} {n:>6}  {'*' if w else ''}")
    wr = [r[1] for r in rows if r[5] and r[1] is not None]
    st = [r[1] for r in rows if not r[5] and r[1] is not None]
    if wr and st:
        print(f"\nvalidation: written lift {sum(wr)/len(wr):+.4f} vs stub lift {sum(st)/len(st):+.4f}")
    print(f"-> {OUT}")


if __name__ == "__main__":
    main()
