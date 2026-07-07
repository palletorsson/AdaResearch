#!/usr/bin/env python3
"""build_spine_graph_props.py — per-artifact staging props for the /spine-graph clusters view.

The spine graph's "Clusters" layout is a three-tier mind-map:
  concept (chapter)  →  artifact  →  props

Tier 3 (props) is derived here, cheaply and honestly, from the staging system:
  dressing_rooms/<lookup>.json  →  posture  →  staging_dna template  →  support prop + dressing

Nearly every book artifact (771/772) has a dressing-room record carrying a posture,
and each staging type resolves to a small, real prop set. Output is a flat map the
web reads on demand:

  { "<lookup>": { "posture": "pedestal", "type": "specimen", "props": ["station_plinth"] }, ... }

Usage:  python tools/build_spine_graph_props.py
Output: ada_encyclopedia/public/spine-graph-props.json
"""
from __future__ import annotations

import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.environ.get("ADA_ENCYCLOPEDIA_PATH", "C:/Users/palle/Documents/GitHub/ada_encyclopedia")
BOOK = os.path.join(ENC, "public", "book.json")
ROOMS = os.path.join(REPO, "commons", "artifacts", "dressing_rooms")
DNA = os.path.join(REPO, "commons", "data", "staging_dna.json")
OUT = os.path.join(ENC, "public", "spine-graph-props.json")


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def main() -> int:
    book = load(BOOK)
    templates = load(DNA)["templates"]
    posture_to_type = {v.get("posture"): t for t, v in templates.items()}

    def props_for_type(t: str) -> list[str]:
        tmpl = templates.get(t, {})
        out: list[str] = []
        sup = (tmpl.get("support") or {}).get("prop")
        if sup:
            out.append(sup)
        dressing = tmpl.get("dressing")
        if isinstance(dressing, list):
            for d in dressing:
                out.append(d.get("prop") if isinstance(d, dict) else d)
        return [p for p in out if p]

    lookups = sorted({a["lookup"] for ch in book["chapters"] for a in ch.get("artifacts", [])})
    result: dict[str, dict] = {}
    missing = 0
    for lk in lookups:
        room = os.path.join(ROOMS, f"{lk}.json")
        if not os.path.exists(room):
            missing += 1
            continue
        try:
            posture = load(room).get("posture")
        except Exception:
            missing += 1
            continue
        # DressingRoomBuilder defaults an unset posture to "pedestal" (specimen) —
        # match that so tier-3 props reflect what the engine actually stages.
        if not posture:
            posture = "pedestal"
        t = posture_to_type.get(posture)
        if not t:
            continue
        result[lk] = {"posture": posture, "type": t, "props": props_for_type(t)}

    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(result, f, indent=0, separators=(",", ":"))
    # summary
    by_type: dict[str, int] = {}
    for v in result.values():
        by_type[v["type"]] = by_type.get(v["type"], 0) + 1
    print(f"wrote {len(result)}/{len(lookups)} artifacts ({missing} without a room) -> {OUT}")
    print("by type:", dict(sorted(by_type.items(), key=lambda kv: -kv[1])))
    return 0


if __name__ == "__main__":
    sys.exit(main())
