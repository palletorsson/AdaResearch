"""record_piles_bench.py - the nearest-target rule of the hall PG_Branching_Growth, as its desk steps it
(commons/artifacts/timing_machines/pg_workshop.gd on algorithms/.../branching_growth_algorithm.gd), counted the way
the floor work `record_piles` lays it out: every stored record is one board, records at one position lie on each other.

  python tools/probes/record_piles_bench.py

Prints, step by step: records, distinct positions, targets reached; then the piles. Without variation the rule's
random terms are off and the run is exact; with variation the jitter is Python's generator, not Godot's, so those
numbers are an illustration of the spread, not a prediction of a frame.
"""
import math
import random
from collections import Counter

TARGETS = [(-2, 1.5, 0), (-2.5, 2.5, 0.4), (-3, 3.5, 0), (1.5, 2.5, 0), (2, 3.5, -0.5), (2.5, 4.5, 0), (0, 5.5, 1), (0, 6, 0)]
REACH = 8.0      # attraction_distance, as the desk sets it
STEP = 0.5       # growth_distance
TOUCH = 0.32     # min_branch_distance
CAP = 192


def run(steps, jitter=0.0, pulse=0.0, seed=1):
    rnd = random.Random(seed)
    records = [{'p': (0.0, 0.0, 0.0), 'parent': -1, 'active': True}]
    reached = [False] * len(TARGETS)
    t = 0.0
    history = []
    for s in range(steps):
        if len(records) >= CAP:
            break
        t += 0.2
        new, hit, full = [], [], False
        for i, b in enumerate(records):
            if not b['active']:
                continue
            best, near = -1, REACH
            for j, target in enumerate(TARGETS):
                if reached[j]:
                    continue
                d = math.dist(b['p'], target)
                if d < near:
                    near, best = d, j
            if best >= 0:
                way = [TARGETS[best][k] - b['p'][k] for k in range(3)]
                n = math.sqrt(sum(x * x for x in way))
                way = [x / n for x in way] if n > 0 else [0.0, 0.0, 0.0]      # Godot: the zero vector normalises to zero
                if jitter > 0:
                    wave = math.sin(t * 3 + math.sqrt(sum(x * x for x in b['p']))) * jitter * 0.5
                    way = [way[0] + rnd.uniform(-jitter, jitter) + wave, way[1] + rnd.uniform(-jitter, jitter) + math.sin(t * 2) * jitter * 0.3,
                           way[2] + rnd.uniform(-jitter, jitter) + math.cos(t * 2.5) * jitter * 0.3]
                    n = math.sqrt(sum(x * x for x in way))
                    way = [x / n for x in way]
                length = STEP * (1 + math.sin(t) * pulse * 0.5)
                new.append({'p': tuple(b['p'][k] + way[k] * length for k in range(3)), 'parent': i, 'active': True})
                if near < TOUCH:
                    hit.append(best)
                    b['active'] = False
            else:
                b['active'] = False
            if len(records) >= CAP:
                full = True
                break
        if full:
            break
        for nb in new:
            if len(records) >= CAP:
                break
            records.append(nb)
        for j in hit:
            reached[j] = True
        history.append((s + 1, len(records), len(set(b['p'] for b in records)), sum(reached)))
    return records, reached, history


if __name__ == '__main__':
    for name, kw in (('the rule alone', {}), ('with variation', {'jitter': 0.15, 'pulse': 0.3})):
        records, reached, history = run(60, **kw)
        print(name)
        print('  step: records / distinct positions / targets reached')
        print('  ' + '  '.join('%d: %d/%d/%d' % h for h in history))
        piles = Counter(b['p'] for b in records)
        print('  %d records on %d positions; the eight tallest piles: %s; targets reached %d of 8' % (len(records), len(piles), sorted(piles.values(), reverse=True)[:8], sum(reached)))
        for p, n in sorted(piles.items(), key=lambda kv: -kv[1])[:6]:
            print('    %3d records at (%.2f, %.2f, %.2f)' % (n, *p))
        xs = [b['p'][0] for b in records]
        ys = [b['p'][1] for b in records]
        print('  extent x %.2f..%.2f, y %.2f..%.2f' % (min(xs), max(xs), min(ys), max(ys)))
