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


## No room in this corpus is larger than this. A body measuring past it has not been
## measured, it has ESCAPED — and the difference matters because the two failures look
## identical to a placer that only checks for absence.
SANE_MAX_M = 60.0

## A synthesis is the comparison its members cannot make alone, so it has to be READABLE
## against them. Past this many cells it is simply a different artifact in the same postcode:
## the walker meets it without meeting what it argues about. Measured cases that forced the
## rule — grain_block offered a slot 101.6 cells from its sources, slack_yard 18.5.
MAX_CELLS_FROM_SOURCES = 12.0

## Auto_* is the generator's scratch output, not a curated room. Auto_Point_One is 506 rows
## by 17 with no display name; a body placed there is a body nobody walks to.
SKIP_MAP_PREFIXES = ("Auto_",)


def footprint(entry: dict):
    """Cells the MEASURED body needs, or None when it cannot be trusted.

    REFUSING AN ABSURD MEASUREMENT IS AS IMPORTANT AS REFUSING A MISSING ONE, and that was
    learned the expensive way. A corpus-wide re-measure turned 39 artifacts that had recorded
    [0,0,0] into boxes of 1000 m, 10000 m and one of 9.4e19 m — runaway particles and float
    overflow, not bodies. The earlier version of this function refused only `None`, so every
    one of those would have been placed: a 10 km artifact dropped into a 13-cell room, and
    the map would still have passed the pathfinder because the grid never sees the mesh.
    """
    m = entry.get("measurements") or {}
    s = m.get("aabb_size")
    if not (isinstance(s, list) and len(s) == 3):
        return None
    try:
        w, h, d = float(s[0]), float(s[1]), float(s[2])
    except (TypeError, ValueError):
        return None
    if not all(math.isfinite(v) for v in (w, h, d)):
        return None
    if max(w, h, d) > SANE_MAX_M:
        return None
    if max(w, h, d) <= 0.0:
        return None
    return max(1, math.ceil(w - 0.001)), max(1, math.ceil(d - 0.001))


def token_of(cell: str) -> str:
    c = str(cell).strip()
    return re.split(r"[:#]", c)[0] if c else ""


def map_files() -> list:
    return sorted(glob.glob(str(MAPS / "*" / "map_data.json")))


def host_maps(sources: list, placed: dict) -> list:
    """Every map holding at least one source, richest first.

    RETURNING A LIST RATHER THAN A WINNER, because the first version took
    `most_common(1)` and gave up when that one map had no room — residue_hall was refused on
    a map holding 3 of its 4 sources while another map holding 3 of 4 sat empty. The tie is
    also arbitrary: two maps with equal source counts come back in dict order, so the same
    query answered differently between a dry run and an apply. Trying them in order removes
    both faults, and a synthesis that lands in the second-richest room is still standing with
    its family.
    """
    cnt = collections.Counter()
    for s in sources:
        for m in placed.get(s, ()):
            cnt[m] += 1
    # sort by source count then name, so the order is stable across runs
    return sorted(cnt.items(), key=lambda kv: (-kv[1], kv[0]))


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

    # THE GRID CENTRES A BODY ON ITS CELL, IT DOES NOT EXTEND IT RIGHTWARD, and the first
    # version of this tool assumed the opposite. ladder_hall is 5.85 m; placed at col 4 it
    # was given cols 4..9 and actually occupies 1.08..6.92 — so three cells were reserved
    # that needed nothing and three were never checked at all. Col 1 held an
    # exhibit_furniture plinth, and the two bodies overlap by 0.22 m in the built map.
    #
    # NOTHING CAUGHT IT. The footprint fitted, the cells were free, map_pathfinder returned
    # 1 OK / 0 FAIL, and the semantic diff was exactly one cell. The grid never sees the
    # mesh, so a collision between two bodies is invisible to every check in this pipeline
    # except looking at the room. It was found by capturing the map and reading the top view.
    pad_w, pad_d = (w - 1) // 2, (d - 1) // 2

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
            # (r, c) is where the TOKEN goes; the body straddles it, so test the span the
            # body will actually occupy rather than a rectangle hanging off one corner.
            ok = True
            for rr in range(r - pad_d, r + d - pad_d):
                for cc in range(c - pad_w, c + w - pad_w):
                    if blocked(rr, cc) or near_traffic(rr, cc):
                        ok = False
                        break
                if not ok:
                    break
            if not ok:
                continue
            if near is None:
                return r, c
            # the token cell IS the body's centre now, so that is what to measure from
            cy, cx = float(r), float(c)
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
        srcs = [str(s) for s in ((e.get("dna") or {}).get("sources") or [])]
        cands = host_maps(srcs, placed)
        if not cands:
            rows.append((t, "-", "no source of this synthesis is placed anywhere", None))
            continue
        found = None
        tried = 0
        for hm, n in cands:
            tried += 1
            if hm.startswith(SKIP_MAP_PREFIXES):
                continue
            mp = MAPS / hm / "map_data.json"
            if not mp.exists():
                continue
            d = json.loads(mp.read_text(encoding="utf-8"))
            near = source_centroid(d.get("layers") or {}, srcs)
            slot = free_slot(d.get("layers") or {}, fp[0], fp[1], near)
            if slot is None:
                continue
            gap = None if near is None else math.dist(
                (slot[0] + (fp[1] - 1) / 2.0, slot[1] + (fp[0] - 1) / 2.0), near)
            if gap is not None and gap > MAX_CELLS_FROM_SOURCES:
                continue                      # in the room, but not with its family
            dist = "" if gap is None else " %.1f cells from its sources" % gap
            extra = f" (host {tried} of {len(cands)})" if tried > 1 else ""
            found = (t, hm,
                     f"{fp[0]}x{fp[1]} at ({slot[0]},{slot[1]}) · {n}/{len(srcs)} sources here ·{dist}{extra}",
                     (mp, slot, fp, srcs))
            break
        if found:
            rows.append(found)
        else:
            rows.append((t, cands[0][0],
                         f"no free {fp[0]}x{fp[1]} floor in any of {len(cands)} maps holding a source",
                         None))

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
        # PRESERVE THE FILE'S OWN FORMAT. json.dumps(indent=1) once reformatted every map it
        # wrote — one cell in Gallery_BarArray produced a 391/83 diff — so the write below is
        # followed by the project's canonical compacter.
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
