#!/usr/bin/env python
"""refit_curated_caps.py — grow the curated walls' plinth caps to fit the LIVE footprint.

The hand-curated spine walls sized their plinth caps from the static manifest, which
under-measures deferred/field artifacts — so --validate-curated found held items overhanging
their caps. This grows each overhanging item's cap_meters (in spine_walls.json, every map it
appears in) to its live footprint + a lip, so nothing overhangs.

The gentlest fix for HAND-curated work: keep the item where the curator placed it, just make
the cap fit. A few items are so large the cap is effectively a stage — those are flagged, not
silently turned into giant plinths; swapping them to station_stage is a curation call.

  In:  commons/data/prop_validation_curated_report.json   (from --validate-curated)
  Out: commons/data/spine_walls.json                       (cap_meters grown in place)
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SW = os.path.join(ROOT, "commons", "data", "spine_walls.json")
REP = os.path.join(ROOT, "commons", "data", "prop_validation_curated_report.json")
LIP = 0.25
STAGE_HINT = 3.6  # beyond this a "cap" is really a stage — flag, don't silently grow


def main() -> None:
    rep = json.load(open(REP, encoding="utf-8"))
    over = {r["artifact"]: r["art_w"] for r in rep if not r.get("fit", True) and r.get("art_w", 0) > 0}
    sw = json.load(open(SW, encoding="utf-8"))
    changed, flagged = [], []
    for mapname, entry in sw.items():
        pieces = entry.get("pieces", [])
        for p in pieces:
            if p.get("token", "") not in over:
                continue
            ax, az = round(float(p.get("x", 0)), 1), round(float(p.get("z", 0)), 1)
            for q in pieces:  # the plinth sharing this artifact's (x, z)
                qt = q.get("token", "")
                if not (qt.startswith("station_plinth") or qt == "station_micropod"):
                    continue
                if round(float(q.get("x", 0)), 1) == ax and round(float(q.get("z", 0)), 1) == az:
                    live = float(over[p["token"]])
                    if live > STAGE_HINT:
                        flagged.append((p["token"], round(live, 2)))
                        break  # too big for a wall cap — leave it for the curator (station_stage)
                    q.setdefault("config", {})["cap_meters"] = round(live + LIP, 2)
                    changed.append((mapname, p["token"], round(live + LIP, 2)))
                    break
    json.dump(sw, open(SW, "w", encoding="utf-8"), indent=1)  # match the file: 1-space indent, ensure_ascii (escaped unicode), CRLF (Windows text mode)
    print(f"grew {len(changed)} caps in spine_walls.json")
    for m, t, c in changed:
        print(f"  {m:30s} {t:32s} cap -> {c} m")
    if flagged:
        print("\nFLAG — cap is stage-sized; consider swapping the prop to station_stage:")
        for t, lv in dict(flagged).items():
            print(f"  {t}  ({lv} m)")


if __name__ == "__main__":
    main()
