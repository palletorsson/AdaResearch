#!/usr/bin/env python3
"""Codex loom (arrays) auto-research generator.

Four families, one per mode of codex_loom.gd - Luigi Serafini's Codex
Seraphinianus board-game / counting / weaving plates rendered as GENUINE array
algorithms, teaching specimens for the array_tutorial spine sequence:
  weave (2D over-under interlace) · abacus (place-value counting array) ·
  boardtrack (grid-index boustrophedon traversal) · wallpaper (modular-arithmetic
  wallpaper-group tessellation).

Each family carries three palette triads (PRIMARY color_a / SECONDARY color_b /
GLOW accent). Writes specimens + a GalleryView manifest into the encyclopedia
codex-loom-gallery (images live in the encyclopedia, never the Godot repo).
"""
from __future__ import annotations
import json, os, random, sys

GAL = r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\codex-loom-gallery"
SCENE = "res://commons/artifacts/codex_loom/codex_loom.tscn"

# palette triads: (color_a PRIMARY, color_b SECONDARY, accent GLOW)
WEAVE_PAL = [
    ("0.82,0.34,0.40", "0.30,0.50,0.66", "0.95,0.82,0.35"),  # red / blue / gold
    ("0.86,0.62,0.28", "0.36,0.54,0.42", "0.95,0.55,0.55"),  # ochre / green / coral
    ("0.55,0.35,0.62", "0.78,0.74,0.60", "0.50,0.85,0.95"),  # purple / cream / cyan
]
ABACUS_PAL = [
    ("0.85,0.45,0.35", "0.45,0.50,0.58", "0.95,0.85,0.35"),  # terracotta / slate / gold
    ("0.40,0.62,0.55", "0.55,0.50,0.46", "0.98,0.70,0.30"),  # teal / taupe / amber
    ("0.70,0.40,0.62", "0.50,0.52,0.60", "0.55,0.90,0.70"),  # mauve / grey / green
]
BOARDTRACK_PAL = [
    ("0.84,0.62,0.42", "0.34,0.42,0.50", "0.40,0.85,0.95"),  # warm / cool / cyan
    ("0.80,0.78,0.66", "0.40,0.34,0.42", "0.98,0.55,0.30"),  # cream / plum / orange
    ("0.58,0.70,0.50", "0.34,0.40,0.46", "0.95,0.82,0.35"),  # green / slate / gold
]
WALLPAPER_PAL = [
    ("0.84,0.40,0.46", "0.34,0.52,0.56", "0.95,0.82,0.35"),  # rose / teal / gold
    ("0.40,0.46,0.72", "0.80,0.76,0.64", "0.95,0.55,0.55"),  # blue / cream / coral
    ("0.86,0.58,0.28", "0.40,0.46,0.40", "0.50,0.85,0.95"),  # ochre / olive / cyan
]


def j(v: float) -> float:
    return round(v, 3)


def base(rng: random.Random, mode: str, triad: tuple) -> dict:
    a, b, c = triad
    return {"mode": mode, "seed": rng.randint(1, 99999),
            "color_a": a, "color_b": b, "accent": c}


def fam_weave(rng, triad):
    d = base(rng, "weave", triad)
    d.update({"sculpt_height": j(rng.uniform(2.1, 2.4)), "sculpt_width": j(rng.uniform(2.0, 2.3)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.7, "emissive": True})
    return d, "Weave (2D interlace)", "A real 2D over-under weave from a boolean pattern matrix - warp and weft tubes interlacing on a loom, a tartan emerging from two crossing colour sequences (the 1D x 1D -> 2D point of arrays)."


def fam_abacus(rng, triad):
    d = base(rng, "abacus", triad)
    d.update({"sculpt_height": j(rng.uniform(1.9, 2.2)), "sculpt_width": j(rng.uniform(2.0, 2.3)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.7, "emissive": True})
    return d, "Abacus (place-value array)", "A real place-value counting array - rods of beads encoding a number in a base, counted beads clustered against the reckoning bar, highlighted places, asemic numeral ticks."


def fam_boardtrack(rng, triad):
    d = base(rng, "boardtrack", triad)
    d.update({"sculpt_height": j(rng.uniform(1.5, 1.8)), "sculpt_width": j(rng.uniform(2.3, 2.6)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.7, "emissive": True})
    return d, "Boardtrack (grid traversal)", "A real grid-index traversal - a checkerboard whose boustrophedon track is row = k//W, col = k%W, with counters, ladder/portal arcs and a glowing finish cell."


def fam_wallpaper(rng, triad):
    d = base(rng, "wallpaper", triad)
    d.update({"sculpt_height": j(rng.uniform(2.0, 2.3)), "sculpt_width": j(rng.uniform(2.1, 2.4)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.7, "emissive": True})
    return d, "Wallpaper (symmetry tessellation)", "A real wallpaper-group tessellation - a motif replicated by a chosen group's symmetry operations (p4 / p4m / p6m / pmm / pgg) using modular arithmetic per cell."


FAMILIES = {
    "weave": (fam_weave, WEAVE_PAL),
    "abacus": (fam_abacus, ABACUS_PAL),
    "boardtrack": (fam_boardtrack, BOARDTRACK_PAL),
    "wallpaper": (fam_wallpaper, WALLPAPER_PAL),
}


def score(d: dict) -> float:
    s = 100.0
    s += d.get("complexity", 0) * 0.4
    if d.get("emissive"):
        s += 1.0
    s += d.get("sculpt_height", 2.0)
    return s


def main() -> int:
    os.makedirs(GAL, exist_ok=True)
    rng = random.Random(91277)
    entries, render = [], []
    for fam, (builder, pal) in FAMILIES.items():
        for rank, triad in enumerate(pal, 1):
            best = None
            for _ in range(4):
                d, name, desc = builder(rng, triad)
                sc = score(d)
                if best is None or sc > best[0]:
                    best = (sc, d, name, desc)
            sc, d, name, desc = best
            cid = "cl_%s_%05x" % (fam, rng.randint(0, 1 << 20))
            json.dump({"id": cid, "name": name, "description": desc, "family": fam,
                       "score": round(sc, 2), "selection_rank": rank, "scene": SCENE, "dna": d},
                      open(os.path.join(GAL, cid + ".json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
            entries.append({"id": cid, "image": "/codex-loom-gallery/%s.png" % cid,
                            "config": "/codex-loom-gallery/%s.json" % cid, "notes": "%s - %s" % (name, desc)})
            render.append("%s\t%s" % (cid, SCENE))
    json.dump({"version": 1,
               "description": "Codex loom - Serafini's grid / weaving / board / counting plates as genuine array algorithms for the array_tutorial lab: weave / abacus / boardtrack / wallpaper, four modes in three palettes each.",
               "entries": entries},
              open(os.path.join(GAL, "manifest.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    open(os.path.join(GAL, "_render_list.txt"), "w", encoding="utf-8").write("\n".join(render) + "\n")
    if not os.path.exists(os.path.join(GAL, "evals.json")):
        json.dump({}, open(os.path.join(GAL, "evals.json"), "w", encoding="utf-8"))
    print("wrote %d codex_loom specimens across %d families" % (len(entries), len(FAMILIES)))
    for e in entries:
        print("  ", e["id"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
