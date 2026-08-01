#!/usr/bin/env python3
"""
build_museum_match_board.py — the match on one board.

Reads every doc/reports/museum_match_<seq>.json and renders the corpus-wide
result as a heatmap: rows = sequences (spine order), columns = the five
fielded museums plus the bred champion. Cell tint = delta vs the bred
champion's classic score (red = museum below, green = museum above); the big
number is the classic score, the small number score2 (with the proposed
`patience` term). A crown marks any museum that beats the whole bred field on
the classic score; a hollow crown marks score2-only wins — the chapters the
withheld-hero contract would claim if patience were ruled in.

Output: doc/reports/museum_match_board.png. Rerun after any match.
"""
import json
import glob
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPINE = os.path.join(ROOT, "commons", "maps", "curriculum_spine.json")
OUT = os.path.join(ROOT, "doc", "reports", "museum_match_board.png")

MUSEUMS = [
    ("uffizi-spine-enfilade", "Uffizi\nspine"),
    ("grande-galerie-axial", "Grande Galerie\naxial"),
    ("castelvecchio-endstopped-enfilade", "Castelvecchio\nend-stopped"),
    ("kanazawa-room-matrix", "Kanazawa\nmatrix"),
    ("sainsbury-false-perspective-enfilade", "Sainsbury\ndeep hero"),
]

spine = json.load(open(SPINE, encoding="utf-8"))["spine"]["sequences"]
seq_order = [r["name"] for r in sorted(spine, key=lambda r: r.get("order", 999))]

reports = {}
for f in glob.glob(os.path.join(ROOT, "doc", "reports", "museum_match_*.json")):
    d = json.load(open(f, encoding="utf-8"))
    reports[d["seq"]] = d
rows = [s for s in seq_order if s in reports]

CW, RH, LEFT, TOP = 150, 46, 190, 92
W = LEFT + CW * (len(MUSEUMS) + 1) + 20
H = TOP + RH * len(rows) + 120
img = Image.new("RGB", (W, H), (16, 17, 20))
d = ImageDraw.Draw(img)
try:
    f_h = ImageFont.truetype("arialbd.ttf", 14)
    f_b = ImageFont.truetype("arialbd.ttf", 15)
    f_s = ImageFont.truetype("arial.ttf", 11)
except OSError:
    f_h = f_b = f_s = ImageFont.load_default()


def tint(delta):
    """delta in score units: -2 deep red .. 0 neutral .. +1 green"""
    t = max(-2.0, min(1.0, delta))
    if t >= 0:
        g = int(60 + 90 * t)
        return (30, 30 + g // 2, 30)
    r = int(50 + 55 * (-t / 2.0))
    return (40 + r, 30, 30)


d.text((14, 10), "THE MATCH BOARD — museums vs bred rooms, corpus-wide", fill=(225, 227, 235), font=f_b)
d.text((14, 32), "cell: classic score (small: score2 with patience) - tint: delta vs bred champion - "
        "WIN: museum beats the whole bred field - w/p: wins only under the patience term",
       fill=(150, 152, 160), font=f_s)

for j, (_, label) in enumerate([("bred", "BRED\nchampion")] + MUSEUMS):
    x = LEFT + j * CW
    for li, line in enumerate(label.split("\n")):
        d.text((x + 8, 52 + li * 14), line, fill=(190, 192, 200), font=f_s)

crowns = {m[0]: 0 for m in MUSEUMS}
crowns2 = {m[0]: 0 for m in MUSEUMS}
for i, seq in enumerate(rows):
    y = TOP + i * RH
    rep = reports[seq]
    baseline = rep["bred_baseline"]
    champ_score = baseline[0]["score"]
    d.text((14, y + 8), seq[:22], fill=(205, 207, 215), font=f_h)
    d.rectangle([LEFT, y, LEFT + CW - 4, y + RH - 4], fill=(38, 42, 52))
    d.text((LEFT + 8, y + 6), f"{champ_score:.2f}", fill=(235, 237, 245), font=f_b)
    d.text((LEFT + 8, y + 25), baseline[0]["recipe"], fill=(150, 152, 160), font=f_s)
    ok = {r["museum"]: r for r in rep["museum_rows"] if r.get("status") == "ok"}
    for j, (mk, _) in enumerate(MUSEUMS):
        x = LEFT + (j + 1) * CW
        r = ok.get(mk)
        if not r:
            d.rectangle([x, y, x + CW - 4, y + RH - 4], fill=(24, 25, 29))
            d.text((x + 8, y + 12), "—", fill=(90, 92, 100), font=f_b)
            continue
        s, s2 = r["score"], r.get("score2", r["score"])
        d.rectangle([x, y, x + CW - 4, y + RH - 4], fill=tint(s - champ_score))
        d.text((x + 8, y + 6), f"{s:.2f}", fill=(235, 237, 245), font=f_b)
        d.text((x + 8, y + 25), f"s2 {s2:.2f}  p {r.get('patience', 0):.2f}",
               fill=(175, 177, 185), font=f_s)
        if s >= champ_score:
            d.text((x + CW - 42, y + 4), "WIN", fill=(255, 214, 90), font=f_s)
            crowns[mk] += 1
        elif s2 >= champ_score:
            d.text((x + CW - 42, y + 4), "w/p", fill=(200, 185, 120), font=f_s)
            crowns2[mk] += 1

y = TOP + len(rows) * RH + 14
d.text((14, y), "wins (classic / +patience-only): " + "   ".join(
    f"{lbl.split(chr(10))[0]} {crowns[mk]}/{crowns2[mk]}" for mk, lbl in MUSEUMS),
    fill=(200, 202, 210), font=f_s)
n_museum_cells = sum(1 for seq in rows for mk, _ in MUSEUMS
                     if mk in {r['museum'] for r in reports[seq]['museum_rows'] if r.get('status') == 'ok'})
d.text((14, y + 20), f"{len(rows)} sequences matched - {n_museum_cells} museum stampings, "
        f"all pathfinder-clean - bred baselines from map_tournament reports (seed 46)",
       fill=(140, 142, 150), font=f_s)

img.save(OUT)
print(f"match board -> {os.path.relpath(OUT, ROOT)}  ({len(rows)} sequences)")
