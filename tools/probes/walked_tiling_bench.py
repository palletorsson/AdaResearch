"""walked_tiling_bench.py - the rule of walked_tiling, benched before it was built (the pass, 2026-11-15).

A walk on a floor of curvature k (-1: five squares at every corner, 0: four, +1: three) is a product of motions
z -> (a z + b) / (-k conj(b) z + conj(a)). Where does a square walk with left turns end, seen from where it began?

    python tools/probes/walked_tiling_bench.py [side in metres]

Prints, per floor: how far home is after the walk and by how much its arrow has turned. The tower probe
(tools/probes/walked_tiling_walk.gd) compares what the artifact reports after the tower's walker has gone round the
painted square with these numbers. Python complex numbers; nothing shared with the artifact's code."""
import cmath, math, sys


def step(vec, k):
    d = abs(vec)
    if d == 0: return (1 + 0j, 0j)
    u = vec / d
    if k < 0: return (complex(math.cosh(d / 2)), math.sinh(d / 2) * u)
    if k > 0: return (complex(math.cos(d / 2)), math.sin(d / 2) * u)
    return (1 + 0j, (d / 2) * u)


def compose(m1, m2, k):
    """m1 . m2: m2 is done first."""
    a1, b1 = m1
    a2, b2 = m2
    return (a1 * a2 - k * b1 * b2.conjugate(), a1 * b2 + b1 * a2.conjugate())


def home(m, k):
    a, b = m
    g0 = abs(b / a.conjugate())
    d = 2 * math.atanh(g0) if k < 0 else (2 * math.atan(g0) if k > 0 else 2 * g0)
    return d, math.degrees(2 * cmath.phase(a))


def square(side, k):
    g = (1 + 0j, 0j)
    for leg in (side + 0j, -side * 1j, -side + 0j, side * 1j):      # east, north (-z), west, south, as x + i z
        g = compose(g, step(leg, k), k)
    return home(g, k)


if __name__ == '__main__':
    side = float(sys.argv[1]) if len(sys.argv) > 1 else 1.4
    for k, name in ((-1, 'five'), (0, 'four'), (1, 'three')):
        d, turned = square(side, k)
        print('%-5s at a corner: a square of %.2f m ends %.3f m from home, turned %.1f degrees' % (name, side, d, turned))
    print('floor within 3 m: five %.1f m2, four %.1f m2, three %.1f m2 (all of it: %.1f)' % (
        2 * math.pi * (math.cosh(3) - 1), math.pi * 9, 2 * math.pi * (1 - math.cos(3)), 4 * math.pi))
