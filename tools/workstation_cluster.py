#!/usr/bin/env python3
"""workstation_cluster.py — export workstations as CLUSTERS for the wall-hangar
capture pipeline (R-016 iterate loop: capture separately, learn what works visually).

A workstation (hero + concept-ladder children + lab prop cast) is emitted in the
same `pieces` format as curated walls -> commons/data/curated_walls/clusters/
ws_<hero>.json. Then the existing loop applies unchanged:

  render:   Godot ... desktop_wall_hangar_editor.tscn -- --capture-clusters
  review:   wall_shots/ws_<hero>.png -> /wall-gallery (auto-seeds section)
  place:    `cluster:ws_<hero>:<rot>` token in any map
  iterate:  edit THIS layout, re-export, re-capture — the visual learning loop.

Local frame: the bench runs along +x (like walls), depth toward the viewer is +z
(0..~2.6). Tight by design — the reference bench, not a plaza.

Usage:
  python tools/workstation_cluster.py --heroes=distribution_sampler,slot_machine --write
"""
from __future__ import annotations

import json
import os
import sys
import urllib.request

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLUSTERS = os.path.join(REPO, "commons", "data", "curated_walls", "clusters")
LADDER = "http://localhost:3003/api/concept-ladder?id="

# the DNA layer (from /surreal-lab-gallery + the dna_* families):
# each station gets a THEMED surreal instrument + one modern-art wall piece.
SURREAL_MODE = {
    "distribution_sampler": "scanner",      # analysis arm over a lit sample
    "slot_machine": "gravgun",              # the chance manipulator
    "perlin_terrain_sculptor": "reactor",   # the field, caged
    "mc_sculpt_vr": "specimen",             # the blob, in the tank
    "klee_walking_point": "teleporter",     # the walk's portal pad
    "lsystem_editor": "chemrig",            # growth as alien glassware
}
WALL_ART = ["dna_modern_art_rothko_chromatic_field", "dna_modern_art_mondrian_de_stijl",
            "dna_modern_art_kandinsky_bauhaus_triad", "dna_modern_art_albers_homage_warm"]

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass


def children_of(hero):
    try:
        d = json.load(urllib.request.urlopen(LADDER + hero, timeout=15))
        t = d.get("tiers", {}) or {}
    except Exception:
        t = {}
    def pick(k):
        xs = [x for x in t.get(k, []) if x != hero]
        return xs[0] if xs else None
    small = [x for x in t.get("small", []) if x != hero][:2]
    return {"medium": pick("medium"), "applied": pick("applied"), "small": small}


def pieces_for(hero, kids, seed=7):
    P = []
    def add(token, x, y, z, wall=False, **cfg):
        p = {"token": token, "x": x, "y": y, "z": z, "wall": wall}
        if cfg:
            p["config"] = cfg
        P.append(p)

    # the bench wall + panel + shelf (the backdrop)
    add("station_wall", 1.0, 0.0, 0.0, wall=True, width_cells=6)
    add("station_panel", 1.5, 2.3, 0.06, wall=True, width_cells=5,
        header=hero.replace("_", " ").upper(),
        lines=["One workstation: the apparatus, its ladder of variants, its lab cast.",
               "A node of the research, staged as a working bench."])
    add("station_multiscreen", 5.8, 1.5, 0.12, wall=True)

    # HERO — centre stage under the task light
    add("station_stage", 3.2, 0.0, 1.5, width_cells=2, depth_cells=2, step_height=0.18,
        name_plate=hero.replace("_", " "))
    add(hero, 3.2, 0.18, 1.5)
    add("station_luminaire", 3.2, 0.0, 0.35)

    # CHILDREN — tight flanks
    if kids.get("medium"):
        add("station_plinth", 1.2, 0.0, 1.0, width_cells=1, depth_cells=1,
            top_height=1.0, cap_inset=0.1, caption_text=kids["medium"].replace("_", " "))
        add(kids["medium"], 1.2, 1.0, 1.0)
    if kids.get("applied"):
        add("station_plinth", 5.2, 0.0, 1.0, width_cells=1, depth_cells=1,
            top_height=1.1, cap_inset=0.1, caption_text=kids["applied"].replace("_", " "))
        add(kids["applied"], 5.2, 1.1, 1.0)
    for i, s in enumerate(kids.get("small") or []):
        x = 2.2 + i * 2.0
        add("station_micropod", x, 0.0, 2.3, base_meters=0.6, cap_meters=1.16,
            top_height=1.15, caption_text=s.replace("_", " "))
        add(s, x, 1.15, 2.3)

    # THE LAB CAST — packed, reference vocabulary
    add("gas_canister", 0.2, 0.0, 2.0)          # cylinder, left front
    add("lab_stool", 4.3, 0.0, 2.4)             # stool at the bench
    add("tech_crate", 6.6, 0.0, 1.9)            # crate stack, right
    add("cardboard_box", 6.6, 0.55, 1.9)
    add("fire_extinguisher", 6.8, 0.0, 0.3)     # at the wall end

    # THE DNA LAYER — the uncanny instrument (surreal_lab, themed mode) at the
    # far end, and one modern-art DNA piece hung on the wall (the lab has art).
    mode = SURREAL_MODE.get(hero, "spectrometer")
    add("station_plinth", 7.6, 0.0, 1.2, width_cells=1, depth_cells=1,
        top_height=0.5, cap_inset=0.1, caption_text=f"surreal {mode}")
    add(f"surreal_lab#mode:{mode}#seed:{seed}", 7.6, 0.5, 1.2)
    art = WALL_ART[seed % len(WALL_ART)]
    add(art, 0.2, 1.5, 0.12, wall=True)
    return P


def main():
    args = sys.argv[1:]
    heroes = next((a.split("=", 1)[1] for a in args if a.startswith("--heroes=")), "")
    write = "--write" in args
    hs = [h.strip() for h in heroes.split(",") if h.strip()]
    if not hs:
        print(__doc__)
        return 1
    made = []
    for i, h in enumerate(hs):
        kids = children_of(h)
        P = pieces_for(h, kids, seed=7 + i)
        n_kids = sum(1 for k in ("medium", "applied") if kids.get(k)) + len(kids.get("small") or [])
        print(f"  ws_{h}: {len(P)} pieces, {n_kids} children "
              f"({kids.get('medium')}, {kids.get('applied')}, {kids.get('small')})")
        if write:
            path = os.path.join(CLUSTERS, f"ws_{h}.json")
            with open(path, "w", encoding="utf-8") as f:
                json.dump({"name": f"ws_{h}",
                           "source": "workstation auto-seed (workstation_cluster.py)",
                           "pieces": P}, f, indent=1)
            made.append(f"ws_{h}")
    if made:
        sys.path.insert(0, os.path.join(REPO, "tools"))
        from book_log import log_event
        log_event("stage", f"workstation clusters exported for the visual iterate loop: "
                           f"{', '.join(made)} — capture via WallHangarEditor --capture-clusters, "
                           "review on /wall-gallery")
    if not write:
        print("(dry run — pass --write)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
