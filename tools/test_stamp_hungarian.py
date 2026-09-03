#!/usr/bin/env python3
"""Is stamp.hungarian actually optimal?

The flow implementation was cross-checked against networkx and the check earned
its keep: the answer agreed and the WITNESS did not, which is how the classifier
turned out to be asking a question that had no well-defined answer. So do the
same here, against scipy.optimize.linear_sum_assignment, on random matrices and
on the shapes a real room produces.

An assignment's total COST is unique even when the assignment is not, so cost is
what gets compared. Two optimal solutions may pair different cells; only a
different total means one of them is wrong.

    python tools/test_stamp_hungarian.py
"""
from __future__ import annotations

import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import stamp  # noqa: E402

try:
    from scipy.optimize import linear_sum_assignment
    import numpy as np
    HAVE_SCIPY = True
except Exception:
    HAVE_SCIPY = False


def total(cost, pairs):
    return sum(cost[i][j] for i, j in pairs)


def brute(cost):
    """Exhaustive optimum, for the small cases. The reference of last resort."""
    import itertools
    n, m = len(cost), len(cost[0])
    best = None
    for cols in itertools.permutations(range(m), n):
        t = sum(cost[i][cols[i]] for i in range(n))
        if best is None or t < best:
            best = t
    return best


def main() -> int:
    rng = random.Random(20260903)
    fails = 0
    checked = 0

    # --- against brute force, where brute force is affordable --------------
    for trial in range(60):
        n = rng.randint(1, 5)
        m = rng.randint(n, 6)
        cost = [[float(rng.randint(0, 30)) for _ in range(m)] for _ in range(n)]
        got = stamp.hungarian(cost)
        if len(got) != n:
            print("FAIL trial %d: assigned %d of %d rows" % (trial, len(got), n))
            fails += 1
            continue
        mine, opt = total(cost, got), brute(cost)
        checked += 1
        if abs(mine - opt) > 1e-9:
            print("FAIL trial %d: cost %g against optimum %g" % (trial, mine, opt))
            fails += 1
    print("brute force: %d random matrices up to 5x6, %d disagreements"
          % (checked, fails))

    # --- against scipy, at the sizes a real hall produces ------------------
    if HAVE_SCIPY:
        big_fails = 0
        for trial in range(40):
            n = rng.randint(2, 25)
            m = rng.randint(n, n + 60)
            cost = [[float(rng.randint(0, 200)) for _ in range(m)] for _ in range(n)]
            got = stamp.hungarian(cost)
            r, c = linear_sum_assignment(np.array(cost))
            ref = float(np.array(cost)[r, c].sum())
            mine = total(cost, got)
            if len(got) != n or abs(mine - ref) > 1e-6:
                print("FAIL big %d (%dx%d): mine %g, scipy %g, rows %d/%d"
                      % (trial, n, m, mine, ref, len(got), n))
                big_fails += 1
        print("scipy      : 40 matrices up to 25x85, %d disagreements" % big_fails)
        fails += big_fails
    else:
        print("scipy      : not installed, skipped (this is not a failure)")

    # --- the forbidden-pair contract ---------------------------------------
    INF = float("inf")
    cost = [[1.0, INF], [INF, 2.0]]
    got = stamp.hungarian(cost)
    ok = sorted(got) == [(0, 0), (1, 1)]
    print("forbidden  : an INF pair is never returned ... %s" % ("OK" if ok else "FAIL"))
    fails += 0 if ok else 1

    cost = [[INF, INF], [1.0, 2.0]]
    got = stamp.hungarian(cost)
    ok = all(cost[i][j] < INF for i, j in got)
    print("forbidden  : a row with no legal column is dropped ... %s"
          % ("OK" if ok else "FAIL"))
    fails += 0 if ok else 1

    # --- and the property the room actually needs --------------------------
    # Greedy is order-dependent; the assignment must not be. Shuffling the rows
    # must not change the total.
    cost = [[float(rng.randint(0, 50)) for _ in range(12)] for _ in range(8)]
    base = total(cost, stamp.hungarian(cost))
    stable = True
    for _ in range(8):
        order = list(range(8))
        rng.shuffle(order)
        shuffled = [cost[i] for i in order]
        if abs(total(shuffled, stamp.hungarian(shuffled)) - base) > 1e-9:
            stable = False
    print("order      : total cost is the same under 8 row shufflings ... %s"
          % ("OK" if stable else "FAIL"))
    fails += 0 if stable else 1

    print("\n%s" % ("PASS" if not fails else "%d FAILURE(S)" % fails))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
