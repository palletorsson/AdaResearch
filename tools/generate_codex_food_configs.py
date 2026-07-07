#!/usr/bin/env python3
"""Codex food / vegetable-machine auto-research generator.

Four families, one per mode of codex_food.gd, after Luigi Serafini's Codex
Seraphinianus food chapter - everyday edibles fused with mechanism, flame, seed,
and the uncanny:
  tuber (potato fused with plumbing) · candleroot (radish that is a candle) ·
  seedpod (cut gourd packed with glowing seeds) · zipfruit (fruit unzipping to a
  crystal core).

Each family carries three palette triads (ORGANIC SKIN color_a / SECONDARY color_b
/ GLOW accent). Writes specimens + a GalleryView manifest into the encyclopedia
codex-food-gallery (images live in the encyclopedia, never the Godot repo).
"""
from __future__ import annotations
import json, os, random, sys

GAL = r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\codex-food-gallery"
SCENE = "res://commons/artifacts/codex_food/codex_food.tscn"

# palette triads: (color_a ORGANIC SKIN, color_b SECONDARY, accent GLOW)
TUBER_PAL = [
    ("0.62,0.46,0.30", "0.72,0.56,0.28", "0.40,0.90,0.95"),  # brown / brass / cyan gauge
    ("0.66,0.52,0.34", "0.55,0.57,0.62", "0.98,0.55,0.20"),  # tan / steel / orange
    ("0.56,0.42,0.28", "0.74,0.50,0.22", "0.55,1.00,0.55"),  # dark potato / copper / green
]
CANDLEROOT_PAL = [
    ("0.82,0.20,0.26", "0.36,0.52,0.30", "1.00,0.72,0.30"),  # red / green / warm flame
    ("0.74,0.26,0.40", "0.40,0.50,0.28", "1.00,0.84,0.45"),  # beet / green / gold flame
    ("0.86,0.34,0.24", "0.34,0.48,0.32", "0.60,0.85,1.00"),  # orange-radish / green / blue flame
]
SEEDPOD_PAL = [
    ("0.40,0.58,0.30", "0.90,0.92,0.80", "0.98,0.85,0.40"),  # green / cream / gold seeds
    ("0.80,0.50,0.20", "0.92,0.88,0.78", "0.95,0.40,0.40"),  # orange pepper / cream / red seeds
    ("0.66,0.20,0.26", "0.94,0.86,0.80", "0.55,1.00,0.70"),  # red pepper / pale / green seeds
]
ZIPFRUIT_PAL = [
    ("0.40,0.20,0.42", "0.58,0.66,0.74", "0.45,0.95,0.90"),  # aubergine / crystal / cyan
    ("0.74,0.18,0.20", "0.72,0.60,0.40", "0.98,0.80,0.40"),  # apple-red / brass-gear / amber
    ("0.30,0.40,0.22", "0.66,0.56,0.74", "0.85,0.45,0.95"),  # squash / amethyst / magenta
]


def j(v: float) -> float:
    return round(v, 3)


def base(rng: random.Random, mode: str, triad: tuple) -> dict:
    a, b, c = triad
    return {"mode": mode, "seed": rng.randint(1, 99999),
            "color_a": a, "color_b": b, "accent": c}


def fam_tuber(rng, triad):
    d = base(rng, "tuber", triad)
    d.update({"sculpt_height": j(rng.uniform(1.3, 1.5)), "sculpt_width": j(rng.uniform(1.5, 1.8)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.85, "rough_amt": 0.4, "emissive": True})
    return d, "Tuber (potato-machine)", "A lumpy potato fused with brass PLUMBING - pipes, a hand-wheel valve, gauges, a red mushroom-knob, a spigot, bolt feet: a vegetable that is secretly a machine."


def fam_candleroot(rng, triad):
    d = base(rng, "candleroot", triad)
    d.update({"sculpt_height": j(rng.uniform(1.4, 1.7)), "sculpt_width": j(rng.uniform(0.9, 1.2)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.6, "emissive": True})
    return d, "Candleroot (radish candle)", "A red radish/beet bulb that is a CANDLE - a glowing flame at the crown, white wax drips down the bulb, green leaves, a root tail on a wax pool."


def fam_seedpod(rng, triad):
    d = base(rng, "seedpod", triad)
    d.update({"sculpt_height": j(rng.uniform(1.2, 1.5)), "sculpt_width": j(rng.uniform(1.2, 1.5)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.5, "emissive": True})
    return d, "Seedpod (cut gourd)", "A gourd/pepper CUT OPEN - a wedge removed to reveal pale inner flesh packed with a cluster of glowing seeds on a placenta, a stem, spilled seeds."


def fam_zipfruit(rng, triad):
    d = base(rng, "zipfruit", triad)
    d.update({"sculpt_height": j(rng.uniform(1.3, 1.6)), "sculpt_width": j(rng.uniform(1.1, 1.4)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.2, "rough_amt": 0.4, "emissive": True})
    return d, "Zipfruit (unzipping fruit)", "A fruit UNZIPPING along a zipper seam - two half-shells gaping to reveal a glowing faceted CRYSTAL geode where the flesh should be, a pull-tab."


FAMILIES = {
    "tuber": (fam_tuber, TUBER_PAL),
    "candleroot": (fam_candleroot, CANDLEROOT_PAL),
    "seedpod": (fam_seedpod, SEEDPOD_PAL),
    "zipfruit": (fam_zipfruit, ZIPFRUIT_PAL),
}


def score(d: dict) -> float:
    s = 100.0
    s += d.get("complexity", 0) * 0.4
    if d.get("emissive"):
        s += 1.0
    s += d.get("sculpt_height", 1.4)
    return s


def main() -> int:
    os.makedirs(GAL, exist_ok=True)
    rng = random.Random(50921)
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
            cid = "cf_%s_%05x" % (fam, rng.randint(0, 1 << 20))
            json.dump({"id": cid, "name": name, "description": desc, "family": fam,
                       "score": round(sc, 2), "selection_rank": rank, "scene": SCENE, "dna": d},
                      open(os.path.join(GAL, cid + ".json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
            entries.append({"id": cid, "image": "/codex-food-gallery/%s.png" % cid,
                            "config": "/codex-food-gallery/%s.json" % cid, "notes": "%s - %s" % (name, desc)})
            render.append("%s\t%s" % (cid, SCENE))
    json.dump({"version": 1,
               "description": "Codex food / vegetable-machines - generative surreal edibles after Serafini's Codex Seraphinianus: tuber / candleroot / seedpod / zipfruit, organism fused with machine, flame, seed and the uncanny, four modes in three palettes each.",
               "entries": entries},
              open(os.path.join(GAL, "manifest.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    open(os.path.join(GAL, "_render_list.txt"), "w", encoding="utf-8").write("\n".join(render) + "\n")
    if not os.path.exists(os.path.join(GAL, "evals.json")):
        json.dump({}, open(os.path.join(GAL, "evals.json"), "w", encoding="utf-8"))
    print("wrote %d codex_food specimens across %d families" % (len(entries), len(FAMILIES)))
    for e in entries:
        print("  ", e["id"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
