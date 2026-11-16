"""four_stations_bench.py - the figures of FOUR STATIONS, ONE WALK before it is built (floor
SpeculativeComputation_Situated_Computation; the pass, 2026-11-16).

A field six metres square with a line up its middle. Four stations at its corners. Each sees only what comes within
3.4 m of it, and each has its own definition of DANGEROUS:
  NW  more than 0.5 m off the line          (dangerous to the order of the line)
  NE  faster than 2.0 m/s                   (dangerous by speed)
  SW  within 1.5 m of the station           (dangerous to the station)
  SE  in its sight for longer than 3 s      (dangerous by staying)
A station that saw the subject for less than a quarter of a second gives no verdict.

ONE DEFINITION gives all four the NE definition (speed). ONE RECORD gives all four the whole walk.

The example walk the work is found with: 1.8 m up the line at 2.4 m/s, then 3.4 m at 0.6 m/s northward while
swinging 1.4 m to the west and back. The same arithmetic is in
commons/artifacts/four_stations/four_stations.gd; the walk probe compares."""
import math

DT = 1.0 / 60.0
REACH = 3.4
CORNERS = {'NW': (-3.0, -3.0), 'NE': (3.0, -3.0), 'SW': (-3.0, 3.0), 'SE': (3.0, 3.0)}
ORDER = ['NW', 'NE', 'SW', 'SE']


def example_walk():
    pts = []
    for i in range(45):
        pts.append((0.0, 2.6 - 2.4 * DT * i))
    for i in range(341):
        z = 0.8 - 0.6 * DT * i
        pts.append((-1.4 * math.sin(math.pi * (0.8 - z) / 3.4), z))
    return pts


def observe(pts, station, whole):
    cx, cz = CORNERS[station]
    seen, top, off, near = 0, 0.0, 0.0, 1e9
    for i, (x, z) in enumerate(pts):
        if not whole and math.hypot(x - cx, z - cz) > REACH: continue
        seen += 1
        if i > 0: top = max(top, math.hypot(x - pts[i - 1][0], z - pts[i - 1][1]) / DT)
        off = max(off, abs(x))
        near = min(near, math.hypot(x - cx, z - cz))
    return {'seen_s': seen * DT, 'share': seen / max(len(pts), 1), 'top': top, 'off': off, 'near': near}


def verdict(station, o, one_definition):
    if o['seen_s'] < 0.25: return 'NOT SEEN'
    rule = 'NE' if one_definition else station
    hit = {'NW': o['off'] > 0.5, 'NE': o['top'] > 2.0, 'SW': o['near'] < 1.5, 'SE': o['seen_s'] > 3.0}[rule]
    return 'DANGEROUS' if hit else 'NOT DANGEROUS'


def table(pts, one_definition, one_record):
    return [(s, observe(pts, s, one_record), verdict(s, observe(pts, s, one_record), one_definition)) for s in ORDER]


def cause(pts):
    """Why the four differ as found: from what each saw, from what each means, both, or not at all."""
    found = len({v for _, _, v in table(pts, False, False)}) > 1
    by_evidence = len({v for _, _, v in table(pts, True, False)}) > 1          # one definition: what is left is evidence
    by_definition = len({v for _, _, v in table(pts, False, True)}) > 1        # one record: what is left is definition
    return found, by_evidence, by_definition


if __name__ == '__main__':
    pts = example_walk()
    print('example walk: %d samples, %.2f s' % (len(pts), len(pts) * DT))
    for one_definition, one_record in ((False, False), (True, False), (False, True), (True, True)):
        print('one definition %s, one record %s:' % (one_definition, one_record))
        for s, o, v in table(pts, one_definition, one_record):
            print('   %s saw %.2f s (%2.0f %%), fastest %.2f m/s, %.2f m off the line, nearest %.2f m: %s' % (s, o['seen_s'], 100 * o['share'], o['top'], o['off'], o['near'], v))
    print('differ as found %s; with one definition %s; with one record %s' % cause(pts))
    unseen = sum(1 for x, z in pts if all(math.hypot(x - cx, z - cz) > REACH for cx, cz in CORNERS.values()))
    print('samples no station saw: %d (%.2f s)' % (unseen, unseen * DT))
    straight = [(0.0, 2.6 - 1.5 * DT * i) for i in range(int(5.2 / (1.5 * DT)) + 1)]
    print('a straight walk at 1.5 m/s: ' + ', '.join('%s %s (%.2f s)' % (s, v, o['seen_s']) for s, o, v in table(straight, False, False)))
