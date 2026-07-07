#!/usr/bin/env python3
"""Codex anamorphic-arch auto-research generator.

Four modes, one per mode of codex_arch.gd, after Luigi Serafini's Codex
Seraphinianus architecture chapter - impossible / anamorphic / morphing arches
where building and organism blur, built from non-primitive swept surfaces:
  arcade (curving colonnade) · vault (ribbed barrel receding into depth) ·
  warp (twisting morphing arch) · organic (scaled-skin vault with roots).

Each mode carries three curated palette triads (MASONRY color_a / TRIM color_b /
APERTURE-GLOW accent) honouring the colored-pencil-on-parchment source - warm
stone, restrained glow. The organic mode swaps color_b for a living green skin.
Writes specimens + a GalleryView manifest into the encyclopedia codex-arch-gallery
(images live in the encyclopedia, never the Godot repo).
"""
from __future__ import annotations
import json, os, random, sys

GAL = r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\codex-arch-gallery"
SCENE = "res://commons/artifacts/codex_arch/codex_arch.tscn"

# palette triads: (color_a MASONRY, color_b TRIM/skin, accent APERTURE GLOW)
ARCADE_PAL = [
    ("0.74,0.52,0.36", "0.86,0.82,0.72", "0.98,0.82,0.50"),  # terracotta / limestone / warm
    ("0.66,0.46,0.40", "0.80,0.76,0.70", "0.96,0.70,0.40"),  # brick-red / stone / amber
    ("0.70,0.60,0.44", "0.88,0.84,0.74", "0.95,0.86,0.55"),  # ochre / pale / gold
]
VAULT_PAL = [
    ("0.72,0.56,0.40", "0.86,0.82,0.72", "0.98,0.84,0.55"),  # ochre / limestone / warm
    ("0.64,0.48,0.42", "0.82,0.78,0.72", "0.96,0.66,0.36"),  # red-brown / stone / amber
    ("0.68,0.58,0.46", "0.84,0.82,0.76", "0.92,0.88,0.60"),  # sand / pale / gold
]
WARP_PAL = [
    ("0.76,0.50,0.34", "0.86,0.82,0.72", "0.98,0.80,0.48"),  # terracotta / limestone / warm
    ("0.60,0.42,0.46", "0.80,0.74,0.74", "0.90,0.55,0.70"),  # mauve-stone / pale / rose (surreal)
    ("0.70,0.54,0.38", "0.86,0.80,0.70", "0.55,0.85,0.95"),  # ochre / stone / cyan (surreal)
]
ORGANIC_PAL = [  # color_b is the living green SKIN here
    ("0.80,0.70,0.54", "0.42,0.56,0.36", "0.70,0.95,0.55"),  # sandstone / green / green-gold
    ("0.78,0.66,0.50", "0.36,0.48,0.30", "0.60,0.95,0.70"),  # sand / deep green / mint
    ("0.82,0.68,0.52", "0.50,0.42,0.30", "0.95,0.80,0.45"),  # sand / olive-brown / amber
]
# vol.2 (grown from Codex reference plates)
RIBARCH_PAL = [  # color_a rib PRIMARY / color_b stripe SECONDARY / accent under-glow
    ("0.85,0.32,0.42", "0.36,0.55,0.40", "0.98,0.84,0.55"),  # pink / green / warm
    ("0.80,0.40,0.30", "0.40,0.50,0.66", "0.96,0.80,0.40"),  # coral / blue / amber
    ("0.78,0.34,0.52", "0.50,0.56,0.36", "0.95,0.88,0.55"),  # magenta / olive / gold
]
FOAMBRIDGE_PAL = [  # color_a membrane BONE / color_b ANCHOR stone / accent pendant glow
    ("0.88,0.84,0.74", "0.74,0.60,0.46", "0.98,0.86,0.58"),  # bone / stone / warm
    ("0.84,0.86,0.82", "0.66,0.62,0.56", "0.60,0.90,0.95"),  # cool bone / grey / cyan
    ("0.90,0.82,0.72", "0.70,0.56,0.44", "0.95,0.60,0.70"),  # warm bone / tan / rose
]
OCULUS_PAL = [  # color_a BRICK / color_b STONE / accent the blood-red POOL
    ("0.74,0.46,0.34", "0.86,0.82,0.72", "0.62,0.10,0.12"),  # terracotta / limestone / blood
    ("0.68,0.42,0.36", "0.82,0.78,0.70", "0.55,0.14,0.30"),  # brick / stone / wine
    ("0.78,0.50,0.32", "0.84,0.80,0.66", "0.20,0.30,0.55"),  # ochre / pale / ink-blue pool (surreal)
]
RAINBOWSPAN_PAL = [  # color_a BRIDGE stone / color_b BUILDING walls / accent WINDOW lights
    ("0.70,0.62,0.50", "0.34,0.32,0.40", "1.00,0.82,0.45"),  # stone / dusk / warm windows
    ("0.72,0.66,0.56", "0.30,0.34,0.42", "0.60,0.85,1.00"),  # stone / blue-dusk / cool windows
    ("0.68,0.58,0.46", "0.38,0.30,0.34", "1.00,0.62,0.40"),  # stone / plum / amber windows
]


def j(v: float) -> float:
    return round(v, 3)


def base(rng: random.Random, mode: str, triad: tuple) -> dict:
    a, b, c = triad
    return {"mode": mode, "seed": rng.randint(1, 99999),
            "color_a": a, "color_b": b, "accent": c}


def fam_arcade(rng, triad):
    d = base(rng, "arcade", triad)
    d.update({"sculpt_height": j(rng.uniform(2.0, 2.3)), "sculpt_width": j(rng.uniform(2.5, 2.9)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.85, "emissive": True})
    return d, "Arcade (curving colonnade)", "A curving colonnade of repeating masonry arches on columns with a sweeping entablature, warped in reverse perspective - an impossible Serafini/Piranesi arcade."


def fam_vault(rng, triad):
    d = base(rng, "vault", triad)
    d.update({"sculpt_height": j(rng.uniform(2.0, 2.3)), "sculpt_width": j(rng.uniform(2.0, 2.3)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.85, "emissive": True})
    return d, "Vault (ribbed barrel)", "A ribbed barrel vault tunnel receding into impossible depth - concentric rib-arches contracting toward a glowing throat, coursed masonry on the concave interior."


def fam_warp(rng, triad):
    d = base(rng, "warp", triad)
    d.update({"sculpt_height": j(rng.uniform(2.3, 2.6)), "sculpt_width": j(rng.uniform(2.2, 2.6)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.85, "emissive": True})
    return d, "Warp (morphing arch)", "A single hero arch whose span twists and morphs - cross-section tumbling square to diamond, leaning out of plane like bent taffy, a watching keystone-eye floating at the crown."


def fam_organic(rng, triad):
    d = base(rng, "organic", triad)
    d.update({"sculpt_height": j(rng.uniform(2.2, 2.5)), "sculpt_width": j(rng.uniform(2.0, 2.4)),
              "complexity": rng.randint(5, 6), "metallic_amt": 0.0, "rough_amt": 0.85, "emissive": True})
    return d, "Organic (scaled vault)", "A rounded vault clad in overlapping living scales with a tree and roots growing up through the opening on a diamond-tiled base - architecture fused with creature."


def fam_ribarch(rng, triad):
    d = base(rng, "ribarch", triad)
    d.update({"sculpt_height": j(rng.uniform(2.5, 2.8)), "sculpt_width": j(rng.uniform(2.3, 2.6)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.8, "emissive": True})
    return d, "Ribarch (striped ribs on legs)", "A monumental arch of concentric STRIPED ribbed bands springing from spindly tapered legs, a crown finial at the apex, foam-cells scattered on the ground - the Codex's hero anamorphic arch."


def fam_foambridge(rng, triad):
    d = base(rng, "foambridge", triad)
    d.update({"sculpt_height": j(rng.uniform(1.9, 2.2)), "sculpt_width": j(rng.uniform(2.6, 3.0)),
              "complexity": rng.randint(5, 6), "metallic_amt": 0.0, "rough_amt": 0.75, "emissive": True})
    return d, "Foambridge (cellular span)", "A bridge that is a FOAM/CELLULAR membrane - a span made mostly of elliptical holes held together by thin pale struts, a few jewel-tinted cells, a pendant teardrop hanging from mid-span."


def fam_oculus(rng, triad):
    d = base(rng, "oculus", triad)
    d.update({"sculpt_height": j(rng.uniform(2.3, 2.6)), "sculpt_width": j(rng.uniform(2.3, 2.6)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.85, "emissive": True})
    return d, "Oculus (brick ruin wall)", "A brick wall with a great dentil-ringed circular OCULUS, a pointed-arch arcade below, a striped toothed column, and a blood-red pool with stepping stones at the base - architecture bleeding into body."


def fam_rainbowspan(rng, triad):
    d = base(rng, "rainbowspan", triad)
    d.update({"sculpt_height": j(rng.uniform(2.1, 2.4)), "sculpt_width": j(rng.uniform(2.7, 3.0)),
              "complexity": rng.randint(5, 6), "metallic_amt": 0.0, "rough_amt": 0.8, "emissive": True})
    return d, "Rainbowspan (arc to a hill-town)", "A great curving ARC BRIDGE springing over a river to a terraced HILL-TOWN whose stacked buildings glitter with warm window-lights, wooded banks below."


FAMILIES = {
    "arcade": (fam_arcade, ARCADE_PAL),
    "vault": (fam_vault, VAULT_PAL),
    "warp": (fam_warp, WARP_PAL),
    "organic": (fam_organic, ORGANIC_PAL),
    "ribarch": (fam_ribarch, RIBARCH_PAL),
    "foambridge": (fam_foambridge, FOAMBRIDGE_PAL),
    "oculus": (fam_oculus, OCULUS_PAL),
    "rainbowspan": (fam_rainbowspan, RAINBOWSPAN_PAL),
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
    rng = random.Random(33107)
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
            cid = "cx_%s_%05x" % (fam, rng.randint(0, 1 << 20))
            json.dump({"id": cid, "name": name, "description": desc, "family": fam,
                       "score": round(sc, 2), "selection_rank": rank, "scene": SCENE, "dna": d},
                      open(os.path.join(GAL, cid + ".json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
            entries.append({"id": cid, "image": "/codex-arch-gallery/%s.png" % cid,
                            "config": "/codex-arch-gallery/%s.json" % cid, "notes": "%s - %s" % (name, desc)})
            render.append("%s\t%s" % (cid, SCENE))
    json.dump({"version": 1,
               "description": "Codex anamorphic arches - generative surreal architecture after Serafini's Codex Seraphinianus: arcade / vault / warp / organic / ribarch / foambridge / oculus / rainbowspan, impossible and morphing, eight modes in three palettes each.",
               "entries": entries},
              open(os.path.join(GAL, "manifest.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    open(os.path.join(GAL, "_render_list.txt"), "w", encoding="utf-8").write("\n".join(render) + "\n")
    if not os.path.exists(os.path.join(GAL, "evals.json")):
        json.dump({}, open(os.path.join(GAL, "evals.json"), "w", encoding="utf-8"))
    print("wrote %d codex_arch specimens across %d families" % (len(entries), len(FAMILIES)))
    for e in entries:
        print("  ", e["id"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
