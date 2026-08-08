# -*- coding: utf-8 -*-
"""spine_contact_sheet.py — the whole curriculum as one pixel image.

269 maps, drawn at their true relative size, in spine order: one row-run per
sequence, from primitives at the top to postfoundationscrisis at the bottom.
Nothing is normalised — a big map looks big — because the point of seeing them
all at once is the comparison the eye makes without being asked.

Floor light, void dark, wall mid, and a dot on every cell that holds an
artifact. A sequence's band is tinted by its QFEP phase.

    python tools/spine_contact_sheet.py --scale 4
"""
import json, argparse, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import walk_polish as wp                       # noqa: E402
import spine_typologies as sty                 # noqa: E402
from PIL import Image, ImageDraw               # noqa: E402

BG      = (18, 20, 26)
VOID    = (25, 28, 36)
FLOOR   = (201, 196, 184)
RAISED  = (163, 157, 145)
HIGH    = (134, 128, 117)
WALL    = (58, 63, 76)
SLOT    = (232, 180, 90)
PHASE_TINT = {
    "F_order":     (148, 107, 61),
    "oscillation": (61, 122, 148),
    "E_entropy":   (138, 75, 107),
    "lambda_edge": (92, 122, 61),
    "integration": (122, 92, 61),
    "relation":    (75, 107, 138),
    "synthesis":   (166, 84, 84),
}


def cell_colour(c):
    s = str(c).strip().rstrip("s")
    if not s:
        return VOID
    try:
        h = int(float(s))
    except Exception:
        h = 1                     # a scene token in the structure layer is floor
    if h <= 0:  return VOID
    if h == 1:  return FLOOR
    if h == 2:  return RAISED
    if h <= 3:  return HIGH
    return WALL


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--scale", type=int, default=4)      # px per grid cell
    ap.add_argument("--width", type=int, default=1900)   # target sheet width
    ap.add_argument("--out", default=str(ROOT / "commons/data/spine_contact_sheet.png"))
    a = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    S_ = a.scale
    GAP, LABEL, PAD = 5, 11, 16

    spine = json.loads((ROOT / "commons/maps/curriculum_spine.json").read_text(encoding="utf-8"))
    PHASE = {s["name"]: s.get("phase", "") for s in spine["spine"]["sequences"]}

    # gather in spine order, grouped by sequence
    bands, cur, curseq = [], [], None
    for seq, nm in sty.spine_maps():
        md = wp.load(nm)
        if not md:
            continue
        S, U, I, WL = wp.grids(md)
        if not S:
            continue
        W = max((len(r) for r in S), default=0)
        if seq != curseq:
            if cur:
                bands.append((curseq, cur))
            cur, curseq = [], seq
        cur.append((nm, S, I, W, len(S)))
    if cur:
        bands.append((curseq, cur))

    # lay each sequence out as its own wrapped run
    plan, y = [], PAD + 14
    for seq, items in bands:
        y0 = y
        x, rowh = PAD, 0
        for nm, S, I, W, D in items:
            w, h = W * S_, D * S_
            if x + w > a.width - PAD and x > PAD:
                x = PAD; y += rowh + GAP; rowh = 0
            plan.append((x, y, S, I, W, D))
            x += w + GAP
            rowh = max(rowh, h)
        y += rowh + GAP
        plan.append(("band", seq, y0 - 12, y - GAP))
        y += LABEL + 6
    H = y + PAD

    img = Image.new("RGB", (a.width, H), BG)
    d = ImageDraw.Draw(img)
    for item in plan:
        if item[0] == "band":
            _, seq, ya, yb = item
            tint = PHASE_TINT.get(PHASE.get(seq, ""), (110, 110, 120))
            d.rectangle([0, ya, 3, yb], fill=tint)
            d.text((PAD, yb + 2), "%s  -  %s" % (seq, PHASE.get(seq, "")), fill=tint)
            continue
        x0, y0, S, I, W, D = item
        for z in range(D):
            for xx in range(len(S[z])):
                col = cell_colour(S[z][xx])
                px, py = x0 + xx * S_, y0 + z * S_
                d.rectangle([px, py, px + S_ - 1, py + S_ - 1], fill=col)
                tok = str(I[z][xx]).strip() if z < len(I) and xx < len(I[z]) else ""
                if tok and not tok.startswith(wp.PRE) and not tok.startswith("hangar_"):
                    if S_ >= 3:
                        d.rectangle([px + 1, py + 1, px + S_ - 2, py + S_ - 2], fill=SLOT)
                    else:
                        d.point((px, py), fill=SLOT)
    # PIL's default bitmap font is latin-1: an em dash raises rather than draws
    d.text((PAD, 4), "The spine - 269 maps in curriculum order, true relative size.  "
                     "floor light / void dark / wall grey / artifact amber", fill=(180, 176, 166))
    img.save(a.out)
    print("%d maps, %d sequences -> %s (%dx%d)"
          % (sum(len(i) for _, i in bands), len(bands), a.out, a.width, H))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
