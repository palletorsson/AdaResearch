"""tools/scrabble_board.py — render a map as a Scrabble board.

The "scrabble look": a top-down tile grid where every artifact is a tile carrying a VALUE
(its placement weight, the way a Scrabble letter carries a score), sitting on a coloured
PREMIUM SQUARE (its zone-phase affordance, the way a Scrabble board has double/triple cells).

This is the Systematic-Layout-Planning REL chart made visual — and it previews the objective
a placement LOOP would maximise: heavy tiles want to land on gold (golden-zone / power-wall /
teaching) squares, light tiles can sit anywhere, nothing valuable belongs on the entry
(decompression) cell or the red threshold.

    python tools/scrabble_board.py --map=Zone_WarehouseLab --out=<png>

Reads structure + interactables + metadata.zone_grid from the map, looks up each artifact's
spatial_needs to compute its tile value, prints the board score.
"""
from __future__ import annotations
import argparse, glob, json, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
MAPS = ROOT / "commons" / "maps"
REG = ROOT / "commons" / "artifacts" / "registry"

# zone-phase -> (premium label, fill, score multiplier) — the board's coloured squares
PREMIUM = {
    "E": ("entry · decompression", (120, 150, 190), 0),    # don't place a hero here
    "T": ("teaching · golden zone", (210, 170, 70), 3),    # the power wall / triple cell
    "X": ("exploration", (90, 120, 110), 1),               # standard square
    "R": ("threshold · keep moving", (185, 80, 80), 2),    # the X-rating cell (cost to linger)
    "Z": ("exit", (90, 150, 95), 1),
    " ": ("floor", (60, 66, 74), 1),
    "#": ("wall", (34, 36, 42), 0),
    ".": ("void", (20, 21, 26), 0),
}
COMPLEXITY_W = {"beginner": 1, "intermediate": 2, "advanced": 3, "": 2}


def load_needs() -> dict:
    out = {}
    for f in glob.glob(str(REG / "*.json")):
        try:
            d = json.load(open(f, encoding="utf-8"))
        except Exception:
            continue
        for name, a in (d.get("artifacts", d) or {}).items():
            if isinstance(a, dict) and name not in out:
                out[name] = a
    return out


def tile_value(meta: dict) -> int:
    """A Scrabble-like 1..9 weight: how much careful/premium placement this artifact wants.
    Heavy = isolated, well-connected, complex, large."""
    sn = meta.get("spatial_needs", {}) or {}
    iso = int(sn.get("isolation", 0) or 0)
    clusters = len(sn.get("cluster_with", []) or [])
    fp = sn.get("footprint_cells", 1) or 1
    if isinstance(fp, (list, tuple)):
        fp = max([int(x) for x in fp] or [1])
    cw = COMPLEXITY_W.get(meta.get("complexity", ""), 2)
    v = cw + min(iso, 3) + min(clusters, 3) + (2 if int(fp) > 2 else 1)
    return max(1, min(9, v))


def abbrev(name: str) -> str:
    parts = [p for p in name.replace("-", "_").split("_") if p]
    if len(parts) >= 2:
        return (parts[0][0] + parts[1][0]).upper()
    return name[:2].upper()


def render(map_name: str, out: Path) -> dict:
    md = json.load(open(MAPS / map_name / "map_data.json", encoding="utf-8"))
    S = md["layers"]["structure"]
    I = md["layers"]["interactables"]
    zone = md["map_info"]["metadata"].get("zone_grid", [])
    zrows = [list(r) for r in zone] if zone else None
    needs = load_needs()

    rows, cols = len(S), len(S[0])
    T, gap, pad, legend = 66, 4, 28, 150
    W = cols * (T + gap) + gap + pad * 2
    H = rows * (T + gap) + gap + pad * 2 + legend
    img = Image.new("RGB", (W, H), (15, 16, 20))
    d = ImageDraw.Draw(img)
    try:
        fL = ImageFont.truetype("arialbd.ttf", 26); fV = ImageFont.truetype("arialbd.ttf", 14)
        fT = ImageFont.truetype("arialbd.ttf", 20); fs = ImageFont.truetype("arial.ttf", 13)
    except Exception:
        fL = fV = fT = fs = ImageFont.load_default()

    d.text((pad, 14), f"{map_name}  ·  scrabble board (tile value = placement weight)", font=fT, fill=(225, 225, 180))

    score = 0
    def zlabel(r, c):
        if zrows and r < len(zrows) and c < len(zrows[r]):
            return zrows[r][c]
        return " "

    for r in range(rows):
        for c in range(cols):
            x = pad + gap + c * (T + gap); y = pad + 36 + gap + r * (T + gap)
            z = zlabel(r, c)
            _, fill, mult = PREMIUM.get(z, PREMIUM[" "])
            d.rounded_rectangle([x, y, x + T, y + T], radius=6, fill=fill)
            tok = (I[r][c] or "").strip()
            if tok and tok not in ("0", " "):
                name = tok.split(":")[0]
                val = tile_value(needs.get(name, {}))
                score += val * mult
                # the cream Scrabble tile sitting on its premium square
                m = 7
                d.rounded_rectangle([x + m, y + m, x + T - m, y + T - m], radius=5,
                                    fill=(238, 226, 196), outline=(120, 105, 70), width=2)
                lab = abbrev(name)
                bb = d.textbbox((0, 0), lab, font=fL)
                d.text((x + T / 2 - (bb[2] - bb[0]) / 2, y + T / 2 - (bb[3] - bb[1]) / 2 - 4),
                       lab, font=fL, fill=(40, 34, 24))
                d.text((x + T - 20, y + T - 22), str(val), font=fV, fill=(150, 60, 40))

    # legend
    ly = H - legend + 18
    d.text((pad, ly - 4), "premium squares (zone affordances):", font=fs, fill=(200, 200, 200))
    lx = pad
    for z in ("E", "T", "X", "R", "Z"):
        lab, fill, mult = PREMIUM[z]
        d.rounded_rectangle([lx, ly + 18, lx + 22, ly + 40], radius=4, fill=fill)
        d.text((lx + 28, ly + 22), f"{lab}  ×{mult}", font=fs, fill=(205, 205, 205))
        lx += 250
        if lx > W - 240:
            lx = pad; ly += 30
    d.text((pad, H - 26), f"board score (Σ tile_value × premium_mult) = {score}   — the loop maximises this",
           font=fs, fill=(225, 205, 120))
    img.save(out)
    return {"score": score, "size": img.size}


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--map", required=True)
    p.add_argument("--out", required=True)
    a = p.parse_args()
    res = render(a.map, Path(a.out))
    print(f"  {a.map}: board score {res['score']}  -> {a.out}  {res['size']}")


if __name__ == "__main__":
    main()
