#!/usr/bin/env python3
"""check_body_overlap.py — do two placed bodies claim the same floor?

THE GAP THIS FILLS, and it cost a real collision to find. Every check in the placement
pipeline works on CELLS: the footprint fits, the cells are empty, map_pathfinder walks the
grid and returns OK. None of them sees a MESH. So two artifacts whose measured bodies
overlap in metres pass every gate, because the grid never knew how wide they were.

Found by capturing Trial_castelvecchio_fractals and reading the top view: ladder_hall (5.85 m,
placed at col 4) overlaps an exhibit_furniture plinth at col 1 by 0.22 m. The placer had
reserved cols 4..9, believing a body extends rightward from its token; the grid CENTRES a
body on its cell, so it actually occupies 1.08..6.92. Three cells reserved for nothing and
three never checked.

This reads every map, expands each placed token to its measured AABB about its own cell, and
reports pairs that intersect. It is deliberately a SEPARATE tool from the placer: the placer
can only be wrong about what it is about to write, and this is wrong about what is already
there — including everything placed before this pipeline existed.

Usage:
  python tools/check_body_overlap.py                  # whole corpus
  python tools/check_body_overlap.py --map=<Name>
  python tools/check_body_overlap.py --min=0.10       # ignore overlaps under 10 cm
"""
from __future__ import annotations
import glob
import json
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parents[1]
MAPS = REPO / "commons" / "maps"
REG = REPO / "commons" / "artifacts" / "registry"

## Below this a "collision" is two things touching, which rooms do on purpose.
DEFAULT_MIN = 0.05
## Past this a measurement is an escape, not a body — see place_syntheses.SANE_MAX_M.
SANE_MAX_M = 60.0


def registry() -> dict:
    out = {}
    for f in sorted(glob.glob(str(REG / "*.json"))):
        try:
            d = json.loads(pathlib.Path(f).read_text(encoding="utf-8")).get("artifacts", {})
        except Exception:
            continue
        for t, e in (d or {}).items():
            if isinstance(e, dict):
                out[t] = e
    return out


def body(entry: dict):
    """(w, d) in metres, or None when the measurement cannot be trusted."""
    s = ((entry or {}).get("measurements") or {}).get("aabb_size")
    if not (isinstance(s, list) and len(s) == 3):
        return None
    try:
        w, h, dd = float(s[0]), float(s[1]), float(s[2])
    except (TypeError, ValueError):
        return None
    if not all(v == v and abs(v) != float("inf") for v in (w, h, dd)):
        return None
    if max(w, h, dd) > SANE_MAX_M or max(w, dd) <= 0.0:
        return None
    return w, dd


def main() -> int:
    only = ""
    min_ov = DEFAULT_MIN
    for a in sys.argv[1:]:
        if a.startswith("--map="):
            only = a.split("=", 1)[1]
        elif a.startswith("--min="):
            min_ov = float(a.split("=", 1)[1])

    reg = registry()
    hits = []
    scanned = 0
    for mp in sorted(glob.glob(str(MAPS / "*" / "map_data.json"))):
        name = pathlib.Path(mp).parent.name
        if only and name != only:
            continue
        try:
            d = json.loads(pathlib.Path(mp).read_text(encoding="utf-8"))
        except Exception:
            continue
        il = (d.get("layers") or {}).get("interactables") or []
        scanned += 1
        boxes = []
        for r, row in enumerate(il):
            for c, cell in enumerate(row):
                s = str(cell).strip()
                if not s:
                    continue
                tok = re.split(r"[:#]", s)[0]
                b = body(reg.get(tok))
                if b is None:
                    continue
                w, dd = b
                # THE BODY IS CENTRED ON ITS CELL. One cell is one metre.
                boxes.append((tok, r, c, c - w / 2.0, c + w / 2.0, r - dd / 2.0, r + dd / 2.0))
        for i in range(len(boxes)):
            for j in range(i + 1, len(boxes)):
                a, b2 = boxes[i], boxes[j]
                ox = min(a[4], b2[4]) - max(a[3], b2[3])
                oz = min(a[6], b2[6]) - max(a[5], b2[5])
                if ox > min_ov and oz > min_ov:
                    hits.append((name, a[0], (a[1], a[2]), b2[0], (b2[1], b2[2]),
                                 round(min(ox, oz), 2)))

    hits.sort(key=lambda h: -h[5])
    if hits:
        print(f"{'map':<40}{'body A':<24}{'body B':<24}overlap")
        print("-" * 100)
        for m, ta, pa, tb, pb, ov in hits[:40]:
            print(f"{m:<40}{ta+' '+str(pa):<24}{tb+' '+str(pb):<24}{ov} m")
        if len(hits) > 40:
            print(f"  … and {len(hits) - 40} more")
        print("-" * 100)
    print(f"{scanned} maps scanned · {len(hits)} body overlaps over {min_ov} m")
    return 1 if hits else 0


if __name__ == "__main__":
    raise SystemExit(main())
