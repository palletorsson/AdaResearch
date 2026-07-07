#!/usr/bin/env python3
"""Haeckel microorganism auto-research generator.

Four genera, one per mode of haeckel.gd, after Ernst Haeckel's Kunstformen der
Natur - latticed / perforated / radially-symmetric forms, a topology grammar of
clusters built from generated open mesh:
  radiolarian (geodesic lattice sphere + spines) ·
  cyrtoid (chambered lattice bell) ·
  siphonophore (hanging colony cluster) ·
  diatom (geometric radial perforated disc/star).

Each genus carries three curated palette triads (MEMBRANE color_a translucent /
SKELETON color_b ivory silica / NUCLEUS accent glow) and per-genus proportions
(radiolarian round; cyrtoid + siphonophore tall; diatom sized by across-span).
Writes specimens + a GalleryView manifest into the encyclopedia haeckel-gallery
(images live in the encyclopedia, never the Godot repo).
"""
from __future__ import annotations
import json, os, random, sys

GAL = r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\haeckel-gallery"
SCENE = "res://commons/artifacts/haeckel/haeckel.tscn"

# palette triads: (color_a MEMBRANE translucent, color_b SKELETON ivory, accent NUCLEUS glow)
RADIOLARIAN_PAL = [
    ("0.55,0.85,0.80", "0.92,0.88,0.78", "0.98,0.80,0.30"),  # aqua / ivory / gold
    ("0.70,0.62,0.88", "0.90,0.86,0.80", "0.40,0.95,0.95"),  # violet / ivory / cyan
    ("0.90,0.62,0.66", "0.94,0.90,0.82", "0.55,1.00,0.50"),  # rose / bone / acid green
]
CYRTOID_PAL = [
    ("0.85,0.70,0.62", "0.92,0.88,0.78", "0.98,0.80,0.30"),  # amber / ivory / gold
    ("0.62,0.80,0.85", "0.90,0.88,0.82", "0.98,0.55,0.30"),  # teal / ivory / coral
    ("0.80,0.66,0.85", "0.93,0.89,0.80", "0.45,0.95,0.85"),  # mauve / bone / jade
]
SIPHONOPHORE_PAL = [
    ("0.62,0.78,0.92", "0.86,0.74,0.70", "0.40,0.95,0.95"),  # aqua-violet / coral-ivory / cyan
    ("0.86,0.66,0.82", "0.88,0.78,0.74", "0.95,0.45,0.80"),  # pink / coral / magenta
    ("0.66,0.86,0.80", "0.84,0.80,0.74", "0.55,1.00,0.55"),  # mint / ivory / green
]
DIATOM_PAL = [
    ("0.70,0.90,0.72", "0.93,0.90,0.82", "0.45,0.95,0.85"),  # green / silica / jade
    ("0.72,0.84,0.92", "0.92,0.90,0.84", "0.98,0.78,0.30"),  # pale blue / silica / gold
    ("0.90,0.80,0.66", "0.94,0.91,0.83", "0.40,0.95,0.95"),  # warm / silica / cyan
]


def j(v: float) -> float:
    return round(v, 3)


def base(rng: random.Random, mode: str, triad: tuple) -> dict:
    a, b, c = triad
    return {"mode": mode, "seed": rng.randint(1, 99999),
            "color_a": a, "color_b": b, "accent": c}


def fam_radiolarian(rng, triad):
    # round sphere: width tracks height (the artifact scales it uniformly anyway).
    d = base(rng, "radiolarian", triad)
    h = j(rng.uniform(2.0, 2.3))
    d.update({"sculpt_height": h, "sculpt_width": h,
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.5, "emissive": True})
    return d, "Radiolarian (lattice sphere)", "A hollow geodesic LATTICE sphere - an ivory strut skeleton you see straight through, radial spines bursting outward, a glowing nucleus suspended inside."


def fam_cyrtoid(rng, triad):
    d = base(rng, "cyrtoid", triad)
    d.update({"sculpt_height": j(rng.uniform(2.3, 2.55)), "sculpt_width": j(rng.uniform(1.7, 1.95)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.5, "emissive": True})
    return d, "Cyrtoid (lattice bell)", "A chambered LATTICE bell - a gourd of meridian and ring struts in stacked constriction chambers, an apical horn, basal spines, a nucleus glowing in the base chamber."


def fam_siphonophore(rng, triad):
    d = base(rng, "siphonophore", triad)
    d.update({"sculpt_height": j(rng.uniform(2.5, 2.8)), "sculpt_width": j(rng.uniform(1.9, 2.1)),
              "complexity": rng.randint(5, 6), "metallic_amt": 0.0, "rough_amt": 0.5, "emissive": True})
    return d, "Siphonophore (colony)", "A hanging COLONY cluster - translucent swimming-bells over a chain of glowing bodies, dangling curtains of curling tentacles: one organism made of many kin units."


def fam_diatom(rng, triad):
    # sized by across-span (sculpt_width); keep height modest (it is a disc).
    d = base(rng, "diatom", triad)
    d.update({"sculpt_height": j(rng.uniform(2.0, 2.2)), "sculpt_width": j(rng.uniform(2.2, 2.5)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.45, "emissive": True})
    return d, "Diatom (radial disc)", "A geometric radial PERFORATED disc/star - concentric ring struts and radial ribs as open areolae cells in strict m-fold symmetry, a spiky star rim, a glowing centre."


FAMILIES = {
    "radiolarian": (fam_radiolarian, RADIOLARIAN_PAL),
    "cyrtoid": (fam_cyrtoid, CYRTOID_PAL),
    "siphonophore": (fam_siphonophore, SIPHONOPHORE_PAL),
    "diatom": (fam_diatom, DIATOM_PAL),
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
    rng = random.Random(18871)
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
            cid = "hk_%s_%05x" % (fam, rng.randint(0, 1 << 20))
            json.dump({"id": cid, "name": name, "description": desc, "family": fam,
                       "score": round(sc, 2), "selection_rank": rank, "scene": SCENE, "dna": d},
                      open(os.path.join(GAL, cid + ".json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
            entries.append({"id": cid, "image": "/haeckel-gallery/%s.png" % cid,
                            "config": "/haeckel-gallery/%s.json" % cid, "notes": "%s - %s" % (name, desc)})
            render.append("%s\t%s" % (cid, SCENE))

    # Showcase: the PLATE mode - a composed 3D Tafel, a cluster of many varied micro-forms.
    # Hand-authored (fixed id, no RNG draw) and appended LAST so the twelve family ids
    # above stay byte-identical.
    pid = "hk_plate_showcase"
    pdna = {"mode": "plate", "seed": 4242,
            "color_a": "0.62,0.84,0.86", "color_b": "0.92,0.88,0.78", "accent": "0.98,0.80,0.30",
            "metallic_amt": 0.0, "rough_amt": 0.5, "emissive": True, "complexity": 7,
            "sculpt_height": 2.2, "sculpt_width": 2.6}
    pname = "Plate (a 3D Tafel)"
    pdesc = ("A composed CLUSTER - a three-dimensional Haeckel plate: many varied micro-forms "
             "(lattice spheres of graded size, diatom discs, a cyrtoid bell) floating together as "
             "one colony, a constellation of glowing nuclei. The whole grammar in one frame - the "
             "literal cluster of clusters.")
    json.dump({"id": pid, "name": pname, "description": pdesc, "family": "plate",
               "score": 0.0, "selection_rank": 1, "scene": SCENE, "dna": pdna},
              open(os.path.join(GAL, pid + ".json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    entries.append({"id": pid, "image": "/haeckel-gallery/%s.png" % pid,
                    "config": "/haeckel-gallery/%s.json" % pid, "notes": "%s - %s" % (pname, pdesc)})
    render.append("%s\t%s" % (pid, SCENE))

    json.dump({"version": 1,
               "description": "Haeckel forms - generative radiolaria / cyrtoids / siphonophores / diatoms after Kunstformen der Natur: latticed, perforated, clustered topology grammar, four genera in three palettes each, plus a 3D Tafel plate cluster.",
               "entries": entries},
              open(os.path.join(GAL, "manifest.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    open(os.path.join(GAL, "_render_list.txt"), "w", encoding="utf-8").write("\n".join(render) + "\n")
    if not os.path.exists(os.path.join(GAL, "evals.json")):
        json.dump({}, open(os.path.join(GAL, "evals.json"), "w", encoding="utf-8"))
    print("wrote %d haeckel specimens across %d families" % (len(entries), len(FAMILIES)))
    for e in entries:
        print("  ", e["id"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
