#!/usr/bin/env python3
"""make_foliage_cards.py — transparent foliage images for the biome's cover cards.

Palle (2026-09-18): "can we add grass and plant foliage? transparent image". The cover of
the biome object (commons/artifacts/biome_object) was low-poly shapes — a plain green quad
for a blade, a cylinder for a reed, a sphere for a bloom. This draws the classic answer:
alpha-cut images of grass tufts and plants on crossed cards. Procedural and seeded, so the
defaults are ours and reproducible; drop any 512 x 512 RGBA PNG with the same name in
commons/biome_layers/foliage/ to replace one (the object loads them at runtime by name).

  python tools/make_foliage_cards.py            # writes the five cards + a contact sheet
  python tools/make_foliage_cards.py --seed 3   # another draw

Cards (each drawn supersampled at 1024 and downsampled to 512 for soft alpha edges):
  grass   a tuft of 12-16 tapered blades, some bent over, base dark to tip light
  reed    tall straight blades, two with a brown cattail head
  fern    one arching rachis with pinnae either side, shrinking to the tip
  plant   a broadleaf rosette, seven to nine leaves with a lighter midrib
  litter  fallen leaves scattered flat, browns and ochres (laid flat under a canopy)
"""
from __future__ import annotations

import argparse
import math
import os
import random
from pathlib import Path

from PIL import Image, ImageDraw

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "commons" / "biome_layers" / "foliage"
S = 1024          # supersampled canvas
FINAL = 512


def lerp(a, b, t):
    return a + (b - a) * t


def col(c, j=0.0, rng=None):
    r, g, b = c
    if rng is not None and j:
        d = rng.uniform(-j, j)
        r, g, b = r + d, g + d, b + d
    return (int(max(0, min(1, r)) * 255), int(max(0, min(1, g)) * 255), int(max(0, min(1, b)) * 255), 255)


def bez(p0, p1, p2, t):
    x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
    y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
    return x, y


def blade(draw, p0, p1, p2, w0, w1, c0, c1, segs=44, rng=None):
    """A tapered strip along a quadratic Bézier, colour lerped base → tip."""
    pts = [bez(p0, p1, p2, i / segs) for i in range(segs + 1)]
    for i in range(segs):
        ax, ay = pts[i]
        bx, by = pts[i + 1]
        tx, ty = bx - ax, by - ay
        n = math.hypot(tx, ty) or 1.0
        nx, ny = -ty / n, tx / n
        wa = lerp(w0, w1, i / segs) * 0.5
        wb = lerp(w0, w1, (i + 1) / segs) * 0.5
        t = i / segs
        c = tuple(int(lerp(c0[k], c1[k], t)) for k in range(3)) + (255,)
        draw.polygon([(ax + nx * wa, ay + ny * wa), (bx + nx * wb, by + ny * wb),
                      (bx - nx * wb, by - ny * wb), (ax - nx * wa, ay - ny * wa)], fill=c)


def leaf(draw, base, angle, length, width, c, rib=None, curl=0.0, segs=28):
    """A leaf: width profile sin(pi u)^0.8 about a slightly curving axis; optional midrib."""
    ca, sa = math.cos(angle), math.sin(angle)
    pts_l, pts_r, axis = [], [], []
    for i in range(segs + 1):
        u = i / segs
        d = length * u
        bend = curl * length * u * u
        x = base[0] + ca * d - sa * bend
        y = base[1] + sa * d + ca * bend
        w = width * 0.5 * (math.sin(math.pi * u) ** 0.8)
        nx, ny = -sa, ca
        pts_l.append((x + nx * w, y + ny * w))
        pts_r.append((x - nx * w, y - ny * w))
        axis.append((x, y))
    draw.polygon(pts_l + pts_r[::-1], fill=c)
    if rib is not None:
        draw.line(axis[: int(segs * 0.85)], fill=rib, width=max(2, int(width * 0.05)))


def grass(rng):
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    base_y = S - 30
    for _ in range(rng.randint(12, 16)):
        x0 = S * 0.5 + rng.uniform(-90, 90)
        L = rng.uniform(0.45, 0.88) * S
        lean = rng.uniform(-0.30, 0.30) * S
        droop = rng.uniform(0.0, 0.55)
        p0 = (x0, base_y)
        p2 = (x0 + lean * (1.0 + droop), base_y - L * (1.0 - 0.45 * droop))
        p1 = (x0 + lean * 0.25, base_y - L * 0.72)
        c0 = col((0.17, 0.33, 0.10), 0.03, rng)
        c1 = col((0.46, 0.68, 0.26), 0.05, rng)
        blade(d, p0, p1, p2, rng.uniform(22, 34), 2, c0, c1)
    return im


def reed(rng):
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    base_y = S - 20
    heads = 0
    for i in range(rng.randint(5, 7)):
        x0 = S * 0.5 + rng.uniform(-110, 110)
        L = rng.uniform(0.78, 0.96) * S
        lean = rng.uniform(-0.10, 0.10) * S
        p0 = (x0, base_y)
        p2 = (x0 + lean, base_y - L)
        p1 = (x0 + lean * 0.4, base_y - L * 0.55)
        c0 = col((0.30, 0.46, 0.20), 0.03, rng)
        c1 = col((0.52, 0.64, 0.32), 0.04, rng)
        blade(d, p0, p1, p2, rng.uniform(14, 20), 4, c0, c1)
        if heads < 2 and rng.random() < 0.5:
            heads += 1
            hx, hy = p2
            d.ellipse([hx - 14, hy - 70, hx + 14, hy + 70], fill=col((0.40, 0.25, 0.11), 0.03, rng))
    return im


def fern(rng):
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    p0 = (S * 0.5, S - 24)
    lean = rng.uniform(-0.28, 0.28) * S
    p2 = (S * 0.5 + lean * 1.3, S * 0.14)
    p1 = (S * 0.5 + lean * 0.35, S * 0.52)
    n = rng.randint(13, 17)
    for i in range(n):
        t = 0.12 + 0.86 * i / (n - 1)
        x, y = bez(p0, p1, p2, t)
        x2, y2 = bez(p0, p1, p2, min(1.0, t + 0.02))
        ang = math.atan2(y2 - y, x2 - x)
        lp = (0.22 * S) * (1.0 - t) ** 0.75 + 0.03 * S
        wp = lp * 0.34
        c = col((0.14, 0.38, 0.15), 0.03, rng)
        c2 = col((0.30, 0.56, 0.24), 0.03, rng)
        for side in (1, -1):
            a = ang + side * math.radians(rng.uniform(40, 55))
            leaf(d, (x, y), a, lp, wp, c if side > 0 else c2, curl=0.15 * side)
    blade(d, p0, p1, p2, 12, 3, col((0.20, 0.36, 0.14)), col((0.34, 0.52, 0.22)))
    return im


def plant(rng):
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    base = (S * 0.5, S - 40)
    n = rng.randint(7, 9)
    angles = sorted(rng.uniform(-78, 78) for _ in range(n))
    for i, a_deg in enumerate(angles):
        a = math.radians(-90 + a_deg)
        L = rng.uniform(0.34, 0.52) * S * (0.8 + 0.2 * (1 - abs(a_deg) / 90))
        W = rng.uniform(0.11, 0.19) * S
        c = col((0.19, 0.45, 0.21), 0.05, rng)
        rib = col((0.46, 0.68, 0.36), 0.03, rng)
        leaf(d, (base[0] + rng.uniform(-18, 18), base[1]), a, L, W, c, rib=rib, curl=rng.uniform(-0.12, 0.12))
    return im


def litter(rng):
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    browns = [(0.42, 0.28, 0.12), (0.55, 0.38, 0.16), (0.36, 0.24, 0.10), (0.62, 0.48, 0.22), (0.30, 0.30, 0.14)]
    for _ in range(rng.randint(30, 40)):
        x, y = rng.uniform(80, S - 80), rng.uniform(80, S - 80)
        L = rng.uniform(0.09, 0.17) * S
        W = L * rng.uniform(0.35, 0.55)
        a = rng.uniform(0, math.tau)
        c = col(rng.choice(browns), 0.04, rng)
        rib = col((0.30, 0.20, 0.09))
        leaf(d, (x, y), a, L, W, c, rib=rib, curl=rng.uniform(-0.2, 0.2))
    return im


CARDS = {"grass": grass, "reed": reed, "fern": fern, "plant": plant, "litter": litter}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--seed", type=int, default=18)
    ap.add_argument("--sheet", default="")
    a = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    tiles = []
    for name, fn in CARDS.items():
        rng = random.Random(a.seed * 1000 + len(name))
        im = fn(rng).resize((FINAL, FINAL), Image.LANCZOS)
        im.save(OUT / f"{name}.png")
        tiles.append((name, im))
        print(f"  {name}.png  {FINAL}x{FINAL} RGBA, {os.path.getsize(OUT / (name + '.png')) // 1024} KB")
    if a.sheet:
        sheet = Image.new("RGB", (FINAL * len(tiles) + 8 * (len(tiles) - 1), FINAL), (28, 30, 36))
        for i, (_, im) in enumerate(tiles):
            sheet.paste(im, (i * (FINAL + 8), 0), im)
        sheet.save(a.sheet, quality=90)
        print(f"  sheet -> {a.sheet}")
    print(f"wrote {len(tiles)} cards -> {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
