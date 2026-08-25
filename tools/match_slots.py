#!/usr/bin/env python3
"""THE MATCHER — what fits here, and where can this go.

2026-08-25, Palle: "build the matcher."

Both halves finally speak the same units, which is the only reason this is a
small tool rather than a research project:

  commons/data/artifact_shapes.json  2355 artifacts as a grid RECTANGLE, area
                                     from spatial_needs.footprint_cells and
                                     proportion from the AABB
  commons/data/museum_50.json        50 rooms, 457 slots in TWO currencies —
                                     squares (hero, plinth, pair, field) and
                                     runs along a wall

    python tools/match_slots.py                      # coverage, both directions
    python tools/match_slots.py --slot=m18#3         # what fits in this slot
    python tools/match_slots.py --artifact=pendulum_hall
    python tools/match_slots.py --fill=m18           # a PROPOSAL for one room

THE FIT RULE is deliberately plain, because a clever one would be unarguable:

  square slot of N   takes a piece whose w and d are both <= N
  run of L by D      takes a piece whose LONG side <= L and SHORT side <= D
  wall_backing       a piece that declares it can only go on a run or an
                     alcove — it has a back it does not want seen

Ranked by WASTE, least first, so a 1x1 never claims the 5x5 hero while a 3x3
that needs it goes homeless. Waste is the honest number here: a piece in a
slot four times its size is technically a fit and visibly wrong.

--fill PROPOSES AND NOTHING ELSE. It writes no map and touches no registry.
Placing is a design act; this only says what the room could take if nobody
made a decision, which is exactly the thing a person should overrule.
"""
from __future__ import annotations

import argparse
import glob
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load():
    with open(os.path.join(ROOT, "commons", "data", "artifact_shapes.json"), encoding="utf-8") as fh:
        shapes = json.load(fh)["shapes"]
    with open(os.path.join(ROOT, "commons", "data", "museum_50.json"), encoding="utf-8") as fh:
        museums = json.load(fh)["museums"]
    return shapes, museums


def registry_seq():
    """token -> the sequences the registry says it belongs to."""
    out = {}
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
            if not isinstance(e, dict):
                continue
            # richer wins — see tools/artifact_shapes.py for the flat-file bug
            if tok not in out or (e.get("map_sequences") and not out[tok]):
                out[tok] = e.get("map_sequences") or []
    return out


def slot_area(slot):
    if slot["kind"] == "run":
        return slot.get("len", 1) * max(1, slot.get("depth", 1))
    return slot["fp"] * slot["fp"]


def fits(sh, slot):
    if sh.get("wall_backing") and slot["kind"] not in ("run", "alcove", "wall"):
        return False
    if slot["kind"] == "run":
        return sh["long"] <= slot.get("len", 1) and sh["short"] <= max(1, slot.get("depth", 1))
    n = slot["fp"]
    return sh["w"] <= n and sh["d"] <= n


def waste(sh, slot):
    return slot_area(slot) - sh["w"] * sh["d"]


def slot_id(m, i):
    return "%s#%d" % (m["id"], i)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--slot", default="", help="m18#3 — what fits here")
    ap.add_argument("--artifact", default="", help="a token — where could it go")
    ap.add_argument("--fill", default="", help="a museum id — propose a population")
    ap.add_argument("--sequence", default="", help="restrict --fill to one sequence")
    ap.add_argument("--limit", type=int, default=12)
    args = ap.parse_args()
    shapes, museums = load()
    by_id = {m["id"]: m for m in museums}

    if args.slot:
        mid, _, idx = args.slot.partition("#")
        m = by_id.get(mid)
        if not m or not idx.isdigit() or int(idx) >= len(m["slots"]):
            print("no such slot: %s" % args.slot)
            return 1
        slot = m["slots"][int(idx)]
        cands = [(waste(s, slot), t, s) for t, s in shapes.items() if fits(s, slot)]
        cands.sort(key=lambda r: (r[0], r[1]))
        desc = ("run %d long x %d deep" % (slot.get("len", 0), slot.get("depth", 1))
                if slot["kind"] == "run" else "%dx%d %s" % (slot["fp"], slot["fp"], slot["kind"]))
        print("%s in %s — %s at (%d, %d)\n" % (args.slot, m["pattern"], desc, slot["x"], slot["z"]))
        print("  %d artifact(s) fit. tightest first:" % len(cands))
        for w, t, s in cands[:args.limit]:
            print("     %-40s %dx%-2d  waste %d" % (t[:40], s["w"], s["d"], w))
        return 0

    if args.artifact:
        sh = shapes.get(args.artifact)
        if not sh:
            print("%s has no grid shape — it declares no spatial_needs.footprint_cells"
                  % args.artifact)
            return 1
        homes = []
        for m in museums:
            for i, slot in enumerate(m["slots"]):
                if fits(sh, slot):
                    homes.append((waste(sh, slot), slot_id(m, i), m["pattern"], slot))
        homes.sort(key=lambda r: (r[0], r[1]))
        print("%s is %dx%d%s\n" % (args.artifact, sh["w"], sh["d"],
                                   " and wants a wall behind it" if sh.get("wall_backing") else ""))
        print("  %d slot(s) across the fifty could take it. tightest first:" % len(homes))
        for w, sid, pat, slot in homes[:args.limit]:
            kind = ("run %d" % slot.get("len", 0)) if slot["kind"] == "run" else \
                   "%dx%d %s" % (slot["fp"], slot["fp"], slot["kind"])
            print("     %-10s %-34s %-14s waste %d" % (sid, pat[:34], kind, w))
        return 0

    if args.fill:
        m = by_id.get(args.fill)
        if not m:
            print("no such museum: %s" % args.fill)
            return 1
        seqs = registry_seq() if args.sequence else {}
        pool = {t: s for t, s in shapes.items()
                if not args.sequence or args.sequence in (seqs.get(t) or [])}
        print("A PROPOSAL for %s (%s, %s) — nothing is written\n"
              % (m["id"], m["pattern"], m["variant"]))
        if args.sequence:
            print("  restricted to sequence %s: %d artifact(s) in the pool\n"
                  % (args.sequence, len(pool)))
        used = set()
        # biggest slot first, so the hero is chosen before the shelves take
        # everything that could have filled it
        order = sorted(range(len(m["slots"])), key=lambda i: -slot_area(m["slots"][i]))
        for i in order:
            slot = m["slots"][i]
            cands = [(waste(s, slot), t) for t, s in pool.items()
                     if t not in used and fits(s, slot)]
            cands.sort()
            kind = ("run %d long" % slot.get("len", 0)) if slot["kind"] == "run" else \
                   "%dx%d %s" % (slot["fp"], slot["fp"], slot["kind"])
            if not cands:
                print("     %-16s (%2d,%2d)  -- nothing in the pool fits" % (kind, slot["x"], slot["z"]))
                continue
            w, t = cands[0]
            used.add(t)
            print("     %-16s (%2d,%2d)  %-38s waste %d  (%d other candidate(s))"
                  % (kind, slot["x"], slot["z"], t[:38], w, len(cands) - 1))
        return 0

    # coverage, both directions
    homed = {t: 0 for t in shapes}
    for m in museums:
        for slot in m["slots"]:
            for t, s in shapes.items():
                if fits(s, slot):
                    homed[t] += 1
    filled = 0
    empty = []
    for m in museums:
        for i, slot in enumerate(m["slots"]):
            n = sum(1 for s in shapes.values() if fits(s, slot))
            if n:
                filled += 1
            else:
                empty.append((slot_id(m, i), m["pattern"], slot))
    total_slots = sum(len(m["slots"]) for m in museums)
    homeless = sorted(t for t, n in homed.items() if n == 0)
    print("THE MATCHER — %d artifacts against %d slots in %d rooms\n"
          % (len(shapes), total_slots, len(museums)))
    print("  artifacts with at least one home:  %d of %d (%.0f%%)"
          % (len(shapes) - len(homeless), len(shapes),
             100.0 * (len(shapes) - len(homeless)) / len(shapes)))
    print("  slots with at least one candidate: %d of %d (%.0f%%)"
          % (filled, total_slots, 100.0 * filled / total_slots))
    wide = sorted(((n, t) for t, n in homed.items() if n), reverse=True)[:3]
    tight = sorted((n, t) for t, n in homed.items() if n)[:6]
    print("\n  the most placeable: %s" % ", ".join("%s (%d)" % (t, n) for n, t in wide))
    print("  the tightest fits:")
    for n, t in tight:
        s = shapes[t]
        print("     %-40s %dx%-2d  only %d slot(s)" % (t[:40], s["w"], s["d"], n))
    if homeless:
        print("\n  %d artifact(s) fit NOWHERE in the fifty:" % len(homeless))
        for t in homeless[:10]:
            s = shapes[t]
            print("     %-40s %dx%-2d%s" % (t[:40], s["w"], s["d"],
                  "  wants a wall" if s.get("wall_backing") else ""))
        if len(homeless) > 10:
            print("     ... and %d more" % (len(homeless) - 10))
    if empty:
        print("\n  %d slot(s) nothing fits:" % len(empty))
        for sid, pat, slot in empty[:6]:
            print("     %-10s %-34s %s" % (sid, pat[:34], slot["kind"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
