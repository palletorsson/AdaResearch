#!/usr/bin/env python3
"""argument_shape.py — does the room's FORM argue what the room CLAIMS?

2026-09-03. The coherence ledger asks whether a room is broken. This asks the
question Palle actually posed: is this the right space to express the essence of
this concept? Nothing measured that, and it had barely been a live question,
because measured across the 185 live rooms the museum is 135 halls, 39 rooms and
11 corridors — three quarters the same proportion. A census, a sequence, a limit
and an encounter all currently get a box.

The claims, though, are not the same shape at all. They are already written, in
the triage arguments and KEEP lines, and they fall into a small number of kinds
that each want something different of a space:

  CENSUS      a closed list, exhausted        -> a hall you can sweep with your eyes
  SEQUENCE    order matters, step by step     -> a route that cannot be taken out of order
  LIMIT       something cannot be done        -> a dead end you walk into
  COMPARISON  two things, side by side        -> a place you can stand between them
  ENCOUNTER   it responds to you              -> a room with clearance around one body
  FIELD       spread over space, everywhere   -> an open expanse with nothing in the way
  ACCRETION   one rule, repeated, accruing    -> a long run that finishes somewhere else

Classification is deterministic and it reports its evidence, because a
classifier that cannot show its working is not usable for a ruling.

    python tools/argument_shape.py                every live room
    python tools/argument_shape.py --mismatch     only where form fights claim
    python tools/argument_shape.py --map=X --why  one room, with the evidence
"""
from __future__ import annotations

import argparse
import collections
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Each kind: (cues in the claim, what the form should do, what it must not do)
KINDS = {
    "census": {
        "cues": ["exactly", "seventeen", "census", "closed", "exhaust", "all of them",
                 "classification", "every one", "the complete", "finite", "no more than",
                 "there are only", "catalogue", "atlas", "index of"],
        "wants": "a hall you can sweep with your eyes: low aspect, open floor, few interior walls",
    },
    "sequence": {
        "cues": ["order", "then", "first", "before", "after", "step", "in turn", "sequence",
                 "one at a time", "non-commut", "does not commute", "process", "stages"],
        "wants": "a route that cannot be taken out of order: high aspect or real chokepoints",
    },
    "limit": {
        "cues": ["cannot", "never", "no formula", "impossible", "fails", "breaks down",
                 "runs out", "stops", "undecid", "halting", "paradox", "no longer",
                 "gives up", "dies", "there is none"],
        "wants": "a dead end you walk into: a terminating arm, not a loop",
    },
    "comparison": {
        "cues": ["versus", "against", "two ways", "both", "either", "same but", "differ",
                 "side by side", "compared", "unlike", "whereas", "on one side"],
        "wants": "a place you can stand between them: two clusters with a gap you occupy",
    },
    "encounter": {
        "cues": ["you", "your body", "affect", "respond", "contact", "meets", "touch",
                 "reaches", "bite", "push", "hold", "grab", "felt"],
        "wants": "clearance around one body: room to circle the thing that answers",
    },
    "field": {
        "cues": ["field", "everywhere", "spread", "over space", "distributed", "each point",
                 "every point", "continuous", "across the", "no centre"],
        "wants": "an open expanse with nothing in the way",
    },
    "accretion": {
        "cues": ["repeat", "again and again", "accru", "accumulat", "compound", "over time",
                 "grows", "iterat", "each step adds", "one rule"],
        "wants": "a long run that finishes somewhere else",
    },
}


def load(p, default=None):
    try:
        return json.load(open(p, encoding="utf-8"))
    except Exception:
        return default if default is not None else {}


def live_rooms():
    authored = load(os.path.join(ROOT, "commons", "data", "map_authored.json"))
    out = []
    for sid in authored:
        d = load(os.path.join(ROOT, "commons", "maps", "sequences", sid + ".json"))
        if not d:
            continue
        s = d["sequences"].get(sid) if isinstance(d.get("sequences"), dict) else d
        if isinstance(s, dict):
            out += [(sid, m) for m in s.get("maps", [])]
    return out


def classify(claim: str, keep: str) -> tuple[str, int, list[str]]:
    """-> (kind, score, the cues that fired). The KEEP line counts double: it is
    the sentence the room was built to land."""
    text = (claim or "").lower()
    keep_l = (keep or "").lower()
    best, hits = "", []
    scores = {}
    for kind, spec in KINDS.items():
        fired = [c for c in spec["cues"] if c in text]
        fired_keep = [c for c in spec["cues"] if c in keep_l]
        scores[kind] = len(fired) + 2 * len(fired_keep)
        if scores[kind]:
            if scores[kind] > scores.get(best, 0):
                best, hits = kind, sorted(set(fired + fired_keep))
    return best or "unclassified", scores.get(best, 0), hits


def form(map_name: str) -> dict:
    md = load(os.path.join(ROOT, "commons", "maps", map_name, "map_data.json"))
    st = md.get("layers", {}).get("structure", [])
    if not st:
        return {}
    H, W = len(st), len(st[0])
    floor = interior_wall = void = 0
    for r in range(H):
        for c in range(len(st[r])):
            v = str(st[r][c]).strip()
            border = r in (0, H - 1) or c in (0, len(st[r]) - 1)
            if v in ("0", ""):
                void += 1
            elif v == "1":
                floor += 1
            elif not border:
                interior_wall += 1
    cells = sum(len(row) for row in st)
    return {
        "w": W, "h": H,
        "aspect": round(max(W, H) / max(1, min(W, H)), 2),
        "floor_frac": round(floor / max(1, cells), 2),
        "interior_walls": interior_wall,
        "void": void,
    }


def verdict(kind: str, f: dict) -> tuple[bool, str]:
    """Does the form do what the kind wants? Returns (fits, why)."""
    if not f:
        return True, "no structure"
    a, ff, iw = f["aspect"], f["floor_frac"], f["interior_walls"]
    if kind == "census":
        if a > 1.5:
            return False, f"a census wants one sweep; this is {a} long, so the list arrives in installments"
        if iw > 6:
            return False, f"{iw} interior walls break the sweep a census needs"
        return True, f"aspect {a}, {iw} interior walls: sweepable"
    if kind == "sequence":
        if a < 1.6 and iw < 4:
            return False, f"an ordered claim in an open box (aspect {a}, {iw} interior walls): nothing forces the order"
        return True, f"aspect {a}, {iw} interior walls: the order can be imposed"
    if kind == "limit":
        if ff > 0.85 and a < 1.5:
            return False, "a limit wants somewhere you cannot go on; this room is an open box with no end"
        return True, f"floor {ff}, aspect {a}: has an edge to arrive at"
    if kind == "comparison":
        if iw == 0 and a < 1.5:
            return False, "two things to compare and nothing dividing the room: no between to stand in"
        return True, f"{iw} interior walls: there is a between"
    if kind == "encounter":
        if ff < 0.55:
            return False, f"only {int(ff * 100)}% floor: not enough ground to circle the thing that answers"
        return True, f"floor {ff}: room to move around one body"
    if kind == "field":
        if iw > 4 or ff < 0.7:
            return False, f"a field wants an expanse; {iw} interior walls and {int(ff * 100)}% floor cut it up"
        return True, f"floor {ff}, {iw} interior walls: open"
    if kind == "accretion":
        if a < 1.8:
            return False, f"accrual wants a run; aspect {a} gives it nowhere to accumulate towards"
        return True, f"aspect {a}: a run"
    return True, "unclassified"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", default="")
    ap.add_argument("--seq", default="")
    ap.add_argument("--mismatch", action="store_true")
    ap.add_argument("--why", action="store_true")
    args = ap.parse_args()

    tri = {r["map"]: r for r in load(os.path.join(ROOT, "ada_run", "spine_triage.json"),
                                     {"maps": []}).get("maps", [])}
    rooms = live_rooms()
    if args.map:
        rooms = [(s, m) for s, m in rooms if m == args.map]
    if args.seq:
        rooms = [(s, m) for s, m in rooms if s == args.seq]

    kinds = collections.Counter()
    bad = 0
    print(f"{'room':38s} {'kind':12s} {'asp':>4s} {'flr':>4s} {'iw':>3s}  fit")
    for seq, m in sorted(rooms, key=lambda x: x[1]):
        t = tri.get(m, {})
        kind, score, hits = classify(str(t.get("argument", "")), str(t.get("keep", "")))
        f = form(m)
        fits, why = verdict(kind, f)
        kinds[kind] += 1
        if not fits:
            bad += 1
        if args.mismatch and fits:
            continue
        mark = "ok " if fits else "NO "
        print(f"{m[:38]:38s} {kind:12s} {f.get('aspect', 0):4} {f.get('floor_frac', 0):4} "
              f"{f.get('interior_walls', 0):3d}  {mark}{why}")
        if args.why:
            print(f"    claim: {str(t.get('argument', ''))[:150]}")
            print(f"    cues fired: {', '.join(hits) if hits else '(none)'}   wants: {KINDS.get(kind, {}).get('wants', '-')}")

    print(f"\n{len(rooms)} room(s). form fights claim in {bad}.")
    print("kinds: " + ", ".join(f"{k} {n}" for k, n in kinds.most_common()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
