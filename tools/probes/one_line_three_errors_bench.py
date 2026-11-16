"""one_line_three_errors_bench.py - the rule of ONE LINE, THREE ERRORS (floor ML_Gradient_Landscape), before it is built.

The work: a floor is the plane of candidate lines (east-west: slope, north-south: intercept). Where a body stands
is one line, drawn as a plank among five observation posts. At the feet lie three arrows, one for each rule of
error, each pointing one step downhill for that rule. The observations are the tutorial's own
(doc/book/studies/ml-gradient/line_fit.gd): five points on y = 0.5 x + 0.2, and its outlier, the fifth lifted to 4.7.
The three rules: squared, Huber (line_fit.gd's `robust`), and the hall exhibit's wavy rule, sin(3e) + 0.5 e^2
(loss_function_comparator.gd). All three as a mean over the observations, on one scale.

What the bench asks:
  1. where is each rule's lowest place, without and with the outlier, and how far apart on the floor?
  2. at the same place, do the three arrows point the same way?  (the hall: 'Can the same observations lead a
     learner downhill in different directions?')
  3. a short step and a long step from the tutorial's START: does the long one make the squared error worse while
     the same long step makes Huber's better?  ('Choosing a score and choosing how to follow it are separate.')
  4. the wavy rule: from a grid of starts, how many different resting places does a short-step descent find?

    python tools/probes/one_line_three_errors_bench.py
"""
import math

DATA = [(-1.0, -0.3), (-0.5, -0.05), (0.0, 0.2), (0.5, 0.45), (1.0, 0.7)]
OUTLIER = 4.7
START = (-1.0, 1.0)
SLOPE = (-1.3, 2.9)                      # the floor's window
INTERCEPT = (-0.9, 2.3)
METRES = 1.5                             # floor metres per unit of slope or intercept
SHORT, LONG = 0.5, 1.2
RULES = ('squared', 'huber', 'wavy')


def data(outlier):
    return DATA[:4] + [(1.0, OUTLIER)] if outlier else DATA


def one(rule, e):
    if rule == 'squared': return e * e
    if rule == 'huber': return 0.5 * e * e if abs(e) <= 1.0 else abs(e) - 0.5
    return math.sin(3.0 * e) + 0.5 * e * e


def loss(rule, q, outlier):
    pts = data(outlier)
    return sum(one(rule, q[0] * x + q[1] - y) for x, y in pts) / len(pts)


def gradient(rule, q, outlier, h=0.001):
    return ((loss(rule, (q[0] + h, q[1]), outlier) - loss(rule, (q[0] - h, q[1]), outlier)) / (2 * h),
            (loss(rule, (q[0], q[1] + h), outlier) - loss(rule, (q[0], q[1] - h), outlier)) / (2 * h))


def inside(q):
    return SLOPE[0] <= q[0] <= SLOPE[1] and INTERCEPT[0] <= q[1] <= INTERCEPT[1]


def descend(rule, q, outlier, rate=0.05, steps=40000):
    for _ in range(steps):
        g = gradient(rule, q, outlier)
        if math.hypot(*g) < 1e-5: break
        nxt = (q[0] - rate * g[0], q[1] - rate * g[1])
        if not inside(nxt): break
        q = nxt
    return q


def angle(u, v):
    a, b = math.hypot(*u), math.hypot(*v)
    if a < 1e-9 or b < 1e-9: return None
    return math.degrees(math.acos(max(-1.0, min(1.0, (u[0] * v[0] + u[1] * v[1]) / (a * b)))))


grid = [(SLOPE[0] + (SLOPE[1] - SLOPE[0]) * i / 16.0, INTERCEPT[0] + (INTERCEPT[1] - INTERCEPT[0]) * j / 12.0) for i in range(17) for j in range(13)]
ok = True
print('1. the lowest place of each rule (slope, intercept), found by short steps from the tutorial\'s START:')
low = {}
for outlier in (False, True):
    for rule in ('squared', 'huber'):
        q = descend(rule, START, outlier, rate=0.05, steps=40000)
        low[(rule, outlier)] = q
        print('   %-8s outlier %-5s  (%.3f, %.3f)   error there %.4f' % (rule, outlier, q[0], q[1], loss(rule, q, outlier)))
apart_off = math.dist(low[('squared', False)], low[('huber', False)]) * METRES
apart_on = math.dist(low[('squared', True)], low[('huber', True)]) * METRES
print('   squared and Huber rest %.2f m apart on the floor without the outlier, %.2f m apart with it' % (apart_off, apart_on))
ok = ok and apart_off < 0.05 and apart_on > 1.0
moved = {rule: math.dist(low[(rule, False)], low[(rule, True)]) * METRES for rule in ('squared', 'huber')}
print('   the outlier moves the squared rule\'s lowest place %.2f m and Huber\'s %.2f m' % (moved['squared'], moved['huber']))
ok = ok and moved['squared'] > moved['huber'] + 0.5

print('2. the angle between two rules\' arrows at the same place, over %d places of the floor:' % len(grid))
for outlier in (False, True):
    for pair in (('squared', 'huber'), ('squared', 'wavy')):
        angles = [a for a in (angle(gradient(pair[0], q, outlier), gradient(pair[1], q, outlier)) for q in grid) if a is not None]
        print('   %s against %s, outlier %-5s  mean %5.1f, largest %5.1f degrees; more than 20 degrees apart at %d places' % (pair[0], pair[1], outlier, sum(angles) / len(angles), max(angles), sum(1 for a in angles if a > 20.0)))
        if pair == ('squared', 'wavy'): ok = ok and max(angles) > 90.0
here = (0.5, 0.2)
print('   at the clean line (0.5, 0.2) with the outlier: squared arrow %.2f long, Huber arrow %.2f long, %.1f degrees apart' % (
    math.hypot(*gradient('squared', here, True)), math.hypot(*gradient('huber', here, True)), angle(gradient('squared', here, True), gradient('huber', here, True))))

print('3. one step from START %s:' % (START,))
for rate in (SHORT, LONG):
    for rule in ('squared', 'huber'):
        g = gradient(rule, START, False)
        to = (START[0] - rate * g[0], START[1] - rate * g[1])
        before, after = loss(rule, START, False), loss(rule, to, False)
        print('   step %.1f, %-8s  %.3f -> %.3f  (%s)   lands at (%.2f, %.2f)%s   arrow %.2f m on the floor' % (rate, rule, before, after, 'better' if after < before else 'WORSE', to[0], to[1], '' if inside(to) else '  outside the floor', rate * math.hypot(*g) * METRES))
        if rate == SHORT: ok = ok and after < before
far = (2.6, 2.0)
g = gradient('squared', far, False)
to = (far[0] - LONG * g[0], far[1] - LONG * g[1])
print('   from (%.1f, %.1f) by the long step, squared: %.3f -> %.3f, lands at (%.2f, %.2f)' % (far[0], far[1], loss('squared', far, False), loss('squared', to, False), to[0], to[1]))
print('   squared: the widest curvature is 2 (the intercept), so any step longer than 1.0 overshoots past where it began')
long_worse = [q for q in grid if loss('squared', (q[0] - LONG * gradient('squared', q, False)[0], q[1] - LONG * gradient('squared', q, False)[1]), False) > loss('squared', q, False)]
long_better_h = [q for q in grid if loss('huber', (q[0] - LONG * gradient('huber', q, False)[0], q[1] - LONG * gradient('huber', q, False)[1]), False) < loss('huber', q, False)]
print('   long step: squared gets WORSE at %d of %d places; Huber gets better at %d of %d' % (len(long_worse), len(grid), len(long_better_h), len(grid)))
ok = ok and len(long_worse) > 0 and len(long_better_h) > len(grid) // 2

print('4. the wavy rule, short steps from each of %d starts:' % len(grid))
rests = []
for q in grid:
    r = descend('wavy', q, False)
    if not any(math.dist(r, s) < 0.08 for s in rests): rests.append(r)
print('   %d different resting places: %s' % (len(rests), ', '.join('(%.2f, %.2f)' % r for r in sorted(rests)[:8])))
ok = ok and len(rests) >= 2
print('PASSED' if ok else 'FAILED')
