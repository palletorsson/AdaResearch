#!/usr/bin/env python
"""Render the iteration-loop diagram for the 'starting point' blog post.

A horizontal cycle — READ → EDIT → WALK → LOG → READ — with three
missing instruments marked in amber where they would sit.

Output: doc/reports/lift_loop.svg (+ optional --copy-to for the
encyclopedia's public/blog).
"""
from __future__ import annotations
import argparse, shutil, sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "doc" / "reports" / "lift_loop.svg"

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass


def xml_escape(s: str) -> str:
    return (s.replace("&", "&amp;").replace("<", "&lt;")
             .replace(">", "&gt;").replace('"', "&quot;")
             .replace("'", "&apos;"))


def node(x, y, w, h, label, sub, fill="#ecfdf5", stroke="#10b981", text_color="#064e3b"):
    return (
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="10" '
        f'fill="{fill}" stroke="{stroke}" stroke-width="2"/>'
        f'<text x="{x + w/2}" y="{y + 26}" text-anchor="middle" '
        f'font-size="16" font-weight="700" fill="{text_color}">{xml_escape(label)}</text>'
        f'<text x="{x + w/2}" y="{y + 48}" text-anchor="middle" '
        f'font-size="11" fill="#475569">{xml_escape(sub)}</text>'
    )


def missing(x, y, w, h, label, sub):
    return (
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="10" '
        f'fill="#fffbeb" stroke="#d97706" stroke-width="2" stroke-dasharray="6,4"/>'
        f'<text x="{x + w/2}" y="{y + 22}" text-anchor="middle" '
        f'font-size="13" font-weight="700" fill="#92400e">{xml_escape(label)}</text>'
        f'<text x="{x + w/2}" y="{y + 40}" text-anchor="middle" '
        f'font-size="10" fill="#92400e">{xml_escape(sub)}</text>'
    )


def arrow(x1, y1, x2, y2, color="#94a3b8"):
    # simple line with triangle head
    head = (
        f'<polygon points="{x2},{y2} {x2-8},{y2-5} {x2-8},{y2+5}" '
        f'fill="{color}"/>'
    )
    return (
        f'<line x1="{x1}" y1="{y1}" x2="{x2-6}" y2="{y2}" '
        f'stroke="{color}" stroke-width="2"/>' + head
    )


def curved_arrow(x1, y1, x2, y2, color="#94a3b8"):
    # back-arrow from right side to left side going under
    return (
        f'<path d="M{x1} {y1} C{x1} {y1+120}, {x2} {y2+120}, {x2} {y2}" '
        f'fill="none" stroke="{color}" stroke-width="2"/>'
        f'<polygon points="{x2},{y2} {x2+8},{y2+5} {x2+8},{y2-5}" '
        f'fill="{color}"/>'
    )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--copy-to")
    args = ap.parse_args()

    W, H = 920, 360
    y_top = 60
    box_w, box_h = 170, 80
    gap = 40
    x_start = 30

    # four boxes across the top
    xs = [x_start + i * (box_w + gap) for i in range(4)]

    nodes = [
        (xs[0], y_top, "READ",  "six text files + captures + docs", "#ecfdf5", "#10b981", "#064e3b"),
        (xs[1], y_top, "EDIT",  "text or placements", "#ecfdf5", "#10b981", "#064e3b"),
        (xs[2], y_top, "WALK",  "VR or capture review", "#ecfdf5", "#10b981", "#064e3b"),
        (xs[3], y_top, "LOG",   "feedback bridge", "#ecfdf5", "#10b981", "#064e3b"),
    ]

    svg: list[str] = []
    svg.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" '
               f'font-family="ui-monospace,Consolas,monospace">')
    svg.append('<rect width="100%" height="100%" fill="white"/>')
    svg.append(f'<text x="{x_start}" y="32" font-size="19" font-weight="700" fill="#18181b">'
               'The iteration loop — what\'s there, what\'s missing</text>')

    for x, y, lbl, sub, f, s, t in nodes:
        svg.append(node(x, y, box_w, box_h, lbl, sub, f, s, t))

    # arrows between top boxes
    for i in range(3):
        a_x1 = xs[i] + box_w
        a_x2 = xs[i+1]
        y = y_top + box_h / 2
        svg.append(arrow(a_x1 + 4, y, a_x2 - 4, y))

    # back-arrow from LOG to READ
    svg.append(curved_arrow(
        xs[3] + box_w / 2, y_top + box_h + 2,
        xs[0] + box_w / 2, y_top + box_h + 2,
    ))

    # missing instruments, placed below the relevant transitions
    y_mid = y_top + box_h + 140
    missing_w, missing_h = 260, 60
    missing_y = y_mid

    # 1. reading surface — between READ and EDIT
    m1_x = (xs[0] + xs[1]) / 2 + box_w / 2 - missing_w / 2
    # 2. walked marker — between WALK and LOG
    m2_x = (xs[2] + xs[3]) / 2 + box_w / 2 - missing_w / 2
    # 3. LLM claim review — spans the whole
    m3_x = x_start
    m3_w = W - 2 * x_start
    m3_y = missing_y + missing_h + 25

    svg.append(missing(m1_x, missing_y, missing_w, missing_h,
                       "reading surface",
                       "/map/[name] — six texts + captures in one place"))
    svg.append(missing(m2_x, missing_y, missing_w, missing_h,
                       "walked marker + drift",
                       "last_walked_at, text_hash, placement_hash"))
    svg.append(missing(m3_x, m3_y, m3_w, 40,
                       "LLM claim review  (spans the loop)",
                       "does the blurb's claim get enacted by the placed artifacts?"))

    # short pointer lines from missing boxes to the transitions they serve
    def thin(x1, y1, x2, y2):
        return (f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" '
                f'stroke="#d97706" stroke-width="1" stroke-dasharray="3,3"/>')
    svg.append(thin(m1_x + missing_w/2, missing_y, xs[0] + box_w + gap/2, y_top + box_h + 4))
    svg.append(thin(m2_x + missing_w/2, missing_y, xs[2] + box_w + gap/2, y_top + box_h + 4))

    svg.append('</svg>')

    OUT.write_text("\n".join(svg), encoding="utf-8")
    print(f"Wrote {OUT.relative_to(REPO)}")
    if args.copy_to:
        target = Path(args.copy_to)
        if target.is_dir():
            target = target / "lift_loop.svg"
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy(OUT, target)
        print(f"Copied to {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
