#!/usr/bin/env python3
"""BAKE THE HAND'S RULINGS INTO THE PLAN — the museum's "save into the map".

Palle, 2026-08-18: "Why can we use the desktop as an editor and save the
changes directly into the map json?"

Until now a ruling lived in ada_run/em_overrides.json and was applied on top
of ada_run/em_plan.json at every build. That layer is honest — it keeps the
negotiator's plan and the hand's word apart, and it survives a regeneration
— but it binds by (chapter, token, from-cell), and the plan MOVES rows, so a
ruling written last week can quietly stop matching. Palle's twelve rulings
were all keyed to cells the plan no longer places.

Baking writes the ruling INTO the plan row: cell, rotation, token (a swap),
removal, and the fine offset/scale as row fields. The row is stamped
`hand: true` with the ruling that made it, so the plan says who placed it.
A baked ruling is moved to ada_run/em_rulings_baked.json — the memory of
what was ruled and when, which a regeneration can replay.

    python tools/bake_rulings.py                # report what would bake
    python tools/bake_rulings.py --apply        # write the plan
    python tools/bake_rulings.py --apply --keep # bake but leave em_overrides.json alone

AFTER A REGENERATION (spine_run --write-plan) the plan is the negotiator's
again and the baked rows are gone; replay them with --replay, which reads
em_rulings_baked.json and bakes it back in. That is the whole trade: the
override layer survives regeneration automatically but can go idle; a bake
is immediate and exact but must be replayed. Both are recorded, neither
guesses.
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PLAN = REPO / "ada_run" / "em_plan.json"
OVERRIDES = REPO / "ada_run" / "em_overrides.json"
BAKED = REPO / "ada_run" / "em_rulings_baked.json"
APRON = 14


def load(p: Path, default=None):
    if not p.exists():
        return default if default is not None else {}
    return json.loads(p.read_text(encoding="utf-8"))


def cell(v) -> tuple[int, ...]:
    return tuple(int(x) for x in (v or []))


#: how far a ruling's key may sit from the row it binds to. A ruling is a
#: cell and a row is a cell; when the plan has moved the row a few metres the
#: pairing is obvious, and when it has moved it across the building it is a
#: GUESS — and a guess baked into the plan is a second author. Beyond this,
#: the ruling is reported stale and left alone.
MAX_BIND_CELLS = 8


def bake(plan: dict, rulings: list[dict], max_bind: int = MAX_BIND_CELLS) -> tuple[int, list[dict], list[dict]]:
    """Apply what can be applied. Returns (n, applied, unbound)."""
    applied: list[dict] = []
    unbound: list[dict] = []
    used: set[int] = set()
    for o in rulings:
        chapter = str(o.get("chapter", ""))
        token = str(o.get("token", ""))
        kind = str(o.get("kind", ""))
        if kind and kind != "artifact":
            unbound.append({**o, "_why": f"kind {kind} is not a plan row (furniture / plinth / showing rulings stay in the overrides layer)"})
            continue
        # candidate rows: same chapter, same token, not already taken
        cands = []
        for pi, p in enumerate(plan.get("plans", [])):
            if chapter and str(p.get("sequence", "")) != chapter:
                continue
            for ai, a in enumerate(p.get("artifacts", [])):
                if str(a.get("token", "")) != token or (pi, ai) in used:
                    continue
                cands.append((pi, ai, a))
        if not cands:
            unbound.append({**o, "_why": "the plan places no such row any more"})
            continue
        fr = cell(o.get("from"))
        def dist(c):
            tc = cell(c[2].get("tile_cell"))
            if len(fr) < 2 or len(tc) < 2:
                return 10 ** 6
            return abs(tc[0] - fr[0]) + abs(tc[1] - fr[1])
        pi, ai, row = min(cands, key=dist)
        d = dist((pi, ai, row))
        if d > max_bind:
            unbound.append({**o, "_why": f"nearest row is {d} cells from its key — too far to be sure "
                                        f"(rule it again in the museum, or pass --max-distance {d})"})
            continue
        used.add((pi, ai))
        before = dict(row)
        if o.get("remove"):
            plan["plans"][pi]["artifacts"][ai] = None
            applied.append({**o, "_row": before, "_bound_distance": d, "_action": "removed"})
            continue
        to = cell(o.get("to")) or cell(o.get("from"))
        if len(to) >= 2:
            row["tile_cell"] = [to[0], to[1]]
            row["cell"] = [to[0] + APRON, to[1] + APRON]
        if o.get("swap_to"):
            row["token"] = str(o["swap_to"])
        if "rotation" in o and o["rotation"] is not None:
            row["rotation"] = int(float(o["rotation"]))
        if isinstance(o.get("offset"), list) and len(o["offset"]) >= 3:
            row["offset"] = [round(float(v), 2) for v in o["offset"]]
        if o.get("scale") is not None:
            row["scale"] = float(o["scale"])
        row["hand"] = True
        row["ruled"] = {"from": list(fr), "at": datetime.now().isoformat(timespec="seconds"),
                        "by": str(o.get("by", o.get("provenance", "hand")))}
        applied.append({**o, "_row": before, "_bound_distance": d, "_action": "placed"})
    # drop the removed rows
    for p in plan.get("plans", []):
        p["artifacts"] = [a for a in p.get("artifacts", []) if a is not None]
    return len(applied), applied, unbound


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--apply", action="store_true", help="write ada_run/em_plan.json")
    ap.add_argument("--keep", action="store_true", help="do not empty em_overrides.json after baking")
    ap.add_argument("--replay", action="store_true", help="bake em_rulings_baked.json back into a regenerated plan")
    ap.add_argument("--max-distance", type=int, default=MAX_BIND_CELLS,
                    help="how far a ruling's key may sit from the row it binds to (cells)")
    a = ap.parse_args()

    plan = load(PLAN)
    if not plan:
        print("no ada_run/em_plan.json"); return 2
    if a.replay:
        rulings = load(BAKED, {}).get("rulings", [])
        print(f"replaying {len(rulings)} baked ruling(s) into the plan")
    else:
        rulings = load(OVERRIDES, {}).get("overrides", [])
    n, applied, unbound = bake(plan, rulings, a.max_distance)

    for r in applied:
        print(f"  BAKED   {r.get('token'):28s} {r['_action']:8s} -> {r.get('to')} "
              f"(bound {r['_bound_distance']} cells from its key)")
    for r in unbound:
        print(f"  unbound {r.get('token'):28s} {r['_why']}")
    print(f"\n{n} ruling(s) bake into the plan, {len(unbound)} stay in the overrides layer")

    if not a.apply:
        print("(dry run — pass --apply to write ada_run/em_plan.json)")
        return 0
    PLAN.write_text(json.dumps(plan, indent=2) + "\n", encoding="utf-8")
    hist = load(BAKED, {"rulings": []})
    keys = {(str(x.get("chapter")), str(x.get("token")), tuple(cell(x.get("from")))) for x in hist.get("rulings", [])}
    for r in applied:
        k = (str(r.get("chapter")), str(r.get("token")), tuple(cell(r.get("from"))))
        if k not in keys:
            hist.setdefault("rulings", []).append({k2: v for k2, v in r.items() if not k2.startswith("_")})
    hist["schema"] = "adaresearch.em_rulings_baked.v1"
    hist["_readme"] = ("Rulings written INTO ada_run/em_plan.json by tools/bake_rulings.py. "
                       "A regeneration (spine_run --write-plan) returns the plan to the negotiator; "
                       "replay these with `python tools/bake_rulings.py --replay --apply`.")
    BAKED.write_text(json.dumps(hist, indent=1) + "\n", encoding="utf-8")
    if not a.keep and not a.replay:
        ov = load(OVERRIDES, {"overrides": []})
        baked_keys = {(str(r.get("chapter")), str(r.get("token")), tuple(cell(r.get("from")))) for r in applied}
        ov["overrides"] = [o for o in ov.get("overrides", [])
                           if (str(o.get("chapter")), str(o.get("token")), tuple(cell(o.get("from")))) not in baked_keys]
        OVERRIDES.write_text(json.dumps(ov, indent="\t") + "\n", encoding="utf-8")
        print(f"em_overrides.json: {len(ov['overrides'])} ruling(s) left (the baked ones moved into the plan)")
    print(f"plan written -> {PLAN.relative_to(REPO)}; history -> {BAKED.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
