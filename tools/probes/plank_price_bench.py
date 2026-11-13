"""plank_price_bench.py - the lands and plank bridges of the floor work `plank_price` (hall GT_Spanning_Trees), counted
before it was built. A bridge costs its length in planks: 1, 2 or 4 metres, the three plank prefabs.

  python tools/probes/plank_price_bench.py

Lands: S (the south bank, where the way in is), A1 B1 C1 (the near row of islands), A2 B2 C2 (the far row).
Bridge places, numbered as the work lays them:
  0 S-A1 2 m   1 S-B1 2 m   2 S-C1 2 m   3 A1-B1 1 m   4 B1-C1 2 m
  5 A2-B2 1 m  6 B2-C2 2 m  7 A1-A2 4 m  8 B1-B2 4 m   9 C1-C2 4 m
"""
LANDS = ['S', 'A1', 'B1', 'C1', 'A2', 'B2', 'C2']
SLOTS = [('S', 'A1', 2), ('S', 'B1', 2), ('S', 'C1', 2), ('A1', 'B1', 1), ('B1', 'C1', 2),
         ('A2', 'B2', 1), ('B2', 'C2', 2), ('A1', 'A2', 4), ('B1', 'B2', 4), ('C1', 'C2', 4)]


def pieces(laid):
    """The lands grouped by what the laid bridges join."""
    group = {l: l for l in LANDS}

    def find(l):
        while group[l] != l:
            l = group[l]
        return l
    for i in laid:
        a, b, _ = SLOTS[i]
        group[find(a)] = find(b)
    out = {}
    for l in LANDS:
        out.setdefault(find(l), []).append(l)
    return sorted(out.values(), key=lambda g: LANDS.index(g[0]))


def kruskal():
    """Shortest first, the lower number first among equals; a bridge is left out when its two ends are already joined."""
    laid = []
    for i in sorted(range(len(SLOTS)), key=lambda i: (SLOTS[i][2], i)):
        a, b, _ = SLOTS[i]
        if not any(a in g and b in g for g in pieces(laid)):
            laid.append(i)
    return sorted(laid)


def describe(name, laid):
    timber = sum(SLOTS[i][2] for i in laid)
    p = pieces(laid)
    from_s = next(g for g in p if 'S' in g)
    spare = len(laid) - len(LANDS) + len(p)
    print('%-9s bridges %s: %d m of plank, %d of %d lands reached from S, %d spare' % (name, laid, timber, len(from_s), len(LANDS), spare))
    return timber


if __name__ == '__main__':
    tree = kruskal()
    least = describe('tree', tree)
    for i in tree:
        cut = [x for x in tree if x != i]
        left = next(g for g in pieces(cut) if 'S' in g)
        print('          take %d away (%s-%s, %d m): %d lands cut off from S' % (i, SLOTS[i][0], SLOTS[i][1], SLOTS[i][2], len(LANDS) - len(left)))
    one_more = sorted(tree + [8])
    describe('one_more', one_more)
    for i in tree:
        cut = [x for x in one_more if x != i]
        left = next(g for g in pieces(cut) if 'S' in g)
        print('          take %d away: %d lands cut off from S' % (i, len(LANDS) - len(left)))
    describe('all', list(range(len(SLOTS))))
    print('the least plank that reaches every land: %d m' % least)
