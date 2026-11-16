"""two_arrivals_bench.py - the figures of TWO ARRIVALS before it is built (floor PostCrisis_Synthesis; the pass,
2026-11-16).

A walk from START (-3, 0) to END (3, 0). The work keeps the last two walks: the earlier and the latest. A record of
the DESTINATION says of each only that it arrived. A record of the PATH says how long it was, how long it took, the
longest pause (speed under 0.2 m/s) and how far it went from the straight line.

The two example walks the work is found with:
  earlier: straight, at 1.5 m/s;
  latest: to (0, -2) at 1.5 m/s, three seconds standing there, on to END at 1.0 m/s.
The same arithmetic is in commons/artifacts/two_arrivals/two_arrivals.gd; the walk probe compares."""
import math

DT = 1.0 / 60.0
START, END = (-3.0, 0.0), (3.0, 0.0)


def leg(a, b, speed):
    n = int(round(math.dist(a, b) / speed / DT))
    return [(a[0] + (b[0] - a[0]) * i / n, a[1] + (b[1] - a[1]) * i / n) for i in range(1, n + 1)]


def earlier():
    return [START] + leg(START, END, 1.5)


def latest():
    mid = (0.0, -2.0)
    return [START] + leg(START, mid, 1.5) + [mid] * 180 + leg(mid, END, 1.0)


def measure(pts):
    length, pause, longest, off = 0.0, 0.0, 0.0, 0.0
    for i in range(1, len(pts)):
        step = math.dist(pts[i], pts[i - 1])
        length += step
        if step / DT < 0.2:
            pause += DT
            longest = max(longest, pause)
        else:
            pause = 0.0
        off = max(off, abs(pts[i][1]))
    return {'length': length, 'seconds': (len(pts) - 1) * DT, 'pause': longest, 'off': off, 'end': math.dist(pts[-1], END)}


if __name__ == '__main__':
    for name, walk in (('earlier', earlier()), ('latest', latest())):
        m = measure(walk)
        print('%s: %d samples; %.2f m, %.1f s, longest pause %.1f s, %.2f m off the line; ends %.2f m from END' % (name, len(walk), m['length'], m['seconds'], m['pause'], m['off'], m['end']))
