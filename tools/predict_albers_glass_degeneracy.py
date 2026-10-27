#!/usr/bin/env python3
"""predict_albers_glass_degeneracy.py - albers_wall_gallery.medium, the closest pair predicted
BEFORE any sweep, in the bite critic's own currency (CLAUDE.md: "PREDICT THE CLOSEST PAIR
BEFORE THE CAPTURE ... THE PREDICTION IS A LOWER BOUND").

Input: ada_run/albers_glass_layers.json, written by probe_albers_glass.gd --mode=check: every
box of the wall as BUILT (read-back rectangles and colours), for paint, relief and cubes.

What it draws: the whole wall HEAD-ON, orthographic, flat, at 400 px/m with a 0.3 m dark
border, no perspective, no light, no antialiasing:
  relief  pixel = B x prod(face) over the slabs covering it (each slab crossed once), linear
  cubes   pixel = B x prod(face^2) over the cubes AND edge bars covering it (closed shells,
          crossed twice), linear; a shelf's front face, which stands in front of the glass,
          shows its own byte
  paint   every mesh's head-on rectangle in z order: lit boxes at their albedo (no light),
          the painted quads at their displayed colour srgb(byte)
Then artifact_dna_critic's pipeline on each pair, imported, not re-implemented: subject box
from pixel (3,3), crop to the union of the two boxes, background neutralised per frame, grey,
160 x 160, FOCUS = mean of the hottest 5 percent.

Why it is a floor: the critic photographs from yaw 0.62 / pitch -0.26 in perspective, where
the cubes show side faces, edge bars from two sides, parallax between neighbours and shelf
tops, none of which a head-on flat raster has; relief at that standpoint shows only its 3 cm
steps. Every one of those adds difference between relief and cubes.

Writes ada_run/albers_glass_predict/<medium>.png and ada_run/albers_glass_predict/predicted.json.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))
from artifact_dna_critic import _subject_bbox, diff, load_img  # noqa: E402

SRC = REPO / "ada_run" / "albers_glass_layers.json"
OUT = REPO / "ada_run" / "albers_glass_predict"
PPM = 400.0
BORDER = 0.3
BG = (38, 36, 46)


def lin(x):
    x = np.asarray(x, dtype=np.float64)
    return np.where(x <= 0.04045, x / 12.92, ((x + 0.055) / 1.055) ** 2.4)


def srgb(x):
    x = np.clip(np.asarray(x, dtype=np.float64), 0.0, 1.0)
    return np.where(x <= 0.0031308, x * 12.92, 1.055 * x ** (1.0 / 2.4) - 0.055)


class Frame:
    def __init__(self, x0: float, y0: float, x1: float, y1: float):
        self.x0, self.y1 = x0 - BORDER, y1 + BORDER
        self.w = int(round((x1 - x0 + 2 * BORDER) * PPM))
        self.h = int(round((y1 - y0 + 2 * BORDER) * PPM))

    def span(self, x0, y0, x1, y1):
        """Pixel index ranges whose centres fall inside the rectangle (no AA)."""
        c0 = int(np.ceil((x0 - self.x0) * PPM - 0.5))
        c1 = int(np.floor((x1 - self.x0) * PPM - 0.5)) + 1
        r0 = int(np.ceil((self.y1 - y1) * PPM - 0.5))
        r1 = int(np.floor((self.y1 - y0) * PPM - 0.5)) + 1
        return max(r0, 0), min(r1, self.h), max(c0, 0), min(c1, self.w)


def wall_extent(layers: dict):
    plate = layers["relief"]["backing"][0]
    return plate[0], plate[1], plate[2], plate[3]


def draw_glass(layers: dict, medium: str, fr: Frame) -> np.ndarray:
    m = layers[medium]
    passes = int(m["passes"])
    img = np.zeros((fr.h, fr.w, 3))
    img[:] = np.array(BG) / 255.0
    backing = m["backing"]
    plate = backing[0]
    r0, r1, c0, c1 = fr.span(*plate[:4])
    # linear light product over the plate
    prod = np.ones((fr.h, fr.w, 3))
    for b in m["boxes"]:
        rr0, rr1, cc0, cc1 = fr.span(*b[:4])
        if rr1 <= rr0 or cc1 <= cc0:
            continue
        f = lin(np.array(b[6]) / 255.0) ** passes
        prod[rr0:rr1, cc0:cc1] *= f
    table = lin(np.array(m["table"]) / 255.0)
    img[r0:r1, c0:c1] = srgb(table * prod[r0:r1, c0:c1])
    # shelves' front faces stand in front of every glass box
    for s in backing[1:]:
        rr0, rr1, cc0, cc1 = fr.span(*s[:4])
        img[rr0:rr1, cc0:cc1] = np.array(s[6]) / 255.0
    return img


def draw_paint(layers: dict, fr: Frame) -> np.ndarray:
    img = np.zeros((fr.h, fr.w, 3))
    img[:] = np.array(BG) / 255.0
    for r in sorted(layers["paint"]["rects"], key=lambda r: r[4]):
        rr0, rr1, cc0, cc1 = fr.span(*r[:4])
        if rr1 <= rr0 or cc1 <= cc0:
            continue
        img[rr0:rr1, cc0:cc1] = np.array(r[5]) / 255.0
    return img


def save(img: np.ndarray, p: Path) -> None:
    Image.fromarray(np.clip(np.round(img * 255.0), 0, 255).astype(np.uint8), "RGB").save(p)


def critic_pair(a: Path, b: Path) -> dict:
    ba, bb = _subject_bbox(a), _subject_bbox(b)
    box = (min(ba[0], bb[0]), min(ba[1], bb[1]), max(ba[2], bb[2]), max(ba[3], bb[3]))
    frame, focus = diff(load_img(a, box), load_img(b, box))
    return {"frame_pct": round(frame * 100, 2), "focus_pct": round(focus * 100, 2), "crop": box}


def main() -> int:
    if not SRC.exists():
        print(f"no {SRC}: run probe_albers_glass.gd --mode=check first")
        return 2
    layers = json.loads(SRC.read_text(encoding="utf-8"))
    OUT.mkdir(parents=True, exist_ok=True)
    fr = Frame(*wall_extent(layers))
    paths = {}
    for med in ("paint", "relief", "cubes"):
        img = draw_paint(layers, fr) if med == "paint" else draw_glass(layers, med, fr)
        paths[med] = OUT / f"{med}.png"
        save(img, paths[med])
    pairs = {}
    for a, b in (("relief", "cubes"), ("paint", "relief"), ("paint", "cubes")):
        pairs[f"{a} vs {b}"] = critic_pair(paths[a], paths[b])
        print(f"  {a:6s} vs {b:6s}: focus {pairs[f'{a} vs {b}']['focus_pct']:6.2f}%  "
              f"frame {pairs[f'{a} vs {b}']['frame_pct']:6.2f}%")
    closest = min(pairs, key=lambda k: pairs[k]["focus_pct"])
    out = {"view": "head-on orthographic, flat, 400 px/m, no light, no AA", "pairs": pairs,
           "closest": closest, "frame_px": [fr.w, fr.h], "source": str(SRC.relative_to(REPO))}
    (OUT / "predicted.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print("closest:", closest, "->", (OUT / "predicted.json").relative_to(REPO))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
