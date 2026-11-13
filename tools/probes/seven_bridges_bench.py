"""seven_bridges_bench.py - the bridge sets of the hall GT_Foundations, as the lesson's own script names them
(algorithms/graphtheory/graphspace3d/konigsberg3d.gd, _bridge_table, axis `parity`), counted before the floor work
`seven_bridges` was built: the bridges at each land, how many lands are odd, whether one walk can cross every bridge
once, and - for the floor's walker - a walk to try from the entrance, which stands on land D.

  python tools/probes/seven_bridges_bench.py

Lands as the lesson numbers them: 0 A Altstadt, 1 B Loebenicht, 2 C Kneiphof, 3 D Vorstadt. Bridges are numbered as
the floor work lays them (its slots): 0, 1 = A-C; 2, 3 = A-D; 4 = A-B; 5 = B-C; 6 = B-D; 7 = C-D; 8 = the second A-B.
"""
from itertools import permutations

LANDS = ['A Altstadt', 'B Loebenicht', 'C Kneiphof', 'D Vorstadt']
SLOT_PAIR = {0: (0, 2), 1: (0, 2), 2: (0, 3), 3: (0, 3), 4: (0, 1), 5: (1, 2), 6: (1, 3), 7: (2, 3), 8: (0, 1)}
SETS = {'blocked': [0, 1, 2, 3, 4, 5, 6],            # the seven of 1736
        'walk': [0, 1, 2, 3, 4, 5, 6, 7],            # + Kneiphof-Vorstadt
        'circuit': [0, 1, 2, 3, 4, 5, 6, 7, 8],      # + a second Altstadt-Loebenicht
        'severed': [0, 1, 2, 3]}                     # every bridge that touched Loebenicht is gone
ENTRANCE = 3


def degrees(slots):
    d = [0, 0, 0, 0]
    for s in slots:
        a, b = SLOT_PAIR[s]
        d[a] += 1
        d[b] += 1
    return d


def reachable(slots, start):
    seen = {start}
    grew = True
    while grew:
        grew = False
        for s in slots:
            a, b = SLOT_PAIR[s]
            if (a in seen) != (b in seen):
                seen |= {a, b}
                grew = True
    return seen


def longest_trail(slots, start):
    """The longest walk from `start` that uses no bridge twice (depth first, the sets are tiny)."""
    best = []

    def go(at, used, path):
        nonlocal best
        if len(path) > len(best):
            best = list(path)
        for s in slots:
            if s in used:
                continue
            a, b = SLOT_PAIR[s]
            if a == at or b == at:
                go(b if a == at else a, used | {s}, path + [s])
    go(start, frozenset(), [])
    return best


def lands_of(trail, start):
    at = start
    out = [at]
    for s in trail:
        a, b = SLOT_PAIR[s]
        at = b if a == at else a
        out.append(at)
    return out


if __name__ == '__main__':
    for name, slots in SETS.items():
        d = degrees(slots)
        odd = [LANDS[i][0] for i in range(4) if d[i] % 2 == 1]
        joined = reachable(slots, ENTRANCE)
        used = [i for i in range(4) if d[i] > 0]
        whole = all(i in joined for i in used)
        can = whole and len(odd) in (0, 2)
        print('%-8s %d bridges; at A, B, C, D: %s; odd lands: %s; every land with a bridge reached from D: %s' % (name, len(slots), d, ''.join(odd) or 'none', whole))
        print('         one walk over every bridge once: %s' % ('no' if not can else ('yes, from any land, ending where it began' if not odd else 'yes, but only from %s to %s' % (odd[0], odd[1]))))
        from_d = longest_trail(slots, ENTRANCE)
        print('         from the entrance (D): %d of %d bridges, slots %s, lands %s' % (len(from_d), len(slots), from_d, ''.join(LANDS[i][0] for i in lands_of(from_d, ENTRANCE))))
        if can and odd and LANDS[ENTRANCE][0] not in odd:
            begin = [i for i in range(4) if d[i] % 2 == 1][0]
            trail = longest_trail(slots, begin)
            print('         from %s: %d of %d, slots %s, lands %s' % (LANDS[begin][0], len(trail), len(slots), trail, ''.join(LANDS[i][0] for i in lands_of(trail, begin))))
        never = [LANDS[i] for i in range(4) if i not in joined]
        if never:
            print('         never reached: %s' % ', '.join(never))
