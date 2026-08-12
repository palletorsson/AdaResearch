#!/usr/bin/env python3
"""
build_museum_corpus_sheet.py — the whole museum corpus on one sheet.

Renders every museum-tagged pattern in template_patterns.json as a cell grid,
in dealing order (em_order).

Cell colours come from the ENCYCLOPEDIA's own ROLES table via
tools/spatial_palette.py — the same one /template-pattern-editor,
/template-gallery, /template-maps and /template-lab read. This sheet used to
carry its own greyscale (floor 32, wall 58, podium 78), so the corpus sheet and
the editor disagreed about what a wall looks like: the same museum rendered two
ways depending on which tool drew it. The per-template accent is kept, but for
what it is actually good at — telling twenty templates apart in a grid — so it
now colours the TITLE and outlines the hero, while the cells say what they are.
Output: ada_encyclopedia/public/museum/museum_templates_corpus.png. Rerun after any extraction
wave or tile repair.
"""
import json
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))
from spatial_palette import GROUND, INK, INK_DIM, cell_colour
OUT = REPO.parent / "ada_encyclopedia" / "public" / "museum" / "museum_templates_corpus.png"

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


img = Image.new("RGB", (W, H), hx(GROUND))
d = ImageDraw.Draw(img)
try:
    f_big = ImageFont.truetype("arialbd.ttf", 13)
    f_sm = ImageFont.truetype("arial.ttf", 11)
except OSError:
    f_big = f_sm = ImageFont.load_default()

def role_rgb(code):
    """One cell's colour, from the table the web pages share."""
    return hx(cell_colour(code))
maxtext = cw - PAD * 2
for i, (key, p) in enumerate(order):
    cx0 = (i % COLS) * cw
    cy0 = (i // COLS) * ch + 30
    accent = hx(p.get("color", "#888888"))
    w, h, tile = int(p["w"]), int(p["h"]), p["tile"]
    slots = sum(1 for r in tile for c in r if str(c) in ("1s", "2s", "3s"))
    head = ("CH" if p.get("challenger") else str(p.get("em_order", "?"))) + f"  {p.get('label', key)}"
    d.text((cx0 + PAD, cy0), fit(d, head, f_big, maxtext), fill=accent, font=f_big)
    d.text((cx0 + PAD, cy0 + 18), fit(d, p.get("museum", ""), f_sm, maxtext), fill=hx(INK), font=f_sm)
    d.text((cx0 + PAD, cy0 + 32), f"{w}x{h}  -  {slots} slots", fill=hx(INK_DIM), font=f_sm)
    ox = cx0 + PAD + (tile_w - w * CELL) // 2
    oy = cy0 + HEAD + (tile_h - h * CELL) // 2
    for y in range(h):
        for x in range(w):
            c = str(tile[y][x])
            px, py = ox + x * CELL, oy + y * CELL
            if c.strip() == "":
                continue
            # Every cell is its declared role colour. The hero keeps an accent
            # outline because it is the one cell that is singular per museum,
            # and losing that made twenty tiles read as one.
            d.rectangle([px, py, px + CELL - 1, py + CELL - 1], fill=role_rgb(c))
            if c == "3s":
                d.rectangle([px, py, px + CELL - 1, py + CELL - 1], outline=accent)
d.text((PAD, 6), f"THE CORPUS - {len(order)} museum templates in dealing order (challengers last, marked CH).   "
        "cell colours from the encyclopedia ROLES table: floor, wall, platform, "
        "floor slot, podium slot, hero (3s, outlined in the museum's accent)",
       fill=hx(INK), font=f_sm)
img.save(OUT)
print(f"corpus sheet -> {OUT}  {img.size}")
