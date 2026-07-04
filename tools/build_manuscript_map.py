#!/usr/bin/env python3
"""build_manuscript_map.py — the book as a map: a 2D projection of the manuscript.

The manuscript is a mapping of a map (VR world -> linear book); this projects it
back into two dimensions: chapter hubs on a meandering spine line, each hub
ringed by its children — the primitive (violet), the walked artifacts, the
rooms as small squares — with the truth and the dig count on the node.

Reads doc/manuscript_frame.json + ada_encyclopedia/public/tutorial/<seq>.json.
Writes ada_encyclopedia/public/manuscript-map.html (self-contained SVG page).

Usage: python tools/build_manuscript_map.py [--reader-url=<base>]
  --reader-url: optional base URL for chapter deep-links (#ch-N appended).
"""
from __future__ import annotations

import html
import json
import math
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.environ.get("ADA_ENCYCLOPEDIA_PATH", "C:/Users/palle/Documents/GitHub/ada_encyclopedia")
FRAME = os.path.join(REPO, "doc", "manuscript_frame.json")
TUTORIAL_DIR = os.path.join(ENC, "public", "tutorial")
OUT = os.path.join(ENC, "public", "manuscript-map.html")

W = 920
CH_H = 400          # vertical space per chapter
PART_H = 90         # part divider band
RING = 108          # satellite ring radius
HUB_L, HUB_R = 300, 620   # alternating hub x — the meander

PART_COLORS = ["#7a7a85", "#3e7d8a", "#b0563f", "#6d4fd4", "#4e8a5a", "#443363"]


def load_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def esc(s: str) -> str:
    return html.escape(str(s), quote=True)


def short(s: str, n: int) -> str:
    return s if len(s) <= n else s[: n - 1] + "…"


def chapter_children(t: dict):
    """primitive + walk artifacts (the ring) and rooms (the squares)."""
    prim, arts, rooms = None, [], []
    for p in t.get("pages", []):
        if p["kind"] == "primitive" and isinstance(p.get("artifact"), dict):
            prim = p["artifact"]
        elif p["kind"] == "walk":
            arts += [a for a in p.get("artifacts") or []]
        elif p["kind"] == "world":
            rooms = [m.get("name", "") for m in p.get("maps") or []]
    return prim, arts, rooms


def main() -> int:
    reader_url = ""
    for a in sys.argv[1:]:
        if a.startswith("--reader-url="):
            reader_url = a.split("=", 1)[1]

    frame = load_json(FRAME)
    if not frame:
        print(f"!! no frame: {FRAME}")
        return 1

    svg = []
    y = 40
    num = 0
    prev_hub = None
    spine_pts = []

    for pi, part in enumerate(frame["parts"]):
        color = PART_COLORS[pi % len(PART_COLORS)]
        roman = ["I", "II", "III", "IV", "V", "VI", "VII"][pi]
        svg.append(f'<g><rect x="20" y="{y}" width="{W-40}" height="2" fill="{color}" opacity=".35"/>'
                   f'<text x="24" y="{y+34}" class="part" fill="{color}">PART {roman} — {esc(part["title"].upper())}</text></g>')
        y += PART_H

        for seq in part["sequences"]:
            num += 1
            t = load_json(os.path.join(TUTORIAL_DIR, f"{seq}.json"))
            cx = HUB_L if num % 2 else HUB_R
            cy = y + CH_H // 2

            # spine segment (meander)
            if prev_hub:
                px, py = prev_hub
                svg.append(f'<path d="M {px} {py} C {px} {py+150}, {cx} {cy-150}, {cx} {cy}" '
                           f'class="spine"/>')
            prev_hub = (cx, cy)
            spine_pts.append((cx, cy))

            link_open = link_close = ""
            if reader_url:
                link_open = f'<a href="{esc(reader_url)}#ch-{num}" target="_blank" rel="noopener">'
                link_close = "</a>"

            if not t:
                svg.append(f'<g><circle cx="{cx}" cy="{cy}" r="26" class="hub missing"/>'
                           f'<text x="{cx}" y="{cy+4}" class="hubnum">{num}</text>'
                           f'<text x="{cx}" y="{cy+48}" class="hubname">{esc(seq)}</text>'
                           f'<text x="{cx}" y="{cy+66}" class="dig">not yet built — stratum unopened</text></g>')
                y += CH_H
                continue

            prim, arts, rooms = chapter_children(t)
            ring = ([prim] if prim else []) + arts
            dig = t.get("dig") or {}
            name = t.get("name", seq)
            truth = t.get("truth", "")

            g = [f"<g>{link_open}<title>{esc(name)}\n{esc(truth)}</title>"]
            # satellites
            k = max(len(ring), 1)
            for i, a in enumerate(ring):
                ang = -math.pi / 2 + i * (2 * math.pi / k)
                x = cx + RING * math.cos(ang)
                yy = cy + RING * math.sin(ang)
                is_prim = (i == 0 and prim is not None)
                r = 7 if is_prim else 4.5
                cls = "prim" if is_prim else "art"
                g.append(f'<line x1="{cx}" y1="{cy}" x2="{x:.0f}" y2="{yy:.0f}" class="spoke"/>')
                g.append(f'<circle cx="{x:.0f}" cy="{yy:.0f}" r="{r}" class="{cls}">'
                         f'<title>{esc(a.get("title") or a.get("name",""))}</title></circle>')
                # label
                lx = cx + (RING + 16) * math.cos(ang)
                ly = cy + (RING + 16) * math.sin(ang)
                anchor = "start" if math.cos(ang) > 0.3 else ("end" if math.cos(ang) < -0.3 else "middle")
                lbl = short(a.get("title") or a.get("name", ""), 18)
                g.append(f'<text x="{lx:.0f}" y="{ly:.0f}" class="lbl{" lblp" if is_prim else ""}" '
                         f'text-anchor="{anchor}" dominant-baseline="middle">{esc(lbl)}</text>')
            # hub
            g.append(f'<circle cx="{cx}" cy="{cy}" r="24" class="hub" stroke="{color}"/>')
            g.append(f'<text x="{cx}" y="{cy+4}" class="hubnum">{num}</text>')
            g.append(f'<text x="{cx}" y="{cy+44}" class="hubname">{esc(short(name.split(":")[0], 26))}</text>')
            if truth:
                g.append(f'<text x="{cx}" y="{cy+60}" class="truth">{esc(short(truth, 46))}</text>')
            if dig.get("pearls"):
                left = dig["pearls"] - dig.get("walked", 0)
                g.append(f'<text x="{cx}" y="{cy+76}" class="dig">{dig.get("walked",0)} of {dig["pearls"]} excavated · {left} at depth</text>')
            # rooms as small squares
            if rooms:
                total_w = min(len(rooms), 14) * 11
                rx0 = cx - total_w / 2
                for j, rm in enumerate(rooms[:14]):
                    g.append(f'<rect x="{rx0 + j*11:.0f}" y="{cy+84}" width="8" height="8" class="room">'
                             f'<title>{esc(rm)}</title></rect>')
            g.append(f"{link_close}</g>")
            svg.append("".join(g))
            y += CH_H

    height = y + 60
    css = """
body{margin:0;background:#f8f7fa;color:#211e28;
font-family:'Iowan Old Style','Palatino Linotype',Palatino,Georgia,serif}
.head{max-width:56rem;margin:2.2rem auto .6rem;padding:0 1.2rem}
.head h1{font-size:2rem;font-weight:500;margin:0 0 .3rem}
.head p{color:#6f6a7a;font-style:italic;margin:.2rem 0}
.legend{font-family:-apple-system,'Segoe UI',system-ui,sans-serif;font-size:.72rem;
color:#6f6a7a;display:flex;gap:1.2rem;flex-wrap:wrap;margin-top:.7rem;align-items:center}
.legend span{display:inline-flex;align-items:center;gap:.35rem}
.mapwrap{overflow-x:auto}
svg{display:block;margin:0 auto}
.part{font-family:-apple-system,'Segoe UI',system-ui,sans-serif;font-size:13px;
font-weight:700;letter-spacing:.2em}
.spine{fill:none;stroke:#6d4fd4;stroke-width:2;opacity:.45}
.spoke{stroke:#d9d4e6;stroke-width:1}
.hub{fill:#f8f7fa;stroke-width:2.5}
.hub.missing{stroke:#b9b3c9;stroke-dasharray:4 3}
.hubnum{font-family:-apple-system,'Segoe UI',system-ui,sans-serif;font-size:13px;
font-weight:700;text-anchor:middle;fill:#211e28}
.hubname{font-size:15px;text-anchor:middle;fill:#211e28}
.truth{font-size:11px;font-style:italic;text-anchor:middle;fill:#6d4fd4}
.dig{font-family:-apple-system,'Segoe UI',system-ui,sans-serif;font-size:9.5px;
text-anchor:middle;fill:#8b8496;letter-spacing:.04em}
.prim{fill:#6d4fd4}
.art{fill:#f8f7fa;stroke:#211e28;stroke-width:1.2}
.lbl{font-family:-apple-system,'Segoe UI',system-ui,sans-serif;font-size:9px;fill:#5a5566}
.lblp{fill:#4f3a9e;font-weight:600}
.room{fill:#e3dfee;stroke:#a49dc0;stroke-width:.8}
a{cursor:pointer}a:hover .hub{fill:#f0edf7}
"""
    doc = (f"<title>Ada Research — The Book as a Map</title>\n<style>{css}</style>\n"
           '<div class="head"><h1>The Book as a Map</h1>'
           '<p>A mapping of a map, in two dimensions: each chapter a hub on the walking line, '
           'ringed by what it excavated. The spine meanders — a walk, not a shortest path.</p>'
           '<div class="legend">'
           '<span><svg width="14" height="14"><circle cx="7" cy="7" r="6" fill="#f8f7fa" stroke="#6d4fd4" stroke-width="2"/></svg>chapter</span>'
           '<span><svg width="12" height="12"><circle cx="6" cy="6" r="5" fill="#6d4fd4"/></svg>the primitive</span>'
           '<span><svg width="10" height="10"><circle cx="5" cy="5" r="4" fill="#f8f7fa" stroke="#211e28"/></svg>walked artifact</span>'
           '<span><svg width="10" height="10"><rect x="1" y="1" width="8" height="8" fill="#e3dfee" stroke="#a49dc0"/></svg>room</span>'
           '<span>· hover anything for its name; the dig count is the ledger\'s field note</span>'
           "</div></div>"
           f'<div class="mapwrap"><svg viewBox="0 0 {W} {height}" width="{W}" height="{height}" '
           f'xmlns="http://www.w3.org/2000/svg">{"".join(svg)}</svg></div>')
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(doc)
    print(f"map: {num} hubs -> {OUT} ({len(doc)} chars)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
