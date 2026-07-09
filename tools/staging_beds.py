"""staging_beds.py — match a measured artifact footprint to the right BED.

The bed is the body an artifact stands on: plinth (small, held to the eye),
table (operated by hand), platform (a form on a stage), pit (a well, sunk),
panel (flat, wall-hung), floor_work (terrain, flush). Each in sizes. The
selector reads artifact_sizes.json (grid_cells, height, aspect) and returns a
bed token + the CELLS it occupies + the clearance ring the player needs — so
placement can guarantee pathfinding between every artifact on a consistent grid.

Selector logic (footprint fp = max grid-cells side; h = height_m; flat = h<0.5):
  fp<=1, h<=1.4   -> plinth s|m           (specimen, small on one body)
  fp<=1, h>1.4    -> vitrine_tall         (tall+precious, glass)
  fp==2, h<1.2    -> table_2m             (instrument, hand height)
  fp==2, h>=1.2   -> platform m           (a form to stand back from)
  fp 3-4          -> platform l | floor_work m
  fp 5-7          -> floor_work l         (terrain)
  fp>7            -> floor_work l + OVERSIZE flag (its own room)
  very flat wide  -> panel                (wall-hung graphic)
  name ~ well/pool/reflect/liquid -> pit  (the well posture)
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
_SIZES = None


def _sizes():
    global _SIZES
    if _SIZES is None:
        try:
            _SIZES = json.loads((ROOT / "commons/data/artifact_sizes.json").read_text(encoding="utf-8"))["sizes"]
        except Exception:
            _SIZES = {}
    return _SIZES


WELL_HINT = re.compile(r"well|pool|reflect|liquid|water|mirror|pond|basin", re.I)
GRAPHIC_HINT = re.compile(r"paint|print|canvas|photo|poster|graphic|drawing|diagram|chart|screen", re.I)


def select_bed(token: str):
    """Return {bed, cells, clearance, oversize}."""
    e = _sizes().get(token, {})
    gc = e.get("grid_cells", [1, 1])
    gx, gz = float(gc[0]), float(gc[1])
    fp = max(1, int(round(max(gx, gz))))
    thin = min(gx, gz)
    h = float(e.get("height_m", 1.0))
    flat = h < 0.5

    bed, cells, oversize = "exhibit_podium", 1, False

    if WELL_HINT.search(token):
        size = "s" if fp <= 1 else ("m" if fp <= 2 else "l")
        bed, cells = f"exhibit_furniture#kind:pit#size:{size}", max(1, fp)
    elif GRAPHIC_HINT.search(token) and thin <= 1.2:
        # a genuine graphic (painting/print/screen) — hang it on the wall
        size = "s" if fp <= 2 else ("m" if fp <= 3 else "l")
        bed, cells = f"exhibit_furniture#kind:panel#size:{size}", 1
    elif h < 0.35:
        # it LIES on the floor (mosaic, dish, low field) — floor_work, not a wall
        size = "s" if fp <= 1 else ("m" if fp <= 3 else "l")
        bed, cells = f"exhibit_furniture#kind:floor_work#size:{size}", max(1, fp)
    elif fp <= 1:
        if h <= 1.4:
            bed = "exhibit_furniture#kind:plinth#size:" + ("s" if h > 1.0 else "m")
        else:
            bed = "exhibit_furniture#kind:vitrine_tall"
        cells = 1
    elif fp == 2:
        bed = "exhibit_furniture#kind:table_2m" if h < 1.2 else "exhibit_furniture#kind:platform#size:m"
        cells = 2
    elif fp <= 4:
        bed = "exhibit_furniture#kind:platform#size:l" if h >= 0.8 else "exhibit_furniture#kind:floor_work#size:m"
        cells = fp
    elif fp <= 7:
        bed, cells = "exhibit_furniture#kind:floor_work#size:l", fp
    else:
        bed, cells, oversize = "exhibit_furniture#kind:floor_work#size:l", 7, True

    is_wall = "panel" in bed
    return {"bed": bed, "cells": cells, "is_wall": is_wall, "oversize": oversize,
            "fp": fp, "height": round(h, 2)}


if __name__ == "__main__":
    for t in sys.argv[1:] or ["galton_board", "koch_curve", "newton_cradle",
                              "pompeii_mosaic_floor", "dark_sphere", "russell_set_box"]:
        b = select_bed(t)
        print(f"{t:28s} fp={b['fp']} h={b['height']:>4} -> {b['bed']}"
              f"{'  [OVERSIZE]' if b['oversize'] else ''}")
