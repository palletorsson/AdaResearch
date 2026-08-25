#!/usr/bin/env python3
"""PLACE THE RESCUES a fold ledger named, one cell each, without disturbing
what a curated map already holds.

2026-08-25. The fold plan says `rescue <map>` for a token; this puts it there.
It does NOT re-place the map (tools/place.py would, and a hand-composed room
does not survive that) — it finds the emptiest floor cell and writes one token.

    python tools/rescue_place.py --plan=doc/folds/forces.json [--apply]

A candidate cell must be floor ("1"), empty in the interactables layer, empty
in the utilities layer, and not the spawn. Among those it takes the cell whose
distance to the nearest existing artifact is largest — the room fills from its
empty middle outward, so a rescue never lands in someone's lap.
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load(name):
    path = os.path.join(ROOT, "commons", "maps", name, "map_data.json")
    with open(path, encoding="utf-8") as fh:
        return path, json.load(fh)


def free_cell(doc, taken):
    layers = doc.get("layers", {})
    st = layers.get("structure", [])
    inter = layers.get("interactables", [])
    util = layers.get("utilities", [])
    occupied = []
    for z, row in enumerate(inter):
        for x, v in enumerate(row):
            if str(v).strip():
                occupied.append((x, z))
    occupied += list(taken)
    best, best_score = None, -1.0
    for z, row in enumerate(st):
        for x, cell in enumerate(row):
            if str(cell).strip() != "1":
                continue
            if z < len(inter) and x < len(inter[z]) and str(inter[z][x]).strip():
                continue
            if z < len(util) and x < len(util[z]) and str(util[z][x]).strip():
                continue
            if (x, z) in taken:
                continue
            # a cell on the border is a doorway more often than a plinth
            if x == 0 or z == 0 or z == len(st) - 1 or x == len(row) - 1:
                continue
            if occupied:
                score = min(abs(x - ox) + abs(z - oz) for ox, oz in occupied)
            else:
                score = 99.0
            if score > best_score:
                best, best_score = (x, z), score
    return best, best_score


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--plan", required=True)
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    with open(os.path.join(ROOT, args.plan), encoding="utf-8") as fh:
        plan = json.load(fh)

    by_map = {}
    for tok, spec in plan.get("verdicts", {}).items():
        parts = str(spec).split()
        if parts and parts[0] == "rescue" and len(parts) > 1:
            by_map.setdefault(parts[1], []).append(tok)
        elif parts and parts[0] == "rehome" and len(parts) > 2:
            # "rehome <sequence> <map>" — the room is named, so place it there
            by_map.setdefault(parts[2], []).append(tok)

    touched = []
    for name in sorted(by_map):
        path, doc = load(name)
        inter = doc["layers"]["interactables"]
        taken = set()
        for tok in sorted(by_map[name]):
            if any(str(v).strip().split("#")[0].split(":")[0] == tok
                   for row in inter for v in row):
                print("  %-46s already in %s" % (tok, name))
                continue
            cell, clearance = free_cell(doc, taken)
            if cell is None:
                print("  %-46s NO ROOM in %s" % (tok, name))
                continue
            x, z = cell
            taken.add(cell)
            print("  %-46s -> %-28s (%2d,%2d)  clearance %d" % (tok, name, x, z, clearance))
            if args.apply:
                inter[z][x] = tok
        if args.apply:
            with open(path, "w", encoding="utf-8") as fh:
                json.dump(doc, fh)
            touched.append(path)
    for path in touched:
        subprocess.run([sys.executable, os.path.join(ROOT, "tools", "compact_map_json.py"), path],
                       cwd=ROOT, check=False)
    return 0


if __name__ == "__main__":
    sys.exit(main())
