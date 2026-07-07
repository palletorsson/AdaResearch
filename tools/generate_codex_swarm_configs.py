#!/usr/bin/env python3
"""Codex swarm (swarm intelligence) auto-research generator.

Four families, one per mode of codex_swarm.gd - Luigi Serafini's Codex
Seraphinianus ant-armies / fish-schools / bird-flocks rendered as GENUINE swarm
algorithms run to convergence and frozen as geometry, teaching specimens for the
swarmintelligence spine sequence:
  flock (Boids 3-rule murmuration) · anttrail (ant-colony optimization pheromone
  trail) · shoal (Vicsek alignment bait-ball) · pso (particle-swarm optimization
  cloud).

Each family carries three palette triads (AGENT color_a / SECONDARY color_b /
GLOW accent). Writes specimens + a GalleryView manifest into the encyclopedia
codex-swarm-gallery (images live in the encyclopedia, never the Godot repo).
"""
from __future__ import annotations
import json, os, random, sys

GAL = r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\codex-swarm-gallery"
SCENE = "res://commons/artifacts/codex_swarm/codex_swarm.tscn"

# palette triads: (color_a AGENT, color_b SECONDARY, accent GLOW)
FLOCK_PAL = [
    ("0.40,0.46,0.56", "0.24,0.28,0.38", "0.95,0.78,0.30"),  # starling slate / dark / gold
    ("0.52,0.34,0.30", "0.30,0.20,0.18", "0.98,0.85,0.40"),  # warm-brown birds / dark / gold
    ("0.30,0.40,0.46", "0.18,0.24,0.30", "0.55,0.90,0.95"),  # teal-grey / dark / cyan leader
]
ANTTRAIL_PAL = [
    ("0.34,0.18,0.13", "0.46,0.40,0.30", "0.45,0.95,0.55"),  # red-brown / earth / green pheromone
    ("0.20,0.16,0.14", "0.50,0.44,0.34", "0.98,0.65,0.25"),  # black ants / sand / amber pheromone
    ("0.40,0.22,0.16", "0.38,0.42,0.36", "0.55,0.85,0.98"),  # rust / olive / cyan pheromone
]
SHOAL_PAL = [
    ("0.55,0.62,0.70", "0.28,0.38,0.50", "0.95,0.82,0.35"),  # silver-blue / dark / gold
    ("0.50,0.66,0.60", "0.26,0.40,0.40", "0.98,0.70,0.40"),  # green-silver / teal / amber
    ("0.62,0.58,0.66", "0.34,0.32,0.46", "0.55,0.90,0.95"),  # mauve-silver / violet / cyan
]
PSO_PAL = [
    ("0.65,0.80,0.85", "0.35,0.45,0.55", "0.95,0.45,0.70"),  # cyan-white / slate / magenta
    ("0.85,0.82,0.65", "0.45,0.42,0.35", "0.98,0.55,0.25"),  # warm-white / taupe / orange
    ("0.70,0.78,0.92", "0.38,0.42,0.55", "0.60,0.95,0.55"),  # ice-blue / slate / green
]


def j(v: float) -> float:
    return round(v, 3)


def base(rng: random.Random, mode: str, triad: tuple) -> dict:
    a, b, c = triad
    return {"mode": mode, "seed": rng.randint(1, 99999),
            "color_a": a, "color_b": b, "accent": c}


def fam_flock(rng, triad):
    d = base(rng, "flock", triad)
    d.update({"sculpt_height": j(rng.uniform(2.3, 2.6)), "sculpt_width": j(rng.uniform(2.3, 2.6)),
              "complexity": rng.randint(8, 9), "metallic_amt": 0.0, "rough_amt": 0.6, "emissive": True})
    return d, "Flock (Boids murmuration)", "A real Boids simulation frozen mid-flight - Reynolds separation / alignment / cohesion stepped to a banking murmuration, every bird oriented along its velocity, leading-edge leaders glowing."


def fam_anttrail(rng, triad):
    d = base(rng, "anttrail", triad)
    d.update({"sculpt_height": j(rng.uniform(1.5, 1.8)), "sculpt_width": j(rng.uniform(2.5, 2.8)),
              "complexity": rng.randint(7, 9), "metallic_amt": 0.0, "rough_amt": 0.6, "emissive": True})
    return d, "Anttrail (ant-colony optimization)", "A real elitist ACO run frozen - pheromone^a*(1/length)^b choice with evaporation over a node graph, a dominant shortest-path trail emerging glowing with a marching ant column."


def fam_shoal(rng, triad):
    d = base(rng, "shoal", triad)
    d.update({"sculpt_height": j(rng.uniform(2.0, 2.3)), "sculpt_width": j(rng.uniform(2.0, 2.3)),
              "complexity": rng.randint(8, 9), "metallic_amt": 0.0, "rough_amt": 0.6, "emissive": True})
    return d, "Shoal (Vicsek bait-ball)", "A real Vicsek collective-motion model frozen - self-propelled agents aligning to neighbour-average heading plus noise, stepped to high rotational order, a swirling bait-ball."


def fam_pso(rng, triad):
    d = base(rng, "pso", triad)
    d.update({"sculpt_height": j(rng.uniform(2.1, 2.4)), "sculpt_width": j(rng.uniform(2.3, 2.6)),
              "complexity": rng.randint(7, 9), "metallic_amt": 0.0, "rough_amt": 0.6, "emissive": True})
    return d, "PSO (particle swarm)", "A real particle-swarm optimization run frozen mid-convergence - particles over a Gaussian fitness landscape funnelling into a glowing global-best attractor, trailing velocity streaks."


FAMILIES = {
    "flock": (fam_flock, FLOCK_PAL),
    "anttrail": (fam_anttrail, ANTTRAIL_PAL),
    "shoal": (fam_shoal, SHOAL_PAL),
    "pso": (fam_pso, PSO_PAL),
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
    rng = random.Random(73311)
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
            cid = "cs_%s_%05x" % (fam, rng.randint(0, 1 << 20))
            json.dump({"id": cid, "name": name, "description": desc, "family": fam,
                       "score": round(sc, 2), "selection_rank": rank, "scene": SCENE, "dna": d},
                      open(os.path.join(GAL, cid + ".json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
            entries.append({"id": cid, "image": "/codex-swarm-gallery/%s.png" % cid,
                            "config": "/codex-swarm-gallery/%s.json" % cid, "notes": "%s - %s" % (name, desc)})
            render.append("%s\t%s" % (cid, SCENE))
    json.dump({"version": 1,
               "description": "Codex swarm - Serafini's ant-armies / fish-schools / bird-flocks as genuine swarm algorithms frozen mid-simulation for the swarmintelligence lab: flock / anttrail / shoal / pso, four modes in three palettes each.",
               "entries": entries},
              open(os.path.join(GAL, "manifest.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    open(os.path.join(GAL, "_render_list.txt"), "w", encoding="utf-8").write("\n".join(render) + "\n")
    if not os.path.exists(os.path.join(GAL, "evals.json")):
        json.dump({}, open(os.path.join(GAL, "evals.json"), "w", encoding="utf-8"))
    print("wrote %d codex_swarm specimens across %d families" % (len(entries), len(FAMILIES)))
    for e in entries:
        print("  ", e["id"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
