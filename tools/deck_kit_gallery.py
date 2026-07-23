#!/usr/bin/env python3
"""deck_kit_gallery.py — the family portrait of the deck kit.

The KitBash catalog shot: every part of the kit laid out as a separate piece on
black, so the whole vocabulary is legible at one glance. This builds that for
wall_kit — each block placed as its own 8x8 island in a sea of void, spaced on a
grid, labelled, then dressed (railings seal each island's edges) and furnished
(masts + lights + crates), so each part reads as a finished chunk the way the
reference buildings each sit on their own base.

It is a DISPLAY map, not a walk: the islands are deliberately disconnected —
that separation is the catalog. Capture it top-down or iso against the void and
each part stands alone on black.

Usage:
  python tools/deck_kit_gallery.py [--name=DeckKit_Gallery] [--cols=5]
  then: deck_dresser --in-place, deck_props --in-place, capture --mode=map
  (or just run tools/deck_city won't apply — use the three passes directly)
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

import wall_kit as wk

B = wk.B
GUTTER = 3          # void cells between islands — the black between pieces
MARGIN = 3


def arg(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith(f"--{name}="):
            return a.split("=", 1)[1]
    return default


def parts_list():
    parts = list(wk.KIT)                                # the 8 room blocks
    parts.append("deck")
    parts += [f"terrace#{v}" for v in wk.VARIANTS["terrace"]]
    parts.append("causeway")
    parts += [f"landing#{v}" for v in wk.VARIANTS["landing"]]
    parts += ["deckcorner", "deckinner"]
    return parts


def build_block(name):
    """the raw block for a part name (corners have their own factories)."""
    if name == "deckcorner":
        return wk.mk_deckcorner()
    if name == "deckinner":
        return wk.mk_deckinner()
    return wk.make_block(name)


def main():
    name = arg("name", "DeckKit_Gallery")
    cols = int(arg("cols", "5"))
    parts = parts_list()
    rows = (len(parts) + cols - 1) // cols

    # island stride: one block + a gutter, plus one row of label above each
    stride = B + GUTTER
    W = MARGIN * 2 + cols * stride - GUTTER
    H = MARGIN * 2 + rows * (stride + 1) - GUTTER      # +1 label row per island

    struct = [["0"] * W for _ in range(H)]              # void everywhere (black)
    utils = [[" "] * W for _ in range(H)]
    walls = [[""] * W for _ in range(H)]
    inter = [[" "] * W for _ in range(H)]

    for i, part in enumerate(parts):
        gr, gc = divmod(i, cols)
        y0 = MARGIN + gr * (stride + 1) + 1            # +1: leave the label row
        x0 = MARGIN + gc * stride
        bl = build_block(part)
        wk.perimeter(bl, ("o", "o", "o", "o"))         # open — dresser rails void
        for r in range(B):
            for c in range(B):
                struct[y0 + r][x0 + c] = bl["structure"][r][c]
                utils[y0 + r][x0 + c] = bl["utilities"][r][c]
                walls[y0 + r][x0 + c] = bl["walls"][r][c]
        # a label plate just north of the island (rendered on the void)
        label = part.replace("#", " ")
        lx = x0
        if 0 <= y0 - 1 < H and lx < W:
            inter[y0 - 1][lx] = f"request_note:0:1.5#text:{label}"

    # a viewing pad in the corner: spawn stands here, one lit cell over void
    struct[MARGIN][MARGIN] = "2"
    utils[MARGIN][MARGIN] = "sp"

    data = {
        "map_info": {"name": name, "lookup_name": name, "title": "Deck Kit",
                     "dimensions": {"width": W, "depth": H, "max_height": 3}},
        "settings": {"wall_segments": {"height": 1.05, "thickness": 0.08,
                                       "color": [0.85, 0.72, 0.18]}},
        "layers": {"structure": struct, "utilities": utils,
                   "walls": walls, "interactables": inter},
    }
    out = ROOT / "commons" / "maps" / name
    out.mkdir(parents=True, exist_ok=True)
    (out / "map_data.json").write_text(json.dumps(data, indent=1), encoding="utf-8")

    print(f"— deck_kit_gallery: {name} ({W}x{H}) —")
    print(f"  parts   {len(parts)}  in {cols}x{rows} grid")
    print(f"  wrote   commons/maps/{name}/map_data.json")
    print(f"  next    python tools/deck_dresser.py --map={name} --in-place")
    print(f"          python tools/deck_props.py   --map={name} --in-place")
    print(f"  view    /map-viewer?map={name}")


if __name__ == "__main__":
    main()
