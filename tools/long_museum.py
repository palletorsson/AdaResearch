#!/usr/bin/env python3
"""THE LONG MUSEUM — the whole spine laid out as one strip of Z.

2026-08-26, Palle: "For this to work I guess the best way is to create a long
museum first let make a museum that has the total length of spine sequence in z.
Do not change but include with the current primitives, transformation and color
and compassion layout the continue use to make the length of the whole museum
including hall ways. Make it scrollable in a url."

So: one building, 4,852 m long, every hall of every spine sequence in walk
order with a hallway between each pair. The halls that exist are included AS
THEY ARE — this tool reads maps and writes exactly one file,
commons/data/long_museum.json, which is not a map. Nothing under commons/maps
is opened for writing anywhere in here.

    python tools/long_museum.py            # summary, writes nothing
    python tools/long_museum.py --apply    # writes commons/data/long_museum.json
    python tools/long_museum.py --json     # the document on stdout
    python tools/long_museum.py --check    # gate: file vs the maps on disk

ONE TRUTH, AND WHERE IT COMES FROM (2026-08-27, Palle: "wall-map and
long-museum and the endless museum godot are not the same. Can we make them one
truth?"). Three things used to answer differently:

  WHICH HALLS   The editors stand ada_run/em_plan.json — what the museum deals
                from the trunk's pearls. This file used to stand Ribbon_*
                placeholders for every unauthored chapter: 208 halls of which
                155 existed nowhere else, only 53 shared with the editors. It
                takes the plan now. 196 of 197 shared, and the one that is not
                is printed by name.

  HOW BIG       endless_museum.gd advances one cursor, `_next_z += h +
                VESTIBULE_H + porch + court`, and that number lived only in RAM
                — since one-hall streaming, em_built.json holds two segments and
                no file ever held the whole building. So this file re-derived the
                geometry, and a second implementation of one rule drifts: it gave
                every hall h20 where the engine builds h23 (the three passage
                rows), describing a museum about 16% longer than the real one.
                The engine writes down what it builds now, hall by hall, into
                ada_run/em_layout_walk.json, and those measurements are used
                wherever they exist. `--check` fails on any disagreement.

  WHAT IT SAYS  commons/data/book/<chapter>.json, read by all of them already.

A hall nobody has walked has no engine row, so the arithmetic here stands in and
that segment says `layout: "derived"`. The summary prints how many of each. This
tool still reads maps and writes exactly one file, commons/data/long_museum.json;
nothing under commons/maps is opened for writing anywhere in here.
"""
from __future__ import annotations

import argparse
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAPS = os.path.join(ROOT, "commons", "maps")
OUT = os.path.join(ROOT, "commons", "data", "long_museum.json")

SCHEMA = "long_museum/1"

# Both from the engine, so the strip and the built museum measure the same
# hallway: endless_museum.gd:224 `const VESTIBULE_H := 4` and :225
# `const LOBBY_W := 17`. Picking a round number here instead would make every
# chapter band a fiction the moment anyone walked the thing.
VESTIBULE_H = 4
LOBBY_W = 17

# The four token prefixes where the field after the colon is NOT a rotation —
# GridInteractablesComponent.gd branches on them at :557 (mc:), :581
# (gridagent:), :594 (criticalinfo:) and :611 (cluster:) before the normal
# parser ever runs. gridagent's second field is a TIER that picks a scene
# (:925 builds grid_agent_<tier>.tscn), so `gridagent:90` is tier 90, not a
# quarter turn. One cell in the strip is affected — Ribbon_Softbodies_25 (8,1)
# — and the naive split had it on its side.
ROT_AT_FIELD_2 = ("criticalinfo:", "cluster:")   # these two DO put rotation there
PREFIXED = ("mc:", "gridagent:") + ROT_AT_FIELD_2


def spine_order():
    """The chapters, in the order the curriculum teaches them. Never a hardcoded
    list: symmetry and array_tutorial were dissolved on 2026-08-24 and anything
    carrying its own copy of the spine still deals them 13 phantom halls."""
    p = os.path.join(MAPS, "curriculum_spine.json")
    with open(p, encoding="utf-8") as fh:
        doc = json.load(fh)
    rows = [(int(s["order"]), str(s["name"])) for s in doc["spine"]["sequences"]]
    rows.sort()
    return rows


def authored_chapters():
    """The chapters whose halls are named by hand, with their order taken
    verbatim.

    Keys beginning with "_" are skipped: `_readme` is prose and `_placed_added`
    is bookkeeping that RE-LISTS the 25 ribbon halls already sitting inside
    color, change and forces. Walking it as a chapter double-counts those 25 and
    invents two chapters that do not exist in the spine.
    """
    p = os.path.join(ROOT, "commons", "data", "map_authored.json")
    with open(p, encoding="utf-8") as fh:
        doc = json.load(fh)
    return {k: [str(n) for n in v] for k, v in doc.items()
            if not k.startswith("_") and isinstance(v, list)}


def planned_chapters():
    """sequence -> the maps the MUSEUM deals it, in walk order.

    2026-08-27, Palle: "/wall-map must have the same data as /long-museum as all
    other instance in the web editing like /wall-texts."

    They did not, and the gap was not small. This strip stood 208 halls of which
    155 were Ribbon_* — placeholder rooms cut to fit a sequence's map count. The
    editors (/wall-map, /wall-texts, /lines) stand the 196 halls of
    ada_run/em_plan.json, which is what the museum deals from the trunk's pearls.
    Only 53 halls were common to both. So a hall you scrolled past in the strip
    usually had no row in any editor, and a hall you wrote a wall text for was
    usually not in the strip.

    The plan is the one to follow, for a reason this file already states four
    hundred lines down: `grep -c Ribbon endless_museum.gd` is 0. The engine has
    never heard of a ribbon hall, so those 155 were rooms nothing can ever build,
    while all 196 planned maps exist on disk and every one is addressable in the
    book.

    THIS DOES NOT MAKE THE STRIP BUILT. An unauthored chapter still builds from
    one of 26 templates rather than from its map, so its length here remains a
    proposal and `built` still says so per chapter. What changes is WHICH ROOMS
    are proposed: the ones the museum names, which you can open in an editor and
    write a wall text for, instead of stand-ins nobody else has heard of."""
    plan = os.path.join(ROOT, "ada_run", "em_plan.json")
    if not os.path.exists(plan):
        return {}
    try:
        with open(plan, encoding="utf-8") as fh:
            rows = json.load(fh).get("plans", [])
    except Exception:
        return {}
    out = {}
    for r in rows:
        seq, m = r.get("sequence"), r.get("map")
        if seq and m:
            out.setdefault(seq, []).append(m)
    return out


def ribbon_index():
    """sequence -> its Ribbon halls, sorted by name.

    Indexed on the map's own `map_info.metadata.sequence`, never on the
    directory name. tools/ribbon.py:589 cuts the sequence to 14 characters
    before title-casing it, which is why the dirs read Ribbon_Boolean_Surfac_01,
    Ribbon_Cellularautoma_03, Ribbon_Machinelearnin_09, Ribbon_Postfoundation_09,
    Ribbon_Proceduralgene_07, Ribbon_Swarmintellige_06, Ribbon_Foundationscri_09.
    A prefix built as "Ribbon_" + sequence.title() matches none of those seven
    and drops 62 halls without a word.
    """
    out = {}
    for d in sorted(os.listdir(MAPS)):
        if not d.startswith("Ribbon_"):
            continue
        p = os.path.join(MAPS, d, "map_data.json")
        if not os.path.exists(p):
            continue
        doc = load_map(d)
        seq = str(((doc.get("map_info") or {}).get("metadata") or {}).get("sequence") or "")
        if seq:
            out.setdefault(seq, []).append(d)
    for seq in out:
        out[seq].sort()
    return out


_MAP_CACHE = {}


def load_map(name):
    if name not in _MAP_CACHE:
        p = os.path.join(MAPS, name, "map_data.json")
        with open(p, encoding="utf-8") as fh:
            _MAP_CACHE[name] = json.load(fh)
    return _MAP_CACHE[name]


def grid_dims(rows):
    """(w, h) measured off the grid itself.

    map_info.dimensions is stale on 6 of the 244 halls and the worst,
    Trans_Rotation, claims depth 53 against 40 actual rows. Trusting it there
    would push 13 phantom metres into the strip and move every chapter after
    transformation.
    """
    if not rows:
        return 0, 0
    return max(len(r) for r in rows), len(rows)


def parse_cell(cell):
    """One interactables cell -> (token, rot), or None if the cell is empty.

    The `#` split comes FIRST. 100 of the 1,745 cells carry a #config tail and
    nine of those have a colon inside the config — `pickup_gate#pickups:6`,
    `floating_sphere_field#bounds:4,3,18`, three `pusher_block#axis:z#...` —
    so a `:` split up front reads a config value as a rotation and hands back a
    token (`pickup_gate#pickups`) that resolves to nothing.
    """
    cell = str(cell).strip()
    if not cell:
        return None
    head = cell.split("#", 1)[0]
    # Legacy `;` separator, normalised the way _normalize_legacy_semicolon_token
    # does (GridInteractablesComponent.gd:1521): only in the head, only when the
    # name does not already carry a colon.
    if ";" in head and ":" not in head.split(";", 1)[0]:
        head = head.replace(";", ":", 1)
    head = head.strip()
    if not head:
        return None
    for pre in PREFIXED:
        if head.startswith(pre):
            parts = head.split(":")
            rot = 0
            if pre in ROT_AT_FIELD_2 and len(parts) > 2:
                rot = as_float(parts[2])
            # The whole head stays the token: "gridagent:90" IS the identity of
            # that cell, and trimming it to "gridagent" loses the tier.
            return head, rot
    parts = head.split(":")
    return parts[0], (as_float(parts[1]) if len(parts) > 1 else 0)


def as_float(s):
    try:
        v = float(str(s).strip())
    except ValueError:
        return 0.0
    return int(v) if v == int(v) else v


class Problems:
    """Every refusal is announced. A hall that quietly fails to appear shortens
    a chapter the walk still believes in."""

    def __init__(self):
        self.missing = []
        self.layers = []
        self.rows = []

    def any(self):
        return bool(self.missing or self.layers or self.rows)


def content_extent(st):
    """The hall's last row and column that hold anything, one past — the crop
    the engine applies before it builds.

    `_derive_map_row` (endless_museum.gd:16175) walks the structure grid for a
    cell that is an int above zero, a "w" wall, or a "p"/"p:N" platform, keeps
    the largest row and column it finds, and builds rows 0..r1 by columns 0..c1.
    Letters count as content: a map whose far edge ends in a wall must not be
    cropped at that edge.

    WITHOUT THIS THE STRIP DRAWS THE EMPTY TAIL. Palle, looking at the opening
    chapter: "their is a gray gap in z in the beginning maps". Point_Trace is
    stored 20x20 and holds nothing past row 15 or column 7; Primitives_Polythedra
    is 20x20 and holds nothing past row 10 or column 9. The museum never builds
    those cells, so drawing them put a grey field beside and below six halls and
    added 30 m of z the visitor would never walk. Far edges only — a leading
    crop would move the origin, and every cell coordinate in the map is relative
    to it.
    """
    r1 = c1 = -1
    for r, row in enumerate(st):
        for c, v in enumerate(row):
            sv = str(v).strip()
            ok = sv == "w" or sv == "p" or sv.startswith("p:")
            if not ok:
                try:
                    ok = int(sv) > 0
                except (ValueError, TypeError):
                    ok = False
            if ok:
                if r > r1:
                    r1 = r
                if c > c1:
                    c1 = c
    # the engine's own floor: a tile smaller than 3x3 is not a room
    if r1 < 2 or c1 < 2:
        return None
    return r1 + 1, c1 + 1


def engine_layout():
    """What the ENGINE measured, keyed by map name.

    2026-08-27, Palle: "wall-map and long-museum and the endless museum godot are
    not the same. Can we make them one truth?"

    They could not be while this file re-derived the museum's geometry in Python.
    A second implementation of one rule drifts, and this one had: measured that
    day, the strip gave every hall h20 where the engine builds h23 — the three
    passage rows it appends — so a 3,663 m strip described a museum about 16%
    longer than that, and no gate could see it because both numbers were internally
    consistent.

    endless_museum.gd now writes down what it built, hall by hall, as it builds it
    (ada_run/em_layout_walk.json). Where a hall has been walked, its measurements
    come from the engine's own cursor and the strip IS the museum. Where it has
    not, the arithmetic below stands in and every segment says which it used, so
    "the strip disagrees with the museum" is a question with an answer rather than
    a suspicion."""
    p = os.path.join(ROOT, "ada_run", "em_layout_walk.json")
    if not os.path.exists(p):
        return {}
    try:
        with open(p, encoding="utf-8") as fh:
            rows = json.load(fh).get("halls", {})
    except Exception:
        return {}
    out = {}
    for r in rows.values():
        m = r.get("map")
        if m:
            out[m] = r
    return out


def built_tile(e):
    """The hall AS BUILT, cut into the frame the book writes in.

    2026-08-28, Palle: "can we have the wall-map, the long-museum and the desktop
    museum read from the same file when they create the space."

    They could not, because the crop below existed only inside the encyclopedia's
    halls_get and nowhere else. The engine's record holds the whole segment: four
    vestibule rows first, one skin column left of the hall (`cell_x0` -1), then the
    hall and its gallery. Every page that wants to draw the room has to cut that
    the same way, and a rule implemented twice is a rule that will disagree with
    itself — the same fault that gave this file h20 where the engine builds h23.

    So it is cut once, here, and written into the strip. A page reads a field.

    The walk grid says only floor (".", or s/b/p/x for floor under something) and
    not-floor ("#"), which lumps the wall you can hang on together with the empty
    space beyond the building. A not-floor cell touching floor is a WALL ("4");
    everything further out is void ("0"). Drawing the difference away would wrap
    every hall in a solid slab and offer faces on its outside.
    """
    cells = e.get("cells") or []
    if not cells:
        return None
    vest = int(e.get("vestibule", 4))
    skin = -int(e.get("cell_x0", -1))               # -1: one column left of the hall
    rows = [str(r)[skin:] for r in cells[vest:]]
    if not rows or not rows[0]:
        return None

    def floor(rr, cc):
        if rr < 0 or rr >= len(rows) or cc < 0 or cc >= len(rows[rr]):
            return False
        return rows[rr][cc] != "#"

    out = []
    for rr, row in enumerate(rows):
        line = []
        for cc, ch in enumerate(row):
            if ch != "#":
                line.append("1")
            elif floor(rr - 1, cc) or floor(rr + 1, cc) or floor(rr, cc - 1) or floor(rr, cc + 1):
                line.append("4")
            else:
                line.append("0")
        out.append(line)
    return out


def read_hall(name, chapter, order, source, probs, engine=None):
    """One hall as a strip segment, or None if it cannot be read."""
    p = os.path.join(MAPS, name, "map_data.json")
    if not os.path.exists(p):
        probs.missing.append((chapter, name))
        print("ERROR: %s names %s and there is no map_data.json on disk - the hall "
              "is SKIPPED and the chapter is that much shorter" % (chapter, name),
              file=sys.stderr)
        return None
    doc = load_map(name)
    layers = doc.get("layers") or {}
    st = layers.get("structure") or []
    ut = layers.get("utilities") or []
    it = layers.get("interactables") or []
    w, h = grid_dims(st)
    raw_w, raw_h = w, h
    raw_st = st

    for lname, rows in (("structure", st), ("utilities", ut), ("interactables", it)):
        widths = {len(r) for r in rows}
        if len(widths) > 1:
            probs.rows.append((name, lname, sorted(widths)))
            print("ERROR: %s layer %s has ragged rows (%s) - width taken as the widest"
                  % (name, lname, ", ".join(str(x) for x in sorted(widths))), file=sys.stderr)

    dims = {lname: grid_dims(rows) for lname, rows in
            (("structure", st), ("utilities", ut), ("interactables", it))}
    if len(set(dims.values())) > 1:
        probs.layers.append((name, dims))
        # NOT skipped, and this is a deliberate departure from "a layer
        # disagreement is skipped". Exactly one hall in 244 trips it —
        # Trans_AxisDecomposition, structure 9x16 against interactables 14x22 —
        # and it is a hand-built hall of the transformation chapter that Palle
        # said to include as it is. Dropping it would take 20 m out of a
        # protected chapter to punish a defect in a file this tool may not fix.
        # So it stays, the floor is the room (geometry off the structure grid),
        # and the five artifacts that fall outside it are reported here and
        # passed through for the renderer to clamp or flag.
        print("ERROR: %s layers disagree in size (%s) - geometry taken from the "
              "structure grid, artifacts outside it are kept and listed below"
              % (name, ", ".join("%s %dx%d" % (k, v[0], v[1]) for k, v in dims.items())),
              file=sys.stderr)

    # CROP ONLY NOW. Cropping before the check above compared a cropped
    # structure against uncropped utilities and interactables, and turned one
    # genuine layer disagreement into eighteen invented ones. The layers agree
    # or they do not as the FILE holds them; the crop is what the engine does
    # afterwards.
    ext = content_extent(raw_st)
    if ext is not None:
        h, w = ext
        st = [list(row[:w]) + [""] * max(0, w - len(row)) for row in raw_st[:h]]

    arts, strays = [], []
    for z, row in enumerate(it):
        for x, cell in enumerate(row):
            got = parse_cell(cell)
            if got is None:
                continue
            token, rot = got
            arts.append({"x": x, "z": z, "token": token, "rot": rot})
            if x >= w or z >= h:
                strays.append("%s at (%d,%d)" % (token, x, z))
    if strays:
        print("       %d artifact(s) outside %s's %dx%d floor: %s"
              % (len(strays), name, w, h, ", ".join(strays)), file=sys.stderr)

    # THE ENGINE'S OWN MEASUREMENTS WHEN IT HAS THEM. `h` becomes the length the
    # museum's cursor actually advanced by, less its vestibule — so the strip's
    # hall plus its hallway equals the engine's span exactly. The drawn grid stays
    # the map's, because that is what a map holds; `passage` names the rows the
    # engine adds beyond it so the page can show them as what they are rather than
    # as a hall that does not fit its own floor.
    # THREE DIFFERENT THINGS, NOT ONE (2026-08-28). `passage` used to be
    # `engine_h + porch + court - map_h`, which is every row the engine adds
    # beyond the map lumped into one number. That reads fine as a total and is
    # useless the moment anything wants the rows themselves: an editor asking
    # "show me the passage" got the last 58 rows of a hall whose court is 48 deep.
    # They are laid in a fixed order — tile (with its passage rows appended by
    # _authored_passages), then the forecourt, then the court — so naming them
    # separately is what lets a page slice the right ones.
    e = (engine or {}).get(name)
    layout = "derived"
    passage = None          # None = the engine has not counted this one yet
    porch = court = 0
    map_h = h
    if e:
        try:
            tile_h = int(e["h"])                    # the tile INCLUDING its passage rows
            porch = int(e.get("porch", 0))
            court = int(e.get("court", 0))
            eh = tile_h + porch + court
            if eh > 0:
                # THE ENGINE'S OWN COUNT when it has one. Deriving it as
                # tile_h - map_h is only true for the five chapters that build
                # from their own map; a TEMPLATE hall's map is not what stands
                # there, and the subtraction returned 20 and 22 for crossings
                # three rows deep. endless_museum.gd writes `passage` from
                # em_passage_start now, so this is a read, not a guess.
                # NO FALLBACK. Deriving it as tile_h - map_h is only true for a
                # hall that builds from its own map, and it does not fail loudly:
                # measured on 36 rows left over from an earlier bake, it returned
                # 18, 20, 22, 26 and 27 for crossings that are 0, 3 or 4 rows deep,
                # and nothing downstream could tell those from real counts. A hall
                # the engine has not counted says so — the page then asks for a
                # walk instead of drawing a number nobody measured.
                passage = int(e["passage"]) if "passage" in e else None
                h = eh
                w = int(e.get("w", w)) or w
                layout = "engine"
        except (KeyError, TypeError, ValueError):
            layout = "derived"
            passage = None
            porch = court = 0
    seg = {"kind": "hall", "name": name, "sequence": chapter, "chapter": order,
           "z0": 0, "z1": 0, "w": w, "h": h, "x0": -(w // 2),
           "source": source, "layout": layout, "passage": passage,
           "porch": porch, "court": court, "map_h": map_h,
           "passage_kind": str((e or {}).get("passage_kind", "")) if e else "",
           "artifacts": arts, "structure": st}
    # THE ROOM AS BUILT, beside the room as authored. `structure` is the map's own
    # grid — what a map holds, and what the brush edits. `tile` is what the museum
    # raised from it: cropped to content, passage rows appended, a skin and a
    # gallery. They are different rooms and both are wanted, so both are named.
    # A hall nobody has walked has no `tile` at all rather than a plausible guess.
    if e:
        # THE PASSAGE ROWS THEMSELVES (2026-08-28, Palle: "I want to see it in
        # /long-museum"). The strip draws `structure`, which is the MAP — and a
        # passage is not in any map, it is rows the engine appends. So the page
        # could not show one however the seam was built, and the hall it drew was
        # also SHORTER than the z it claimed: h counts the passage, `structure`
        # does not. These are the engine's own carved rows, in the map's own
        # vocabulary, for the page to draw after the hall.
        bt_all = built_tile(e)
        if bt_all and passage:
            tail = bt_all[map_h:map_h + passage]
            if tail:
                seg["passage_rows"] = tail
        bt = bt_all
        if bt:
            seg["tile"] = bt
            seg["tile_source"] = "engine"
            seg["tile_w"] = len(bt[0])
            seg["tile_h"] = len(bt)
    # KEPT SO THE CROP IS AUDITABLE. A hall drawn smaller than the file it came
    # from invites "is the strip losing cells?", and the honest answer is a
    # number rather than a reassurance: these two fields are the grid as stored,
    # and the engine builds the cropped one.
    if (raw_w, raw_h) != (w, h):
        seg["raw_w"] = raw_w
        seg["raw_h"] = raw_h
    return seg


def build():
    probs = Problems()
    authored = authored_chapters()
    planned = planned_chapters()
    ribbons = ribbon_index()
    engine = engine_layout()

    halls = []
    for order, seq in spine_order():
        if seq in authored:
            names = authored[seq]
        elif planned.get(seq):
            # THE MUSEUM'S OWN DEAL, so the strip and the editors name the same
            # rooms. See planned_chapters().
            names = planned[seq]
        else:
            names = ribbons.get(seq, [])
            if not names:
                print("ERROR: %s is dealt, has no plan row and no Ribbon halls "
                      "on disk - the chapter is empty" % seq, file=sys.stderr)
        for n in names:
            # A hall inside an authored chapter can still be a ribbon hall:
            # color, change and forces each end with theirs. The source says
            # which, and the chapter's source below says both.
            src = ("ribbon" if n.startswith("Ribbon_")
                   else "authored" if seq in authored else "plan")
            seg = read_hall(n, seq, order, src, probs, engine)
            if seg is not None:
                halls.append(seg)

    # Z, cumulative and contiguous. The hallway takes the width of the wider of
    # the two halls it joins, floored at the lobby — the engine's
    # `maxi(LOBBY_W, maxi(pw, w))` at endless_museum.gd:5111. Pinning it flat at
    # 17 would make it narrower than the hall it opens into 31 times over, up to
    # VFM_05_Launch at 34, and the strip would read as a pinch that the built
    # museum does not have.
    segments, z = [], 0
    for i, hall in enumerate(halls):
        if True:
            # EVERY SEGMENT HAS A VESTIBULE, INCLUDING THE FIRST. This used to
            # put a hallway only BETWEEN halls — 243 of them — which reads as
            # obvious and is wrong: the engine's only z cursor is
            # `_next_z += h + VESTIBULE_H + porch + court` (endless_museum.gd
            # :5694), one vestibule per segment, and ada_run/em_built.json's
            # segment 0 records z0 0, z1 27 for a hall of h 23. So the museum
            # is entered through a vestibule, not walked into cold.
            prev = halls[i - 1] if i else hall
            vw = max(LOBBY_W, prev["w"], hall["w"])
            # The hallway carries the chapter of the hall it OPENS, not the one
            # it leaves. That is what makes the chapter bands tile exactly:
            # label it with the preceding hall instead and every boundary
            # overlaps its neighbour by 4 m.
            segments.append({"kind": "vestibule", "name": "Vestibule_%03d" % i,
                             "sequence": hall["sequence"], "chapter": hall["chapter"],
                             "z0": z, "z1": z + VESTIBULE_H, "w": vw, "h": VESTIBULE_H,
                             "x0": -(vw // 2), "source": "engine",
                             "artifacts": [], "structure": []})
            z += VESTIBULE_H
        hall["z0"] = z
        hall["z1"] = z + hall["h"]
        z += hall["h"]
        segments.append(hall)

    chapters = []
    for order, seq in spine_order():
        own = [s for s in segments if s["sequence"] == seq]
        if not own:
            continue
        hs = [s for s in own if s["kind"] == "hall"]
        srcs = {s["source"] for s in hs}
        source = "+".join(sorted(srcs)) if len(srcs) > 1 else next(iter(srcs), "authored")
        # BUILT OR PROPOSED, AND THE PAGE MUST BE ABLE TO SAY WHICH.
        # endless_museum.gd builds a plan row from its own map ONLY when the
        # row says authored == "map" (:4858). In ada_run/em_plan.json that is
        # true of 67 of 223 rows, all in the five chapters map_authored.json
        # names; the other 156 build from one of 26 templates. And
        # `grep -c Ribbon endless_museum.gd` is 0 — the engine has never heard
        # of a ribbon hall. So seventeen of these twenty-two chapters are a
        # PROPOSAL, and a strip that does not say so is claiming a museum that
        # does not exist. Roughly two thirds of the length is proposal.
        built = seq in authored
        for s2 in own:
            s2["built"] = built
        # AND A SECOND, DIFFERENT QUESTION (2026-08-28). `built` above is about
        # PROVENANCE — does this hall rise from its own map, or from one of the 26
        # templates. It says nothing about whether the museum has ever stood the
        # room up, and the page was reading it as if it did: "9,771 m proposed —
        # halls the museum has never built", of halls the engine builds every time
        # anyone walks past them. After a full bake it has a measured row for 195
        # of 197. Both facts are worth having and neither is the other, so both are
        # written down: `built` is where the room comes from, `walked` is whether
        # the engine has ever raised it and written down what it raised.
        walked_h = [s for s in hs if s.get("layout") == "engine"]
        walked_m = float(sum(s["z1"] - s["z0"] for s in walked_h))
        chapters.append({"sequence": seq, "order": order,
                         "z0": own[0]["z0"], "z1": hs[-1]["z1"],
                         "halls": len(hs),
                         "artifacts": sum(len(s["artifacts"]) for s in hs),
                         "source": source, "built": built,
                         "walked": len(walked_h), "walked_metres": walked_m})

    n_halls = sum(1 for s in segments if s["kind"] == "hall")
    doc = {"schema": SCHEMA, "axis": "z", "unit_m": 1.0, "vestibule_h": VESTIBULE_H,
           "totals": {"halls": n_halls,
                      "vestibules": sum(1 for s in segments if s["kind"] == "vestibule"),
                      "cells_z": z, "metres": float(z),
                      "artifacts": sum(len(s["artifacts"]) for s in segments),
                      "sequences": len(chapters),
                      "built_metres": float(sum(c["z1"] - c["z0"] for c in chapters
                                                if c["built"])),
                      "proposed_metres": float(sum(c["z1"] - c["z0"] for c in chapters
                                                   if not c["built"])),
                      "built_chapters": sum(1 for c in chapters if c["built"]),
                      "walked_halls": sum(c["walked"] for c in chapters),
                      "walked_metres": float(sum(c["walked_metres"] for c in chapters)),
                      # STATED, NOT IMPLIED. The engine also crops each map to
                      # its last row of content, appends an exit chicane to an
                      # authored hall, and can insert a porch or a court between
                      # buildings. Every one of those makes the museum LONGER
                      # than this strip, so 4,852 is a floor and not a length.
                      "courts_counted": False,
                      "crop_and_chicane_counted": False},
           "chapters": chapters, "segments": segments}
    return doc, probs


def contract_faults(doc):
    """The invariants the file promises, checked on the file rather than assumed
    of the builder — this is what makes --check a gate for a hand edit too."""
    bad = []
    segs = doc.get("segments") or []
    if not segs:
        return ["no segments"]
    if segs[0]["z0"] != 0:
        bad.append("segments[0].z0 is %s, not 0" % segs[0]["z0"])
    for a, b in zip(segs, segs[1:]):
        if a["z1"] != b["z0"]:
            bad.append("gap at %s -> %s: %d != %d" % (a["name"], b["name"], a["z1"], b["z0"]))
        if a["kind"] == "hall" and b["kind"] == "hall":
            bad.append("no hallway between %s and %s" % (a["name"], b["name"]))
    for s in segs:
        if s["x0"] != -(s["w"] // 2):
            bad.append("%s x0 %s, expected %d" % (s["name"], s["x0"], -(s["w"] // 2)))
        if s["z1"] - s["z0"] != s["h"]:
            bad.append("%s spans %d but h is %d" % (s["name"], s["z1"] - s["z0"], s["h"]))
    t = doc.get("totals") or {}
    if t.get("cells_z") != segs[-1]["z1"]:
        bad.append("totals.cells_z %s but the strip ends at %s"
                   % (t.get("cells_z"), segs[-1]["z1"]))
    chs = doc.get("chapters") or []
    for a, b in zip(chs, chs[1:]):
        if a["z1"] != b["z0"]:
            bad.append("chapter band gap: %s ends %d, %s starts %d"
                       % (a["sequence"], a["z1"], b["sequence"], b["z0"]))
    return bad


def diff(built, have, limit=12):
    """What the file says against what the maps say, in the order a reader
    would want it: the totals first, then the chapter, then the segment."""
    out = []
    for k in ("schema", "axis", "unit_m", "vestibule_h"):
        if built.get(k) != have.get(k):
            out.append("%s: file %r, maps %r" % (k, have.get(k), built.get(k)))
    for k in sorted(built["totals"]):
        if built["totals"][k] != (have.get("totals") or {}).get(k):
            out.append("totals.%s: file %r, maps %r"
                       % (k, (have.get("totals") or {}).get(k), built["totals"][k]))
    bc, hc = built["chapters"], have.get("chapters") or []
    if len(bc) != len(hc):
        out.append("chapters: file %d, maps %d" % (len(hc), len(bc)))
    for a, b in zip(hc, bc):
        for k in sorted(b):
            if a.get(k) != b[k]:
                out.append("chapter %s.%s: file %r, maps %r" % (b["sequence"], k, a.get(k), b[k]))
    bs, hs = built["segments"], have.get("segments") or []
    if len(bs) != len(hs):
        out.append("segments: file %d, maps %d" % (len(hs), len(bs)))
    for a, b in zip(hs, bs):
        for k in ("kind", "name", "sequence", "chapter", "z0", "z1", "w", "h", "x0", "source"):
            if a.get(k) != b[k]:
                out.append("segment %s.%s: file %r, maps %r" % (b["name"], k, a.get(k), b[k]))
        if a.get("structure") != b["structure"]:
            out.append("segment %s: structure grid differs" % b["name"])
        if a.get("artifacts") != b["artifacts"]:
            fa = {(d["x"], d["z"]): d for d in (a.get("artifacts") or [])}
            fb = {(d["x"], d["z"]): d for d in b["artifacts"]}
            for cell in sorted(set(fa) | set(fb)):
                if fa.get(cell) != fb.get(cell):
                    out.append("segment %s artifact at (%d,%d): file %r, maps %r"
                               % (b["name"], cell[0], cell[1], fa.get(cell), fb.get(cell)))
    return out[:limit], len(out)


def summary(doc):
    print()
    print("  #  chapter                     z0     z1  metres  halls  arts  source")
    for c in doc["chapters"]:
        print("  %2d  %-22s %6d %6d  %6d  %5d  %4d  %s"
              % (c["order"], c["sequence"], c["z0"], c["z1"], c["z1"] - c["z0"],
                 c["halls"], c["artifacts"], c["source"]))
    t = doc["totals"]
    print("      %-22s %6d %6d  %6d  %5d  %4d  %d hallways of %d m"
          % ("TOTAL", 0, t["cells_z"], t["cells_z"], t["halls"], t["artifacts"],
             t["vestibules"], doc["vestibule_h"]))
    print()
    print("  %d sequences, %d segments, %.1f m of Z (%.3f km)"
          % (t["sequences"], len(doc["segments"]), t["metres"], t["metres"] / 1000.0))
    # WHICH HALLS ARE THE MUSEUM, AND WHICH ARE THIS FILE'S ARITHMETIC. A strip
    # that does not say cannot be trusted about its own length.
    halls = [x for x in doc["segments"] if x["kind"] == "hall"]
    measured = [x for x in halls if x.get("layout") == "engine"]
    if halls:
        print("  %d of %d halls carry the ENGINE's own measurements (%.0f%%); "
              "the rest are derived here"
              % (len(measured), len(halls), 100.0 * len(measured) / len(halls)))
        if len(measured) < len(halls):
            print("     walk the museum to measure more - each hall it builds "
                  "writes itself into ada_run/em_layout_walk.json")


def main():
    ap = argparse.ArgumentParser(description="the whole spine as one strip of Z")
    ap.add_argument("--apply", action="store_true", help="write commons/data/long_museum.json")
    ap.add_argument("--json", action="store_true", help="print the document to stdout")
    ap.add_argument("--check", action="store_true",
                    help="verify the written file against the maps on disk; non-zero on any disagreement")
    args = ap.parse_args()

    doc, probs = build()

    faults = contract_faults(doc)
    if faults:
        # The builder disagreeing with its own contract means the strip is
        # wrong, not the file — refuse before anything is written.
        for f in faults:
            print("CONTRACT: %s" % f, file=sys.stderr)
        return 1

    if args.json:
        json.dump(doc, sys.stdout, ensure_ascii=False, separators=(",", ":"))
        sys.stdout.write("\n")
        return 0

    if args.check:
        # THE ONE THAT MATTERS (2026-08-27). The old check compared this file
        # against the maps, which cannot see the difference that actually bit:
        # both the file and the maps said h20 while the museum built h23, and
        # every number was internally consistent. This compares the file against
        # what the ENGINE recorded building, for every hall it has built.
        eng = engine_layout()
        drift = []
        for s2 in json.load(open(OUT, encoding="utf-8"))["segments"]:
            if s2["kind"] != "hall":
                continue
            e = eng.get(s2["name"])
            if not e:
                continue
            want_h = int(e["h"]) + int(e.get("porch", 0)) + int(e.get("court", 0))
            if int(s2["h"]) != want_h or int(s2["w"]) != int(e.get("w", s2["w"])):
                drift.append("%s: strip %dx%d, the museum built %dx%d"
                             % (s2["name"], s2["w"], s2["h"], int(e.get("w", 0)), want_h))
            # AND THE ROOM ITSELF, not only its measurements. `tile` is the field
            # the editors draw from, so a hall the engine has built and this file
            # gave no tile is a hall /wall-map renders blank while the museum has
            # it standing — the exact silence Palle asked about. Its size is
            # checked against the record's OWN arithmetic rather than against the
            # crop that produced it, so a wrong crop cannot vouch for itself.
            cells = e.get("cells") or []
            if cells:
                th = len(cells) - int(e.get("vestibule", 4))
                tw = len(str(cells[-1])) - (-int(e.get("cell_x0", -1)))
                if not s2.get("tile"):
                    drift.append("%s: the museum built a %dx%d room and the strip "
                                 "carries no tile — the editors draw it blank"
                                 % (s2["name"], tw, th))
                elif int(s2.get("tile_h", 0)) != th or int(s2.get("tile_w", 0)) != tw:
                    drift.append("%s: tile %dx%d, the museum's own grid is %dx%d"
                                 % (s2["name"], int(s2.get("tile_w", 0)),
                                    int(s2.get("tile_h", 0)), tw, th))
        if drift:
            print("DRIFT: the strip disagrees with what the museum built, in %d hall(s):"
                  % len(drift), file=sys.stderr)
            for d in drift:
                print("  " + d, file=sys.stderr)
            print("  run: python tools/long_museum.py --apply", file=sys.stderr)
            return 1
        if eng:
            print("engine check OK: %d hall(s) measured by the museum, all matching"
                  % sum(1 for s3 in json.load(open(OUT, encoding="utf-8"))["segments"]
                        if s3["kind"] == "hall" and s3["name"] in eng))
        if not os.path.exists(OUT):
            print("MISSING: %s - run `python tools/long_museum.py --apply`" % OUT,
                  file=sys.stderr)
            return 2
        with open(OUT, encoding="utf-8") as fh:
            have = json.load(fh)
        shown, total = diff(doc, have)
        stale = contract_faults(have)
        for f in stale:
            print("CONTRACT (file): %s" % f, file=sys.stderr)
        for line in shown:
            print("DIFF: %s" % line, file=sys.stderr)
        if total > len(shown):
            print("DIFF: ... and %d more" % (total - len(shown)), file=sys.stderr)
        if total or stale:
            print("check FAILED: %d disagreement(s) with the maps, %d contract fault(s)"
                  % (total, len(stale)), file=sys.stderr)
            return 1
        t = have["totals"]
        print("check OK: %s matches the maps on disk - %d halls, %d hallways, %d m, "
              "%d artifacts, %d sequences"
              % (os.path.relpath(OUT, ROOT).replace("\\", "/"), t["halls"], t["vestibules"],
                 t["cells_z"], t["artifacts"], t["sequences"]))
        return 0

    summary(doc)
    # THE DRIFT, NAMED. The strip stands the museum's own deal for every chapter
    # the hand has not authored, so the two agree by construction there. Where
    # they can still part is an AUTHORED chapter: map_authored.json is a hand
    # file and the plan is dealt from the trunk's pearls, so a hall can be
    # authored and never dealt. That hall appears here and in no editor, which
    # is exactly the confusion this alignment was meant to end - so it is
    # printed rather than quietly carried.
    planned_names = set()
    for _seq, _maps in planned_chapters().items():
        planned_names.update(_maps)
    if planned_names:
        orphans = [s2["name"] for s2 in doc["segments"]
                   if s2["kind"] == "hall" and s2["name"] not in planned_names]
        if orphans:
            print("\n  %d hall(s) authored but NOT dealt by the museum - they stand "
                  "in this strip and in no editor: %s"
                  % (len(orphans), ", ".join(orphans)))
    if probs.any():
        print("\n  %d hall(s) missing from disk, %d with layers that disagree, "
              "%d with ragged rows - see the errors above"
              % (len(probs.missing), len(probs.layers), len(probs.rows)))
    if not args.apply:
        print("\n  nothing written. --apply to write %s"
              % os.path.relpath(OUT, ROOT).replace("\\", "/"))
        return 0

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as fh:
        json.dump(doc, fh, ensure_ascii=False, separators=(",", ":"))
        fh.write("\n")
    print("\n  wrote %s (%.1f KB)"
          % (os.path.relpath(OUT, ROOT).replace("\\", "/"), os.path.getsize(OUT) / 1024.0))
    return 0


if __name__ == "__main__":
    sys.exit(main())
