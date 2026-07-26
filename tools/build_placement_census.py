#!/usr/bin/env python3
"""
build_placement_census.py — count how often each artifact is actually placed.

Writes commons/data/placement_census.json: the project's own frequency distribution,
ranked. This is a TRUTH SOURCE, not a report — stock_stratum reads it at runtime and
builds its strata to these thicknesses, so the sediment is the real deposit rather
than a hand-tuned illustration of one.

Usage:
  python tools/build_placement_census.py [--top=24]
"""
from __future__ import annotations
import json
import re
import sys
from collections import Counter
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
OUT = REPO / "commons" / "data" / "placement_census.json"
TOK = re.compile(r'^[A-Za-z][A-Za-z0-9_]*$')


def main() -> int:
    top = 24
    for a in sys.argv[1:]:
        if a.startswith("--top="):
            top = int(a.split("=", 1)[1])

    placed: Counter = Counter()
    maps = 0
    for p in (REPO / "commons" / "maps").glob("*/map_data.json"):
        try:
            d = json.loads(p.read_text(encoding="utf-8"))
        except Exception:
            continue
        il = (d.get("layers") or {}).get("interactables") or d.get("interactables")
        if not il:
            continue
        maps += 1
        for row in il:
            if not isinstance(row, list):
                continue
            for c in row:
                if isinstance(c, str) and c.strip():
                    t = c.split(":")[0].split("#")[0].strip()
                    if TOK.match(t):
                        placed[t] += 1

    # scene path per token, so a consumer can instance the actual prop
    lut: dict[str, str] = {}
    for rp in (REPO / "commons" / "artifacts" / "registry").glob("*.json"):
        try:
            data = json.loads(rp.read_text(encoding="utf-8"))
        except Exception:
            continue
        arts = data.get("artifacts", data) if isinstance(data, dict) else data
        if isinstance(arts, dict):
            for tok, e in arts.items():
                if isinstance(e, dict) and e.get("scene"):
                    lut[tok] = e["scene"]

    ranked = [{"token": t, "placements": n, "scene": lut.get(t, "")}
              for t, n in placed.most_common(top)]
    total = sum(placed.values())
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps({
        "_note": "The project's own frequency distribution. Bed thickness in "
                 "stock_stratum is proportional to `placements` — what gets placed most "
                 "becomes the ground everything else stands on.",
        "maps_counted": maps,
        "distinct_tokens": len(placed),
        "total_placements": total,
        "ranked": ranked,
    }, indent=1), encoding="utf-8")
    print(f"{maps} maps · {len(placed)} distinct · {total} placements -> {OUT.name}")
    for r in ranked[:10]:
        print(f"  {r['placements']:5d}  {r['token']}{'' if r['scene'] else '   (no scene)'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
