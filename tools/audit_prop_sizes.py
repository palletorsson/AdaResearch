#!/usr/bin/env python3
"""Audit: does every prop-mounted artifact in the curated walls sit on a RIGHT-SIZED prop?

For each station prop (plinth / micropod / wide) carrying a content artifact at the same (x,z),
compare the artifact's measured footprint (artifact_sizes.json aabb_size -> fx, fz) to the prop's
cap and classify. AXIS-AWARE: station_plinth.gd::_build sizes cap_w and cap_d INDEPENDENTLY
(cap_w = width_cells - 2*inset, cap_d = depth_cells - 2*inset), so an elongated plinth has a long
cap on one axis. The artifact fits if it fits in EITHER orientation (it may be rotated 90 deg).

  GOOD        fits the cap (either orientation), not wildly oversized
  OVERHANG    spills past the cap on both orientations (prop too small) and base <= 1.4 m
  TOO_BIG     base > 1.4 m on a 1-cell prop -> needs a multi-cell footprint / open floor, not a cap
  OVERSIZED   cap much bigger than the artifact (wrong tier / wasteful)
  BENCH       a self-grounded _bench/_workbench/_desk/_console raised on a plinth (placement bug)
  JUNK        base < 0.08 m (unbuilt AABB) or > 5 m (runaway particle/fractal AABB) — bad measurement
  UNMEASURED  no size in the manifest (run tools/measure_artifact_aabbs.py)

"Right-sized" % is reported over the JUDGEABLE set (measured, non-bench, non-junk) so it isn't
deflated by issues that aren't about cap size.
"""
import json
import glob
import os
from collections import Counter, defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CURATED = os.path.join(ROOT, "commons", "data", "curated_walls")
MANIFEST = os.path.join(ROOT, "commons", "data", "artifact_sizes.json")

PLINTH_DEFAULTS = {
    "station_plinth":      {"cap_inset": 0.16, "base_meters": 0.0},
    "station_micropod":    {"cap_inset": 0.10, "base_meters": 0.6},
    "station_plinth_wide": {"cap_meters": 1.05},
}
PLINTHS = set(PLINTH_DEFAULTS)
SELF_GROUNDED = ("_bench", "_workbench", "_desk", "_console")

TOL = 0.04
PLINTH_MAX = 1.4
JUNK_LO, JUNK_HI = 0.08, 5.0
OVERSIZE_RATIO, OVERSIZE_ABS = 2.3, 0.40


def _f(v, d=0.0):
    try:
        return float(str(v))
    except Exception:
        return d


def _i(v, d=0):
    try:
        return int(float(str(v)))
    except Exception:
        return d


def cap_dims(token, cfg):
    """(cap_w, cap_d) matching station_plinth.gd::_build (independent axes; one shared inset)."""
    d = dict(PLINTH_DEFAULTS.get(token, {}))
    d.update(cfg or {})
    if _f(d.get("cap_meters", 0.0)) > 0.0:
        cm = _f(d["cap_meters"])
        return cm, cm
    base_m = _f(d.get("base_meters", 0.0))
    if base_m > 0.0:
        wc = dc = min(max(base_m, 0.2), 1.0)
    else:
        fc = _i(d.get("footprint_cells", 1), 1)
        wc = float(_i(d.get("width_cells", fc), fc))
        dc = float(_i(d.get("depth_cells", fc), fc))
    cap_inset = _f(d.get("cap_inset", 0.16), 0.16)
    inset = min(cap_inset, min(wc, dc) * 0.28)   # _build applies the same inset on both axes
    return wc - 2.0 * inset, dc - 2.0 * inset


def is_multicell(cfg):
    return (_i(cfg.get("width_cells", 1), 1) > 1 or _i(cfg.get("depth_cells", 1), 1) > 1
            or _i(cfg.get("footprint_cells", 1), 1) > 1)


def classify(token, cfg, fx, fz):
    cw, cd = cap_dims(token, cfg)
    capmin = min(cw, cd)
    if fx is None:
        return "UNMEASURED", capmin
    base = max(fx, fz)
    if base < JUNK_LO or base > JUNK_HI:
        return "JUNK", capmin
    fits = ((fx <= cw + TOL and fz <= cd + TOL) or (fx <= cd + TOL and fz <= cw + TOL))
    if not fits:
        if base > PLINTH_MAX and not is_multicell(cfg):
            return "TOO_BIG", capmin
        return "OVERHANG", capmin
    if not is_multicell(cfg) and capmin > base * OVERSIZE_RATIO and (capmin - base) > OVERSIZE_ABS:
        return "OVERSIZED", capmin
    return "GOOD", capmin


def main():
    man = json.load(open(MANIFEST, encoding="utf-8"))
    sizes = man.get("sizes", {})
    verdicts = Counter()
    problems = defaultdict(list)
    walls = 0
    placements = 0

    for wp in sorted(glob.glob(os.path.join(CURATED, "*.json"))):
        wall = json.load(open(wp, encoding="utf-8"))
        pieces = wall.get("pieces", [])
        walls += 1
        name = os.path.basename(wp)[:-5]
        for pc in pieces:
            if pc.get("token") not in PLINTHS:
                continue
            cfg = pc.get("config", {}) or {}
            art = next((q for q in pieces if q is not pc
                        and abs(_f(q.get("x")) - _f(pc.get("x"))) < 0.06
                        and abs(_f(q.get("z")) - _f(pc.get("z"))) < 0.06
                        and not str(q.get("token", "")).startswith("station_")), None)
            if not art:
                continue
            placements += 1
            atok = str(art.get("token", ""))
            sz = sizes.get(atok, {}).get("aabb_size")
            fx = _f(sz[0]) if sz else None
            fz = _f(sz[2]) if sz else None
            if atok.endswith(SELF_GROUNDED):
                v, cap = "BENCH", min(cap_dims(pc["token"], cfg))
            else:
                v, cap = classify(pc["token"], cfg, fx, fz)
            verdicts[v] += 1
            if v != "GOOD":
                base = max(fx, fz) if fx is not None else float("nan")
                problems[v].append((name, atok, base, round(cap, 2)))

    judgeable = placements - verdicts["BENCH"] - verdicts["UNMEASURED"] - verdicts["JUNK"]
    good = verdicts["GOOD"]
    print("=== PROP-SIZE AUDIT (axis-aware) — %d walls, %d prop-mounted artifacts ===\n" % (walls, placements))
    for v in ["GOOD", "OVERHANG", "TOO_BIG", "OVERSIZED", "BENCH", "JUNK", "UNMEASURED"]:
        if verdicts.get(v):
            print("  %-10s %d" % (v, verdicts[v]))
    print("\n  -> of the %d JUDGEABLE (measured, non-bench, non-junk): %d right-sized, %d need a size fix (%.0f%% good)\n"
          % (judgeable, good, judgeable - good, 100.0 * good / max(judgeable, 1)))

    labels = {
        "OVERHANG": "prop too small (grow cap if <=1.4 m, else move to floor)",
        "TOO_BIG": "too big for any 1-cell cap -> multi-cell footprint or open floor",
        "OVERSIZED": "prop too big for the artifact (drop a tier)",
        "BENCH": "self-grounded furniture on a plinth -> take off the plinth",
        "JUNK": "bad measurement (re-measure)",
        "UNMEASURED": "no size yet (re-measure)",
    }
    for v in ["OVERHANG", "TOO_BIG", "OVERSIZED", "BENCH", "JUNK", "UNMEASURED"]:
        rows = problems.get(v)
        if not rows:
            continue
        print("--- %s (%d) — %s ---" % (v, len(rows), labels[v]))
        for wall, art, base, cap in sorted(rows):
            bs = ("%.2f" % base) if base == base else " n/a"
            print("    %-22s %-32s base %s  cap %.2f" % (wall, art, bs, cap))
        print()


if __name__ == "__main__":
    main()
