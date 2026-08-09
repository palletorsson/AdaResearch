# -*- coding: utf-8 -*-
"""match_board_shelf.py — the 310-wide match, drawn.

One row per chapter, in curriculum order. The winning plan's floor tile beside
its score, the bred champion it had to beat, and the crown it was ruled into
where one exists. The plan's tint is its FAMILY — museum, the curriculum's own
segment, a pattern-editor tile, a spine typology — because the whole point of
widening the field from five museums to the shelf was to find out which family
actually wins, and that is invisible in a number.

    python tools/match_board_shelf.py
"""
import json, argparse, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from PIL import Image, ImageDraw            # noqa: E402

BG, INK, DIM = (18, 20, 26), (232, 228, 220), (122, 128, 140)
FAMILY = {"museum": (196, 142, 82), "spine-segment": (82, 158, 196),
          "authored": (150, 106, 196), "spine": (110, 190, 130)}
CELL = {0: (25, 28, 36), 1: (201, 196, 184), 2: (163, 157, 145),
        3: (134, 128, 117), 4: (58, 63, 76)}


def h_of(c):
    s = str(c).strip().rstrip("s")
    if not s:
        return 0
    try:
        return min(4, max(0, int(float(s))))
    except Exception:
        return 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(ROOT / "commons/data/match_board_shelf.png"))
    a = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    shelf = json.loads((ROOT / "commons/data/template_shelf.json").read_text(encoding="utf-8"))["patterns"]
    crowns = json.loads((ROOT / "commons/data/museum_crowns.json").read_text(encoding="utf-8"))["crowns"]
    d = json.loads((ROOT / "doc/reports/own_room_match.json").read_text(encoding="utf-8"))
    rows = d.get("results", [])
    if not rows:
        print("no results yet"); return 1

    S, RH, PAD, LEFT = 4, 62, 18, 250          # tile px per cell, row height
    W = 1500
    H = PAD + 58 + len(rows) * RH + 30
    img = Image.new("RGB", (W, H), BG)
    g = ImageDraw.Draw(img)
    g.text((PAD, 12), "THE 310-WIDE MATCH - every chapter against every stampable plan the project owns",
           fill=INK)
    g.text((PAD, 28), "winner tile + score  /  bred champion it beat  /  crown it was ruled into.  "
                      "tint = family: museum, spine segment, pattern editor, typology", fill=DIM)
    g.text((PAD, 44), "%d chapters   %d candidates each" %
           (len(rows), rows[0].get("candidates", 0)), fill=DIM)

    y = PAD + 58
    won = {}
    for r in rows:
        best = r.get("best") or [None, None, "?"]
        key, sc, fam = (best + ["?"])[:3] if isinstance(best, list) else ("?", None, "?")
        pat = shelf.get(str(key), {})
        fam = pat.get("source", fam or "?")
        tint = FAMILY.get(fam, (140, 140, 150))
        won[fam] = won.get(fam, 0) + 1
        bred = (r.get("bred_champ") or [None, None])[1]
        cs = crowns.get(r["seq"], {}).get("score")

        g.rectangle([0, y, 3, y + RH - 6], fill=tint)
        g.text((PAD, y + 2), r["seq"], fill=INK)
        g.text((PAD, y + 16), r.get("phase", ""), fill=DIM)
        g.text((PAD, y + 30), "%s" % str(key)[:26], fill=tint)
        g.text((PAD, y + 44), fam, fill=tint)

        # the winning plan's floor tile
        tile = pat.get("tile") or []
        x0 = LEFT
        for z, row in enumerate(tile[:14]):
            for x, c in enumerate(row[:34]):
                hv = h_of(c)
                px, py = x0 + x * S, y + 2 + z * S
                g.rectangle([px, py, px + S - 1, py + S - 1], fill=CELL[hv])
                if str(c).endswith("s"):
                    g.point((px + 1, py + 1), fill=(232, 180, 90))

        bx = LEFT + 160
        for label, val, col in (("won", sc, tint), ("bred", bred, (150, 150, 158)),
                                ("crown", cs, (196, 142, 82))):
            g.text((bx, y + 8), label, fill=DIM)
            g.text((bx, y + 24), ("%.2f" % val) if val else "-", fill=col)
            bx += 62
        # margin bar: how far the winner beat the bred champion
        if sc and bred:
            dm = sc - bred
            wpx = int(min(abs(dm), 3.0) * 90)
            col = (108, 176, 118) if dm > 0 else (176, 96, 96)
            g.rectangle([bx + 10, y + 20, bx + 10 + max(2, wpx), y + 30], fill=col)
            g.text((bx + 16 + max(2, wpx), y + 20), "%+.2f" % dm, fill=col)
        y += RH

    g.text((PAD, y + 6), "winners by family:  " +
           "   ".join("%s %d" % (k, v) for k, v in sorted(won.items(), key=lambda kv: -kv[1])),
           fill=INK)
    img.save(a.out)
    print("%d chapters -> %s (%dx%d)" % (len(rows), a.out, W, H))
    print("winners by family:", won)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
