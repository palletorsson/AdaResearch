"""gen_sdf_map.py — the map as a level set of the desire field (L-026).

SDF floor generation: the walk is a serpentine SPINE through world space,
the text-compiled desire curve is the RADIUS along it, and the floor is
the tube  dist(p, spine) < r(t).  Dense desire widens the world; vacuum
narrows it to a thread; the hero's climax is a bulge (the plaza as a blob).
Height terraces rise along the walk (levels 1->4, wp ramps on the spine),
so the tube also climbs — bridges and basins fall out of the field where
the tube pinches over lower bands.

  python tools/gen_sdf_map.py --map Point_Lines
Writes commons/maps/Sdf_<Map>/ — sibling, judged like everything else.
"""
import argparse
import json
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAPS_DIR = os.path.join(ROOT, "commons", "maps")
sys.path.insert(0, os.path.join(ROOT, "tools"))
import script_compose as sc  # noqa: E402


def spine_points(n=400):
    """A serpentine spine in world units: three legs joined by half-turns."""
    pts = []
    for i in range(n):
        t = i / (n - 1)
        if t < 0.4:
            u = t / 0.4
            pts.append((10 + 4 * math.sin(u * math.pi * 1.5), 4 + u * 30, t))
        elif t < 0.55:
            u = (t - 0.4) / 0.15  # the first turn
            a = math.pi * u
            pts.append((10 + 4 * math.sin(1.5 * math.pi) + 9 * (1 - math.cos(a)) / 2 * 2,
                        34 + 5 * math.sin(a), t))
        elif t < 0.9:
            u = (t - 0.55) / 0.35
            pts.append((28 + 3 * math.sin(u * math.pi * 2), 34 - u * 24, t))
        else:
            u = (t - 0.9) / 0.1
            pts.append((28 + 10 * u, 10 - 3 * u, t))
    return pts


def compose(map_name):
    source, cast, exit_tok = sc.read_cast(map_name)
    target = sc.load_target(map_name)
    vis = target["target"]["visual"] if target and "target" in target else \
        (target["visual"] if target else [30.0] * 16)
    if isinstance(target, dict) and "visual" in target:
        vis = target["visual"]
    hero_i = max(range(len(cast)), key=lambda i: sc.size_of(cast[i]))

    def radius(t):
        f = t * (len(vis) - 1)
        a, b = vis[int(f)], vis[min(len(vis) - 1, int(f) + 1)]
        v = a + (b - a) * (f - int(f))
        r = 2.0 + (v / 72.0) * 4.0          # desire -> width (2..6 cells)
        if abs(t - 0.72) < 0.06:
            r += 3.0                          # the climax bulge: the plaza as a blob
        if 0.55 <= t <= 0.64:
            r = max(1.2, r - 2.5)             # the vacuum pinch: a thread over the void
        return r

    spine = spine_points()
    W, D = 44, 44
    floor = [["0"] * W for _ in range(D)]
    utils = [[" "] * W for _ in range(D)]
    inter = [[" "] * W for _ in range(D)]

    def level_of(t):
        return 1 + min(3, int(t * 3.4))       # the tube climbs 1..4 along the walk

    # rasterize the tube
    for z in range(D):
        for x in range(W):
            best = None
            for (sx, sz, t) in spine[::4]:
                d2 = (x - sx) ** 2 + (z - sz) ** 2
                if best is None or d2 < best[0]:
                    best = (d2, t)
            d, t = math.sqrt(best[0]), best[1]
            if d < radius(t):
                floor[z][x] = str(level_of(t))

    # ramps where the level rises, on the spine
    prev = 1
    for (sx, sz, t) in spine:
        lv = level_of(t)
        if lv != prev:
            xi, zi = int(round(sx)), int(round(sz))
            for dz in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    xx, zz = xi + dx, zi + dz
                    if 0 <= xx < W and 0 <= zz < D and floor[zz][xx] != "0":
                        utils[zz][xx] = "wp"
            prev = lv

    # cast along the spine by arclength, alternating sides; hero at the bulge
    order = [i for i in range(len(cast)) if i != hero_i]
    placements = []
    for k, idx in enumerate(order):
        t = 0.06 + 0.86 * (k / max(1, len(order) - 1))
        if abs(t - 0.72) < 0.07:
            t += 0.1
        si = min(len(spine) - 1, int(t * len(spine)))
        sx, sz, _ = spine[si]
        nx, nz, _ = spine[min(len(spine) - 1, si + 4)]
        px, pz = -(nz - sz), (nx - sx)        # perpendicular
        norm = math.hypot(px, pz) or 1
        off = (radius(t) - 1.2) * (1 if k % 2 else -1)
        x = int(round(sx + px / norm * off))
        z = int(round(sz + pz / norm * off))
        placements.append((x, z, cast[idx]))
    hi = min(len(spine) - 1, int(0.72 * len(spine)))
    placements.append((int(round(spine[hi][0])), int(round(spine[hi][1])), cast[hero_i]))

    dropped = []
    for x, z, tok in placements:
        placed = False
        for r_ in range(0, 4):
            for dz in range(-r_, r_ + 1):
                for dx in range(-r_, r_ + 1):
                    xx, zz = x + dx, z + dz
                    if 0 <= xx < W and 0 <= zz < D and floor[zz][xx] != "0" \
                            and inter[zz][xx].strip() == "" and utils[zz][xx].strip() == "":
                        inter[zz][xx] = tok
                        placed = True
                        break
                if placed:
                    break
            if placed:
                break
        if not placed:
            dropped.append(sc.base_of(tok))

    s0 = spine[0]
    se = spine[-1]
    utils[int(round(s0[1]))][int(round(s0[0]))] = "s"
    utils[int(round(se[1]))][int(round(se[0]))] = exit_tok

    out = f"Sdf_{map_name}"
    data = {
        "documentation": {
            "composer": {
                "tool": "gen_sdf_map.py",
                "note": "the floor is a level set of the desire field: dist(p, spine) < desire(t); "
                        "the climax is a bulge, the vacuum a pinch, the tube climbs 1..4",
                "dropped": dropped,
            },
        },
        "layers": {"structure": floor, "utilities": utils, "interactables": inter},
        "lighting": source.get("lighting", {}),
        "map_info": {"dimensions": {"width": float(W), "depth": float(D), "max_height": 5.0},
                     "lookup_name": out, "name": out, "format": "json"},
        "settings": source.get("settings", {}),
        "utility_definitions": source.get("utility_definitions", {}),
    }
    sc.write_map(out, data)
    n_floor = sum(1 for row in floor for c in row if c != "0")
    print(f"{out}: {n_floor} floor cells, {len(placements) - len(dropped)}/{len(placements)} placed"
          + (f", dropped {dropped}" if dropped else ""))
    return out


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", default="Point_Lines")
    a = ap.parse_args()
    compose(a.map)
