#!/usr/bin/env python3
"""The exhibition brief — order and kinship, never coordinates.

The layer between "here are the artifacts" and "here is the room". It answers
what stands next to what and why, and hands the negotiator a list it can place
without ever having to reason about meaning.

Nothing here is invented. The project already holds:

  * `commons/data/spine_artifact_order.json`  — the canonical 1D walk, 799 rows
  * `commons/data/artifact_relations.json`    — 12610 TYPED edges over 799
        anchors, each carrying its own `why`, in five kinds
  * `dna.axes` in the registry                — 481 anchors declare axes whose
        values are real, code-derived variants

and `commons/scenes/em/em_sets.gd` already decides what each edge KIND means
spatially. That mapping is repeated here because a Python negotiator cannot call
into GDScript, and it is quoted rather than reinvented:

    named      the relative stands in the lead's SIGHTLINE
    sibling    one scene under several names — an evenly spaced ROW
    axis_kin   ADJACENT, at DIFFERENT values of the shared axis
    family     same neighbourhood, kept apart by PADDING
    co_placed  fill; they already stand together in real maps

A DNA run wants a SERIES — adjacent slots of like capacity — which
`tools/slot_capacity.py` already found 36 of. This checks the brief against
them, so "can this museum actually hold this lineage?" is answered before a
single coordinate is chosen.

Usage:
    python tools/exhibition_brief.py --anchors=origin,platonicsolids
    python tools/exhibition_brief.py --count=6 --museum=uffizi-spine-enfilade
    python tools/exhibition_brief.py --count=12 --json=ada_run/brief.json
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parent.parent
ORDER = REPO / "commons" / "data" / "spine_artifact_order.json"
RELATIONS = REPO / "commons" / "data" / "artifact_relations.json"
CAPACITY = REPO / "commons" / "data" / "slot_capacity.json"

#: What each edge kind means in space. Quoted from em_sets.gd so the two cannot
#: drift silently; if that file changes its mind, this comment is the diff.
KIND_RULE = {
    "named":     "sightline — the relative stands where the lead can be seen with it",
    "sibling":   "row — one scene under several names, dealt at even spacing",
    "axis_kin":  "adjacent, at a DIFFERENT value of the shared axis",
    "family":    "same neighbourhood, held apart by padding",
    "co_placed": "fill — they already stand together in real maps",
}
#: Which kinds earn a place beside the anchor, best first. `co_placed` is
#: deliberately last: standing together in existing maps is evidence of habit,
#: not of argument, and a brief built from habit reproduces the corpus instead
#: of composing it.
KIND_RANK = ["named", "sibling", "axis_kin", "family", "co_placed"]


def load(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def spine_order() -> list[dict[str, Any]]:
    return load(ORDER).get("order", [])


def brief_for(anchor: str, rel: dict[str, Any], relations_cap: int = 2,
              dna_cap: int = 6) -> dict[str, Any]:
    """One anchor's stanza: the lead, its typed relations, and its DNA run."""
    rec = rel.get(anchor, {})
    entries: list[dict[str, Any]] = [{
        "lookup_name": anchor, "role": "feature", "relation": None,
        "why": "the lead this bay is about",
    }]

    # Relations, best KIND first, and never two of the same kind — a bay that
    # shows three co_placed neighbours has said one thing three times.
    seen_kinds: set[str] = set()
    picked = 0
    for kind in KIND_RANK:
        if picked >= relations_cap:
            break
        for r in rec.get("relations", []):
            if picked >= relations_cap:
                break
            if r.get("kind") != kind or kind in seen_kinds:
                continue
            seen_kinds.add(kind)
            entries.append({
                "lookup_name": r.get("token"),
                "role": "related",
                "relation": {"kind": kind, "why": r.get("why"),
                             "rule": KIND_RULE.get(kind, ""),
                             "placements_together": r.get("placements_together", 0)},
                "why": r.get("why"),
            })
            picked += 1

    # One DNA run: the anchor's widest axis, as a local series after its parent.
    axes: dict[str, list[str]] = rec.get("axes") or {}
    run: dict[str, Any] = {}
    if axes:
        axis, values = max(axes.items(), key=lambda kv: len(kv[1]))
        values = list(values)[:dna_cap]
        if len(values) >= 2:
            run = {"axis": axis, "values": values, "length": len(values)}
            for v in values:
                entries.append({
                    "lookup_name": anchor, "role": "dna_variant",
                    "dna": {"axis": axis, "value": v},
                    "relation": {"kind": "dna", "rule":
                                 "a local series immediately after its parent"},
                    "why": f"{anchor}.{axis} = {v}",
                })
    return {"anchor": anchor, "entries": entries, "dna_run": run,
            "multiples": rec.get("multiples", 0),
            "known_to_relations": anchor in rel}


def series_in(museum: str) -> list[dict[str, Any]]:
    table = load(CAPACITY).get("museums", {})
    if museum:
        return table.get(museum, {}).get("series", [])
    out: list[dict[str, Any]] = []
    for key, m in table.items():
        for s in m.get("series", []):
            s = dict(s)
            s["museum"] = key
            out.append(s)
    return out


def match_runs_on_walls(briefs: list[dict[str, Any]],
                        museum: str) -> list[dict[str, Any]]:
    """Route each lineage to a WALL, via the negotiator.

    The floor answer is kept below for comparison, but it is not the answer:
    the corpus offers 36 floor series against 481 anchors that declare a run,
    and 18 of 30 museums offer none. A run is a row on a wall.
    """
    import sys
    sys.path.insert(0, str(REPO / "tools"))
    from spatial_floorplan import from_museum
    from spatial_negotiation import Occupancy, hang_run

    plan = from_museum(museum)
    occ = Occupancy()
    out: list[dict[str, Any]] = []
    for b in briefs:
        run = b.get("dna_run") or {}
        if not run:
            continue
        r = hang_run(plan, b["anchor"], run["axis"], run["values"], occ)
        out.append({
            "anchor": b["anchor"], "axis": run["axis"], "values": run["length"],
            "wall": r.wall, "housed": r.result == "ACCEPT",
            "why": (r.traces[0].detail if r.traces else ""),
        })
    walls_used = len({m["wall"] for m in out if m["housed"]})
    for m in out:
        m["walls_in_museum"] = len(plan.walls)
        m["walls_used"] = walls_used
    return out


def match_runs(briefs: list[dict[str, Any]],
               series: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """The FLOOR answer, kept for comparison — a run wanting N adjacent slots."""
    pool = sorted(series, key=lambda s: s["length"])
    out: list[dict[str, Any]] = []
    for b in briefs:
        run = b.get("dna_run") or {}
        if not run:
            continue
        need = run["length"]
        hit = next((s for s in pool if s["length"] >= need
                    and not s.get("_taken")), None)
        if hit is not None:
            hit["_taken"] = True
        out.append({
            "anchor": b["anchor"], "axis": run["axis"], "values": need,
            "series": (hit.get("slots") if hit else None),
            "series_length": (hit.get("length") if hit else 0),
            "museum": (hit.get("museum") if hit else None),
            "housed": hit is not None,
        })
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--anchors", default="", help="comma-separated lookup names")
    ap.add_argument("--count", type=int, default=6,
                    help="how many spine anchors to take when none are named")
    ap.add_argument("--museum", default="", help="check series against one museum")
    ap.add_argument("--relations", type=int, default=2)
    ap.add_argument("--json", default="")
    args = ap.parse_args()

    rel = load(RELATIONS).get("artifacts", {})
    if not rel:
        print("no artifact_relations.json — nothing to build a brief from")
        return 1

    if args.anchors:
        anchors = [a.strip() for a in args.anchors.split(",") if a.strip()]
    else:
        anchors, seen = [], set()
        for row in spine_order():
            tok = str(row.get("lookup", ""))
            if tok in rel and tok not in seen:
                anchors.append(tok)
                seen.add(tok)
            if len(anchors) >= args.count:
                break

    briefs = [brief_for(a, rel, args.relations) for a in anchors]
    series = series_in(args.museum)
    floor_matches = match_runs(briefs, series)
    matches = (match_runs_on_walls(briefs, args.museum) if args.museum
               else floor_matches)

    print("=" * 68)
    print("EXHIBITION BRIEF — order and kinship, no coordinates")
    print("=" * 68)
    n_entries = 0
    for b in briefs:
        print(f"\n  {b['anchor']}")
        for e in b["entries"]:
            n_entries += 1
            role = e["role"]
            if role == "feature":
                print(f"      {e['lookup_name']:34s} feature")
            elif role == "dna_variant":
                print(f"        - {e['dna']['axis']}={e['dna']['value']:<20s} "
                      f"dna variant")
            else:
                k = e["relation"]["kind"]
                print(f"      {str(e['lookup_name']):34s} {k:<9s} {e['relation']['rule']}")

    print()
    print("=" * 68)
    print("LINEAGE vs ARCHITECTURE")
    print("=" * 68)
    if not matches:
        print("  no anchor in this brief declares a DNA axis")
    for m in matches:
        if "wall" in m:
            where = (str(m["wall"]).split("/")[-1] if m["housed"]
                     else "NO WALL LONG ENOUGH")
        else:
            where = (f"{m.get('museum') or args.museum}/{len(m['series'])} slots"
                     if m["housed"] else "NO SERIES LONG ENOUGH")
        print(f"  {m['anchor']:30s} {m['axis']:<14s} {m['values']} values -> {where}")

    housed = sum(1 for m in matches if m["housed"])
    if args.museum:
        on_floor = sum(1 for m in floor_matches if m["housed"])
        print()
        print(f"  routed to WALLS : {housed}/{len(matches)}"
              f"   (the same runs on the FLOOR: {on_floor}/{len(floor_matches)})")
    print()
    print(f"  anchors {len(briefs)} · entries {n_entries} · "
          f"DNA runs {len(matches)} · runs with a home {housed}/{len(matches)}")
    print(f"  series available: {len(series)}"
          + (f" in {args.museum}" if args.museum else " across all museums"))

    if args.json:
        out = REPO / args.json
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps({
            "schema": "adaresearch.exhibition_brief.v1",
            "kind_rules": KIND_RULE,
            "anchors": briefs,
            "lineage_matches": matches,
        }, indent=1), encoding="utf-8")
        print(f"  wrote {args.json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
