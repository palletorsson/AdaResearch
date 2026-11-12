"""koch_coast_bench.py - what a body measures when it walks round a Koch island.

The island is the Koch snowflake on a triangle of side S after n generations: its coast is 3 S (4/3)^n long.
A body is a disc of radius r. Kept against the coast, its centre runs along the curve at distance r outside the
island: it cannot enter a notch narrower than itself, so its lap is the length of that offset curve. Computed on a
5 mm raster: outside distance field, the level set at r, its length.

    python tools/probes/koch_coast_bench.py [side] [radius ...]      -> the table
    python tools/probes/koch_coast_bench.py --json                   -> {generation: [coast, lap]} for side 5, r 0.2
"""
import sys, json, math
import numpy as np
import cv2
from scipy import ndimage
from skimage import measure

PX = 0.005


def snowflake(side, depth):
    """outline, counter-clockwise seen from above with x right and y up; one corner points up"""
    h = side * math.sqrt(3) / 2
    pts = [(-side / 2, -h / 3), (side / 2, -h / 3), (0.0, 2 * h / 3)]
    for _ in range(depth):
        out = []
        for i in range(len(pts)):
            a = np.array(pts[i]); b = np.array(pts[(i + 1) % len(pts)])
            d = (b - a) / 3
            p1 = a + d; p2 = a + 2 * d
            peak = p1 + np.array([d[0] * 0.5 + d[1] * math.sqrt(3) / 2, -d[0] * math.sqrt(3) / 2 + d[1] * 0.5])   # turned -60 degrees: outward for a ccw outline
            out += [tuple(a), tuple(p1), tuple(peak), tuple(p2)]
        pts = out
    return pts


def lap(side, depth, radius):
    pts = np.array(snowflake(side, depth))
    half = side * 0.7 + radius + 0.1
    n = int(2 * half / PX)
    img = np.zeros((n, n), np.uint8)
    pix = np.round((pts + half) / PX).astype(np.int32)
    cv2.fillPoly(img, [pix], 1)
    dist = ndimage.distance_transform_edt(img == 0) * PX
    total = 0.0
    for c in measure.find_contours(dist, radius):
        total += float(np.sum(np.hypot(np.diff(c[:, 0]), np.diff(c[:, 1])))) * PX
    return total


if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if not a.startswith('-')]
    side = float(args[0]) if args else 5.0
    radii = [float(a) for a in args[1:]] or [0.2]
    if '--json' in sys.argv:
        print(json.dumps({str(d): [round(3 * side * (4 / 3) ** d, 3), round(lap(side, d, radii[0]), 2)] for d in range(6)}))
        sys.exit(0)
    for r in radii:
        print('side %.1f m, body radius %.2f m' % (side, r))
        prev = None
        for d in range(6):
            coast = 3 * side * (4 / 3) ** d
            walk = lap(side, d, r)
            print('  generation %d: coast %6.2f m (shortest piece %5.1f cm) | lap %6.2f m%s' % (d, coast, side / 3 ** d * 100, walk, '' if prev is None else '  (+%.1f %%)' % ((walk / prev - 1) * 100)))
            prev = walk
