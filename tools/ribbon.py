#!/usr/bin/env python3
"""THE RIBBON — halls cut to fit the exhibition, not the other way round.

2026-08-25, Palle: "we lay out the museum without the artifact first and just
prepare an empty initial spot for the artifact... When we have the museum for a
sequence we lay out the artifact where they fit. If one map of artifact fill
does not fill up the full hall we can add an extra wall and continue with the
new map."

Everything before this fixed the rooms and let the artifacts be the remainder,
which is why softbodies got 16 rooms for 34 maps and change got one room and
stopped. Here the WALL is the remainder: you walk the ribbon placing artifacts
with air between them, and where the hall fills — or the artifacts run out —
that is where the wall goes.

    python tools/ribbon.py --sequence=color
    python tools/ribbon.py --sequence=color --apply

THE SPACING IS MEASURED, NOT CHOSEN. From the seven hand-authored color maps:

    nearest neighbour   mean 2.83 cells, median 3, distribution 1:16 2:21
                        3:26 4:15 5:7 6:1
    density             one artifact per 21.3 floor cells

So the gap is 3 and a hall wants floor/21 things. The tail at 1 cell is not
noise: Color_Nails sits at 1.18 mean while Color_Walls sits at 3.38, because
Nails holds variants of one idea. Kin pack tight; strangers get three cells.

HEAVY MEANS EXPENSIVE, NOT BIG (Palle: "what I meant with heavy was if they
consume a lot of cpu gpu"). Packing is by FOOTPRINT alone. Cost is a separate
budget that only stops a hall holding several expensive things at once, and it
is a PROXY — complexity, category and size_group — not a measurement. It is
labelled as a guess wherever it is printed.
"""
from __future__ import annotations

import argparse
import glob
import json
import math
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import museum_50 as M50          # noqa: E402
import match_slots as MS         # noqa: E402
import stamp_ready as SR         # noqa: E402

GAP = 3          # measured median nearest-neighbour in the color maps
KIN_GAP = 1      # measured floor — Color_Nails runs at 1.18
PER_ARTIFACT = 21.3   # measured floor cells per artifact
# ONLY THE EXCESS COUNTS. Every artifact costs at least 1, so charging the
# full figure made the budget bite on cheap things too and cut every hall at
# two or three — 33 halls for 74 artifacts, when color's own maps average ten.
# A cost of 1 is free; the budget is how much EXPENSIVE an eye can take at once.
COST_FREE = 1.0
COST_BUDGET = 3.0

EXPENSIVE_CATS = {"physics", "physics_simulation", "shaders", "isosurfaces",
                  "swarmintelligence", "softbodies", "procedural"}


def registry():
    reg = {}
    for p in glob.glob(os.path.join(ROOT, "commons", "artifacts", "registry", "*.json")):
        try:
            with open(p, encoding="utf-8") as fh:
                doc = json.load(fh)
        except Exception:
            continue
        arts = doc.get("artifacts") if isinstance(doc.get("artifacts"), dict) else doc
        if not isinstance(arts, dict):
            continue
        for tok, e in arts.items():
            if isinstance(e, dict) and (tok not in reg or len(e) > len(reg[tok])):
                reg[tok] = e
    return reg


def cost_of(entry):
    """A GUESS at render cost, and labelled as one everywhere it is printed.
    No measurement of frame time exists in this repo, so this reads the three
    fields that correlate with it and stops there."""
    c = 1.0
    if entry.get("complexity") in ("advanced", "expert"):
        c += 1.0
    if str(entry.get("category", "")).lower() in EXPENSIVE_CATS:
        c += 1.0
    sg = entry.get("size_group") or (entry.get("parameters") or {}).get("size_group")
    if sg in ("world_scale", "environment", "xlarge"):
        c += 1.0
    return c


def family_of(tok, entry):
    """What this artifact is a variant OF. Kin may stand a cell apart; strangers
    get the measured three."""
    dna = entry.get("dna") if isinstance(entry.get("dna"), dict) else {}
    if dna.get("kin"):
        return "kin:%s" % str(dna["kin"])
    if entry.get("delegate_to"):
        return "del:%s" % entry["delegate_to"]
    if dna.get("axes"):
        return "dna:%s" % tok
    # a shared prefix is the corpus's oldest family marker
    head = tok.split("_")[0].lower()
    return "pre:%s" % head if len(head) >= 4 else "solo:%s" % tok


def sequence_artifacts(seq, reg, shapes):
    """The sequence's artifacts in CURRICULUM order — the order its own maps
    place them, then the rest of the pool. The walk should meet them the way
    the sequence teaches them."""
    p = os.path.join(ROOT, "commons", "maps", "sequences", "%s.json" % seq)
    with open(p, encoding="utf-8") as fh:
        doc = json.load(fh)
    blk = doc["sequences"]
    blk = blk[0] if isinstance(blk, list) else (blk.get(seq) or list(blk.values())[0])
    order, seen = [], set()
    for m in blk.get("maps", []):
        mp = os.path.join(ROOT, "commons", "maps", str(m), "map_data.json")
        if not os.path.exists(mp):
            continue
        with open(mp, encoding="utf-8") as fh:
            md = json.load(fh)
        for row in md["layers"].get("interactables", []):
            for v in row:
                t = str(v).strip().split("#")[0].split(":")[0]
                if t and t not in seen and t in shapes:
                    seen.add(t)
                    order.append(t)
    seq_of = MS.registry_seq()
    for t in sorted(shapes):
        if t not in seen and seq in (seq_of.get(t) or []):
            seen.add(t)
            order.append(t)
    return order


def sequence_shape(seq, n_artifacts):
    """(map, quota) per hall, from the sequence's OWN maps — how many halls it
    is and roughly how full each one runs, scaled to the artifacts on hand."""
    p = os.path.join(ROOT, "commons", "maps", "sequences", "%s.json" % seq)
    if not os.path.exists(p):
        return []
    with open(p, encoding="utf-8") as fh:
        doc = json.load(fh)
    blk = doc["sequences"]
    blk = blk[0] if isinstance(blk, list) else (blk.get(seq) or list(blk.values())[0])
    rows = []
    for m in blk.get("maps", []):
        mp = os.path.join(ROOT, "commons", "maps", str(m), "map_data.json")
        if not os.path.exists(mp):
            continue
        with open(mp, encoding="utf-8") as fh:
            md = json.load(fh)
        n = sum(1 for r in md["layers"].get("interactables", []) for c in r if str(c).strip())
        if n:
            rows.append([str(m), n])
    if not rows:
        return []
    total = sum(n for _m, n in rows)
    # scale the profile to what is actually on hand: color's maps hold 86
    # PLACEMENTS but only 74 distinct artifacts, and the ribbon places each once
    scaled, run = [], 0
    for i, (m, n) in enumerate(rows):
        q = max(1, int(round(n * n_artifacts / total)))
        if i == len(rows) - 1:
            q = max(1, n_artifacts - run)
        run += q
        scaled.append([m, q])
    return scaled


def ribbon_plans():
    """The shapes a hall may take, odd and in band. Diverse, WITH repetition —
    a rhythm, not nineteen different buildings."""
    pats = json.load(open(os.path.join(ROOT, "commons", "data", "template_patterns.json"),
                          encoding="utf-8"))["patterns"]
    out = []
    for k, v in pats.items():
        if v.get("mode") != "stamp" or k.startswith(("lattice:", "beat:")):
            continue
        w = v.get("w", 0)
        if not (9 <= w <= 19 and w % 2 == 1):
            continue
        out.append((k, v))
    out.sort(key=lambda t: -(t[1]["w"] * len(t[1]["tile"])))
    return out


def cut_window(tile, want_h):
    h = len(tile)
    want_h = max(9, min(19, want_h if want_h % 2 == 1 else want_h + 1))
    if want_h >= h:
        want_h = h if h % 2 == 1 else h - 1
        want_h = max(9, min(19, want_h))
    best, bz = None, 0
    for z0 in range(0, max(1, h - want_h + 1)):
        win = [r[:] for r in tile[z0:z0 + want_h]]
        fl = sum(1 for r in win for c in r if str(c).strip() in ("1", "1s"))
        if best is None or fl > best[0]:
            best, bz = (fl, win), z0
    return best[1], bz


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sequence", default="color")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--free", action="store_true",
                    help="ignore the sequence's own shape and let the walls fall where they may")
    args = ap.parse_args()

    reg = registry()
    with open(os.path.join(ROOT, "commons", "data", "artifact_shapes.json"), encoding="utf-8") as fh:
        shapes = json.load(fh)["shapes"]
    order = sequence_artifacts(args.sequence, reg, shapes)
    plans = ribbon_plans()

    print("THE RIBBON — %s\n" % args.sequence)
    print("  %d artifact(s) to place, in curriculum order" % len(order))
    print("  gap %d cells between strangers, %d between kin (measured from the "
          "hand-authored maps)" % (GAP, KIN_GAP))
    print("  a hall wants one artifact per %.1f floor cells; cost budget %.0f per hall\n"
          % (PER_ARTIFACT, COST_BUDGET))

    # THE SEQUENCE'S OWN SHAPE IS THE TARGET (2026-08-25, Palle: "the Color and
    # Composition spine sequence should only be like 6 map... here you can see
    # their approximate artifact layout that should be fitted in the maps").
    #
    # Left to itself the ribbon made FIFTEEN halls for color's 74 artifacts,
    # averaging five each, when color's own seven maps average twelve. The
    # sequence already knows how many halls it is and roughly how full each one
    # runs — Array 12, Pattern_Foundry 12, Color_Context_Placed 22, Nails 9,
    # Pillar 8, Walls 10, Symmetry 13 — so that profile is the target and the
    # ribbon fits into it rather than inventing its own length.
    shape = [] if args.free else sequence_shape(args.sequence, len(order))
    if shape:
        print("  fitting the sequence's OWN shape: %d hall(s) of %s\n"
              % (len(shape), ", ".join(str(n) for _m, n in shape)))

    halls, pending = [], list(order)
    plan_i = 0
    # A HALL THAT PLACES NOTHING CONSUMES NOTHING. Without this the loop can
    # spin forever: `continue` on an empty hall leaves both `pending` and
    # `halls` unchanged, and the bound is on halls. Caught by a run that never
    # returned rather than by reading the code.
    tries = 0
    # A RHYTHM, NOT A CATALOGUE: ABACA — two shapes alternate with a third
    # returning, so the walk repeats without being uniform.
    rhythm = [0, 1, 0, 2, 0, 3, 1, 0, 4, 1]
    # The shape is the TARGET, not a cap. Palle's own rule for the remainder:
    # "if one map of artifact fill does not fill up the full hall we can add an
    # extra wall and continue with the new map." So the sequence's profile sets
    # the first halls, and anything left over gets its own — nothing is dropped
    # to make the count come out.
    cap = (len(shape) + 6) if shape else 40
    while pending and len(halls) < cap and tries < 200:
        tries += 1
        key, pat = plans[rhythm[plan_i % len(rhythm)] % len(plans)]
        plan_i += 1
        # how tall a hall do the remaining artifacts want?
        # size the hall for a READABLE number of things, not for all that are
        # left — a hall holding forty is a warehouse. Ten is what color does.
        quota = (shape[len(halls)][1] if len(halls) < len(shape)
                 else min(len(pending), 11)) if shape else min(len(pending), 11)
        quota = min(quota, len(pending))
        want_cells = quota * PER_ARTIFACT
        want_h = int(round(want_cells / max(4, pat["w"] - 2))) + 4
        tile, z0 = cut_window(pat["tile"], want_h)
        slots_all, grid = M50.slots_for(tile)
        runs = M50.runs_for(grid)
        # EVERY measured position, not a thinned variant list. Thinning is
        # what a room-first tool does — it publishes a curated set of slots and
        # fills them. Here the AIR does the thinning: a candidate is rejected
        # because something is already within three cells of it, not because a
        # variant declined to publish that spot. Drawing from thinned slots
        # capped color at 38 of 74 with halls that could not reach their quota.
        # RUNS FIRST. Dedupe keeps whichever offer reaches a cell first, and a
        # square can never take an oblong: row_3_x is 6x1 and the biggest square
        # in the hall was 4, so putting squares first dropped every run and the
        # ribbon placed NOTHING. A run is the scarcer, more specific offer, so
        # it wins the cell. (Third time today the oblong currency has bitten.)
        pub = list(runs) + list(slots_all)
        seen_xy, slots = set(), []
        for s in pub:
            k2 = (s["x"], s["z"])
            if k2 not in seen_xy:
                seen_xy.add(k2)
                slots.append(s)
        slots.sort(key=lambda s: (s["z"], s["x"]))

        # the hall's own appetite, from the measured density
        floor_n = sum(1 for r in tile for c2 in r if str(c2).strip() in ("1", "1s"))
        target = quota if shape else max(3, int(round(floor_n / PER_ARTIFACT)))
        placed, cost, last_fam = [], 0.0, None
        for s in list(slots):
            if not pending:
                break
            tok = pending[0]
            sh = shapes.get(tok)
            if not sh or not MS.fits(sh, s):
                continue
            fam = family_of(tok, reg.get(tok, {}))
            need = KIN_GAP if fam == last_fam else GAP
            if any(math.hypot(s["x"] - p["x"], s["z"] - p["z"]) < need for p in placed):
                continue
            c = max(0.0, cost_of(reg.get(tok, {})) - COST_FREE)
            # the sequence's quota outranks the load budget: a hall that is
            # meant to hold twelve does not stop at four because three of them
            # were expensive. The budget still spaces them, it no longer walls.
            if placed and cost + c > COST_BUDGET and not shape:
                break                      # THE WALL GOES HERE — too much load
            if placed and len(placed) >= target:
                break                      # THE WALL GOES HERE — the hall is full
            placed.append({"x": s["x"], "z": s["z"], "token": tok, "kind": s["kind"],
                           "fam": fam, "cost": c})
            cost += c
            last_fam = fam
            pending.pop(0)
        if not placed:
            continue
        halls.append({"plan": key, "z0": z0, "tile": tile, "placed": placed,
                      "cost": cost, "slots": len(slots)})

    print("  %-3s %-32s %-7s %4s %6s  %s" % ("#", "plan window", "size", "n", "cost", "first three"))
    for i, h in enumerate(halls):
        print("  %-3d %-32s %2dx%-3d  %4d %6.1f  %s"
              % (i + 1, ("%s z%d" % (h["plan"], h["z0"]))[:32], len(h["tile"][0]), len(h["tile"]),
                 len(h["placed"]), h["cost"],
                 ", ".join(p["token"] for p in h["placed"][:3])[:46]))
    print("\n  %d hall(s) · %d placed · %d left over" % (
        len(halls), sum(len(h["placed"]) for h in halls), len(pending)))
    if pending:
        print("  left over: %s" % ", ".join(pending[:8]))
    kin_pairs = sum(1 for h in halls for a, b in zip(h["placed"], h["placed"][1:])
                    if a["fam"] == b["fam"])
    print("  %d adjacent pair(s) are kin and were allowed to sit %d cell(s) apart"
          % (kin_pairs, KIN_GAP))
    if not args.apply:
        print("\n  nothing written — pass --apply")
        return 0

    wrote = []
    for i, h in enumerate(halls):
        name = "Ribbon_%s_%02d" % (args.sequence[:14].title(), i + 1)
        st = [["0" if str(v).strip() in ("", "0") else
               ("w" if str(v).strip().startswith("4") else str(v).strip())
               for v in row] for row in h["tile"]]
        w, hh = len(st[0]), len(st)
        ut = [["" for _ in range(w)] for _ in range(hh)]
        it = [["" for _ in range(w)] for _ in range(hh)]
        for p in h["placed"]:
            it[p["z"]][p["x"]] = p["token"]
        taken = {(p["x"], p["z"]) for p in h["placed"]}
        sp = tp = None
        for z in range(1, hh - 1):
            for x in range(1, w - 1):
                if st[z][x] == "1" and (x, z) not in taken:
                    sp = (x, z); break
            if sp: break
        for z in range(hh - 2, 0, -1):
            for x in range(w - 2, 0, -1):
                if st[z][x] == "1" and (x, z) not in taken and (x, z) != sp:
                    tp = (x, z); break
            if tp: break
        if sp: ut[sp[1]][sp[0]] = "sp"
        if tp:
            st[tp[1]][tp[0]] = "0"
            ut[tp[1]][tp[0]] = "t"
        doc = {"map_info": {"name": name, "lookup_name": name,
                            "title": "%s %d — %s" % (args.sequence, i + 1, h["plan"].split("-")[0]),
                            "format": "json", "version": "1.0",
                            "dimensions": {"width": w, "depth": hh, "max_height": 5},
                            "museum": {"gate": False},
                            "metadata": {"source": "tools/ribbon.py", "sequence": args.sequence,
                                         "plan": h["plan"], "n_artifacts": len(h["placed"]),
                                         "cost_guess": round(h["cost"], 1),
                                         "gap": GAP, "kin_gap": KIN_GAP}},
               "layers": {"structure": st, "utilities": ut, "interactables": it}}
        d = os.path.join(ROOT, "commons", "maps", name)
        os.makedirs(d, exist_ok=True)
        fp = os.path.join(d, "map_data.json")
        with open(fp, "w", encoding="utf-8") as fh:
            json.dump(doc, fh)
        fresh = json.load(open(fp, encoding="utf-8"))
        s2 = fresh["layers"]["structure"]
        keep = {(x, z) for x, z in SR.analyse(fresh)["blocked"]}
        saved = {(x, z): s2[z][x] for (x, z) in keep}
        SR.wall_border(s2)
        for (x, z), v in saved.items():
            s2[z][x] = v
        with open(fp, "w", encoding="utf-8") as fh:
            json.dump(fresh, fh)
        subprocess.run([sys.executable, os.path.join(ROOT, "tools", "compact_map_json.py"), fp],
                       cwd=ROOT, capture_output=True)
        wrote.append(name)
    print("\n  wrote %d map(s):" % len(wrote))
    for n in wrote:
        print("     %-28s %s" % (n, "pathfinder OK" if SR.check_map(n) else "PATHFINDER FAILED"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
