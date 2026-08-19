#!/usr/bin/env python3
"""ROOM READING — does the hall read the poem in order?

    python tools/em_reading.py primitives            # every pearl of the chapter
    python tools/em_reading.py primitives/point      # one pearl

Palle, 2026-08-19: "the book and the plan and the 3d space should have the same
artifact and artifact order — from the right to the left and along z, down the
page." The poem's order is the pearl's tokens (tools/em_speak.py, /speak). The
hall's order is the plan row read as a room: along z (down the page), and
within a row from the right to the left (facing +z the right hand is -x, so x
ascending). Every interior body of the poem gets a position in both; the
report names each line that reads out of order and where it stands.
Exit 1 when a pearl reads out of order.
"""
from __future__ import annotations
import json, sys
from pathlib import Path
REPO = Path(__file__).resolve().parent.parent
TRUNK = REPO / "commons" / "data" / "trunk_branches.json"
PLAN = REPO / "ada_run" / "em_plan.json"
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")


def check(chapter: str, pearl: str | None) -> int:
    trunk = json.loads(TRUNK.read_text(encoding="utf-8"))
    plan = json.loads(PLAN.read_text(encoding="utf-8"))
    node = next((t for t in trunk.get("trunk", []) if t.get("node") == chapter), None)
    if not node:
        print(f"no chapter {chapter}"); return 1
    bad_total = 0
    pearls = node.get("pearls", [])
    for pi, p in enumerate(pearls):
        if pearl and p.get("pearl") != pearl:
            continue
        if p.get("join") and pi > 0:
            print(f"{p.get('pearl'):18s} shares the hall of the pearl before (read there)"); continue
        row = next((r for r in plan.get("plans", []) if r.get("sequence") == chapter and r.get("pearl") == p.get("pearl")), None)
        if not row:
            print(f"{p.get('pearl'):18s} no plan row"); continue
        poem = [t for t in p.get("tokens", [])]
        for pg in (row.get("pages") or [])[1:]:
            poem += [t for t in pg.get("tokens", []) if t not in poem]
        where = {}
        for a in row.get("artifacts", []):
            if a.get("venue") == "interior" and a.get("tile_cell"):
                where.setdefault(a["token"], (int(a["tile_cell"][1]), int(a["tile_cell"][0])))   # (z, x): down the page, right to left
        for i, t in enumerate(p.get("foyer", [])):
            where.setdefault(t, (-100 + i, 0))          # the foyer reads first, in the poem's order
        present = [t for t in poem if t in where]
        missing = [t for t in poem if t not in where]
        hall = sorted(present, key=lambda t: where[t])
        # the reading: walk the hall order and mark lines that come before a line earlier in the poem
        rank = {t: i for i, t in enumerate(poem)}
        # the lines OUT of order are the fewest whose removal leaves the hall reading
        # the poem — the complement of a longest increasing subsequence of ranks —
        # so one body that fell back to the front is one fault, not a fault on
        # every line after it
        seq = [rank[t] for t in hall]
        best_len = [1] * len(seq); prev = [-1] * len(seq)
        for i in range(len(seq)):
            for j in range(i):
                if seq[j] < seq[i] and best_len[j] + 1 > best_len[i]:
                    best_len[i] = best_len[j] + 1; prev[i] = j
        keep = set()
        if seq:
            i = max(range(len(seq)), key=lambda k: best_len[k])
            while i != -1:
                keep.add(i); i = prev[i]
        bad = [hall[i] for i in range(len(hall)) if i not in keep]
        tag = "READS" if not bad else f"{len(bad)} out of order"
        print(f"{p.get('pearl'):18s} {'ordered' if p.get('ordered') else 'unordered':9s} poem {len(poem):2d} · in hall {len(present):2d} · {tag}"
              + (f" · not in the hall: {', '.join(missing)}" if missing else ""))
        if bad or pearl:
            for i, t in enumerate(hall):
                mark = "  ✗" if t in bad else "   "
                print(f"   {mark} {i + 1:2d}. {t:32s} z {where[t][0]:2d} x {where[t][1]:2d}   (poem line {rank[t] + 1})")
        bad_total += len(bad)
    return 1 if bad_total else 0


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__); return 2
    chapter, _, pearl = sys.argv[1].partition("/")
    return check(chapter, pearl or None)


if __name__ == "__main__":
    raise SystemExit(main())
