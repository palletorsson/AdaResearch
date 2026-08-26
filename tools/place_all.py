#!/usr/bin/env python3
"""EVERY MAP OF EVERY SEQUENCE, PLACED.

2026-08-25, Palle: "for each sequence make all maps."

place_spine.py made one room per sequence — a sample. This makes as many as
the sequence itself has maps: color has 7 in the spine, so color gets 7;
softbodies has 34, so softbodies gets 34. The museum ends up the same shape as
the curriculum instead of a summary of it.

    python tools/place_all.py                 # what it would write
    python tools/place_all.py --apply
    python tools/place_all.py --sequence=color --apply

ADDITIVE. The rooms already placed count toward the target, so the nineteen
written earlier stay exactly as they are and only the remainder is new.

EACH ROOM GETS A DIFFERENT BUILDING AND A DIFFERENT VARIANT, cycling both, so
a sequence with fourteen rooms is fourteen different offers rather than one
plan copied. And each draws from the pool the earlier rooms LEFT — an artifact
is placed once per sequence, so room seven holds what rooms one to six did not.

WHERE IT WILL FALL SHORT, and this is the point rather than a defect: a
sequence cannot furnish more rooms than it has artifacts. change has a pool of
2 and wants 4 rooms; formfinding has 0 and wants 7. The run reports the
shortfall per sequence, which is the same measurement the fold ledger, the
thickening pass and the fifty-museum fill all arrived at from elsewhere.
"""
from __future__ import annotations

import argparse
import glob
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import museum_50 as M50          # noqa: E402
import match_slots as MS         # noqa: E402
import place_museums as PM       # noqa: E402
import place_spine as PS         # noqa: E402
import stamp_ready as SR         # noqa: E402

MIN_PLACED = 1     # a room with nothing in it is not a room


def existing_by_sequence():
    """What is already placed, so this run only writes the remainder."""
    out = {}
    for p in glob.glob(os.path.join(ROOT, "commons", "maps", "*", "map_data.json")):
        try:
            with open(p, encoding="utf-8") as fh:
                doc = json.load(fh)
        except Exception:
            continue
        meta = (doc.get("map_info") or {}).get("metadata") or {}
        if not str(meta.get("source", "")).startswith("tools/place_"):
            continue
        seq = meta.get("sequence", "")
        name = os.path.basename(os.path.dirname(p))
        rec = out.setdefault(seq, {"rooms": [], "tokens": set()})
        rec["rooms"].append(name)
        for row in (doc.get("layers") or {}).get("interactables", []):
            for c in row:
                t = str(c).strip()
                if t:
                    rec["tokens"].add(t.split("#")[0].split(":")[0])
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--sequence", default="")
    ap.add_argument("--cap", type=int, default=40, help="most rooms to add per sequence")
    args = ap.parse_args()

    with open(os.path.join(ROOT, "commons", "maps", "curriculum_spine.json"), encoding="utf-8") as fh:
        spine = [s["name"] for s in json.load(fh)["spine"]["sequences"]]
    after = spine[spine.index("transformation") + 1:]
    if args.sequence:
        after = [s for s in after if s == args.sequence]

    pats = json.load(open(os.path.join(ROOT, "commons", "data", "template_patterns.json"),
                          encoding="utf-8"))["patterns"]
    named = [(k, v) for k, v in pats.items()
             if v.get("mode") == "stamp" and not k.startswith(("lattice:", "beat:", "bay:"))
             and PS.odd_band(v.get("w", 0))]
    named.sort(key=lambda t: -(t[1]["w"] * len(t[1]["tile"])))

    shapes = json.load(open(os.path.join(ROOT, "commons", "data", "artifact_shapes.json"),
                            encoding="utf-8"))["shapes"]
    seq_of = MS.registry_seq()
    variants = list(M50.VARIANTS.keys())
    have = existing_by_sequence()

    print("PLACE ALL — a room for every map the sequence has\n")
    print("  %-22s %5s %5s %5s %6s  %s" % ("sequence", "want", "have", "pool", "adding", ""))
    plan_i = 0
    wrote, short = [], []
    for seq in after:
        p = os.path.join(ROOT, "commons", "maps", "sequences", "%s.json" % seq)
        if not os.path.exists(p):
            continue
        with open(p, encoding="utf-8") as fh:
            doc = json.load(fh)
        blk = doc["sequences"]
        blk = blk[0] if isinstance(blk, list) else (blk.get(seq) or list(blk.values())[0])
        want = len(blk.get("maps", []))
        rec = have.get(seq) or {"rooms": [], "tokens": set()}
        pool = [t for t in shapes if seq in (seq_of.get(t) or []) and t not in rec["tokens"]]
        todo = max(0, min(args.cap, want - len(rec["rooms"])))
        print("  %-22s %5d %5d %5d %6d" % (seq, want, len(rec["rooms"]), len(pool), todo))
        made = 0
        used = set(rec["tokens"])
        for n in range(todo):
            if not pool:
                break
            key, pat = named[plan_i % len(named)]
            plan_i += 1
            wins = PS.windows(pat["tile"], pat["w"])
            if not wins:
                continue
            _floor, wh, z0, tile = wins[(n // len(named)) % len(wins)]
            variant = variants[(len(rec["rooms"]) + n) % len(variants)]
            slots, grid = M50.slots_for(tile)
            runs = M50.runs_for(grid)
            pub = M50.thin(slots, runs, variant)
            live = [t for t in pool if t not in used]
            if not live:
                break
            m = {"id": "a", "pattern": key, "variant": variant, "w": len(tile[0]),
                 "h": len(tile), "slots": pub, "tile": tile}
            assigns = MS.fill_one(m, live, shapes)
            chosen, _ = PM.pick(pub, assigns, PM.DENSITY.get(variant, 0.6))
            if len(chosen) < MIN_PLACED:
                continue
            short_plan = key.split("-")[0].title()[:12]
            name = "Placed_%s_%02d_%s" % (seq[:16].title(), len(rec["rooms"]) + made + 1, short_plan)
            room = {"map_name": name, "sequence": seq, "title": "%s %d — %s"
                    % (short_plan, len(rec["rooms"]) + made + 1, seq)}
            mapdoc = PM.build_map(m, room, chosen)
            mapdoc["map_info"]["metadata"]["window"] = "%s rows %d..%d" % (key, z0, z0 + wh - 1)
            for a in chosen:
                used.add(a["token"])
            made += 1
            wrote.append((name, seq, len(chosen)))
            if args.apply:
                d = os.path.join(ROOT, "commons", "maps", name)
                os.makedirs(d, exist_ok=True)
                fp = os.path.join(d, "map_data.json")
                with open(fp, "w", encoding="utf-8") as fh:
                    json.dump(mapdoc, fh)
                fresh = json.load(open(fp, encoding="utf-8"))
                st = fresh["layers"]["structure"]
                keep = {(x, z) for x, z in SR.analyse(fresh)["blocked"]}
                saved = {(x, z): st[z][x] for (x, z) in keep}
                SR.wall_border(st)
                for (x, z), v in saved.items():
                    st[z][x] = v
                with open(fp, "w", encoding="utf-8") as fh:
                    json.dump(fresh, fh)
                subprocess.run([sys.executable, os.path.join(ROOT, "tools", "compact_map_json.py"), fp],
                               cwd=ROOT, capture_output=True)
                blurb = ("%s\n\n%s\n\nA window of `%s`, %dx%d, walled and odd on both axes. "
                         "%d artifact%s from %s, at %d%% of what the room could take.\n"
                         % (room["title"], (M50.VARIANTS.get(variant) or {}).get("why", ""),
                            key, len(tile[0]), len(tile), len(chosen),
                            "" if len(chosen) == 1 else "s", seq,
                            int(PM.DENSITY.get(variant, 0.6) * 100)))
                with open(os.path.join(d, "blurb.md"), "w", encoding="utf-8") as fh:
                    fh.write(blurb)
        if made < todo:
            short.append((seq, want, len(rec["rooms"]) + made, len(pool)))

    print("\n  %d room(s) %s" % (len(wrote), "written" if args.apply else "would be written"))
    if short:
        print("\n  %d sequence(s) could not reach their map count:" % len(short))
        for seq, want, got, pool in short:
            print("     %-22s wants %2d, has %2d — pool of %d ran out" % (seq, want, got, pool))
    if args.apply and wrote:
        bad = 0
        for name, _s, _n in wrote:
            if not SR.check_map(name):
                bad += 1
                print("     PATHFINDER FAILED: %s" % name)
        print("\n  %d of %d pass the pathfinder" % (len(wrote) - bad, len(wrote)))
    if not args.apply:
        print("\n  nothing written — pass --apply")
    return 0


if __name__ == "__main__":
    sys.exit(main())
