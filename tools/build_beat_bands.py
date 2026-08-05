#!/usr/bin/env python3
"""
build_beat_bands.py — floor courses that keep someone else's rhythm.

tools/mine_level_patterns.py already measured the thing this needs: for the
VGLC Super Mario Bros corpus and for Ada's own authored maps, the gaps between
consecutive entities along the walk (`spacing_pool`), which perpendicular lane
they stand in (`lane_pool`), and how long the empty stretches run
(`breathing_pool`). Those distributions ARE a design language, and a belt band
is a stretch of corridor — so a band can be laid to Miyamoto's beat, or to our
own, and the two can stand next to each other in the same building.

WHAT IS BORROWED IS TIMING, NOT OBSTRUCTION. Mario's entities are mostly things
in your path; ours are things you stop at. A beat band therefore places FLOOR
slots (1s), which a body can stand on: the pattern taken is the rhythm of
encounter, and a band that blocked the corridor would be borrowing the wrong
thing. (The wallpaper bands carry the obstruction question — podiums you walk
around. The two answer different halves of "what is a floor pattern for".)

Sampling is seeded, so a beat is reproducible and can be ruled on; gaps are
drawn from the measured pool itself rather than from a fitted curve, because the
pool is the evidence and a fit would be a second opinion about it.

  python tools/build_beat_bands.py                 # report the corpora
  python tools/build_beat_bands.py --emit
  python tools/build_beat_bands.py --self-test
"""
from __future__ import annotations
import argparse
import json
import random
import sys
from collections import deque
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PATTERNS = REPO / "commons" / "data" / "template_patterns.json"
MINED = REPO / "doc" / "placement_research" / "level_patterns.json"
WIDTHS = (13, 15, 17)
STAND = {"1", "1s"}
CORPORA = {
    "mario_smb": ("Miyamoto beat", "#e0563d"),
    "ada_all_authored": ("Ada's own beat", "#7fce8a"),
}


def mined() -> dict:
    if not MINED.is_file():
        raise SystemExit(f"{MINED} missing — run tools/mine_level_patterns.py first")
    return json.loads(MINED.read_text(encoding="utf-8"))


def beat(corpus: dict, w: int, rows: int, seed: int) -> list:
    """Lay slots down the corridor on the corpus's own spacing and lane pools."""
    rng = random.Random(seed)
    spacing = [g for g in corpus.get("spacing_pool", []) if g >= 1] or [2]
    lanes = corpus.get("lane_pool") or [0.25, 0.25, 0.25, 0.25]
    tile = [["1"] * w for _ in range(rows)]
    z = rng.choice(spacing) % max(1, rows)
    while z < rows:
        # the lane is a quarter of the corridor's width, chosen by the corpus's
        # own distribution — Mario keeps three quarters of his entities low
        r = rng.random()
        acc, lane = 0.0, len(lanes) - 1
        for i, p in enumerate(lanes):
            acc += p
            if r <= acc:
                lane = i
                break
        lo = int(lane * w / len(lanes))
        hi = max(lo, int((lane + 1) * w / len(lanes)) - 1)
        x = rng.randint(lo, hi)
        tile[z][x] = "1s"
        z += rng.choice(spacing)
    return tile


def walks(tile: list) -> bool:
    h, w = len(tile), len(tile[0])
    starts = [(0, x) for x in range(w) if tile[0][x] in STAND]
    seen, q = set(starts), deque(starts)
    while q:
        y, x = q.popleft()
        if y == h - 1:
            return True
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and (ny, nx) not in seen and tile[ny][nx] in STAND:
                seen.add((ny, nx))
                q.append((ny, nx))
    return False


def describe(name: str, c: dict) -> dict:
    sp = sorted(c.get("spacing_pool", []))
    med = sp[len(sp) // 2] if sp else 0
    return {
        "corpus": name, "levels": c.get("n_levels"), "entities": c.get("total_entities"),
        "median_gap": med, "lanes": [round(v, 3) for v in (c.get("lane_pool") or [])],
        "mean_walk": round(float(c.get("mean_walk_length", 0)), 1),
    }


def emit(rows: int, seed: int) -> int:
    data = json.loads(PATTERNS.read_text(encoding="utf-8"))
    pats = data.setdefault("patterns", {})
    src = mined()
    kept = 0
    for key, (label, color) in CORPORA.items():
        c = src.get(key)
        if not c:
            continue
        for w in WIDTHS:
            t = beat(c, w, rows, seed)
            if not walks(t):
                continue
            slots = sum(1 for r in t for x in r if x == "1s")
            pats[f"beat:{key}-{w}"] = {
                "label": f"{label} - {w} wide", "color": color,
                "w": w, "h": rows, "mode": "stamp", "tile": t,
                "beat": True, "corpus": key, "seed": seed, "slots": slots,
                "note": "slots laid on the corpus's measured spacing and lane pools "
                        "(tools/build_beat_bands.py from tools/mine_level_patterns.py); "
                        "what is borrowed is timing, not obstruction",
            }
            kept += 1
    PATTERNS.write_text(json.dumps(data, indent=1, ensure_ascii=False), encoding="utf-8")
    return kept


def selftest() -> int:
    src = mined()
    c = src["mario_smb"]
    ok = []
    pool = set(g for g in c["spacing_pool"] if g >= 1)
    t1 = beat(c, 13, 12, 46)
    t2 = beat(c, 13, 12, 46)
    t3 = beat(c, 13, 12, 47)
    ok.append(("A the same seed lays the same beat", t1 == t2, "deterministic"))
    ok.append(("B a different seed lays a different one", t1 != t3, "seeded, not fixed"))
    zs = sorted(z for z, row in enumerate(t1) for x in row if x == "1s")
    gaps = [b - a for a, b in zip(zs, zs[1:])]
    ok.append(("C every gap comes from the measured pool",
               all(g in pool for g in gaps) if gaps else False,
               f"{len(gaps)} gaps, all in the corpus"))
    ok.append(("D the beat leaves the corridor walkable", walks(t1), "path survives"))
    # the borrowed rhythm must actually differ from ours, or the band says nothing
    a = beat(src["ada_all_authored"], 13, 12, 46)
    ok.append(("E Mario's beat differs from Ada's", a != t1, "distinct corpora"))
    for label, good, detail in ok:
        print(f"  {'PASS' if good else 'FAIL'}  {label}: {detail}")
    n = sum(1 for _, g, _ in ok if g)
    print(f"self-test: {n}/{len(ok)} controls passed")
    return 0 if n == len(ok) else 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--rows", type=int, default=12)
    ap.add_argument("--seed", type=int, default=46)
    ap.add_argument("--emit", action="store_true")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        return selftest()
    src = mined()
    print(f"{'corpus':20} {'levels':>6} {'entities':>8} {'med gap':>7} {'mean walk':>9}  lanes")
    print("-" * 78)
    for key in CORPORA:
        if key not in src:
            continue
        d = describe(key, src[key])
        print(f"{d['corpus']:20} {d['levels']:>6} {d['entities']:>8} {d['median_gap']:>7} "
              f"{d['mean_walk']:>9}  {d['lanes']}")
    print("-" * 78)
    print("lanes read across the corridor; Mario's mass sits in the lower two")
    if args.emit:
        n = emit(args.rows, args.seed)
        print(f"-> {n} beat bands merged into {PATTERNS.relative_to(REPO)} "
              f"(keys `beat:*`, additive, seed {args.seed})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
