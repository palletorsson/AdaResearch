"""seat_you_take_bench.py - the figures of THE SEAT YOU TAKE before it is built (floor
CriticalAlgorithms_Applied_Ethics; the pass, 2026-11-16).

Two plans at full size. A long table: a head seat at the west end, six seats along its sides facing across. A round
table: six seats on a ring facing the centre. A seat FACES another when the other lies within a turn of the neck
(30, 60 or 90 degrees either side of where the seat points). ANGLE THE CHAIRS turns the six side seats 40 degrees
toward the head.

Counted: for each seat, how many others it faces and how many face it; for each plan, the pairs who face each other.
The same arithmetic is in commons/artifacts/seat_you_take/seat_you_take.gd; the walk probe compares."""
import math

TABLE = (-2.5, 0.0)
RING = (2.6, 0.0)
RING_R = 1.1
SIDE_Z = 0.85
ANGLED = 40.0


def seats(angled=False):
    out = [{'plan': 'table', 'name': 'the head', 'at': (TABLE[0] - 1.75, TABLE[1]), 'facing': 0.0}]            # facing: degrees from +x toward +z
    n = 0
    for side in (-1.0, 1.0):                                    # north side (z < 0), then south
        for x in (-0.8, 0.0, 0.8):
            n += 1
            across = 90.0 if side < 0 else -90.0                # toward the table
            toward_head = (180.0 - across + 180.0) % 360.0 - 180.0
            turn = math.copysign(min(ANGLED, abs(toward_head)), toward_head) if angled else 0.0
            out.append({'plan': 'table', 'name': 'side %d' % n, 'at': (TABLE[0] + x, TABLE[1] + side * SIDE_Z), 'facing': across + turn})
    for k in range(6):
        a = math.radians(30.0 + 60.0 * k)
        at = (RING[0] + RING_R * math.cos(a), RING[1] + RING_R * math.sin(a))
        out.append({'plan': 'ring', 'name': 'ring %d' % (k + 1), 'at': at, 'facing': math.degrees(math.atan2(RING[1] - at[1], RING[0] - at[0]))})
    return out


def turn_to(a, b):
    want = math.degrees(math.atan2(b['at'][1] - a['at'][1], b['at'][0] - a['at'][0]))
    return abs((want - a['facing'] + 180.0) % 360.0 - 180.0)


def faces(a, b, neck):
    return a is not b and a['plan'] == b['plan'] and turn_to(a, b) <= neck + 0.5


def counts(all_seats, neck):
    rows = []
    for a in all_seats:
        others = [b for b in all_seats if b is not a and b['plan'] == a['plan']]
        rows.append((a['name'], sum(faces(a, b, neck) for b in others), sum(faces(b, a, neck) for b in others), len(others)))
    return rows


def mutual(all_seats, plan, neck):
    s = [a for a in all_seats if a['plan'] == plan]
    pairs = [(a, b) for i, a in enumerate(s) for b in s[i + 1:]]
    return sum(faces(a, b, neck) and faces(b, a, neck) for a, b in pairs), len(pairs)


if __name__ == '__main__':
    for angled in (False, True):
        s = seats(angled)
        for neck in (30, 60, 90):
            t, r = mutual(s, 'table', neck), mutual(s, 'ring', neck)
            print('%s neck %2d: pairs who face each other: table %2d of %d, ring %2d of %d' % ('angled  ' if angled else 'straight', neck, t[0], t[1], r[0], r[1]))
            print('    ' + '; '.join('%s faces %d, faced by %d' % (n, o, i) for n, o, i, _ in counts(s, neck) if n in ('the head', 'side 1', 'side 2', 'side 3', 'ring 1')))
    s = seats()
    head = s[0]
    print('the head must turn: ' + ', '.join('%s %.1f' % (b['name'], turn_to(head, b)) for b in s[1:7]))
    print('to face the head: ' + ', '.join('%s %.1f' % (b['name'], turn_to(b, head)) for b in s[1:7]))
    print('side 2 must turn: ' + ', '.join('%s %.1f' % (b['name'], turn_to(s[2], b)) for b in s[:7] if b is not s[2]))
    print('ring 1 must turn: ' + ', '.join('%s %.1f' % (b['name'], turn_to(s[7], b)) for b in s[8:]))
    print('farthest from the head: %.2f m; across the ring: %.2f m' % (max(math.dist(head['at'], b['at']) for b in s[1:7]), 2 * RING_R))
