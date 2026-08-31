"""em_one_map.py — the whole endless museum as ONE map.

2026-08-29, Palle: "can you visualize as one map". Chapters as rows in spine
order; every hall drawn from its own plan tile (wall dark, floor cream, hole =
gap, platform amber); artifacts as dots — HERO gold with its name under the
hall (from doc/reports/em_best_of.json, so the picture and the distribution
report can never disagree), cast white, furniture grey; the four no-hero halls
flagged red. Re-run after any replan or a fresh em_best_of pass:

  python tools/em_best_of.py && python tools/em_one_map.py

Writes ada_run/em_one_map.png. Report-first family: mutates nothing.
"""
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = "C:/Users/palle/Documents/GitHub/AdaResearch_46"
plan = json.load(open(ROOT + "/ada_run/em_plan.json", encoding="utf-8"))
best = json.load(open(ROOT + "/doc/reports/em_best_of.json", encoding="utf-8"))
hero_of = {(h["sequence"], h["map"]): h for h in best["halls"]}

SPINE = ["primitives", "transformation", "color", "change", "forces", "formfinding",
         "wavefunctions", "randomness", "noise", "cellularautomata", "fractals",
         "lsystems", "proceduralgeneration", "softbodies", "isosurfaces",
         "boolean_surfaces", "swarmintelligence", "machinelearning", "graphtheory",
         "foundationscrisis", "qfeplaboratory", "postfoundationscrisis"]

rows = {}
for r in plan["plans"]:
    rows.setdefault(r["sequence"], []).append(r)

CELL = 6
GAP = 14
LEFT = 170
LABEL_H = 30
PAD_Y = 18
MIN_SLOT = 96

try:
    F_SM = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 11)
    F_HERO = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 11)
    F_CH = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 15)
    F_TITLE = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 24)
    F_SUB = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 13)
except Exception:
    F_SM = F_HERO = F_CH = F_TITLE = F_SUB = ImageFont.load_default()

CH_HUES = {}
for i, ch in enumerate(SPINE):
    import colorsys
    r_, g_, b_ = colorsys.hsv_to_rgb((i * 0.618034) % 1.0, 0.55, 0.85)
    CH_HUES[ch] = (int(r_ * 255), int(g_ * 255), int(b_ * 255))

# measure layout
row_dims = []
total_w = 0
for ch in SPINE:
    hs = rows.get(ch, [])
    w = LEFT
    max_h = 0
    for h in hs:
        tw = h["room"]["w"] * CELL
        th = h["h"] * CELL
        slot = max(tw, MIN_SLOT)
        w += slot + GAP
        max_h = max(max_h, th)
    row_dims.append((ch, hs, w, max_h))
    total_w = max(total_w, w)

HEADER = 78
total_h = HEADER
for _ch, _hs, _w, mh in row_dims:
    total_h += mh + LABEL_H + PAD_Y

BG = (16, 17, 22)
img = Image.new("RGB", (total_w + 30, total_h + 20), BG)
d = ImageDraw.Draw(img)

d.text((LEFT, 16), "THE ENDLESS MUSEUM — ONE MAP", font=F_TITLE, fill=(235, 230, 215))
s = best["stats"]
d.text((LEFT, 48), "156 map-authored halls · 22 chapters · every hall IS its grid map · "
        "hero \u25cf gold (all %d distinct) · cast \u25cb white · furniture · grey" % s["heroes_assigned"],
        font=F_SUB, fill=(150, 150, 160))

y = HEADER
for ch, hs, _w, mh in row_dims:
    col = CH_HUES[ch]
    d.rectangle([12, y, 20, y + mh + LABEL_H - 6], fill=col)
    d.text((28, y + 2), ch, font=F_CH, fill=col)
    n_heroes = sum(1 for h in hs if hero_of.get((ch, h.get("map", "")), {}).get("hero"))
    d.text((28, y + 22), "%d halls" % len(hs), font=F_SM, fill=(120, 120, 130))
    x = LEFT
    for h in hs:
        tile = h["tile"]
        tw = h["room"]["w"] * CELL
        th = h["h"] * CELL
        slot = max(tw, MIN_SLOT)
        ox = x + (slot - tw) // 2
        # tile cells
        for rr, line in enumerate(tile):
            for cc, v in enumerate(line):
                v = str(v)
                cx0 = ox + cc * CELL
                cy0 = y + rr * CELL
                if v == "4":
                    c = (70, 72, 84)
                elif v == "1":
                    c = (205, 200, 188)
                elif v.startswith("p"):
                    c = (196, 160, 90)
                else:
                    continue
                d.rectangle([cx0, cy0, cx0 + CELL - 1, cy0 + CELL - 1], fill=c)
        info = hero_of.get((ch, h.get("map", "")), {})
        hero = info.get("hero")
        # artifacts
        for a in h.get("artifacts") or []:
            tc = a.get("tile_cell") or a.get("cell") or [0, 0]
            cx = ox + tc[0] * CELL + CELL // 2
            cy = y + tc[1] * CELL + CELL // 2
            tok = a.get("token")
            if tok == hero:
                d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(255, 196, 60), outline=(90, 60, 0))
            elif tok in (info.get("furniture") or []):
                d.ellipse([cx - 1, cy - 1, cx + 1, cy + 1], fill=(110, 110, 118))
            else:
                d.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=(240, 240, 245), outline=(60, 60, 70))
        # labels
        name = h.get("map", "")
        maxch = max(8, slot // 6)
        if len(name) > maxch:
            name = name[:maxch - 1] + "\u2026"
        d.text((x + 1, y + mh + 3), name, font=F_SM, fill=(140, 140, 150))
        if hero:
            htxt = hero
            if len(htxt) > maxch:
                htxt = htxt[:maxch - 1] + "\u2026"
            d.text((x + 1, y + mh + 16), htxt, font=F_HERO, fill=(255, 196, 60))
        else:
            d.text((x + 1, y + mh + 16), "\u2014 no hero", font=F_HERO, fill=(200, 90, 80))
        x += slot + GAP
    y += mh + LABEL_H + PAD_Y

out = ROOT + "/ada_run/em_one_map.png"
img.save(out)
print("saved", out, img.size)
