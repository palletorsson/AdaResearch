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

DENSITIES = [1.0, 0.75, 0.55, 0.35]
ORDERS = ["tightest", "largest", "rotate"]


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


def configs_for(name):
    doc = load_map(name)
    if doc is None:
        return None
    meta = (doc.get("map_info") or {}).get("metadata") or {}
    seq = meta.get("sequence", "")
    tile = as_tile(doc)
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
                    "items": [{"x": a["x"], "z": a["z"], "token": a["token"],
                               "kind": a["kind"]} for a in chosen],
                })
    # the room as it stands today, so a configuration can be compared to it
    current = []
    for z, row in enumerate(doc["layers"].get("interactables", [])):
        for x, v in enumerate(row):
            t = str(v).strip()
            if t:
                current.append({"x": x, "z": z, "token": t.split("#")[0].split(":")[0]})
    return {
        "map": name, "sequence": seq, "pool": len(pool),
        "w": len(tile[0]), "h": len(tile),
        "structure": doc["layers"]["structure"],
        "current": current,
        "current_variant": meta.get("variant", ""),
        "current_density": meta.get("density", None),
        "configs": out,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", required=True)
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--pick", type=int, default=-1,
                    help="write configuration N into the map — a separate act on purpose")
    args = ap.parse_args()
    d = configs_for(args.map)
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
        print("wrote config %d into %s — %s at %d%%, %d artifact(s)"
              % (args.pick, args.map, c["variant"], int(c["density"] * 100), len(c["items"])))
        return 0
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
