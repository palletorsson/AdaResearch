#!/usr/bin/env python3
"""Codex glyph (grammars & graphs) auto-research generator.

Four families, one per mode of codex_glyph.gd - Luigi Serafini's Codex
Seraphinianus asemic writing-system rendered as GENUINE grammar + graph
algorithms, teaching specimens for the lsystems / graphtheory spine sequences:
  glyphgrid (combinatorial stroke-grammar alphabet) · branchscript (L-system
  letterform) · glyphgraph (graph-theory network with a highlighted Prim's MST) ·
  codexcolumn (generative cursive script).

Each family carries three palette triads (PARCHMENT color_a / INK color_b / GLOW
accent). The glyphgraph accent drives the MST highlight, so its palettes use
jewel/cyan accents; the others use gold/ochre illumination. Writes specimens + a
GalleryView manifest into the encyclopedia codex-glyph-gallery (images live in the
encyclopedia, never the Godot repo).
"""
from __future__ import annotations
import json, os, random, sys

GAL = r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\codex-glyph-gallery"
SCENE = "res://commons/artifacts/codex_glyph/codex_glyph.tscn"

# palette triads: (color_a PARCHMENT, color_b INK, accent GLOW)
GLYPHGRID_PAL = [
    ("0.86,0.80,0.66", "0.22,0.16,0.12", "0.85,0.45,0.25"),  # cream / sepia / red-ochre
    ("0.82,0.78,0.70", "0.16,0.18,0.24", "0.90,0.70,0.25"),  # grey-parchment / blue-black / gold
    ("0.80,0.74,0.60", "0.26,0.14,0.14", "0.45,0.70,0.85"),  # tan / oxblood / blue rubric
]
BRANCHSCRIPT_PAL = [
    ("0.80,0.72,0.58", "0.20,0.15,0.12", "0.90,0.55,0.30"),  # stone / sepia / gold
    ("0.76,0.74,0.68", "0.14,0.14,0.20", "0.95,0.80,0.35"),  # pale / blue-black / bright gold
    ("0.82,0.70,0.55", "0.24,0.12,0.14", "0.55,0.85,0.95"),  # tan / oxblood / cyan tip
]
GLYPHGRAPH_PAL = [  # accent drives the MST highlight - jewel tones
    ("0.82,0.76,0.62", "0.24,0.18,0.14", "0.40,0.85,0.95"),  # stone / sepia / cyan MST
    ("0.80,0.78,0.74", "0.18,0.18,0.22", "0.55,1.00,0.65"),  # grey / ink / green MST
    ("0.84,0.74,0.62", "0.26,0.16,0.16", "0.95,0.55,0.75"),  # tan / oxblood / magenta MST
]
CODEXCOLUMN_PAL = [
    ("0.87,0.81,0.67", "0.20,0.15,0.12", "0.88,0.50,0.28"),  # cream / sepia / gold
    ("0.84,0.80,0.72", "0.15,0.16,0.22", "0.92,0.74,0.30"),  # grey / blue-black / gold
    ("0.85,0.76,0.62", "0.24,0.13,0.13", "0.50,0.75,0.90"),  # tan / oxblood / blue
]


def j(v: float) -> float:
    return round(v, 3)


def base(rng: random.Random, mode: str, triad: tuple) -> dict:
    a, b, c = triad
    return {"mode": mode, "seed": rng.randint(1, 99999),
            "color_a": a, "color_b": b, "accent": c}


def fam_glyphgrid(rng, triad):
    d = base(rng, "glyphgrid", triad)
    d.update({"sculpt_height": j(rng.uniform(1.9, 2.2)), "sculpt_width": j(rng.uniform(2.0, 2.3)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.7, "emissive": True})
    return d, "Glyphgrid (stroke-grammar)", "A combinatorial stroke-grammar - 7 stroke primitives composed by 4 attachment rules into a grid of distinct asemic glyphs in raised relief on a parchment tablet, some gold-rubricated."


def fam_branchscript(rng, triad):
    d = base(rng, "branchscript", triad)
    d.update({"sculpt_height": j(rng.uniform(2.3, 2.6)), "sculpt_width": j(rng.uniform(1.5, 1.8)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.7, "emissive": True})
    return d, "Branchscript (L-system letter)", "A real bracketed L-system - axiom + production rules expanded over generations, a 3D turtle growing a single ornate branching letterform with curling flourishes and illuminated tips."


def fam_glyphgraph(rng, triad):
    d = base(rng, "glyphgraph", triad)
    d.update({"sculpt_height": j(rng.uniform(1.7, 2.0)), "sculpt_width": j(rng.uniform(2.2, 2.5)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.7, "emissive": True})
    return d, "Glyphgraph (MST network)", "Real graph theory - a glyph-node network whose Prim's minimum spanning tree is computed and highlighted as glowing arcs threading the dim web of edges."


def fam_codexcolumn(rng, triad):
    d = base(rng, "codexcolumn", triad)
    d.update({"sculpt_height": j(rng.uniform(2.3, 2.6)), "sculpt_width": j(rng.uniform(1.6, 1.9)),
              "complexity": rng.randint(5, 7), "metallic_amt": 0.0, "rough_amt": 0.7, "emissive": True})
    return d, "Codexcolumn (cursive script)", "Generative cursive - a pen-walk of sine + value-noise + loops + word-gaps swept as raised ink ribbons into lines of flowing asemic script on a parchment stele, with an illuminated initial."


FAMILIES = {
    "glyphgrid": (fam_glyphgrid, GLYPHGRID_PAL),
    "branchscript": (fam_branchscript, BRANCHSCRIPT_PAL),
    "glyphgraph": (fam_glyphgraph, GLYPHGRAPH_PAL),
    "codexcolumn": (fam_codexcolumn, CODEXCOLUMN_PAL),
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
    rng = random.Random(82355)
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
            cid = "cg_%s_%05x" % (fam, rng.randint(0, 1 << 20))
            json.dump({"id": cid, "name": name, "description": desc, "family": fam,
                       "score": round(sc, 2), "selection_rank": rank, "scene": SCENE, "dna": d},
                      open(os.path.join(GAL, cid + ".json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
            entries.append({"id": cid, "image": "/codex-glyph-gallery/%s.png" % cid,
                            "config": "/codex-glyph-gallery/%s.json" % cid, "notes": "%s - %s" % (name, desc)})
            render.append("%s\t%s" % (cid, SCENE))
    json.dump({"version": 1,
               "description": "Codex glyph - Serafini's asemic writing-system as genuine grammar + graph algorithms for the lsystems / graphtheory labs: glyphgrid / branchscript / glyphgraph / codexcolumn, four modes in three palettes each.",
               "entries": entries},
              open(os.path.join(GAL, "manifest.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    open(os.path.join(GAL, "_render_list.txt"), "w", encoding="utf-8").write("\n".join(render) + "\n")
    if not os.path.exists(os.path.join(GAL, "evals.json")):
        json.dump({}, open(os.path.join(GAL, "evals.json"), "w", encoding="utf-8"))
    print("wrote %d codex_glyph specimens across %d families" % (len(entries), len(FAMILIES)))
    for e in entries:
        print("  ", e["id"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
