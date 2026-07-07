#!/usr/bin/env python3
"""Surreal sci-fi lab instrument auto-research generator.

Four families, one per mode of surreal_lab.gd:
  specimen (glowing tank + alien embryo) · reactor (plasma core + ring cage) ·
  scanner (articulated analysis arm) · chemrig (glassware + condenser + burner).
Generates scored DNA specimens (varied by seed + colour register), keeps the best
few per family, writes them + a GalleryView manifest into the encyclopedia
surreal-lab-gallery.
"""
from __future__ import annotations
import json, os, random, sys

GAL = r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\surreal-lab-gallery"
SCENE = "res://commons/artifacts/surreal_lab/surreal_lab.tscn"

# palette triads: (color_a primary glow/fluid, color_b secondary, accent indicator/glint)
SPECIMEN_PAL = [("0.20,0.95,0.80", "0.96,0.55,0.62", "0.98,0.86,0.32"),
                ("0.30,0.82,0.98", "0.88,0.42,0.78", "0.96,0.76,0.40"),
                ("0.45,0.96,0.55", "0.96,0.62,0.46", "0.92,0.92,0.42")]
REACTOR_PAL = [("0.32,0.86,1.00", "0.96,0.30,0.76", "0.62,0.96,1.00"),
               ("0.96,0.36,0.86", "0.40,0.72,1.00", "1.00,0.56,0.86"),
               ("1.00,0.60,0.20", "0.42,0.82,1.00", "1.00,0.86,0.42")]
SCANNER_PAL = [("0.30,0.96,0.86", "0.52,1.00,0.46", "0.98,0.80,0.30"),
               ("0.40,0.80,1.00", "0.96,0.40,0.80", "0.96,0.86,0.36"),
               ("0.56,0.96,0.66", "0.96,0.56,0.42", "0.90,0.90,0.42")]
CHEMRIG_PAL = [("0.35,0.86,0.96", "0.96,0.36,0.76", "0.98,0.70,0.26"),
               ("0.45,0.96,0.60", "0.86,0.40,0.86", "1.00,0.66,0.30"),
               ("0.30,0.80,1.00", "0.96,0.50,0.56", "0.96,0.86,0.42")]
# Half-Life science-lab families: Black Mesa teal-green-hazard + Combine blue-white
SPECTROMETER_PAL = [("0.20,0.95,0.78", "0.40,1.00,0.45", "0.98,0.55,0.10"),
                    ("0.25,0.90,0.85", "0.50,0.95,0.40", "0.96,0.60,0.12"),
                    ("0.30,1.00,0.70", "0.45,1.00,0.50", "0.95,0.50,0.08")]
TELEPORTER_PAL = [("0.55,0.85,1.00", "0.45,0.78,1.00", "0.98,0.75,0.15"),
                  ("0.45,1.00,0.55", "0.40,0.95,0.50", "0.98,0.70,0.15"),
                  ("0.65,0.80,1.00", "0.50,0.75,1.00", "0.96,0.78,0.18")]
GRAVGUN_PAL = [("0.40,0.75,1.00", "0.72,0.90,1.00", "0.98,0.80,0.30"),
               ("1.00,0.55,0.15", "1.00,0.80,0.40", "0.98,0.85,0.40"),
               ("0.45,0.80,1.00", "0.75,0.92,1.00", "0.96,0.82,0.32")]
DARKREACTOR_PAL = [("0.62,0.86,1.00", "0.13,0.17,0.25", "0.50,0.80,1.00"),
                   ("0.55,0.90,1.00", "0.14,0.16,0.22", "0.48,0.85,1.00"),
                   ("0.70,0.88,1.00", "0.12,0.15,0.24", "0.55,0.82,1.00")]


def j(v: float) -> float:
    return round(v, 3)


def base(rng: random.Random, mode: str, pal: list) -> dict:
    a, b, c = rng.choice(pal)
    return {"mode": mode, "seed": rng.randint(1, 99999),
            "color_a": a, "color_b": b, "accent": c}


def fam_specimen(rng):
    d = base(rng, "specimen", SPECIMEN_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.7, 2.0)), "sculpt_width": j(rng.uniform(0.9, 1.2)),
              "complexity": rng.randint(4, 7), "metallic_amt": 0.6, "rough_amt": 0.3, "emissive": True})
    return d, "Specimen tank", "A glass containment tank cradling a glowing alien embryo in luminous fluid — the uncanny made functional."


def fam_reactor(rng):
    d = base(rng, "reactor", REACTOR_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.7, 2.0)), "sculpt_width": j(rng.uniform(0.9, 1.2)),
              "complexity": rng.randint(4, 7), "metallic_amt": 0.85, "rough_amt": 0.3, "emissive": True})
    return d, "Plasma reactor", "A glowing plasma core suspended in a cage of gimbal rings and coils, arcing energy to a dark instrumented plinth."


def fam_scanner(rng):
    d = base(rng, "scanner", SCANNER_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.6, 1.9)), "sculpt_width": j(rng.uniform(1.0, 1.4)),
              "complexity": rng.randint(4, 7), "metallic_amt": 0.8, "rough_amt": 0.35, "emissive": True})
    return d, "Analysis scanner", "An articulated mechanical arm with a glowing sensor head and probe beam, peering over a lit sample stage."


def fam_chemrig(rng):
    d = base(rng, "chemrig", CHEMRIG_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.6, 1.9)), "sculpt_width": j(rng.uniform(1.0, 1.4)),
              "complexity": rng.randint(4, 7), "metallic_amt": 0.7, "rough_amt": 0.3, "emissive": True})
    return d, "Chemistry rig", "Alien interconnected glassware — a glowing retort, a luminous spiral condenser coil and a burner — bubbling on a metal stand."


def fam_spectrometer(rng):
    d = base(rng, "spectrometer", SPECTROMETER_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.9, 2.2)), "sculpt_width": j(rng.uniform(1.2, 1.6)),
              "complexity": rng.randint(4, 7), "metallic_amt": 0.7, "rough_amt": 0.4, "emissive": True})
    return d, "Anti-mass spectrometer", "Black Mesa's resonance-cascade machine — a ringed emitter firing a teal beam into a glowing green Xen crystal, framed in hazard-striped gantry."


def fam_teleporter(rng):
    d = base(rng, "teleporter", TELEPORTER_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.9, 2.2)), "sculpt_width": j(rng.uniform(1.2, 1.6)),
              "complexity": rng.randint(4, 7), "metallic_amt": 0.8, "rough_amt": 0.35, "emissive": True})
    return d, "Teleporter pad", "A teleportation platform spinning up — tilted gimbal rings arcing over a glowing portal disc that fires a vertical energy column."


def fam_gravgun(rng):
    d = base(rng, "gravgun", GRAVGUN_PAL)
    d.update({"sculpt_height": j(rng.uniform(1.3, 1.6)), "sculpt_width": j(rng.uniform(1.0, 1.4)),
              "complexity": rng.randint(4, 7), "metallic_amt": 0.85, "rough_amt": 0.4, "emissive": True})
    return d, "Gravity gun", "The zero-point energy field manipulator on a lab cradle — three splayed prongs cradling a glowing core, cables looping the chunky body."


def fam_darkreactor(rng):
    d = base(rng, "darkreactor", DARKREACTOR_PAL)
    d.update({"sculpt_height": j(rng.uniform(2.0, 2.3)), "sculpt_width": j(rng.uniform(1.0, 1.4)),
              "complexity": rng.randint(4, 7), "metallic_amt": 0.85, "rough_amt": 0.4, "emissive": True})
    return d, "Combine reactor", "A Combine dark-energy reactor — a brilliant blue-white energy column caged in dark angular claw struts on an armoured base. Cold captured power."


FAMILIES = {"specimen": fam_specimen, "reactor": fam_reactor,
            "scanner": fam_scanner, "chemrig": fam_chemrig,
            "spectrometer": fam_spectrometer, "teleporter": fam_teleporter,
            "gravgun": fam_gravgun, "darkreactor": fam_darkreactor}


def score(d: dict) -> float:
    s = 100.0
    s += d.get("complexity", 0) * 0.3
    if d.get("emissive"):
        s += 1.0
    s += d.get("sculpt_height", 1.5)
    return s


def main() -> int:
    os.makedirs(GAL, exist_ok=True)
    rng = random.Random(7717)
    entries, render = [], []
    for fam, builder in FAMILIES.items():
        cands = []
        for _ in range(7):
            d, name, desc = builder(rng)
            cands.append((score(d), d, name, desc))
        cands.sort(key=lambda c: c[0], reverse=True)
        for rank, (sc, d, name, desc) in enumerate(cands[:3], 1):
            cid = "lab_%s_%05x" % (fam, rng.randint(0, 1 << 20))
            json.dump({"id": cid, "name": name, "description": desc, "family": fam,
                       "score": round(sc, 2), "selection_rank": rank, "scene": SCENE, "dna": d},
                      open(os.path.join(GAL, cid + ".json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
            entries.append({"id": cid, "image": "/surreal-lab-gallery/%s.png" % cid,
                            "config": "/surreal-lab-gallery/%s.json" % cid, "notes": "%s — %s" % (name, desc)})
            render.append("%s\t%s" % (cid, SCENE))
    json.dump({"version": 1,
               "description": "Surreal sci-fi lab instruments — generative specimens across eight lab-item families (four surreal + four Half-Life).",
               "entries": entries},
              open(os.path.join(GAL, "manifest.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    open(os.path.join(GAL, "_render_list.txt"), "w", encoding="utf-8").write("\n".join(render) + "\n")
    if not os.path.exists(os.path.join(GAL, "evals.json")):
        json.dump({}, open(os.path.join(GAL, "evals.json"), "w", encoding="utf-8"))
    print("wrote %d lab specimens across %d families" % (len(entries), len(FAMILIES)))
    for e in entries:
        print("  ", e["id"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
