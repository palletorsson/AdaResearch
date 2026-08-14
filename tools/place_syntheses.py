#!/usr/bin/env python3
"""place_syntheses.py — stand each synthesis in the map where its own sources already stand.

WHY THIS EXISTS. Forty-two syntheses have been built across eleven waves and NOT ONE of them
is placed in a map. They have been swept, measured, predicted, critiqued and published to
galleries, and no player has ever met one. That is item 4 of doc/spatial/HANDOVER.md and it
is the largest thing still open in the DNA lineage.

THE PLACEMENT RULE, and it is derived rather than chosen: a synthesis goes where the most of
its OWN SOURCES already stand. A synthesis exists to make an argument no single member can
make, so the room that already holds the members is the room where the argument can be
checked against them. Measured over the corpus, 40 of 42 syntheses have such a room and six
have one holding every source they declare.

THE BODY WINS OVER THE AUTHORED ROOM, which is the corpus's standing ruling and matters here
more than usual: 9 of 39 measured syntheses declare a `footprint_cells` too small for their
own measured AABB, `foresight_range` worst at 12 declared against 7x19 = 133 needed. Placing
on the authored number would wedge an oversized body into an undersized hole, so this tool
reads `measurements.aabb_size` and refuses anything with no measurement at all.

WHAT IT WILL NOT DO:
  - overwrite an occupied cell, ever
  - place on anything but floor (structure height 1)
  - place on or beside a spawn or a teleporter — those cells are the map's entry and exit
  - place a body it has not measured

Usage:
  python tools/place_syntheses.py --dry-run          # report only
  python tools/place_syntheses.py --apply --limit=6  # place at most six
  python tools/place_syntheses.py --apply --token=ladder_hall
"""
from __future__ import annotations
import collections
import glob
import json
import math
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parents[1]
MAPS = REPO / "commons" / "maps"
REG = REPO / "commons" / "artifacts" / "registry"

## Cells a body may not stand on or next to. A synthesis dropped on the spawn is a synthesis
## the player is standing inside at t=0.
KEEP_CLEAR = 1


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


def syntheses(reg: dict) -> dict:
    return {t: e for t, e in reg.items()
            if str((e.get("dna") or {}).get("stage", "")) == "synthesis"}


def footprint(entry: dict):
    """Cells the MEASURED body needs, or None when it has never been measured."""
    m = entry.get("measurements") or {}
    s = m.get("aabb_size")
    if not (isinstance(s, list) and len(s) == 3):
        return None
    return max(1, math.ceil(s[0] - 0.001)), max(1, math.ceil(s[2] - 0.001))


def token_of(cell: str) -> str:
    c = str(cell).strip()
    return re.split(r"[:#]", c)[0] if c else ""


def map_files() -> list:
    return sorted(glob.glob(str(MAPS / "*" / "map_data.json")))


def host_map(sources: list, placed: dict) -> tuple:
    """The map holding the most of this synthesis's declared sources."""
    cnt = collections.Counter()
    for s in sources:
        for m in placed.get(s, ()):
            cnt[m] += 1
    best = cnt.most_common(1)
    return best[0] if best else (None, 0)


def source_centroid(layers: dict, sources: list):
    """Where this synthesis's own sources are standing in this map, as a row/col centre.

    THE POINT OF PLACING NEAR THEM. A synthesis is the comparison its members cannot make
    alone, so it has to be READABLE AGAINST THEM — a walker who meets the hall thirty cells
    away from the four benches it is arguing about is meeting a different artifact. A
    first-free scan does not do this: it drops bodies in whichever corner it reaches first,
    which is legal, cheap and curatorially useless.
    """
    il = layers.get("interactables") or []
    want = set(sources)
    pts = []
    for r, row in enumerate(il):
        for c, cell in enumerate(row):
            if token_of(cell) in want:
                pts.append((r, c))
    if not pts:
        return None
    return (sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts))


def free_slot(layers: dict, w: int, d: int, near=None):
    """Top-left of a w x d rectangle that is all floor, all empty, and clear of spawn/exit.

    When `near` is given, the CLOSEST such rectangle to that point wins rather than the first
    one scanning finds.
    """
    st = layers.get("structure") or []
    ut = layers.get("utilities") or []
    il = layers.get("interactables") or []
    if not st or not il:
        return None
    rows, cols = len(st), len(st[0])

    def blocked(r, c):
        if r < 0 or c < 0 or r >= rows or c >= len(st[r]):
            return True
        if str(st[r][c]).strip() != "1":          # floor only
            return True
        if r < len(il) and c < len(il[r]) and str(il[r][c]).strip():
            return True                            # occupied
        return False

    def near_traffic(r, c):
        for rr in range(r - KEEP_CLEAR, r + KEEP_CLEAR + 1):
            for cc in range(c - KEEP_CLEAR, c + KEEP_CLEAR + 1):
                if 0 <= rr < len(ut) and 0 <= cc < len(ut[rr]):
                    if str(ut[rr][cc]).strip():    # spawn, teleporter, ramp, anything
                        return True
        return False

    best = None
    best_score = None
    for r in range(rows):
        for c in range(cols):
            ok = True
            for rr in range(r, r + d):
                for cc in range(c, c + w):
                    if blocked(rr, cc) or near_traffic(rr, cc):
                        ok = False
                        break
                if not ok:
                    break
            if not ok:
                continue
            if near is None:
                return r, c
            # distance from the footprint's own centre to the sources' centre
            cy, cx = r + (d - 1) / 2.0, c + (w - 1) / 2.0
            score = (cy - near[0]) ** 2 + (cx - near[1]) ** 2
            if best_score is None or score < best_score:
                best_score, best = score, (r, c)
    return best


def main() -> int:
    apply = "--apply" in sys.argv
    limit = 0
    only = ""
    for a in sys.argv[1:]:
        if a.startswith("--limit="):
            limit = int(a.split("=", 1)[1])
        elif a.startswith("--token="):
            only = a.split("=", 1)[1]

    reg = registry()
    syn = syntheses(reg)

    placed = collections.defaultdict(set)
    for mp in map_files():
        name = pathlib.Path(mp).parent.name
        try:
            d = json.loads(pathlib.Path(mp).read_text(encoding="utf-8"))
        except Exception:
            continue
        for row in ((d.get("layers") or {}).get("interactables") or []):
            for cell in row:
                t = token_of(cell)
                if t:
                    placed[t].add(name)

    rows = []
    for t, e in sorted(syn.items()):
        if only and t != only:
            continue
        if placed.get(t):
            rows.append((t, "-", "already placed in " + sorted(placed[t])[0], None))
            continue
        fp = footprint(e)
        if fp is None:
            rows.append((t, "-", "NO MEASUREMENT - refusing to place a body of unknown size", None))
            continue
        srcs = (e.get("dna") or {}).get("sources") or []
        hm, n = host_map([str(s) for s in srcs], placed)
        if not hm:
            rows.append((t, "-", "no source of this synthesis is placed anywhere", None))
            continue
        mp = MAPS / hm / "map_data.json"
        d = json.loads(mp.read_text(encoding="utf-8"))
        near = source_centroid(d.get("layers") or {}, [str(s) for s in srcs])
        slot = free_slot(d.get("layers") or {}, fp[0], fp[1], near)
        if slot is None:
            rows.append((t, hm, f"no free {fp[0]}x{fp[1]} floor clear of traffic", None))
            continue
        dist = "" if near is None else " %.1f cells from its sources" % math.dist(
            (slot[0] + (fp[1] - 1) / 2.0, slot[1] + (fp[0] - 1) / 2.0), near)
        rows.append((t, hm, f"{fp[0]}x{fp[1]} at ({slot[0]},{slot[1]}) · {n}/{len(srcs)} sources here ·{dist}",
                     (mp, slot, fp, [str(s) for s in srcs])))

    print(f"{'synthesis':<24}{'host map':<38}plan")
    print("-" * 108)
    doable = [r for r in rows if r[3]]
    for t, hm, why, plan in rows:
        print(f"{t:<24}{str(hm):<38}{why}")
    print("-" * 108)
    print(f"{len(doable)} placeable of {len(rows)} considered")

    if not apply:
        print("\n(dry run — pass --apply to write)")
        return 0

    done = 0
    touched = set()
    for t, hm, why, plan in rows:
        if not plan:
            continue
        if limit and done >= limit:
            break
        mp, _slot, (w, d), srcs = plan
        # RE-READ AND RE-SOLVE AT WRITE TIME. The plan above was computed against the map as
        # it was before ANY placement, so two syntheses sharing a host can be handed the same
        # cell — pedagogical_sketchbook and subtraction_suite both wanted (0,1) of the same
        # map on the first run. Re-solving here means each one sees its predecessor.
        data = json.loads(mp.read_text(encoding="utf-8"))
        layers = data.get("layers") or {}
        near = source_centroid(layers, srcs)
        slot = free_slot(layers, w, d, near)
        if slot is None:
            print(f"  SKIP {t}: its slot in {hm} was taken by an earlier placement")
            continue
        r, c = slot
        # The token sits on the TOP-LEFT cell of its footprint; the grid places one token per
        # cell and the artifact's own body fills the rest, as every other placement here does.
        layers["interactables"][r][c] = f"{t}:0:0"
        mp.write_text(json.dumps(data, indent=1) + "\n", encoding="utf-8")
        print(f"  placed {t} in {hm} at ({r},{c})")
        touched.add(hm)
        done += 1
    if touched:
        print("\nmaps touched: " + " ".join(sorted(touched)))
    print(f"\n{done} placed. Now run: python tools/map_pathfinder.py check <MapName> --verbose")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
