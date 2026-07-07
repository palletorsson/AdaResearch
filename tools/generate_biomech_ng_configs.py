#!/usr/bin/env python3
"""Biomech NG (non-primitive) auto-research generator.

Four families, one per mode of biomech_ng.gd — each a different surface-generation
strategy (NOT primitive-stacking):
  serpentloft (one continuous lofted swept-tube serpent) ·
  fusion (flesh melting into metal as one marching-cubes isosurface) ·
  carapace (a Gielis superformula shell creature) ·
  mech (procedural hard-surface paneling + convex-hull armor).

Each family carries three curated palette triads (FLESH color_a / METAL color_b /
GLOW accent) and per-family proportions. Flesh tones are kept DEEP and saturated:
a light-salmon albedo washes to pale pastel under the soft subsurface flesh shader.
Carapace runs taller-than-wide so the superformula dome reads (the sizing step
applies sculpt_width to x/z). Fusion keeps complexity modest because that mode's
marching-cubes resolution scales with it.

Writes specimens + a GalleryView manifest into the encyclopedia biomech-ng-gallery
(images live in the encyclopedia, never the Godot repo).
"""
from __future__ import annotations
import json, os, random, sys

GAL = r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\biomech-ng-gallery"
SCENE = "res://commons/artifacts/biomech_ng/biomech_ng.tscn"

# palette triads: (color_a FLESH deep, color_b METAL dark, accent GLOW)
SERPENTLOFT_PAL = [
    ("0.60,0.11,0.13", "0.13,0.15,0.18", "0.35,0.95,0.95"),  # blood / steel / cyan
    ("0.54,0.10,0.16", "0.16,0.16,0.20", "0.55,1.00,0.45"),  # crimson / gunmetal / acid green
    ("0.62,0.14,0.11", "0.11,0.12,0.14", "0.98,0.66,0.20"),  # red / near-black / amber
]
FUSION_PAL = [
    ("0.60,0.11,0.13", "0.13,0.15,0.18", "0.35,0.95,0.95"),  # blood / steel / cyan
    ("0.56,0.10,0.18", "0.14,0.14,0.17", "0.45,0.80,1.00"),  # wine / dark / electric blue
    ("0.58,0.13,0.12", "0.12,0.13,0.16", "0.40,0.95,0.82"),  # red / gunmetal / teal
]
CARAPACE_PAL = [
    ("0.58,0.12,0.14", "0.14,0.16,0.20", "0.98,0.72,0.20"),  # crimson / blue-steel / amber
    ("0.62,0.13,0.16", "0.13,0.14,0.17", "0.32,0.92,0.96"),  # rose / dark / cyan
    ("0.52,0.10,0.17", "0.16,0.15,0.14", "0.55,1.00,0.50"),  # wine / warm steel / acid green
]
MECH_PAL = [
    ("0.56,0.11,0.13", "0.14,0.15,0.18", "0.35,0.92,0.96"),  # crimson / gunmetal / cyan
    ("0.58,0.13,0.11", "0.12,0.12,0.14", "0.98,0.74,0.22"),  # red / black / amber
    ("0.52,0.10,0.16", "0.15,0.16,0.20", "0.45,0.80,1.00"),  # wine / blue-steel / electric blue
]


def j(v: float) -> float:
    return round(v, 3)


def base(rng: random.Random, mode: str, triad: tuple) -> dict:
    a, b, c = triad
    return {"mode": mode, "seed": rng.randint(1, 99999),
            "color_a": a, "color_b": b, "accent": c}


def fam_serpentloft(rng, triad):
    d = base(rng, "serpentloft", triad)
    d.update({"sculpt_height": j(rng.uniform(2.3, 2.5)), "sculpt_width": j(rng.uniform(1.9, 2.1)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.85, "rough_amt": 0.40, "emissive": True})
    return d, "Serpent (lofted)", "A rearing serpent whose body is ONE continuous lofted swept tube - a flowing surface no primitive stack can make - with a metal vertebral spine, noise-rippled muscle skin, and a glowing head pod."


def fam_fusion(rng, triad):
    d = base(rng, "fusion", triad)
    d.update({"sculpt_height": j(rng.uniform(1.8, 2.0)), "sculpt_width": j(rng.uniform(2.0, 2.2)),
              "complexity": rng.randint(5, 6), "metallic_amt": 0.85, "rough_amt": 0.40, "emissive": True})
    return d, "Fusion beast", "Flesh melting into metal as ONE marching-cubes skin - the flesh-vs-metal seam graded smoothly by a per-vertex shader - with a socketed glow core, eyes, and vein cracks crossing the melt."


def fam_carapace(rng, triad):
    # taller than wide so the superformula dome reads (sizing applies width to x/z)
    d = base(rng, "carapace", triad)
    d.update({"sculpt_height": j(rng.uniform(2.2, 2.45)), "sculpt_width": j(rng.uniform(1.75, 1.95)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.85, "rough_amt": 0.40, "emissive": True})
    return d, "Carapace (superformula)", "A Gielis superformula shell - the spherical product of two mismatched-symmetry superformulae, giving huge organic-mechanical variety - on bezier-swept legs with a sensor head and a glowing core port."


def fam_mech(rng, triad):
    d = base(rng, "mech", triad)
    d.update({"sculpt_height": j(rng.uniform(2.0, 2.2)), "sculpt_width": j(rng.uniform(2.2, 2.45)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.85, "rough_amt": 0.40, "emissive": True})
    return d, "Hard-surface mech", "Procedural hard-surface armor - inset/extrude raised panels + convex-hull armor chunks + greebles over a generated revolution shell - with deep-red flesh showing through the panel seams and a glowing optic."


FAMILIES = {
    "serpentloft": (fam_serpentloft, SERPENTLOFT_PAL),
    "fusion": (fam_fusion, FUSION_PAL),
    "carapace": (fam_carapace, CARAPACE_PAL),
    "mech": (fam_mech, MECH_PAL),
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
    rng = random.Random(60606)
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
            cid = "bng_%s_%05x" % (fam, rng.randint(0, 1 << 20))
            json.dump({"id": cid, "name": name, "description": desc, "family": fam,
                       "score": round(sc, 2), "selection_rank": rank, "scene": SCENE, "dna": d},
                      open(os.path.join(GAL, cid + ".json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
            entries.append({"id": cid, "image": "/biomech-ng-gallery/%s.png" % cid,
                            "config": "/biomech-ng-gallery/%s.json" % cid, "notes": "%s - %s" % (name, desc)})
            render.append("%s\t%s" % (cid, SCENE))

    # Showcase specimen for the queer / bio / fetish `finish` register. Hand-authored
    # (fixed id, no RNG draw) and appended LAST so the twelve family ids above stay
    # byte-identical. mode=fusion + finish=latex -> wet-latex skin melting into an
    # oil-slick iridescent chrome shell, electric-cyan bioluminescence.
    fid = "bng_fetish_showcase"
    fdna = {"mode": "fusion", "seed": 4242,
            "color_a": "0.95,0.10,0.52", "color_b": "0.10,0.03,0.16", "accent": "0.25,1.00,0.90",
            "metallic_amt": 0.90, "rough_amt": 0.20, "emissive": True, "complexity": 6,
            "sculpt_height": 1.9, "sculpt_width": 2.2, "finish": "latex"}
    fname = "Fetish fusion (latex)"
    fdesc = ("Queer / bio / fetish materiality - the fusion beast in a wet-latex register: "
             "a hot-magenta latex membrane melting into an oil-slick iridescent chrome shell, "
             "electric-cyan bioluminescent core and eyes, neon veins crossing the smooth seam. "
             "Same genome, a different finish - the boundary between body and gear is a question "
             "of surface, not just colour.")
    json.dump({"id": fid, "name": fname, "description": fdesc, "family": "fetish",
               "score": 0.0, "selection_rank": 1, "scene": SCENE, "dna": fdna},
              open(os.path.join(GAL, fid + ".json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    entries.append({"id": fid, "image": "/biomech-ng-gallery/%s.png" % fid,
                    "config": "/biomech-ng-gallery/%s.json" % fid, "notes": "%s - %s" % (fname, fdesc)})
    render.append("%s\t%s" % (fid, SCENE))

    json.dump({"version": 1,
               "description": "Biomech NG - non-primitive biomech creatures built from generated mesh surfaces (lofting, marching-cubes fusion, superformula, procedural paneling) across four families, each in three palettes, plus a queer / bio / fetish wet-latex showcase.",
               "entries": entries},
              open(os.path.join(GAL, "manifest.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    open(os.path.join(GAL, "_render_list.txt"), "w", encoding="utf-8").write("\n".join(render) + "\n")
    if not os.path.exists(os.path.join(GAL, "evals.json")):
        json.dump({}, open(os.path.join(GAL, "evals.json"), "w", encoding="utf-8"))
    print("wrote %d biomech_ng specimens across %d families" % (len(entries), len(FAMILIES)))
    for e in entries:
        print("  ", e["id"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
