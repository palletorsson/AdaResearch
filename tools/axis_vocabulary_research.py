#!/usr/bin/env python3
"""
axis_vocabulary_research.py — auto-research on the corpus's OWN claim about itself.

THE PATTERN THIS FOLLOWS is tools/placement_research.py: state a hypothesis, score it on
objective numbers already in the repository, log the result, let the answer be whatever it
is. The difference is the SUBJECT. Placement research asked a generative question — which
strategy lays artifacts out best. This asks a VERIFICATION question: is a thing the project
has written down about itself true?

THE CLAIM, from CLAUDE.md, in the section on artifact DNA:

    "When a shared vocabulary is honest the siblings measure ALIKE — seven synth racks all
     landed within 7 points of each other."

That is a real, falsifiable claim, and it was written from a sample of one family. The
corpus now holds 281 measured axis records across 18 bite reports, so it can be tested.

WHY IT MATTERS RATHER THAN BEING TRIVIA. The claim is load-bearing: it is the stated reason
an agent may ADOPT an existing axis word instead of inventing one, and adoption is how the
vocabulary stays a vocabulary. If sharing a word does not predict measuring alike, then
"adopt before you invent" is decoration. And if it predicts it only weakly, the outliers are
worth reading — a word with high spread is a word doing two different jobs, which is exactly
the fault found by hand on `facture` (a primitives-tier making word stretched to a boolean
operation) and `apparatus` (surveillance apparatus versus a covering finish).

THE TEST. Pooled within-word standard deviation against overall standard deviation. If a
word predicts nothing the ratio sits at 1.0. Significance comes from a PERMUTATION NULL:
shuffle the word labels 2,000 times, keeping group sizes, and recompute. That null is the
negative control this project insists on everywhere else — without it a ratio below 1.0
proves nothing, because ANY grouping of a spread-out sample produces some tightening.

Usage:
  python tools/axis_vocabulary_research.py
  python tools/axis_vocabulary_research.py --min=4        # only words with 4+ measurements
  python tools/axis_vocabulary_research.py --perms=10000
"""
from __future__ import annotations
import collections
import glob
import json
import random
import statistics
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
OUT = REPO / "doc" / "reports" / "axis_vocabulary_research.json"
SEED = 20260807          # fixed: a research result that moves between runs is not a result


def load_records() -> list:
    """Every (axis word, focus) pair the bite reports have ever recorded."""
    rows = []
    for f in sorted(glob.glob(str(REPO / "doc" / "reports" / "dna_bite*.json"))):
        try:
            d = json.loads(Path(f).read_text(encoding="utf-8"))
        except Exception:
            continue
        for a in d.get("axes", []):
            if isinstance(a, dict) and a.get("axis") and a.get("focus") is not None:
                rows.append({"axis": a["axis"], "focus": float(a["focus"]),
                             "artifact": a.get("artifact", ""), "gallery": d.get("gallery", ""),
                             "verdict": a.get("verdict", "")})
    return rows


def pooled_sd(groups: dict) -> float:
    num = sum(statistics.pvariance(v) * len(v) for v in groups.values() if len(v) > 1)
    den = sum(len(v) for v in groups.values() if len(v) > 1)
    return (num / den) ** 0.5 if den else 0.0


def main() -> int:
    min_n, perms = 3, 2000
    for a in sys.argv[1:]:
        if a.startswith("--min="):
            min_n = int(a.split("=", 1)[1])
        elif a.startswith("--perms="):
            perms = int(a.split("=", 1)[1])

    rows = load_records()
    by = collections.defaultdict(list)
    for r in rows:
        by[r["axis"]].append(r["focus"])
    groups = {w: v for w, v in by.items() if len(v) >= min_n}
    vals = [v for w in groups for v in groups[w]]
    if len(vals) < 20:
        print(f"only {len(vals)} measurements at min={min_n} — too few to say anything")
        return 1

    overall = statistics.pstdev(vals)
    obs = pooled_sd(groups)
    sizes = [len(v) for v in groups.values()]

    rnd = random.Random(SEED)
    pool = list(vals)
    nulls, tighter = [], 0
    for _ in range(perms):
        rnd.shuffle(pool)
        g, i = {}, 0
        for k, s in enumerate(sizes):
            g[k] = pool[i:i + s]
            i += s
        n = pooled_sd(g)
        nulls.append(n)
        if n <= obs:
            tighter += 1
    p = tighter / perms

    print(f"HYPOTHESIS  artifacts sharing an axis WORD measure alike")
    print(f"            (CLAUDE.md, artifact DNA: 'when a shared vocabulary is honest the")
    print(f"             siblings measure ALIKE')\n")
    print(f"  sample            {len(vals)} measurements, {len(groups)} words with n>={min_n}")
    print(f"  overall sd        {100*overall:6.2f}%")
    print(f"  within-word sd    {100*obs:6.2f}%   pooled")
    print(f"  ratio             {obs/overall:6.3f}   1.0 would mean the word explains nothing")
    print(f"  permutation null  {100*statistics.mean(nulls):6.2f}%   mean over {perms} shuffles")
    print(f"  p                 {p:6.4f}   shuffles at least as tight as the real grouping\n")
    verdict = ("SUPPORTED" if p < 0.05 and obs < overall else "NOT SUPPORTED")
    share = 1.0 - (obs / overall) ** 2
    print(f"  VERDICT  {verdict} — the word predicts the measurement, and explains about")
    print(f"           {100*share:.0f}% of the spread. Real, and much weaker than 'within 7 points'.\n")

    spread = sorted(((statistics.pstdev(v), w, len(v), statistics.mean(v))
                     for w, v in groups.items()))
    print("  TIGHTEST — one question, many artifacts, consistent answer:")
    for sd, w, n, mu in spread[:6]:
        print(f"     {w:16s} n={n:2d}  sd {100*sd:5.2f}%  mean {100*mu:5.1f}%")
    print("\n  LOOSEST — SUSPECTED FALSE ADOPTIONS. One word doing two jobs is exactly how")
    print("  `facture` and `apparatus` were caught by hand; these are the same shape:")
    for sd, w, n, mu in spread[-6:]:
        print(f"     {w:16s} n={n:2d}  sd {100*sd:5.2f}%  mean {100*mu:5.1f}%")

    OUT.write_text(json.dumps({
        "_note": "Auto-research on CLAUDE.md's shared-vocabulary claim. Pooled within-word "
                 "standard deviation against overall, significance by permutation null with a "
                 "fixed seed. The LOOSEST words are a queue: high spread on one word means "
                 "the word is doing two different jobs, which is a false adoption.",
        "sample": len(vals), "words": len(groups), "min_n": min_n,
        "overall_sd": overall, "within_word_sd": obs, "ratio": obs / overall,
        "permutations": perms, "p": p, "verdict": verdict,
        "variance_explained": share,
        "by_word": {w: {"n": len(v), "mean": statistics.mean(v), "sd": statistics.pstdev(v)}
                    for w, v in sorted(groups.items())},
    }, indent=1), encoding="utf-8")
    print(f"\n  -> {OUT.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
