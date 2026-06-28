#!/usr/bin/env python3
"""Take self-grounded furniture (_bench/_workbench/_desk/_console) OFF its plinth in the curated walls.

These artifacts build their own base (extends embodied_prop.gd), so a plinth under them double-raises
them. For each such artifact paired with a station plinth at the same (x,z): drop the plinth and set
the artifact's y to floor (0) — the resolver's _settle then grounds it on the floor. The plinth's
caption plate goes away with it (benches read as their own thing).

Dry-run by default; pass --apply to write the curated_walls files.
"""
import json
import glob
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CURATED = os.path.join(ROOT, "commons", "data", "curated_walls")
APPLY = "--apply" in sys.argv

SELF_GROUNDED = ("_bench", "_workbench", "_desk", "_console")
PLINTHS = ("station_plinth", "station_micropod", "station_plinth_wide")


def _f(v, d=0.0):
    try:
        return float(str(v))
    except Exception:
        return d


def main():
    n_benches = 0
    n_removed = 0
    for wp in sorted(glob.glob(os.path.join(CURATED, "*.json"))):
        wall = json.load(open(wp, encoding="utf-8"))
        pieces = wall.get("pieces", [])
        benches = [p for p in pieces if str(p.get("token", "")).endswith(SELF_GROUNDED)]
        if not benches:
            continue
        name = os.path.basename(wp)[:-5]
        removed_ids = set()
        for b in benches:
            bx, bz = _f(b.get("x")), _f(b.get("z"))
            plinth = next((p for p in pieces if str(p.get("token", "")) in PLINTHS
                           and abs(_f(p.get("x")) - bx) < 0.06 and abs(_f(p.get("z")) - bz) < 0.06
                           and id(p) not in removed_ids), None)
            tag = "(no plinth — already on floor)"
            if plinth:
                removed_ids.add(id(plinth))
                tag = "drop %s (was y=%.2f -> 0)" % (plinth.get("token"), _f(b.get("y")))
            print("    %-30s %s" % (b.get("token"), tag))
            if APPLY:
                b["y"] = 0.0
        if APPLY and removed_ids:
            wall["pieces"] = [p for p in pieces if id(p) not in removed_ids]
            json.dump(wall, open(wp, "w", encoding="utf-8"), indent=1)
        print("%-26s %d bench(es), %d plinth(s) removed\n" % (name, len(benches), len(removed_ids)))
        n_benches += len(benches)
        n_removed += len(removed_ids)
    print("TOTAL: %d benches set to floor, %d plinths removed  (%s)"
          % (n_benches, n_removed, "APPLIED" if APPLY else "dry-run"))


if __name__ == "__main__":
    main()
