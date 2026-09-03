#!/usr/bin/env python3
"""shelf.py — the artifact shelf, made searchable and seeable.

2026-09-03, Palle: "see that you know all the artifacts and that they are
organized in the right categories for fast look up and have images so you can
see them".

Measured before writing this: 2899 artifacts across 223 registry files; 892 of
them stand in the 185 live spine maps, so 2007 have never been placed; 607 are
category "unknown" among 119 distinct category values; and 1750 have no capture,
so more than half the shelf has never been looked at. A loop that starts by
asking "what could express this concept" cannot run against that.

This builds one index, doc/shelf.json, and answers the question three ways:

    python tools/shelf.py --build              rebuild the index
    python tools/shelf.py rotation invariant   what could express this
    python tools/shelf.py --unseen --seq=color what is unplaced and unseen here
    python tools/shelf.py --blind              what has no capture (the shoot list)

The search is deliberately dumb and deterministic: a scored substring match over
name, description, tags, category, qfep connection and the identity header. No
model, no server, no key. It is the fast lookup, not the judgement — the
judgement is what the loop spends its agents on.
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
SHELF = os.path.join(ROOT, "doc", "shelf.json")
SHOTS = os.path.expandvars(
    r"%APPDATA%/Godot/app_userdata/Ada Research Zero One/multi_shots")

STOP = {"the", "a", "an", "and", "of", "in", "to", "is", "it", "for", "on", "with", "that"}


def _text_of(entry: dict) -> str:
    """Everything about an artifact that a concept search should see."""
    bits = [
        str(entry.get("name", "")), str(entry.get("description", "")),
        str(entry.get("category", "")), " ".join(entry.get("tags", []) or []),
        str(entry.get("qfep_connection", "")), str(entry.get("theoreticalGrounding", "")),
    ]
    dna = entry.get("dna") or {}
    for axis, values in (dna.get("axes") or {}).items():
        bits.append(axis + " " + " ".join(str(v) for v in values))
    return " ".join(bits).lower()


def build() -> dict:
    reg: dict[str, dict] = {}
    src: dict[str, str] = {}
    for f in sorted(glob.glob(os.path.join(ROOT, "commons", "artifacts", "registry", "*.json"))):
        try:
            arts = json.load(open(f, encoding="utf-8")).get("artifacts", {})
        except Exception:
            continue
        for k, v in arts.items():
            reg[k] = v
            src[k] = os.path.basename(f)

    # where each artifact stands, across the LIVE spine only
    authored = json.load(open(os.path.join(ROOT, "commons", "data", "map_authored.json"), encoding="utf-8"))
    live_maps: set[str] = set()
    for f in glob.glob(os.path.join(ROOT, "commons", "maps", "sequences", "*.json")):
        sid = os.path.basename(f)[:-5]
        if sid not in authored:
            continue
        try:
            d = json.load(open(f, encoding="utf-8"))
        except Exception:
            continue
        s = d["sequences"].get(sid) if isinstance(d.get("sequences"), dict) else d
        if isinstance(s, dict):
            for m in s.get("maps", []):
                live_maps.add(m)
    where: dict[str, list[str]] = collections.defaultdict(list)
    for m in sorted(live_maps):
        p = os.path.join(ROOT, "commons", "maps", m, "map_data.json")
        if not os.path.exists(p):
            continue
        try:
            layers = json.load(open(p, encoding="utf-8"))["layers"]
        except Exception:
            continue
        for row in layers.get("interactables", []):
            for c in row:
                c = str(c).strip()
                if c and c != "-":
                    tok = c.split(":")[0].split("#")[0]
                    if m not in where[tok]:
                        where[tok].append(m)

    seen = set(os.listdir(SHOTS)) if os.path.isdir(SHOTS) else set()

    out = {}
    for k, v in reg.items():
        sn = v.get("spatial_needs") or {}
        meas = v.get("measurements") or {}
        out[k] = {
            "file": src[k],
            "category": str(v.get("category", "")) or "unknown",
            "description": str(v.get("description", ""))[:400],
            "tags": v.get("tags") or [],
            "dna_axes": list(((v.get("dna") or {}).get("axes") or {}).keys()),
            "in_maps": where.get(k, []),
            "placements": len(where.get(k, [])),
            "seen": k in seen,
            "footprint_cells": sn.get("footprint_cells"),
            "platform": sn.get("platform"),
            "aabb": meas.get("aabb_size"),
            "search": _text_of(v),
        }
    return out


def load() -> dict:
    if not os.path.exists(SHELF):
        return build()
    return json.load(open(SHELF, encoding="utf-8"))


def score(entry: dict, terms: list[str]) -> int:
    """Name hit 5, tag or category 3, anything else 1. Dumb on purpose."""
    s = 0
    name = entry["file"] + " " + " ".join(entry["tags"]) + " " + entry["category"]
    for t in terms:
        if t in STOP:
            continue
        s += 5 * len(re.findall(r"\b" + re.escape(t), name.lower()))
        s += entry["search"].count(t)
    return s


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("terms", nargs="*")
    ap.add_argument("--build", action="store_true")
    ap.add_argument("--blind", action="store_true", help="artifacts with no capture")
    ap.add_argument("--unseen", action="store_true", help="never placed in the live spine")
    ap.add_argument("--seq", default="", help="restrict --unseen to a sequence's own registry files")
    ap.add_argument("--limit", type=int, default=20)
    args = ap.parse_args()

    if args.build:
        shelf = build()
        os.makedirs(os.path.dirname(SHELF), exist_ok=True)
        json.dump(shelf, open(SHELF, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
        placed = sum(1 for v in shelf.values() if v["placements"])
        seen = sum(1 for v in shelf.values() if v["seen"])
        unknown = sum(1 for v in shelf.values() if v["category"] == "unknown")
        print(f"shelf: {len(shelf)} artifacts -> {SHELF}")
        print(f"  placed in the live spine : {placed}   never placed: {len(shelf) - placed}")
        print(f"  with a capture           : {seen}   blind: {len(shelf) - seen}")
        print(f"  category 'unknown'       : {unknown}")
        return 0

    shelf = load()

    if args.blind:
        rows = [(k, v) for k, v in shelf.items() if not v["seen"] and v["placements"]]
        rows.sort(key=lambda kv: -kv[1]["placements"])
        print(f"BLIND BUT STANDING — {len(rows)} artifacts are in a live map with no capture")
        for k, v in rows[:args.limit]:
            print(f"  {k:38s} {v['placements']:2d} map(s)  {v['category']:16s} {v['in_maps'][0]}")
        return 0

    if args.unseen:
        rows = [(k, v) for k, v in shelf.items() if not v["placements"]]
        if args.seq:
            rows = [(k, v) for k, v in rows if args.seq.lower() in (v["file"] + v["category"]).lower()]
        rows.sort(key=lambda kv: (not kv[1]["seen"], kv[0]))
        print(f"ON THE SHELF, NEVER PLACED — {len(rows)}"
              + (f" matching {args.seq!r}" if args.seq else ""))
        for k, v in rows[:args.limit]:
            eye = "seen" if v["seen"] else "BLIND"
            print(f"  {k:38s} {eye:5s} {v['category']:16s} {v['description'][:70]}")
        return 0

    if not args.terms:
        ap.print_help()
        return 1

    terms = [t.lower() for t in args.terms]
    rows = [(score(v, terms), k, v) for k, v in shelf.items()]
    rows = [r for r in rows if r[0] > 0]
    rows.sort(key=lambda r: (-r[0], -r[2]["seen"], r[1]))
    print(f"WHAT COULD EXPRESS {' '.join(terms)!r} — {len(rows)} candidates\n")
    for s, k, v in rows[:args.limit]:
        mark = "*" if not v["placements"] else " "
        eye = "seen" if v["seen"] else "BLIND"
        axes = ("  axes:" + ",".join(v["dna_axes"])) if v["dna_axes"] else ""
        print(f" {mark}{s:4d}  {k:34s} {eye:5s} {v['placements']}x  {v['category']:14s}{axes}")
        print(f"        {v['description'][:110]}")
    print("\n  * = never placed in the live spine. These are the ones the museum has not met.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
