#!/usr/bin/env python3
"""coherence.py — one table where concept, book, museum and curation check each other.

2026-09-03, Palle: "What tool do we need to uplift the concept, book, museum,
artifact curation in one interdependent loop that benefits all?"

This one, and the reason it can exist is that all four already key on the same
join: ROOM x ARTIFACT x CLAIM. The concept lives in the triage argument. The book
lives in final.md, whose <!-- @token --> regions name artifacts. The museum lives
in map_data.json, which places those same tokens. The curation lives in the
registry, which declares their axes and measures their size. Four vocabularies,
one join, and nobody was reading them together.

So every column below is a different modality, and a gap in one is a fact about
another:

  CLAIM    the room has an argument                       (concept)
  BODIES   objects that could support it                  (curation)
  SEEN     of those, how many anyone has ever looked at   (curation)
  TEXT     a wall text exists and covers every body       (book)
  SPACE    nothing overruns, is walled in, or floats      (museum)
  VARY     promoted families placed at a non-default      (curation)

A room short in one column is not a "bad room". It is a specific next action,
and the action belongs to a specific tool:

  no CLAIM   -> the triage needs a ruling
  no BODIES  -> shelf.py with the KEEP line
  low SEEN   -> capture_multi_angle.gd, the shoot queue
  no TEXT    -> the reader wave, then write
  SPACE bad  -> map_plan.py, then cell-edit
  VARY zero  -> build_dna_deck.py, then the curator

    python tools/coherence.py                 every live room, worst first
    python tools/coherence.py --seq=fractals  one chapter
    python tools/coherence.py --queue         just the next actions
"""
from __future__ import annotations

import argparse
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load_json(p, default=None):
    try:
        return json.load(open(p, encoding="utf-8"))
    except Exception:
        return default if default is not None else {}


def live_rooms() -> list[tuple[str, str]]:
    authored = load_json(os.path.join(ROOT, "commons", "data", "map_authored.json"))
    out = []
    for sid in authored:
        p = os.path.join(ROOT, "commons", "maps", "sequences", sid + ".json")
        d = load_json(p)
        if not d:
            continue
        s = d["sequences"].get(sid) if isinstance(d.get("sequences"), dict) else d
        if isinstance(s, dict):
            for m in s.get("maps", []):
                out.append((sid, m))
    return out


def audit(seq: str, name: str, shelf: dict, triage: dict) -> dict:
    d = os.path.join(ROOT, "commons", "maps", name)
    md = load_json(os.path.join(d, "map_data.json"))
    layers = md.get("layers", {})
    st = layers.get("structure", [])
    it = layers.get("interactables", [])

    placed, cells = [], {}
    for r, row in enumerate(it):
        for c, v in enumerate(row):
            v = str(v).strip()
            if v and v != "-":
                tok = v.split(":")[0].split("#")[0]
                placed.append(tok)
                cells[(r, c)] = v
    uniq = sorted(set(placed))

    t = triage.get(name, {})
    claim = bool(str(t.get("argument", "")).strip())

    fp = os.path.join(d, "final.md")
    text = ""
    if os.path.exists(fp):
        text = open(fp, encoding="utf-8").read()
    tagged = {m for m in re.findall(r"<!-- @(\S+) -->", text)}
    uncovered = [x for x in uniq if x not in tagged] if text else uniq

    seen = sum(1 for x in uniq if (shelf.get(x) or {}).get("seen"))

    # space faults, the same rules map_plan.py draws
    H = len(st)
    W = len(st[0]) if H else 0
    over = walled = void = unmeas = 0
    for (r, c), raw in cells.items():
        tok = raw.split(":")[0].split("#")[0]
        e = shelf.get(tok) or {}
        a = e.get("aabb")
        if not a or not (a[0] or a[2]):
            unmeas += 1
        elif a[0] > W or a[2] > H:
            over += 1
        under = str(st[r][c]).strip() if r < H and c < len(st[r]) else ""
        if under in ("0", ""):
            void += 1
        elif under != "1" and e.get("wall_backing") is not True:
            walled += 1

    promoted = [x for x in uniq if (shelf.get(x) or {}).get("dna_axes")]
    # VARIED means a DNA AXIS is set, not merely that some config key is present.
    # The first draft of this column counted any '#key:value' and reported 72
    # rooms, which flattered the corpus: most of those keys are modes and sizes,
    # not axes. Counting only declared axes is the honest measure of whether the
    # museum has ever met a variant.
    varied = 0
    for raw in cells.values():
        tok = raw.split(":")[0].split("#")[0]
        axes = set((shelf.get(tok) or {}).get("dna_axes") or [])
        for part in raw.split("#")[1:]:
            if ":" in part and part.split(":", 1)[0] in axes:
                varied += 1
                break

    # ROUTE and ORDER, from tools/museum_walk.py - the ONE implementation of the
    # museum's traversal. The protocol promised these two columns before they
    # existed, which is the same fault the loop warns about in artifacts: a
    # declaration ahead of its runtime. ACT (does the thing DO what it says) is
    # deliberately absent and marked so in the header: behaviour cannot be read
    # from a map, only from a probe, and the survey is static by design.
    walks, ways, unreached = True, 0, 0
    try:
        import museum_walk as mw
        ev = mw.evaluate(md)
        if not ev.get("error"):
            walks = bool(ev["walks"])
            ways = int(ev["ways"])
            step = {cell: i for i, cell in enumerate(ev["route"])}
            for (r, c) in cells:
                if not any((r + dr, c + dc) in step
                           for dr, dc in ((0, 0), (-1, 0), (1, 0), (0, -1), (0, 1))):
                    unreached += 1
    except Exception:
        pass

    return {
        "seq": seq, "map": name, "claim": claim,
        "walks": walks, "ways": ways, "unreachable": unreached,
        "bodies": len(uniq), "seen": seen,
        "text": bool(text), "uncovered": uncovered,
        "over": over, "walled": walled, "void": void, "unmeas": unmeas,
        "promoted": len(promoted), "varied": varied,
    }


# ── ranking ─────────────────────────────────────────────────────────────────
# This sorted by the COUNT of todos, so a hall nobody can walk through tied with
# a hall that merely has no wall text. A review caught it on 2026-09-03 and it
# is the difference between a queue and a list.
#
# Rank instead by CONSEQUENCE x UNCERTAINTY x TEST VALUE, the three questions
# that actually decide what to look at next:
#
#   consequence  how bad is this if it is real
#   uncertainty  how unsure are we that it is real. A fault we have MEASURED is
#                certain, and certainty lowers the value of looking again - it
#                is work, not a question. A fault we have INFERRED from a map
#                while the museum builds through its own copy of the rules is
#                uncertain, and that is where a cheap test pays.
#   test value   how much would the next cheap test resolve
#
# The weights are stated rather than tuned, so a disagreement about priority is
# a disagreement about a number in this table and not about taste.

#: (consequence, uncertainty, test value) per fault, each 0-10.
FAULT_WEIGHTS = {
    # nobody can get through the hall. The worst thing a room can be, and the
    # uncertainty is real: this is measured on the MAP, and the museum widens
    # doors and carves passages through its own copy of the rules.
    "no_walk":      (10, 6, 9),
    # a body nobody can reach is not in the exhibition
    "unreachable":  (8, 4, 8),
    # an unmeasured body is an UNBOUNDED one: it silently invalidates every
    # other spatial number for the room, so its test value is the highest here
    "unmeasured":   (7, 9, 10),
    # standing over a hole
    "over_void":    (6, 3, 6),
    # bigger than the room it stands in
    "over":         (5, 2, 5),
    # inside a wall it declares it does not want
    "walled":       (4, 3, 5),
    # the room says nothing. Serious, but there is no question here to resolve:
    # the test value is zero because we already know, and it is work not doubt.
    "no_text":      (3, 0, 0),
    # text that does not name a body the room places
    "uncovered":    (2, 1, 2),
    # a promoted family met at its shipped default
    "no_variant":   (1, 1, 1),
    # no argument at all. Zero rooms are in this state, kept for completeness.
    "no_claim":     (9, 0, 1),
}


def faults(a: dict) -> dict:
    """-> {fault: how many}. One place, so the score and the todo agree."""
    f = {}
    if not a["claim"]:
        f["no_claim"] = 1
    if not a.get("walks", True):
        f["no_walk"] = 1
    if a.get("unreachable"):
        f["unreachable"] = a["unreachable"]
    if a["unmeas"]:
        f["unmeasured"] = a["unmeas"]
    if a["void"]:
        f["over_void"] = a["void"]
    if a["over"]:
        f["over"] = a["over"]
    if a["walled"]:
        f["walled"] = a["walled"]
    if not a["text"]:
        f["no_text"] = 1
    elif a["uncovered"]:
        f["uncovered"] = len(a["uncovered"])
    if a["promoted"] and not a["varied"]:
        f["no_variant"] = 1
    return f


def score(a: dict) -> float:
    """consequence x uncertainty x test value, summed over the room's faults.

    A count is damped by a square root: two unmeasured bodies are worse than
    one and nothing like twice as bad, because the first measurement pass fixes
    both. Uncertainty is offset by 1 so a certain fault still scores its
    consequence rather than vanishing - a hall with no text is real work even
    though nothing about it is in doubt.
    """
    import math
    total = 0.0
    for k, n in faults(a).items():
        c, u, t = FAULT_WEIGHTS.get(k, (1, 1, 1))
        total += c * (1 + u) * (1 + t) * math.sqrt(n)
    return round(total, 1)


def actions(a: dict) -> list[str]:
    out = []
    if not a.get("walks", True):
        out.append("route: the hall does not walk row 0 to row H-1 "
                   "(museum_walk.py, then stamp.py)")
    if a.get("unreachable"):
        out.append("order: %d placement(s) never passed on the museum walk "
                   "(walk_evaluator.py --as-placed)" % a["unreachable"])
    if not a["claim"]:
        out.append("triage: the room has no argument")
    if a["bodies"] == 0:
        out.append("shelf.py: the room is empty")
    elif a["bodies"] and a["seen"] < a["bodies"] / 2:
        out.append(f"shoot: {a['bodies'] - a['seen']}/{a['bodies']} bodies never looked at")
    if not a["text"]:
        out.append("write: no final.md")
    elif a["uncovered"]:
        out.append(f"write: {len(a['uncovered'])} placed bod(y/ies) unwritten "
                   f"({', '.join(a['uncovered'][:3])})")
    if a["over"]:
        out.append(f"map_plan: {a['over']} body/ies bigger than the room")
    if a["walled"]:
        out.append(f"cell-edit: {a['walled']} body/ies embedded in a wall they do not want")
    if a["void"]:
        out.append(f"cell-edit: {a['void']} body/ies over a hole")
    if a["unmeas"]:
        out.append(f"measure: {a['unmeas']} body/ies have no aabb")
    if a["promoted"] and not a["varied"]:
        out.append(f"curator: {a['promoted']} promoted famil(y/ies), all at default")
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--seq", default="")
    ap.add_argument("--queue", action="store_true", help="print only the next actions")
    ap.add_argument("--limit", type=int, default=40)
    args = ap.parse_args()

    shelf = load_json(os.path.join(ROOT, "doc", "shelf.json"))
    tri = {r["map"]: r for r in load_json(os.path.join(ROOT, "ada_run", "spine_triage.json"),
                                          {"maps": []}).get("maps", [])}
    rooms = [(s, m) for s, m in live_rooms() if not args.seq or s == args.seq]
    rows = [audit(s, m, shelf, tri) for s, m in rooms]
    for r in rows:
        r["todo"] = actions(r)
    for r in rows:
        r["score"] = score(r)
    rows.sort(key=lambda r: (-r["score"], r["map"]))

    if args.queue:
        for r in rows[:args.limit]:
            if not r["todo"]:
                continue
            print(f"\n{r['map']}  ({r['seq']})")
            for t in r["todo"]:
                print(f"   - {t}")
    else:
        print("columns: CLAIM BODY SEEN TEXT SPACE ROUTE ORDER. "
              "ACT (behaviour) is NOT here - it needs a probe, not a map.")
        print(f"{'room':36s} {'risk':>6s} {'clm':3s} {'body':>4s} {'seen':>4s} {'txt':3s} "
              f"{'unwr':>4s} {'over':>4s} {'wall':>4s} {'void':>4s} {'nom':>4s} {'vary':>4s} "
              f"{'walk':4s} {'wys':>3s} {'unrc':>4s}  next")
        for r in rows[:args.limit]:
            print(f"{r['map'][:36]:36s} {r['score']:6.1f} {'y' if r['claim'] else '.':3s} "
                  f"{r['bodies']:4d} {r['seen']:4d} {'y' if r['text'] else '.':3s} "
                  f"{len(r['uncovered']):4d} {r['over']:4d} {r['walled']:4d} {r['void']:4d} "
                  f"{r['unmeas']:4d} {r['varied']:4d} "
                  f"{'y' if r['walks'] else 'NO':4s} {r['ways']:3d} {r['unreachable']:4d}"
                  f"  {r['todo'][0] if r['todo'] else 'clear'}")

    n = len(rows)
    clear = sum(1 for r in rows if not r["todo"])
    print(f"\n{n} live room(s): {clear} clear, {n - clear} with work.")
    for k, label in (("claim", "no argument"), ("text", "no wall text")):
        miss = sum(1 for r in rows if not r[k])
        print(f"   {miss:4d} with {label}")
    for k, label in (("over", "a body bigger than the room"),
                     ("walled", "a body embedded in a wall"),
                     ("void", "a body over a hole"),
                     ("unmeas", "an unmeasured body")):
        miss = sum(1 for r in rows if r[k])
        print(f"   {miss:4d} with {label}")
    varied = sum(1 for r in rows if r["varied"])
    print(f"   {varied:4d} place any artifact at a non-default value")
    return 0


if __name__ == "__main__":
    sys.exit(main())
