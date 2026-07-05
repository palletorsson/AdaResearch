#!/usr/bin/env python3
"""modkit.py — the modular staging system (R-017): slots with size contracts,
seeded fills.

Reads commons/data/station_modules.json: templates are named SLOT layouts; every
slot carries a kind and a size contract. The seeder fills a template from pools —
HERO and CHILD slots from the artifact's own family (concept-ladder), POOL slots
from the DNA/prop pools — with a deterministic seed, so the SAME wall can be
seeded into DIFFERENT configurations. Any prop fits: the fit rule routes it to a
compatible slot class (S/M/L by measured base_m) and the class's footing
normalizes the seat. Output = wall-cluster format -> the whole capture/review/
place pipeline applies.

Usage:
  python tools/modkit.py --hero=distribution_sampler --seeds=1,2,3 --write
Emits clusters/mk_<hero>_s<seed>.json per seed.
"""
from __future__ import annotations

import json
import os
import random
import sys
import urllib.request

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC = os.path.join(REPO, "commons", "data", "station_modules.json")
SIZES = os.path.join(REPO, "commons", "data", "artifact_sizes.json")
CLUSTERS = os.path.join(REPO, "commons", "data", "curated_walls", "clusters")
LADDER = "http://localhost:3003/api/concept-ladder?id="

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass


def load_json(p):
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def family_of(hero):
    """children pool from the concept ladder, classed by measured size."""
    try:
        t = json.load(urllib.request.urlopen(LADDER + hero, timeout=15)).get("tiers", {}) or {}
    except Exception:
        t = {}
    fam = []
    for k in ("small", "medium", "large", "applied"):
        fam += [x for x in t.get(k, []) if x != hero]
    seen = []
    for x in fam:
        if x not in seen:
            seen.append(x)
    return seen


def classify(name, sizes, classes):
    b = float((sizes.get(name.split("#")[0]) or {}).get("base_m", 1.0) or 1.0)
    for cls in ("S", "M", "L", "XL"):
        if b <= classes[cls]["max_base"]:
            return cls, b
    return "XL", b


def seed_station(hero, template, spec, sizes, seed):
    rng = random.Random(seed)
    classes = spec["classes"]
    pools = spec["pools"]
    fam = family_of(hero)
    rng.shuffle(fam)
    # class the family for CHILD slots
    fam_by = {"S": [], "M": [], "L": []}
    for f in fam:
        cls, _ = classify(f, sizes, classes)
        if cls in fam_by:
            fam_by[cls].append(f)

    P = []
    def add(token, x, y, z, wall=False, **cfg):
        p = {"token": token, "x": x, "y": y, "z": z, "wall": wall}
        if cfg:
            p["config"] = cfg
        P.append(p)

    def seat(cls_name, x, z, caption, low=False):
        c = classes[cls_name]
        cfg = dict(c["footing_config"])
        if low:
            cfg["top_height"] = 0.5
        cfg["caption_text"] = caption
        add(c["footing"], x, 0.0, z, **cfg)
        return 0.5 if low else c["seat_y"]

    for slot in template["slots"]:
        kind = slot["kind"]
        x, z = slot.get("x", 0), slot.get("z", 0)
        if kind == "WALL":
            add("station_wall", x, 0.0, z, wall=True, width_cells=slot.get("width_cells", 5))
        elif kind == "PANEL":
            add("station_panel", x, slot.get("y", 2.3), z, wall=True,
                width_cells=slot.get("width_cells", 5),
                header=hero.replace("_", " ").upper(),
                lines=[f"Modular station, seed {seed} — same slots, different fill.",
                       "Every prop fits its size class; the seed picks the cast."])
        elif kind == "HERO":
            cls, b = classify(hero, sizes, classes)
            use = cls if cls in ("S", "M", "L") else "L"
            y = seat(use, x, z, hero.replace("_", " "))
            add(hero, x, y, z)
        elif kind.startswith("CHILD:"):
            want = kind.split(":")[1]
            pick = (fam_by.get(want) or fam_by.get("M") or fam_by.get("S") or [None])
            name = pick.pop(0) if pick else None
            if name:
                y = seat(want, x, z, name.replace("_", " "))
                add(name, x, y, z)
        elif kind.startswith("POOL:"):
            pool = pools.get(kind.split(":")[1], [])
            if not pool:
                continue
            token = rng.choice(pool)
            if "surreal_lab#" in token:
                token += f"#seed:{seed}"
            if slot.get("seat") == "M":
                y = seat("M", x, z, token.split("#")[0].replace("_", " "))
                add(token, x, y, z)
            elif slot.get("seat") == "M_low":
                y = seat("M", x, z, token.split("#")[0].replace("_", " "), low=True)
                add(token, x, y, z)
            else:
                add(token, x, slot.get("y", 0.0), z, wall=bool(slot.get("wall")))
    return P


def main():
    args = sys.argv[1:]
    hero = next((a.split("=", 1)[1] for a in args if a.startswith("--hero=")), None)
    seeds = next((a.split("=", 1)[1] for a in args if a.startswith("--seeds=")), "1")
    tname = next((a.split("=", 1)[1] for a in args if a.startswith("--template=")), "bench_v1")
    write = "--write" in args
    if not hero:
        print(__doc__)
        return 1
    spec = load_json(SPEC)
    sizes = (load_json(SIZES) or {}).get("sizes") or {}
    template = spec["templates"][tname]
    made = []
    for s in [int(x) for x in seeds.split(",") if x.strip()]:
        P = seed_station(hero, template, spec, sizes, s)
        name = f"mk_{hero}_s{s}"
        print(f"  {name}: {len(P)} pieces "
              f"({', '.join(p['token'].split('#')[0] for p in P if not p['token'].startswith('station_'))})")
        if write:
            with open(os.path.join(CLUSTERS, name + ".json"), "w", encoding="utf-8") as f:
                json.dump({"name": name,
                           "source": "modkit auto-seed (station_modules.json)",
                           "pieces": P}, f, indent=1)
            made.append(name)
    if made:
        sys.path.insert(0, os.path.join(REPO, "tools"))
        from book_log import log_event
        log_event("stage", f"modkit seeded {hero} x{len(made)} configurations "
                           f"({', '.join(made)}) — same slot template, different fill (R-017)")
    if not write:
        print("(dry run — pass --write)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
