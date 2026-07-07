#!/usr/bin/env python3
"""Great Wave auto-research generator.

One hero form - Hokusai's "The Great Wave off Kanagawa" rendered as genuine
algorithm (a logarithmic-spiral breaking lip + recursive self-similar claw-foam),
re-skinned across six palettes. Each palette = (color_a DEEP WAVE, color_b INNER
light-blue spiral, accent FOAM, paper_color SKY); two seed/proportion variants
each = 12 specimens. "The same wave under different skies and inks." Writes
specimens + a GalleryView manifest into the encyclopedia great-wave-gallery
(images live in the encyclopedia, never the Godot repo).
"""
from __future__ import annotations
import json, os, random, sys

GAL = r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\great-wave-gallery"
SCENE = "res://commons/artifacts/great_wave/great_wave.tscn"

# palettes: name -> (color_a DEEP WAVE, color_b INNER light-blue, accent FOAM, paper_color SKY)
PALETTES = [
    ("classic",  "0.06,0.12,0.30", "0.55,0.70,0.80", "0.96,0.97,0.94", "0.87,0.81,0.66"),  # Prussian / cream
    ("night",    "0.03,0.05,0.14", "0.40,0.52,0.66", "0.90,0.93,0.96", "0.52,0.56,0.64"),  # storm dusk
    ("jade",     "0.04,0.20,0.20", "0.45,0.75,0.66", "0.95,0.98,0.95", "0.86,0.82,0.68"),  # jade sea
    ("sunset",   "0.16,0.10,0.32", "0.72,0.56,0.70", "0.98,0.94,0.90", "0.91,0.80,0.60"),  # indigo / warm sky
    ("ink",      "0.10,0.10,0.13", "0.55,0.58,0.62", "0.97,0.97,0.97", "0.84,0.80,0.70"),  # sumi-e monochrome
    ("crimson",  "0.26,0.06,0.10", "0.82,0.46,0.42", "0.98,0.95,0.92", "0.90,0.83,0.68"),  # crimson wave
]


def j(v: float) -> float:
    return round(v, 3)


def specimen(rng: random.Random, pal: tuple) -> dict:
    _name, a, b, foam, paper = pal
    return {
        "seed": rng.randint(1, 99999),
        "color_a": a, "color_b": b, "accent": foam, "paper_color": paper,
        "sculpt_height": j(rng.uniform(1.9, 2.1)),
        "sculpt_width": j(rng.uniform(2.8, 3.2)),
        "complexity": rng.randint(6, 7),
        "metallic_amt": 0.0, "rough_amt": 0.7, "emissive": True,
    }


def score(d: dict) -> float:
    return 100.0 + d.get("complexity", 0) * 0.4 + d.get("sculpt_height", 2.0) + (1.0 if d.get("emissive") else 0.0)


def main() -> int:
    os.makedirs(GAL, exist_ok=True)
    rng = random.Random(60607)
    entries, render = [], []
    for pname, *_cols in PALETTES:
        pal = (pname, *_cols)
        for variant in range(1, 3):
            best = None
            for _ in range(3):
                d = specimen(rng, pal)
                sc = score(d)
                if best is None or sc > best[0]:
                    best = (sc, d)
            sc, d = best
            cid = "gw_%s_%d_%05x" % (pname, variant, rng.randint(0, 1 << 20))
            name = "Great Wave - %s" % pname
            desc = "Hokusai's Great Wave as genuine algorithm (logarithmic-spiral lip + recursive self-similar claw-foam), in the %s palette." % pname
            json.dump({"id": cid, "name": name, "description": desc, "family": pname,
                       "score": round(sc, 2), "selection_rank": variant, "scene": SCENE, "dna": d},
                      open(os.path.join(GAL, cid + ".json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
            entries.append({"id": cid, "image": "/great-wave-gallery/%s.png" % cid,
                            "config": "/great-wave-gallery/%s.json" % cid, "notes": "%s - %s" % (name, desc)})
            render.append("%s\t%s" % (cid, SCENE))
    json.dump({"version": 1,
               "description": "The Great Wave - Hokusai's Great Wave off Kanagawa as genuine algorithm (logarithmic-spiral breaking lip + recursive self-similar claw-foam), re-skinned across six palettes: classic Prussian, storm night, jade, sunset, sumi-e ink, crimson.",
               "entries": entries},
              open(os.path.join(GAL, "manifest.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    open(os.path.join(GAL, "_render_list.txt"), "w", encoding="utf-8").write("\n".join(render) + "\n")
    if not os.path.exists(os.path.join(GAL, "evals.json")):
        json.dump({}, open(os.path.join(GAL, "evals.json"), "w", encoding="utf-8"))
    print("wrote %d great_wave specimens across %d palettes" % (len(entries), len(PALETTES)))
    for e in entries:
        print("  ", e["id"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
