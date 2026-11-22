"""CONTACT: two bodies come together, made four ways. The forms for commons/artifacts/contact_study.

Palle, 22 November 2026, with Alan Warburton's essay Goodbye Uncanny Valley (2017) in hand: "I see a potential here
that is the future beyond the grotesque that is visual queer desire. Can you create that procedural geometry that
touches and goes beyond in future beauty ... smooth surface, soft bodies, hard edges primitives, extreme shaders,
boolean operation trick, isosurface trick, voxels, and more."

In the essay's wilderness the digital grotesque lets software show its seams: "warped bodies intersect". That is
what a mesh does with another mesh by default - it passes through it. This tool takes ONE meeting of two bodies and
makes it with four of the tower's constructions, as frames of an approach:

  through  the two bodies as two separate meshes, low in triangles: the game slides one into the other
  cut      A minus B: a boolean difference, the other body's shape taken out
  cubes    the join below, sampled on a 5 cm lattice and drawn as its cells
  skin     smooth union, smin(A, B, k): a neck of skin grows between the two before they meet, and the two become
           one body - first joined at the head, then at the hip too, with an opening left between (a ring)
  inside   the same join kept only inside another form (a diamond): where that form cuts the bodies the cut
           shows the field itself in rings - two sets of rings deep inside, one set near the skin

and, the same day ("make them larger ... fill the floor with versions"), THE FIELD: one SKIN version for every
place on the floor it stands on. The place gives the version, as on the colour floor: REACH (k) across the floor,
DISTANCE (gap) along it. The tool also finds where on that floor two bodies become one and where the first
opening appears, as lines to be drawn on the ground.

and ("can we go inside these forms?") WITHIN: at their own size nobody fits inside, so the place where the two
heads meet is made again at a size a visitor walks into - a hollow wall under the skin, cut level by the floor, a
door in each body: in through one, across the join, out through the other.

The bodies are solids of revolution drawn from one outline family (a foot, a neck, two swellings, a rounded tip);
B leans towards A so the heads meet first. A frame is one position of B: `gap` metres between the two skins where
they are closest (negative: overlapping).

Vertex colour is DATA for the shader: r = how much of body A a point is (the smooth union's mixing weight), g = a
face the cut made, b = the join's band (1 at the middle of a neck), a = ambient occlusion read from the field.

    python tools/contact_forms.py [frames] [field] [lines] [within]
                                  march them -> ada_run/contact_forms/*.bin + manifest.json (all four when none is named)
    godot --headless --path . --xr-mode off --script res://commons/artifacts/contact_study/bake_frames.gd
"""
import json
import struct
import sys
from pathlib import Path

import numpy as np
from skimage import measure

sys.path.insert(0, str(Path(__file__).resolve().parent))
import iso_prefabs as iso  # noqa: E402  the tower's distance-field kit: leaf, D, SU, evaluate, gradient, ambient_occlusion

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'ada_run' / 'contact_forms'
H = 0.014                       # the march's cell for cut and skin
CELL = 0.05                     # the cubes
K = 0.24                        # the smooth union's reach: within this the two boundaries melt into one
LEAN = 9.0                      # degrees B leans towards A
A_AT = -0.26                    # A's axis; B stands at +x
GAPS = [0.30, 0.24, 0.19, 0.15, 0.11, 0.07, 0.03, 0.0, -0.03, -0.06, -0.09, -0.12]
CUT_GAPS = [0.06, 0.0, -0.04, -0.08, -0.12, -0.16, -0.20, -0.24]
INSIDE = {'kind': 'diamond', 'radius': 0.86, 'centre_y': 1.16}   # the form the join is kept inside: tip to centre, and its height

# THE FIELD (floor ISO_ImplicitModeling). Where a version stands, in the floor's own metres (x east, z south), and
# what its place makes it: reach across, distance along. The places leave out the two shafts, the raymarched body
# at the north wall, the row of the five ways in the south band and the arrival.
FIELD_X = (-19.3, 19.3)
FIELD_REACH = (0.04, 0.56)          # k at the west edge and at the east edge
FIELD_Z = (5.0, -5.4)
FIELD_GAP = (0.22, -0.10)           # gap at the south row and at the north row
FIELD_PLACES = ([(x, z) for x in (-19.3, -15.4, 15.4, 19.3) for z in (5.0, 1.8, -1.8, -5.4)]
                + [(x, -5.4) for x in (-11.4, -7.7, 7.7, 11.4)])
FLOOR_HOLES = [(-13.3, -3.3, -6.7, 3.3), (6.7, -3.3, 13.3, 3.3), (-4.6, -8.5, 4.6, -0.6)]   # x0, z0, x1, z1: shafts, the body

# WITHIN: the two heads where they meet, hollow, at `size` times the bodies' own size. Everything else here is in
# the metres a visitor walks: the floor lies `drop` under the middle of the join, the wall is `wall` thick, a
# door is (wide, high). `cell` is the march's cell in the bodies' own metres: the wall needs three of them.
WITHIN = {'size': 9.0, 'gap': -0.04, 'reach': 0.12, 'drop': 1.1, 'wall': 0.14, 'door': (1.3, 2.2), 'cell': 0.005, 'budget': 24000}


def reach_at(x):
    t = (x - FIELD_X[0]) / (FIELD_X[1] - FIELD_X[0])
    return FIELD_REACH[0] + (FIELD_REACH[1] - FIELD_REACH[0]) * t


def gap_at(z):
    t = (z - FIELD_Z[0]) / (FIELD_Z[1] - FIELD_Z[0])
    return FIELD_GAP[0] + (FIELD_GAP[1] - FIELD_GAP[0]) * t


def z_of_gap(gap):
    t = (gap - FIELD_GAP[0]) / (FIELD_GAP[1] - FIELD_GAP[0])
    return FIELD_Z[0] + (FIELD_Z[1] - FIELD_Z[0]) * t

# (height, radius) of the outline's turning points; between two of them the radius eases, so each is a swelling or a waist
BODY_A = [(0.0, 0.21), (0.10, 0.21), (0.26, 0.070), (0.62, 0.075), (0.88, 0.185), (1.14, 0.085), (1.44, 0.205), (1.60, 0.150)]
TIP_A = 1.78
BODY_B = [(0.0, 0.19), (0.09, 0.19), (0.24, 0.060), (0.58, 0.065), (0.84, 0.170), (1.08, 0.070), (1.36, 0.190), (1.52, 0.135)]
TIP_B = 1.68


def outline(turns, tip, per=10):
    """The closed outline in (radius, height): up the skin, over a rounded tip, back down the axis."""
    pts = [(0.0, turns[0][0])]
    for (y0, r0), (y1, r1) in zip(turns[:-1], turns[1:]):
        for i in range(per):
            u = i / per
            e = 0.5 - 0.5 * np.cos(np.pi * u)
            pts.append((r0 + (r1 - r0) * e, y0 + (y1 - y0) * u))
    y0, r0 = turns[-1]
    for i in range(per + 1):                      # a quarter ellipse: level where it leaves the body, upright at the axis
        u = i / per
        pts.append((r0 * np.sqrt(max(0.0, 1.0 - u * u)), y0 + (tip - y0) * u))
    return np.asarray(pts, float)


def lathe(turns, tip, base=(0.0, 0.0, 0.0), lean=0.0):
    """A solid of revolution about an axis through `base`, leaning `lean` degrees about z towards -x: exact distance."""
    poly = outline(turns, tip)
    base = np.asarray(base, float)
    c, s = np.cos(np.radians(lean)), np.sin(np.radians(lean))

    def d(p):
        q = p - base
        x = c * q[:, 0] + s * q[:, 1]             # the point in the body's own upright frame
        y = -s * q[:, 0] + c * q[:, 1]
        rho = np.hypot(x, q[:, 2])
        best = np.full(len(p), np.inf)
        inside = np.zeros(len(p), bool)
        n = len(poly)
        for i in range(n):
            a, b = poly[i], poly[(i + 1) % n]
            ex, ey = b[0] - a[0], b[1] - a[1]
            wx, wy = rho - a[0], y - a[1]
            # the edge back down the axis only closes the outline: it is not skin, and counting it made every
            # depth inside a body a distance to its own axis (found 22 Nov, when a room was made from a level
            # under the skin and a column stood on each axis). The skin itself was never affected.
            if a[0] > 1e-9 or b[0] > 1e-9:
                t = np.clip((wx * ex + wy * ey) / max(ex * ex + ey * ey, 1e-12), 0.0, 1.0)
                best = np.minimum(best, (wx - ex * t) ** 2 + (wy - ey * t) ** 2)
            # crossing number, a ray towards +radius
            cross = ((a[1] <= y) != (b[1] <= y)) & (rho < a[0] + ex * (y - a[1]) / (ey if abs(ey) > 1e-12 else 1e-12))
            inside ^= cross
        dist = np.sqrt(best)
        return np.where(inside, -dist, dist)
    return iso.leaf(d)


def grounded(body):
    """Cut level where it stands: a leaning body's foot would otherwise dip under the ground on one side and leave
    the skin open there (an open skin has no honest count of its openings)."""
    return iso.I(body, iso.half_space((0.0, -1.0, 0.0), 0.0))


def body_a():
    return grounded(lathe(BODY_A, TIP_A, (A_AT, 0.0, 0.0)))


def body_b(x):
    # set 3 cm into the ground, so the whole leaning foot reaches it
    return grounded(lathe(BODY_B, TIP_B, (x, -0.03, 0.0), LEAN))


def march(f, h, lo, hi):
    axes = [np.arange(lo[i], hi[i] + h, h) for i in range(3)]
    g = np.stack(np.meshgrid(*axes, indexing='ij'), axis=-1).reshape(-1, 3)
    d, _, _ = iso.evaluate(f, g)
    vol = d.reshape([len(a) for a in axes])
    verts, faces, _, _ = measure.marching_cubes(vol, level=0.0, spacing=(h, h, h), allow_degenerate=False)
    verts = verts + np.array([a[0] for a in axes])
    normals = iso.gradient(f, verts, h * 0.5)
    tri = verts[faces]
    gn = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])
    flip = np.einsum('ij,ij->i', gn, normals[faces].sum(axis=1)) < 0
    faces[flip] = faces[flip][:, ::-1]
    return verts, normals, faces


def weights(a, b, p, k):
    """How much of A a point is (1 on A alone, 0 on B alone), and the band of the join between them."""
    da, _, _ = iso.evaluate(a, p)
    db, _, _ = iso.evaluate(b, p)
    h = np.clip(0.5 + 0.5 * (db - da) / k, 0.0, 1.0)
    return h, 4.0 * h * (1.0 - h)


def surface_gap(a, b_verts):
    """The smallest distance from B's skin to A's (negative when B is inside A)."""
    da, _, _ = iso.evaluate(a, b_verts)
    return float(da.min())


def contact_x(a):
    """Where B must stand for the two skins to touch at one point: found by halving."""
    lo, hi = A_AT + 0.2, A_AT + 1.2
    box_lo, box_hi = np.array([-0.4, -0.02, -0.3]), np.array([0.5, 1.8, 0.3])
    verts, _, _ = march(body_b(0.0), 0.02, box_lo, box_hi)      # B's skin once, at x = 0; it only slides after that
    for _ in range(30):
        mid = 0.5 * (lo + hi)
        if surface_gap(a, verts + np.array([mid, 0.0, 0.0])) > 0.0: hi = mid
        else: lo = mid
    return 0.5 * (lo + hi)


def cubes(f, a, b, lo, hi, cell):
    """The form as the cells of a lattice whose centres are inside it: one quad for every face a full cell shows."""
    axes = [np.arange(lo[i] + cell * 0.5, hi[i], cell) for i in range(3)]
    g = np.stack(np.meshgrid(*axes, indexing='ij'), axis=-1)
    shape = g.shape[:3]
    centres = g.reshape(-1, 3)
    d, _, _ = iso.evaluate(f, centres)
    full = (d < 0).reshape(shape)
    h, band = weights(a, b, centres, K)
    h, band = h.reshape(shape), band.reshape(shape)
    verts, normals, colours, faces = [], [], [], []
    corners = {  # the four corners of the face a cell shows towards each side, wound outward
        (1, 0, 0): [(1, 0, 0), (1, 1, 0), (1, 1, 1), (1, 0, 1)], (-1, 0, 0): [(0, 0, 0), (0, 0, 1), (0, 1, 1), (0, 1, 0)],
        (0, 1, 0): [(0, 1, 0), (0, 1, 1), (1, 1, 1), (1, 1, 0)], (0, -1, 0): [(0, 0, 0), (1, 0, 0), (1, 0, 1), (0, 0, 1)],
        (0, 0, 1): [(0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)], (0, 0, -1): [(0, 0, 0), (0, 1, 0), (1, 1, 0), (1, 0, 0)],
    }
    padded = np.pad(full, 1)
    for side, quad in corners.items():
        neighbour = padded[1 + side[0]:1 + side[0] + shape[0], 1 + side[1]:1 + side[1] + shape[1], 1 + side[2]:1 + side[2] + shape[2]]
        for i, j, k in np.argwhere(full & ~neighbour):
            origin = np.array([axes[0][i], axes[1][j], axes[2][k]]) - cell * 0.5
            base = len(verts)
            for corner in quad:
                verts.append(origin + np.array(corner) * cell)
                normals.append(side)
                colours.append((h[i, j, k], 0.0, band[i, j, k], 1.0))
            faces.append((base, base + 1, base + 2))
            faces.append((base, base + 2, base + 3))
    return np.asarray(verts, np.float32), np.asarray(normals, np.float32), np.asarray(colours, np.float32), np.asarray(faces, np.uint32)


def diamond(centre, radius):
    """An octahedron, tip to centre `radius`: exact enough for a container (the bound is its faces' planes)."""
    centre = np.asarray(centre, float)
    return iso.leaf(lambda p: (np.abs(p - centre).sum(axis=1) - radius) / np.sqrt(3.0))


def state(f, lo, hi, h=0.03):
    """Pieces and openings of a body, counted on a coarse lattice: objects, and tunnels from the Euler number."""
    axes = [np.arange(lo[i], hi[i] + h, h) for i in range(3)]
    g = np.stack(np.meshgrid(*axes, indexing='ij'), axis=-1).reshape(-1, 3)
    d, _, _ = iso.evaluate(f, g)
    solid = np.pad((d < 0).reshape([len(a) for a in axes]), 1)
    pieces = int(measure.label(solid, connectivity=1).max())
    return pieces, int(pieces - measure.euler_number(solid, connectivity=1))


def on_floor(x, z):
    return not any(x0 <= x <= x1 and z0 <= z <= z1 for x0, z0, x1, z1 in FLOOR_HOLES) and abs(x) <= 21.2 and abs(z) <= 8.2


def floor_states(a, x0, lo, hi, step_x=1.5, step_z=0.75):
    """What a pair would be at every place of the floor, by the floor's rule: pieces and openings on a lattice of
    places. Openings come and go as reach grows (a wide reach closes them again), so the regions are found from
    this map and not by looking for one crossing."""
    xs = np.arange(-21.0, 21.01, step_x)
    zs = np.arange(-8.25, 8.26, step_z)
    pieces = np.zeros((len(xs), len(zs)), int)
    openings = np.zeros((len(xs), len(zs)), int)
    wide = hi + np.array([0.5, 0.0, 0.0])
    for i, x in enumerate(xs):
        k = reach_at(float(np.clip(x, *FIELD_X)))
        for j, z in enumerate(zs):
            pieces[i, j], openings[i, j] = state(iso.SU(k, a, body_b(x0 + gap_at(float(z)))), lo, wide)
    return xs, zs, pieces, openings


def edges_of(xs, zs, inside):
    """The edge of a region of the map, as stretches of floor points [(x, z), ...] that lie on the slab."""
    stretches = []
    for contour in measure.find_contours(inside.astype(float), 0.5):
        run = []
        for i, j in contour:
            x = float(np.interp(i, np.arange(len(xs)), xs))
            z = float(np.interp(j, np.arange(len(zs)), zs))
            if on_floor(x, z):
                run.append([round(x, 2), round(z, 2)])
            else:
                if len(run) > 1: stretches.append(run)
                run = []
        if len(run) > 1: stretches.append(run)
    return stretches


def within_form(a, x0):
    """WITHIN: the place where the two heads meet, as a room. The wall is the join's own field between the skin
    and `wall` under it, so the room's inner face is a level of the same distance: the form, a little under its
    skin. The floor cuts it level; a door is an arch taken out of each body on the line through both axes, so
    one looks from door to door through the join. Written in the bodies' own metres with the floor at y = 0 and
    the middle of the two at x = 0; the game scales it by `size`.
    Vertex colour: r = how much of A, g = 0 on the skin and 1 on the inner wall, b = the join's band, a = AO."""
    w = WITHIN
    s, t, cell = w['size'], w['wall'] / w['size'], w['cell']
    b = body_b(x0 + w['gap'])
    join = iso.SU(w['reach'], a, b)
    c, sn = np.cos(np.radians(LEAN)), np.sin(np.radians(LEAN))
    ya, along = BODY_A[6][0], BODY_B[6][0]                  # the upper swelling of each, along its own axis
    y0 = 0.5 * (ya + (-0.03 + c * along)) - w['drop'] / s   # the floor, in the bodies' own metres
    xa = A_AT
    xb = x0 + w['gap'] - sn * (y0 + 0.03) / c               # B's axis where the floor cuts it
    shell = iso.leaf(lambda p: (lambda f: np.maximum(f, -(f + t)))(join(p)[0]))
    # the outermost wall at door height, to the west of A and to the east of B
    door_w, door_h = w['door'][0] / s, w['door'][1] / s
    xs = np.arange(xa - 0.36, xb + 0.36, 0.001)
    heights = y0 + np.arange(0.05, w['door'][1], 0.1) / s
    grid = np.stack(np.meshgrid(xs, heights, [-door_w / 2, 0.0, door_w / 2], indexing='ij'), axis=-1).reshape(-1, 3)
    solid_there = (iso.evaluate(join, grid)[0] < 0).reshape(len(xs), -1).any(axis=1)
    west, east = float(xs[solid_there.argmax()]), float(xs[len(xs) - 1 - solid_there[::-1].argmax()])
    spring = door_h - door_w / 2
    doors = [iso.arch('x', door_w, spring, xa - west + 0.02, c=(0.5 * (west - 0.02 + xa), y0, 0.0), bottom=-0.05),
             iso.arch('x', door_w, spring, east - xb + 0.02, c=(0.5 * (east + 0.02 + xb), y0, 0.0), bottom=-0.05)]
    # the wall goes a little way into the slab (`sunk`): cut exactly at the floor, on the march's own lattice, its
    # foot came out as a sawtooth; now the slab itself draws the line where wall meets floor
    sunk = 0.012
    solid = iso.D(iso.I(shell, iso.half_space((0.0, -1.0, 0.0), -(y0 - sunk))), *doors, k=0.006)
    lo = np.array([west - 0.03, y0 - sunk - 2.5 * cell, -0.27])
    hi = np.array([east + 0.03, TIP_A + 0.03, 0.27])
    verts, normals, faces = march(solid, cell, lo, hi)
    under = np.clip(-iso.evaluate(join, verts)[0] / t, 0.0, 1.0)
    h, band = weights(a, b, verts, w['reach'])
    ao = iso.ambient_occlusion(solid, verts + normals * cell * 0.1, normals, floor=False, reach=0.12)
    pieces, handles = genus(verts, faces)

    # what a visitor meets on the way from door to door: the room's height over the line, and its width at the shoulder
    def room(x, z, height):
        return iso.evaluate(join, np.array([[x, y0 + height / s, z]]))[0][0] < -t
    line = []
    for x in np.linspace(xa, xb, 21):
        up = np.arange(0.05, 5.0, 0.05)
        free = iso.evaluate(join, np.stack([np.full(len(up), x), y0 + up / s, np.zeros(len(up))], axis=1))[0] < -t
        headroom = float(up[free.argmin()]) if not free.all() else 5.0
        zs = np.arange(-0.27, 0.27, 0.002)
        wide = iso.evaluate(join, np.stack([np.full(len(zs), x), np.full(len(zs), y0 + 1.5 / s), zs], axis=1))[0] < -t
        line.append((round(float((x - 0.5 * (west + east)) * s), 2), round(headroom, 2), round(float(wide.sum() * 0.002 * s), 2)))
    # is that line free for a body 0.6 m wide and 1.8 m tall, from outside one door to outside the other? Only the
    # sign is asked: after a cut the field is a bound on the distance, no longer the distance.
    walk_x = np.arange(west - 0.6 / s, east + 0.6 / s, 0.05 / s)
    walk_h = y0 + np.arange(0.05, 1.81, 0.05) / s
    walk = np.stack(np.meshgrid(walk_x, walk_h, [-0.3 / s, 0.0, 0.3 / s], indexing='ij'), axis=-1).reshape(-1, 3)
    line_free = bool((iso.evaluate(solid, walk)[0] > 0).all())

    centre = 0.5 * (west + east)
    verts = verts - np.array([centre, y0, 0.0])
    write_bin(OUT / 'within.bin', verts, normals, np.stack([h, under, band, ao], axis=1), faces)
    return {'file': 'within', 'size': s, 'gap': w['gap'], 'reach': w['reach'], 'wall': w['wall'], 'drop': w['drop'], 'door': list(w['door']),
            'floor_y': round(float(y0), 4), 'west_door_x': round((west - centre) * s, 2), 'east_door_x': round((east - centre) * s, 2),
            'axis_a_x': round((xa - centre) * s, 2), 'axis_b_x': round((xb - centre) * s, 2),
            'long_m': round(float(np.ptp(verts[:, 0]) * s), 2), 'deep_m': round(float(np.ptp(verts[:, 2]) * s), 2), 'tall_m': round(float(verts[:, 1].max() * s), 2),
            'line_x_headroom_width': line, 'narrowest_headroom_m': min(r[1] for r in line), 'narrowest_width_m': min(r[2] for r in line),
            'line_free_for_a_body': line_free,
            'pieces': pieces, 'handles': handles, 'triangles': int(len(faces)), 'budget': w['budget']}


def write_bin(path, verts, normals, colours, faces):
    with open(path, 'wb') as fh:
        fh.write(b'ISO2')
        fh.write(struct.pack('<4I', len(verts), faces.size, 0, 0))
        fh.write(np.asarray(verts, '<f4').tobytes())
        fh.write(np.asarray(normals, '<f4').tobytes())
        fh.write(np.asarray(colours, '<f4').tobytes())
        fh.write(np.asarray(faces, '<u4').reshape(-1).tobytes())


def genus(verts, faces):
    """Handles of a closed skin, from its Euler number - per piece, so two bodies read 0 and 0."""
    edges = np.sort(np.concatenate([faces[:, [0, 1]], faces[:, [1, 2]], faces[:, [2, 0]]]), axis=1)
    e = len(np.unique(edges, axis=0))
    parent = np.arange(len(verts))

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i
    for u, v in np.unique(edges, axis=0):
        ru, rv = find(u), find(v)
        if ru != rv: parent[ru] = rv
    pieces = len({find(i) for i in np.unique(faces)})
    chi = len(np.unique(faces)) - e + len(faces)
    return pieces, int(round((2 * pieces - chi) / 2))


def main():
    """python tools/contact_forms.py [frames] [field] [lines] [within] - all four when none is named."""
    parts = set(sys.argv[1:]) or {'frames', 'field', 'lines', 'within'}
    OUT.mkdir(parents=True, exist_ok=True)
    a = body_a()
    x0 = contact_x(a)
    print('the skins touch with B at x = %.4f' % x0)
    lo, hi = np.array([-0.56, -0.02, -0.30]), np.array([x0 + 0.62, 1.84, 0.30])
    path = OUT / 'manifest.json'
    manifest = json.loads(path.read_text(encoding='utf-8')) if path.is_file() else {}
    manifest.update({'k': K, 'cell': CELL, 'lean_degrees': LEAN, 'a_at': A_AT, 'b_at_contact': x0, 'inside': INSIDE,
                     'field_rule': {'x': FIELD_X, 'reach': FIELD_REACH, 'z': FIELD_Z, 'gap': FIELD_GAP}})
    if 'frames' in parts:
        manifest['parts'], manifest['frames'] = {}, {}
        # the two bodies alone (through): B is written where it touches, and the game slides it
        for name, f in (('body_a', a), ('body_b', body_b(x0))):
            verts, normals, faces = march(f, H, lo, hi)
            ao = iso.ambient_occlusion(f, verts + normals * H * 0.1, normals, floor=True, reach=0.5)
            colours = np.stack([np.full(len(verts), 1.0 if name == 'body_a' else 0.0), np.zeros(len(verts)), np.zeros(len(verts)), ao], axis=1)
            write_bin(OUT / (name + '.bin'), verts, normals, colours, faces)
            manifest['parts'][name] = {'triangles': int(len(faces)), 'budget': 700}
            print(name, len(faces), 'triangles')
        for strategy, gaps in (('skin', GAPS), ('cubes', GAPS), ('cut', CUT_GAPS), ('inside', GAPS)):
            rows = []
            for n, gap in enumerate(gaps):
                b = body_b(x0 + gap)
                name = '%s_%02d' % (strategy, n)
                if strategy == 'skin':
                    f = iso.SU(K, a, b)
                    verts, normals, faces = march(f, H, lo, hi)
                    h, band = weights(a, b, verts, K)
                    ao = iso.ambient_occlusion(f, verts + normals * H * 0.1, normals, floor=True, reach=0.5)
                    colours = np.stack([h, np.zeros(len(verts)), band, ao], axis=1)
                    pieces, handles = genus(verts, faces)
                    row = {'gap': gap, 'triangles': int(len(faces)), 'pieces': pieces, 'handles': handles, 'budget': 7000}
                elif strategy == 'cubes':
                    f = iso.SU(K, a, b)
                    verts, normals, colours, faces = cubes(f, a, b, lo, hi, CELL)
                    row = {'gap': gap, 'triangles': int(len(faces)), 'budget': 0}
                elif strategy == 'inside':
                    # the join kept inside another form; g = how deep under the skin a point of the cut lies
                    join = iso.SU(K, a, b)
                    centre = (0.5 * (A_AT + x0 + gap), INSIDE['centre_y'], 0.0)
                    f = iso.I(join, diamond(centre, INSIDE['radius']), k=0.012)
                    verts, normals, faces = march(f, H, lo, hi)
                    h, band = weights(a, b, verts, K)
                    dj, _, _ = iso.evaluate(join, verts)
                    depth = np.clip(-dj / 0.22, 0.0, 1.0)
                    ao = iso.ambient_occlusion(f, verts + normals * H * 0.1, normals, floor=False, reach=0.5)
                    colours = np.stack([h, depth, band, ao], axis=1)
                    row = {'gap': gap, 'triangles': int(len(faces)), 'budget': 5000, 'centre': [round(c, 4) for c in centre]}
                else:
                    f = iso.D(a, b, k=0.012)
                    verts, normals, faces = march(f, H, lo, hi)
                    db, _, _ = iso.evaluate(b, verts)
                    ao = iso.ambient_occlusion(f, verts + normals * H * 0.1, normals, floor=True, reach=0.5)
                    colours = np.stack([np.ones(len(verts)), (db < H * 1.5).astype(float), np.zeros(len(verts)), ao], axis=1)
                    row = {'gap': gap, 'triangles': int(len(faces)), 'budget': 5000}
                write_bin(OUT / (name + '.bin'), verts, normals, colours, faces)
                row['file'] = name
                rows.append(row)
                print(name, row)
            manifest['frames'][strategy] = rows
    if 'field' in parts:
        # THE FIELD: a version for every place
        field = []
        for n, (x, z) in enumerate(FIELD_PLACES):
            k, gap = reach_at(x), gap_at(z)
            b = body_b(x0 + gap)
            f = iso.SU(k, a, b)
            verts, normals, faces = march(f, H, lo, hi + np.array([max(gap, 0.0), 0.0, 0.0]))
            h, band = weights(a, b, verts, k)
            ao = iso.ambient_occlusion(f, verts + normals * H * 0.1, normals, floor=True, reach=0.5)
            pieces, handles = genus(verts, faces)
            name = 'field_%02d' % n
            write_bin(OUT / (name + '.bin'), verts, normals, np.stack([h, np.zeros(len(verts)), band, ao], axis=1), faces)
            row = {'file': name, 'x': x, 'z': z, 'reach': round(k, 3), 'gap': round(gap, 3), 'pieces': pieces, 'handles': handles,
                   'triangles': int(len(faces)), 'budget': 5000}
            field.append(row)
            print(name, row)
        manifest['field'] = field
    if 'lines' in parts:
        # the ground: where a pair is one body, and where it has an opening
        xs, zs, pieces, openings = floor_states(a, x0, lo, hi)
        manifest['lines'] = {'one_body': edges_of(xs, zs, pieces == 1), 'an_opening': edges_of(xs, zs, (pieces == 1) & (openings >= 1))}
        manifest['states'] = {'x': [round(float(v), 2) for v in xs], 'z': [round(float(v), 2) for v in zs],
                              'rows': [''.join('2' if pieces[i, j] >= 2 else ('o' if openings[i, j] >= 1 else '1') for i in range(len(xs))) for j in range(len(zs))]}
        print('lines', {key: [len(run) for run in runs] for key, runs in manifest['lines'].items()})
        for row in manifest['states']['rows']: print('  ', row)
    if 'within' in parts:
        # the heads as a room
        manifest['within'] = within_form(a, x0)
        for key, value in manifest['within'].items(): print('  within', key, value)
    path.write_text(json.dumps(manifest, indent=1), encoding='utf-8')
    print('wrote', OUT)


if __name__ == '__main__':
    main()
