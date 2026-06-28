#!/usr/bin/env python3
"""Consolidate every artifact's measured AABB into ONE manifest: commons/data/artifact_sizes.json.

Reads measurements.aabb_size / max_dimension_m / grid_cells from every registry under
commons/artifacts/registry/*.json (populated by tools/measure_artifact_aabbs.py) and writes a
single flat lookup so any tool (cap-fit, footprints, placement) has one source of truth for size.

  sizes[lookup_name] = {aabb_size:[w,h,d], base_m, height_m, max_dimension_m, grid_cells,
                        registry, measured_at}

base_m = max(aabb_size.x, aabb_size.z) — the horizontal footprint a plinth cap must cover.
Artifacts with NO measurement are listed under "unmeasured" so the gap stays visible.
"""
import json
import glob
import os
from datetime import datetime, timezone

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REG = os.path.join(ROOT, "commons", "artifacts", "registry")
OUT = os.path.join(ROOT, "commons", "data", "artifact_sizes.json")


def main():
    sizes = {}
    unmeasured = []
    total = 0
    for p in sorted(glob.glob(os.path.join(REG, "*.json"))):
        try:
            d = json.load(open(p, encoding="utf-8"))
        except Exception:
            continue
        arts = d.get("artifacts")
        if not isinstance(arts, dict):
            continue
        reg = os.path.basename(p)[:-5]
        for key, e in arts.items():
            if not isinstance(e, dict):
                continue
            lname = e.get("lookup_name", key)
            total += 1
            m = e.get("measurements") or {}
            sz = m.get("aabb_size")
            if sz and len(sz) >= 3:
                w, h, dz = round(float(sz[0]), 3), round(float(sz[1]), 3), round(float(sz[2]), 3)
                sizes[lname] = {
                    "aabb_size": [w, h, dz],
                    "base_m": round(max(w, dz), 3),
                    "height_m": h,
                    "max_dimension_m": m.get("max_dimension_m"),
                    "grid_cells": m.get("grid_cells"),
                    "registry": reg,
                    "measured_at": m.get("measured_at"),
                }
            else:
                unmeasured.append(lname)
    manifest = {
        "_generated": datetime.now(timezone.utc).isoformat(),
        "_source": "registry measurements.aabb_size (run tools/measure_artifact_aabbs.py to refresh)",
        "_note": "base_m = max(aabb_size.x, aabb_size.z) — the horizontal footprint a plinth cap must cover.",
        "count": len(sizes),
        "unmeasured_count": len(unmeasured),
        "unmeasured": sorted(unmeasured),
        "sizes": dict(sorted(sizes.items())),
    }
    json.dump(manifest, open(OUT, "w", encoding="utf-8"), indent=1)
    print("wrote %s" % os.path.relpath(OUT, ROOT))
    print("  measured:   %d / %d artifacts" % (len(sizes), total))
    print("  unmeasured: %d" % len(unmeasured))
    if unmeasured:
        print("   " + ", ".join(sorted(unmeasured)[:24]) + (" …" if len(unmeasured) > 24 else ""))


if __name__ == "__main__":
    main()
