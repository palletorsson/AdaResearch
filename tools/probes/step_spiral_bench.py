"""step_spiral_bench.py - the step spiral's rule, benched before it is built (the pass, 2026-11-15).

The rule: go round the pole, always at right angles to the line from the pole, at one rate: a circle. Computed the
plain way, a step at a time (p += dt * turn(p)), every step leaves the circle a little: the radius is multiplied by
sqrt(1 + dt*dt). Same start, same model time (one turn, 2 pi), three step sizes.

Read here:
  1. where each computation ends, against the rule's own answer (the start's radius);
  2. the difference between the ends of a pair, coarse and fine: the hall's 'difference reading' for two fields;
  3. with a wall that clips whatever passes it: the ends of the first pair agree, and both are wrong.
"""
import math

R0 = 1.6
TURN = 2 * math.pi
WALL = 2.0


def run(steps, wall=None):
    dt = TURN / steps
    x, z = R0, 0.0
    path = [(x, z)]
    for i in range(steps):
        x, z = x + dt * z, z - dt * x          # turning from east toward north (north is -z)
        r = math.hypot(x, z)
        if wall is not None and r > wall:
            x, z = x * wall / r, z * wall / r
        path.append((x, z))
    return path


print('1. one turn from %.1f m east of the pole; the rule says: %.2f m from the pole at the end' % (R0, R0))
ends = {}
for steps in (24, 48, 96):
    p = run(steps)
    r = math.hypot(*p[-1])
    turned = sum(math.atan(TURN / steps) for i in range(steps))
    ends[steps] = p[-1]
    widest = max(math.hypot(*q) for q in p)
    print('   %2d steps of %.3f: ends %.2f m from the pole (x %.2f, z %.2f), having turned %.0f degrees; a step is %.2f to %.2f m long' % (
        steps, TURN / steps, r, p[-1][0], p[-1][1], math.degrees(turned), TURN / steps * R0, TURN / steps * widest))
assert abs(math.hypot(*ends[24]) - R0 * (1 + (TURN / 24) ** 2) ** 12) < 1e-9

print('2. the difference between two ends')
for a, b in ((24, 48), (48, 96)):
    d = math.hypot(ends[a][0] - ends[b][0], ends[a][1] - ends[b][1])
    print('   %d against %d steps: %.2f m apart' % (a, b, d))

print('3. with a wall at %.1f m that clips' % WALL)
ca, cb = run(24, WALL)[-1], run(48, WALL)[-1]
d = math.hypot(ca[0] - cb[0], ca[1] - cb[1])
print('   24 steps ends %.2f m from the pole, 48 steps %.2f m: %.2f m apart' % (math.hypot(*ca), math.hypot(*cb), d))
print('   the difference fell from %.2f to %.2f m, and neither end is at %.2f m' % (math.hypot(ends[24][0] - ends[48][0], ends[24][1] - ends[48][1]), d, R0))
on_wall = sum(1 for q in run(24, WALL) if abs(math.hypot(*q) - WALL) < 1e-9)
print('   of the coarse path\'s 25 places, %d lie on the wall: a ring the wall made' % on_wall)
