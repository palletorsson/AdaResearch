"""room_to_tell_apart_bench.py - the figures of ROOM TO TELL APART before it is built (floor
CriticalAlgorithms_Algorithmic_Bias_Visualization; the pass, 2026-11-16).

Twenty-four posts in two fields of twelve (3 columns x 4 rows, 0.95 m apart, each a little off its place). One
group (warm) is pressed toward a point, to 0.22 of its spread; the other (grey) spreads to 1.4 of its own. A post
has ROOM ROUND IT when the nearest other post stands a body's width away (0.5 m clear: 0.64 m centre to centre).
A post is HIDDEN from a place when its middle lies behind a nearer post.

Grouping A: the west field is warm. Grouping B: the two south rows of both fields are warm.
The same arithmetic is in commons/artifacts/room_to_tell_apart/room_to_tell_apart.gd; the walk probe compares."""
import math

SPACING = 0.95
POST = 0.14
ROOM = 0.5 + POST
TIGHT, LOOSE = 0.22, 1.4
FIELD_X, FIELD_Z = 2.3, -0.3
CLUMP = {'A': (-0.5, -0.3), 'B': (0.0, 0.65)}


def home(i):
    field, j = divmod(i, 12)
    col, row = j % 3, j // 3
    x = (-FIELD_X if field == 0 else FIELD_X) + (col - 1) * SPACING + 0.12 * math.sin(2.4 * i + 0.7)
    z = FIELD_Z + (row - 1.5) * SPACING + 0.12 * math.cos(3.7 * i + 1.9)
    return (x, z)


def warm(i, grouping):
    return i < 12 if grouping == 'A' else (i % 12) // 3 >= 2


def centre(ids):
    return (sum(home(i)[0] for i in ids) / len(ids), sum(home(i)[1] for i in ids) / len(ids))


def places(grouping, c, kept=()):
    w = [i for i in range(24) if warm(i, grouping)]
    g = [i for i in range(24) if not warm(i, grouping)]
    cw, cg = centre(w), centre(g)
    k = 1.0 + (TIGHT - 1.0) * c
    s = 1.0 + (LOOSE - 1.0) * c
    ax, az = cw[0] + (CLUMP[grouping][0] - cw[0]) * c, cw[1] + (CLUMP[grouping][1] - cw[1]) * c
    out = {}
    for i in range(24):
        hx, hz = home(i)
        if i in kept: out[i] = (hx, hz)
        elif i in w: out[i] = (ax + (hx - cw[0]) * k, az + (hz - cw[1]) * k)
        else: out[i] = (cg[0] + (hx - cg[0]) * s, cg[1] + (hz - cg[1]) * s)
    return out, w, g


def nearest(p, i):
    return min(math.dist(p[i], p[j]) for j in p if j != i)


def room(p, ids):
    return sum(1 for i in ids if nearest(p, i) >= ROOM)


def hidden(p, ids, eye):
    n = 0
    for i in ids:
        di = math.dist(p[i], eye)
        ai = math.atan2(p[i][0] - eye[0], p[i][1] - eye[1])
        for j in p:
            if j == i: continue
            dj = math.dist(p[j], eye)
            if dj >= di: continue
            d = abs((ai - math.atan2(p[j][0] - eye[0], p[j][1] - eye[1]) + math.pi) % (2 * math.pi) - math.pi)
            if d < math.atan(POST * 0.5 / dj):
                n += 1
                break
    return n


if __name__ == '__main__':
    for grouping in 'AB':
        for c in (0.0, 0.25, 0.5, 0.75, 1.0):
            p, w, g = places(grouping, c)
            xs = [p[i][0] for i in p]; zs = [p[i][1] for i in p]
            print('grouping %s pressed %.2f: room warm %2d grey %2d | nearest warm %.2f m | extent x %.2f..%.2f z %.2f..%.2f'
                  % (grouping, c, room(p, w), room(p, g), min(nearest(p, i) for i in w), min(xs), max(xs), min(zs), max(zs)))
    p, w, g = places('A', 1.0)
    cl = [p[i] for i in w]
    print('A pressed: the twelve stand within x %.2f..%.2f z %.2f..%.2f' % (min(c[0] for c in cl), max(c[0] for c in cl), min(c[1] for c in cl), max(c[1] for c in cl)))
    for name, eye in (('south-west', (-3.0, 1.2)), ('north of the twelve', (-0.5, -2.8)), ('east end of the rail', (2.5, 2.4)), ('west end of the rail', (-2.5, 2.4)), ('middle of the rail', (0.0, 2.4))):
        print('A pressed, from %s %s: hidden warm %d grey %d' % (name, eye, hidden(p, w, eye), hidden(p, g, eye)))
    p0, w0, g0 = places('A', 0.0)
    for name, eye in (('middle of the rail', (0.0, 2.4)), ('west end of the rail', (-2.5, 2.4)), ('south-west', (-3.0, 1.2))):
        print('A open, from %s: hidden warm %d grey %d' % (name, hidden(p0, w0, eye), hidden(p0, g0, eye)))
    # the pair a body can stand between in the middle of the west field: posts 5 and 8 (index 4 and 7)
    mid = ((home(4)[0] + home(7)[0]) / 2, (home(4)[1] + home(7)[1]) / 2)
    print('posts 5 and 8: %.2f m apart, their middle at (%.2f, %.2f)' % (math.dist(home(4), home(7)), mid[0], mid[1]))
    pk, w, g = places('A', 1.0, kept=(4, 7))
    print('A pressed with 5 and 8 kept: room warm %d (kept: nearest %.2f and %.2f m), grey %d' % (room(pk, w), nearest(pk, 4), nearest(pk, 7), room(pk, g)))
    # nothing may stand in a column: the row is at [0, -4.0], columns at (+-5, -7) are local (+-5, -3.0), 0.9 m square
    for grouping in 'AB':
        p, w, g = places(grouping, 1.0)
        bad = [i + 1 for i in p if abs(abs(p[i][0]) - 5.0) < 0.45 + POST / 2 and abs(p[i][1] + 3.0) < 0.45 + POST / 2]
        print('grouping %s pressed: posts in a column: %s; nearest to the rail lane (z 1.9): %.2f m' % (grouping, bad, 1.9 - max(p[i][1] for i in p)))
