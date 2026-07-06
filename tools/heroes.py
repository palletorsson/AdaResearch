#!/usr/bin/env python3
"""heroes.py — the dialectic list: a HERO and an ANTI-HERO per map.

Palle wants, in conversation, a living list of the project's heroes and
anti-heroes — mostly one per map — because naming the pair names the DRAMA the
map runs, and drama is structure. The hero is the map's protagonist (what the
walk champions); the anti-hero is the counter that complicates it (what the turn
raises). Their tension is the map's dialectic in one line.

This tool maintains doc/book/heroes.json. The CONVERSATION is the editor — the
ghost calls set/del as Palle rules; list renders the current state.

Usage:
  python tools/heroes.py list [--seq=<name>]
  python tools/heroes.py set <Map> --seq=<name> --hero="..." --anti="..." --tension="..."
  python tools/heroes.py del <Map>
"""
from __future__ import annotations

import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
F = os.path.join(REPO, "doc", "book", "heroes.json")

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass


def load() -> dict:
    if os.path.exists(F):
        with open(F, encoding="utf-8") as f:
            return json.load(f)
    return {"_note": "the dialectic list — hero ⟷ anti-hero per map; built in conversation",
            "sequences": {}}


def save(d: dict):
    os.makedirs(os.path.dirname(F), exist_ok=True)
    with open(F, "w", encoding="utf-8", newline="\n") as f:
        json.dump(d, f, indent=1, ensure_ascii=False)


def find_seq(d: dict, mapname: str) -> str:
    for s, maps in d.get("sequences", {}).items():
        if mapname in maps:
            return s
    return ""


def cmd_list(d: dict, seq: str | None):
    seqs = [seq] if seq else list(d.get("sequences", {}))
    total = 0
    for s in seqs:
        maps = d.get("sequences", {}).get(s, {})
        if not maps:
            continue
        print(f"\n### {s}  ({len(maps)})")
        for m, v in maps.items():
            total += 1
            print(f"  {m}")
            print(f"     HERO : {v.get('hero','—')}")
            print(f"     ANTI : {v.get('anti','—')}")
            if v.get("tension"):
                print(f"     ⟷    {v['tension']}")
    print(f"\n{total} maps named.")


def main() -> int:
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return 1
    d = load()
    op = args[0]
    seq = next((a.split("=", 1)[1] for a in args if a.startswith("--seq=")), None)

    if op == "list":
        cmd_list(d, seq)
        return 0

    if op == "set":
        mapname = args[1]
        hero = next((a.split("=", 1)[1] for a in args if a.startswith("--hero=")), None)
        anti = next((a.split("=", 1)[1] for a in args if a.startswith("--anti=")), None)
        tension = next((a.split("=", 1)[1] for a in args if a.startswith("--tension=")), None)
        s = seq or find_seq(d, mapname) or "unfiled"
        d.setdefault("sequences", {}).setdefault(s, {})
        entry = d["sequences"][s].get(mapname, {})
        if hero is not None: entry["hero"] = hero
        if anti is not None: entry["anti"] = anti
        if tension is not None: entry["tension"] = tension
        d["sequences"][s][mapname] = entry
        save(d)
        print(f"set {s}/{mapname}: HERO {entry.get('hero','—')} ⟷ ANTI {entry.get('anti','—')}")
        return 0

    if op == "del":
        mapname = args[1]
        s = find_seq(d, mapname)
        if s and mapname in d["sequences"][s]:
            del d["sequences"][s][mapname]
            if not d["sequences"][s]:
                del d["sequences"][s]
            save(d)
            print(f"deleted {mapname}")
        else:
            print(f"not found: {mapname}")
        return 0

    print(__doc__)
    return 1


if __name__ == "__main__":
    sys.exit(main())
