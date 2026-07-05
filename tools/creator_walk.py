#!/usr/bin/env python3
"""creator_walk.py — the final map-space generator: a first-person creator walk (R-013).

You start at 0,0 as the creator of the fantasy space. The rolling tray holds the
chapter in necklace order — the hand-cut walk interleaved with the curated wall
works. You walk along z in ~3-cell strides and place item by item; every placement
STAMPS its footprint into the occupancy grid, so spacing is right by construction.
Wall works go left or right, rotated INWARD so they read along z. Heroes and
large/applied citizens raise their own dais (the intelligent floor). Then you walk
back and enrich: concept chalkboards, crates, extinguishers, whiteboards — the
lab vernacular — in the empty beats. The room is the concept's imaginative
science laboratory.

Phases: (1) the walk (place+stamp) · (2) the walk-back (enrich) · (3) read it
(pathfinder; then fold_ride files the ride into the chapter).

Usage:
  python tools/creator_walk.py --seq=primitives [--map=Hangar_Primitives] [--write]
"""
from __future__ import annotations

import json
import math
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.environ.get("ADA_ENCYCLOPEDIA_PATH", "C:/Users/palle/Documents/GitHub/ada_encyclopedia")
TUTORIAL_DIR = os.path.join(ENC, "public", "tutorial")
CURATED_DIR = os.path.join(REPO, "commons", "data", "curated_walls")
CLUSTERS_DIR = os.path.join(CURATED_DIR, "clusters")
SIZES = os.path.join(REPO, "commons", "data", "artifact_sizes.json")
REG_DIR = os.path.join(REPO, "commons", "artifacts", "registry")
MAPS_DIR = os.path.join(REPO, "commons", "maps")

CX = 10                 # corridor center column; corridor = CX-1..CX+1
STRIDE = 3              # the librarian's step
WALL_GAP = 2            # breath between wall works
LAB_PROPS = ["station_crates", "fire_extinguisher", "whiteboard", "lab_stool",
             "hangar_supply_pile", "tech_crate"]

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass


def load_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def registry_names() -> set[str]:
    out = set()
    for f in os.listdir(REG_DIR):
        if f.endswith(".json"):
            d = load_json(os.path.join(REG_DIR, f)) or {}
            arts = d.get("artifacts") if isinstance(d.get("artifacts"), dict) else d
            out |= {k for k, v in arts.items() if isinstance(v, dict)}
    return out


def main() -> int:
    args = sys.argv[1:]
    seq = next((a.split("=", 1)[1] for a in args if a.startswith("--seq=")), None)
    if not seq:
        print(__doc__)
        return 1
    map_name = next((a.split("=", 1)[1] for a in args if a.startswith("--map=")),
                    f"Hangar_{seq.capitalize()}")
    write = "--write" in args

    t = load_json(os.path.join(TUTORIAL_DIR, f"{seq}.json")) or {}
    walk, maps_order, blanks = [], [], t.get("blanks") or []
    for p in t.get("pages", []):
        if p["kind"] == "primitive" and isinstance(p.get("artifact"), dict):
            walk.append(p["artifact"]["name"])
        elif p["kind"] == "walk":
            walk += [a["name"] for a in p.get("artifacts") or []]
        elif p["kind"] == "world":
            maps_order = [m.get("name") for m in p.get("maps") or []]
    if not walk:
        print(f"!! no walk for {seq}")
        return 1
    sizes = (load_json(SIZES) or {}).get("sizes") or {}
    reg = registry_names()

    def base_of(name):
        e = sizes.get(name)
        return float(e.get("base_m", 1.0)) if isinstance(e, dict) else 1.0

    # ── the tray: curated wall works anchored into the necklace ────────────────
    walls_mode = next((a.split("=", 1)[1] for a in args if a.startswith("--walls=")), "all")
    walls = []
    for f in sorted(os.listdir(CURATED_DIR)):
        if not f.endswith(".json"):
            continue
        d = load_json(os.path.join(CURATED_DIR, f))
        if not isinstance(d, dict) or d.get("sequence") != seq:
            continue
        wmap = f[:-5]
        cname = "pw_" + wmap.lower()
        cpath = os.path.join(CLUSTERS_DIR, cname + ".json")
        if not os.path.exists(cpath):
            # curated wall without a resolver cluster — export it on the fly
            with open(cpath, "w", encoding="utf-8") as cf:
                json.dump({"name": cname,
                           "source": f"curated ({wmap}) — auto-export by creator_walk",
                           "pieces": d.get("pieces", [])}, cf, indent=1)
        pieces = d.get("pieces", [])
        held = [p["token"] for p in pieces
                if not str(p["token"]).startswith(("station_", "science_", "hangar_"))]
        length = int(math.ceil(max(float(p.get("x", 0)) for p in pieces))) + 2
        depth = int(math.ceil(max(float(p.get("z", 0)) for p in pieces))) + 1
        overlap = [walk.index(h) for h in held if h in walk]
        if walls_mode == "overlap" and not overlap:
            continue  # only walls that argue walked artifacts come on the tray
        anchor = min(overlap) if overlap else \
            int((maps_order.index(wmap) / max(len(maps_order), 1)) * len(walk)
                if wmap in maps_order else len(walk) - 1)
        walls.append({"map": wmap, "cluster": cname, "len": length, "depth": depth,
                      "anchor": anchor})
    walls.sort(key=lambda w: w["anchor"])

    tray = []
    wi = 0
    for i, a in enumerate(walk):
        tray.append(("artifact", a))
        while wi < len(walls) and walls[wi]["anchor"] <= i:
            tray.append(("wall", walls[wi]))
            wi += 1
    tray += [("wall", w) for w in walls[wi:]]
    tray += [("blank", b) for b in blanks]

    # ── phase 1: the walk — place and stamp ────────────────────────────────────
    global CX
    max_fp = max(max(1, int(math.ceil(min(base_of(a), 9.0)))) for a in walk)
    CX = max(CX, max_fp + 5)          # adaptive corridor: the giants need shoulder room
    cols = 2 * CX + 1
    occupied: set[tuple[int, int]] = set()
    placements = []      # (kind, token/cluster, row, col, extra)
    daises = []          # (r0, c0, r1, c1)
    r = 3
    side = -1            # start placing west; alternate
    for kind, item in tray:
        if kind == "artifact" or kind == "blank":
            name = item if kind == "artifact" else "station_plinth"
            b = base_of(name) if kind == "artifact" else 1.0
            fp = max(1, int(math.ceil(min(b, 9.0))))          # cap the giants
            dist = 2 + fp // 2 + (1 if b >= 4 else 0)
            col = CX + side * dist
            col = max(2, min(cols - 3, col))
            # push outward until the stamp is free
            tries = 0
            while any((rr, cc) in occupied
                      for rr in range(r - fp // 2, r + fp // 2 + 1)
                      for cc in range(col - fp // 2, col + fp // 2 + 1)) and tries < 6:
                col += side
                col = max(2, min(cols - 3, col))
                tries += 1
            for rr in range(r - fp // 2, r + fp // 2 + 1):
                for cc in range(col - fp // 2, col + fp // 2 + 1):
                    occupied.add((rr, cc))
            hero = b >= 4.0
            if hero:
                daises.append((r - fp // 2, col - fp // 2, r + fp // 2, col + fp // 2))
            placements.append((kind, name, r, col, {"hero": hero}))
            r += max(STRIDE, fp // 2 + 2)
            side *= -1
        else:  # wall work — inward-facing, occupying its length along z
            w = item
            if side < 0:
                col = CX - 2 - w["depth"]          # wall line west, exhibits reach corridor
                rot = 90                            # local +x -> north; anchor at south end
                anchor_row = r + w["len"]
            else:
                col = CX + 2 + w["depth"]
                rot = 270
                anchor_row = r
            for rr in range(r, r + w["len"] + 1):
                for cc in range(min(col, CX + 2), max(col, CX - 2) + 1):
                    if abs(cc - CX) > 1:
                        occupied.add((rr, cc))
            placements.append(("wall", f"cluster:{w['cluster']}:{rot}",
                               min(anchor_row, r + w["len"]), col, {"len": w["len"]}))
            r += w["len"] + WALL_GAP
            side *= -1
    rows = r + 4

    # ── phase 2: the walk-back — enrich the empty beats ────────────────────────
    stems = {s for n in walk for s in n.lower().split("_")} | \
            {s for m in maps_order for s in str(m).lower().split("_")}
    chalk = [n for n in sorted(reg) if n.endswith("_chalkboard")
             and n.split("_chalkboard")[0].split("_")[-1] in stems]
    props = chalk + [p for p in LAB_PROPS if p in reg]
    beats = []
    rr = 4
    while rr < rows - 4:
        band = [(rr2, cc) for rr2 in range(rr, rr + 3)
                for cc in range(CX - 3, CX + 4) if (rr2, cc) in occupied]
        if not band:
            beats.append(rr + 1)
            rr += 3
        else:
            rr += 1
    enrich = []
    pi = 0
    # beat seeding: props in the empty stretches
    for i, br in enumerate(beats):
        if pi >= len(props):
            break
        side_p = -1 if i % 2 == 0 else 1
        col = CX + side_p * 3
        rot = 90 if side_p < 0 else 270
        if (br, col) not in occupied:
            enrich.append((props[pi], br, col, rot))
            occupied.add((br, col))
            pi += 1
    # mirror seeding: a lab beat FACING each artifact across the corridor
    for kind, name, prow, pcol, extra in placements:
        if pi >= len(props) or kind != "artifact" or extra.get("hero"):
            continue
        colm = CX + (3 if pcol < CX else -3)
        rot = 270 if colm > CX else 90
        cells = [(prow, colm), (prow, colm + (1 if colm > CX else -1))]
        if all(c not in occupied for c in cells):
            enrich.append((props[pi], prow, colm, rot))
            occupied.update(cells)
            pi += 1

    # ── emit ────────────────────────────────────────────────────────────────────
    gs = [["1"] * cols for _ in range(rows)]
    gu = [[" "] * cols for _ in range(rows)]
    gi = [[" "] * cols for _ in range(rows)]
    for (r0, c0, r1, c1) in daises:
        for rr2 in range(max(0, r0), min(rows, r1 + 1)):
            for cc in range(max(0, c0), min(cols, c1 + 1)):
                gs[rr2][cc] = "2"
    for kind, token, prow, pcol, extra in placements:
        gi[prow][pcol] = token if kind != "blank" else "station_plinth"
    for (token, prow, pcol, rot) in enrich:
        gi[prow][pcol] = f"{token}:{rot}:0"
    gu[1][CX] = "t"
    gs[1][CX] = "0"
    gu[rows - 2][CX] = "sp"

    n_art = sum(1 for k, *_ in placements if k == "artifact")
    n_wall = sum(1 for k, *_ in placements if k == "wall")
    print(f"{map_name}: {cols} x {rows} — creator walk placed {n_art} artifacts, "
          f"{n_wall} wall works, {len(daises)} daises, {len(enrich)} enrichments "
          f"({', '.join(e[0] for e in enrich) or 'none'})")
    if not write:
        print("(dry run — pass --write)")
        return 0

    data = {
        "map_info": {
            "name": map_name, "lookup_name": map_name,
            "title": f"{seq.capitalize()} — the creator's walk",
            "description": f"R-013: the {seq} chapter placed by a first-person creator walk — "
                           "the necklace on a rolling tray, footprints stamped, wall works "
                           "facing inward, the lab vernacular seeded on the walk-back.",
            "version": "1.0", "format": "json",
            "dimensions": {"width": cols, "depth": rows, "max_height": 3},
            "metadata": {"difficulty": "intermediate", "category": seq,
                         "estimated_time": "6-8 minutes",
                         "learning_objectives": [f"The {seq} walk, staged as a lab",
                                                 "Creator-walk placement",
                                                 "The intelligent floor and walls"]},
        },
        "utility_definitions": {"t": {"type": "teleporter", "name": "Exit",
                                      "description": "leave the lab",
                                      "properties": {"action": "next_in_sequence"}}},
        "lighting": {"ambient_color": [0.4, 0.4, 0.5], "ambient_energy": 0.6,
                     "directional_light": {"enabled": True, "direction": [-0.4, -0.7, -0.4],
                                           "color": [1.0, 0.95, 0.9], "energy": 1.2}},
        "settings": {"cube_size": 1.0, "gutter": 0.0, "show_grid": True,
                     "enable_physics": True,
                     "background": {"type": "sky", "color": [0.2, 0.15, 0.3]}},
        "layers": {"structure": gs, "utilities": gu, "interactables": gi},
    }
    out_dir = os.path.join(MAPS_DIR, map_name)
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "map_data.json"), "w", encoding="utf-8") as f:
        json.dump(data, f, indent=1)
    print(f"wrote {out_dir}/map_data.json")
    sys.path.insert(0, os.path.join(REPO, "tools"))
    from book_log import log_event
    log_event("room", f"{map_name} generated by creator_walk (R-013): {n_art} artifacts + "
                      f"{n_wall} wall works placed along the librarian's corridor, "
                      f"{len(daises)} daises raised, walk-back seeded {len(enrich)} lab props "
                      f"({', '.join(e[0] for e in enrich[:5])}…)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
