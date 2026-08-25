#!/usr/bin/env python3
"""WHAT CHANGED BETWEEN TWO STAMPS — the halls, side by side.

2026-08-25, Palle: "can we also make some visual diff map side by side and see
what change between stamps?"

`em_map_halls.py --apply` writes em_plan.backup.json before it overwrites
em_plan.json, so every stamp already leaves a before and an after on disk.
This reads both, finds the authored halls whose derived tile or artifact set
moved, and draws them as a pair: before on the left, after on the right, with
every changed cell ringed.

    python tools/stamp_diff.py                       # ada_run/stamp_diff.svg
    python tools/stamp_diff.py --ascii               # in the terminal
    python tools/stamp_diff.py --before=X --after=Y --out=Z.svg

A hall that reads the same in both is not drawn — the point is the delta, and
a page of unchanged halls hides the two that moved. Halls that appeared or
vanished between the stamps are listed at the top, because a hall that stops
being authored is the change most likely to go unnoticed.

CELL COLOURS follow the museum's own tile vocabulary: 4 wall, 1 floor,
0 hole, p/pN platform. Artifacts are dots on the cell they stand on.
"""
from __future__ import annotations

import argparse
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILL = {"4": "#3b3b45", "1": "#d8d4cc", "0": "#0b0b0f"}
PLATFORM = "#8a7f6a"
CELL = 9
GAP = 34
PAD = 16


def load_rows(path):
    """map name -> row, for authored rows only (they are the ones a stamp owns)."""
    with open(path, encoding="utf-8") as fh:
        doc = json.load(fh)
    out = {}
    for row in doc.get("plans", []):
        if not isinstance(row, dict):
            continue
        name = str(row.get("map") or "")
        if name and row.get("authored"):
            out[name] = row
    return out


def tile_of(row):
    return [[str(c).strip() for c in r] for r in (row.get("tile") or [])]


def arts_of(row):
    out = {}
    for a in (row.get("artifacts") or []):
        cell = a.get("tile_cell") or a.get("cell") or []
        if len(cell) == 2:
            out[(int(cell[0]), int(cell[1]))] = str(a.get("token", "?"))
    return out


def diff_cells(a, b):
    """set of (x, z) whose tile value differs; None where a grid is short."""
    h = max(len(a), len(b))
    out = set()
    for z in range(h):
        ra = a[z] if z < len(a) else []
        rb = b[z] if z < len(b) else []
        for x in range(max(len(ra), len(rb))):
            va = ra[x] if x < len(ra) else None
            vb = rb[x] if x < len(rb) else None
            if va != vb:
                out.add((x, z))
    return out


def cell_fill(v):
    if v is None:
        return "#151519"
    if v.startswith("p"):
        return PLATFORM
    return FILL.get(v, "#6b6b76")


def draw(tile, arts, ox, oy, changed, mark):
    """one grid, as SVG rects; `changed` cells get a ring when `mark`."""
    out = []
    for z, row in enumerate(tile):
        for x, v in enumerate(row):
            out.append('<rect x="%d" y="%d" width="%d" height="%d" fill="%s"/>'
                       % (ox + x * CELL, oy + z * CELL, CELL - 1, CELL - 1, cell_fill(v)))
            if mark and (x, z) in changed:
                out.append('<rect x="%d" y="%d" width="%d" height="%d" fill="none" '
                           'stroke="#ff4d3d" stroke-width="1.6"/>'
                           % (ox + x * CELL - 1, oy + z * CELL - 1, CELL + 1, CELL + 1))
    for (x, z) in arts:
        out.append('<circle cx="%.1f" cy="%.1f" r="2.4" fill="#4fb3ff"/>'
                   % (ox + x * CELL + CELL / 2.0 - 0.5, oy + z * CELL + CELL / 2.0 - 0.5))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--before", default="ada_run/em_plan.backup.json")
    ap.add_argument("--after", default="ada_run/em_plan.json")
    ap.add_argument("--out", default="ada_run/stamp_diff.svg")
    ap.add_argument("--ascii", action="store_true")
    args = ap.parse_args()

    before = load_rows(os.path.join(ROOT, args.before))
    after = load_rows(os.path.join(ROOT, args.after))
    gone = sorted(set(before) - set(after))
    fresh = sorted(set(after) - set(before))

    pairs = []
    for name in sorted(set(before) & set(after)):
        ta, tb = tile_of(before[name]), tile_of(after[name])
        aa, ab = arts_of(before[name]), arts_of(after[name])
        ch = diff_cells(ta, tb)
        if ch or aa != ab:
            pairs.append((name, ta, tb, aa, ab, ch))

    print("STAMP DIFF — %s vs %s" % (args.before, args.after))
    print("  %d authored hall(s) before, %d after · %d changed" % (len(before), len(after), len(pairs)))
    if fresh:
        print("  NEW halls: %s" % ", ".join(fresh))
    if gone:
        print("  NO LONGER AUTHORED: %s" % ", ".join(gone))
    for name, ta, tb, aa, ab, ch in pairs:
        wa = len(ta[0]) if ta else 0
        wb = len(tb[0]) if tb else 0
        lost = sorted(set(aa.values()) - set(ab.values()))
        got = sorted(set(ab.values()) - set(aa.values()))
        bits = []
        if (wa, len(ta)) != (wb, len(tb)):
            bits.append("%dx%d -> %dx%d" % (wa, len(ta), wb, len(tb)))
        bits.append("%d cell(s) changed" % len(ch))
        if lost:
            bits.append("-%s" % ", -".join(lost))
        if got:
            bits.append("+%s" % ", +".join(got))
        print("    %-28s %s" % (name, "; ".join(bits)))

    if args.ascii:
        for name, ta, tb, _aa, _ab, ch in pairs:
            print("\n%s" % name)
            h = max(len(ta), len(tb))
            for z in range(h):
                ra = "".join((ta[z][x] if x < len(ta[z]) else " ")[:1] for x in range(len(ta[z]))) if z < len(ta) else ""
                rb = "".join((tb[z][x] if x < len(tb[z]) else " ")[:1] for x in range(len(tb[z]))) if z < len(tb) else ""
                star = "*" if any(cz == z for _cx, cz in ch) else " "
                print("  %-38s %s %s" % (ra, star, rb))
        return 0

    if not pairs and not fresh and not gone:
        print("  nothing moved between these two stamps")
        return 0

    body, y = [], PAD + 26
    width = 900
    for name, ta, tb, aa, ab, ch in pairs:
        wa = len(ta[0]) if ta else 0
        wb = len(tb[0]) if tb else 0
        rows = max(len(ta), len(tb))
        body.append('<text x="%d" y="%d" fill="#e8e6e1" font-family="ui-monospace,monospace" '
                    'font-size="13">%s</text>' % (PAD, y, name))
        lost = sorted(set(aa.values()) - set(ab.values()))
        got = sorted(set(ab.values()) - set(aa.values()))
        note = "%d cell(s) changed" % len(ch)
        if (wa, len(ta)) != (wb, len(tb)):
            note = "%dx%d to %dx%d · " % (wa, len(ta), wb, len(tb)) + note
        if lost:
            note += " · gone: " + ", ".join(lost)
        if got:
            note += " · new: " + ", ".join(got)
        body.append('<text x="%d" y="%d" fill="#8b8b96" font-family="ui-monospace,monospace" '
                    'font-size="10">%s</text>' % (PAD, y + 14, note))
        top = y + 24
        body += draw(ta, aa, PAD, top, ch, False)
        x2 = PAD + wa * CELL + GAP
        body.append('<text x="%d" y="%d" fill="#5c5c66" font-family="ui-monospace,monospace" '
                    'font-size="10">-&gt;</text>' % (x2 - GAP + 8, top + rows * CELL / 2))
        body += draw(tb, ab, x2, top, ch, True)
        width = max(width, x2 + wb * CELL + PAD)
        y = top + rows * CELL + 30

    svg = ['<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" '
           'viewBox="0 0 %d %d">' % (width, y, width, y),
           '<rect width="100%" height="100%" fill="#101014"/>',
           '<text x="%d" y="%d" fill="#e8e6e1" font-family="ui-monospace,monospace" '
           'font-size="15">stamp diff · %d hall(s) moved · left = before, right = after, '
           'ringed = changed</text>' % (PAD, PAD + 12, len(pairs))]
    svg += body
    svg.append("</svg>")
    dest = os.path.join(ROOT, args.out)
    with open(dest, "w", encoding="utf-8") as fh:
        fh.write("\n".join(svg))
    print("\n  -> %s" % args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
