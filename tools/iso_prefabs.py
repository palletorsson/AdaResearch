"""iso_prefabs.py - twenty construction prefabs made as ISOSURFACES, for the boolean floor (Boolean_Verbs, 2026-11-13).

The tower's construction kit is built from primitives and their associations: cubes, wedges, planks, panels, barriers,
drums. Every piece is convex or a stack of convex parts, so nothing in it has a hole a body can walk through, a hollow
that keeps a ball, a curved deck, or a stair a body can climb. Boolean operations on distance fields make exactly those:
difference opens passages and hollows, intersection keeps what two shapes share (and what is shared by two convex shapes
is convex, so it can move), smooth union melts a crease into a slope a body can walk, and a field can be twisted,
revolved, swept or roughened before it is cut. Palle, 2026-11-13: "We have prefabs but boolean surfaces creates new
principal opportunities. Can you make 20 new prefabs using iso surfaces? ... I mean in the boolean floor."

Each form is a signed-distance expression; marching cubes (scikit-image) draws its zero set. Every vertex also carries
DATA read from the expression - where its face came from (a DIFFERENCE cut it, an INTERSECTION trimmed it, it lies in
the band where a SMOOTH UNION melted two bodies) and how open the air round it is (ambient occlusion read from the field
along the normal, the floor counted as an occluder) - as vertex colour (r cut, g trim, b band, a occlusion). The
artifact's shader turns that into a finish: paint (the hall's CUT_COLOR orange for a cut), rock (the Cave System's own
procedural texture: a cut shows fresh pale stone, a trim dressed stone, a band worn smooth), or one pale cast. The hall
says of its difference demo "we could make the new faces announce another origin" - here they do.

Palle, 2026-11-13, later: "Make the space a bit bigger and find the procedural boolean surface caves and place the object
in a boolean map, use the same texture as in the example and make them look very good ... they use sine and random etc to
carve in a space in cubes." The example is the Random Boolean Carving (algorithms/proceduralgeneration/constraint_solvers/
randomboolean/advanced_carver.gd; map ProceduralGenerationBooleanPatterns, registry boolean_patterns): a cube minus
low-poly spheres along a path - a random walk, a sine spiral, random branches, a sine-driven "Perlin" path, grid tunnels.
Its demo (all_patterns_demo.tscn) carves six 10 m cubes; the forms `carved_*` here are those six at 0.28 of their size
(a cube of 2.8 m, every length scaled alike), with the same seeds, steps and faceted cutters (6 segments, 4 rings), and
the finish `satin` is the demo's material: albedo (0.7, 0.7, 0.8), metallic 0.3, roughness 0.7, its SSAO stood in for by
the occlusion baked into each vertex.

Palle, 2026-11-14, after the cave a visitor paints: "make these but carved sculptures using sine and randomness, what is
inbetween a helix etc". The forms `column_*` are seven columns carved by one rule - a ball run along three grooves - in a
triangle whose corners are a sine, a helix and chance, and whose sides and middle are their mixtures (see THE COLUMNS).

  python tools/iso_prefabs.py check [form ...]     build each form, measure it, run its checks; print a table
  python tools/iso_prefabs.py export [form ...]    ... and write ada_run/iso_prefabs/<form>.bin + manifest.json
  python tools/iso_prefabs.py views [form ...]     sections and heights as PNG in ada_run/iso_prefabs/views/

then bake the meshes the game loads (commons/artifacts/iso_prefabs/forms/<form>.res):

  godot --headless --path . --xr-mode off --script res://commons/artifacts/iso_prefabs/bake_forms.gd

Checks are the bench for what the tower's walker and balls will meet (tools/probes/iso_prefabs_walk.gd tests the real
thing): a passage leaves a capsule of radius 0.2 m and height 1.7 m a margin; a walkable surface rises no steeper than
40 degrees and starts at the floor without a lip (the walker cannot take a 4.5 cm step); a ball hole's size is set
against the kit's balls - rubber ball 0.22 m, trace ball 0.28 m.
"""
import json
import struct
import sys
from pathlib import Path

import numpy as np
from skimage import measure

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'ada_run' / 'iso_prefabs'

BODY, CUT, TRIM, FLOOR = 0, 1, 2, 3
PALETTE = {BODY: (0.86, 0.84, 0.80), CUT: (1.0, 0.55, 0.35), TRIM: (0.50, 0.80, 0.74), FLOOR: (0.86, 0.84, 0.80)}
BAND = (1.0, 0.95, 0.65)
RUBBER, TRACE = 0.11, 0.14          # ball radii of the kit's rubber ball and trace ball
WALKER_R, WALKER_H = 0.2, 1.7       # commons/void/walker.gd


# ---------------------------------------------------------------- the field: every node returns (distance, role, band)

def leaf(fn):
    def f(p):
        d = fn(p)
        return d, np.zeros(d.shape, np.int8), np.zeros(d.shape, np.float32)
    return f


def sphere(c, r):
    c = np.asarray(c, float)
    return leaf(lambda p: np.linalg.norm(p - c, axis=1) - r)


def ellipsoid(c, radii):
    c, radii = np.asarray(c, float), np.asarray(radii, float)

    def d(p):
        q = (p - c) / radii
        k0 = np.linalg.norm(q, axis=1)
        k1 = np.linalg.norm(q / radii, axis=1)
        return np.where(k1 > 1e-9, k0 * (k0 - 1.0) / np.maximum(k1, 1e-9), -radii.min())
    return leaf(d)


def rbox(c, half, r=0.0):
    c, half = np.asarray(c, float), np.asarray(half, float)

    def d(p):
        q = np.abs(p - c) - (half - r)
        return np.linalg.norm(np.maximum(q, 0.0), axis=1) + np.minimum(q.max(axis=1), 0.0) - r
    return leaf(d)


def cyl(c, axis, r, half_len, rr=0.0):
    """A capped cylinder along x, y or z with its rim rounded by rr."""
    c = np.asarray(c, float)
    a = 'xyz'.index(axis)
    rest = [i for i in range(3) if i != a]

    def d(p):
        q = p - c
        rad = np.hypot(q[:, rest[0]], q[:, rest[1]])
        dx, dy = rad - (r - rr), np.abs(q[:, a]) - (half_len - rr)
        return np.minimum(np.maximum(dx, dy), 0.0) + np.hypot(np.maximum(dx, 0.0), np.maximum(dy, 0.0)) - rr
    return leaf(d)


def capsule(a, b, r):
    a, b = np.asarray(a, float), np.asarray(b, float)
    ba = b - a

    def d(p):
        pa = p - a
        h = np.clip(pa @ ba / (ba @ ba), 0.0, 1.0)
        return np.linalg.norm(pa - h[:, None] * ba, axis=1) - r
    return leaf(d)


def half_space(normal, offset):
    """Inside where dot(p, n) <= offset."""
    n = np.asarray(normal, float)
    n = n / np.linalg.norm(n)
    return leaf(lambda p: p @ n - offset)


def arch(axis, width, spring, length, c=(0.0, 0.0, 0.0), bottom=-1.0):
    """An arched opening: a rectangle up to the springing line under a half disc, extruded along x or z."""
    c = np.asarray(c, float)
    hw = width / 2.0

    def d(p):
        q = p - c
        u, w = (q[:, 2], q[:, 0]) if axis == 'x' else (q[:, 0], q[:, 2])
        v = q[:, 1]
        cy, hy = (spring + bottom) / 2.0, (spring - bottom) / 2.0
        bx, by = np.abs(u) - hw, np.abs(v - cy) - hy
        rect = np.hypot(np.maximum(bx, 0), np.maximum(by, 0)) + np.minimum(np.maximum(bx, by), 0)
        disk = np.hypot(u, v - spring) - hw
        d2 = np.minimum(rect, disk)
        e = np.abs(w) - length / 2.0
        return np.minimum(np.maximum(d2, e), 0) + np.hypot(np.maximum(d2, 0), np.maximum(e, 0))
    return leaf(d)


def U(*fs):
    def f(p):
        out = None
        for g in fs:
            d, r, b = g(p)
            if out is None:
                out = [d, r, b]
                continue
            m = d < out[0]
            out = [np.where(m, d, out[0]), np.where(m, r, out[1]), np.where(m, b, out[2])]
        return out[0], out[1].astype(np.int8), out[2]
    return f


def I(a, b, role=TRIM, k=0.0):
    """Keep what a and b share; the faces b makes take `role`. k > 0 rounds the edge where they meet (a sharp edge
    that does not run along the grid marches into a sawtooth)."""
    def f(p):
        da, ra, ba = a(p)
        db, rb, bb = b(p)
        m = db > da
        if k <= 0:
            return np.where(m, db, da), np.where(m, role, ra).astype(np.int8), np.where(m, bb, ba)
        h = np.clip(0.5 - 0.5 * (db - da) / k, 0.0, 1.0)
        return db * (1 - h) + da * h + k * h * (1 - h), np.where(m, role, ra).astype(np.int8), np.where(m, bb, ba)
    return f


def D(a, *bs, k=0.0):
    """a minus the union of bs; the faces the cut makes are CUT. k > 0 rounds the cut's edges (a smooth difference)."""
    sub = U(*bs) if len(bs) > 1 else bs[0]

    def f(p):
        da, ra, ba = a(p)
        db, _, _ = sub(p)
        nb = -db
        if k <= 0:
            m = nb > da
            return np.where(m, nb, da), np.where(m, CUT, ra).astype(np.int8), np.where(m, 0.0, ba)
        h = np.clip(0.5 - 0.5 * (db + da) / k, 0.0, 1.0)
        d = da * (1 - h) + nb * h + k * h * (1 - h)
        return d, np.where(h > 0.5, CUT, ra).astype(np.int8), np.where(h > 0.5, 0.0, ba)
    return f


def SU(k, *fs):
    """Smooth union: within k of a meeting the two boundaries melt into one; band = how much of the blend a point is."""
    def f(p):
        da, ra, ba = fs[0](p)
        for g in fs[1:]:
            db, rb, bb = g(p)
            h = np.clip(0.5 + 0.5 * (db - da) / k, 0.0, 1.0)
            w = (4.0 * h * (1.0 - h)).astype(np.float32)
            da = db * (1 - h) + da * h - k * h * (1 - h)
            ra = np.where(h >= 0.5, ra, rb).astype(np.int8)
            ba = np.maximum(np.where(h >= 0.5, ba, bb), w)
        return da, ra, ba
    return f


FLOOR_SINK = 0.08


def ON_FLOOR(a):
    """Everything here stands on the floor, and goes on 8 cm INTO it (inside the slab, never seen): what lies at or
    under the floor is dropped from the mesh afterwards. A ramp that ended exactly at the floor would thin to nothing,
    and marching cubes cannot draw anything thinner than a voxel - the collision mesh would keep a lip of up to half a
    voxel (3.5 cm), which the tower's walker cannot take. Continued under the floor, every ramp meets it on a clean line."""
    return I(a, half_space((0, -1, 0), FLOOR_SINK), role=FLOOR)


def moved(fn, t=(0, 0, 0), yaw=0.0, roll=0.0):
    """fn placed at t, turned by yaw (about y) then roll (about z), in degrees."""
    t = np.asarray(t, float)
    cy, sy = np.cos(np.radians(yaw)), np.sin(np.radians(yaw))
    cr, sr = np.cos(np.radians(roll)), np.sin(np.radians(roll))

    def f(p):
        q = p - t
        x, y, z = q[:, 0] * cy - q[:, 2] * sy, q[:, 1], q[:, 0] * sy + q[:, 2] * cy
        return fn(np.stack([x * cr + y * sr, -x * sr + y * cr, z], axis=1))
    return f


def shrunk(fn, by):
    def f(p):
        d, r, b = fn(p)
        return d + by, r, b
    return f


# ---------------------------------------------------------------- fields that are not boolean trees

def helix_ramp(r_in, r_out, rise, turn_deg, landing_deg):
    """A solid ramp wound round the y axis: from the floor at angle 0 up to `rise` at turn - landing, flat to `turn`.
    The rest of the circle is open floor (the way on, and where the high end drops)."""
    turn = np.radians(turn_deg)
    climb = np.radians(turn_deg - landing_deg)

    def d(p):
        x, y, z = p[:, 0], p[:, 1], p[:, 2]
        rho = np.hypot(x, z)
        theta = np.mod(np.arctan2(z, x), 2 * np.pi)
        # the surface starts 4 cm under the floor, so that the floor cuts a clean line where the ramp begins (a ramp
        # that thins to nothing is a lip one voxel high: marching cubes cannot draw anything thinner than a voxel)
        top = np.minimum((rise + 0.04) * theta / climb - 0.04, rise)
        # past the end the nearest part of the ramp is one of its two end faces: distance to the sector in the plan
        inside = theta <= turn
        to_start = np.abs(z) * (x > 0) + np.hypot(x, z) * (x <= 0)
        ex, ez = np.cos(turn), np.sin(turn)
        along = x * ex + z * ez
        to_end = np.where(along > 0, np.abs(-x * ez + z * ex), np.hypot(x, z))
        sector = np.where(inside, -np.minimum(to_start, to_end), np.minimum(to_start, to_end))
        ring = np.maximum(rho - r_out, r_in - rho)
        plan = np.maximum(ring, sector)
        top_end = np.where(theta > turn, np.where(theta > (turn + 2 * np.pi) / 2, 0.0, rise), top)
        return np.maximum(plan, y - top_end)            # the floor is ON_FLOOR's (8 cm under it)
    return leaf(d)


def revolved(profile_points, thickness):
    """A thin shell turned about the y axis from a polyline profile [(radius, height), ...]."""
    pts = np.asarray(profile_points, float)

    def d(p):
        rho, y = np.hypot(p[:, 0], p[:, 2]), p[:, 1]
        q = np.stack([rho, y], axis=1)
        best = np.full(len(p), np.inf)
        for a, b in zip(pts[:-1], pts[1:]):
            ba = b - a
            h = np.clip((q - a) @ ba / (ba @ ba), 0.0, 1.0)
            best = np.minimum(best, np.linalg.norm(q - a - h[:, None] * ba, axis=1))
        return best - thickness
    return leaf(d)


def _swept_frame(curve):
    """Local coordinates along a curve in the x-y plane: s along it, v up off it (perpendicular), u across (z)."""
    from scipy.spatial import cKDTree
    curve = np.asarray(curve, float)
    tangent = np.gradient(curve, axis=0)
    tangent /= np.linalg.norm(tangent, axis=1)[:, None]
    up = np.stack([-tangent[:, 1], tangent[:, 0]], axis=1)
    up *= np.sign(up[:, 1:2])
    tree = cKDTree(curve)
    length = np.r_[0, np.cumsum(np.linalg.norm(np.diff(curve, axis=0), axis=1))]

    def frame(p):
        xy = p[:, :2]
        _, i = tree.query(xy)
        rel = xy - curve[i]
        return length[i] + np.einsum('ij,ij->i', rel, tangent[i]), np.einsum('ij,ij->i', rel, up[i]), p[:, 2]
    return frame, length[-1]


def swept_trough(curve, radius, bore=False, start=0.0, end=0.0):
    """The lower half of a disc of `radius` carried along a curve: a solid trough; or, as a bore, the whole disc,
    running `start` metres past (negative: short of) the curve's first end and `end` past its last."""
    frame, total = _swept_frame(curve)

    def d(p):
        s, v, u = frame(p)
        disc = np.hypot(u, v) - radius
        ends = np.maximum(-s - start, s - total - end)
        return np.maximum(disc, ends) if bore else np.maximum(np.maximum(disc, v), ends)
    return leaf(d)


def gyroid_shell(period, thickness):
    k = 2 * np.pi / period

    def d(p):
        x, y, z = (p * k).T
        g = np.sin(x) * np.cos(y) + np.sin(y) * np.cos(z) + np.sin(z) * np.cos(x)
        return np.abs(g) / (k * 1.5) - thickness
    return leaf(d)


def metaballs(centres, radii, squash):
    """Summed fields of round bodies (squashed in y): where the sum passes 1 there is a boundary - near enough, two
    bodies share one. Returned as an approximate distance (exact for a single ball)."""
    centres, radii = np.asarray(centres, float), np.asarray(radii, float)
    mean = radii.mean()

    def d(p):
        total = np.zeros(len(p))
        for c, r in zip(centres, radii):
            q = p - c
            q[:, 1] *= squash
            total += r * r / np.maximum(np.einsum('ij,ij->i', q, q), 1e-9)
        return mean * (1.0 / np.sqrt(np.maximum(total, 1e-12)) - 1.0)
    return leaf(d)


def _perlin(seed):
    rng = np.random.default_rng(seed)
    perm = rng.permutation(256)
    perm = np.r_[perm, perm]
    grads = np.array([[1, 1, 0], [-1, 1, 0], [1, -1, 0], [-1, -1, 0], [1, 0, 1], [-1, 0, 1], [1, 0, -1], [-1, 0, -1],
                      [0, 1, 1], [0, -1, 1], [0, 1, -1], [0, -1, -1]], float)

    def noise(p):
        pi = np.floor(p).astype(int)
        pf = p - pi
        pi &= 255
        fade = pf * pf * pf * (pf * (pf * 6 - 15) + 10)
        out = 0.0
        for dx in (0, 1):
            for dy in (0, 1):
                for dz in (0, 1):
                    h = perm[perm[perm[pi[:, 0] + dx] + pi[:, 1] + dy] + pi[:, 2] + dz] % 12
                    g = np.einsum('ij,ij->i', grads[h], pf - np.array([dx, dy, dz]))
                    w = (fade[:, 0] if dx else 1 - fade[:, 0]) * (fade[:, 1] if dy else 1 - fade[:, 1]) * (fade[:, 2] if dz else 1 - fade[:, 2])
                    out = out + w * g
        return out
    return noise


def roughened(fn, amplitude, scale, seed, octaves=3):
    """A body whose boundary carries a noise field: the value at each point moves the boundary in or out."""
    noise = _perlin(seed)

    def f(p):
        d, r, b = fn(p)
        n = np.zeros(len(p))
        for o in range(octaves):
            n += noise(p * (scale * 2 ** o) + 17.3 * o) / 2 ** o
        return d - amplitude * n, r, b
    return f


# ---------------------------------------------------------------- the twenty

# The walk-in forms were first drawn tight for a body of 1.7 m (a tunnel 1.3 m wide, a dome 3.4 m across); walked in
# the tower they read as narrow. They are a third bigger now: a passage 1.8 m wide under a 2.95 m crown, a room 2.8 m
# across, a dome 4.7 m across inside.
TUNNEL_WIDE, TUNNEL_SPRING = 1.8, 2.05
CROSSING_WIDE, CROSSING_SPRING, CROSSING_ROOM = 1.6, 2.1, 1.4
DOOR_X, DOOR_WIDE, DOOR_SPRING = -0.9, 1.3, 2.0
PORT_X = 1.2


def _tunnel():
    block = rbox((0, 1.75, 0), (2.0, 1.75, 1.6), 0.3)
    way = arch('x', TUNNEL_WIDE, TUNNEL_SPRING, 5.2)
    return ON_FLOOR(D(block, way, k=0.08))


def _crossing():
    block = rbox((0, 1.95, 0), (2.15, 1.95, 2.15), 0.32)
    room = U(cyl((0, 1.05, 0), 'y', CROSSING_ROOM, 1.6), sphere((0, 2.1, 0), CROSSING_ROOM))
    return ON_FLOOR(D(block, arch('x', CROSSING_WIDE, CROSSING_SPRING, 5.4), arch('z', CROSSING_WIDE, CROSSING_SPRING, 5.4), room, k=0.08))


def _thresholds():
    wall = rbox((0, 1.75, 0), (2.15, 1.75, 0.2), 0.1)
    door = arch('z', DOOR_WIDE, DOOR_SPRING, 1.2, c=(DOOR_X, 0, 0))
    porthole = cyl((PORT_X, 1.2, 0), 'z', 0.2, 0.5)
    mousehole = cyl((PORT_X, 0.05, 0), 'z', 0.2, 0.5)
    return ON_FLOOR(D(wall, door, porthole, mousehole, k=0.045))


SIEVE_TILT = 14.0
SIEVE_HOLE = 0.128


def _sieve():
    plate = rbox((0, 0, 0), (0.8, 0.03, 0.55), 0.02)
    rim = D(rbox((0, 0.03, 0), (0.83, 0.07, 0.58), 0.03), rbox((0.1, 0.09, 0), (0.86, 0.1, 0.55)))
    s = 0.32
    def holes(p):                                       # limited repetition of one sphere, in the plate's frame
        q = p.copy()
        q[:, 0] -= s * np.clip(np.round(q[:, 0] / s), -2, 2)
        q[:, 2] -= s * np.clip(np.round(q[:, 2] / s), -1, 1)
        return np.linalg.norm(q, axis=1) - SIEVE_HOLE
    tray = moved(D(U(plate, rim), leaf(holes), k=0.012), t=(0, 0.85, 0), roll=-SIEVE_TILT)
    legs = [capsule((sx * 0.68, 0.0, sz * 0.45), (sx * 0.68, 0.85 + sx * 0.68 * np.tan(np.radians(SIEVE_TILT)) * -1 - 0.02, sz * 0.45), 0.035)
            for sx in (-1, 1) for sz in (-1, 1)]
    return ON_FLOOR(SU(0.04, tray, *legs))


DOME_Y, DOME_OUT, DOME_IN = 0.75, 2.7, 2.45


def _dome():
    outer = sphere((0, DOME_Y, 0), DOME_OUT)
    inner = sphere((0, DOME_Y, 0), DOME_IN)
    door = arch('z', 1.3, 1.9, 2.4, c=(0, 0, 2.2))
    oculus = cyl((0, 3.3, 0), 'y', 0.42, 0.8)
    return ON_FLOOR(D(outer, inner, door, oculus, k=0.06))


def _basin():
    """Deep enough to keep a ball off the chute: a rubber ball arriving at 2.5 m/s climbed out of a 0.26 m dish and
    rolled 3 m away; out of 0.4 m it would need about 3.3 m/s."""
    block = rbox((0, 0.25, 0), (0.85, 0.25, 0.85), 0.12)
    return ON_FLOOR(D(block, sphere((0, 1.05, 0), 0.95), k=0.04))


GUTTER_RISE, GUTTER_LONG = 0.75, 3.0


def _gutter_ramp():
    slope = GUTTER_RISE / GUTTER_LONG
    n = (-slope, 1.0, 0.0)
    wedge = I(rbox((0, 0.5, 0), (1.5, 0.5, 0.7), 0.03), half_space(n, slope * 1.5 * np.cos(np.arctan(slope))), role=BODY, k=0.05)
    a = np.array([-1.7, slope * (-1.7 + 1.5) - 0.04, 0.0])
    b = np.array([1.7, slope * (1.7 + 1.5) - 0.04, 0.0])
    return ON_FLOOR(D(wedge, capsule(a, b, 0.13), k=0.03))


MOULD_R = 0.36


def _mould():
    block = rbox((0, 0.25, 0), (0.45, 0.25, 0.45), 0.06)
    return ON_FLOOR(D(block, sphere((0, 0.5, 0), MOULD_R), k=0.015))


def _cast():
    """The mould's block and sphere again, kept where both are: the stone that fills the cup. 8 mm smaller, so that it
    can be put in. Its own frame: resting on its round side, the lowest point at the origin."""
    block = rbox((0, 0.25, 0), (0.45, 0.25, 0.45), 0.06)
    body = I(block, sphere((0, 0.5, 0), MOULD_R), role=TRIM, k=0.02)
    return moved(shrunk(body, 0.008), t=(0, -(0.5 - MOULD_R) + 0.0, 0))


def _hump_bridge():
    rise, half = 0.45, 2.0
    big = (half * half + rise * rise) / (2 * rise)
    beam = rbox((0, 0.3, 0), (half + 0.2, 0.5, 0.6), 0.04)
    deck = I(beam, sphere((0, rise - big, 0), big), role=TRIM, k=0.05)
    culvert = cyl((0, 0.06, 0), 'z', 0.2, 1.0)
    return ON_FLOOR(D(deck, culvert, k=0.03))


def _die_body():
    """The die before its pips are cut: the intersection of two convex shapes, so convex - this is its hull's shape."""
    return I(rbox((0, 0, 0), (0.25, 0.25, 0.25), 0.0), sphere((0, 0, 0), 0.33), role=TRIM, k=0.02)


def _die():
    body = _die_body()
    spots = {(0, 1, 0): [(0, 0)], (0, -1, 0): [(-1, -1), (-1, 0), (-1, 1), (1, -1), (1, 0), (1, 1)],
             (1, 0, 0): [(-1, -1), (1, 1)], (-1, 0, 0): [(-1, -1), (-1, 1), (0, 0), (1, -1), (1, 1)],
             (0, 0, 1): [(-1, -1), (0, 0), (1, 1)], (0, 0, -1): [(-1, -1), (-1, 1), (1, -1), (1, 1)]}
    pits = []
    for n, marks in spots.items():
        n = np.asarray(n, float)
        a = np.roll(n, 1)
        b = np.cross(n, a)
        for i, j in marks:
            pits.append(sphere(n * 0.262 + a * i * 0.12 + b * j * 0.12, 0.05))
    return moved(D(body, *pits, k=0.01), t=(0, 0.25, 0))


STILE_STEP, STILE_TREAD, STILE_TOP, STILE_K = 0.22, 0.5, 0.6, 0.5


def _stile():
    """Three steps up and three down. On one half the steps are a union of boxes; on the other a smooth union of
    rounded boxes AND THE FLOOR (without the floor among the operands the first riser has nothing to melt into and
    stays a wall: measured, k up to 1.6 left an 82 degree riser). Both halves are connected. Only one lets a body over."""
    def steps(z0, round_r):
        boxes = []
        for i in range(3):
            hx = STILE_TOP / 2 + (3 - i) * STILE_TREAD
            h = STILE_STEP * (i + 1)
            boxes.append(rbox((0, h / 2 - 0.2, z0), (hx, h / 2 + 0.2, 0.5), round_r))
        return boxes
    hard = U(*steps(-0.5, 0.0))
    soft = I(SU(STILE_K, half_space((0, 1, 0), 0.0), *steps(0.5, 0.2)), rbox((0, 0, 0.5), (2.4, 2.0, 0.5)), role=BODY)
    return ON_FLOOR(U(hard, soft))


def _mound():
    ground = half_space((0, 1, 0), 0.0)
    return ON_FLOOR(I(SU(0.75, ground, sphere((0, -0.45, 0), 1.15)), cyl((0, 0, 0), 'y', 2.0, 2.0), role=BODY))


STONES = [(-1.35, -0.02, 0.0), (-0.3, -0.02, 0.05), (1.75, -0.02, -0.05)]
STONES_K = 0.12


def _stones():
    ground = half_space((0, 1, 0), 0.0)
    balls = metaballs(STONES, [0.5, 0.5, 0.46], 2.6)
    return ON_FLOOR(I(SU(STONES_K, ground, balls), rbox((0, 0, 0), (2.6, 1.0, 1.0)), role=BODY))


TEE_BORE, TEE_WALL = 0.16, 0.045


def _pipe_tee():
    top, mid, end_x, end_y = 1.25, 0.55, 0.85, 0.25
    r_out = TEE_BORE + TEE_WALL
    a, b, c = (0, top, 0), (0, mid, 0), ((-end_x, end_y, 0), (end_x, end_y, 0))
    pipes = U(capsule(a, b, r_out), capsule(b, c[0], r_out), capsule(b, c[1], r_out))
    fall = (mid - end_y) / end_x
    legs = [capsule((sx * 0.5, 0.0, sz * 0.16), (sx * 0.5, mid - fall * 0.5, 0.0), 0.035) for sx in (-1, 1) for sz in (-1, 1)]
    bores = U(capsule((0, top + 0.4, 0), b, TEE_BORE), capsule(b, (-end_x - 0.4, end_y - 0.4 * fall, 0), TEE_BORE),
              capsule(b, (end_x + 0.4, end_y - 0.4 * fall, 0), TEE_BORE))
    joined_then_bored = I(D(SU(0.03, pipes, *legs), bores), half_space((0, 1, 0), top), role=CUT, k=0.015)
    return ON_FLOOR(I(I(joined_then_bored, half_space((1, 0, 0), end_x), role=CUT, k=0.015), half_space((-1, 0, 0), end_x), role=CUT, k=0.015))


SPIRAL_RISE = 1.0


def _spiral_ramp():
    ramp = helix_ramp(0.2, 1.55, SPIRAL_RISE, 300.0, 30.0)
    post = cyl((0, 1.1, 0), 'y', 0.28, 1.1, 0.12)
    return ON_FLOOR(SU(0.06, ramp, post))


FUNNEL_THROAT = 0.19
FUNNEL_SKIN = 0.03


def _funnel():
    shell = revolved([(0.62, 1.35), (FUNNEL_THROAT, 0.8), (FUNNEL_THROAT, 0.58)], FUNNEL_SKIN)
    legs = []
    for k in range(3):
        a = np.radians(90 + 120 * k)
        legs.append(capsule((0.5 * np.cos(a), 1.2, 0.5 * np.sin(a)), (0.72 * np.cos(a), 0.0, 0.72 * np.sin(a)), 0.035))
    return ON_FLOOR(SU(0.05, shell, *legs))


CHUTE_LOW, CHUTE_DROP = 0.75, 0.45     # its mouth over the basin's rim (0.5 m), and a drop a basin can catch


def _chute_curve():
    xs = np.linspace(-1.5, 1.4, 240)
    t = (1.4 - xs) / 2.9
    return np.stack([xs, CHUTE_LOW + CHUTE_DROP * t * t], axis=1)


CHUTE_R = 0.15
CHUTE_WALL = 0.045                  # thicker than a collision voxel: a shell thinner than one marches with holes


def _chute():
    curve = _chute_curve()
    trough = swept_trough(curve, CHUTE_R + CHUTE_WALL)
    legs = [capsule((-1.0, 0.0, sz * 0.12), (-1.0, CHUTE_LOW + CHUTE_DROP * (2.4 / 2.9) ** 2 - CHUTE_R, 0.0), 0.035) for sz in (-1, 1)]
    legs += [capsule((0.9, 0.0, sz * 0.12), (0.9, CHUTE_LOW + CHUTE_DROP * (0.5 / 2.9) ** 2 - CHUTE_R, 0.0), 0.035) for sz in (-1, 1)]
    # the bore stops 4 cm short of the high end: an end wall, so that a ball put in at the top can only roll down
    return ON_FLOOR(D(SU(0.04, trough, *legs), swept_trough(curve, CHUTE_R, bore=True, start=-0.04, end=0.3), k=0.01))


GYROID_PERIOD, GYROID_DEPTH = 0.7, 0.12


def _gyroid_screen():
    panel = I(rbox((0, 1.08, 0), (1.0, 1.0, GYROID_DEPTH), 0.0), gyroid_shell(GYROID_PERIOD, 0.03), role=TRIM, k=0.02)
    frame = D(rbox((0, 1.08, 0), (1.08, 1.08, GYROID_DEPTH + 0.02), 0.05), rbox((0, 1.08, 0), (1.0, 1.0, 0.4)))
    return ON_FLOOR(U(panel, frame))


def _boulder():
    ground = half_space((0, 1, 0), 0.0)
    rock = roughened(ellipsoid((0, 0.12, 0), (0.62, 0.42, 0.52)), 0.09, 2.2, seed=161)
    return ON_FLOOR(I(SU(0.12, ground, rock), rbox((0, 0, 0), (1.0, 1.2, 0.9)), role=BODY))


# ---------------------------------------------------------------- the carvings (Random Boolean Carving, its demo)

CARVE_SCALE = 0.28              # the demo's 10 m cubes at 2.8 m: every length alike, so the carvings keep their look
CARVINGS = {                    # all_patterns_demo.tscn, node by node (unset fields take advanced_carver.gd's defaults)
    'carved_walk': dict(pattern='walk', seed=1, steps=50, step=1.5, radius=2.5, label='Random Walk'),
    'carved_spiral': dict(pattern='spiral', seed=2, steps=60, step=1.8, radius=2.8, turns=4.0, decay=0.3, label='Spiral'),
    # Branches at the demo's own numbers (seed 3, step 2.0 in a 10 m cube, trunk from the centre) climbs out in two steps and
    # never branches - its own code prints "main path too short". Started at the floor with a 0.8 m step (seed 4, branch
    # chance 0.5) the rule fires: a 12-point trunk and three branches. Shown in section, so that they can be seen.
    'carved_branches': dict(pattern='branches', seed=4, steps=50, step=0.8, radius=1.2, branch_p=0.5, branches=6, start=(0.0, -4.0, 0.0),
                            section=True, label='Branches',
                            principle="The demo's trunk starts mid-cube with 4.5 m to climb, and a branch may leave only after 11 points 0.6 m apart: none ever fits. Started at the floor, it branches; the block is cut open to show it."),
    'carved_perlin': dict(pattern='perlin', seed=4, steps=70, step=1.5, radius=2.5, perlin_scale=0.25, perlin_strength=2.0, label='Sine Field',
                          principle='The demo calls it Perlin, but no noise is drawn: each step turns by sin and cos of where it stands and how many steps it has tried. 19 of its 70 tries land.'),
    'carved_grid': dict(pattern='grid', seed=5, steps=60, step=1.5, radius=2.5, line=False, label='Grid Tunnels',
                        principle="Nine straight tunnels on a fixed grid. Only each sphere's size is drawn (+-20 %), and that draw alone decides where the skin breaks."),
    'carved_sphere': dict(pattern='spiral', seed=6, steps=50, step=1.8, radius=2.8, turns=3.0, decay=0.5, base='sphere', label='Sphere + Spiral',
                          principle='Spheres up to 1.9 m across, on turns 0.75 m apart, overlap from turn to turn: the spiral takes 97 % of the sphere. A difference can leave less than either operand.'),
}


def carving_paths(spec, size=10.0):
    """advanced_carver.gd's path generators, step for step, in the demo's own units (a 10 m cube centred on the
    origin). Python's generator stands in for Godot's: the same procedure and seeds, not the same draws."""
    rng = np.random.RandomState(spec['seed'])
    half = size * 0.45
    cross = 0.6                                         # crossing_check_distance
    occupied = []

    def valid(q):
        if np.any(np.abs(q) > half):
            return False
        return all(np.linalg.norm(q - o) >= cross for o in occupied)
    paths = []
    if spec['pattern'] == 'walk':
        cur = np.zeros(3)
        path = [cur]
        occupied.append(cur)
        dirs = [np.array(v, float) for v in ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, -1), (0, 0, 1))]
        for _ in range(spec['steps']):
            for attempt in range(20):
                nxt = cur + dirs[rng.randint(6)] * spec['step']
                if valid(nxt):
                    cur = nxt
                    path.append(cur)
                    occupied.append(cur)
                    break
        paths.append(path)
    elif spec['pattern'] == 'spiral':
        path = []
        n = spec['steps']
        for i in range(n):
            t = i / n
            angle = t * spec['turns'] * 2 * np.pi
            radius = size * 0.4 * (1.0 - t * spec['decay'])
            path.append(np.array([np.cos(angle) * radius, (t - 0.5) * size * 0.8, np.sin(angle) * radius]))
        paths.append(path)
    elif spec['pattern'] == 'branches':
        def branch(start, main, steps):
            cur, out = start, [start]
            for _ in range(steps):
                d = main + rng.uniform(-0.3, 0.3, 3)
                nxt = cur + d / np.linalg.norm(d) * spec['step']
                if valid(nxt):
                    cur = nxt
                    out.append(cur)
                    occupied.append(cur)
            return out
        trunk = branch(np.array(spec.get('start', (0.0, 0.0, 0.0)), float), np.array([0.0, 1.0, 0.0]), int(spec['steps'] * 0.6))
        paths.append(trunk)
        if len(trunk) > 10:
            made = 0
            for _ in range(spec['branches']):
                if rng.uniform() < spec['branch_p'] and made < spec['branches']:
                    start = trunk[rng.randint(max(1, len(trunk) - 10))]
                    d = np.array([rng.uniform(-1, 1), rng.uniform(-0.5, 0.5), rng.uniform(-1, 1)])
                    paths.append(branch(start, d / np.linalg.norm(d), int(spec['steps'] * 0.3)))
                    made += 1
    elif spec['pattern'] == 'perlin':
        cur = np.zeros(3)
        path = [cur]
        ps, st = spec['perlin_scale'], spec['perlin_strength']
        for step in range(spec['steps']):
            d = np.array([np.sin(cur[0] * ps + step * 0.1) * st, np.cos(cur[1] * ps + step * 0.15) * st, np.sin(cur[2] * ps + step * 0.12) * st])
            nxt = cur + d / max(np.linalg.norm(d), 1e-9) * spec['step']
            if valid(nxt):
                cur = nxt
                path.append(cur)
                occupied.append(cur)
        paths.append(path)
    elif spec['pattern'] == 'grid':
        g = 3
        spacing = size / (g + 1)
        for y in range(g):
            for z in range(g):
                paths.append([np.array([x * spacing * 0.5, (y - g / 2.0 + 0.5) * spacing, (z - g / 2.0 + 0.5) * spacing]) for x in range(-g, g + 1)])
    # every point once, each with its radius varied +-20 % (radius_variation 0.2)
    points, seen = [], set()
    for path in paths:
        for q in path:
            key = tuple(np.round(q, 4))
            if key not in seen:
                seen.add(key)
                points.append((q, spec['radius'] * rng.uniform(0.8, 1.2)))
    return paths, points


def lowpoly_sphere(c, r, radial=6, rings=4):
    """A CSGSphere3D with radial_segments 6 and rings 4 - the carver's cutter - as a convex polyhedron: the ball its
    vertices span, cut flat at every face. Its gradient is piecewise constant, so the cavities come out faceted, as
    in the demo."""
    c = np.asarray(c, float)
    normals, offsets = [], []
    lat = [np.pi * (i / rings) - np.pi / 2 for i in range(rings + 1)]
    for i in range(rings):
        for j in range(radial):
            a0, a1 = 2 * np.pi * j / radial, 2 * np.pi * (j + 1) / radial
            quad = []
            for la in (lat[i], lat[i + 1]):
                for a in (a0, a1):
                    quad.append(np.array([np.cos(la) * np.sin(a), np.sin(la), np.cos(la) * np.cos(a)]) * r)
            n = np.cross(quad[1] - quad[0], quad[2] - quad[0])
            if np.linalg.norm(n) < 1e-9:
                n = np.cross(quad[3] - quad[1], quad[2] - quad[1])
            n /= np.linalg.norm(n)
            centre = np.mean(quad, axis=0)
            if n @ centre < 0:
                n = -n
            normals.append(n)
            offsets.append(max(n @ v for v in quad))
    normals, offsets = np.array(normals), np.array(offsets)

    def d(p):
        return ((p - c) @ normals.T - offsets).max(axis=1)
    return leaf(d)


def _carved(name):
    spec = CARVINGS[name]
    k = CARVE_SCALE
    edge = 10.0 * k
    centre = np.array([0.0, edge / 2, 0.0])
    _, points = carving_paths(spec)
    if spec.get('base') == 'sphere':                   # seated 15 cm into the floor, not balanced on a point
        centre = centre - np.array([0.0, 0.15, 0.0])
        base = sphere(centre, edge / 2)
    else:
        base = rbox(centre, (edge / 2, edge / 2, edge / 2), 0.02)
    cutters = [lowpoly_sphere(centre + q * k, r * k) for q, r in points]
    if spec.get('section'):                             # cut open: the north half stands, its cut face to the south
        return ON_FLOOR(I(D(base, *cutters), half_space((0, 0, 1), 0.05), role=TRIM))
    return ON_FLOOR(D(base, *cutters))


def carving_cutters(name):
    """A carving's cutters in metres (centre, radius), the cube lifted onto the floor."""
    spec = CARVINGS[name]
    k = CARVE_SCALE
    edge = 10.0 * k
    centre = np.array([0.0, edge / 2 - (0.15 if spec.get('base') == 'sphere' else 0.0), 0.0])
    _, points = carving_paths(spec)
    return [(centre + q * k, r * k) for q, r in points]


def _carving_builder(name):
    return lambda: _carved(name)



# ---------------------------------------------------------------- the passes: a box to walk into (Palle, 2026-11-13)
# "Take the best shader and add inner-out different passes of movement inside a bigger and larger box so we can walk
# into strange places." A box 16 x 5 x 9 m carved from the inside out by the Random Boolean Carving's own movements, at
# a body's size:
#   SPIRAL    the inner room: a pass coiled one and a quarter turns out from a pillar
#   GRID      straight runs and right angles, from a mouth in the building face to the room, with a dead-end stub
#   WALK      from a second mouth in the building face to the room, every step drawn at random - sideways, and up or
#             down: its floor climbs and drops like a random walk's height
#   SINE      out of the room's east side, snaking to the far end of the box
#   BRANCHES  out of the room's ceiling: a trunk that forks and forks again and leaves through the roof as light
# Every pass keeps 0.3 m of wall to the box's outer faces except at its mouth (checked: the faces are sampled), and
# 0.3 m to the passes it does not meet. A pass breathes (its radius swells and narrows along its length) and opens
# into a pocket with a skylight. Coloured as PARTS for the rhizome surface shader: COLOR.rgb is the pass a wall
# belongs to, COLOR.a how near the runner-up pass is - 1 where two passes fused, which the shader lights.

PASS_BOX = (8.0, 2.5, 4.5)      # half extents: 16 x 5 x 9 m; +z is the face toward the building
PASS_Y = 1.05                   # a pass's axis over its floor; radius 1.32 +- 0.16, so a floor 1.3 - 2.1 m wide
PASS_FLOOR = 0.004              # the floor at the outer faces, so a mouth meets the slab without a step
PASS_FLOOR_IN = 0.06            # the floor inside: 6 cm of the box's own material over the slab, drawn in the skin
PASS_FLOOR_RAMP = 0.9           # from the faces to the inside floor, over this much (3.6 degrees)
PASS_HUES = {'spiral': (0.62, 0.30, 0.92), 'walk': (0.86, 0.22, 0.52), 'sine': (0.30, 0.42, 0.95),
             'grid': (0.20, 0.78, 0.72), 'branches': (0.95, 0.52, 0.20), 'box': (0.90, 0.88, 0.84)}


def passes_plan(seed=161):
    rng = np.random.RandomState(seed)
    hx, hy, hz = PASS_BOX
    room = np.array([0.0, 0.0, -0.3])
    paths, floors, mouths = {}, {}, []
    # SPIRAL: the room, coiled out from its pillar
    paths['spiral'] = [room + np.array([np.cos(a) * r, 0.0, np.sin(a) * r])
                       for a, r in zip(0.3 * np.pi + np.linspace(0, 2.5 * np.pi, 60), np.linspace(1.15, 1.6, 60))]
    # GRID: in from the building face at x 4.6, by right angles, to the room's north-east; a stub runs on east
    paths['grid'] = [np.array(v, float) for v in ((4.6, 0, hz + 1.2), (4.6, 0, 2.7), (2.0, 0, 2.7), (2.0, 0, 1.4), (1.2, 0, 0.9))]
    paths['grid_stub'] = [np.array([4.6, 0, 2.7]), np.array([6.3, 0, 2.7])]
    mouths.append(dict(face='+z', at=4.6, name='grid'))
    # WALK: in from the building face at x -5.2, south down the west of the box, then east into the room's south-west.
    # Each 1.2 m step is drawn: sideways within the lane, and the floor up or down 0.3 m (never below the slab, never
    # over 0.9 m), level again where it meets the room
    for _ in range(64):                                 # drawn again until the walk climbs at least 0.6 m somewhere
        walk, heights = [np.array([-5.2, 0, hz + 1.2]), np.array([-5.2, 0, 3.3])], [0.0, 0.0]
        z, h = 3.3, 0.0
        while z > -2.2:
            z = max(z - 1.2, -2.6)
            h = float(np.clip(h + rng.choice([-0.35, 0.35, 0.35]), 0.0, 0.9))
            walk.append(np.array([float(np.clip(-5.25 + rng.uniform(-0.35, 0.35), -5.6, -4.9)), 0, z]))
            heights.append(h)
        if max(heights) >= 0.6:
            break
    for x in (-3.9, -2.6):
        h = max(0.0, h - 0.45)
        walk.append(np.array([x, 0, -2.6]))
        heights.append(h)
    walk.append(np.array([-1.3, 0, -1.8]))             # onto the room's floor, so no sill where they meet
    heights.append(0.0)
    heights[-2] = 0.0
    paths['walk'] = walk
    floors['walk'] = heights
    mouths.append(dict(face='+z', at=-5.2, name='walk'))
    # SINE: out of the room's east side to the far end
    xs = np.arange(2.7, hx + 0.95, 0.45)
    paths['sine'] = [np.array([1.5, 0.0, -1.0])] + [np.array([x, 0.0, -1.55 + 0.95 * np.sin(2 * np.pi * (x - xs[0]) / 4.3)]) for x in xs]
    mouths.append(dict(face='+x', at=float(paths['sine'][-1][2]), name='sine'))
    # BRANCHES: up out of the room's ceiling over the coil's north side, forking twice, out through the roof
    base = np.array([0.0, 2.0, 1.1])
    trunk_top = base + np.array([0.0, 1.15, 0.0])
    branches = [(base, trunk_top, 0.55)]
    tips = []
    for sx in (-1, 1):
        a = trunk_top + np.array([0.8 * sx + rng.uniform(-0.15, 0.15), 0.95, 0.35 * sx + rng.uniform(-0.15, 0.15)])
        branches.append((trunk_top, a, 0.42))
        for sz in (-1, 1):
            tip = a + np.array([0.45 * sx + rng.uniform(-0.15, 0.15), 2 * hy + 0.4 - a[1], 0.5 * sz + rng.uniform(-0.1, 0.1)])
            branches.append((a, tip, 0.3))
            tips.append(tip)
    # pockets: where the walk is highest, and the middle of the sine; each with a skylight
    top = int(np.argmax(heights))
    pockets = [(np.array([walk[top][0], heights[top], walk[top][2]]), 1.7, 'walk')]
    mid = paths['sine'][len(paths['sine']) // 2]
    pockets.append((np.array([mid[0], 0.0, max(mid[2], -hz + 0.35 + 1.75)]), 1.7, 'sine'))
    skylights = [q for q, _, _ in pockets]
    return dict(room=room, paths=paths, floors=floors, mouths=mouths, branches=branches, tips=tips, pockets=pockets,
                skylights=skylights, pillar=room)


def _floor_along(points, heights):
    """The height of a pass's floor under a plan point: along the nearest segment of its line, interpolated."""
    a = np.array([[q[0], q[2]] for q in points[:-1]], float)
    b = np.array([[q[0], q[2]] for q in points[1:]], float)
    ha, hb = np.array(heights[:-1], float), np.array(heights[1:], float)

    def at(p):
        xz = p[:, [0, 2]]
        best_d = np.full(len(p), np.inf)
        best_h = np.zeros(len(p))
        for i in range(len(a)):
            ab = b[i] - a[i]
            t = np.clip(((xz - a[i]) @ ab) / max(ab @ ab, 1e-9), 0.0, 1.0)
            d = np.linalg.norm(xz - (a[i] + t[:, None] * ab), axis=1)
            m = d < best_d
            best_d = np.where(m, d, best_d)
            best_h = np.where(m, ha[i] + t * (hb[i] - ha[i]), best_h)
        return best_h
    return at


def _pass_part(points, phase, heights=None):
    """One pass as a field: spheres along its line, the radius breathing with the distance walked; with `heights`,
    its axis follows its floor and the air is cut flat at that floor."""
    pts = np.array(points, float)
    hs = np.zeros(len(pts)) if heights is None else np.array(heights, float)
    length = np.r_[0, np.cumsum(np.linalg.norm(np.diff(pts, axis=0), axis=1))]
    dense = []
    for i in range(len(pts) - 1):
        n = max(1, int(np.linalg.norm(pts[i + 1] - pts[i]) / 0.35))
        for t in np.linspace(0, 1, n, endpoint=False):
            q = pts[i] + (pts[i + 1] - pts[i]) * t
            sw = length[i] + (length[i + 1] - length[i]) * t
            dense.append((q, hs[i] + (hs[i + 1] - hs[i]) * t, 1.32 + 0.16 * np.sin(2 * np.pi * sw / 3.4 + phase)))
    dense.append((pts[-1], hs[-1], 1.32))
    centres = np.array([[q[0], h + PASS_Y, q[2]] for q, h, _ in dense])
    radii = np.array([r for _, _, r in dense])

    def d(p):
        best = np.full(len(p), np.inf)
        for c, r in zip(centres, radii):
            best = np.minimum(best, np.linalg.norm(p - c, axis=1) - r)
        return best
    tube = leaf(d)
    if heights is None:
        return tube
    floor = _floor_along(points, heights)
    return I(tube, leaf(lambda p: floor(p) - p[:, 1]))


def pass_parts(plan=None):
    """The passes as separate fields (for the carving and for the colours), each with its name."""
    plan = plan or passes_plan()
    groups = {}
    for k, (name, pts) in enumerate(plan['paths'].items()):
        hue = name.split('_')[0]
        groups.setdefault(hue, []).append(_pass_part(pts, phase=k * 1.3, heights=plan['floors'].get(name)))
    floors = {name.split('_')[0]: _floor_along(plan['paths'][name], hs) for name, hs in plan['floors'].items()}
    for q, r, hue in plan['pockets']:
        pocket = sphere((q[0], q[1] + 1.35, q[2]), r)
        if hue in floors:                                # a pocket on a climbing pass keeps that pass's floor
            pocket = I(pocket, leaf(lambda p, fl=floors[hue]: fl(p) - p[:, 1]))
        groups[hue].append(pocket)
        groups[hue].append(cyl((q[0], q[1] + 1.35 + 2.5, q[2]), 'y', 0.45, 2.5))
    groups['branches'] = [capsule(a, b, r) for a, b, r in plan['branches']]
    parts = [(hue, SU(0.4, *fs) if len(fs) > 1 else fs[0]) for hue, fs in groups.items()]
    # a smooth union swells below both fields where they meet, so a climbing pass is cut at its floor AFTER the blend
    return [(hue, I(f, leaf(lambda p, fl=floors[hue]: fl(p) - p[:, 1])) if hue in floors else f) for hue, f in parts]


def pass_floor(x, z):
    """The passes' floor height at plan points: PASS_FLOOR_IN inside, ramped down to PASS_FLOOR at the outer faces."""
    hx, _, hz = PASS_BOX
    inner = np.minimum(hx - np.abs(x), hz - np.abs(z))
    return PASS_FLOOR + (PASS_FLOOR_IN - PASS_FLOOR) * np.clip(inner / PASS_FLOOR_RAMP, 0.0, 1.0)


def _passes():
    plan = passes_plan()
    hx, hy, hz = PASS_BOX
    # the box goes FLOOR_SINK into the slab (dropped from the mesh), so under a pass there is material to draw a floor
    box = rbox((0, hy - FLOOR_SINK / 2, 0), (hx, hy + FLOOR_SINK / 2, hz), 0.25)
    air = I(SU(0.5, *[f for _, f in pass_parts(plan)]), leaf(lambda p: pass_floor(p[:, 0], p[:, 2]) - p[:, 1]), role=CUT)
    pillar = cyl((plan['pillar'][0], hy, plan['pillar'][2]), 'y', 0.5, hy, 0.2)
    return ON_FLOOR(U(D(box, air, k=0.15), pillar))


def passes_faces(f, plan, inset=0.12, step=0.2):
    """The box's outer faces sampled just inside: how many points are open, and which of those are not at a mouth
    or a light shaft (a pass that broke out where it should not)."""
    hx, hy, hz = PASS_BOX
    pts, where = [], []
    us = np.arange(-hx + 0.4, hx - 0.4 + 1e-6, step)
    ws = np.arange(-hz + 0.4, hz - 0.4 + 1e-6, step)
    ys = np.arange(0.3, 2 * hy - 0.3 + 1e-6, step)
    for u in us:
        for y in ys:
            pts += [(u, y, hz - inset), (u, y, -hz + inset)]
            where += ['+z', '-z']
    for w in ws:
        for y in ys:
            pts += [(hx - inset, y, w), (-hx + inset, y, w)]
            where += ['+x', '-x']
    for u in us:
        for w in ws:
            pts.append((u, 2 * hy - inset, w))
            where.append('top')
    pts = np.array(pts)
    d, _, _ = evaluate(f, pts)
    lights = [(q[0], q[2]) for q in list(plan['tips']) + list(plan['skylights'])]
    stray = []
    for p, face, dv in zip(pts, where, d):
        if dv <= 0:
            continue
        if face == 'top' and any(np.hypot(p[0] - x, p[2] - z) < 0.8 for x, z in lights):
            continue
        if any(m['face'] == face and abs((p[0] if face in ('+z', '-z') else p[2]) - m['at']) < 1.9 for m in plan['mouths']):
            continue
        stray.append([round(float(v), 2) for v in p] + [face])
    return int((d > 0).sum()), stray


def part_colours(verts, normals, h):
    """COLOR for the rhizome surface: rgb = the nearest pass's hue (the box's own on its outer faces), a = how near the
    runner-up pass is - 1 at a tie, where two passes fused - which the shader lights."""
    parts = pass_parts()
    names = [n for n, _ in parts]
    probe = verts + normals * 0.05
    dist = np.stack([evaluate(f, probe)[0] for _, f in parts], axis=1)
    order = np.argsort(dist, axis=1)
    first = dist[np.arange(len(dist)), order[:, 0]]
    second = dist[np.arange(len(dist)), order[:, 1]]
    inside = first < 0.35                                  # on a carved wall: a pass is right there
    hues = np.array([PASS_HUES[n] for n in names])
    rgb = np.where(inside[:, None], hues[order[:, 0]], np.array(PASS_HUES['box']))
    tie = np.clip(1.0 - (second - first) / 0.9, 0.0, 1.0) * inside
    return np.concatenate([rgb, tie[:, None]], axis=1)


# ---------------------------------------------------------------- the columns: between a sine, a helix and chance
# Palle, 2026-11-14: "make these but carved sculptures using sine and randomness, what is inbetween a helix etc".
# Seven columns, each a black cylinder carved by a ball run along three grooves a third of a turn apart. One rule carves
# them all; what differs is the law that turns a groove as it climbs - a weighted sum of three movements:
#   SINE    theta = A sin(2 pi y / wave)    the groove swings out and comes back
#   HELIX   theta = 2 pi y / pitch           it keeps turning, one way
#   CHANCE  theta = W(y)                     how fast it turns is drawn as it climbs: a random walk, one per groove
# theta(y) = s SINE + h HELIX + c CHANCE, with s + h + c = 1. The pure laws stand at the corners of a triangle, half of
# each of two at the middles of its sides, a third of each at its centre - a ternary diagram made of columns. Every
# column draws the SAME three walks, so a column with chance in it carries a share of exactly the chance the pure one
# does: the mixtures are mixtures, not new draws. Seen from in front, a helix's groove is a sine as well (a helix seen
# from the side IS a sine); only walking round the two tells them apart.
# Coloured as PARTS for the rhizome surface, as the passes are: the column's skin black, a groove's wall in the colour
# of its law - sine blue, helix green, chance red, a mixture their weighted sum - and COLOR.a lit where two grooves met,
# which only chance makes them do.

# Palle, 2026-11-14, on first sight of them: "make them bigger". Every length x1.5 - 4.5 m tall, 1.35 m across - and the
# laws as they were: three swings, a turn and a half, the same walks (their rate per metre / 1.5, their knots x1.5).
COLUMN_SCALE = 1.5
COLUMN_R = 0.45 * COLUMN_SCALE  # the column's radius
COLUMN_H = 3.0 * COLUMN_SCALE   # and its height
COLUMN_RIM = 0.08 * COLUMN_SCALE  # its top edge, rounded
COLUMN_TOOL = 0.17 * COLUMN_SCALE  # the ball that carves
COLUMN_RIDE = 0.41 * COLUMN_SCALE  # the ball's centre from the axis: just inside the skin, a groove 0.21 (x1.5) deep and the
#                               core keeps 0.24 m whatever the grooves do
COLUMN_Y = (0.4 * COLUMN_SCALE, 2.6 * COLUMN_SCALE)  # the carved height: a solid foot and a solid head
COLUMN_GROOVES = 3
COLUMN_K = 0.06 * COLUMN_SCALE  # a groove's lip rounded over three voxels (at 0.03 the lip marched into a sawtooth)
SINE_A = 0.75                 # radians either way: a groove swings 43 degrees out and back
# a swing as long as A x pitch: the sine then turns at most as fast as the helix (4.28 rad/m at 1.0), so sine + helix halts
# once a swing instead of hooking back - and two swings, not three: at three the pure sine's strokes ran 71 degrees from
# vertical, a groove spread wider than the black between, and on a quarter of its height the face was all blue (a judge)
SINE_WAVE = SINE_A * 1.467 * COLUMN_SCALE  # metres a swing takes, out and back: two in the carved height
HELIX_PITCH = 1.467 * COLUMN_SCALE  # metres a turn takes: one and a half turns
# CHANCE draws the groove's TURNING RATE, not its angle: a rate every CHANCE_KNOT metres, eased between, summed up the
# column into the angle turned - a random walk of the direction, so a groove wanders as a hand would. The first cut drew
# the angle itself, a step every 6 cm: each step threw the groove 13 cm sideways, the grooves smeared into each other,
# and from in front the chance columns were sheets of colour with black islands, not paths.
CHANCE_RATE = 2.6 / COLUMN_SCALE  # radians per metre: the spread of a drawn turning rate (the helix turns at 4.3 / 1.5)
CHANCE_KNOT = 0.22 * COLUMN_SCALE  # metres between two drawn rates
# chosen as a stone is: legible by column_seed_survey() (one X, at eye height, no bare side) AND at half and a third of
# chance no two grooves ever run fused - 1659 passed the first and failed the second: its walks fused into a yellow leaf
# at half chance and a white ghost at a third (two judges, measured); 2154 is one of 23 in 1000 that pass both
COLUMN_SEED = 2154
COLUMN_BODY = (0.035, 0.03, 0.045)
COLUMN_HUES = {'sine': (0.15, 0.38, 1.0), 'helix': (0.2, 1.0, 0.36), 'chance': (1.0, 0.16, 0.26)}
COLUMNS = {                   # (sine, helix, chance)
    'column_sine': (1.0, 0.0, 0.0),
    'column_helix': (0.0, 1.0, 0.0),
    'column_chance': (0.0, 0.0, 1.0),
    'column_sine_helix': (0.5, 0.5, 0.0),
    'column_helix_chance': (0.0, 0.5, 0.5),
    'column_sine_chance': (0.5, 0.0, 0.5),
    'column_middle': (1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0),
}


def column_walks(seed=None):
    """The three walks every column draws, one per groove and the same in every column: W(y), the angle a groove has
    turned by height y when its turning rate is drawn (a unit normal every CHANCE_KNOT metres, a smooth spline between)
    and summed up the column."""
    from scipy.interpolate import CubicSpline
    y0, y1 = COLUMN_Y
    # counted, not stepped: at 1.5x, arange(y0, y1 + knot, knot) rounded to 11 knots instead of 12, one draw fewer per
    # groove, and every chance column silently got new walks (a review caught it: seed 1659 stopped being legible)
    knots = y0 + CHANCE_KNOT * np.arange(int(round((y1 - y0) / CHANCE_KNOT)) + 2)
    ys = np.linspace(y0, y1, 2400)
    rng = np.random.RandomState(COLUMN_SEED if seed is None else seed)
    out = []
    for _ in range(COLUMN_GROOVES):
        rate = CubicSpline(knots, rng.normal(0.0, 1.0, len(knots)))(ys)
        out.append((ys, np.r_[0.0, np.cumsum((rate[1:] + rate[:-1]) * 0.5 * np.diff(ys))]))
    return out


def column_seed_survey(seeds=range(1600, 1700), weights=(0.0, 0.0, 1.0)):
    """Why COLUMN_SEED: for each seed, read off the pure chance column's three grooves (their angles at 1200 heights) -
    how often two CROSS (their angles swap sides while near), the longest stretch two run FUSED (closer than a groove's
    width, 0.83 rad), and how much of the height leaves a BARE side (all three within a third of a turn, so one side of
    the column shows no groove). Chance, legible: crossings 2..6, no fused run over 0.6 m x COLUMN_SCALE (two grooves
    crossing at a shallow angle run together for about half a metre: that is the X), a bare side under 15 %."""
    rows = []
    for seed in seeds:
        ys, th = None, []
        for j, (wy, w) in enumerate(column_walks(seed)):
            ys = wy
            th.append(np.pi / 2 + 2 * np.pi * j / COLUMN_GROOVES + weights[2] * CHANCE_RATE * w)
        th = np.array(th)
        cross, fused = 0, 0.0
        for a in range(COLUMN_GROOVES):
            for b in range(a + 1, COLUMN_GROOVES):
                d = np.angle(np.exp(1j * (th[a] - th[b])))
                cross += int(np.sum((np.sign(d[1:]) != np.sign(d[:-1])) & (np.abs(d[1:]) < 0.5) & (np.abs(d[:-1]) < 0.5)))
                run = best = 0
                for near in np.abs(d) < 0.83:
                    run = run + 1 if near else 0
                    best = max(best, run)
                fused = max(fused, best * (ys[-1] - ys[0]) / len(ys))
        srt = np.sort(np.mod(th, 2 * np.pi), axis=0)
        gaps = np.diff(np.vstack([srt, srt[:1] + 2 * np.pi]), axis=0)
        bare = float((gaps.max(axis=0) > 4.19).mean())
        rows.append(dict(seed=seed, crossings=cross, fused=round(float(fused), 2), bare=round(bare, 3),
                         legible=2 <= cross <= 6 and fused <= 0.6 * COLUMN_SCALE and bare < 0.15))
    return rows


def column_strands(weights, spacing=0.02):
    """The grooves' centre lines in metres (the column's axis at x = z = 0, its foot at y = 0), resampled every
    `spacing` metres along their length. The first groove faces +z, the column's front."""
    s, hx, c = weights
    y0, y1 = COLUMN_Y
    ys = np.linspace(y0, y1, 2400)
    out = []
    for j, (wy, w) in enumerate(column_walks()):
        theta = (np.pi / 2 + 2 * np.pi * j / COLUMN_GROOVES
                 + s * SINE_A * np.sin(2 * np.pi * (ys - y0) / SINE_WAVE)
                 + hx * 2 * np.pi * (ys - y0) / HELIX_PITCH
                 + c * CHANCE_RATE * np.interp(ys, wy, w))
        pts = np.stack([COLUMN_RIDE * np.cos(theta), ys, COLUMN_RIDE * np.sin(theta)], axis=1)
        arc = np.r_[0.0, np.cumsum(np.linalg.norm(np.diff(pts, axis=0), axis=1))]
        at = np.linspace(0.0, arc[-1], max(2, int(arc[-1] / spacing) + 1))
        out.append(np.stack([np.interp(at, arc, pts[:, k]) for k in range(3)], axis=1))
    return out


def ball_run(points, r):
    """A ball of radius r run along a densely sampled line: the union of the balls at its points (2 cm apart against a
    17 cm ball, so the ripple between two is 0.3 mm), measured exactly through a k-d tree."""
    from scipy.spatial import cKDTree
    tree = cKDTree(np.asarray(points, float))
    return leaf(lambda p: tree.query(p)[0] - r)


def column_hue(weights):
    """A mixture's colour, mixed on the colour wheel: the weighted mean of its laws' hues, at their saturation - so half
    sine and half helix is cyan, half helix and half chance yellow, half sine and half chance violet - fading to white
    as the hues cancel (a third of each). An RGB sum made the mixtures pastel: the yellow read as beige in the tower."""
    import colorsys
    hsv = [colorsys.rgb_to_hsv(*COLUMN_HUES[k]) for k in ('sine', 'helix', 'chance')]
    vec = sum(w * np.exp(2j * np.pi * h) for w, (h, _, _) in zip(weights, hsv))
    # full saturation while the mean still points somewhere (two hues 139 degrees apart leave 0.35: helix + chance kept
    # only 0.6 of it on a wider ramp and read cream), white as it cancels (a third of each leaves 0.13)
    sat = sum(w * s for w, (_, s, _) in zip(weights, hsv)) * float(np.clip((abs(vec) - 0.15) / 0.15, 0.0, 1.0))
    return np.array(colorsys.hsv_to_rgb((np.angle(vec) / (2 * np.pi)) % 1.0, sat, 1.0))


def _column(name):
    body = cyl((0.0, (COLUMN_H - FLOOR_SINK) / 2, 0.0), 'y', COLUMN_R, (COLUMN_H + FLOOR_SINK) / 2, COLUMN_RIM)
    return ON_FLOOR(D(body, *[ball_run(s, COLUMN_TOOL) for s in column_strands(COLUMNS[name])], k=COLUMN_K))


def column_colours(name, verts, normals):
    """COLOR for the rhizome surface: rgb the column's black skin, or on a groove's wall the colour of the column's law;
    a = how near the runner-up groove is - 1 where two grooves met."""
    from scipy.spatial import cKDTree
    probe = verts + normals * 0.04 * COLUMN_SCALE       # into the groove's air: inside the ball that cut it
    dist = np.stack([cKDTree(s).query(probe)[0] - COLUMN_TOOL for s in column_strands(COLUMNS[name])], axis=1)
    dist.sort(axis=1)
    first, second = dist[:, 0], dist[:, 1]
    # 1 on a groove's wall (where the probe is 0.04 S inside its ball), 0 on the skin a few cm past the lip. The ramp first
    # stopped at 0.9 on the wall: the grooves wore 90 % of their colour and the crossing light (smoothstep 0.88..1 on
    # COLOR.a) peaked at 6 % - a review measured it
    on = np.clip((0.05 * COLUMN_SCALE - first) / (0.09 * COLUMN_SCALE), 0.0, 1.0)
    #                                                     (narrower showed the simplified mesh's triangles as a sawtooth)
    rgb = np.array(COLUMN_BODY) * (1.0 - on[:, None]) + column_hue(COLUMNS[name])[None, :] * on[:, None]
    tie = np.clip(1.0 - (second - first) / (0.3 * COLUMN_SCALE), 0.0, 1.0) * on
    # and a lit PATCH round each crossing, not only the 4 cm band where two balls tie (narrower than the mesh's vertex
    # spacing, so no render showed it): the trough wall is a ball's radius from the crossing point, the patch ~0.4 m wide
    # The shader lights only COLOR.a above 0.88 (smoothstep 0.88..1), so the patch is written IN that band, easing from
    # 0.98 at its core to 0.88 half a metre out - a linear 0..1 ramp left a 1.4 cm fade. And it is a disc of light round
    # the crossing, groove and skin alike: cut off at the grooves' lips it was a ragged star along the mesh's triangles.
    xs = column_crossings(name)
    if len(xs):
        near = cKDTree(np.array(xs)).query(verts)[0]
        r0, r1 = 0.15 * COLUMN_SCALE, 0.5 * COLUMN_SCALE
        x = np.clip((near - r0) / (r1 - r0), 0.0, 1.0)
        tie = np.maximum(tie, np.where(near < r1, 0.88 + 0.10 * (1.0 - x * x * (3.0 - 2.0 * x)), 0.0))
    return np.concatenate([rgb, tie[:, None]], axis=1)


def column_crossings(name):
    """Where two grooves' centre lines cross (their angles swap sides while near): the points, in metres."""
    s, hx, c = COLUMNS[name]
    ys, th = None, []
    for j, (wy, w) in enumerate(column_walks()):
        ys = wy
        th.append(np.pi / 2 + 2 * np.pi * j / COLUMN_GROOVES + s * SINE_A * np.sin(2 * np.pi * (wy - wy[0]) / SINE_WAVE)
                  + hx * 2 * np.pi * (wy - wy[0]) / HELIX_PITCH + c * CHANCE_RATE * w)
    out = []
    for a in range(COLUMN_GROOVES):
        for b in range(a + 1, COLUMN_GROOVES):
            d = np.angle(np.exp(1j * (th[a] - th[b])))
            for i in np.where((np.sign(d[1:]) != np.sign(d[:-1])) & (np.abs(d[1:]) < 0.5))[0]:
                m = th[b][i] + d[i] / 2.0
                out.append([COLUMN_RIDE * np.cos(m), ys[i], COLUMN_RIDE * np.sin(m)])
    return out


# ---------------------------------------------------------------- the catalogue of forms

FORMS = {
    'tunnel': dict(build=_tunnel, verb='difference', h=0.05, title='Tunnel',
                   expression='difference(round_box, arch)',
                   principle='A passage through a solid: a body is inside the work and still on its way.'),
    'crossing': dict(build=_crossing, verb='difference', h=0.05, title='Crossing',
                     expression='difference(block, union(arch_x, arch_z, room))',
                     principle='The cut is itself a union: four ways meet in a room, a vertex a body can stand in.'),
    'thresholds': dict(build=_thresholds, verb='difference', h=0.035, title='Thresholds',
                       expression='difference(wall, door, porthole, mousehole)',
                       principle='Each cut is sized for whom it lets through: a body by the door, a hand by the porthole, a small ball under the wall.'),
    'sieve': dict(build=_sieve, verb='difference', h=0.02, hc=0.022, cbudget=4000, ao_reach=0.3, title='Sieve',
                  expression='difference(tilted plate, repeat(sphere)) + legs',
                  principle='A repeated cut is a filter: a rubber ball falls through, a trace ball rolls off.'),
    'dome': dict(build=_dome, verb='difference', h=0.055, title='Dome',
                 expression='difference(sphere, sphere, door, oculus)',
                 principle='Two differences make an inside: one takes the room out of the body, one lets you into the room.'),
    'basin': dict(build=_basin, verb='difference', h=0.025, title='Basin',
                  expression='difference(round_box, sphere)',
                  principle='The removed volume keeps: a ball that falls in stays.'),
    'gutter_ramp': dict(build=_gutter_ramp, verb='difference', h=0.03, title='Gutter ramp',
                        expression='difference(wedge, capsule)',
                        principle='One cut makes two paths at two sizes: the ramp for a body, the gutter for a ball.'),
    'mould': dict(build=_mould, verb='difference', h=0.02, title='Mould',
                  expression='difference(block, sphere)  (A - B)',
                  principle='Its cast is intersection(block, sphere): the two partition the block, so the cast fills the cup.'),
    'cast': dict(build=_cast, verb='intersection', h=0.015, title='Cast', rigid=True, mass=9.0,
                 expression='intersection(block, sphere)  (A & B)',
                 principle='What two convex shapes share is convex, so it can move: a rigid body that rolls and fits the mould.'),
    'hump_bridge': dict(build=_hump_bridge, verb='intersection', h=0.03, title='Hump bridge',
                        expression='difference(intersection(beam, sphere), culvert)',
                        principle='The sphere gives the beam its rise: a curved deck to walk over, a culvert for a ball underneath.'),
    'die': dict(build=_die, verb='intersection', h=0.012, title='Die', rigid=True, mass=6.0,
                expression='difference(intersection(cube, sphere), pips)',
                principle='The cube gives faces to rest on, the sphere takes the corners off so it can roll: thrown, it lands on a number.'),
    'gyroid_screen': dict(build=_gyroid_screen, verb='intersection', h=0.03, hc=0.03, cbudget=4000, ao_reach=0.2, title='Gyroid screen',
                          expression='intersection(box, shell(gyroid)) + frame',
                          principle='A periodic field cut to a panel: open everywhere and closed everywhere; the eye passes, a body does not.'),
    'stile': dict(build=_stile, verb='union', h=0.025, title='Stile',
                  expression='union(steps)  beside  smooth_union(floor, steps, k = 0.5)',
                  principle='Both halves are connected; only the smoothed one lets a body over. Connected is not passable.'),
    'mound': dict(build=_mound, verb='union', h=0.04, title='Mound',
                  expression='smooth_union(floor, sphere, k = 0.75)',
                  principle='The floor is an operand: blended into it, a hill has no edge to trip on.'),
    'stones': dict(build=_stones, verb='union', h=0.025, title='Stones',
                   expression='smooth_union(floor, metaballs(3))',
                   principle='Summed fields: near enough, two stones share one boundary; the third stands alone.'),
    'pipe_tee': dict(build=_pipe_tee, verb='union', h=0.02, hc=0.022, cbudget=4000, ao_reach=0.3, title='Pipe tee',
                     expression='difference(union(pipes, legs), union(bores))',
                     principle='Join first, then bore: the junction is open. Bored first and then joined, each wall would close it.'),
    'spiral_ramp': dict(build=_spiral_ramp, verb='field', h=0.035, title='Spiral ramp',
                        expression='smooth_union(helix(rise 1 m, 300 deg), post)',
                        principle='Twist the space and rising becomes going round: a metre up in one turn, and back down.'),
    'funnel': dict(build=_funnel, verb='field', h=0.02, hc=0.025, cbudget=4000, title='Funnel',
                   expression='revolve(shell(profile)) + legs',
                   principle='A profile turned about an axis is a vessel with a throat: whatever is poured in leaves one at a time.'),
    'chute': dict(build=_chute, verb='field', h=0.02, hc=0.022, cbudget=4000, title='Chute',
                  expression='difference(sweep(trough, curve) + legs, sweep(bore, curve))',
                  principle='A section carried along a curve: a slide for a ball, from 1.2 m down into a basin.'),
    'passes': dict(build=_passes, verb='difference', h=0.08, hc=0.12, cbudget=8000, budget=64000, extent=(9.5, 5.6, 6.0), colours='parts',
                   skin_shader='rhizome', title='Passes',
                   expression='difference(box, spiral + grid + walk + sine + branches)',
                   principle='Five movements carve a box from the inside out: each pass keeps its colour, and where two met the wall lights.'),
    'boulder': dict(build=_boulder, verb='field', h=0.025, title='Boulder',
                    expression='smooth_union(floor, ellipsoid + noise)',
                    principle='A boundary made from values: the noise moves every point of it in or out.'),
}
_CARVE_TEXT = {
    'walk': ('difference(cube, faceted spheres along a random walk)', 'Six directions, chosen at random, never crossing itself: the walk is the cave.'),
    'spiral': ('difference(cube, faceted spheres along a sine spiral)', 'x = cos(angle) r, z = sin(angle) r, rising as the radius decays: a cave wound by a sine.'),
    'branches': ('difference(cube, spheres along a trunk and random branches)', "A trunk should climb and branches leave it. At the demo's own numbers (a 2 m step in a 10 m cube) it climbs out in two steps and no branch starts: three cutters, a shaft."),
    'perlin': ('difference(cube, spheres along a sine-steered path)', 'Each step turns by sin and cos of where it stands: a path that follows a field.'),
    'grid': ('difference(cube, spheres along a 3 x 3 grid of tunnels)', 'Nine straight tunnels, evenly spaced: the same verb, no chance at all.'),
}
for _name, _spec in CARVINGS.items():
    _expr, _why = _CARVE_TEXT[_spec['pattern']]
    _why = _spec.get('principle', _why)
    if _spec.get('base') == 'sphere':
        _expr = _expr.replace('difference(cube,', 'difference(sphere,')
    if _spec.get('section'):
        _expr = 'intersection(' + _expr + ', half-space)'
    FORMS[_name] = dict(build=_carving_builder(_name), verb='difference', h=0.022, hc=0.045, cbudget=5000, budget=9000,
                        extent=(1.8, 3.2, 1.8), title=_spec['label'], expression=_expr, principle=_why,
                        rigid=False, carving=True)
_COLUMN_TEXT = {
    'column_sine': ('Sine', 'difference(column, ball along theta = A sin(2 pi y / wave))',
                    'The groove swings out and comes back. From in front it draws a sine; from the side, a pendulum that climbs.'),
    'column_helix': ('Helix', 'difference(column, ball along theta = 2 pi y / pitch)',
                     "The groove keeps turning one way: every stroke you see leans the same way. The sine's lean out and come back."),
    'column_chance': ('Chance', 'difference(column, ball along theta = W(y), W summed from drawn turns)',
                      'How fast each groove turns is drawn as it climbs: three random walks. At eye height two of them cross: they fuse, and the wall lights.'),
    'column_sine_helix': ('Sine + helix', 'theta = A/2 sin(2 pi y / wave) + pi y / pitch',
                          'Turning and swinging at once: the groove turns, halts, turns again.'),
    'column_helix_chance': ('Helix + chance', 'theta = pi y / pitch + W(y) / 2',
                            'A turn that drifts: the groove still winds, but no two of its steps are alike.'),
    'column_sine_chance': ('Sine + chance', 'theta = A/2 sin(2 pi y / wave) + W(y) / 2',
                           'A swing with chance in it: the rhythm survives, each beat lands somewhere else.'),
    'column_middle': ('A third of each', 'theta = (sine + helix + chance) / 3',
                      'What lies between a sine, a helix and chance: all three laws at a third - and all three lights: blue, green and red make white.'),
}
for _name in COLUMNS:
    _title, _expr, _why = _COLUMN_TEXT[_name]
    # pure chance is the one that lights where its grooves cross: a denser mesh there, so the light's rim is smooth
    FORMS[_name] = dict(build=(lambda n=_name: _column(n)), verb='difference', h=0.024, hc=0.06, cbudget=3000,
                        budget=40000 if COLUMNS[_name][2] == 1.0 else 24000,
                        extent=(COLUMN_R + 0.5, COLUMN_H + 0.4, COLUMN_R + 0.5), colours='column', skin_shader='rhizome', title=_title, expression=_expr,
                        principle=_why, column=True)


# ---------------------------------------------------------------- marching, measuring

def evaluate(f, p, chunk=400000):
    ds, rs, bs = [], [], []
    for i in range(0, len(p), chunk):
        d, r, b = f(p[i:i + chunk])
        ds.append(d), rs.append(r), bs.append(b)
    return np.concatenate(ds), np.concatenate(rs), np.concatenate(bs)


def bounds(f, h, rigid, extent=(3.0, 4.6, 3.0)):
    """Find the box the form lives in by a coarse search, then pad it."""
    c = 0.08 if extent[0] <= 3.0 else 0.15
    xs = np.arange(-extent[0], extent[0] + c, c)
    ys = np.arange(-0.5, extent[1] + c, c)
    zs = np.arange(-extent[2], extent[2] + c, c)
    g = np.stack(np.meshgrid(xs, ys, zs, indexing='ij'), axis=-1).reshape(-1, 3)
    d, _, _ = evaluate(f, g)
    inside = g[d < c]
    lo, hi = inside.min(axis=0) - 3 * h, inside.max(axis=0) + 3 * h
    if not rigid:
        lo[1] = -FLOOR_SINK - 2 * h - 0.013 * h        # under the sunk bottom, and never a sample on the floor's plane
    return lo, hi


def march(f, h, rigid, extent=(3.0, 4.6, 3.0), grounded_only=False):
    lo, hi = bounds(f, h, rigid, extent)
    axes = [np.arange(lo[i], hi[i] + h, h) for i in range(3)]
    g = np.stack(np.meshgrid(*axes, indexing='ij'), axis=-1).reshape(-1, 3)
    d, _, _ = evaluate(f, g)
    vol = d.reshape([len(a) for a in axes])
    if grounded_only:                                   # a carving keeps only solid that reaches the floor: a cutter can
        labels, n = measure.label(vol < 0, return_num=True)     # leave a piece floating in the air, which no body could stand
        low = axes[1] < 0.1
        standing = set(np.unique(labels[:, low, :])) - {0}
        for k in range(1, n + 1):
            if k not in standing:
                vol[labels == k] = h
    verts, faces, _, _ = measure.marching_cubes(vol, level=0.0, spacing=(h, h, h), allow_degenerate=False)
    verts = verts + np.array([a[0] for a in axes])
    return verts, faces


def gradient(f, p, e):
    out = np.zeros_like(p)
    for i in range(3):
        dp = np.zeros(3)
        dp[i] = e
        out[:, i] = evaluate(f, p + dp)[0] - evaluate(f, p - dp)[0]
    n = np.linalg.norm(out, axis=1)
    return out / np.maximum(n, 1e-12)[:, None]


def clip_above(verts, normals, colours, faces, y0):
    """Keep what lies above y0, splitting the triangles that cross it (a clean outline where a blend meets the floor,
    instead of the sawtooth that dropping whole triangles leaves)."""
    above = verts[:, 1] > y0
    flags = above[faces]
    out = [faces[flags.all(axis=1)]]
    extra_v, extra_n, extra_c, cuts = [], [], [], {}

    def cut(i, j):
        key = (min(i, j), max(i, j))
        if key not in cuts:
            t = (verts[i, 1] - y0) / (verts[i, 1] - verts[j, 1])
            extra_v.append(verts[i] + t * (verts[j] - verts[i]))
            n = normals[i] + t * (normals[j] - normals[i])
            extra_n.append(n / max(np.linalg.norm(n), 1e-9))
            extra_c.append(colours[i] + t * (colours[j] - colours[i]))
            cuts[key] = len(verts) + len(extra_v) - 1
        return cuts[key]
    pieces = []
    for f in faces[flags.any(axis=1) & ~flags.all(axis=1)]:
        poly = []
        for k in range(3):
            i, j = int(f[k]), int(f[(k + 1) % 3])
            if above[i]:
                poly.append(i)
            if above[i] != above[j]:
                poly.append(cut(i, j))
        for k in range(1, len(poly) - 1):
            pieces.append((poly[0], poly[k], poly[k + 1]))
    if pieces:
        out.append(np.array(pieces, dtype=faces.dtype))
    faces = np.concatenate(out)
    if extra_v:
        verts = np.r_[verts, np.array(extra_v, verts.dtype)]
        normals = np.r_[normals, np.array(extra_n, normals.dtype)]
        colours = np.r_[colours, np.array(extra_c, colours.dtype)]
    used = np.unique(faces)
    remap = -np.ones(len(verts), int)
    remap[used] = np.arange(len(used))
    return verts[used], normals[used], colours[used], remap[faces]


def ambient_occlusion(f, p, n, floor=True, reach=0.6, steps=5):
    """How open the air round a point is, read from the field along its normal (Inigo Quilez's distance-field
    occlusion): where solid is nearer than the distance walked out, light is shut out. The floor counts as solid for a
    form standing on it - the dark line where a wall meets the ground. 1 open, 0 shut in."""
    occ = np.zeros(len(p))
    total = 0.0
    for i in range(1, steps + 1):
        hh = reach * i / steps
        q = p + n * hh
        d, _, _ = evaluate(f, q)
        if floor:
            d = np.minimum(d, q[:, 1])
        w = 1.0 / i
        occ += w * np.clip((hh - d) / hh, 0.0, 1.0)
        total += w
    return np.clip(1.0 - 1.5 * occ / total, 0.0, 1.0)


def data_colours(f, verts, normals, h, rigid, reach=0.6):
    """Vertex colour as data: r = a difference cut this face, g = an intersection trimmed it, b = a smooth union's band,
    a = ambient occlusion."""
    _, role, band = evaluate(f, verts - normals * h * 0.05)
    ao = ambient_occlusion(f, verts + normals * h * 0.1, normals, floor=not rigid, reach=reach)
    return np.stack([(role == CUT).astype(float), (role == TRIM).astype(float), band, ao], axis=1), role, band


def mesh_of(name, h=None, purpose='render'):
    spec = FORMS[name]
    f = spec['build']()
    h = h or spec['h']
    rigid = spec.get('rigid', False)
    verts, faces = march(f, h, rigid, spec.get('extent', (3.0, 4.6, 3.0)), grounded_only=bool(spec.get('carving')))
    normals = gradient(f, verts, h * 0.5)
    # each face wound so that its geometric normal agrees with the field's gradient (outward)
    tri = verts[faces]
    gn = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])
    outward = normals[faces].sum(axis=1)
    flip = np.einsum('ij,ij->i', gn, outward) < 0
    faces[flip] = faces[flip][:, ::-1]
    if not rigid and purpose == 'collision':            # what lies wholly under the floor is never touched
        faces = faces[tri[:, :, 1].max(axis=1) > -0.005]
    used = np.unique(faces)
    remap = -np.ones(len(verts), int)
    remap[used] = np.arange(len(used))
    verts, normals, faces = verts[used], normals[used], remap[faces]
    if purpose == 'collision':
        _, role, band = evaluate(f, verts - normals * h * 0.05)
        colours = np.zeros((len(verts), 4))
    else:
        if not rigid:                                   # what lies under the floor (or on it) is never seen
            verts, normals, _, faces = clip_above(verts, normals, np.zeros((len(verts), 4)), faces, 0.003)
        colours, role, band = data_colours(f, verts, normals, h, rigid, spec.get('ao_reach', 0.6))
        if spec.get('colours') == 'parts':
            colours = part_colours(verts, normals, h)
        elif spec.get('colours') == 'column':
            colours = column_colours(name, verts, normals)
        if spec.get('carving'):                         # P8 (d): the demo's cutters are smooth-shaded (smooth_faces): a cave
            cut = colours[:, 0] > 0.5                    # wall's normal points to the centre of its nearest cutter
            if cut.any():
                cs = carving_cutters(name)
                centres = np.array([c for c, _ in cs])
                radii = np.array([r for _, r in cs])
                pv = verts[cut]
                nearest = np.argmin(np.linalg.norm(pv[:, None, :] - centres[None, :, :], axis=2) - radii[None, :], axis=1)
                towards = centres[nearest] - pv
                normals = normals.copy()
                normals[cut] = towards / np.maximum(np.linalg.norm(towards, axis=1), 1e-9)[:, None]
    return dict(f=f, verts=verts.astype(np.float32), normals=normals.astype(np.float32), faces=faces.astype(np.uint32),
                colours=colours.astype(np.float32), role=role, band=band)


def centroid(m):
    """Volume centre of a closed mesh (signed tetrahedra against the origin)."""
    tri = m['verts'][m['faces']].astype(np.float64)
    v = np.einsum('ij,ij->i', tri[:, 0], np.cross(tri[:, 1], tri[:, 2])) / 6.0
    return (tri.sum(axis=1) / 4.0 * v[:, None]).sum(axis=0) / v.sum(), float(v.sum())


def area_by_role(m):
    tri = m['verts'][m['faces']]
    a = 0.5 * np.linalg.norm(np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0]), axis=1)
    r = m['role'][m['faces'][:, 0]]
    b = m['band'][m['faces']].mean(axis=1)
    out = {'body': float(a[(r == BODY) | (r == FLOOR)].sum()), 'cut': float(a[r == CUT].sum()), 'trim': float(a[r == TRIM].sum()),
           'band': float((a * b).sum())}
    return {k: round(v, 3) for k, v in out.items()}


# ---------------------------------------------------------------- checks: what the walker and the balls will meet

def _directions(n=400):
    i = np.arange(n) + 0.5
    phi = np.arccos(1 - 2 * i / n)
    theta = np.pi * (1 + 5 ** 0.5) * i
    return np.stack([np.cos(theta) * np.sin(phi), np.cos(phi), np.sin(theta) * np.sin(phi)], axis=1)


DIRS = _directions()


def free_radius(f, centres, r_max=0.7):
    """The largest sphere round every centre that holds no solid, found by sampling the sphere's volume against the
    zero set (a distance field's VALUES inside a union or an extrusion are only a bound, so they under-report)."""
    centres = np.asarray(centres, float)
    lo, hi = 0.0, r_max
    for _ in range(14):
        mid = (lo + hi) / 2
        pts = (centres[:, None, None, :] + DIRS[None, None, :, :] * (mid * np.array([0.35, 0.7, 1.0]))[None, :, None, None]).reshape(-1, 3)
        d, _, _ = evaluate(f, np.r_[pts, centres])
        if d.min() > 0:
            lo = mid
        else:
            hi = mid
    return lo


def clear_capsule(f, path_xz, floor_y=0.0, r=WALKER_R, height=WALKER_H, margin=0.02):
    """Clearance left round a standing body walked along a path: the free radius round its capsule's centre line,
    less the capsule's radius."""
    ys = np.linspace(floor_y + r, floor_y + height - r, 7)
    pts = np.array([(x, y, z) for x, z in path_xz[::2] for y in ys])
    return float(free_radius(f, pts) - r), float(margin)


def surface_height(f, xz, top=3.0, step=0.01):
    """Height of the first surface met coming down from `top` at each plan point (0 where only floor)."""
    ys = np.arange(top, -0.001, -step)
    out = []
    for x, z in xz:
        d, _, _ = evaluate(f, np.stack([np.full_like(ys, x), ys, np.full_like(ys, z)], axis=1))
        inside = np.nonzero(d < 0)[0]
        if len(inside) == 0:
            out.append(0.0)
            continue
        i = inside[0]
        if i == 0:
            out.append(top)
            continue
        y0, y1, d0, d1 = ys[i - 1], ys[i], d[i - 1], d[i]
        out.append(float(y0 + (y1 - y0) * d0 / (d0 - d1)))
    return np.array(out)


def under_foot(f, xz, r=0.12):
    """What a foot meets: the highest surface within r of each point (a capsule bottom is round, not a needle)."""
    rings = [(0, 0)] + [(r * np.cos(a), r * np.sin(a)) for a in np.linspace(0, 2 * np.pi, 8, endpoint=False)]
    hs = np.stack([surface_height(f, [(x + dx, z + dz) for x, z in xz]) for dx, dz in rings])
    return hs.max(axis=0)


def walk_profile(f, path_xz):
    """Slope and lips of what a body walks on along a path."""
    path_xz = np.asarray(path_xz, float)
    centre = surface_height(f, path_xz)                 # the slope is read along the path itself ...
    hs = under_foot(f, path_xz)                         # ... the lips under the round foot (a ring of 8 points jumps
    run = np.linalg.norm(np.diff(path_xz, axis=0), axis=1)  # as it turns, so it makes false slopes, not false lips)
    slope = np.degrees(np.arctan2(np.abs(np.diff(centre)), np.maximum(run, 1e-9)))
    return dict(start=float(hs[0]), end=float(hs[-1]), top=float(hs.max()), max_slope=float(slope.max()),
                max_lip=float(np.abs(np.diff(hs)).max()), heights=hs)


def ball_path(f, centres, ball):
    """Room left round a ball whose centre follows the path (negative: it does not fit)."""
    room = free_radius(f, centres, r_max=ball + 0.3)
    if room > 1e-3:
        return float(room - ball)
    d, _, _ = evaluate(f, np.asarray(centres, float))     # the centre itself is in solid: say by how much
    return float(min(d.min(), 0.0) - ball)


def line(a, b, n=60):
    a, b = np.asarray(a, float), np.asarray(b, float)
    return [tuple(a + (b - a) * t) for t in np.linspace(0, 1, n)]


def arc(r, a0, a1, n=120):
    return [(r * np.cos(a), r * np.sin(a)) for a in np.radians(np.linspace(a0, a1, n))]


def checks(name, m):
    f = m['f']
    out = []

    def need(label, value, ok, want):
        out.append(dict(check=label, value=round(float(value), 3), ok=bool(ok), want=want))

    if name == 'tunnel':
        c, margin = clear_capsule(f, line((-2.3, 0), (2.3, 0)))
        need('a standing body clears the passage', c, c >= 0.45, '>= 0.45 m (the sampler reads up to 0.5)')
        c, _ = clear_capsule(f, line((-2.3, 0.5), (2.3, 0.5)))
        need('... and 50 cm off its middle', c, c >= 0.1, '>= 0.1')
    elif name == 'crossing':
        c1, margin = clear_capsule(f, line((-2.4, 0), (2.4, 0)))
        c2, _ = clear_capsule(f, line((0, -2.4), (0, 2.4)))
        need('west-east way clear', c1, c1 >= 0.35, '>= 0.35 m')
        need('north-south way clear', c2, c2 >= 0.35, '>= 0.35 m')
        c3, _ = clear_capsule(f, arc(0.8, 0, 360))
        need('a body can walk round in the room (r 0.8)', c3, c3 >= 0.05, '>= 0.05')
    elif name == 'thresholds':
        c, margin = clear_capsule(f, line((DOOR_X, -0.6), (DOOR_X, 0.6)))
        need('a body passes the door', c, c >= 0.3, '>= 0.3 m')
        pr = ball_path(f, line((PORT_X, 1.2, -0.5), (PORT_X, 1.2, 0.5)), TRACE)
        need('the porthole passes a trace ball held at its middle', pr, pr >= 0.01, '>= 0.01 m')
        mr = ball_path(f, line((PORT_X, RUBBER, -0.5), (PORT_X, RUBBER, 0.5)), RUBBER)
        need('a rubber ball rolls under the wall', mr, mr >= 0.015, '>= 0.015 m')
        mt = ball_path(f, line((PORT_X, TRACE, -0.5), (PORT_X, TRACE, 0.5)), TRACE)
        need('a trace ball does not', mt, mt < 0.0, '< 0')
    elif name == 'sieve':
        opening = 2 * np.sqrt(SIEVE_HOLE ** 2 - 0.03 ** 2)
        need('hole opening (m)', opening, 2 * RUBBER + 0.02 <= opening <= 2 * TRACE - 0.02, 'rubber 0.22 + 2 cm .. trace 0.28 - 2 cm')
    elif name == 'dome':
        c, margin = clear_capsule(f, line((0, 3.2), (0, 0.0)))
        need('a body walks in to the middle', c, c >= 0.3, '>= 0.3 m')
        c2, _ = clear_capsule(f, arc(1.2, 0, 360))
        need('and round inside it (r 1.2)', c2, c2 >= 0.1, '>= 0.1 m')
        hs = surface_height(f, [(0, 0)], top=4.0)
        need('ceiling over the middle (the oculus is open)', hs[0], hs[0] < 0.01, 'open')
    elif name == 'passes':
        plan = passes_plan()
        worst = {}
        for k, pts in plan['paths'].items():
            hs = plan['floors'].get(k, [0.0] * len(pts))
            dense = []
            for (a, ha), (b, hb) in zip(zip(pts[:-1], hs[:-1]), zip(pts[1:], hs[1:])):
                # a body on a slope rests on it a little higher than on the flat: r (sec(slope) - 1)
                lift = WALKER_R * (np.sqrt(1.0 + ((hb - ha) / max(np.hypot(b[0] - a[0], b[2] - a[2]), 1e-6)) ** 2) - 1.0)
                for t in np.linspace(0, 1, 6, endpoint=False):
                    dense.append((a[0] + (b[0] - a[0]) * t, a[2] + (b[2] - a[2]) * t, ha + (hb - ha) * t + lift))
            dense.append((pts[-1][0], pts[-1][2], hs[-1]))
            # a body stands ON its floor: the lowest sample is lifted 6 cm, so what is measured is walls and ceiling
            # (on a level pass the floor is a 4 mm sheet over the slab and the sampling missed it either way)
            ys = np.linspace(WALKER_R + 0.06, WALKER_H - WALKER_R, 7)
            centres = np.array([(x, max(fl, float(pass_floor(x, z))) + y, z) for x, z, fl in dense[::2] for y in ys])
            worst[k] = round(free_radius(f, centres) - WALKER_R, 3)
        need('every pass leaves a standing body room (worst, m)', min(worst.values()), min(worst.values()) >= 0.05, '>= 0.05 m ' + json.dumps(worst))
        flat = [k for k in plan['paths'] if k not in plan['floors']]
        off = 0.0
        for k in flat:
            xz = np.array([(q[0], q[2]) for q in plan['paths'][k] if abs(q[0]) < PASS_BOX[0] and abs(q[2]) < PASS_BOX[2]])
            off = max(off, float(np.abs(surface_height(f, xz, top=1.0) - pass_floor(xz[:, 0], xz[:, 1])).max()))
        need('the level passes stand on their own floor, 6 cm up inside (worst off, m)', off, off < 0.02, '< 0.02')
        wk = [(q, hq) for q, hq in zip(plan['paths']['walk'], plan['floors']['walk']) if abs(q[2]) < PASS_BOX[2]]
        got = surface_height(f, [(q[0], q[2]) for q, _ in wk], top=1.6)
        want = np.array([max(hq, float(pass_floor(q[0], q[2]))) for q, hq in wk])
        need('the walk climbs and drops (highest floor, m)', float(got.max()), got.max() >= 0.55, '>= 0.55')
        need('and its floor is where its steps put it (worst, m)', float(np.abs(got - want).max()), np.abs(got - want).max() < 0.06, '< 0.06')
        opened, stray = passes_faces(f, plan)
        need('the box is closed but at its mouths and light shafts (stray openings)', len(stray), not stray, '0 ' + json.dumps(stray[:4]))
        mouths = 0
        for mo in plan['mouths']:
            p = (mo['at'], 1.0, PASS_BOX[2] - 0.12) if mo['face'] == '+z' else (PASS_BOX[0] - 0.12, 1.0, mo['at'])
            mouths += int(evaluate(f, np.array([p]))[0][0] > 0)
        need('mouths open (grid, walk, sine)', mouths, mouths == 3, '3')
        lit = int(sum(evaluate(f, np.array([(x, 2 * PASS_BOX[1] - 0.05, z)]))[0][0] > 0 for x, _, z in plan['tips']))
        need('the branches come out through the roof (tips open)', lit, lit == len(plan['tips']), str(len(plan['tips'])))
    elif name in CARVINGS:
        spec = CARVINGS[name]
        paths, points = carving_paths(spec)
        v = m['verts']
        need('cutters set along the path(s)', len(points), len(points) >= 9, '>= 9')
        if spec['pattern'] == 'branches':
            need('the trunk branches', len(paths), len(paths) >= 2, '>= 2 paths')
        k = CARVE_SCALE
        lift = 10.0 * k / 2
        inside = evaluate(f, np.array([[q[0] * k, q[1] * k + lift, q[2] * k] for q, _ in points]))[0]
        need('every cutter left air where it stood', inside.min(), inside.min() > 0.0, '> 0 (outside the solid)')
        need('it is still one block (largest dimension m)', (v.max(axis=0) - v.min(axis=0)).max(), (v.max(axis=0) - v.min(axis=0)).max() <= 10.0 * k + 0.05, '<= 2.85')
    elif name in COLUMNS:
        strands = column_strands(COLUMNS[name])
        inside = evaluate(f, np.concatenate(strands))[0]
        need('every groove left air where its ball ran', inside.min(), inside.min() > 0.0, '> 0 (outside the solid)')
        ys = np.linspace(COLUMN_Y[0], COLUMN_Y[1], 150)     # over the carved height (foot and head are whole)
        axis = evaluate(f, np.stack([np.zeros_like(ys), ys, np.zeros_like(ys)], axis=1))[0]
        need('the core holds: solid round the axis at every carved height (thinnest, m)', -axis.max(), -axis.max() >= 0.15 * COLUMN_SCALE, '>= %.2f' % (0.15 * COLUMN_SCALE))
        v = m['verts']
        span = max(v[:, 0].max() - v[:, 0].min(), v[:, 2].max() - v[:, 2].min())
        need('one column, no wider than it was cut from (m)', span, span <= 2 * COLUMN_R + 0.01, '<= %.2f' % (2 * COLUMN_R + 0.01))
        cut = float((m['colours'][:, :3] != np.array(COLUMN_BODY, np.float32)).any(axis=1).mean())
        need('the grooves wear their law (share of vertices coloured)', cut, 0.2 <= cut <= 0.8, '0.2 .. 0.8')
        a = m['colours'][:, 3].astype(float)              # what the rhizome shader lights: smoothstep(0.88, 1, COLOR.a)
        x = np.clip((a - 0.88) / 0.12, 0.0, 1.0)
        lit = float((x * x * (3.0 - 2.0 * x)).max())
        chance = COLUMNS[name][2]
        need('grooves meet, and the wall lights, only by chance (brightest crossing light, 0..1)', lit,
             lit == 0.0 if chance == 0 else (lit >= 0.5 if chance == 1.0 else True), '0 without chance, >= 0.5 for chance alone')
    elif name == 'boulder':
        w = walk_profile(f, line((-1.2, 0), (1.2, 0), 120))
        need('a seat, not a step: height (m)', w['top'], 0.35 <= w['top'] <= 0.75, '0.35 .. 0.75')
    v = m['verts']
    lo, hi = v.min(axis=0), v.max(axis=0)
    top = surface_height(f, [(0.0, 0.0)], top=6.0)[0]
    need('the march reached its top (field top vs mesh top, m)', abs(top - hi[1]) if top > 0.05 else 0.0, top <= hi[1] + 0.02 or top < 0.05, 'the mesh is as tall as the field')
    need('fits under the ceiling (m)', hi[1], hi[1] < 5.3, '< 5.3')
    if not FORMS[name].get('rigid'):
        need('stands on the floor (lowest drawn y)', lo[1], 0.0 <= lo[1] <= 0.01, '0 .. 0.01')
    return out


# ---------------------------------------------------------------- collision and output

def _die_hull():
    """The die's hull from points that carry all of the cube's symmetries (a hull from sampled points favours one face:
    measured, three throws of the first die all landed on 5)."""
    pts = []
    for a in range(3):
        for sign in (-1, 1):
            for u, v in [(0.12, 0.12), (0.12, -0.12), (-0.12, 0.12), (-0.12, -0.12), (0.17, 0), (-0.17, 0), (0, 0.17), (0, -0.17)]:
                p = [0.0, 0.0, 0.0]
                p[a] = 0.25 * sign
                p[(a + 1) % 3], p[(a + 2) % 3] = u, v
                pts.append(p)
    for a in range(3):
        for s1 in (-1, 1):
            for s2 in (-1, 1):
                p = [0.0, 0.0, 0.0]
                p[a], p[(a + 1) % 3] = 0.233 * s1, 0.233 * s2
                pts.append(p)
    pts += [[0.19 * x, 0.19 * y, 0.19 * z] for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)]
    pts = np.array(pts) + np.array([0, 0.25, 0])
    d, _, _ = evaluate(moved(_die_body(), t=(0, 0.25, 0)), pts)
    assert np.abs(d).max() < 0.003, np.abs(d).max()     # every point on the uncut die's surface, within 3 mm
    return pts.astype(np.float32)


def collision_of(name, render):
    spec = FORMS[name]
    if name == 'die':
        return np.zeros((0, 3), np.float32), _die_hull()
    if spec.get('rigid'):
        from scipy.spatial import ConvexHull
        coarse = mesh_of(name, h=max(spec['h'] * 2.0, 0.03), purpose='collision')
        points = coarse['verts'][ConvexHull(coarse['verts']).vertices]
        # a physics hull wants few points: keep the 64 that lie farthest from each other, then hull those
        keep = [int(np.argmax(np.linalg.norm(points - points.mean(axis=0), axis=1)))]
        gap = np.linalg.norm(points - points[keep[0]], axis=1)
        while len(keep) < min(64, len(points)):
            keep.append(int(np.argmax(gap)))
            gap = np.minimum(gap, np.linalg.norm(points - points[keep[-1]], axis=1))
        points = points[keep]
        return np.zeros((0, 3), np.float32), points[ConvexHull(points).vertices].astype(np.float32)
    coarse = mesh_of(name, h=spec.get('hc', min(max(spec['h'] * 2.0, 0.05), 0.08)), purpose='collision')
    soup = coarse['verts'][coarse['faces']].reshape(-1, 3)
    return soup.astype(np.float32), np.zeros((0, 3), np.float32)


def extras_of(name):
    """What a form's artifact needs beyond its mesh: for a carving, the path(s) its cutters were set along (the demo
    draws them as an orange line, path_line_color (1, 0.5, 0); Grid Tunnels does not); for the passes, their lines, so a
    probe can walk each one."""
    if name == 'passes':
        plan = passes_plan()
        outside_in = {'grid': plan['paths']['grid'], 'walk': plan['paths']['walk'], 'sine': plan['paths']['sine'][::-1],
                      'spiral': plan['paths']['spiral'], 'grid_stub': plan['paths']['grid_stub']}
        return {'shader': FORMS[name].get('skin_shader', ''),
                'walks': {k: [[round(float(q[0]), 3), round(float(q[2]), 3)] for q in v] for k, v in outside_in.items()},
                'walk_floors': [round(float(h), 3) for h in plan['floors']['walk']],
                'chamber': [round(float(v), 3) for v in plan['room']],
                'skylights': [[round(float(q[0]), 3), round(float(q[2]), 3)] for q in list(plan['skylights']) + list(plan['tips'])]}
    if name in COLUMNS:                                  # the grooves' centre lines, every 8 cm (for a probe, or a line)
        return {'shader': FORMS[name].get('skin_shader', ''), 'outdoor': True,
                'weights': [round(float(w), 4) for w in COLUMNS[name]],
                'hue': [round(float(c), 4) for c in column_hue(COLUMNS[name])],
                'paths': [[[round(float(v), 3) for v in q] for q in s[::4]] for s in column_strands(COLUMNS[name])],
                'line': False, 'seed': COLUMN_SEED,
                'plaque_at': [round(COLUMN_R + 0.6, 3), 0.0, 0.5]}  # beside it (north, local +x), not in front (a lectern 1 m
        #                                                         out in front hid the lower half of the grooves)
    spec = CARVINGS.get(name)
    if spec is None:
        return {}
    paths, points = carving_paths(spec)
    k = CARVE_SCALE
    lift = 10.0 * k / 2
    return {'paths': [[[round(float(q[0] * k), 3), round(float(q[1] * k + lift), 3), round(float(q[2] * k), 3)] for q in path] for path in paths],
            'line': bool(spec.get('line', True)), 'seed': spec['seed'], 'cutters': len(points), 'pattern': spec['pattern']}


def write_bin(path, render, soup, hull):
    with open(path, 'wb') as fh:
        fh.write(b'ISO2')
        fh.write(struct.pack('<4I', len(render['verts']), render['faces'].size, len(soup), len(hull)))
        fh.write(render['verts'].tobytes())
        fh.write(render['normals'].tobytes())
        fh.write(render['colours'].tobytes())
        fh.write(render['faces'].reshape(-1).astype('<u4').tobytes())
        fh.write(soup.tobytes())
        fh.write(hull.tobytes())


def run(command, names):
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = {}
    if command == 'export' and (OUT / 'manifest.json').exists():
        manifest = json.loads((OUT / 'manifest.json').read_text(encoding='utf-8'))
    failed = 0
    for name in names:
        spec = FORMS[name]
        m = mesh_of(name)
        cs = checks(name, m)
        v = m['verts']
        lo, hi = v.min(axis=0), v.max(axis=0)
        dims = [round(float(x), 3) for x in hi - lo]
        bad = [c for c in cs if not c['ok']]
        failed += len(bad)
        print('%-14s %-12s tris %6d  dims %-22s %s' % (name, spec['verb'], len(m['faces']), dims, 'ok' if not bad else 'FAIL %d' % len(bad)))
        for c in cs:
            print('      %s %-64s %8s   want %s' % ('ok ' if c['ok'] else 'NO ', c['check'][:64], c['value'], c['want']))
        if command == 'export':
            soup, hull = collision_of(name, m)
            write_bin(OUT / (name + '.bin'), m, soup, hull)
            manifest[name] = dict(title=spec['title'], verb=spec['verb'], expression=spec['expression'], principle=spec['principle'],
                                  rigid=bool(spec.get('rigid', False)), mass=float(spec.get('mass', 0.0)), voxel=spec['h'],
                                  dimensions=dims, aabb=[[round(float(x), 3) for x in lo], [round(float(x), 3) for x in hi]],
                                  triangles=int(len(m['faces'])), collision_triangles=int(len(soup) // 3), hull_points=int(len(hull)),
                                  collision_voxel=float(spec.get('hc', min(max(spec['h'] * 2.0, 0.05), 0.08))), collision_budget=int(spec.get('cbudget', 2400)),
                                  centroid=[round(float(c), 4) for c in centroid(m)[0]] if spec.get('rigid') else None,
                                  budget=int(spec.get('budget', 0)), extras=extras_of(name),
                                  area=area_by_role(m), checks=cs)
        if command == 'views':
            views(name, m)
    if command == 'export':
        (OUT / 'manifest.json').write_text(json.dumps(manifest, indent=1), encoding='utf-8')
        print('wrote', OUT, 'for', len(names), 'forms;', sum(manifest[n]['triangles'] for n in manifest), 'triangles in all')
    return failed


def views(name, m):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    folder = OUT / 'views'
    folder.mkdir(parents=True, exist_ok=True)
    f = m['f']
    v = m['verts']
    lo, hi = v.min(axis=0) - 0.1, v.max(axis=0) + 0.1
    fig, ax = plt.subplots(1, 3, figsize=(15, 5))
    xs, zs = np.linspace(lo[0], hi[0], 160), np.linspace(lo[2], hi[2], 160)
    hs = np.array([surface_height(f, [(x, z) for x in xs], top=float(hi[1]) + 0.1, step=0.02) for z in zs])
    ax[0].imshow(hs, origin='lower', extent=[lo[0], hi[0], lo[2], hi[2]], cmap='viridis')
    ax[0].set_title(name + ' heights (plan, z up)')
    for k, (axis, label) in enumerate([(2, 'section z = 0'), (0, 'section x = 0')]):
        a = np.linspace(lo[0 if axis == 2 else 2], hi[0 if axis == 2 else 2], 240)
        ys = np.linspace(lo[1], hi[1], 200)
        A, Y = np.meshgrid(a, ys)
        pts = np.stack([A.ravel(), Y.ravel(), np.zeros(A.size)] if axis == 2 else [np.zeros(A.size), Y.ravel(), A.ravel()], axis=1)
        d, _, _ = evaluate(f, pts)
        ax[k + 1].contourf(A, Y, d.reshape(A.shape), levels=[-10, 0], colors=['#c8b8a0'])
        ax[k + 1].contour(A, Y, d.reshape(A.shape), levels=[0], colors=['k'])
        ax[k + 1].set_aspect('equal')
        ax[k + 1].set_title(label)
    fig.tight_layout()
    fig.savefig(folder / (name + '.png'), dpi=70)
    plt.close(fig)


if __name__ == '__main__':
    command = sys.argv[1] if len(sys.argv) > 1 else 'check'
    names = [n for n in sys.argv[2:] if n in FORMS] or list(FORMS)
    unknown = [n for n in sys.argv[2:] if n not in FORMS]
    if unknown:
        print('unknown forms:', unknown)
    sys.exit(1 if run(command, names) else 0)
