#!/usr/bin/env python3
"""PICK THE BEST CONFIGURATION FOR EACH ROOM — and say what "best" means.

2026-08-25, Palle: "pick the best config for each map."

Every other tool here refused to choose. This one chooses, so the whole of the
judgement is in one place where it can be read and argued with:

  FIT       the mean waste per artifact, as a share of the slot it sits in.
            A 1x1 in a 5x5 hero is a fit and a mistake. Lower is better.
  SPREAD    mean pairwise distance between placements over the room's
            diagonal. A room whose things all cluster in one corner is a
            worse room than the same things spread. Higher is better.
  VARIETY   how many distinct slot KINDS are used. A room with a hero, two
            plinths and a run reads richer than eleven identical wall slots,
            even at the same count. Higher is better.
  OCCUPANCY how close the count is to one thing per 25 floor cells. Measured
            against the ROOM, never against the variant's own offer — density
            is relative, so a drum publishing one slot reads as "100% full",
            and scoring on that let the emptiest possible room win.
  BREATH    a curve on density, peaking at 0.6 and falling off both sides.
            Pure taste, and weighted lowest so taste cannot outvote measurement.

    score = 0.28*(1-fit) + 0.22*spread + 0.15*variety + 0.25*occ + 0.10*breath

TWO BUGS THIS SCORE HAD, both caught by running it once and reading the top
row rather than trusting it: FIT was not measuring fit — the config carried a
slot INDEX, not a slot size, so every item read as area 1 and the term simply
rewarded large artifacts. And a lone item was given a neutral 0.5 for SPREAD,
which it has not got. Together they made a drum holding ONE object beat a
six-object enfilade, and the tool would have emptied every room in the corpus.

    python tools/best_config.py                    # what it would choose
    python tools/best_config.py --map=X --verbose  # and why, for one room
    python tools/best_config.py --apply            # commit the choices

THE WEIGHTS ARE A CLAIM, NOT A FACT. They say fit matters most and density
taste matters least. Disagree by changing four numbers — and the report prints
every component per room, so a bad choice can be traced to the term that made
it rather than to the tool as a whole.

Searches each room's OWN plan. The buildings were assigned deliberately, one
per room, and re-cutting all of them from the highest-scoring plan would make
165 rooms into one building repeated.
"""
from __future__ import annotations

import argparse
import json
import math
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import map_configs as MC          # noqa: E402

W_FIT, W_SPREAD, W_VARIETY, W_OCC, W_BREATH = 0.28, 0.22, 0.15, 0.25, 0.10
BREATH_PEAK = 0.6


def score(cfg, room, shapes):
    items = cfg["items"]
    n = len(items)
    if not n:
        return None
    # FIT — the real waste, as a share of the slot it sits in
    waste = []
    for it in items:
        area = max(1, int(it.get("area", 1)))
        waste.append(max(0.0, min(1.0, float(it.get("waste", 0)) / area)))
    fit = sum(waste) / n

    # SPREAD — mean pairwise distance over the diagonal
    diag = math.hypot(room["w"], room["h"]) or 1.0
    if n > 1:
        tot = c = 0.0
        for i in range(n):
            for j in range(i + 1, n):
                tot += math.hypot(items[i]["x"] - items[j]["x"], items[i]["z"] - items[j]["z"])
                c += 1
        spread = min(1.0, (tot / c) / (diag * 0.5))
    else:
        # ONE ITEM HAS NO SPREAD. A neutral 0.5 was a gift that let a drum with
        # a single perfectly-fitted object outscore a six-object enfilade — the
        # scorer preferring the emptiest room it could find.
        spread = 0.0

    variety = len({it.get("kind", "field") for it in items}) / 6.0
    # OCCUPANCY against the ROOM, not the variant's own offer. Density is
    # RELATIVE — a drum publishes one slot, so filling it reads as "100%" — and
    # comparing variants on a relative number lets the emptiest room win. The
    # room wants roughly one thing per 25 floor cells.
    floor = 0
    for row in room["structure"]:
        for c2 in row:
            v = str(c2).strip()
            if v and v != "0" and v != "w" and not v.startswith("4"):
                floor += 1
    ideal = max(2.0, floor / 25.0)
    occ = max(0.0, 1.0 - abs(n - ideal) / max(ideal, 6.0))
    breath = max(0.0, 1.0 - abs(cfg["density"] - BREATH_PEAK) / 0.65)
    total = (W_FIT * (1 - fit) + W_SPREAD * spread + W_VARIETY * variety
             + W_OCC * occ + W_BREATH * breath)
    return {"score": total, "fit": fit, "spread": spread, "variety": variety,
            "occ": occ, "breath": breath, "n": n, "ideal": ideal}


def best_for(name, shapes, verbose=False):
    d = MC.configs_for(name)
    if not d or d.get("error") or not d.get("configs"):
        return None
    rows = []
    for i, c in enumerate(d["configs"]):
        s = score(c, d, shapes)
        if s:
            rows.append((s["score"], i, c, s))
    if not rows:
        return None
    rows.sort(key=lambda r: -r[0])
    if verbose:
        print("\n  %s — %d configuration(s), top 8:" % (name, len(d["configs"])))
        print("    %-4s %-10s %-6s %-9s %4s %5s %5s %5s %5s %6s"
              % ("#", "variant", "dens", "order", "n", "fit", "sprd", "vary", "occ", "score"))
        for sc, i, c, s in rows[:8]:
            print("    %-4d %-10s %-6s %-9s %4d %5.2f %5.2f %5.2f %5.2f %6.3f"
                  % (i, c["variant"], "%d%%" % int(c["density"] * 100), c["order"],
                     s["n"], s["fit"], s["spread"], s["variety"], s["occ"], sc))
    sc, i, c, s = rows[0]
    return {"index": i, "config": c, "stats": s, "total": len(d["configs"]),
            "current": len(d.get("current") or []),
            "current_variant": d.get("current_variant", "")}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", default="")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    with open(os.path.join(ROOT, "commons", "data", "artifact_shapes.json"), encoding="utf-8") as fh:
        shapes = json.load(fh)["shapes"]
    if args.map:
        names = [args.map]
    else:
        p = os.path.join(ROOT, "commons", "maps", "sequences", "placed_museums.json")
        with open(p, encoding="utf-8") as fh:
            names = json.load(fh)["sequences"]["placed_museums"]["maps"]

    print("BEST CONFIG — %.2f fit + %.2f spread + %.2f variety + %.2f occupancy + %.2f breath\n"
          % (W_FIT, W_SPREAD, W_VARIETY, W_OCC, W_BREATH))
    if not args.verbose:
        print("  %-38s %-10s %-6s %-9s %4s %6s %s"
              % ("map", "variant", "dens", "order", "n", "score", "was"))
    changed = kept = 0
    for name in names:
        b = best_for(name, shapes, args.verbose)
        if not b:
            print("  %-38s no configuration" % name)
            continue
        c, s = b["config"], b["stats"]
        same = (c["variant"] == b["current_variant"] and s["n"] == b["current"])
        if same:
            kept += 1
        else:
            changed += 1
        if not args.verbose:
            print("  %-38s %-10s %-6s %-9s %4d %6.3f %s"
                  % (name[:38], c["variant"], "%d%%" % int(c["density"] * 100), c["order"],
                     s["n"], s["score"],
                     "unchanged" if same else "%s/%d" % (b["current_variant"] or "?", b["current"])))
        if args.apply and not same:
            r = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "map_configs.py"),
                                "--map=%s" % name, "--pick", str(b["index"])],
                               cwd=ROOT, capture_output=True, text=True)
            if r.returncode != 0:
                print("     !! %s" % (r.stdout or r.stderr or "").strip()[:120])
    print("\n  %d room(s) would change, %d already best" % (changed, kept)
          if not args.apply else "\n  %d room(s) changed, %d already best" % (changed, kept))
    if not args.apply:
        print("  nothing written — pass --apply")
    return 0


if __name__ == "__main__":
    sys.exit(main())
