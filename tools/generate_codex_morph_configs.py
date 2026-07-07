#!/usr/bin/env python3
"""Codex morphogenesis auto-research generator.

Four families, one per mode of codex_morph.gd - Luigi Serafini's Codex
Seraphinianus fauna-metamorphosis rendered as GENUINE morphogenesis algorithms,
teaching specimens for the cellularautomata / softbodies(reaction-diffusion) /
machinelearning(evolution) spine sequences:
  lifecycle (developmental stage-sequence) · division (Conway's Game of Life cell
  colony) · turing (Gray-Scott reaction-diffusion creature) · taxon (evolved-variant
  taxonomy grid).

Each family carries three palette triads (FLESH color_a / STRUCTURE color_b /
GLOW accent). Per-mode proportions: lifecycle is scaled tall-ish so the wide arc
fills the frame; division + taxon are wide-flat (mound / tray). Writes specimens +
a GalleryView manifest into the encyclopedia codex-morph-gallery (images live in
the encyclopedia, never the Godot repo).
"""
from __future__ import annotations
import json, os, random, sys

GAL = r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\codex-morph-gallery"
SCENE = "res://commons/artifacts/codex_morph/codex_morph.tscn"

# palette triads: (color_a FLESH, color_b STRUCTURE, accent GLOW)
LIFECYCLE_PAL = [
    ("0.86,0.42,0.40", "0.30,0.34,0.40", "0.45,0.95,0.85"),  # coral / slate / mint
    ("0.78,0.52,0.74", "0.32,0.30,0.40", "0.95,0.85,0.40"),  # mauve / dark / gold
    ("0.55,0.70,0.45", "0.30,0.36,0.30", "0.98,0.55,0.55"),  # green / dark / coral
]
DIVISION_PAL = [
    ("0.62,0.82,0.70", "0.45,0.48,0.44", "0.45,0.95,0.85"),  # green protoplasm / grey / mint
    ("0.70,0.78,0.88", "0.48,0.48,0.50", "0.55,0.85,1.00"),  # blue / grey / cyan
    ("0.86,0.72,0.78", "0.50,0.46,0.46", "0.98,0.60,0.70"),  # pink / grey / rose
]
TURING_PAL = [
    ("0.34,0.62,0.58", "0.86,0.40,0.46", "0.95,0.85,0.40"),  # teal / rose / amber (ocelli)
    ("0.80,0.62,0.30", "0.40,0.22,0.30", "0.55,1.00,0.70"),  # tan / dark / green (leopard)
    ("0.45,0.50,0.70", "0.92,0.70,0.30", "0.98,0.50,0.55"),  # blue / gold / coral
]
TAXON_PAL = [
    ("0.80,0.55,0.40", "0.82,0.80,0.74", "0.55,1.00,0.70"),  # ochre / pale tray / green
    ("0.62,0.45,0.78", "0.80,0.78,0.74", "0.98,0.82,0.40"),  # violet / tray / gold
    ("0.85,0.45,0.45", "0.78,0.80,0.76", "0.50,0.90,1.00"),  # red / tray / cyan
]


def j(v: float) -> float:
    return round(v, 3)


def base(rng: random.Random, mode: str, triad: tuple) -> dict:
    a, b, c = triad
    return {"mode": mode, "seed": rng.randint(1, 99999),
            "color_a": a, "color_b": b, "accent": c}


def fam_lifecycle(rng, triad):
    # scaled tall-ish so the wide developmental arc fills the capture frame
    d = base(rng, "lifecycle", triad)
    d.update({"sculpt_height": j(rng.uniform(2.1, 2.3)), "sculpt_width": j(rng.uniform(1.2, 1.4)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.65, "emissive": True})
    return d, "Lifecycle (metamorphosis)", "A developmental stage-sequence - egg to larva to pupa to winged adult along an arc, growing, threaded by a glowing progression line: morphogenesis as a timeline."


def fam_division(rng, triad):
    d = base(rng, "division", triad)
    d.update({"sculpt_height": j(rng.uniform(0.8, 1.0)), "sculpt_width": j(rng.uniform(2.0, 2.4)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.6, "emissive": True})
    return d, "Division (Game of Life)", "A real Conway's Game of Life run, embodied as a translucent cell colony on a petri-mound: glowing newborns, dumbbell mitosis cells, faded dying husks."


def fam_turing(rng, triad):
    d = base(rng, "turing", triad)
    d.update({"sculpt_height": j(rng.uniform(1.5, 1.8)), "sculpt_width": j(rng.uniform(1.7, 2.0)),
              "complexity": rng.randint(5, 6), "metallic_amt": 0.0, "rough_amt": 0.65, "emissive": True})
    return d, "Turing (reaction-diffusion)", "A real Gray-Scott reaction-diffusion simulation mapped to a creature's skin as raised rimmed ocelli spots - Turing morphogenesis, the pattern that computes itself."


def fam_taxon(rng, triad):
    d = base(rng, "taxon", triad)
    d.update({"sculpt_height": j(rng.uniform(1.1, 1.3)), "sculpt_width": j(rng.uniform(2.2, 2.6)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.65, "emissive": True})
    return d, "Taxon (evolution grid)", "An evolved-variant taxonomy grid - egg-pods grown from a mutating genome with a selection cline plus sibling drift: a population of mutants."


FAMILIES = {
    "lifecycle": (fam_lifecycle, LIFECYCLE_PAL),
    "division": (fam_division, DIVISION_PAL),
    "turing": (fam_turing, TURING_PAL),
    "taxon": (fam_taxon, TAXON_PAL),
}


def score(d: dict) -> float:
    s = 100.0
    s += d.get("complexity", 0) * 0.4
    if d.get("emissive"):
        s += 1.0
    s += d.get("sculpt_height", 1.5)
    return s


def main() -> int:
    os.makedirs(GAL, exist_ok=True)
    rng = random.Random(60413)
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
            cid = "cm_%s_%05x" % (fam, rng.randint(0, 1 << 20))
            json.dump({"id": cid, "name": name, "description": desc, "family": fam,
                       "score": round(sc, 2), "selection_rank": rank, "scene": SCENE, "dna": d},
                      open(os.path.join(GAL, cid + ".json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
            entries.append({"id": cid, "image": "/codex-morph-gallery/%s.png" % cid,
                            "config": "/codex-morph-gallery/%s.json" % cid, "notes": "%s - %s" % (name, desc)})
            render.append("%s\t%s" % (cid, SCENE))
    json.dump({"version": 1,
               "description": "Codex morphogenesis - Serafini's fauna-metamorphosis as genuine algorithms (Conway's Life, Gray-Scott reaction-diffusion, genome evolution) for the CA / softbodies / ML spine labs: lifecycle / division / turing / taxon, four modes in three palettes each.",
               "entries": entries},
              open(os.path.join(GAL, "manifest.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    open(os.path.join(GAL, "_render_list.txt"), "w", encoding="utf-8").write("\n".join(render) + "\n")
    if not os.path.exists(os.path.join(GAL, "evals.json")):
        json.dump({}, open(os.path.join(GAL, "evals.json"), "w", encoding="utf-8"))
    print("wrote %d codex_morph specimens across %d families" % (len(entries), len(FAMILIES)))
    for e in entries:
        print("  ", e["id"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
