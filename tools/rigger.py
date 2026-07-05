#!/usr/bin/env python3
"""rigger.py — the glue pass (R-014): the relation graph run UNDERNEATH the floor.

The room is one thing, held together by its relations made visible. The Rigger
reads a generated room, pulls the relation graph of its placed walked artifacts
(embedding kinship via /api/artifact-pairs, counter-pairs from the dig report),
builds a maximum-kinship spanning tree ROOTED AT THE HERO — every relation flows
back to the room's reactor — and lays the tree into the floor as
station_floorline runs: flush lit conduits you read with your feet.
Counter-pairs get the opposite treatment: two facing THRESHOLD bars with an
unlit gap between them — the tension, inlaid.

Usage:
  python tools/rigger.py --map=Hangar_Primitives --seq=primitives [--write]
Edits the map's interactables in place (empty cells only). Re-run pathfinder after.
"""
from __future__ import annotations

import json
import math
import os
import re
import sys
import urllib.request

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.environ.get("ADA_ENCYCLOPEDIA_PATH", "C:/Users/palle/Documents/GitHub/ada_encyclopedia")
TUTORIAL_DIR = os.path.join(ENC, "public", "tutorial")
SIZES = os.path.join(REPO, "commons", "data", "artifact_sizes.json")
MAPS_DIR = os.path.join(REPO, "commons", "maps")
DIG_DIR = os.path.join(REPO, "doc", "book", "dig_reports")
API = "http://localhost:3003/api/artifact-pairs"

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass


def load_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def kinship(ids: list[str]) -> dict[tuple[str, str], float]:
    """pairwise cosine from the encyclopedia; graceful uniform fallback."""
    try:
        req = urllib.request.Request(API, data=json.dumps({"ids": ids}).encode(),
                                     headers={"Content-Type": "application/json"})
        d = json.load(urllib.request.urlopen(req, timeout=30))
        out = {}
        for p in d.get("pairs", []):
            a, b, s = p.get("a"), p.get("b"), float(p.get("sim", 0))
            out[(a, b)] = out[(b, a)] = s
        if out:
            return out
    except Exception as e:
        print(f"  (artifact-pairs API unavailable: {e} — uniform kinship)")
    return {(a, b): 0.5 for a in ids for b in ids if a != b}


def main() -> int:
    args = sys.argv[1:]
    map_name = next((a.split("=", 1)[1] for a in args if a.startswith("--map=")), None)
    seq = next((a.split("=", 1)[1] for a in args if a.startswith("--seq=")), None)
    write = "--write" in args
    if not map_name or not seq:
        print(__doc__)
        return 1

    t = load_json(os.path.join(TUTORIAL_DIR, f"{seq}.json")) or {}
    walk = []
    for p in t.get("pages", []):
        if p["kind"] == "primitive" and isinstance(p.get("artifact"), dict):
            walk.append(p["artifact"]["name"])
        elif p["kind"] == "walk":
            walk += [a["name"] for a in p.get("artifacts") or []]
    mpath = os.path.join(MAPS_DIR, map_name, "map_data.json")
    md = load_json(mpath)
    if not md:
        print(f"!! no map {map_name}")
        return 1
    gi = md["layers"]["interactables"]
    rows, cols = len(gi), len(gi[0])

    pos: dict[str, tuple[int, int]] = {}
    for r in range(rows):
        for c in range(cols):
            tok = str(gi[r][c]).strip().split("#")[0].split(":")[0]
            if tok in walk and tok not in pos:
                pos[tok] = (r, c)
    ids = list(pos)
    if len(ids) < 3:
        print(f"!! only {len(ids)} walked artifacts placed on the floor")
        return 1

    sizes = (load_json(SIZES) or {}).get("sizes") or {}
    hero = max(ids, key=lambda n: float((sizes.get(n) or {}).get("base_m", 1.0)))
    kin = kinship(ids)

    # maximum-kinship spanning tree, Prim from the hero (the reactor)
    in_tree = {hero}
    edges: list[tuple[str, str, float]] = []
    while len(in_tree) < len(ids):
        best = None
        for a in in_tree:
            for b in ids:
                if b in in_tree:
                    continue
                s = kin.get((a, b), 0.0)
                if best is None or s > best[2]:
                    best = (a, b, s)
        if not best:
            break
        edges.append(best)
        in_tree.add(best[1])

    # counter-pairs from the dig report (both ends placed)
    counters = []
    dig = ""
    try:
        dig = open(os.path.join(DIG_DIR, f"{seq}.md"), encoding="utf-8").read()
    except Exception:
        pass
    for a, b in re.findall(r"\*\*(\w+) ⟷ (\w+)\*\*", dig):
        if a in pos and b in pos:
            counters.append((a, b))

    def free(r, c):
        return 0 <= r < rows and 0 <= c < cols and str(gi[r][c]).strip() in ("", " ")

    def lay_run(r, c0, c1, style="line"):
        """horizontal run on row r from c0..c1 — one token at the free-est midpoint."""
        if abs(c1 - c0) < 1:
            return 0
        length = abs(c1 - c0) + 1
        mid = (c0 + c1) // 2
        for cc in [mid, mid - 1, mid + 1, mid - 2, mid + 2]:
            if free(r, cc):
                gi[r][cc] = f"station_floorline:0:0#length_cells:{length}#style:{style}"
                return length
        return 0

    def lay_run_v(c, r0, r1, style="line"):
        if abs(r1 - r0) < 1:
            return 0
        length = abs(r1 - r0) + 1
        mid = (r0 + r1) // 2
        for rr in [mid, mid - 1, mid + 1, mid - 2, mid + 2]:
            if free(rr, c):
                gi[rr][c] = f"station_floorline:90:0#length_cells:{length}#style:{style}"
                return length
        return 0

    laid = 0
    for a, b, s in edges:
        (r1, c1), (r2, c2) = pos[a], pos[b]
        laid += lay_run(r1, min(c1, c2), max(c1, c2))          # horizontal leg on a's row
        laid += lay_run_v(c2, min(r1, r2), max(r1, r2))        # vertical leg on b's column

    gaps = 0
    for a, b in counters:
        (r1, c1), (r2, c2) = pos[a], pos[b]
        # two facing THRESHOLD bars near each end of the (straight-ish) span — the gap stays dark
        for (rr, cc) in [(r1, c1 + (1 if c2 > c1 else -1)), (r2, c2 + (1 if c1 > c2 else -1))]:
            if free(rr, cc):
                gi[rr][cc] = "station_floorline:0:0#length_cells:1#style:threshold"
                gaps += 1

    print(f"{map_name}: rigged {len(edges)} relations from hero '{hero}' — "
          f"{laid} cells of underfloor conduit, {len(counters)} counter-pair(s) "
          f"marked with {gaps} facing thresholds (the gap stays dark)")
    for a, b, s in edges:
        print(f"  {a} ←{s:.2f}→ {b}")
    for a, b in counters:
        print(f"  ⚡ spark gap: {a} ⟷ {b}")
    if not write:
        print("(dry run — pass --write)")
        return 0
    with open(mpath, "w", encoding="utf-8") as f:
        json.dump(md, f, indent=1)
    print(f"wrote {mpath}")
    sys.path.insert(0, os.path.join(REPO, "tools"))
    from book_log import log_event
    log_event("room", f"{map_name} rigged (R-014): {len(edges)} relations laid under the floor "
                      f"from hero {hero} ({laid} conduit cells); {len(counters)} spark gap(s) — "
                      "the room wired into one apparatus")
    return 0


if __name__ == "__main__":
    sys.exit(main())
