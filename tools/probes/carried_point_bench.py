"""carried_point_bench.py - the floor drawing of the work `carried_point` (hall GT_Layout), tried before it was built.
The rule is the tutorial's own (doc/book/studies/graphs-through-the-hands/GT_Layout/layout.gd): every pair repels with
repulsion / d^2 (d at least 0.1), every listed connection is a spring of strength `spring` and rest length
`rest_length`, velocities are damped by exp(-damping * dt) and limited to 2 m/s, and a pinned vertex does not move.
What this bench adds is what the floor adds: metres instead of a tabletop, and bounds.

  python tools/probes/carried_point_bench.py [spring rest repulsion damping]

For each graph (the hall artifact's own lists: cube, ring, star): where the eight points settle, how long the cords
are (and the places at rest, which the work starts from so that a floor is not built on a minute of settling),
and what happens when vertex 0 is carried four metres across the floor at walking pace: how far its neighbours trail, how
near a point without a cord comes, and how long the drawing takes to settle after it is let go.
"""
import math
import sys

HALF_X, HALF_Z, INSET = 6.0, 5.4, 0.4
SPRING, REST, REPULSION, DAMPING = 3.0, 2.2, 5.0, 3.0
N = 8


def connections(kind):
    if kind == 'ring':
        return [(i, (i + 1) % N) for i in range(N)]
    if kind == 'star':
        return [(0, i) for i in range(1, N)]
    return [(0, 1), (1, 2), (2, 3), (3, 0), (0, 4), (1, 5), (2, 6), (3, 7), (4, 5), (5, 6), (6, 7), (7, 4)]


def start():
    """On a ring, each point a little off it (a ring exactly kept is a balance the drawing later slides out of)."""
    out = []
    for i in range(N):
        r = 3.0 + 0.6 * math.sin(i * 2.3 + 1.0)
        a = i * math.tau / N + 0.2 + 0.25 * math.sin(i * 1.7 + 0.4)
        out.append([r * math.cos(a), r * math.sin(a)])
    return out


def step(pos, vel, edges, dt, pinned=-1):
    force = [[0.0, 0.0] for _ in pos]
    for a in range(N):
        for b in range(a + 1, N):
            dx, dz = pos[b][0] - pos[a][0], pos[b][1] - pos[a][1]
            length = math.hypot(dx, dz)
            d = max(length, 0.1)
            if length > 0:
                px, pz = dx / length * REPULSION / (d * d), dz / length * REPULSION / (d * d)
                force[a][0] -= px; force[a][1] -= pz
                force[b][0] += px; force[b][1] += pz
    for a, b in edges:
        dx, dz = pos[b][0] - pos[a][0], pos[b][1] - pos[a][1]
        length = math.hypot(dx, dz)
        if length > 0:
            pull = SPRING * (length - REST)
            force[a][0] += dx / length * pull; force[a][1] += dz / length * pull
            force[b][0] -= dx / length * pull; force[b][1] -= dz / length * pull
    for v in range(N):
        if v == pinned:
            vel[v] = [0.0, 0.0]
            continue
        vel[v][0] += force[v][0] * dt
        vel[v][1] += force[v][1] * dt
        k = math.exp(-DAMPING * dt)
        vel[v][0] *= k; vel[v][1] *= k
        speed = math.hypot(*vel[v])
        if speed > 2.0:
            vel[v][0] *= 2.0 / speed; vel[v][1] *= 2.0 / speed
        pos[v][0] += vel[v][0] * dt
        pos[v][1] += vel[v][1] * dt
    for v in range(N):          # the floor's bounds
        for axis, half in ((0, HALF_X - INSET), (1, HALF_Z - INSET)):
            if abs(pos[v][axis]) > half:
                pos[v][axis] = math.copysign(half, pos[v][axis])
                vel[v][axis] = 0.0


def settle(pos, vel, edges, seconds, pinned=-1):
    quiet = None
    for i in range(int(seconds * 60)):
        step(pos, vel, edges, 1 / 60, pinned)
        if max(math.hypot(*v) for v in vel) < 0.05 and i > 30:
            if quiet is None:
                quiet = i / 60
        else:
            quiet = None          # it moved again: not quiet yet
    return quiet


if __name__ == '__main__':
    if len(sys.argv) == 5:
        SPRING, REST, REPULSION, DAMPING = [float(a) for a in sys.argv[1:]]
    print('spring %.1f, rest %.1f m, repulsion %.1f, damping %.1f; bounds %.1f x %.1f m' % (SPRING, REST, REPULSION, DAMPING, HALF_X * 2, HALF_Z * 2))
    for kind in ('cube', 'ring', 'star'):
        edges = connections(kind)
        pos, vel = start(), [[0.0, 0.0] for _ in range(N)]
        quiet = settle(pos, vel, edges, 60)
        lengths = [math.hypot(pos[a][0] - pos[b][0], pos[a][1] - pos[b][1]) for a, b in edges]
        apart = min(math.hypot(pos[a][0] - pos[b][0], pos[a][1] - pos[b][1]) for a in range(N) for b in range(a + 1, N))
        wide = max(p[0] for p in pos) - min(p[0] for p in pos)
        deep = max(p[1] for p in pos) - min(p[1] for p in pos)
        at_wall = sum(1 for p in pos if abs(p[0]) > HALF_X - INSET - 0.01 or abs(p[1]) > HALF_Z - INSET - 0.01)
        print('%-5s %2d cords: quiet after %s s; cords %.2f-%.2f m; nearest two points %.2f m; the drawing %.1f x %.1f m; at the bounds: %d'
              % (kind, len(edges), '%.1f' % quiet if quiet else '>60', min(lengths), max(lengths), apart, wide, deep, at_wall))
        print('      at rest: ' + ', '.join('Vector2(%.2f, %.2f)' % (p[0], p[1]) for p in pos))
        mine = [b if a == 0 else a for a, b in edges if 0 in (a, b)]
        strangers = [v for v in range(1, N) if v not in mine]
        before = [list(p) for p in pos]
        way = -1.0 if pos[0][0] > 0 else 1.0          # across the floor, away from the nearer bound
        nearest_stranger, longest = 99.0, 0.0
        for i in range(int(4.0 / 1.2 * 60)):
            pos[0][0] += way * 1.2 / 60
            step(pos, vel, edges, 1 / 60, 0)
            for v in strangers:
                nearest_stranger = min(nearest_stranger, math.hypot(pos[v][0] - pos[0][0], pos[v][1] - pos[0][1]))
            for v in mine:
                longest = max(longest, math.hypot(pos[v][0] - pos[0][0], pos[v][1] - pos[0][1]))
        moved = sum(1 for v in range(1, N) if math.hypot(pos[v][0] - before[v][0], pos[v][1] - before[v][1]) > 0.5)
        carried = abs(pos[0][0] - before[0][0])
        quiet = settle(pos, vel, edges, 20)
        print('      carried %.1f m across the floor at 1.2 m/s: its %d trail at most %.2f m behind; a point without a cord comes no nearer than %s; %d of 7 others moved over half a metre; let go, quiet after %s s'
              % (carried, len(mine), longest, '%.2f m' % nearest_stranger if strangers else '- (none)', moved, '%.1f' % quiet if quiet else '>20'))
