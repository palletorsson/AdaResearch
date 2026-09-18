#!/usr/bin/env python3
"""em_plan_subset.py — a plan that walks a chosen set of halls back to back.

The endless museum walks the plan's pearl strings, chapter by chapter, so halls that sit
at the ends of four chapters (the biome ladders) are hours apart on foot. This writes a
DERIVED plan holding only the halls you name, as ONE string in ONE building, in the order
you name them — and the museum, handed it with --em-plan, walks them in succession.

  python tools/em_plan_subset.py --maps=Biome_Ladder_Primitives,Biome_Ladder_Transformation,Biome_Ladder_Color,Biome_Cage,Biome_Ladder_Randomness --out=ada_run/em_plan_biome.json
  godot --path . --xr-mode off res://commons/scenes/endless_museum.tscn -- --em-plan=res://ada_run/em_plan_biome.json --em-chapter=primitives --em-map=Biome_Ladder_Primitives

Everything under ada_run/ is derived; this file is too — regenerate it after every
`em_map_halls.py --apply`. The rows are copied verbatim from ada_run/em_plan.json (tile,
bodies, rulings), only `museum`, `sequence`, `pearl_index` and `pearls_total` are rewritten
so the five read as one string. Halls not in the plan are named and skipped.
"""
from __future__ import annotations
import argparse, json, sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PLAN = REPO / "ada_run" / "em_plan.json"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--maps", required=True, help="comma-separated map names, in walk order")
    ap.add_argument("--out", default="ada_run/em_plan_subset.json")
    ap.add_argument("--chapter", default="", help="the chapter the string is filed under (default: the first hall's)")
    ap.add_argument("--building", default="", help="the building every hall wears (default: the first hall's)")
    a = ap.parse_args()
    plan = json.loads(PLAN.read_text(encoding="utf-8"))
    by_map = {}
    for r in plan.get("plans", []):
        if isinstance(r, dict) and r.get("map") and "pearl" in r:
            by_map.setdefault(str(r["map"]), r)
    want = [m for m in a.maps.split(",") if m]
    rows = []
    for m in want:
        if m not in by_map:
            print(f"  {m}: not in {PLAN.name} — skipped (is it dealt? see commons/data/map_authored.json)")
            continue
        rows.append(json.loads(json.dumps(by_map[m])))
    if not rows:
        print("no rows — nothing written")
        return 1
    chapter = a.chapter or str(rows[0]["sequence"])
    building = a.building or str(rows[0]["museum"])
    for i, r in enumerate(rows, 1):
        r["museum"] = building
        r["sequence"] = chapter
        r["pearl_index"] = i
        r["pearls_total"] = len(rows)
        r["_subset"] = f"tools/em_plan_subset.py: copied from the {r.get('map')} row of em_plan.json"
    out = {k: plan[k] for k in ("schema", "museums") if k in plan}
    out["_readme"] = ("DERIVED by tools/em_plan_subset.py — %d hall(s) as one string under chapter `%s` in building `%s`; "
                      "walk it with --em-plan=res://%s --em-chapter=%s --em-map=%s" % (
                          len(rows), chapter, building, a.out.replace("\\", "/"), chapter, rows[0]["map"]))
    out["plans"] = rows
    Path(a.out).write_text(json.dumps(out, indent=1, ensure_ascii=False), encoding="utf-8")
    print(f"wrote {a.out}: {len(rows)} hall(s) under `{chapter}` in `{building}`:")
    for r in rows:
        print(f"  {r['pearl_index']}/{r['pearls_total']}  {r['pearl']}  ({r['map']})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
