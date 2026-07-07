#!/usr/bin/env python3
"""Biomech cyborg auto-research generator.

Four families, one per mode of biomech.gd:
  arachnid (eight-leg flesh-and-steel spider) · serpent (rearing segmented
  centipede) · avian (winged flesh drone on a perch) · walker (quadruped
  synth-beast with an exposed core).

Each family carries three curated palette triads (FLESH color_a / METAL color_b /
GLOW accent). For every palette we breed a few seed-candidates and keep the
best, so each family ships three visually distinct specimens. The flesh tones
are kept DEEP and saturated on purpose: a light-salmon albedo washes to pale
pastel under the soft subsurface flesh material, while a deep blood-red reads as
living meat fused to the steel.

Writes the specimens + a GalleryView manifest into the encyclopedia
biomech-gallery (images stay in the encyclopedia, never the Godot repo).
"""
from __future__ import annotations
import json, os, random, sys

GAL = r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\biomech-gallery"
SCENE = "res://commons/artifacts/biomech/biomech.tscn"

# palette triads: (color_a FLESH, color_b METAL, accent GLOW)
ARACHNID_PAL = [
    ("0.60,0.11,0.13", "0.30,0.31,0.35", "0.35,0.95,0.95"),  # blood red / steel / cyan
    ("0.52,0.09,0.16", "0.16,0.17,0.20", "0.45,0.80,1.00"),  # crimson / gunmetal / electric blue
    ("0.64,0.14,0.10", "0.12,0.12,0.14", "0.98,0.62,0.20"),  # red / near-black / amber
]
SERPENT_PAL = [
    ("0.58,0.12,0.14", "0.13,0.15,0.18", "0.40,0.95,0.80"),  # crimson / dark / teal-green
    ("0.50,0.10,0.18", "0.16,0.16,0.20", "0.55,1.00,0.45"),  # wine / gunmetal / acid green
    ("0.62,0.15,0.12", "0.10,0.11,0.13", "0.35,0.95,0.95"),  # red / black / cyan
]
AVIAN_PAL = [
    ("0.62,0.13,0.16", "0.15,0.17,0.21", "0.32,0.90,0.96"),  # rose-red / blue-steel / cyan
    ("0.56,0.11,0.20", "0.13,0.13,0.16", "0.50,0.78,1.00"),  # magenta-red / dark / sky blue
    ("0.66,0.16,0.13", "0.17,0.16,0.15", "0.98,0.72,0.22"),  # warm red / warm steel / amber
]
WALKER_PAL = [
    ("0.55,0.11,0.12", "0.10,0.10,0.12", "0.98,0.78,0.22"),  # maroon / black / amber
    ("0.60,0.14,0.10", "0.14,0.15,0.18", "0.40,0.95,0.85"),  # red / gunmetal / teal
    ("0.50,0.09,0.15", "0.13,0.12,0.14", "0.55,0.85,1.00"),  # deep wine / dark / ice blue
]


def j(v: float) -> float:
    return round(v, 3)


def base(rng: random.Random, mode: str, triad: tuple) -> dict:
    a, b, c = triad
    return {"mode": mode, "seed": rng.randint(1, 99999),
            "color_a": a, "color_b": b, "accent": c}


def fam_arachnid(rng, triad):
    d = base(rng, "arachnid", triad)
    d.update({"sculpt_height": j(rng.uniform(1.7, 1.95)), "sculpt_width": j(rng.uniform(2.2, 2.6)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.85, "rough_amt": 0.40, "emissive": True})
    return d, "Arachnid cyborg", "An eight-leg spider-crab: a deep-red fleshy abdomen under a riveted steel carapace, jointed strider legs, and a metal cephalon with a glowing compound-eye cluster."


def fam_serpent(rng, triad):
    d = base(rng, "serpent", triad)
    d.update({"sculpt_height": j(rng.uniform(2.2, 2.6)), "sculpt_width": j(rng.uniform(1.8, 2.2)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.85, "rough_amt": 0.42, "emissive": True})
    return d, "Serpent cyborg", "A rearing segmented centipede coiling along a curve - flesh body-segments clamped under dark armour plates, an exposed mechanical spine, a maw, and glowing inter-segment cores."


def fam_avian(rng, triad):
    d = base(rng, "avian", triad)
    d.update({"sculpt_height": j(rng.uniform(2.0, 2.3)), "sculpt_width": j(rng.uniform(2.0, 2.4)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.85, "rough_amt": 0.40, "emissive": True})
    return d, "Avian cyborg", "A winged drone: a fleshy body slung on a perch, strut-and-membrane wings, a sensor head with an optic, and a glowing chest core."


def fam_walker(rng, triad):
    d = base(rng, "walker", triad)
    d.update({"sculpt_height": j(rng.uniform(1.8, 2.05)), "sculpt_width": j(rng.uniform(2.3, 2.7)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.85, "rough_amt": 0.42, "emissive": True})
    return d, "Walker cyborg", "A quadruped synth-beast: a bulbous flesh torso on four piston-driven mechanical legs, with an exposed glowing core caged in a strut ribcage."


FAMILIES = {
    "arachnid": (fam_arachnid, ARACHNID_PAL),
    "serpent": (fam_serpent, SERPENT_PAL),
    "avian": (fam_avian, AVIAN_PAL),
    "walker": (fam_walker, WALKER_PAL),
}


def score(d: dict) -> float:
    s = 100.0
    s += d.get("complexity", 0) * 0.4
    if d.get("emissive"):
        s += 1.0
    s += d.get("sculpt_height", 1.8)
    return s


def main() -> int:
    os.makedirs(GAL, exist_ok=True)
    rng = random.Random(40417)
    entries, render = [], []
    for fam, (builder, pal) in FAMILIES.items():
        for rank, triad in enumerate(pal, 1):
            # Breed a few seed-candidates for this palette, keep the best.
            best = None
            for _ in range(4):
                d, name, desc = builder(rng, triad)
                sc = score(d)
                if best is None or sc > best[0]:
                    best = (sc, d, name, desc)
            sc, d, name, desc = best
            cid = "bm_%s_%05x" % (fam, rng.randint(0, 1 << 20))
            json.dump({"id": cid, "name": name, "description": desc, "family": fam,
                       "score": round(sc, 2), "selection_rank": rank, "scene": SCENE, "dna": d},
                      open(os.path.join(GAL, cid + ".json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
            entries.append({"id": cid, "image": "/biomech-gallery/%s.png" % cid,
                            "config": "/biomech-gallery/%s.json" % cid, "notes": "%s - %s" % (name, desc)})
            render.append("%s\t%s" % (cid, SCENE))
    json.dump({"version": 1,
               "description": "Biomech cyborgs - non-human bodies where living flesh and machine fuse. Generative specimens across four anatomies (arachnid, serpent, avian, walker), each in three palettes.",
               "entries": entries},
              open(os.path.join(GAL, "manifest.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    open(os.path.join(GAL, "_render_list.txt"), "w", encoding="utf-8").write("\n".join(render) + "\n")
    if not os.path.exists(os.path.join(GAL, "evals.json")):
        json.dump({}, open(os.path.join(GAL, "evals.json"), "w", encoding="utf-8"))
    print("wrote %d biomech specimens across %d families" % (len(entries), len(FAMILIES)))
    for e in entries:
        print("  ", e["id"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
