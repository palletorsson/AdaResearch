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

THE STRIP IS NOT THE ENGINE'S OWN SEGMENT MATH, and the difference is worth
knowing before anyone compares numbers. endless_museum.gd advances one cursor,
`_next_z += h + VESTIBULE_H + porch + court` (:5694), so there the vestibule is
the LEADING four rows of a segment — 244 of them, the first being the lobby —
and a dealt chapter also carries courtyards. This strip is the flat reading Palle
asked for: hall, hallway, hall, 244 halls and 243 hallways between them, no
lobby and no courts, every hall's grid exactly as its map holds it. Same halls,
same order, 4,852 m against the engine's 5,559 m for the same 244 rooms
(the engine crops each tile to content and appends 3 passage rows). Do not
average the two: they answer different questions.
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


def read_hall(name, chapter, order, source, probs):
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

    return {"kind": "hall", "name": name, "sequence": chapter, "chapter": order,
            "z0": 0, "z1": 0, "w": w, "h": h, "x0": -(w // 2),
            "source": source, "artifacts": arts, "structure": st}


def build():
    probs = Problems()
    authored = authored_chapters()
    ribbons = ribbon_index()

    halls = []
    for order, seq in spine_order():
        if seq in authored:
            names = authored[seq]
        else:
            names = ribbons.get(seq, [])
            if not names:
                print("ERROR: %s is dealt and has no Ribbon halls on disk - the "
                      "chapter is empty" % seq, file=sys.stderr)
        for n in names:
            # A hall inside an authored chapter can still be a ribbon hall:
            # color, change and forces each end with theirs. The source says
            # which, and the chapter's source below says both.
            src = "ribbon" if n.startswith("Ribbon_") else "authored"
            seg = read_hall(n, seq, order, src, probs)
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
        source = "authored+ribbon" if len(srcs) > 1 else ("ribbon" if "ribbon" in srcs
                                                          else "authored")
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
        chapters.append({"sequence": seq, "order": order,
                         "z0": own[0]["z0"], "z1": hs[-1]["z1"],
                         "halls": len(hs),
                         "artifacts": sum(len(s["artifacts"]) for s in hs),
                         "source": source, "built": built})

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
