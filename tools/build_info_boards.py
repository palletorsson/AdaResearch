# -*- coding: utf-8 -*-
"""build_info_boards.py — what each map holds, and what it holds too early.

Palle: an info board per spine map showing which algorithms are the TOPIC (lit)
and which are PRESENT BUT NOT YET INTRODUCED (greyed) — so a map that quietly
uses randomness in chapter two shows randomness dim, and chapter ten lights it.
Later the lit ones combine: a translated laser plus collision detection removes
cubes.

The introduction schedule is not invented: the 24 spine sequences ARE it, in
curriculum order. A term owned by sequence N is introduced at N, and any map
before N that uses it is using it early. Finer terms that live inside a sequence
(point, line, cube, laser, collision, loop) are pinned to the sequence that
teaches them.

DETECTION IS A KEYWORD MATCH and says so. A map "holds" a term if the term
appears in one of its artifacts' lookup name, category, tags or description.
That will over-fire on a word used loosely and under-fire on a concept nobody
named. It is a first pass over 269 maps, not a proof, and the board shows the
evidence so a wrong light can be argued with.

    python tools/build_info_boards.py
"""
import json, re, argparse, pathlib, sys
from collections import Counter

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "commons/data/info_boards.json"
sys.path.insert(0, str(ROOT / "tools"))
import walk_polish as wp                       # noqa: E402
import spine_typologies as sty                 # noqa: E402

# THE VOCABULARY. Each term carries the sequence that introduces it and the
# words that betray its presence. Terms are the things a map can be ABOUT; the
# sequence order decides when each becomes fair game.
VOCAB = [
    ("point",        "primitives",           ["point", "origin", "vertex", "dot"]),
    ("line",         "primitives",           ["line", "segment", "edge", "trace", "ray"]),
    ("plane",        "primitives",           ["plane", "surface", "quad", "face"]),
    ("primitive",    "primitives",           ["primitive", "polyhedra", "sphere", "cylinder", "torus"]),
    ("cube",         "primitives",           ["cube", "box", "voxel", "block"]),
    ("laser",        "primitives",           ["laser", "beam", "measure"]),
    ("transform",    "transformation",       ["transform", "translate", "translation", "rotate",
                                              "rotation", "scale", "matrix"]),
    ("symmetry",     "symmetry",             ["symmetry", "mirror", "glide", "wallpaper", "motif",
                                              "kaleidoscope", "tile"]),
    ("array",        "array_tutorial",       ["array", "grid", "index", "row", "column", "lattice"]),
    ("loop",         "array_tutorial",       ["loop", "iterate", "repeat", "recursion", "recursive"]),
    ("colour",       "color",                ["color", "colour", "hue", "palette", "rgb", "paint"]),
    ("change",       "change",               ["derivative", "slope", "velocity", "rate", "delta",
                                              "calculus"]),
    ("force",        "forces",               ["force", "gravity", "spring", "physics", "newton",
                                              "acceleration", "momentum"]),
    ("collision",    "forces",               ["collision", "collide", "contact", "impact", "bounce"]),
    ("formfinding",  "formfinding",          ["catenary", "equilibrium", "relaxation", "annealing",
                                              "minimal", "descent"]),
    ("wave",         "wavefunctions",        ["sine", "cosine", "oscillat", "waveform",
                                              "pendulum", "harmonic", "frequency"]),
    ("randomness",   "randomness",           ["random", "stochastic", "gaussian", "entropy",
                                              "probability", "dice", "coin"]),
    ("noise",        "noise",                ["noise", "perlin", "simplex", "flow field", "turbulence"]),
    ("automata",     "cellularautomata",     ["cellular", "automat", "rule 110", "life", "neighbour"]),
    ("fractal",      "fractals",             ["fractal", "mandelbrot", "julia", "koch", "sierpinski",
                                              "menger", "cantor", "self-similar"]),
    ("grammar",      "lsystems",             ["l-system", "lsystem", "grammar", "rewrite", "axiom",
                                              "production"]),
    ("procedural",   "proceduralgeneration", # NOT the bare word "procedural": the registry has a CATEGORY of
     # that name meaning "procedurally generated mesh", which lit 89 maps
     # that teach nothing of the kind. Only the algorithms count.
     ["wfc", "wave function collapse", "markov chain",
      "poisson disk", "procedural generation"]),
    ("softbody",     "softbodies",           ["softbody", "soft body", "cloth", "deform", "elastic",
                                              "jelly"]),
    ("isosurface",   "isosurfaces",          ["isosurface", "marching cube", "metaball",
                                              "implicit surface", "signed distance"]),
    ("boolean",      "boolean_surfaces",     ["boolean", "csg", "constructive solid"]),
    ("swarm",        "swarmintelligence",    ["swarm", "boid", "flock", "ant colony", "stigmergy",
                                              "pheromone", "physarum"]),
    ("learning",     "machinelearning",      ["neural", "machine learning", "perceptron",
                                              "backprop", "training set", "classifier"]),
    ("graph",        "graphtheory",          ["graph", "adjacency", "edge list", "traversal",
                                              "shortest path", "dijkstra", "a-star"]),
    ("limit",        "foundationscrisis",    ["godel", "gödel", "russell", "paradox", "incomplete",
                                              "undecidable", "halting"]),
]


def registry():
    reg = {}
    for f in (ROOT / "commons/artifacts/registry").glob("*.json"):
        try:
            d = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        for k, v in (d.get("artifacts", d) or {}).items():
            if isinstance(v, dict):
                reg[k] = v
    return reg


def body_constants():
    """eye and fov from the Vitruvian block — the same body the camera stands as."""
    try:
        v = json.loads((ROOT / "commons/data/museum_principles.json")
                       .read_text(encoding="utf-8"))["vitruvian"]
        return float(v["eye_height_m"]["value"]), float(v["fov_deg"]["value"])
    except Exception:
        return 1.65, 90.0


EYE, FOV = body_constants()


def build():
    spine = json.loads((ROOT / "commons/maps/curriculum_spine.json").read_text(encoding="utf-8"))
    seq_order = {s["name"]: s.get("order", 99) for s in spine["spine"]["sequences"]}
    phase = {s["name"]: s.get("phase", "") for s in spine["spine"]["sequences"]}
    reg = registry()
    terms = [{"term": t, "owner": o, "intro": seq_order.get(o, 99), "words": w}
             for t, o, w in VOCAB]

    boards, early_total = {}, Counter()
    order_i = 0
    for seq, nm in sty.spine_maps():
        md = wp.load(nm)
        if not md:
            continue
        I = wp.grids(md)[2]
        cast = []
        for row in I:
            for c in row:
                s = str(c).strip()
                if s and not s.startswith(wp.PRE) and not s.startswith("hangar_"):
                    tok = s.split(":")[0]
                    if tok not in cast:
                        cast.append(tok)
        # the searchable text of this map: its own name plus each artifact's entry
        hay = {}
        for tok in cast:
            e = reg.get(tok, {})
            hay[tok] = " ".join([tok, str(e.get("category", "")),
                                 " ".join(map(str, e.get("tags", []) or [])),
                                 str(e.get("description", "")),
                                 str(e.get("name", ""))]).lower()
        mine = seq_order.get(seq, 99)
        held = []
        for t in terms:
            hits = [tok for tok, h in hay.items()
                    if any(re.search(r"\b" + re.escape(w), h) for w in t["words"])]
            if not hits and not any(re.search(r"\b" + re.escape(w), nm.lower()) for w in t["words"]):
                continue
            state = ("topic" if t["owner"] == seq else
                     "lit" if t["intro"] < mine else
                     "early")
            if state == "early":
                early_total[t["term"]] += 1
            held.append({"term": t["term"], "owner": t["owner"], "intro": t["intro"],
                         "state": state, "evidence": hits[:4]})
        # THE SUBSTRATE ROW. Everything a point needs in order to exist, almost
        # none of which the curriculum names. Searched across all 24 spine
        # sequences (the loose patterns, then every hit read by hand):
        #   collider · camera · XR        0 hits. Named nowhere.
        #   scene graph                   3 hits, all false — "non-hierarchical"
        #                                 is the rhizome, not the node tree.
        #   clock / delta time            1 hit, a compute-budget tag ("TICK").
        #   shader                        2 hits: an artifact token and a budget
        #                                 note. Apparatus, not lesson.
        #   rasterization                 1 real line, in primitives objectives.
        #   the grid                      TAUGHT — as `array`, sequence 3, two
        #                                 sequences after the maps are made of it.
        # So these are shown and not taught. The row is always lit and never a
        # topic: the conditions you are standing in, not the lesson you are in.
        S, U, I2, WL = wp.grids(md)
        cells = [wp.h_at(S, x, z) for z in range(len(S)) for x in range(len(S[z]))]
        solid = [h for h in cells if h > 0]
        substrate = {
            "cubes": len(solid),
            "floor": sum(1 for h in solid if h <= 3),
            "wall": sum(1 for h in solid if h >= 4),
            "levels": len(sorted({h for h in solid})),
            "grid": "%dx%d" % (max((len(r) for r in S), default=0), len(S)),
            "collider": bool(solid),
            "eye_m": EYE, "fov_deg": FOV,
            "utilities": sum(1 for r in U for c in r if str(c).strip()),
        }
        boards[nm] = {"map": nm, "sequence": seq, "phase": phase.get(seq, ""),
                      "substrate": substrate,
                      "seq_order": mine, "spine_index": order_i,
                      "cast": len(cast), "terms": held,
                      "topic": [h["term"] for h in held if h["state"] == "topic"],
                      "lit": [h["term"] for h in held if h["state"] == "lit"],
                      "early": [h["term"] for h in held if h["state"] == "early"]}
        order_i += 1

    OUT.write_text(json.dumps({
        "_readme": ("One info board per spine map. `topic` = a term this map's own sequence "
                    "introduces; `lit` = introduced earlier in the curriculum, so fair game; "
                    "`early` = PRESENT BUT NOT YET INTRODUCED — the map uses it before the "
                    "curriculum has taught it. Detection is a keyword match over each artifact's "
                    "lookup name, category, tags and description, and every term carries the "
                    "artifacts that triggered it so a wrong light can be argued with."),
        "substrate_note": ("Everything a point needs in order to exist, almost none of which "
                           "the curriculum names. Across the 24 spine sequences: collider, camera "
                           "and XR score zero hits; clock and shader appear only as notes the "
                           "authors left themselves; rasterization gets one line; and the grid — "
                           "the floor from the first second — is taught at sequence 3, as `array`. "
                           "The point is taught first and is last to exist. Measured per map here: "
                           "grid, cubes, floor, wall, levels, collider, utilities. Constants of the "
                           "runtime, true by construction and not measured: clock, shader, XR. "
                           "eye_m and fov_deg come from the Vitruvian block."),
        "vocabulary": [{"term": t["term"], "introduced_by": t["owner"], "order": t["intro"]}
                       for t in terms],
        "counts": {"maps": len(boards),
                   "maps_using_something_early": sum(1 for b in boards.values() if b["early"]),
                   "early_by_term": dict(early_total.most_common())},
        "boards": boards}, indent=1), encoding="utf-8")
    n_early = sum(1 for b in boards.values() if b["early"])
    print("%d boards -> %s" % (len(boards), OUT))
    print("  maps using a term before it is introduced: %d of %d (%.0f%%)"
          % (n_early, len(boards), 100.0 * n_early / max(1, len(boards))))
    print("  most-used-early terms:", early_total.most_common(8))
    worst = sorted(boards.values(), key=lambda b: -len(b["early"]))[:6]
    print("\n  earliest offenders:")
    for b in worst:
        print("    %-30s seq %-2d  early: %s" % (b["map"][:30], b["seq_order"],
                                                 ", ".join(b["early"][:6])))


if __name__ == "__main__":
    argparse.ArgumentParser().parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    build()
