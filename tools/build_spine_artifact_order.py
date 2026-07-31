#!/usr/bin/env python3
"""
build_spine_artifact_order.py — the curriculum as a dealing order.

The endless museum's fast loop deals artifacts into template slots. Dealt from a
seeded shuffle it is a museum of the collection; dealt in SPINE ORDER it is the
curriculum walked through eight real museums — the book as a building (the wire
named in the 2026-07-31 handover).

Spine order is not invented here, it is read out of the shipped truth files:
  curriculum_spine.json  spine.sequences sorted by `order`   (24 sequences)
  sequences/<seq>.json   sequences[<seq>].maps               (map order)
  <Map>/map_data.json    layers.interactables, row-major     (artifact order)

An artifact placed many times appears ONCE, at its first appearance in the walk
— the same rule /order-of-things uses. Cells strip placement suffixes
(`token:rot:y` and `#key:value` config tokens). No registry filtering happens
here: the manifest records the curriculum's order; the consumer applies its own
liveness rules (map_ready, scene exists) at load.

Output: commons/data/spine_artifact_order.json
  { _meta: {...}, order: [ {lookup, sequence, map}, ... ] }

Usage:
  python tools/build_spine_artifact_order.py           # write the manifest
  python tools/build_spine_artifact_order.py --print   # also list the first 40
"""
from __future__ import annotations
import json
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SPINE = REPO / "commons" / "maps" / "curriculum_spine.json"
SEQ_DIR = REPO / "commons" / "maps" / "sequences"
MAPS_DIR = REPO / "commons" / "maps"
OUT = REPO / "commons" / "data" / "spine_artifact_order.json"


def _load(p: Path):
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None


def spine_sequences() -> list[str]:
    d = _load(SPINE) or {}
    rows = d.get("spine", {}).get("sequences", [])
    rows = sorted(rows, key=lambda r: r.get("order", 999))
    return [r["name"] for r in rows if r.get("name")]


def maps_for(seq: str) -> list[str]:
    d = _load(SEQ_DIR / f"{seq}.json") or {}
    entry = d.get("sequences", {}).get(seq, {})
    return [m for m in entry.get("maps", []) if isinstance(m, str)]


def artifacts_in(map_name: str) -> list[str]:
    d = _load(MAPS_DIR / map_name / "map_data.json")
    if not d:
        return []
    rows = d.get("layers", {}).get("interactables", [])
    out: list[str] = []
    for row in rows:
        if not isinstance(row, list):
            continue
        for cell in row:
            tok = str(cell).split("#")[0].split(":")[0].strip()
            if tok:
                out.append(tok)
    return out


def main() -> int:
    seqs = spine_sequences()
    if not seqs:
        print(f"no spine sequences found in {SPINE}")
        return 1
    seen: set[str] = set()
    order: list[dict] = []
    maps_read = maps_missing = 0
    for seq in seqs:
        for m in maps_for(seq):
            arts = artifacts_in(m)
            if not (MAPS_DIR / m / "map_data.json").exists():
                maps_missing += 1
                continue
            maps_read += 1
            for a in arts:
                if a in seen:
                    continue
                seen.add(a)
                order.append({"lookup": a, "sequence": seq, "map": m})
    OUT.write_text(json.dumps({
        "_meta": {
            "generated": time.strftime("%Y-%m-%d %H:%M:%S"),
            "generator": "tools/build_spine_artifact_order.py",
            "rule": "first appearance walking the spine: sequence order -> map order -> interactables row-major",
            "sequences": len(seqs),
            "maps_read": maps_read,
            "maps_missing": maps_missing,
            "artifacts": len(order),
        },
        "order": order,
    }, indent=1), encoding="utf-8")
    print(f"spine artifact order -> {OUT.relative_to(REPO)}")
    print(f"  {len(seqs)} sequences, {maps_read} maps read ({maps_missing} missing), {len(order)} distinct artifacts")
    if "--print" in sys.argv:
        for row in order[:40]:
            print(f"  {row['sequence']:22} {row['map']:32} {row['lookup']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
