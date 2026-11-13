"""way_back_bench.py - the places and connections of the floor work `way_back` (hall GT_Connectivity), counted before
it was built: which places can reach which, and which places share a group (a strongly connected component: every
place in it can reach every other AND be reached back).

  python tools/probes/way_back_bench.py

Places: the hall FLOOR, ONE (a platform 2 m up), TWO (1 m up), THREE (a court at floor level, fenced).
Connections are physical. A wedge is walked both ways. A drop of a metre is walked one way: a body steps off and
cannot climb back.
  always   FLOOR <-> ONE by the ramp; ONE -> TWO by a drop
  none     TWO -> THREE by a drop
  split    TWO <-> THREE by a wedge                      (the lesson's value on this floor: two groups, one arrow)
  total    split, and TWO <-> ONE by the return wedge
"""
PLACES = ['FLOOR', 'ONE', 'TWO', 'THREE']
ALWAYS = [('FLOOR', 'ONE'), ('ONE', 'FLOOR'), ('ONE', 'TWO')]
EXTRA = {'none': [('TWO', 'THREE')],
         'split': [('TWO', 'THREE'), ('THREE', 'TWO')],
         'total': [('TWO', 'THREE'), ('THREE', 'TWO'), ('TWO', 'ONE')]}


def reach(edges):
    can = {p: {p} for p in PLACES}
    grew = True
    while grew:
        grew = False
        for a, b in edges:
            for p in PLACES:
                if a in can[p] and b not in can[p]:
                    can[p].add(b)
                    grew = True
    return can


def groups(edges):
    can = reach(edges)
    out = []
    for p in PLACES:
        g = sorted((q for q in PLACES if q in can[p] and p in can[q]), key=PLACES.index)
        if g not in out:
            out.append(g)
    return out


if __name__ == '__main__':
    for name in ('none', 'split', 'total'):
        edges = ALWAYS + EXTRA[name]
        can = reach(edges)
        print('%-6s groups: %s' % (name, ' | '.join(' + '.join(g) for g in groups(edges))))
        for p in PLACES:
            back = [q for q in PLACES if q != p and q in can[p] and p in can[q]]
            only_there = [q for q in PLACES if q in can[p] and p not in can[q]]
            print('         from %-5s  there and back: %-18s  there, no way back: %s' % (p, ', '.join(back) or '-', ', '.join(only_there) or '-'))
