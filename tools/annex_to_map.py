#!/usr/bin/env python3
"""Move a hall's ANNEX out of em_overrides.json and into its own map.

2026-08-28, Palle: "Can we consolidate the different json files so we can keep
one truth, or at least not have different truths we can disagree on? Make a
system that is clear and where we can encode what we need."

WHAT WAS HARD, precisely. One hall's space was spread over three files in two
alphabets, and two of the three could disagree without anyone being told:

    commons/maps/<Map>/map_data.json   structure, passage, basin, props_deny
    ada_run/em_overrides.json          the four ANNEX rows, keyed by PEARL
    commons/data/em_layout.json        the annex's fittings (window, drop hole)

The annex rows were the worst of it. They lived in the rulings file under a
different key (pearl, not map), in a vocabulary of their own where "4" is a wall
and the map's own "2" is silently dropped — so nine cells painted "2" saved
cleanly, built nothing, and reported nothing. Three files, two alphabets, one
room.

After this there is ONE place a hall's space is written: its map.

    map_info.museum.annex = ["2222…", "2....…", …]   4 rows, z -4 … -1

in the MAP's vocabulary ("1" floor, "2".."5"/"w" wall, "0" = say nothing), which
endless_museum.gd translates for the vestibule. Hand rulings still apply ON TOP —
they are read after the map — so the in-museum T key keeps working and the
precedence is stated instead of accidental.

    python tools/annex_to_map.py --map=Point_One            # report
    python tools/annex_to_map.py --map=Point_One --apply    # migrate
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OVERRIDES = os.path.join(ROOT, "ada_run", "em_overrides.json")
PLAN = os.path.join(ROOT, "ada_run", "em_plan.json")
VESTIBULE_H = 4


def pearl_of(map_name: str) -> str:
    with open(PLAN, encoding="utf-8") as fh:
        for row in json.load(fh).get("plans", []):
            if str(row.get("map", "")) == map_name:
                return str(row.get("pearl", ""))
    return ""


def map_path(map_name: str) -> str:
    return os.path.join(ROOT, "commons", "maps", map_name, "map_data.json")


def main() -> int:
    ap = argparse.ArgumentParser(description="move a hall's annex rows into its map")
    ap.add_argument("--map", required=True)
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()

    pearl = pearl_of(a.map)
    if not pearl:
        print("no plan row names %s — cannot find its pearl" % a.map, file=sys.stderr)
        return 1

    with open(OVERRIDES, encoding="utf-8") as fh:
        ov = json.load(fh)
    rulings = [r for r in ov.get("overrides", [])
               if str(r.get("kind", "")) == "cell" and str(r.get("pearl", "")) == pearl
               and isinstance(r.get("from"), list) and int(r["from"][1]) < 0]

    mp = map_path(a.map)
    with open(mp, "rb") as fh:
        text = fh.read().decode("utf-8")
    crlf = "\r\n" in text
    body = text.replace("\r\n", "\n") if crlf else text
    doc = json.loads(body)
    width = len((doc.get("layers") or {}).get("structure", [[]])[0])

    #: "0" says nothing about a cell — the museum's own default stands. Only the
    #: cells actually ruled are written, so a migration cannot invent walls.
    rows = [["0"] * width for _ in range(VESTIBULE_H)]
    for r in rulings:
        x, z = int(r["from"][0]), int(r["from"][1])
        if not (-VESTIBULE_H <= z < 0) or not (0 <= x < width):
            print("  skipped out-of-range ruling at (%d, %d)" % (x, z))
            continue
        v = str(r.get("value", "1"))
        rows[z + VESTIBULE_H][x] = "1" if v in ("1", "1s") else "2"

    ruled = sum(1 for row in rows for c in row if c != "0")
    print("%s (pearl %r)" % (a.map, pearl))
    print("  %d annex ruling(s) in em_overrides.json -> %d cell(s) in the map" % (len(rulings), ruled))
    for z, row in enumerate(rows):
        print("    z%-3d %s" % (z - VESTIBULE_H, "".join(row)))
    if not a.apply:
        print("\n(report only — pass --apply)")
        return 0
    if not rulings:
        print("\nnothing to migrate")
        return 0

    # write the block into map_info.museum, surgically: the map is compact-rows
    # and a json.dumps round trip reflows it (130 lines -> 1870, measured today)
    lit = ",\n".join('\t\t\t\t"%s"' % "".join(r) for r in rows)
    # AN EMPTY BLOCK TAKES NO COMMA. `"museum": {}` is common — Point_Lines has
    # one — and appending `"annex": [...],` straight after the brace makes a
    # trailing comma and a map that will not parse. Caught before any write,
    # because this tool re-parses what it built, but better not to write it.
    tail = "," if re.search(r'"museum"\s*:\s*\{\s*[^}\s]', body) else "\n\t\t"
    block = '\n\t\t\t"annex": [\n%s\n\t\t\t]%s' % (lit, tail)
    m = re.search(r'("museum"\s*:\s*\{)', body)
    if not m:
        print("no map_info.museum block to write into", file=sys.stderr)
        return 1
    if '"annex"' in body[m.start():m.start() + 2000]:
        print("this map already declares an annex — refusing to write twice", file=sys.stderr)
        return 1
    out = body[:m.end()] + block + body[m.end():]
    json.loads(out)

    ov["overrides"] = [r for r in ov.get("overrides", []) if r not in rulings]
    with open(OVERRIDES, "w", encoding="utf-8") as fh:
        json.dump(ov, fh, indent="\t")
    if crlf:
        out = out.replace("\n", "\r\n")
    tmp = mp + ".tmp"
    with open(tmp, "wb") as fh:
        fh.write(out.encode("utf-8"))
    os.replace(tmp, mp)
    print("\nwrote the annex into %s" % os.path.relpath(mp, ROOT))
    print("removed %d ruling(s) from %s" % (len(rulings), os.path.relpath(OVERRIDES, ROOT)))
    print("one file holds this hall's space now.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
