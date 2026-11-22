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

The bodies are solids of revolution drawn from one outline family (a foot, a neck, two swellings, a rounded tip);
B leans towards A so the heads meet first. A frame is one position of B: `gap` metres between the two skins where
they are closest (negative: overlapping).

Vertex colour is DATA for the shader: r = how much of body A a point is (the smooth union's mixing weight), g = a
face the cut made, b = the join's band (1 at the middle of a neck), a = ambient occlusion read from the field.

    python tools/contact_forms.py                 march every frame -> ada_run/contact_forms/*.bin + manifest.json
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
    OUT.mkdir(parents=True, exist_ok=True)
    a = body_a()
    x0 = contact_x(a)
    print('the skins touch with B at x = %.4f' % x0)
    lo, hi = np.array([-0.56, -0.02, -0.30]), np.array([x0 + 0.62, 1.84, 0.30])
    manifest = {'k': K, 'cell': CELL, 'lean_degrees': LEAN, 'a_at': A_AT, 'b_at_contact': x0, 'frames': {}, 'parts': {}}
    # the two bodies alone (through): B is written where it touches, and the game slides it
    for name, f in (('body_a', a), ('body_b', body_b(x0))):
        verts, normals, faces = march(f, H, lo, hi)
        ao = iso.ambient_occlusion(f, verts + normals * H * 0.1, normals, floor=True, reach=0.5)
        colours = np.stack([np.full(len(verts), 1.0 if name == 'body_a' else 0.0), np.zeros(len(verts)), np.zeros(len(verts)), ao], axis=1)
        write_bin(OUT / (name + '.bin'), verts, normals, colours, faces)
        manifest['parts'][name] = {'triangles': int(len(faces)), 'budget': 700}
        print(name, len(faces), 'triangles')
    for strategy, gaps in (('skin', GAPS), ('cubes', GAPS), ('cut', CUT_GAPS)):
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
    (OUT / 'manifest.json').write_text(json.dumps(manifest, indent=1), encoding='utf-8')
    print('wrote', OUT)


if __name__ == '__main__':
    main()
