"""build_hidden_gallery_index.py — the gallery pages nothing links to, named and placed.

2026-08-27, Palle: "where can we put like /surreal-lab-gallery and other find other that
are hidden", then "name the 37 unplaced ones properly".

WHAT THIS IS FOR. 165 routes under ada_encyclopedia/src/app have a page.tsx and a
gallery-shaped name. Only about half are reachable from any index: /dna-galleries carries
a hardcoded list, /concept-galleries reads its own generated index, /galleries reads
galleryIndex.ts. Everything else exists and is reachable only by someone who already
knows the URL. This finds those and writes public/dna-galleries/hidden.json, which the
/dna-galleries page renders under each sequence.

WHY IT IS GENERATED. The hardcoded list is exactly how 87 pages got lost - a route is
added, nobody remembers to touch the index, and the page is invisible from that day on.
A generated index cannot drift that way. Re-run it after adding a gallery route.

TWO TIERS, AND THE DIFFERENCE IS DELIBERATE. A gallery in this file has no blurb. The
written-up galleries on /dna-galleries have one because a person looked at them and wrote
it. Inventing prose for the rest would erase the only honest distinction on that page, so
they get a NAME and a SEQUENCE and nothing else.

NAMES ARE AUTHORED, NOT DERIVED, and the first pass proves why. Slug cues placed 50 of
137 and left 37 with nothing - and the 37 were not obscure, they were badly named:
`array-cartridge-gallery` announces in its own manifest that it is for the array_tutorial
sequence (folded into color in August), `codex-morph-gallery` says Conway's Life and
Gray-Scott, `codex-glyph-gallery` says grammar and graph algorithms. The evidence was
sitting in the manifests the whole time; no slug regex was ever going to reach it. So
PLACED below is read off what each gallery says about itself.

  python tools/build_hidden_gallery_index.py
  python tools/build_hidden_gallery_index.py --check    non-zero if any route is unnamed
"""
from __future__ import annotations
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.path.normpath(os.path.join(ROOT, "..", "ada_encyclopedia"))
APP = os.path.join(ENC, "src", "app")
PUB = os.path.join(ENC, "public")
OUT = os.path.join(PUB, "dna-galleries", "hidden.json")

GALLERY_ROUTE = re.compile(r"(galler|^dna-|-dna$|-concepts$)", re.I)

# Not galleries: index pages that happen to match the name pattern. `concept-galleries`
# was listed among the "hidden galleries" in the first pass, which was wrong - it is the
# index OF the concept galleries, and putting it in a list of things it indexes is a
# small nonsense worth not shipping.
NOT_A_GALLERY = {"dna-galleries", "concept-galleries", "principle-galleries", "galleries"}

# (sequence, display name). Read off each gallery's own manifest description and page
# title. "" for sequence means genuinely cross-cutting - the subject is the corpus or the
# rig, not a rung of the curriculum - and those render under "Across the spine".
PLACED = {
    # array_tutorial dissolved into color in August as its index + rule rungs, so its
    # substrate work belongs to colour now rather than to a sequence that is gone.
    "array-cartridge-gallery": ("color", "Array Cartridges — grid2d substrates"),
    "array-probe-dna": ("color", "The Array Probe — twelve expressions"),

    "vector-bench-gallery": ("forces", "The Vector Bench — small machines for vector concepts"),
    "vector-toys-gallery": ("forces", "Embodied Vector & Force Toys"),
    "principle-field-gallery": ("forces", "The Field Principle — 65 artifacts"),

    "principle-geometric-gallery": ("primitives", "The Geometric Principle — 162 artifacts"),

    "codex-glyph-gallery": ("lsystems", "Codex Glyph — asemic grammar and graphs"),
    "living-dna": ("lsystems", "Living DNA — the biome's organisms, one grammar token each"),
    "tree-dna": ("lsystems", "Tree DNA"),
    "principle-grammatical-gallery": ("lsystems", "The Grammatical Principle — 33 artifacts"),

    "codex-morph-gallery": ("cellularautomata", "Codex Morphogenesis — Life, Gray-Scott, evolution"),
    "principle-iterative-gallery": ("cellularautomata", "The Iterative Principle — 7 artifacts"),

    "codex-arch-gallery": ("proceduralgeneration", "Codex Arches — anamorphic architecture"),
    "codex-food-gallery": ("proceduralgeneration", "Codex Food — vegetable-machines"),

    "concept-architecture-gallery": ("postfoundationscrisis",
                                     "Concept Architecture — four engulfing structures"),

    # --- cross-cutting: the subject is the collection or the rig, not a rung ----------
    "sequence-cards-gallery": ("", "Sequence Picker Cards — 22 chamber icons"),
    "cabinet-gallery": ("", "The Cabinet Family — one grammar, sixteen bodies"),
    "crates-boxes-gallery": ("", "Crates & Boxes"),
    "props-dna-gallery": ("", "Lab & Facility Props DNA"),
    "props-shape-gallery": ("", "Lab Props Shape Sweep"),
    "installation-stands-gallery": ("", "Installation Stands"),
    "interactable-demos-gallery": ("", "Interactable Demos"),
    "interactable-layouts-gallery": ("", "Interactable Layouts"),
    "interactable-scenes-gallery": ("", "Interactable Scenes"),
    "grid-editor-gallery": ("", "Grid Layouts"),
    "rack-gallery": ("", "Rack Configurations"),
    "interface-presets-gallery": ("", "Principal Interface Setups — the 17 canonical types"),
    "template-gallery": ("", "Templates"),
    "principal-gallery": ("", "Principal Artifacts"),
    "dna-best": ("", "DNA Best Of — three expressions per artifact"),
    "dna-triptych": ("", "One Knob, Three Meanings"),
    "gallery-dna": ("", "Gallery DNA — evolved empty architecture"),
    "artifact-dna": ("", "Artifact DNA"),
    "map-dna": ("", "Map DNA"),
    "synthesis-gallery": ("", "The Synthesis Passes — one frame per wave"),
    "collations-dna": ("", "Collations — laser_measure at hand scale"),
}

# Slug cues for everything not hand-named. Specific first; the slug decides and prose
# never does — the same rule as tools/gallery_spine_map.py, for the same reason.
CUES = [
    ("softbodies", ["soft-body", "softbody", "spring", "verlet", "cloth"]),
    ("isosurfaces", ["isosurface", "marching", "metaball", "sdf"]),
    ("boolean_surfaces", ["boolean", "csg", "radiolaria"]),
    ("lsystems", ["lsystem", "l-system", "turtle", "grammar", "flora", "botanical", "haeckel"]),
    ("cellularautomata", ["ca-rules", "wolfram", "lenia", "complexity-dial", "rd-"]),
    ("fractals", ["fractal", "koch", "julia"]),
    ("noise", ["perlin", "noise", "truchet"]),
    ("randomness", ["random", "stochastic", "galton", "poisson", "voronoi"]),
    ("graphtheory", ["graph", "loom", "adjacency", "bottleneck"]),
    ("proceduralgeneration", ["procgen", "procedural", "facade", "pipes", "compositions-auto",
                              "interactables-auto", "rack-auto"]),
    ("formfinding", ["morpholog", "self-portrait", "sculpture", "form-gallery"]),
    ("swarmintelligence", ["swarm", "boid", "flock", "critter", "fungus", "biome", "biomech"]),
    ("machinelearning", ["gradient", "neural", "optimization", "learn"]),
    ("primitives", ["parametric", "primitive", "platonic", "johnson", "prism", "mesh",
                    "coordinate", "triangle", "grid-substrate"]),
    ("transformation", ["transform", "rotation", "matrix", "composition"]),
    ("color", ["colour", "color", "chromatic", "pattern", "tartan", "turrell", "great-wave",
               "interface-skins"]),
    ("wavefunctions", ["wave", "sine", "harmonic", "fourier", "audio"]),
    ("forces", ["force", "gravity", "physics", "trajectory", "catapult", "hazard"]),
    ("change", ["riemann", "tangent", "slope", "derivative"]),
    ("foundationscrisis", ["godel", "russell", "halting", "paradox", "shannon", "cantor"]),
    ("qfeplaboratory", ["qfep", "lab-room", "lab-"]),
    ("postfoundationscrisis", ["bias", "commons", "rhizome", "readymades", "dark-spot"]),
]


def titleise(slug: str) -> str:
    s = slug.replace("-gallery", "").replace("-", " ").replace("_", " ")
    return " ".join(w.upper() if w in ("dna", "ca", "rd", "csg") else w.capitalize()
                    for w in s.split())


def cue_for(slug: str):
    low = slug.replace("_", "-").lower()
    for seq, cues in CUES:
        for c in cues:
            if c in low:
                return seq, c
    return "", ""


def indexed() -> set:
    out = set()
    p = os.path.join(APP, "dna-galleries", "page.tsx")
    if os.path.isfile(p):
        out |= set(re.findall(r'slug:\s*"([^"]+)"', open(p, encoding="utf-8").read()))
    p = os.path.join(PUB, "concept-galleries", "index.json")
    if os.path.isfile(p):
        try:
            j = json.load(open(p, encoding="utf-8"))
            rows = j if isinstance(j, list) else j.get("galleries") or j.get("rows") or []
            out |= {str(r.get("seq", "")) + "-concepts" for r in rows if isinstance(r, dict)}
        except Exception:
            pass
    p = os.path.join(ENC, "src", "lib", "galleryIndex.ts")
    if os.path.isfile(p):
        out |= set(re.findall(r"['\"]([a-z0-9][a-z0-9\-_]{3,60})['\"]",
                              open(p, encoding="utf-8").read()))
    return out


def main() -> int:
    check = "--check" in sys.argv
    routes = {d for d in os.listdir(APP)
              if os.path.isfile(os.path.join(APP, d, "page.tsx"))
              and GALLERY_ROUTE.search(d) and d not in NOT_A_GALLERY}
    known = indexed()
    hidden = sorted(routes - known)

    rows, unnamed = [], []
    for slug in hidden:
        tiles, desc = None, ""
        mp = os.path.join(PUB, slug, "manifest.json")
        if os.path.isfile(mp):
            try:
                m = json.load(open(mp, encoding="utf-8"))
                tiles = len(m.get("entries") or []) or None
                desc = (m.get("description") or "")[:240]
            except Exception:
                pass
        if slug in PLACED:
            seq, name = PLACED[slug]
            how = "named"
        else:
            seq, cue = cue_for(slug)
            name = titleise(slug)
            how = ("cue:" + cue) if cue else "unnamed"
            if not seq:
                unnamed.append(slug)
        rows.append({"slug": slug, "name": name, "sequence": seq, "how": how,
                     "tiles": tiles, "description": desc})

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump({"generated_by": "tools/build_hidden_gallery_index.py",
               "note": "gallery routes reachable from no index. name+sequence authored in PLACED.",
               "count": len(rows), "galleries": rows},
              open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

    named = sum(1 for r in rows if r["how"] == "named")
    cued = sum(1 for r in rows if r["how"].startswith("cue:"))
    cross = sum(1 for r in rows if r["how"] == "named" and not r["sequence"])
    print("hidden gallery routes : %d" % len(rows))
    print("  hand-named          : %d  (%d of them cross-cutting)" % (named, cross))
    print("  placed by slug cue  : %d" % cued)
    print("  still unnamed       : %d" % len(unnamed))
    for s in unnamed:
        print("      " + s)
    print("-> %s" % os.path.relpath(OUT, ENC).replace("\\", "/"))
    return 1 if (check and unnamed) else 0


if __name__ == "__main__":
    raise SystemExit(main())
