#!/usr/bin/env python3
"""EVERY CONFIGURATION OF ONE ROOM — the same plan, furnished every way.

2026-08-25, Palle: "can we make a live tool where we can flip through
different configurations for each map. I mean like a slide show for each map
with the configs?"

A placed room is one answer out of many. The plan is fixed — the walls are the
walls — but three dials move underneath it and nobody could see them turn:

    VARIANT   what kind of room this is, which decides WHICH SLOTS EXIST.
              A cabinet publishes its niches and refuses the middle; a
              free_plan publishes islands and refuses the walls. Change the
              variant and the room offers different places, not just different
              things in the same places.
    DENSITY   how much of what it offers is taken. 100% reads as everything
              that fit; 55% reads as chosen.
    ORDER     which artifact wins a slot when several fit. Tightest is the
              default, but largest-first and a rotation of the pool give
              genuinely different rooms from the same pool.

    python tools/map_configs.py --map=Placed_Color_02_Louisiana
    python tools/map_configs.py --map=... --json      # for /api/configs

Fast on purpose — it reads JSON and touches no engine, so a page can ask for
every configuration of a room and get them inside a second.

NOTHING IS WRITTEN. This is the flip-book; `--pick` is what would commit one,
and it is deliberately a separate act.
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
import place_spine as PS         # noqa: E402
import stamp_ready as SR         # noqa: E402

DENSITIES = [1.0, 0.75, 0.55, 0.35]
ORDERS = ["tightest", "largest", "rotate"]


def plans():
    """The buildings a room can be re-cut from — every named pattern whose width
    is already odd and in band. The window is chosen by floor area, so swapping
    plan gives the fullest room that building offers."""
    with open(os.path.join(ROOT, "commons", "data", "template_patterns.json"),
              encoding="utf-8") as fh:
        pats = json.load(fh)["patterns"]
    out = []
    for k, v in pats.items():
        if v.get("mode") != "stamp" or k.startswith(("lattice:", "beat:", "bay:")):
            continue
        if not PS.odd_band(v.get("w", 0)):
            continue
        wins = PS.windows(v["tile"], v["w"])
        if not wins:
            continue
        floor, wh, z0, tile = wins[0]
        out.append({"key": k, "label": v.get("label", k), "w": v["w"], "h": wh,
                    "floor": floor, "z0": z0, "tile": tile})
    out.sort(key=lambda r: -r["floor"])
    return out


def load_map(name):
    p = os.path.join(ROOT, "commons", "maps", name, "map_data.json")
    if not os.path.exists(p):
        return None
    with open(p, encoding="utf-8") as fh:
        return json.load(fh)


def as_tile(doc):
    """A map's structure back into the museum tile vocabulary the slot
    measurer speaks: 'w' and heights become '4' wall / '1' floor / '0' hole."""
    out = []
    for row in doc["layers"]["structure"]:
        line = []
        for v in row:
            s = str(v).strip()
            if s == "" or s == "0":
                line.append("0")
            elif s == "w" or s.startswith("4"):
                line.append("4")
            elif s and s[0] in "23p":
                line.append(s)
            else:
                line.append("1")
        out.append(line)
    return out


def order_pool(pool, shapes, how, turn):
    if how == "largest":
        return sorted(pool, key=lambda t: (-(shapes[t]["w"] * shapes[t]["d"]), t))
    if how == "rotate" and pool:
        k = turn % len(pool)
        s = sorted(pool)
        return s[k:] + s[:k]
    return sorted(pool)


def configs_for(name, plan_key=""):
    doc = load_map(name)
    if doc is None:
        return None
    meta = (doc.get("map_info") or {}).get("metadata") or {}
    seq = meta.get("sequence", "")
    all_plans = plans()
    chosen_plan = None
    if plan_key:
        chosen_plan = next((q for q in all_plans if q["key"] == plan_key), None)
        if chosen_plan is None:
            return {"error": "no such plan: %s" % plan_key}
    # THE PLAN IS A DIAL TOO. Without one the room keeps its own walls;
    # with one it is re-cut from that building and the slots are measured
    # afresh, because different walls offer different PLACES and not just
    # different things standing in the same ones.
    tile = chosen_plan["tile"] if chosen_plan else as_tile(doc)
    with open(os.path.join(ROOT, "commons", "data", "artifact_shapes.json"), encoding="utf-8") as fh:
        shapes = json.load(fh)["shapes"]
    seq_of = MS.registry_seq()
    pool = [t for t in shapes if seq in (seq_of.get(t) or [])]

    slots_all, grid = M50.slots_for(tile)
    runs = M50.runs_for(grid)
    out = []
    turn = 0
    for variant in M50.VARIANTS:
        pub = M50.thin(slots_all, runs, variant)
        if not pub:
            continue
        for how in ORDERS:
            ordered = order_pool(pool, shapes, how, turn)
            turn += 1
            assigns = MS.fill_one({"slots": pub}, ordered, shapes) if ordered else []
            for dens in DENSITIES:
                chosen, _ = PM.pick(pub, assigns, dens) if assigns else ([], {})
                if not chosen:
                    continue
                out.append({
                    "variant": variant, "density": dens, "order": how,
                    "why": M50.VARIANTS[variant]["why"],
                    "slots": len(pub), "placed": len(chosen),
                    # SLOT SIZE RIDES WITH THE ITEM: without it nothing
                    # downstream can compute waste, and a scorer that cannot
                    # see the slot ends up rewarding big artifacts instead of
                    # good fits (measured 2026-08-25, it picked a one-object
                    # room over a six-object one).
                    # WASTE AND SLOT AREA RIDE WITH THE ITEM. a["slot"] is an
                    # INDEX into pub, not a size — reading it as a size gave
                    # every item an area of 1 and let a scorer prefer a
                    # one-object room to a six-object one (measured 2026-08-25).
                    "items": [{"x": a["x"], "z": a["z"], "token": a["token"],
                               "kind": a["kind"], "waste": a.get("waste", 0),
                               "area": MS.slot_area(pub[a["slot"]])}
                              for a in chosen],
                })
    # the room as it stands today, so a configuration can be compared to it
    current = []
    for z, row in enumerate(doc["layers"].get("interactables", [])):
        for x, v in enumerate(row):
            t = str(v).strip()
            if t:
                current.append({"x": x, "z": z, "token": t.split("#")[0].split(":")[0]})
    if chosen_plan:
        drawn = [[("w" if c == "4" else c) for c in row] for row in tile]
    else:
        drawn = doc["layers"]["structure"]
    return {
        "map": name, "sequence": seq, "pool": len(pool),
        "plan": plan_key or meta.get("window", meta.get("plan", "")),
        "plans": [{"key": q["key"], "label": q["label"],
                   "size": "%dx%d" % (q["w"], q["h"]), "floor": q["floor"]}
                  for q in all_plans],
        "w": len(tile[0]), "h": len(tile),
        "structure": drawn,
        "current": current,
        "current_variant": meta.get("variant", ""),
        "current_density": meta.get("density", None),
        "configs": out,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", required=True)
    ap.add_argument("--plan", default="", help="re-cut the room from this building")
    ap.add_argument("--plans", action="store_true", help="list the buildings")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--pick", type=int, default=-1,
                    help="write configuration N into the map — a separate act on purpose")
    args = ap.parse_args()
    if args.plans:
        for q in plans():
            print("  %-44s %-7s floor %3d  %s" % (q["key"], "%dx%d" % (q["w"], q["h"]),
                                                  q["floor"], q["label"][:34]))
        return 0
    d = configs_for(args.map, args.plan)
    if d is None:
        print(json.dumps({"error": "no such map: %s" % args.map}) if args.json
              else "no such map: %s" % args.map)
        return 1
    if args.pick >= 0:
        if args.pick >= len(d["configs"]):
            print("only %d configuration(s)" % len(d["configs"]))
            return 1
        c = d["configs"][args.pick]
        p = os.path.join(ROOT, "commons", "maps", args.map, "map_data.json")
        doc = load_map(args.map)
        if args.plan:
            # A NEW PLAN IS A NEW ROOM. The walls change, so the map is REBUILT
            # rather than repopulated, and spawn and exit are placed afresh —
            # keeping the old utilities would leave a door in a wall.
            pl = next(q for q in plans() if q["key"] == args.plan)
            m = {"pattern": args.plan, "variant": c["variant"], "tile": pl["tile"],
                 "w": pl["w"], "h": pl["h"]}
            room = {"map_name": args.map, "sequence": d["sequence"],
                    "title": (doc.get("map_info") or {}).get("title", args.map)}
            doc = PM.build_map(m, room, [{"x": it["x"], "z": it["z"], "token": it["token"]}
                                         for it in c["items"]])
            doc["map_info"]["metadata"]["window"] = ("%s rows %d..%d"
                                                     % (args.plan, pl["z0"],
                                                        pl["z0"] + pl["h"] - 1))
            st = doc["layers"]["structure"]
            keep = {(x, z) for x, z in SR.analyse(doc)["blocked"]}
            saved = {(x, z): st[z][x] for (x, z) in keep}
            SR.wall_border(st)
            for (x, z), v in saved.items():
                st[z][x] = v
        else:
            inter = doc["layers"]["interactables"]
            for row in inter:
                for i in range(len(row)):
                    row[i] = ""
            for it in c["items"]:
                inter[it["z"]][it["x"]] = it["token"]
        doc["map_info"].setdefault("metadata", {}).update(
            {"variant": c["variant"], "density": c["density"], "order": c["order"],
             "n_artifacts": len(c["items"]), "source": "tools/map_configs.py --pick"})
        with open(p, "w", encoding="utf-8") as fh:
            json.dump(doc, fh)
        subprocess.run([sys.executable, os.path.join(ROOT, "tools", "compact_map_json.py"), p],
                       cwd=ROOT, capture_output=True)
        ok = SR.check_map(args.map)
        print("wrote config %d into %s - %s at %d%%, %d artifact(s)%s - pathfinder %s"
              % (args.pick, args.map, c["variant"], int(c["density"] * 100), len(c["items"]),
                 (" on plan " + args.plan) if args.plan else "", "OK" if ok else "FAILED"))
        return 0 if ok else 1
    if args.json:
        print(json.dumps(d))
        return 0
    print("%s — %s, pool of %d, %d configuration(s)\n"
          % (d["map"], d["sequence"], d["pool"], len(d["configs"])))
    print("  %-3s %-10s %-8s %-8s %s" % ("#", "variant", "density", "order", "placed / slots"))
    for i, c in enumerate(d["configs"]):
        print("  %-3d %-10s %-8s %-8s %d / %d"
              % (i, c["variant"], "%d%%" % int(c["density"] * 100), c["order"],
                 c["placed"], c["slots"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
