#!/usr/bin/env python3
"""PLACE FOR REAL — the fifty stop being a proposal.

2026-08-25, Palle: "what would you say to make some proportions of actual
placement, there is a lot of potential, i do not think placement can go wrong,
vibe it?"

Every tool before this one refused to place. That was the right default while
the units were still being argued about; it is the wrong one now that both
sides speak grid cells and the fit is checkable. So this writes maps.

PROPORTIONS, which is the half of the question that matters. A room filled to
100% is worse than the same room at 60% — the empty slots are what make the
full ones read as chosen. So each VARIANT gets a density, and it is a design
claim rather than a parameter:

    drum       1.0   one thing, and the room is the frame
    crypt      1.0   a single niche IS the room
    free_plan  0.75  Mies: few islands, and floor between them
    enfilade   0.65  a vista needs the wall to be mostly wall
    field      0.55  Dia:Beacon reads as many only if it is not all
    hypostyle  0.50  the columns make the rhythm; things answer, not fill
    cabinet    0.80  Soane packed his, and that is the point of a cabinet

Within a room the hero is kept first, then the tightest fits, then whatever
sits FURTHEST from what is already placed — so a half-filled room spreads
instead of clumping in one corner.

    python tools/place_museums.py             # what it would write
    python tools/place_museums.py --apply     # write the maps

Only rooms that are already legal maps get written: odd 9-19 on both axes, per
the band ruled today. The rest of the fifty stay proposals until their plans
are trimmed.
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

DENSITY = {"drum": 1.0, "crypt": 1.0, "free_plan": 0.75, "enfilade": 0.65,
           "field": 0.55, "hypostyle": 0.50, "cabinet": 0.80}

SHORT = {"bay:altes-rotunda-hub#b2": "Rotunda",
         "bay:mesdag-panorama-drum#b3": "Drum",
         "bay:thoronet-circumambulation-void#b3": "Cloister",
         "bay:teshima-droplet#b3": "Droplet",
         "bay:uffizi-spine-ordered#b4": "Spine",
         "bay:caracalla-thermal-axis#b4": "Thermae"}


def odd_band(n):
    return 9 <= n <= 19 and n % 2 == 1


def cell_out(v):
    """The museum tile's vocabulary as a MAP's. '4' becomes the explicit 'w'
    the grid and both derivers agree on; everything else passes through."""
    s = str(v).strip()
    if s == "" or s == "0":
        return "0"
    if s.startswith("4"):
        return "w"
    return s


def pick(slots, assigns, density):
    """Which slots actually get a thing. Hero first, then tightest, then
    furthest from what is already down — a half-filled room should spread."""
    have = [a for a in assigns if a["token"]]
    want = max(1, int(round(len(have) * density)))
    by_slot = {a["slot"]: a for a in have}
    chosen = []
    heroes = [a for a in have if slots[a["slot"]]["kind"] == "hero"]
    if heroes:
        chosen.append(heroes[0])
    rest = sorted((a for a in have if a not in chosen),
                  key=lambda a: (a["waste"] if a["waste"] is not None else 99, a["slot"]))
    while len(chosen) < want and rest:
        if not chosen:
            chosen.append(rest.pop(0))
            continue
        # furthest from everything already placed, among the tightest half
        head = rest[:max(1, len(rest) // 2)]
        best = max(head, key=lambda a: min(abs(a["x"] - c["x"]) + abs(a["z"] - c["z"])
                                           for c in chosen))
        chosen.append(best)
        rest.remove(best)
    return sorted(chosen, key=lambda a: (a["z"], a["x"])), by_slot


def build_map(m, room, chosen):
    tile = m["tile"]
    h, w = len(tile), len(tile[0])
    st = [[cell_out(v) for v in row] for row in tile]
    ut = [["" for _ in range(w)] for _ in range(h)]
    it = [["" for _ in range(w)] for _ in range(h)]
    for a in chosen:
        it[a["z"]][a["x"]] = a["token"]
    # the spawn: the first free floor cell reading from the near edge
    placed = {(a["x"], a["z"]) for a in chosen}
    sp = None
    for z in range(1, h - 1):
        for x in range(1, w - 1):
            if st[z][x] == "1" and (x, z) not in placed:
                sp = (x, z)
                break
        if sp:
            break
    if sp:
        ut[sp[1]][sp[0]] = "sp"
    # the exit: a far-end floor cell, sunk to void because a teleporter stands
    # on 0 (the pathfinder says so, and it is right — you step DOWN and out)
    tp = None
    for z in range(h - 2, 0, -1):
        for x in range(w - 2, 0, -1):
            if st[z][x] == "1" and (x, z) not in placed and (x, z) != sp:
                tp = (x, z)
                break
        if tp:
            break
    if tp:
        st[tp[1]][tp[0]] = "0"
        ut[tp[1]][tp[0]] = "t"
    return {
        "map_info": {
            "name": room["map_name"],
            "lookup_name": room["map_name"],
            "title": room["title"],
            "format": "json", "version": "1.0",
            "dimensions": {"width": w, "depth": h, "max_height": 5},
            "museum": {"gate": False},
            "metadata": {"source": "tools/place_museums.py",
                         "plan": m["pattern"], "variant": m["variant"],
                         "sequence": room["sequence"], "density": DENSITY.get(m["variant"], 0.6),
                         "n_artifacts": len(chosen)},
        },
        "layers": {"structure": st, "utilities": ut, "interactables": it},
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    with open(os.path.join(ROOT, "commons", "data", "museum_50.json"), encoding="utf-8") as fh:
        museums = {m["id"]: m for m in json.load(fh)["museums"]}
    with open(os.path.join(ROOT, "commons", "data", "museum_50_fill.json"), encoding="utf-8") as fh:
        fills = {r["id"]: r for r in json.load(fh)["rooms"]}

    wrote = []
    print("PLACING — density per variant, hero first, then spread\n")
    for mid, m in museums.items():
        f = fills.get(mid)
        if not f or f["filled"] != f["slots"] or not f["filled"]:
            continue
        if not (odd_band(m["w"]) and odd_band(m["h"])):
            continue
        dens = DENSITY.get(m["variant"], 0.6)
        chosen, _ = pick(m["slots"], f["assignments"], dens)
        short = SHORT.get(m["pattern"], m["pattern"].split(":")[-1].split("#")[0][:10].title())
        name = "Fifty_%s_%s" % (short, f["sequence"][:14].title())
        room = {"map_name": name, "sequence": f["sequence"],
                "title": "%s — %s" % (short, f["sequence"])}
        doc = build_map(m, room, chosen)
        print("  %-5s %-30s %-16s %2dx%-3d  %2d of %2d slots (%.0f%%)  %s"
              % (mid, name, m["variant"], m["w"], m["h"], len(chosen), f["slots"],
                 100 * dens, ", ".join(a["token"] for a in chosen[:3])[:44]))
        if args.apply:
            d = os.path.join(ROOT, "commons", "maps", name)
            os.makedirs(d, exist_ok=True)
            with open(os.path.join(d, "map_data.json"), "w", encoding="utf-8") as fh:
                json.dump(doc, fh)
            subprocess.run([sys.executable, os.path.join(ROOT, "tools", "compact_map_json.py"),
                            os.path.join(d, "map_data.json")], cwd=ROOT, capture_output=True)
            wrote.append(name)
    if args.apply and wrote:
        print("\n  wrote %d map(s). checking each:" % len(wrote))
        for n in wrote:
            r = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "map_pathfinder.py"),
                                "check", n], cwd=ROOT, capture_output=True, text=True)
            ok = "0 FAIL" in (r.stdout or "")
            print("     %-30s %s" % (n, "pathfinder OK" if ok else "PATHFINDER FAILED"))
    elif not args.apply:
        print("\n  nothing written — pass --apply")
    return 0


if __name__ == "__main__":
    sys.exit(main())
