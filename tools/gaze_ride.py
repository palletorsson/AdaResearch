#!/usr/bin/env python3
"""gaze_ride - a map's experience as a GAZE token-stream, not a top-down picture.

The reframe (point 2): the player is not an ant on a 2D path; they are a moving viewpoint in 3D.
The experience is what the gaze-rays HIT as the ride moves - which bodies, in what order, at what
angular size (how big in view) and screen side. That stream is computable from the registry:
  positions (map_data) + real sizes (commons/data/artifact_sizes.json) + a camera path.

Point 1 (sizes): every body is measured at its REAL footprint (base_m), so overlaps and the gaps
you walk between are computed, not guessed.

Usage:
  python tools/gaze_ride.py <MapName> [--fov 90]
"""
import json, math, os, argparse

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load(p):
    return json.load(open(p, encoding="utf-8"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("map")
    ap.add_argument("--fov", type=float, default=90.0)
    ap.add_argument("--walk", type=float, default=1.2, help="clearance to walk between (m)")
    a = ap.parse_args()

    md = load(os.path.join(ROOT, "commons", "maps", a.map, "map_data.json"))
    sizes = load(os.path.join(ROOT, "commons", "data", "artifact_sizes.json")).get("sizes", {})
    s = md.get("settings", {})
    cube = float(s.get("cube_size", 1.0)) + float(s.get("gutter", 0.0))
    L = md["layers"]
    inter, util = L["interactables"], L["utilities"]

    def size_of(name):
        e = sizes.get(name)
        if e and float(e.get("base_m", 0)) > 0.05:
            return float(e["base_m"]), float(e.get("height_m", 1.0)), True
        if name == "station_wall":
            return 12.0, 4.5, False
        if name == "cube_staircase":
            return 2.0, 2.0, False
        return 1.0, 1.0, False  # estimated fallback for unmeasured / procedural

    arts = []  # [name, wx, wz, base, height, measured]
    for z in range(len(inter)):
        for x in range(len(inter[z])):
            t = str(inter[z][x]).strip()
            if not t or t == " ":
                continue
            if t.startswith("cluster:"):
                cname = t.split("#")[0].split(":")[1]
                cp = os.path.join(ROOT, "commons", "data", "curated_walls", "clusters", cname + ".json")
                if os.path.exists(cp):
                    for pc in load(cp).get("pieces", []):
                        pn = pc.get("token", "")
                        b, h, m = size_of(pn)
                        if pn == "station_wall":
                            cfg = pc.get("config", {})
                            b, h = float(cfg.get("width_cells", 12)), float(cfg.get("height", 4.5))
                        arts.append([pn, x * cube + float(pc.get("x", 0)), z * cube + float(pc.get("z", 0)), b, h, m])
                continue
            b, h, m = size_of(t)
            arts.append([t, x * cube, z * cube, b, h, m])

    spawn = exit_ = None
    for z in range(len(util)):
        for x in range(len(util[z])):
            c = str(util[z][x]).strip()
            if c == "s":
                spawn = (x * cube, z * cube)
            elif c == "t":
                exit_ = (x * cube, z * cube)

    W = len(inter[0]) if inter else 0
    H = len(inter)
    print("# %s  -  %dx%d cells, cube %.1fm, %d bodies\n" % (a.map, W, H, cube, len(arts)))

    print("SIZES (real footprint, biggest first):")
    for n, wx, wz, b, h, m in sorted(arts, key=lambda r: -r[3]):
        print("  %-40s base %5.2fm  h %5.2fm  @(%4.1f,%4.1f)%s"
              % (n, b, h, wx, wz, "" if m else "  [estimated]"))
    print()

    floor = [r for r in arts if r[0] != "station_wall"]
    print("CLEARANCE  (gaps that should be >= %.1fm to walk between):" % a.walk)
    issues = 0
    for i in range(len(floor)):
        for j in range(i + 1, len(floor)):
            n1, x1, z1, b1, _, _ = floor[i]
            n2, x2, z2, b2, _, _ = floor[j]
            d = math.hypot(x1 - x2, z1 - z2)
            gap = d - (b1 / 2 + b2 / 2)
            if gap < a.walk:
                issues += 1
                print("  [%-7s] %-26s <-> %-26s gap %+5.2fm (centers %.2fm)"
                      % ("OVERLAP" if gap < 0 else "tight", n1, n2, gap, d))
    if not issues:
        print("  all clear")
    print()

    # walk path: spawn -> nearest-neighbour through floor bodies -> exit
    pts = []
    if spawn:
        pts.append(("SPAWN", spawn[0], spawn[1]))
    cur = spawn if spawn else (floor[0][1], floor[0][2])
    rem = list(floor)
    while rem:
        rem.sort(key=lambda r: math.hypot(r[1] - cur[0], r[2] - cur[1]))
        nx = rem.pop(0)
        pts.append((nx[0], nx[1], nx[2]))
        cur = (nx[1], nx[2])
    if exit_:
        pts.append(("EXIT", exit_[0], exit_[1]))

    half = math.radians(a.fov / 2)
    print("RIDE LOG  (gaze FOV %.0fdeg, facing direction of travel) - what hits the cortex:" % a.fov)
    for i in range(len(pts) - 1):
        nm, px, pz = pts[i]
        _, qx, qz = pts[i + 1]
        fa = math.atan2(qz - pz, qx - px)
        hits = []
        for n, wx, wz, b, h, m in arts:
            d = math.hypot(wx - px, wz - pz)
            if d < 0.3:
                continue
            ang = (math.atan2(wz - pz, wx - px) - fa + math.pi) % (2 * math.pi) - math.pi
            if abs(ang) > half:
                continue
            angw = math.degrees(2 * math.atan((b / 2) / max(d, 0.3)))
            hits.append([angw, n, d, math.degrees(ang)])
        vis = []
        for angw, n, d, ang in sorted(hits, key=lambda r: r[2]):  # near -> far
            if not any(abs(ang - a2) < aw2 / 2 for aw2, n2, d2, a2 in vis):
                vis.append([angw, n, d, ang])
        vis.sort(reverse=True)
        print("\n  step %d  @(%.0f,%.0f) -> %-14s facing %+.0fdeg" % (i, px, pz, pts[i + 1][0], math.degrees(fa)))
        if not vis:
            print("    (nothing in view - dead step)")
        for angw, n, d, ang in vis[:5]:
            sz = "HUGE" if angw > 55 else "big" if angw > 28 else "med" if angw > 12 else "small"
            pos = "left" if ang < -12 else "right" if ang > 12 else "CENTER"
            print("    %-38s %-5s %3.0fdeg  %-6s %4.1fm" % (n, sz, angw, pos, d))


if __name__ == "__main__":
    main()
