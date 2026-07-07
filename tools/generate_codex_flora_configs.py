#!/usr/bin/env python3
"""Codex flora (L-systems) auto-research generator.

Four families, one per mode of codex_flora.gd - Luigi Serafini's Codex
Seraphinianus imaginary-botany rendered as GENUINE L-SYSTEMS, teaching specimens
for the `lsystems` curriculum sequence:
  bracketed (bracketed L-system tree) · helix (parametric double-helix stem) ·
  spacefill (Koch space-filling tendril) · inflorescence (recursive phyllotactic
  flowering grammar).

Each family carries three palette triads (FOLIAGE/PETAL color_a / WOODY color_b /
GLOW accent). NOTE: spacefill is a delicate frond - keep its width near its height
so the settle step does not stretch it into a flat sprawl. Writes specimens + a
GalleryView manifest into the encyclopedia codex-flora-gallery (images live in the
encyclopedia, never the Godot repo).
"""
from __future__ import annotations
import json, os, random, sys

GAL = r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\codex-flora-gallery"
SCENE = "res://commons/artifacts/codex_flora/codex_flora.tscn"

# palette triads: (color_a FOLIAGE/PETAL, color_b WOODY, accent GLOW)
BRACKETED_PAL = [
    ("0.36,0.55,0.34", "0.46,0.34,0.24", "0.98,0.78,0.30"),  # green / brown / gold bloom
    ("0.42,0.52,0.30", "0.40,0.30,0.22", "0.95,0.45,0.55"),  # olive / dark wood / red bloom
    ("0.30,0.50,0.40", "0.50,0.38,0.26", "0.95,0.90,0.45"),  # teal-green / tan / yellow bloom
]
HELIX_PAL = [
    ("0.40,0.58,0.34", "0.40,0.50,0.30", "0.55,1.00,0.55"),  # green / green-stem / green core
    ("0.46,0.54,0.32", "0.38,0.46,0.30", "0.98,0.82,0.40"),  # green / stem / gold core
    ("0.34,0.50,0.44", "0.36,0.44,0.34", "0.50,0.85,1.00"),  # teal / stem / cyan core
]
SPACEFILL_PAL = [
    ("0.40,0.62,0.46", "0.34,0.52,0.32", "0.95,0.55,0.75"),  # teal-green / green / pink bud
    ("0.44,0.60,0.40", "0.32,0.48,0.30", "0.98,0.78,0.40"),  # green / green / gold bud
    ("0.36,0.58,0.50", "0.30,0.50,0.38", "0.60,0.80,1.00"),  # jade / green / blue bud
]
INFLORESCENCE_PAL = [
    ("0.86,0.40,0.62", "0.34,0.50,0.30", "0.98,0.82,0.35"),  # magenta petal / green / gold center
    ("0.92,0.62,0.30", "0.36,0.48,0.28", "0.95,0.90,0.45"),  # orange petal / green / yellow center
    ("0.62,0.45,0.85", "0.32,0.48,0.32", "0.55,1.00,0.70"),  # violet petal / green / green center
]


def j(v: float) -> float:
    return round(v, 3)


def base(rng: random.Random, mode: str, triad: tuple) -> dict:
    a, b, c = triad
    return {"mode": mode, "seed": rng.randint(1, 99999),
            "color_a": a, "color_b": b, "accent": c}


def fam_bracketed(rng, triad):
    d = base(rng, "bracketed", triad)
    d.update({"sculpt_height": j(rng.uniform(2.3, 2.6)), "sculpt_width": j(rng.uniform(1.4, 1.8)),
              "complexity": rng.randint(5, 6), "metallic_amt": 0.0, "rough_amt": 0.75, "emissive": True})
    return d, "Bracketed (L-system tree)", "A canonical bracketed L-system tree - axiom + production rules expanded over generations, walked by a 3D turtle with a push/pop branch stack and depth decay, a surreal Codex canopy and thread-roots."


def fam_helix(rng, triad):
    d = base(rng, "helix", triad)
    d.update({"sculpt_height": j(rng.uniform(2.4, 2.8)), "sculpt_width": j(rng.uniform(1.0, 1.3)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.75, "emissive": True})
    return d, "Helix (DNA-ladder stem)", "A parametric double-helix DNA-ladder stem - two phase-offset helical strands with rungs, golden-angle phyllotaxis leaves, a layered artichoke head with a glowing core."


def fam_spacefill(rng, triad):
    # delicate frond: keep width near height so the settle step doesn't sprawl it
    d = base(rng, "spacefill", triad)
    d.update({"sculpt_height": j(rng.uniform(2.2, 2.5)), "sculpt_width": j(rng.uniform(1.0, 1.15)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.75, "emissive": True})
    return d, "Spacefill (Koch tendril)", "A space-filling Koch L-system curve swept as a recursively-crinkled tendril frond on a stem, with surreal Codex blooms at the curl tips."


def fam_inflorescence(rng, triad):
    d = base(rng, "inflorescence", triad)
    d.update({"sculpt_height": j(rng.uniform(2.3, 2.6)), "sculpt_width": j(rng.uniform(1.4, 1.8)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.75, "emissive": True})
    return d, "Inflorescence (phyllotaxis spray)", "A recursive phyllotactic flowering grammar - a stem rule re-applied over depth, golden-angle branching into size-graded Codex blooms with glowing centers and leaves."


FAMILIES = {
    "bracketed": (fam_bracketed, BRACKETED_PAL),
    "helix": (fam_helix, HELIX_PAL),
    "spacefill": (fam_spacefill, SPACEFILL_PAL),
    "inflorescence": (fam_inflorescence, INFLORESCENCE_PAL),
}


def score(d: dict) -> float:
    s = 100.0
    s += d.get("complexity", 0) * 0.4
    if d.get("emissive"):
        s += 1.0
    s += d.get("sculpt_height", 2.4)
    return s


def main() -> int:
    os.makedirs(GAL, exist_ok=True)
    rng = random.Random(71043)
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
            cid = "cfl_%s_%05x" % (fam, rng.randint(0, 1 << 20))
            json.dump({"id": cid, "name": name, "description": desc, "family": fam,
                       "score": round(sc, 2), "selection_rank": rank, "scene": SCENE, "dna": d},
                      open(os.path.join(GAL, cid + ".json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
            entries.append({"id": cid, "image": "/codex-flora-gallery/%s.png" % cid,
                            "config": "/codex-flora-gallery/%s.json" % cid, "notes": "%s - %s" % (name, desc)})
            render.append("%s\t%s" % (cid, SCENE))
    json.dump({"version": 1,
               "description": "Codex flora - Serafini's imaginary botany as genuine L-systems for the lsystems sequence: bracketed / helix / spacefill / inflorescence, four grammars in three palettes each.",
               "entries": entries},
              open(os.path.join(GAL, "manifest.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    open(os.path.join(GAL, "_render_list.txt"), "w", encoding="utf-8").write("\n".join(render) + "\n")
    if not os.path.exists(os.path.join(GAL, "evals.json")):
        json.dump({}, open(os.path.join(GAL, "evals.json"), "w", encoding="utf-8"))
    print("wrote %d codex_flora specimens across %d families" % (len(entries), len(FAMILIES)))
    for e in entries:
        print("  ", e["id"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
