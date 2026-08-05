#!/usr/bin/env python3
"""
build_lattice_bands.py — the seventeen wallpaper groups as floor bands.

The symmetry chapter's truth is that "a pattern is not a picture — it is a rule
performed", and that there are exactly seventeen ways a flat pattern can repeat:
the one census in this book that CLOSES. The museum belt lays courses across a
corridor. So the groups can BE courses: a band whose podiums stand on the orbit
of one seed point under a named plane group, which is a floor pattern with a
mathematical warrant rather than a taste.

WHAT IS HONEST HERE. Twelve of the seventeen groups have a square lattice and
land exactly on our grid. FIVE DO NOT: p3, p31m, p3m1, p6 and p6m are
hexagonal, and a square grid cannot hold three- or six-fold rotation. Those are
generated on a sheared approximation and flagged `exact: false` — the grid's own
limit, named rather than hidden. (This is the chapter's argument in miniature:
the census closes in the plane, not in every encoding of it.)

AND THE MEASUREMENT THE TOOL EXISTS FOR: podiums are furniture you walk AROUND,
so a dense group floors a corridor you can no longer cross. Every generated band
is tiled to the corridor width, walked, and only kept if the walk survives — so
the output answers "which of the seventeen can floor a 13-wide museum and still
be a museum?"

  python tools/build_lattice_bands.py            # report
  python tools/build_lattice_bands.py --emit     # merge bands into template_patterns.json
  python tools/build_lattice_bands.py --self-test
"""
from __future__ import annotations
import argparse
import json
import sys
from collections import deque
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PATTERNS = REPO / "commons" / "data" / "template_patterns.json"
STAND = {"1", "1s"}
N = 6                      # unit cell edge, in cells
WIDTHS = (13, 15, 17)

# Each group as the generators of its point group acting on the unit cell, in
# integer cell coordinates modulo N. (x, y) -> (x', y'); glides carry a half
# translation, which is what distinguishes pg from pm and pgg from pmm.
H = N // 2
GROUPS: dict[str, dict] = {
    "p1":   {"ops": [lambda x, y: (x, y)], "exact": True},
    "p2":   {"ops": [lambda x, y: (x, y), lambda x, y: (-x, -y)], "exact": True},
    "pm":   {"ops": [lambda x, y: (x, y), lambda x, y: (-x, y)], "exact": True},
    "pg":   {"ops": [lambda x, y: (x, y), lambda x, y: (-x, y + H)], "exact": True},
    "cm":   {"ops": [lambda x, y: (x, y), lambda x, y: (-x, y),
                     lambda x, y: (x + H, y + H), lambda x, y: (-x + H, y + H)], "exact": True},
    "pmm":  {"ops": [lambda x, y: (x, y), lambda x, y: (-x, y),
                     lambda x, y: (x, -y), lambda x, y: (-x, -y)], "exact": True},
    "pmg":  {"ops": [lambda x, y: (x, y), lambda x, y: (-x, -y),
                     lambda x, y: (-x, y + H), lambda x, y: (x, -y + H)], "exact": True},
    "pgg":  {"ops": [lambda x, y: (x, y), lambda x, y: (-x, -y),
                     lambda x, y: (-x + H, y + H), lambda x, y: (x + H, -y + H)], "exact": True},
    "cmm":  {"ops": [lambda x, y: (x, y), lambda x, y: (-x, y), lambda x, y: (x, -y),
                     lambda x, y: (-x, -y), lambda x, y: (x + H, y + H),
                     lambda x, y: (-x + H, y + H), lambda x, y: (x + H, -y + H),
                     lambda x, y: (-x + H, -y + H)], "exact": True},
    "p4":   {"ops": [lambda x, y: (x, y), lambda x, y: (-y, x),
                     lambda x, y: (-x, -y), lambda x, y: (y, -x)], "exact": True},
    "p4m":  {"ops": [lambda x, y: (x, y), lambda x, y: (-y, x), lambda x, y: (-x, -y),
                     lambda x, y: (y, -x), lambda x, y: (y, x), lambda x, y: (-x, y),
                     lambda x, y: (-y, -x), lambda x, y: (x, -y)], "exact": True},
    "p4g":  {"ops": [lambda x, y: (x, y), lambda x, y: (-y, x), lambda x, y: (-x, -y),
                     lambda x, y: (y, -x), lambda x, y: (y + H, x + H),
                     lambda x, y: (-x + H, y + H), lambda x, y: (-y + H, -x + H),
                     lambda x, y: (x + H, -y + H)], "exact": True},
    # hexagonal — approximated on a square grid, and said so
    "p3":   {"ops": [lambda x, y: (x, y), lambda x, y: (-y, x - y),
                     lambda x, y: (y - x, -x)], "exact": False},
    "p31m": {"ops": [lambda x, y: (x, y), lambda x, y: (-y, x - y), lambda x, y: (y - x, -x),
                     lambda x, y: (y, x), lambda x, y: (x - y, -y),
                     lambda x, y: (-x, y - x)], "exact": False},
    "p3m1": {"ops": [lambda x, y: (x, y), lambda x, y: (-y, x - y), lambda x, y: (y - x, -x),
                     lambda x, y: (-y, -x), lambda x, y: (y - x, y),
                     lambda x, y: (x, x - y)], "exact": False},
    "p6":   {"ops": [lambda x, y: (x, y), lambda x, y: (-y, x - y), lambda x, y: (y - x, -x),
                     lambda x, y: (-x, -y), lambda x, y: (y, y - x),
                     lambda x, y: (x - y, x)], "exact": False},
    "p6m":  {"ops": [lambda x, y: (x, y), lambda x, y: (-y, x - y), lambda x, y: (y - x, -x),
                     lambda x, y: (-x, -y), lambda x, y: (y, y - x), lambda x, y: (x - y, x),
                     lambda x, y: (y, x), lambda x, y: (x - y, -y), lambda x, y: (-x, y - x),
                     lambda x, y: (-y, -x), lambda x, y: (y - x, y),
                     lambda x, y: (x, x - y)], "exact": False},
}
SEED = (1, 2)     # one point; the group does the rest


def orbit(group: str) -> set:
    ox, oy = SEED
    return {((f(ox, oy)[0]) % N, (f(ox, oy)[1]) % N) for f in GROUPS[group]["ops"]}


def band(group: str, w: int, rows: int) -> list:
    """The group's orbit tiled across a corridor of width w, `rows` deep."""
    pts = orbit(group)
    return [["2s" if ((x % N), (y % N)) in pts else "1" for x in range(w)]
            for y in range(rows)]


def walks(tile: list) -> tuple[bool, int]:
    """Can a body cross this band? (podiums are furniture, not floor)"""
    h = len(tile)
    w = len(tile[0]) if h else 0
    starts = [(0, x) for x in range(w) if tile[0][x] in STAND]
    seen, q = set(starts), deque(starts)
    while q:
        y, x = q.popleft()
        if y == h - 1:
            return True, len(seen)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and (ny, nx) not in seen and tile[ny][nx] in STAND:
                seen.add((ny, nx))
                q.append((ny, nx))
    return False, len(seen)


def survey(rows: int = 6) -> list:
    out = []
    for g in GROUPS:
        pts = orbit(g)
        row = {"group": g, "exact": GROUPS[g]["exact"], "orbit": len(pts), "widths": {}}
        for w in WIDTHS:
            t = band(g, w, rows)
            ok, reach = walks(t)
            podiums = sum(1 for r in t for c in r if c == "2s")
            row["widths"][w] = {"walks": ok, "podiums": podiums,
                                "density": round(podiums / (w * rows), 3)}
        out.append(row)
    return out


def emit(rows: int = 6) -> int:
    data = json.loads(PATTERNS.read_text(encoding="utf-8"))
    pats = data.setdefault("patterns", {})
    kept = 0
    for g in GROUPS:
        for w in WIDTHS:
            t = band(g, w, rows)
            ok, _ = walks(t)
            if not ok:
                continue    # a floor you cannot cross is not a floor
            ex = GROUPS[g]["exact"]
            pats[f"lattice:{g}-{w}"] = {
                "label": f"{g} lattice band - {w} wide" + ("" if ex else " (approx)"),
                "color": "#7fa8ce" if ex else "#8a7fce",
                "w": w, "h": rows, "mode": "stamp", "tile": t,
                "lattice": True, "group": g, "exact_on_square_grid": ex,
                "orbit": len(orbit(g)),
                "note": "the seventeen-group census as a floor course "
                        "(tools/build_lattice_bands.py); podiums stand on the orbit of one "
                        "seed under the named plane group",
            }
            kept += 1
    PATTERNS.write_text(json.dumps(data, indent=1, ensure_ascii=False), encoding="utf-8")
    return kept


def selftest() -> int:
    ok = []
    ok.append(("A the census is complete", len(GROUPS) == 17, f"{len(GROUPS)} groups"))
    ok.append(("B twelve are exact on a square grid",
               sum(1 for g in GROUPS.values() if g["exact"]) == 12,
               f"{sum(1 for g in GROUPS.values() if g['exact'])} exact"))
    # a group's orbit must be closed under its own operations, or it is not a group
    closed = True
    for g in GROUPS:
        pts = orbit(g)
        for (x, y) in pts:
            for f in GROUPS[g]["ops"]:
                nx, ny = f(x, y)
                if ((nx % N), (ny % N)) not in pts:
                    closed = False
    ok.append(("C every orbit is closed under its own ops", closed, "group axiom"))
    ok.append(("D p1 is the trivial orbit", len(orbit("p1")) == 1, f"{len(orbit('p1'))} point"))
    ok.append(("E p4m is richer than p4", len(orbit("p4m")) > len(orbit("p4")),
               f"p4m {len(orbit('p4m'))} vs p4 {len(orbit('p4'))}"))
    solid = [["2s"] * 13 for _ in range(6)]
    ok.append(("F a solid podium field is refused", not walks(solid)[0], "walk blocked"))
    for label, good, detail in ok:
        print(f"  {'PASS' if good else 'FAIL'}  {label}: {detail}")
    n = sum(1 for _, g, _ in ok if g)
    print(f"self-test: {n}/{len(ok)} controls passed")
    return 0 if n == len(ok) else 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--rows", type=int, default=6)
    ap.add_argument("--emit", action="store_true")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        return selftest()
    rows = survey(args.rows)
    print(f"{'group':6} {'exact':5} {'orbit':5}  " + "  ".join(f"w{w:<9}" for w in WIDTHS))
    print("-" * 62)
    walkable = 0
    for r in rows:
        cells = []
        for w in WIDTHS:
            d = r["widths"][w]
            cells.append(f"{'ok ' if d['walks'] else 'BLOCK'} {d['density']:.2f}")
        if any(r["widths"][w]["walks"] for w in WIDTHS):
            walkable += 1
        print(f"{r['group']:6} {'yes' if r['exact'] else 'no ':5} {r['orbit']:5}  "
              + "  ".join(f"{c:<11}" for c in cells))
    print("-" * 62)
    print(f"{walkable}/17 groups can floor a corridor and still be crossed "
          f"(at {args.rows} rows deep)")
    if args.emit:
        n = emit(args.rows)
        print(f"-> {n} lattice bands merged into {PATTERNS.relative_to(REPO)} "
              f"(keys `lattice:*`, additive)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
