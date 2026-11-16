"""three_wedges_bench.py - the rule of THREE CORNERS ON ONE STRAIGHT LINE (floor Euclid_Parallel), before it is built.

The work: A and B stand on the floor, the visitor is C, and a line is drawn through C. Three wedges lie along that
line at C: the angle between the line and CA, the triangle's own angle at C, the angle between CB and the line.

What the bench asks:
  1. do a triangle's three corners add to a straight angle at every place C can stand?  (the measurement)
  2. with the line through C PARALLEL to AB, are the two outer wedges the corners at A and B?  (the construction)
  3. with the line TILTED, do the three wedges still fill the line?  And are the outer two still the corners?
     If any line is filled, 'they fill the line' is no evidence; the parallel's work is the EQUALITY.
  4. the instrument's edge: how thin is the thinnest triangle in the field, against a 10 degree tolerance?
  5. the next floor down: the same three side lengths on a sphere - do the corners still add to 180?

    python tools/probes/three_wedges_bench.py
"""
import math, random

A = (-2.3, 1.5)
B = (2.3, 1.5)
FIELD = (-3.0, -2.5, 3.0, 1.8)          # x0, z0, x1, z1: where a body is read as C
TILT = 8.0
TOLERANCE = 10.0


def ang(u, v):
    d = math.atan2(u[0] * v[1] - u[1] * v[0], u[0] * v[0] + u[1] * v[1])
    return abs(math.degrees(d))


def sub(p, q): return (p[0] - q[0], p[1] - q[1])


def corners(c):
    return ang(sub(B, A), sub(c, A)), ang(sub(A, B), sub(c, B)), ang(sub(A, c), sub(B, c))


def along(c, tilt):
    t = math.radians(tilt)
    d = (math.cos(t), math.sin(t))
    return ang((-d[0], -d[1]), sub(A, c)), ang(sub(A, c), sub(B, c)), ang(d, sub(B, c))


def sphere_sum(a, b, c, radius):
    """Angle sum of a spherical triangle with side lengths a, b, c (metres) on a sphere of `radius`."""
    a, b, c = a / radius, b / radius, c / radius
    def corner(opp, s1, s2):
        return math.degrees(math.acos((math.cos(opp) - math.cos(s1) * math.cos(s2)) / (math.sin(s1) * math.sin(s2))))
    return corner(a, b, c) + corner(b, a, c) + corner(c, a, b)


random.seed(7)
places = []
while len(places) < 4000:
    c = (random.uniform(FIELD[0], FIELD[2]), random.uniform(FIELD[1], FIELD[3]))
    if c[1] < A[1] - 0.02: places.append(c)          # north of AB: the side the field lies on
kept = [c for c in places if min(corners(c)) >= TOLERANCE]
worst_sum = max(abs(sum(corners(c)) - 180.0) for c in kept)
worst_copy = max(max(abs(along(c, 0.0)[0] - corners(c)[0]), abs(along(c, 0.0)[2] - corners(c)[1])) for c in kept)
worst_fill = max(abs(sum(along(c, TILT)) - 180.0) for c in kept)
left_off = [along(c, TILT)[0] - corners(c)[0] for c in kept]
right_off = [along(c, TILT)[2] - corners(c)[1] for c in kept]
thin = min(min(corners(c)) for c in places)
print('places tried: %d; read (no corner under %g degrees): %d; withheld: %d' % (len(places), TOLERANCE, len(kept), len(places) - len(kept)))
print('1. corners add to 180 within %.2e degrees at every place read' % worst_sum)
print('2. parallel: outer wedges equal the corners at A and B within %.2e degrees' % worst_copy)
print('3. tilted %g degrees: the three wedges still add to 180 within %.2e degrees' % (TILT, worst_fill))
print('   but the outer wedges are off the corners by %+.3f .. %+.3f (toward A) and %+.3f .. %+.3f (toward B)' % (min(left_off), max(left_off), min(right_off), max(right_off)))
print('4. thinnest corner anywhere in the field: %.2f degrees; smallest corner among places read: %.2f' % (thin, min(min(corners(c)) for c in kept)))
c = (0.7, -1.3)
sides = (math.dist(B, c), math.dist(A, c), math.dist(A, B))
print('5. the example triangle (C at %s): corners %.1f, %.1f, %.1f; sides %.2f, %.2f, %.2f m' % ((c,) + corners(c) + sides))
for radius in (40.0, 8.0, 3.0):
    print('   the same three sides on a sphere of radius %g m: corners add to %.2f degrees' % (radius, sphere_sum(*sides, radius)))
ok = worst_sum < 1e-9 and worst_copy < 1e-9 and worst_fill < 1e-9 and abs(min(left_off) - TILT) < 1e-9 and abs(max(right_off) + TILT) < 1e-9
print('PASSED' if ok else 'FAILED')
