#!/usr/bin/env python3
"""ONE PLACED MUSEUM PER SPINE SEQUENCE, FROM COLOR ONWARD.

2026-08-25, Palle: "try to place all spine sequence maps after transformation
in the same way and show me."

The same chain as tools/place_museums.py, run across the spine: a real
building plan becomes a room, the room is measured for slots, the slots are
filled from that sequence's own artifacts, and the result is written as a map
that passes the pathfinder.

WHY IT CUTS WINDOWS. Only 8 of the 182 template patterns are already legal
maps — odd, 9-19 on both axes — and 20 sequences need 20 distinct rooms. But a
`bay:` in that file IS a window cut from a bigger plan, so this cuts more the
same way: the tallest in-band window of each building, chosen by floor area.
A window of the Uffizi is still the Uffizi.

    python tools/place_spine.py            # what it would write
    python tools/place_spine.py --apply

DENSITY, not capacity — the same claim place_museums.py makes. A room filled
to 100% reads as everything that fit; a room at 60% reads as chosen.
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import museum_50 as M50          # noqa: E402
import match_slots as MS         # noqa: E402
import place_museums as PM       # noqa: E402
import stamp_ready as SR         # noqa: E402

BAND = (9, 19)


def odd_band(n):
    return BAND[0] <= n <= BAND[1] and n % 2 == 1


def windows(tile, w):
    """Every in-band window of this plan, tallest first, ranked by floor."""
    h = len(tile)
    out = []
    for wh in (19, 17, 15, 13, 11, 9):
        if wh > h:
            continue
        for z0 in range(0, h - wh + 1):
            win = [row[:] for row in tile[z0:z0 + wh]]
            floor = sum(1 for r in win for c in r if str(c).strip() in ("1", "1s"))
            out.append((floor, wh, z0, win))
        if out:
            break
    out.sort(key=lambda r: -r[0])
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    with open(os.path.join(ROOT, "commons", "maps", "curriculum_spine.json"), encoding="utf-8") as fh:
        spine = [s["name"] for s in json.load(fh)["spine"]["sequences"]]
    after = spine[spine.index("transformation") + 1:]

    pats = json.load(open(os.path.join(ROOT, "commons", "data", "template_patterns.json"),
                          encoding="utf-8"))["patterns"]
    named = [(k, v) for k, v in pats.items()
             if v.get("mode") == "stamp" and not k.startswith(("lattice:", "beat:", "bay:"))
             and odd_band(v.get("w", 0))]
    named.sort(key=lambda t: -(t[1]["w"] * len(t[1]["tile"])))

    shapes = json.load(open(os.path.join(ROOT, "commons", "data", "artifact_shapes.json"),
                            encoding="utf-8"))["shapes"]
    seq_of = MS.registry_seq()
    variants = list(M50.VARIANTS.keys())

    print("PLACING THE SPINE AFTER TRANSFORMATION — %d sequence(s)\n" % len(after))
    print("  %-22s %-34s %-10s %-7s %s" % ("sequence", "plan window", "variant", "size", "placed"))
    wrote, skipped = [], []
    for i, seq in enumerate(after):
        key, pat = named[i % len(named)]
        wins = windows(pat["tile"], pat["w"])
        if not wins:
            skipped.append((seq, key, "no in-band window"))
            continue
        floor, wh, z0, tile = wins[0]
        variant = variants[i % len(variants)]
        slots, grid = M50.slots_for(tile)
        runs = M50.runs_for(grid)
        pub = M50.thin(slots, runs, variant)
        pool = [t for t in shapes if seq in (seq_of.get(t) or [])]
        m = {"id": "s%02d" % (i + 1), "pattern": key, "variant": variant,
             "w": len(tile[0]), "h": len(tile), "slots": pub, "tile": tile}
        assigns = MS.fill_one(m, pool, shapes) if pool else []
        dens = PM.DENSITY.get(variant, 0.6)
        chosen, _ = PM.pick(pub, assigns, dens) if assigns else ([], {})
        short = key.split("-")[0].replace(":", "_").title()[:12]
        name = "Spine_%s_%s" % (seq[:16].title(), short)
        print("  %-22s %-34s %-10s %2dx%-3d  %2d of %2d slot(s)%s"
              % (seq, "%s z%d" % (key[:26], z0), variant, len(tile[0]), len(tile),
                 len(chosen), len(pub), "" if pool else "   <- EMPTY POOL"))
        if not chosen:
            skipped.append((seq, key, "pool of %d" % len(pool)))
            continue
        room = {"map_name": name, "sequence": seq,
                "title": "%s — %s" % (short, seq)}
        doc = PM.build_map(m, room, chosen)
        doc["map_info"]["metadata"]["window"] = "%s rows %d..%d" % (key, z0, z0 + wh - 1)
        if args.apply:
            d = os.path.join(ROOT, "commons", "maps", name)
            os.makedirs(d, exist_ok=True)
            p = os.path.join(d, "map_data.json")
            with open(p, "w", encoding="utf-8") as fh:
                json.dump(doc, fh)
            # close the shell — a window cut from a plan has open edges where
            # it met the rest of the building
            fresh = json.load(open(p, encoding="utf-8"))
            st = fresh["layers"]["structure"]
            keep = {(x, z) for x, z in SR.analyse(fresh)["blocked"]}
            saved = {(x, z): st[z][x] for (x, z) in keep}
            SR.wall_border(st)
            for (x, z), v in saved.items():
                st[z][x] = v
            with open(p, "w", encoding="utf-8") as fh:
                json.dump(fresh, fh)
            subprocess.run([sys.executable, os.path.join(ROOT, "tools", "compact_map_json.py"), p],
                           cwd=ROOT, capture_output=True)
            wrote.append((name, seq, len(chosen)))

    if args.apply and wrote:
        print("\n  wrote %d map(s), checking each:" % len(wrote))
        bad = 0
        for name, seq, n in wrote:
            ok = SR.check_map(name)
            a = SR.analyse(json.load(open(os.path.join(ROOT, "commons", "maps", name,
                                                       "map_data.json"), encoding="utf-8")))
            ready = (not a["gaps"]) and a["band"]
            if not ok:
                bad += 1
            print("     %-38s %2d artifact(s)  %-14s %s" % (name, n,
                  "pathfinder OK" if ok else "PATHFINDER FAILED",
                  "READY" if ready else "%d gap(s)" % len(a["gaps"])))
        print("\n  %d of %d passed" % (len(wrote) - bad, len(wrote)))
    if skipped:
        print("\n  %d sequence(s) got no room:" % len(skipped))
        for seq, key, why in skipped:
            print("     %-22s %s" % (seq, why))
    if not args.apply:
        print("\n  nothing written — pass --apply")
    return 0


if __name__ == "__main__":
    sys.exit(main())
