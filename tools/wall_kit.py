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


def perimeter(bl, sides=("g", "g", "g", "g")):
    """the contract, v2. sides = (n, e, s, w), each:
    'g' wall with the centred gate (the meeting point) · 's' solid wall · 'o' open."""
    n, e, s, w = sides
    for i in range(B):
        if n != "o" and (n == "s" or i not in GATE):
            add_wall(bl, 0, i, "n")
        if s != "o" and (s == "s" or i not in GATE):
            add_wall(bl, B - 1, i, "s")
        if w != "o" and (w == "s" or i not in GATE):
            add_wall(bl, i, 0, "w")
        if e != "o" and (e == "s" or i not in GATE):
            add_wall(bl, i, B - 1, "e")


# enclosure classes (Palle: "one, corner, all sides, 3 part, 4 already in"),
# authored facing north, rotated at seed time
ENCLOSURES = {
    "none":    ("o", "o", "o", "o"),   # NO walls — the room is made by floor,
                                       # level, pillars, things (the most
                                       # important space; SANAA condition)
    "open":    ("g", "g", "g", "g"),   # all gated — the original contract
    "one":     ("s", "g", "g", "g"),   # one solid side
    "corner":  ("s", "s", "g", "g"),   # two adjacent solid
    "channel": ("s", "g", "s", "g"),   # two opposite solid — a corridor
    "three":   ("s", "s", "s", "g"),   # the U — one way in
    "veil":    ("o", "g", "o", "g"),   # open flow one axis, doored the other
}
ENC_WEIGHTS = {"none": 4, "open": 2, "one": 2, "corner": 2, "channel": 1,
               "three": 1, "veil": 2}


def rot_sides(sides, k):
    """rotate the (n,e,s,w) pattern clockwise k quarter-turns."""
    n, e, s, w = sides
    for _ in range(k % 4):
        n, e, s, w = w, n, e, s
    return (n, e, s, w)


# ── the blocks ───────────────────────────────────────────────────────────────

def mk_field():
    bl = blank()
    return bl


def mk_pinwheel():
    bl = blank()
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
    for r in range(2, 6):
        for c in range(2, 6):
            bl["structure"][r][c] = "1"          # sunken centre
    bl["utilities"][3][2] = "wp:-90"             # rise west, back to the ring
    bl["utilities"][4][5] = "wp:90"              # rise east
    return bl


def mk_ledge():
    bl = blank()
    for r in (1, 2):
        for c in range(2, 6):
            bl["structure"][r][c] = "3"          # the overlook island
    bl["utilities"][3][3] = "wp:180"             # stair up, rising north
    bl["utilities"][3][4] = "wp:180"
    return bl


def mk_street():
    bl = blank()
    # one dense wall across the block, door at the centre (the Uffizi bay wall)
    for c in range(1, 7):
        if c not in GATE:
            add_wall(bl, 3, c, "n")
    return bl


def mk_cross():
    bl = blank()
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
    for (r, c) in ((2, 2), (2, 5), (5, 2), (5, 5)):
        for code in "nesw":
            add_wall(bl, r, c, code)             # a sealed pillar cell
    return bl


def mk_chapel():
    """a 4x4 walled hut with ONE door, aisles flowing around it — the only
    enclosed room in an open hall. Built for the voltage pieces: the walk
    streams past; the critical turn requires stepping through a threshold."""
    bl = blank()
    for c in range(2, 6):
        if c != 3:                                   # the one door, north
            add_wall(bl, 2, c, "n")
        add_wall(bl, 5, c, "s")
    for r in range(2, 6):
        add_wall(bl, r, 2, "w")
        add_wall(bl, r, 5, "e")
    return bl


KIT = {"field": mk_field, "pinwheel": mk_pinwheel, "court": mk_court,
       "ledge": mk_ledge, "street": mk_street, "cross": mk_cross,
       "colonnade": mk_colonnade, "chapel": mk_chapel}
WEIGHTS = {"field": 2, "pinwheel": 2, "court": 2, "ledge": 2,
           "street": 2, "cross": 1, "colonnade": 2, "chapel": 1}


# ── the edge COLOUR: the Wang generalisation ─────────────────────────────────
# The original contract said every boundary cell returns to sea level. In Wang
# terms that is ONE colour — every block matches every block, which is why the
# seams could never go wrong. It is also why this kit could not make the
# KitBash platform structures: dressing a seeded map found cliff2+ = 0, not one
# fall edge in the whole map, because nothing is ever allowed to leave h=2 at a
# boundary.
#
# So the constant becomes a LABEL. An edge colour is the height of each of the
# 8 boundary cells along one side, read west->east (n, s) or north->south (w,
# e). Two blocks may abut iff the facing colours are equal — A.e == B.w, A.s ==
# B.n. Sea level is now just the colour "22222222", so every block above keeps
# the colour it always had and still matches everything it always matched.
#
# The colour is DERIVED from the block's own structure, never declared beside
# it. A declared colour is a second source of truth that drifts from the first;
# reading it off the floor means a block cannot lie about its own edge.
FLAT = SEA * B


def edges_of(bl):
    """(n, e, s, w) colours of a block, read off its floor."""
    st = bl["structure"]
    n = "".join(str(st[0][c]) for c in range(B))
    s = "".join(str(st[B - 1][c]) for c in range(B))
    w = "".join(str(st[r][0]) for r in range(B))
    e = "".join(str(st[r][B - 1]) for r in range(B))
    return (n, e, s, w)


# ── deck blocks: the vocabulary the flat contract could not hold ─────────────
# OPT-IN (--decks). Without the flag KIT is untouched and every existing seed
# reproduces byte-for-byte — the additive gate.

def mk_deck():
    """a whole plate lifted to h3 — the elevated deck. Colour '33333333' on
    all four sides, so decks tile with decks and never with sea level."""
    bl = blank()
    for r in range(B):
        for c in range(B):
            bl["structure"][r][c] = "3"
    return bl


def mk_terrace(variant="gate"):
    """the height change made walkable: north half h3, south half h2, with the
    stair at the step. Colours n='33333333', s='22222222' — so a terrace is the
    only way a deck field can come down to a sea-level field. The kit's
    transformer.

    The fold sits between r3 and r4 on EVERY terrace — moving it would rewrite
    the west/east colours ('33332222') and the block would stop tiling. So the
    two plateaus are fixed; the VARIANT is only which cells of the fold you may
    climb, placed in the utilities layer, which the edge colour never sees.
    That is the interior freedom the contract was meant to buy: four readings
    of one colour, interchangeable at every seam.

      gate    the 2-cell centred stair (the original)
      broad   a 4-cell grand stair — the plateau opens wide
      ledge   ONE stair; the rest of the fold is a drop you take but cannot
              climb back, so the upper deck drains freely and returns only here
      split   two stairs at the flanks, an untenanted overlook between them

    ledge and split make the fold a one-way membrane — genuinely a different
    walk, not just a different look. deck_dresser adds the fewest walkways for
    reachability, so as long as one stair connects the plate it leaves the
    asymmetry standing."""
    bl = blank()
    for r in range(4):
        for c in range(B):
            bl["structure"][r][c] = "3"
    stairs = {"gate": (3, 4), "broad": (2, 3, 4, 5),
              "ledge": (3,), "split": (1, 6)}.get(variant, (3, 4))
    for c in stairs:
        bl["utilities"][4][c] = "wp:180"   # rise north, onto the upper plate
    return bl


MOAT = SEA + "00" + "33" + "00" + SEA     # '20033002' — the causeway colour


def mk_causeway():
    """a raised walkway crossing open void — the cyber-district silhouette.

    The first draft made the whole block void except the deck strip, which put
    void on the east and west edges too. Nothing flat could ever sit beside it,
    so the causeway became an island the seeder could not reach and the solver
    spent its life proving grids unsatisfiable. Keeping the outer COLUMNS at sea
    level fixes it: east and west read flat, so a causeway drops into any
    existing hall, while north and south read MOAT so causeways chain into runs.
    That is the edge colour doing the work it was added for — one block, two
    colours, and the drop lives inside."""
    bl = blank()
    for r in range(B):
        for c in range(B):
            if c in (0, B - 1):
                continue                   # the flat shoulders that let it tile
            bl["structure"][r][c] = "3" if c in GATE else "0"
    return bl


def mk_landing(variant="stair"):
    """where a causeway run meets the ground: MOAT to the north, sea level to
    the south, flat shoulders. The pier head — and the only way a causeway
    comes down.

    row 0 must stay MOAT and the outer columns / south edge stay flat, or the
    landing stops tiling. Everything the variant touches lives in the interior
    at the gate columns, so the deck TONGUE — the h3 strip descending from the
    moat — can run short or deep before it steps down:

      stair   tongue r0-1, a 2-cell step at r2 (the original pier head)
      pier    tongue r0-3, the step at r4 — a long jetty before the descent
      broad   short tongue, a 4-cell step splayed across the base

    The tongue is h3 flanked by sea; dropping off its sides is a single step
    (a curb, not a cliff) so it needs no rail and stays walkable all round."""
    bl = blank()
    for c in range(1, B - 1):
        bl["structure"][0][c] = "3" if c in GATE else "0"
    depth = {"stair": 2, "pier": 4, "broad": 2}.get(variant, 2)
    for r in range(1, depth):
        for c in GATE:
            bl["structure"][r][c] = "3"    # the tongue
    step = {"broad": (2, 3, 4, 5)}.get(variant, GATE)
    for c in step:
        bl["utilities"][depth][c] = "wp:180"   # down off the deck onto the plate
    return bl


def mk_deckcorner():
    """the OUTER corner of a deck rectangle — h3 in the SE quadrant, flat
    elsewhere. Authored as the north-west-of-deck corner; the seeder rotates it
    for the other three. This is the piece a full-width band never needed: it
    lets a deck region STOP mid-grid and turn, so plateaus become free-standing
    rectangles instead of stripes. Its edges (flat, 22223333, 22223333, flat)
    are exactly what the terrace caps present at the corners of the frame, so a
    deck rect ringed by terrace*2/0/1/3 caps and four rotated corners tiles by
    construction. Placed only by the plaza-plant, never drawn at random."""
    bl = blank()
    for r in range(4, B):
        for c in range(4, B):
            bl["structure"][r][c] = "3"
    return bl


def mk_deckinner():
    """the REFLEX (inner) corner of a deck region — the armpit of an L, where
    the deck wraps the WEST and SOUTH of this cell. h3 everywhere except the NE
    quadrant (c<4 or r>=4). This is what lets a plateau be an L instead of only
    a rectangle: at the concave corner the deck folds around a single flat cell,
    and this block is that fold. Its edges (33332222, 22223333, 33333333,
    33333333) match a west-cap to the north and a north-cap to the east exactly.
    Rotations give the other three armpits. Frame-only, like the outer corner."""
    bl = blank()
    for r in range(B):
        for c in range(B):
            if c < 4 or r >= 4:
                bl["structure"][r][c] = "3"
    return bl


DECK_KIT = {"deck": mk_deck, "terrace": mk_terrace,
            "causeway": mk_causeway, "landing": mk_landing}
DECK_WEIGHTS = {"deck": 2, "terrace": 3, "causeway": 2, "landing": 3}
CORNER_KIT = {"deckcorner": mk_deckcorner,   # frame-only, never in the pool
              "deckinner": mk_deckinner}
KIT_ALL = {**KIT, **DECK_KIT, **CORNER_KIT}

# framing a deck region: which tile a frame cell needs, by where the deck lies.
_ORTHO = {"N": (-1, 0), "E": (0, 1), "S": (1, 0), "W": (0, -1)}
_DIAG = {"NE": (-1, 1), "SE": (1, 1), "SW": (1, -1), "NW": (-1, -1)}
_CAP = {"S": 2, "N": 0, "E": 1, "W": 3}          # deck in dir -> terrace rot
_OUTER = {"SE": 0, "SW": 1, "NW": 2, "NE": 3}    # deck diagonal -> deckcorner rot
_INNER = {frozenset({"W", "S"}): 0, frozenset({"N", "W"}): 1,
          frozenset({"N", "E"}): 2, frozenset({"E", "S"}): 3}


def frame_deck(deck, terr):
    """Given a set of deck cells, return {(r,c): (block, rot)} covering the deck
    AND the ring of caps/corners that seals it — or None if the shape has a
    frame cell no single tile can serve (an opposite pair, three deck sides, a
    one-wide gap). The caller keeps only shapes that classify cleanly.

    `terr` is a callable rot -> (name, rot) that picks a terrace variant, so the
    frame's stairs vary the same way the band's do."""
    out = {p: ("deck", 0) for p in deck}
    frame = set()
    for (r, c) in deck:
        for dr, dc in list(_ORTHO.values()) + list(_DIAG.values()):
            if (r + dr, c + dc) not in deck:
                frame.add((r + dr, c + dc))
    for (r, c) in frame:
        od = {d for d, (dr, dc) in _ORTHO.items() if (r + dr, c + dc) in deck}
        dd = {d for d, (dr, dc) in _DIAG.items() if (r + dr, c + dc) in deck}
        if len(od) == 1:
            out[(r, c)] = terr(_CAP[next(iter(od))])
        elif len(od) == 2 and frozenset(od) in _INNER:
            out[(r, c)] = ("deckinner", _INNER[frozenset(od)])
        elif len(od) == 0 and len(dd) == 1:
            out[(r, c)] = ("deckcorner", _OUTER[next(iter(dd))])
        else:
            return None
    return out

# named transition variants (edge-preserving, so they SHARE a block's colour and
# cost the solver nothing). "few and named" — sub-templates, not sliders; a
# terrace#ledge is a different room from a terrace, and still says its name.
VARIANTS = {"terrace": ["gate", "broad", "ledge", "split"],
            "landing": ["stair", "pier", "broad"]}


def make_block(name):
    """build a block from a name that may carry a #variant."""
    base, _, var = name.partition("#")
    return KIT_ALL[base](var) if var else KIT_ALL[base]()


def deck_pool():
    """(names, weights) for the --decks pool, variants expanded. A block's
    weight is SPLIT across its variants, so adding transition variety does not
    make terraces more common — the family keeps its budget."""
    names, weights = [], []
    for n in DECK_KIT:
        vs = VARIANTS.get(n)
        if vs:
            for v in vs:
                names.append(f"{n}#{v}")
                weights.append(DECK_WEIGHTS[n] / len(vs))
        else:
            names.append(n)
            weights.append(DECK_WEIGHTS[n])
    return names, weights


_ROT_WALL = {"n": "e", "e": "s", "s": "w", "w": "n"}    # one quarter-turn CW


def rot_block(bl, k):
    """rotate a block k quarter-turns clockwise — floor, walls and walkways.

    Needed the moment edges carry colour: a terrace transitions north-south
    only, so without rotation a deck plateau can never stop travelling east and
    the deck family becomes an island no seed can reach. One authored block,
    four orientations — the same move the enclosures already make.
    """
    k %= 4
    if not k:
        return bl
    out = blank()
    for _ in range(k):
        for r in range(B):
            for c in range(B):
                out["structure"][r][c] = bl["structure"][B - 1 - c][r]
                out["walls"][r][c] = "".join(
                    _ROT_WALL[ch] for ch in bl["walls"][B - 1 - c][r] if ch in _ROT_WALL)
                u = bl["utilities"][B - 1 - c][r]
                if u.startswith("wp"):
                    parts = u.split(":")
                    ang = int(parts[1]) if len(parts) > 1 else 0
                    u = f"wp:{(ang + 90) % 360}"
                out["utilities"][r][c] = u
        bl = {kk: [row[:] for row in vv] for kk, vv in out.items()}
    return bl


def choose_blocks(cols, rows, rng, names, weights, flat_first_last=True):
    """Lay blocks so every seam's colours agree — the Wang solve.

    Row-major with backtracking. Candidates at each cell are the blocks whose
    west colour equals the left neighbour's east, and whose north colour equals
    the upper neighbour's south. Weighted-random among the survivors, so the
    dice still throw; the constraint only says which faces the dice may show.

    Connectivity is no longer free. The flat contract guaranteed it by making
    every seam identical; with colours a seam can agree on height and still be
    a wall, or agree on void and be no seam at all. deck_dresser's traversal
    pass is what closes that gap now — this function only promises the seams
    LINE UP, not that you can walk them.
    """
    # a tile is a (block, rotation) pair; its colour is read off the rotated
    # floor. Corner tiles ride along in the cache so the plaza-plant can force
    # them, but they are never offered to the dice (see candidates).
    pool_names = list(names)
    all_names = pool_names + [n for n in CORNER_KIT if n not in pool_names]
    tiles = [(n, k) for n in all_names for k in range(4)]
    cache = {t: edges_of(rot_block(make_block(t[0]), t[1])) for t in tiles}
    wt = {n: weights[names.index(n)] for n in pool_names}
    grid = [[None] * cols for _ in range(rows)]

    # WANT a plateau, and left to weighted chance the solve collapses to all-flat
    # every time — flat outnumbers deck and, having placed one flat block, the
    # cheapest continuation is another. A deck's colour is all-h3 on all four
    # sides, so a deck can only neighbour a deck east-west: deck REGIONS are
    # full-width bands, and a single planted cell rarely grows into one on a wide
    # grid (every cell of its row would have to independently choose deck). So
    # the plant is the whole band — one interior row forced to deck, the rows
    # that skirt it forced to the terrace rotation that caps a plateau (a
    # different transition VARIANT per cell, so the four readings appear across
    # the width). The dice still throw for every row the band does not claim.
    #
    #   row bR-1   terrace*2   flat above -> deck below   (the north cap)
    #   row bR     deck        the plateau
    #   row bR+1   terrace*0   deck above -> flat below    (the south cap)
    #
    # bR-1 >= 1 keeps the north cap off the spawn row (which must stay flat);
    # bR+1 may be the last row, since a terrace*0's south edge IS flat and so
    # satisfies the teleporter's footing. Needs rows >= 4.
    # The BAND (above) makes a full-width plateau. The PLAZA makes a free-standing
    # one: a deck rectangle ringed by terrace caps (*2 north, *0 south, *1 west,
    # *3 east) with a rotated deckcorner at each of the four corners — the shape
    # the band could never make because a deck could not stop mid-row. Corners
    # are what let it stop. One is chosen per seed when there is room; the frame
    # only has to avoid the spawn and teleporter cells.
    forced = {}
    tvars = VARIANTS.get("terrace") or [""]

    def _terr(rot):
        v = rng.choice(tvars)
        return (f"terrace#{v}" if v else "terrace", rot)

    def plaza_plant():
        # A deck region — a rectangle, or an L (a rectangle with one corner
        # quadrant bitten out) — dropped inside a one-block frame margin so its
        # caps never land on the spawn or teleporter. frame_deck seals it.
        for _ in range(30):
            dh = rng.randint(1, min(rows - 2, 3))     # deck rect, interior only
            dw = rng.randint(1, min(cols - 2, 3))
            dy = rng.randint(1, rows - 1 - dh)        # >=1 leaves the north ring
            dx = rng.randint(1, cols - 1 - dw)
            deck = {(r, c) for r in range(dy, dy + dh)
                    for c in range(dx, dx + dw)}
            # bite a corner to make an L, when the rect is big enough to stay
            # connected and still leave a reflex corner
            if dh >= 2 and dw >= 2 and rng.random() < 0.55:
                bh = rng.randint(1, dh - 1)
                bw = rng.randint(1, dw - 1)
                corner = rng.choice([(dy, dx), (dy, dx + dw - bw),
                                     (dy + dh - bh, dx),
                                     (dy + dh - bh, dx + dw - bw)])
                deck -= {(corner[0] + r, corner[1] + c)
                         for r in range(bh) for c in range(bw)}
            if not deck:
                continue
            f = frame_deck(deck, _terr)
            if f is None:
                continue                          # a shape with a bad frame cell
            box = set(f)
            if (0, 0) in box or (rows - 1, cols - 1) in box:
                continue
            if any(not (0 <= r < rows and 0 <= c < cols) for r, c in box):
                continue                          # frame must fit the grid
            return f
        return {}

    if any(n in DECK_KIT for n in names):
        # plaza when it fits and the coin says so; else the full-width band
        if rows >= 3 and cols >= 3 and rng.random() < 0.5:
            forced = plaza_plant()
        if not forced and rows >= 4:
            bR = rng.randrange(2, rows - 1)
            for bc in range(cols):
                forced[(bR - 1, bc)] = _terr(2)
                forced[(bR, bc)] = ("deck", 0)
                forced[(bR + 1, bc)] = _terr(0)
        elif not forced and rows * cols > 1:
            p = (rng.randrange(rows), rng.randrange(cols))   # the old point plant
            if p not in ((0, 0), (rows - 1, cols - 1)):
                forced[p] = None            # None = "any DECK_KIT tile"

    def candidates(br, bc):
        out = []
        for t in tiles:
            en, ee, es, ew = cache[t]
            if bc > 0 and cache[grid[br][bc - 1]][1] != ew:
                continue
            if br > 0 and cache[grid[br - 1][bc]][2] != en:
                continue
            if flat_first_last and (br, bc) == (0, 0) and en + ee + es + ew != FLAT * 4:
                continue          # calm arrival: spawn stands on sea level
            if flat_first_last and (br, bc) == (rows - 1, cols - 1) \
                    and es != FLAT:
                continue          # the teleporter needs solid ground under it
            if (br, bc) in forced:
                want = forced[(br, bc)]
                if want is None:
                    if t[0] not in DECK_KIT:
                        continue  # point plant: any deck block
                elif t != want:
                    continue      # band/plaza plant: this exact tile
            elif t[0] in CORNER_KIT:
                continue          # corners are frame-only, never drawn at random
            out.append(t)
        return out

    # A budget, because an unsatisfiable grid is not rare and proving it the
    # honest way costs 48^(rows*cols). The first --decks sweep hung here.
    budget = [200_000]

    def solve(i):
        if i == rows * cols:
            return True
        budget[0] -= 1
        if budget[0] <= 0:
            return False
        br, bc = divmod(i, cols)
        pool = candidates(br, bc)
        while pool:
            pick = rng.choices(pool, [wt.get(t[0], 1) for t in pool])[0]
            grid[br][bc] = pick
            if solve(i + 1):
                return True
            pool.remove(pick)          # that colour dead-ended; try another
            grid[br][bc] = None
            if budget[0] <= 0:
                return False
        return False

    if not solve(0):
        if forced:                     # the plateau was too greedy for this
            forced.clear()             # grid — fall back to a flat colouring
            budget[0] = 200_000
            grid = [[None] * cols for _ in range(rows)]
            if solve(0):
                return grid
        raise SystemExit("wall_kit: no colouring satisfies this grid — "
                         "widen the kit or drop --decks")
    return grid


# ── the seeder ───────────────────────────────────────────────────────────────

def spanning_tree(cols, rows, rng):
    """random DFS tree over the block grid; returns the set of tree seams,
    each as frozenset({(br,bc),(br2,bc2)}). Tree seams are forced open (gated)
    so the map is connected BY CONSTRUCTION however solid the other seams get."""
    start = (rng.randrange(rows), rng.randrange(cols))
    seen = {start}
    stack = [start]
    seams = set()
    while stack:
        r, c = stack[-1]
        nbrs = [(r + dr, c + dc) for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1))
                if 0 <= r + dr < rows and 0 <= c + dc < cols
                and (r + dr, c + dc) not in seen]
        if not nbrs:
            stack.pop()
            continue
        nb = rng.choice(nbrs)
        seams.add(frozenset({(r, c), nb}))
        seen.add(nb)
        stack.append(nb)
    return seams


def seed_map(cols, rows, seed, name, decks=False):
    rng = random.Random(seed)
    enames = list(ENCLOSURES)
    eweights = [ENC_WEIGHTS[n] for n in enames]
    if decks:
        # the coloured solve — deck blocks in play, seams must agree
        dnames, dweights = deck_pool()
        names = list(KIT) + dnames
        weights = [WEIGHTS[n] for n in KIT] + dweights
        chosen = choose_blocks(cols, rows, rng, names, weights)
    else:
        # the original path, untouched: one colour, so no solve is needed and
        # every seed ever thrown still lands exactly where it landed before
        names = list(KIT)
        weights = [WEIGHTS[n] for n in names]
        chosen = [[rng.choices(names, weights)[0] for _ in range(cols)]
                  for _ in range(rows)]
        chosen[0][0] = "field"                   # calm arrival
    # enclosure + rotation per block
    encl = [[rot_sides(ENCLOSURES[rng.choices(enames, eweights)[0]],
                       rng.randrange(4)) for _ in range(cols)]
            for _ in range(rows)]
    # the connectivity guarantee: tree seams must be gated on BOTH sides
    tree = spanning_tree(cols, rows, rng)
    SIDE = {(-1, 0): 0, (0, 1): 1, (1, 0): 2, (0, -1): 3}   # n e s w index
    for br in range(rows):
        for bc in range(cols):
            for (dr, dc), i in SIDE.items():
                nb = (br + dr, bc + dc)
                if 0 <= nb[0] < rows and 0 <= nb[1] < cols and \
                        frozenset({(br, bc), nb}) in tree:
                    sides = list(encl[br][bc])
                    if sides[i] == "s":       # unseal solids only — never
                        sides[i] = "g"        # add a wall to an open side
                    encl[br][bc] = tuple(sides)
    W, H = cols * B, rows * B
    layers = {"structure": [[SEA] * W for _ in range(H)],
              "utilities": [[" "] * W for _ in range(H)],
              "walls": [[""] * W for _ in range(H)],
              "interactables": [[" "] * W for _ in range(H)]}
    for br in range(rows):
        for bc in range(cols):
            _pick = chosen[br][bc]
            if isinstance(_pick, tuple):
                bl = rot_block(make_block(_pick[0]), _pick[1])
            else:
                bl = make_block(_pick)
            perimeter(bl, encl[br][bc])
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
                         "dimensions": {"width": W, "depth": H,
                                        "max_height": 3},
                         "wall_kit": {"seed": seed, "grid": f"{cols}x{rows}",
                                      "blocks": [[list(b) if isinstance(b, tuple) else b for b in row]
                                                 for row in chosen],
                                      "enclosures": [["".join(e) for e in row]
                                                     for row in encl]}},
            "settings": {"wall_segments": {"style": "labwall", "height": 3.2,
                                        "thickness": 0.16, "door_width": 2.2}},
            "layers": layers}
    import wall_runs as _wr
    _wr.annotate(data, name)   # marriage 2: runs live in the map
    import wall_props as _wp
    _wp.annotate(data, name)    # the hospitality layer on the run slots
    out = ROOT / "commons" / "maps" / name
    out.mkdir(parents=True, exist_ok=True)
    with open(out / "map_data.json", "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, indent=1)
    return chosen, encl


def main() -> int:
    if "--list" in sys.argv:
        for n in KIT:
            print(n)
        for n in DECK_KIT:
            print(f"{n}  (--decks)")
        return 0
    arg = lambda k, d: next((a.split("=", 1)[1] for a in sys.argv
                             if a.startswith(f"--{k}=")), d)
    cols, rows = (int(x) for x in arg("grid", "3x2").split("x"))
    seed = int(arg("seed", "7"))
    name = arg("name", f"WallKit_Seed_{seed}")
    decks = "--decks" in sys.argv
    chosen, encl = seed_map(cols, rows, seed, name, decks)
    print(f"{name}: {cols}x{rows} blocks ({cols*B}x{rows*B} cells), seed {seed}")
    for br, row in enumerate(chosen):
        cells = []
        for bc, n in enumerate(row):
            label = f"{n[0]}*{n[1]}" if isinstance(n, tuple) else n
            cells.append(f"{label:11s}[{''.join(encl[br][bc])}]")
        print("  " + " | ".join(cells))
    print(f"view: /map-viewer?map={name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
