#!/usr/bin/env python3
"""Fit each curated plinth's CAP to the artifact standing on it, so nothing overhangs.

The station plinth/micropod cap TAPERS in from the footprint (cap = footprint - 2*cap_inset),
so a 1x1 plinth presents only a ~0.68 m cap and a ~0.4 m micropod cap. An artifact whose
measured base (measurements.aabb_size, max horizontal) is wider than that cap OVERHANGS.

This grows the cap to fit: when the artifact's base + a small lip exceeds the prop's current
cap, it sets the plinth's config `cap_meters` (StationPlinth's fixed-cap lever) = base + MARGIN,
leaving already-fitting plinths untouched. cap_meters is horizontal-only, so the artifact's y
(it sits at top_height) does not change. Dry-run by default; pass --apply to write curated_walls.
"""
import json
import glob
import os
import sys
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CURATED = os.path.join(ROOT, "commons", "data", "curated_walls")
REG = os.path.join(ROOT, "commons", "artifacts", "registry")
APPLY = "--apply" in sys.argv

MARGIN = 0.10          # grown cap = artifact base + this (≈ a 5 cm lip per side)
TOL = 0.04             # only act when the overhang exceeds this (don't churn near-fits)
CAP_MAX = 2.4          # clamp the grown cap
PLINTH_MAX = 1.4       # a base bigger than this needs a multi-cell footprint / stage, not a wider cap — flag it

# Per-token plinth defaults — the .tscn values that are NOT in the wall config.
PLINTH_DEFAULTS = {
    "station_plinth":      {"cap_inset": 0.16, "base_meters": 0.0},
    "station_micropod":    {"cap_inset": 0.10, "base_meters": 0.6},
    "station_plinth_wide": {"cap_meters": 1.05},
}


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


def load_aabb():
    aabb = {}
    for p in glob.glob(os.path.join(REG, "*.json")):
        try:
            d = json.load(open(p, encoding="utf-8"))
        except Exception:
            continue
        arts = d.get("artifacts", d)
        if isinstance(arts, dict):
            for tok, e in arts.items():
                if isinstance(e, dict):
                    sz = (e.get("measurements") or {}).get("aabb_size")
                    if sz and len(sz) >= 3:
                        aabb[tok] = sz
    return aabb


def current_cap(token, cfg):
    """Replicate StationPlinth._build's cap-width formula for this token + config overrides."""
    d = dict(PLINTH_DEFAULTS.get(token, {}))
    d.update(cfg or {})
    if _f(d.get("cap_meters", 0.0)) > 0.0:
        return _f(d["cap_meters"])
    base_m = _f(d.get("base_meters", 0.0))
    if base_m > 0.0:
        wc = dc = min(max(base_m, 0.2), 1.0)
    else:
        fc = _i(d.get("footprint_cells", 1), 1)
        wc = float(_i(d.get("width_cells", fc), fc))
        dc = float(_i(d.get("depth_cells", fc), fc))
    cap_inset = _f(d.get("cap_inset", 0.16), 0.16)
    inset = min(cap_inset, min(wc, dc) * 0.28)
    return min(wc, dc) - 2.0 * inset


def main():
    aabb = load_aabb()
    PLINTHS = set(PLINTH_DEFAULTS)
    total = 0
    unmeasured = []
    toobig = []
    for wp in sorted(glob.glob(os.path.join(CURATED, "*.json"))):
        wall = json.load(open(wp, encoding="utf-8"))
        pieces = wall.get("pieces", [])
        fixes = []
        for pc in pieces:
            if pc.get("token") not in PLINTHS:
                continue
            cfg = pc.get("config", {}) or {}
            # multi-cell plinths already present a broad cap; their footprint, not the taper, governs.
            if (_i(cfg.get("width_cells", 1), 1) > 1 or _i(cfg.get("depth_cells", 1), 1) > 1
                    or _i(cfg.get("footprint_cells", 1), 1) > 1):
                continue
            art = next((q for q in pieces if q is not pc
                        and abs(_f(q.get("x")) - _f(pc.get("x"))) < 0.05
                        and abs(_f(q.get("z")) - _f(pc.get("z"))) < 0.05
                        and not str(q.get("token", "")).startswith("station_")), None)
            if not art:
                continue
            sz = aabb.get(art["token"])
            if not sz:
                unmeasured.append(art["token"])
                continue
            mx = max(_f(sz[0]), _f(sz[2]))
            if mx < 0.10:
                continue   # unbuilt / empty measurement -> leave on the default plinth (safer)
            cap = current_cap(pc["token"], cfg)
            if mx > cap + TOL:
                if mx > PLINTH_MAX:
                    toobig.append((os.path.basename(wp)[:-5], art["token"], mx))
                    continue
                new_cap = round(min(mx + MARGIN, CAP_MAX), 2)
                fixes.append((pc, art["token"], cap, mx, new_cap))
        for pc, _tok, _cap, _mx, new_cap in fixes:
            if APPLY:
                pc.setdefault("config", {})["cap_meters"] = new_cap
        if APPLY and fixes:
            json.dump(wall, open(wp, "w", encoding="utf-8"), indent=1)
        total += len(fixes)
        if fixes:
            print("%-30s %d:" % (os.path.basename(wp)[:-5], len(fixes)))
            for pc, tok, cap, mx, new_cap in fixes:
                print("    %-34s base %.2f > cap %.2f  ->  cap_meters %.2f" % (tok, mx, cap, new_cap))
    print("\nTOTAL: %d caps grown to fit  (%s)" % (total, "APPLIED" if APPLY else "dry-run"))
    if toobig:
        print("\nTOO BIG for a 1-cell plinth (base > %.1f m — needs a multi-cell plinth / stage, NOT a wider cap):" % PLINTH_MAX)
        for wname, art, mx in toobig:
            print("    %-22s %-32s base %.1f m  (large/applied artifact on a plinth, or an outlier AABB — review)" % (wname, art, mx))
    if unmeasured:
        c = Counter(unmeasured)
        print("\nUNMEASURED (no aabb_size in registry, left as-is): %d placements, %d distinct" % (len(unmeasured), len(c)))
        print("   " + ", ".join("%s(%d)" % (t, n) for t, n in c.most_common(14)))


if __name__ == "__main__":
    main()
