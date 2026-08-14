#!/usr/bin/env python3
"""predict_pairs.py — enumerate EVERY pair of a sweep, so a prediction cannot name the wrong one.

WHY THIS EXISTS, and it is a fault of mine rather than of the pipeline. The declaring agent
in waves 8-10 rasterised every variant and returned a full pair table; predicting inline in
wave 11 I did the arithmetic by hand along ONE axis and named `path` vs `envelope` as
residue_hall's closest pair. The measured closest was `residue = head` at two different
tenures — the OTHER axis, at the lowest rung, where the hall draws three balls and the
second axis only nudges them. I reasoned along the axis I was thinking about and never
enumerated the cross-axis pairs.

This does the enumeration. It does not rasterise — it takes a per-variant COST that the
caller supplies (a count of marks, a total drawn length, an area, whatever the artifact's
own arithmetic makes cheap) and reports every pair ranked by absolute difference, so the
quietest pair is found rather than guessed. A cost model that is wrong about magnitude is
still usually right about ORDER, and order is what the prediction has to get right.

Usage as a library, which is how a build script should use it:

    from predict_pairs import rank
    cost = {("chain","square"): 41.2, ("star","square"): 38.9, ...}
    for a, b, d in rank(cost)[:5]:
        print(a, b, d)

Usage from the shell, for a quick check against a JSON of {"variant": cost}:

    python tools/predict_pairs.py costs.json
"""
from __future__ import annotations
import itertools
import json
import sys


def rank(cost: dict) -> list:
    """Every unordered pair, quietest first.

    `cost` maps a variant key (a tuple or a string) to a number. The pair difference is
    |cost(a) - cost(b)|, which is a PROXY and is only claimed to order pairs, never to
    predict a percentage.
    """
    out = []
    for a, b in itertools.combinations(sorted(cost, key=lambda k: str(k)), 2):
        out.append((a, b, abs(float(cost[a]) - float(cost[b]))))
    out.sort(key=lambda t: t[2])
    return out


def report(cost: dict, axes: tuple = ()) -> str:
    """A printable table, with the same-axis and cross-axis pairs marked.

    THE CROSS-AXIS ROWS ARE THE POINT. A pair that varies BOTH axes at once is still a pair
    the sweep will diff, and the quietest pair in wave 11 was one of those. Marking them
    stops a reader skimming only the rows they were already thinking about.
    """
    rows = rank(cost)
    lines = []
    lines.append(f"{'quietest pairs':<52}{'delta':>10}   kind")
    lines.append("-" * 78)
    for a, b, d in rows[:12]:
        kind = "same-axis"
        if isinstance(a, tuple) and isinstance(b, tuple) and len(a) == len(b):
            differing = sum(1 for i in range(len(a)) if a[i] != b[i])
            kind = "same-axis" if differing == 1 else f"CROSS-AXIS ({differing} differ)"
        lines.append(f"{str(a) + '  vs  ' + str(b):<52}{d:>10.3f}   {kind}")
    lines.append("-" * 78)
    if rows:
        a, b, d = rows[0]
        lines.append(f"PREDICTED CLOSEST PAIR: {a}  vs  {b}   (delta {d:.3f})")
        lines.append("The delta is a PROXY for ordering, not a percentage. Convert it to a")
        lines.append("frame percentage with the artifact's own gauge before writing the floor.")
    return "\n".join(lines)


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    with open(sys.argv[1], encoding="utf-8") as fh:
        cost = json.load(fh)
    print(report(cost))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
