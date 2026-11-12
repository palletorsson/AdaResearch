"""percolation_bench.py - which fields can a body cross, and which only a signal?

A field `cols` cells across and `rows` cells deep. Every cell has one fixed number r in [0, 1) (a seeded hash); with `open` = p the
cell is floor if r < p and a block otherwise, so opening more never closes anything.
A BODY goes from an open cell to an open cell across a shared FACE (two blocks that touch at a corner leave no gap).
A SIGNAL also passes where two open cells touch at a CORNER.
Crossing = from the near row (row 0, where a visitor stands) to the far row.

    python tools/probes/percolation_bench.py [cols rows]          -> for seeds 1..30: the first p (in steps of 0.05) at which each crosses
    python tools/probes/percolation_bench.py --json <seed>        -> {p: [body crosses, signal crosses, open cells, body reach, signal reach]}
"""
import sys, json
from collections import deque

STEPS = [0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55, 0.60, 0.65, 0.70, 0.75]


def hash01(*key):
    h = 2166136261
    for v in key:
        h = ((h ^ (int(v) & 0xffffffff)) * 16777619) & 0xffffffff
        h ^= h >> 13
        h = (h * 1274126177) & 0xffffffff
    h ^= h >> 16
    return (h & 0xffffff) / 16777216.0


def field(seed, cols, rows):
    return [[hash01(seed, c, r) for r in range(rows)] for c in range(cols)]


def reach(numbers, p, corners):
    cols, rows = len(numbers), len(numbers[0])
    seen = set()
    dq = deque()
    for c in range(cols):
        if numbers[c][0] < p:
            seen.add((c, 0)); dq.append((c, 0))
    steps = [(1, 0), (-1, 0), (0, 1), (0, -1)] + ([(1, 1), (1, -1), (-1, 1), (-1, -1)] if corners else [])
    while dq:
        c, r = dq.popleft()
        for dc, dr in steps:
            n = (c + dc, r + dr)
            if 0 <= n[0] < cols and 0 <= n[1] < rows and n not in seen and numbers[n[0]][n[1]] < p:
                seen.add(n); dq.append(n)
    return seen


def table(seed, cols, rows):
    numbers = field(seed, cols, rows)
    out = {}
    for p in STEPS:
        body = reach(numbers, p, False)
        signal = reach(numbers, p, True)
        out['%.2f' % p] = [any(r == rows - 1 for c, r in body), any(r == rows - 1 for c, r in signal),
                           sum(1 for col in numbers for v in col if v < p), len(body), len(signal)]
    return out


if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if not a.startswith('-')]
    if '--json' in sys.argv:
        print(json.dumps(table(int(args[0]), int(args[1]) if len(args) > 1 else 12, int(args[2]) if len(args) > 2 else 10)))
        sys.exit(0)
    cols, rows = (int(args[0]), int(args[1])) if len(args) >= 2 else (12, 10)
    for seed in range(1, 31):
        t = table(seed, cols, rows)
        body = next((p for p in t if t[p][0]), '-')
        signal = next((p for p in t if t[p][1]), '-')
        print('seed %2d  %d x %d: a signal first crosses at %s, a body at %s   %s' % (seed, cols, rows, signal, body,
              '  '.join('%s:%s%s' % (p[2:], 'S' if t[p][1] else '.', 'B' if t[p][0] else '.') for p in t)))
