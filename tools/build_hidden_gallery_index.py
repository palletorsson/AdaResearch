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

TWO TIERS, AND THE DIFFERENCE IS DELIBERATE. This file first shipped with names and no
blurbs, on the grounds that inventing prose would put an unread gallery on equal footing
with one somebody had looked at. The 21 cross-cutting ones have blurbs now because they
were then READ - manifest description, entry count, sample entries and page source, one at
a time - so the prose is reporting rather than invention. The 50 placed by slug cue still
have none, and that is the same rule still running: a blurb means somebody looked.

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
    "sequence-cards-gallery": ("", "Sequence Picker Cards — 22 chamber icons",
     "Each of the 22 spine sequences as a picker card - number, name, qfep_role, phase colour, map count, and a procedural Portal-2-style chamber glyph drawn live in GDScript. The same SequenceGlyph Control runs the main-menu picker, so this is not a mock-up of the menu; it is the menu's own catalogue, published side by side."),
    "cabinet-gallery": ("", "The Cabinet Family — one grammar, sixteen bodies",
     "Sixteen artifacts that used to scatter their readouts, titles and keypads into the air, rebuilt as single appliances in one shared grammar: an interface is part of a body, and the body's shape follows what it does. Thirteen body types across two dialects - vertical, which you face, and horizontal, which you look down at. The first nine carry three views each, the seven hero-wave members a single front. All compose HangarKit."),
    "crates-boxes-gallery": ("", "Crates & Boxes",
     "Scored DNA variants of crate.gd and cardboard_box.gd, swept across five families: raw, weathered and dark wooden crates, white-painted, and cardboard. The humblest artifacts in the corpus and the ones most likely to be placed by the hundred, which is exactly why they were worth researching instead of guessing."),
    "props-dna-gallery": ("", "Lab & Facility Props DNA",
     "The lab_room substrate ships empty; the chamber needs its furniture. Eight prop artifacts - exit_sign, sliding_door, whiteboard, large_table, large_window, info_screen, ceiling_vent, cable_tray - in three DNA configurations each, same .gd and same .tscn every time. Every row exercises the prop's declared critical_parameter, so sliding_door runs shut / mid-gesture / fully open rather than three colours of the same door."),
    "props-shape-gallery": ("", "Lab Props Shape Sweep",
     "Sister to the props DNA gallery, sweeping the other axis. Where that one varies colour, count and state, this varies DIMENSION - width, length, height, slat_count, cable_count - eight props at five sizes each. Camera distance scales with each cell's AABB, so a 5 m table really does read bigger than a 1 m one instead of being normalised back into the same picture."),
    "installation-stands-gallery": ("", "Installation Stands",
     "Large-scale modular infrastructure for installing technology. The grammar starts from a 1 m cube, a 2 m frame and a 0.5 m shelf, then composes screens, speakers, light bars, equipment boxes and telescopic masts. Auto-researched rather than authored: the manifest is generated from whatever the sweep produced."),
    "interactable-demos-gallery": ("", "Interactable Demos",
     "Four composite demo scenes - every control in one view, then singles, compounds and passives apart. This is where the procedural module types get photographed together: touch_grid, rotary_selector, needle_meter, patch bay."),
    "interactable-layouts-gallery": ("", "Interactable Layouts",
     "JSON-configured composite boards built from the InteractableDemo vocabulary - scene controls, procedural buttons, passive monitors, compound slider packs, prototype modules. The layout layer above the atoms: same parts, arranged."),
    "interactable-scenes-gallery": ("", "Interactable Scenes",
     "The atoms themselves - seventeen .tscn files from commons/interactables: a dial, three joysticks, three levers, two push buttons, seven sliders and a wheel, each shot with perfect_shot in scene mode. The DNA here is the scene file rather than a parameter, which is why the count is exactly the number of files."),
    "grid-editor-gallery": ("", "Grid Layouts",
     "VR glass-rack, audio-rack and grid-editor layouts, shared by three builder surfaces. The axis is subset stride x alignment x clearance x element placement. Pre-rendered in Godot rather than in the browser, because the rack is the thing being designed and a Three.js approximation would be designing something else."),
    "rack-gallery": ("", "Rack Configurations",
     "Every eurorack preset in the project, exported from Godot and re-rendered in Three.js so the cards are interactive - click one and turn its controls. The only gallery here you can operate rather than only look at."),
    "interface-presets-gallery": ("", "Principal Interface Setups — the 17 canonical types",
     "Over a thousand interface artifacts are being unified onto one board/console system, and these are the principal configs: workbench, machine, console and fourteen more, each a single source of truth in commons rather than a per-artifact improvisation. The reference sheet the unification is being carried out against."),
    "template-gallery": ("", "Templates",
     "Every placement contract in the project, shown as what it does to a 14x10 zone - heights shaded, green rings where an artifact may stand. Not pictures of maps but pictures of the RULES maps are built from. Click a card to paint with it in /template-maps."),
    "principal-gallery": ("", "Principal Artifacts",
     "Every artifact family - shared-scene principals and interface-kin - as its own DNA gallery, up to ten examples each with verdicts enabled. An index of the FAMILIES rather than of the galleries, and the surface where you find out that one scene answers to four registry names."),
    "dna-best": ("", "DNA Best Of — three expressions per artifact",
     "The three best expressions of every DNA-researched artifact in the project, drawn from every sweep gallery at once. Ranking is Palle's star evals first, curated picks second, authored order last - so the sheet records what was actually judged good rather than what happened to render. Rebuilt by tools/build_dna_best.py."),
    "dna-triptych": ("", "One Knob, Three Meanings",
     "One knob, three meanings. Each machine at three values of a single parameter, side by side, so the axis reads as a sentence instead of a slider. The most compressed argument the DNA work makes."),
    "gallery-dna": ("", "Gallery DNA — evolved empty architecture",
     "Twelve champion rooms evolved from three taste-profiles - empty architecture bred rather than authored - with the learning curve kept alongside, so you can see which taste converged and which wandered."),
    "artifact-dna": ("", "Artifact DNA",
     "Stage 2 of the DNA programme: variation, measured by REACH - how many map placements a family actually has, not how many artifacts exist. The dashboard that decides where promotion effort goes, and the reason the corpus's largest families are not its most promoted ones."),
    "map-dna": ("", "Map DNA",
     "One DNA gallery per map: every artifact in a map's cast promoted to an entry carrying its current genome - registry plus dressing room plus map token. Sorted weakest-coverage first, so the table IS the auto-research queue rather than a report about one."),
    "synthesis-gallery": ("", "The Synthesis Passes — one frame per wave",
     "One frame from each synthesis wave - boundary_tank, removal_room, rack_room and the rest. An artifact in this corpus is a family rather than one object: it declares axes, and each value of an axis is a photograph from a fixed camera. This is the shortest route to seeing what that has produced."),
    "collations-dna": ("", "Collations — laser_measure at hand scale",
     "A collation is multiples of one object, each with its own config. laser_measure rebuilt at hand scale with the LCD housing saddled OVER the barrel instead of floating tangent to it, and draw_dot crossed ink x retention so a collation of them can each write in a different colour, addressable from a map token (#ink:cyan). Five inks; magenta is byte-for-byte the legacy default."),
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
            spec = PLACED[slug]
            seq, name = spec[0], spec[1]
            blurb = spec[2] if len(spec) > 2 else ""
            how = "named"
        else:
            seq, cue = cue_for(slug)
            name = titleise(slug)
            blurb = ""
            how = ("cue:" + cue) if cue else "unnamed"
            if not seq:
                unnamed.append(slug)
        rows.append({"slug": slug, "name": name, "sequence": seq, "how": how,
                     "blurb": blurb, "tiles": tiles, "description": desc})

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump({"generated_by": "tools/build_hidden_gallery_index.py",
               "note": "gallery routes reachable from no index. name+sequence authored in PLACED.",
               "count": len(rows), "galleries": rows},
              open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

    blurbed = sum(1 for r in rows if r.get("blurb"))
    named = sum(1 for r in rows if r["how"] == "named")
    cued = sum(1 for r in rows if r["how"].startswith("cue:"))
    cross = sum(1 for r in rows if r["how"] == "named" and not r["sequence"])
    print("hidden gallery routes : %d" % len(rows))
    print("  hand-named          : %d  (%d of them cross-cutting)" % (named, cross))
    print("  placed by slug cue  : %d" % cued)
    print("  with a blurb        : %d" % blurbed)
    print("  still unnamed       : %d" % len(unnamed))
    for s in unnamed:
        print("      " + s)
    print("-> %s" % os.path.relpath(OUT, ENC).replace("\\", "/"))
    return 1 if (check and unnamed) else 0


if __name__ == "__main__":
    raise SystemExit(main())
