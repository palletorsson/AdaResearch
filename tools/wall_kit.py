#!/usr/bin/env python3
"""wall_kit.py — the modular room kit: 8x8 blocks with matching edges, seedable.

Palle: "if we let each 8x8 block have repeatable edges that match we can seed
the maps — like when you want a pattern to repeat you turn the corner to the
middle." The textile half-drop trick applied to rooms — Wang tiles for space.

THE EDGE CONTRACT (what makes any block sit next to any block):
  - every boundary cell returns to SEA LEVEL (h=2); interiors may sink (court
    h1) or rise (ledge h3) but must come home at the edge
  - every block walls its perimeter EXCEPT a 2-cell GATE centered on each side
    (cells 3-4 of 8) — the "same out meeting point": abutting gates align
  - interior features never block the four gate approaches

Blocks (from the canon study + the evolved champions):
  field      open floor — the breathing room
  pinwheel   four sliding walls around a still centre (Barcelona)
  court      sunken h1 centre, wedges back up (Raumplan)
  ledge      raised h3 island, stair down (the overlook)
  street     one dense niche wall with a centred door (Uffizi)
  cross      four quadrant rooms around a crossing
  colonnade  four pillars — nave and aisles implied

Seeder: --grid=COLSxROWS --seed=N --name=Map  ->  stitched map_data.json,
spawn in the first block, teleporter in the last, hull sealed. Guaranteed
walkable BY CONSTRUCTION (the contract), verified by the pathfinder anyway.

Usage:
  python tools/wall_kit.py --list
  python tools/wall_kit.py --seed=7 --grid=3x2 --name=WallKit_Seed_1
"""
import json
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

B = 8            # block size
SEA = "2"        # edge-contract floor height
GATE = (3, 4)    # the centred meeting point, every side of every block


def blank():
    return {"structure": [[SEA] * B for _ in range(B)],
            "utilities": [[" "] * B for _ in range(B)],
            "walls": [[""] * B for _ in range(B)]}


def add_wall(bl, r, c, code):
    if code not in bl["walls"][r][c]:
        bl["walls"][r][c] += code


def perimeter(bl):
    """the contract: perimeter walls with centred gates on all four sides."""
    for i in range(B):
        if i not in GATE:
            add_wall(bl, 0, i, "n")
            add_wall(bl, B - 1, i, "s")
            add_wall(bl, i, 0, "w")
            add_wall(bl, i, B - 1, "e")


# ── the blocks ───────────────────────────────────────────────────────────────

def mk_field():
    bl = blank()
    perimeter(bl)
    return bl


def mk_pinwheel():
    bl = blank()
    perimeter(bl)
    # four sliding walls, each stopping short — corner gaps admit rotationally
    for c in (2, 3, 4):
        add_wall(bl, 3, c, "n")          # top wall (between r2/r3), c2..4
    for r in (2, 3, 4):
        add_wall(bl, r, 5, "e")          # right wall shifted up
    for c in (3, 4, 5):
        add_wall(bl, 5, c, "s")          # bottom wall shifted right
    for r in (3, 4, 5):
        add_wall(bl, r, 2, "w")          # left wall shifted down
    return bl


def mk_court():
    bl = blank()
    perimeter(bl)
    for r in range(2, 6):
        for c in range(2, 6):
            bl["structure"][r][c] = "1"          # sunken centre
    bl["utilities"][3][2] = "wp:-90"             # rise west, back to the ring
    bl["utilities"][4][5] = "wp:90"              # rise east
    return bl


def mk_ledge():
    bl = blank()
    perimeter(bl)
    for r in (1, 2):
        for c in range(2, 6):
            bl["structure"][r][c] = "3"          # the overlook island
    bl["utilities"][3][3] = "wp:180"             # stair up, rising north
    bl["utilities"][3][4] = "wp:180"
    return bl


def mk_street():
    bl = blank()
    perimeter(bl)
    # one dense wall across the block, door at the centre (the Uffizi bay wall)
    for c in range(1, 7):
        if c not in GATE:
            add_wall(bl, 3, c, "n")
    return bl


def mk_cross():
    bl = blank()
    perimeter(bl)
    # four quadrant rooms; the crossing stays open at the gates
    for r in range(B):
        if r not in GATE:
            add_wall(bl, r, 4, "w")
    for c in range(B):
        if c not in GATE:
            add_wall(bl, 4, c, "n")
    return bl


def mk_colonnade():
    bl = blank()
    perimeter(bl)
    for (r, c) in ((2, 2), (2, 5), (5, 2), (5, 5)):
        for code in "nesw":
            add_wall(bl, r, c, code)             # a sealed pillar cell
    return bl


KIT = {"field": mk_field, "pinwheel": mk_pinwheel, "court": mk_court,
       "ledge": mk_ledge, "street": mk_street, "cross": mk_cross,
       "colonnade": mk_colonnade}
WEIGHTS = {"field": 2, "pinwheel": 2, "court": 2, "ledge": 2,
           "street": 2, "cross": 1, "colonnade": 2}


# ── the seeder ───────────────────────────────────────────────────────────────

def seed_map(cols, rows, seed, name):
    rng = random.Random(seed)
    names = list(KIT)
    weights = [WEIGHTS[n] for n in names]
    chosen = [[rng.choices(names, weights)[0] for _ in range(cols)]
              for _ in range(rows)]
    chosen[0][0] = "field"                       # calm arrival
    W, H = cols * B, rows * B
    layers = {"structure": [[SEA] * W for _ in range(H)],
              "utilities": [[" "] * W for _ in range(H)],
              "walls": [[""] * W for _ in range(H)],
              "interactables": [[" "] * W for _ in range(H)]}
    for br in range(rows):
        for bc in range(cols):
            bl = KIT[chosen[br][bc]]()
            for r in range(B):
                for c in range(B):
                    R, C = br * B + r, bc * B + c
                    layers["structure"][R][C] = bl["structure"][r][c]
                    layers["utilities"][R][C] = bl["utilities"][r][c]
                    layers["walls"][R][C] = bl["walls"][r][c]
    # seal the hull: outer boundary walls, gates included
    for c in range(W):
        layers["walls"][0][c] = layers["walls"][0][c].replace("n", "") + "n"
        layers["walls"][H - 1][c] = layers["walls"][H - 1][c].replace("s", "") + "s"
    for r in range(H):
        layers["walls"][r][0] = layers["walls"][r][0].replace("w", "") + "w"
        layers["walls"][r][W - 1] = layers["walls"][r][W - 1].replace("e", "") + "e"
    layers["utilities"][1][1] = "sp"
    layers["utilities"][H - 2][W - 2] = "t:restart"
    layers["structure"][H - 2][W - 2] = "0"      # teleporter sits on void
    data = {"map_info": {"name": name, "lookup_name": name, "title": name,
                         "wall_kit": {"seed": seed, "grid": f"{cols}x{rows}",
                                      "blocks": chosen}},
            "layers": layers}
    out = ROOT / "commons" / "maps" / name
    out.mkdir(parents=True, exist_ok=True)
    with open(out / "map_data.json", "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, indent=1)
    return chosen


def main() -> int:
    if "--list" in sys.argv:
        for n in KIT:
            print(n)
        return 0
    arg = lambda k, d: next((a.split("=", 1)[1] for a in sys.argv
                             if a.startswith(f"--{k}=")), d)
    cols, rows = (int(x) for x in arg("grid", "3x2").split("x"))
    seed = int(arg("seed", "7"))
    name = arg("name", f"WallKit_Seed_{seed}")
    chosen = seed_map(cols, rows, seed, name)
    print(f"{name}: {cols}x{rows} blocks ({cols*B}x{rows*B} cells), seed {seed}")
    for row in chosen:
        print("  " + " | ".join(f"{n:9s}" for n in row))
    print(f"view: /map-viewer?map={name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
