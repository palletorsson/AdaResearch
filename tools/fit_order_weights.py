"""fit_order_weights.py — reverse-engineer the editor's implicit weights.

The six WRITTEN chapters' manual orders are trusted ground truth. This searches
the weight simplex over the five independent lenses (pedagogy / ontology /
criticality / engine / atoms — consensus is excluded because it is itself a
ped+onto+crit blend) for the vector whose blended order best reproduces the
manual order, measured by mean Spearman across the written chapters.

Two fits:
  · GLOBAL  — one weight vector for all written chapters (the default to apply
              to unwritten chapters)
  · PER-CHAPTER — the best vector per chapter (shows how much natures differ;
              if these diverge wildly, a global default is a compromise)

Output: doc/book/order_weights.json  (+ printed report)

Usage: python tools/fit_order_weights.py [--step=0.25]
"""

import itertools
import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENC = Path(os.environ.get("ADA_ENCYCLOPEDIA_PATH", ROOT.parent / "ada_encyclopedia"))
MIXER = ENC / "public" / "order-mixer.json"
OUT = ROOT / "doc" / "book" / "order_weights.json"

WRITTEN = ["primitives", "array_tutorial", "softbodies", "fractals",
           "qfeplaboratory", "postfoundationscrisis"]
LENSES = ["pedagogy", "ontology", "criticality", "engine", "atoms"]


def spearman(xs, ys):
    n = len(xs)
    if n < 4:
        return None

    def ranks(v):
        order = sorted(range(n), key=lambda i: v[i])
        r = [0.0] * n
        i = 0
        while i < n:
            j = i
            while j + 1 < n and v[order[j + 1]] == v[order[i]]:
                j += 1
            avg = (i + j) / 2 + 1
            for k in range(i, j + 1):
                r[order[k]] = avg
            i = j + 1
        return r

    rx, ry = ranks(xs), ranks(ys)
    mx, my = sum(rx) / n, sum(ry) / n
    cov = sum((rx[i] - mx) * (ry[i] - my) for i in range(n))
    vx = sum((rx[i] - mx) ** 2 for i in range(n)) ** 0.5
    vy = sum((ry[i] - my) ** 2 for i in range(n)) ** 0.5
    return cov / (vx * vy) if vx and vy else None


def blended_rho(arts, weights):
    """spearman(manual rank, blended score) for one sequence."""
    xs, ys = [], []
    for i, a in enumerate(arts):
        num = den = 0.0
        for lens, wgt in zip(LENSES, weights):
            v = a["lenses"].get(lens)
            if wgt > 0 and v is not None:
                num += wgt * v
                den += wgt
        if den > 0:
            xs.append(i)          # manual rank = position in mixer list
            ys.append(num / den)
    return spearman(xs, ys)


def main():
    step = 0.25
    for a in sys.argv[1:]:
        if a.startswith("--step="):
            step = float(a.split("=", 1)[1])

    seqs = json.loads(MIXER.read_text(encoding="utf-8"))["sequences"]
    levels = [round(step * i, 4) for i in range(int(1 / step) + 1)]
    grid = [w for w in itertools.product(levels, repeat=len(LENSES)) if any(w)]

    def fit(chapters):
        best_w, best_mean = None, -2
        for w in grid:
            rhos = []
            for seq in chapters:
                rho = blended_rho(seqs[seq]["artifacts"], w)
                if rho is not None:
                    rhos.append(rho)
            if rhos:
                m = sum(rhos) / len(rhos)
                if m > best_mean:
                    best_mean, best_w = m, w
        return best_w, best_mean

    global_w, global_rho = fit(WRITTEN)
    per = {}
    for seq in WRITTEN:
        w, r = fit([seq])
        per[seq] = {"weights": dict(zip(LENSES, w)), "rho": round(r, 3)}

    # how well does the global vector transfer to each written chapter?
    transfer = {seq: round(blended_rho(seqs[seq]["artifacts"], global_w) or 0, 3)
                for seq in WRITTEN}

    out = {"generated_by": "tools/fit_order_weights.py",
           "note": "weights fitted to reproduce the manual order of the written chapters; consensus excluded (it is itself a blend)",
           "global": {"weights": dict(zip(LENSES, global_w)),
                      "mean_rho": round(global_rho, 3), "per_chapter_rho": transfer},
           "per_chapter": per}
    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=1), encoding="utf-8")

    print(f"GLOBAL fit (mean rho {global_rho:+.3f} over {len(WRITTEN)} written chapters):")
    for l, w in zip(LENSES, global_w):
        print(f"  {l:12} {w}")
    print("  transfer per chapter:", transfer)
    print("\nPER-CHAPTER best fits:")
    for seq, p in per.items():
        ws = " ".join(f"{l[:4]}={v}" for l, v in p["weights"].items() if v > 0)
        print(f"  {seq:24} rho={p['rho']:+.3f}  {ws}")
    print(f"-> {OUT}")


if __name__ == "__main__":
    main()
