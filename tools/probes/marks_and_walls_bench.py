"""marks_and_walls_bench.py - the figures of MARKS AND WALLS before it is built (floor
SpeculativeComputation_Collective_Knowledge; the pass, 2026-11-16).

A field of five by four cells, 1.2 m each. Between some cells stand walls that cannot be seen: 8 of the 31 inner
edges. On the floor lie the marks of six earlier sources, each saying 'a wall here': some FELT (a body was stopped),
some TOLD (copied or heard). Some repeat one another, three are wrong, and three walls nobody marked.

Counted: marks, sources, felt and told, and how many of the 31 edges the map is wrong about (a mark where no wall
stands, or a wall with no mark). Then: what SIGN EVERYTHING changes (the visitor adds a told mark to every marked
edge), and what a visitor's body changes (stopped at an unmarked wall: a felt mark is added; walked through a
marked edge: its marks are struck).

Edges: V c r is between cell (c, r) and (c+1, r); H c r between (c, r) and (c, r+1). Row 0 is north.
The same arithmetic is in commons/artifacts/marks_and_walls/marks_and_walls.gd; the walk probe compares."""
COLS, ROWS = 5, 4
WALLS = ['H:2:2', 'H:3:2', 'V:0:3', 'H:1:1', 'V:1:1', 'H:2:0', 'V:3:0', 'H:4:1']
MARKS = [('P1', 'H:2:2', 'felt'), ('P2', 'H:2:2', 'told'), ('P4', 'H:2:2', 'told'), ('P1', 'H:1:1', 'felt'), ('P3', 'V:1:1', 'felt'), ('P3', 'H:2:0', 'felt'), ('P5', 'H:2:0', 'told'),
         ('P2', 'V:0:3', 'felt'), ('P6', 'V:1:2', 'told'), ('P4', 'V:1:2', 'told'), ('P5', 'H:3:1', 'told')]


def edges():
    return ['V:%d:%d' % (c, r) for c in range(COLS - 1) for r in range(ROWS)] + ['H:%d:%d' % (c, r) for c in range(COLS) for r in range(ROWS - 1)]


def between(a, b):
    (c, r), (d, s) = a, b
    if r == s and abs(c - d) == 1: return 'V:%d:%d' % (min(c, d), r)
    if c == d and abs(r - s) == 1: return 'H:%d:%d' % (c, min(r, s))
    return None


def counts(marks, struck=()):
    live = [m for i, m in enumerate(marks) if i not in struck]
    marked = {m[1] for m in live}
    wrong = sorted(e for e in edges() if (e in marked) != (e in WALLS))
    return {'marks': len(marks), 'struck': len(struck), 'sources': len({m[0] for m in marks}), 'felt': sum(1 for m in marks if m[2] == 'felt'), 'told': sum(1 for m in marks if m[2] == 'told'),
            'marked_edges': len({m[1] for m in marks}), 'wrong_about': len(wrong), 'wrong': wrong}


def route(blocked, start=(2, 3), goal=(2, 0)):
    seen, queue = {start: None}, [start]
    while queue:
        at = queue.pop(0)
        if at == goal:
            path = []
            while at is not None:
                path.append(at)
                at = seen[at]
            return path[::-1]
        for d in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nxt = (at[0] + d[0], at[1] + d[1])
            if 0 <= nxt[0] < COLS and 0 <= nxt[1] < ROWS and nxt not in seen and between(at, nxt) not in blocked:
                seen[nxt] = at
                queue.append(nxt)
    return None


if __name__ == '__main__':
    print('inner edges: %d; walls: %d' % (len(edges()), len(WALLS)))
    found = counts(MARKS)
    print('as found: %(marks)d marks from %(sources)d sources, %(felt)d felt and %(told)d told, on %(marked_edges)d edges; the map is wrong about %(wrong_about)d edges: %(wrong)s' % found)
    signed = MARKS + [('VISITOR', e, 'told') for e in sorted({m[1] for m in MARKS})]
    s = counts(signed)
    print('signed: %(marks)d marks from %(sources)d sources, %(felt)d felt and %(told)d told; wrong about %(wrong_about)d' % s)
    checked = MARKS + [('VISITOR', e, 'felt') for e in WALLS if e not in {m[1] for m in MARKS}]
    struck = [i for i, m in enumerate(checked) if m[1] not in WALLS]
    c = counts(checked, struck)
    print('checked by a body: %(marks)d marks (%(struck)d struck) from %(sources)d sources, %(felt)d felt and %(told)d told; wrong about %(wrong_about)d' % c)
    print('the real way from the south middle to the north middle:', route(set(WALLS)))
    print('the way a believer of the marks takes:', route({m[1] for m in MARKS}))
    print('does the believer meet a wall nobody marked?', [between(a, b) for a, b in zip(route({m[1] for m in MARKS}), route({m[1] for m in MARKS})[1:]) if between(a, b) in WALLS])
