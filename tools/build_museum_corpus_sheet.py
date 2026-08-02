#!/usr/bin/env python3
"""
build_museum_corpus_sheet.py — the fourteen museums on one sheet.

Renders every museum-tagged pattern in template_patterns.json as a cell grid,
in dealing order (em_order), each in its own accent colour: dark floor, grey
wall, light podium, accent-tinted artifact slots, the hero slot outlined.
Output: doc/reports/museum_templates_corpus.png. Rerun after any extraction
wave or tile repair.
"""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

REPO = Path(__file__).resolve().parents[1]
OUT = REPO / "doc" / "reports" / "museum_templates_corpus.png"

tp = json.loads((REPO / "commons/data/template_patterns.json").read_text(encoding="utf-8"))["patterns"]
mus = {k: p for k, p in tp.items() if isinstance(p, dict) and p.get("museum")}
order = sorted(mus.items(), key=lambda kv: (kv[1].get("em_order", 99), kv[0]))

CELL, PAD, HEAD, COLS = 9, 14, 48, 7
tile_w = max(int(p["w"]) for _, p in order) * CELL
tile_h = max(int(p["h"]) for _, p in order) * CELL
cw, ch = tile_w + PAD * 2, tile_h + HEAD + PAD
rows = (len(order) + COLS - 1) // COLS
W, H = COLS * cw, rows * ch + 34


def hx(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def fit(dr, text, font, maxw):
    while text and dr.textlength(text, font=font) > maxw:
        text = text[:-1]
    return text


img = Image.new("RGB", (W, H), (16, 17, 20))
d = ImageDraw.Draw(img)
try:
    f_big = ImageFont.truetype("arialbd.ttf", 13)
    f_sm = ImageFont.truetype("arial.ttf", 11)
except OSError:
    f_big = f_sm = ImageFont.load_default()

COLORS = {"4": (58, 60, 68), "1": (32, 34, 39), "2": (78, 82, 92)}
maxtext = cw - PAD * 2
for i, (key, p) in enumerate(order):
    cx0 = (i % COLS) * cw
    cy0 = (i // COLS) * ch + 30
    accent = hx(p.get("color", "#888888"))
    w, h, tile = int(p["w"]), int(p["h"]), p["tile"]
    slots = sum(1 for r in tile for c in r if str(c) in ("1s", "2s", "3s"))
    head = ("CH" if p.get("challenger") else str(p.get("em_order", "?"))) + f"  {p.get('label', key)}"
    d.text((cx0 + PAD, cy0), fit(d, head, f_big, maxtext), fill=accent, font=f_big)
    d.text((cx0 + PAD, cy0 + 18), fit(d, p.get("museum", ""), f_sm, maxtext), fill=(168, 170, 178), font=f_sm)
    d.text((cx0 + PAD, cy0 + 32), f"{w}x{h}  -  {slots} slots", fill=(120, 122, 130), font=f_sm)
    ox = cx0 + PAD + (tile_w - w * CELL) // 2
    oy = cy0 + HEAD + (tile_h - h * CELL) // 2
    for y in range(h):
        for x in range(w):
            c = str(tile[y][x])
            px, py = ox + x * CELL, oy + y * CELL
            if c.strip() == "":
                continue
            if c == "3s":
                d.rectangle([px, py, px + CELL - 1, py + CELL - 1], fill=accent, outline=(255, 255, 255))
            elif c in ("1s", "2s"):
                base = COLORS["1"] if c == "1s" else COLORS["2"]
                d.rectangle([px, py, px + CELL - 1, py + CELL - 1], fill=base)
                mix = tuple(int(0.55 * a + 0.45 * b) for a, b in zip(accent, base))
                d.rectangle([px + 1, py + 1, px + CELL - 2, py + CELL - 2], fill=mix)
            else:
                d.rectangle([px, py, px + CELL - 1, py + CELL - 1], fill=COLORS.get(c, (25, 26, 30)))
d.text((PAD, 6), f"THE CORPUS - {len(order)} museum templates in dealing order (challengers last, marked CH).   "
        "dark = floor   grey = wall   light = podium   tinted = artifact slot   outlined = hero (3s)",
       fill=(200, 202, 210), font=f_sm)
img.save(OUT)
print(f"corpus sheet -> {OUT.relative_to(REPO)}  {img.size}")
