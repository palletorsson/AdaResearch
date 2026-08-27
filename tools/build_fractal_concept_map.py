"""Build the comprehensive Fractal concept map.

Fifth concept map (vectors, randomness, CA, L-systems, fractals). Fractals are their own chapter — the
one the others are prerequisites for. Scans the registries, classifies fractal artifacts into 19
concepts across 6 acts (recursion & dimension / the classic sets / escape-time / IFS, spirals & growth /
chaos & landscapes / useful structures), tiers each small/medium/large/applied. Writes
doc/fractal_concept_map.json.

Two threads in the truths: the math (self-similarity, dimension between integers, infinite-in-finite)
AND the applications (Act VI) — fractals as the engineer's trick for infinite edge / max surface /
self-supporting structure in finite room: furniture, architecture, antennas. Glances at NoC ch.8
(recursion, the recursive tree, IFS) as the on-ramp; the dimension math, escape-time, and applications
go beyond it. Koch/Sierpinski/Hilbert are shared with the L-system + CA maps as light bridges.

Run from repo root:  python tools/build_fractal_concept_map.py
"""
import json, glob, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG_DIR = os.path.normpath(os.path.join(ROOT, "..", "ada_encyclopedia", "public", "scene-catalog"))

HIGH_SIGNAL = {"fractals.json"}   # no dedicated fractals.json registry — gate-driven
GATE = re.compile(r"fractal|mandelbrot|julia|sierpinski|menger|cantor|koch|recursi|barnsley|"
                  r"strange_attractor|lyapunov|box_count|golden_rectangle|romanesco|fibonacci|"
                  r"diffusion_limited|\bdla\b|space_filling|hilbert3d|snowflake|newton_fractal|burning_ship|"
                  r"recursive_chair|recursive_table|recursive_boolean|cube_bookshelf|cube_cabin|cube_desk|"
                  r"cube_chair|cube_staircase|cube_subdivision|pagoda|inverted_tree|grammar_recursive", re.I)
EXCLUDE = {
    "hilbert_hotel",        # Hilbert's infinity hotel (foundations), not the curve
    "entropy_axiom",
}
def is_candidate(reg, lookup):
    if lookup.lower() in EXCLUDE:
        return False
    if lookup in FORCE:
        return True
    if reg in HIGH_SIGNAL:
        return True
    if re.fullmatch(r"[a-z0-9_]+\.json", reg) and GATE.search(lookup):
        return True
    return bool(GATE.search(lookup))

# concept -> (strong [w3], weak [w1], truth). Order: specific first; ties break to the earlier concept.
CONCEPTS = [
 ("The base case",
  ["base_case", "stop_rule", "depth_limit", "terminator"],
  ["base", "stop", "halt"],
  "The rung that stops it. A function that calls itself and never stops is not a fractal, it is a crash - the engine's stack limit is the first teacher in this sequence."),
 ("The self-call",
  ["self_call", "recursion_animator", "recursion_bench", "call_stack"],
  ["recurse", "self"],
  "func f(): ... f(). The whole of recursion is those four characters, and the engine gives you a stack deep enough to mean it."),
 ("Depth",
  ["depth_dial", "level", "iteration_depth", "generations"],
  ["depth", "levels"],
  "How far down before the base case catches you - and each level costs a frame on the stack. Depth is a budget, and infinity is a promise the machine cannot keep."),
 ("Recursion (calls itself)",
  ["fractal_recursion", "recursion_spiral", "recursion_circles", "example_8_3_recursion", "recursive_boolean"],
  ["recursion", "base case", "self-call"],
  "A rule that contains itself: the whole is in the part, and the part is in the part, with no bottom but the base case."),
 ("Recursive trees",
  ["recursive_tree", "fractal_recursive_tree", "example_8_6_recursive_tree", "fractal_stochastic_tree",
   "grammar_recursive_branching_tree", "inverted_tree"],
  ["branch", "split", "deterministic vs stochastic"],
  "Split, rotate, recurse: the simplest recursion that looks alive — a trunk that is two smaller trees, forever."),
 ("Fractal dimension",
  ["box_counting_dimension", "fractal_dimension"],
  ["box-counting", "hausdorff", "coastline"],
  "D = log N / log S — the coastline that refuses to be 1D or 2D, measured by how the detail multiplies when you zoom."),
 ("Cantor set",
  ["cantor_set", "fractal_cantor", "cantor_pagoda", "cantor_diagonal", "example_8_4_cantor"],
  ["middle third", "dust"],
  "Remove the middle third, forever: a set with zero length that still has as many points as the line. Existence without extension."),
 ("Koch curve & snowflake",
  ["koch_curve", "kochsnowflake", "fractal_koch", "living_paper_koch", "koch_loom", "koch"],
  ["snowflake", "infinite perimeter"],
  "Infinite perimeter around a finite area — D ≈ 1.26, the edge that never resolves no matter how close you look."),
 ("Sierpinski",
  ["sierpinski_triangle", "sierpinski_pyramid", "sierpinskipyramid", "living_paper_sierpinski", "sierpinski"],
  ["gasket", "carpet"],
  "The triangle of triangles of triangles — D ≈ 1.585, and exactly what Rule 90 draws. The same hole at every scale."),
 ("Menger sponge",
  ["menger_sponge", "mengersponge", "menger"],
  ["sponge", "carpet 3d"],
  "A cube with its middles removed forever — D ≈ 2.73, infinite surface around zero volume, a solid you can walk inside."),
 ("Mandelbrot set",
  ["mandelbrot_set", "mandelbrot_dive", "living_paper_mandelbrot", "mandelbrot"],
  ["escape-time", "z^2+c", "boundary"],
  "z -> z² + c, asked of every point: the master fractal, an infinitely intricate boundary between staying and escaping."),
 ("Julia sets",
  ["julia_set", "julia_set_explorer", "living_paper_julia", "julia"],
  ["connected", "dust", "parameter space"],
  "One c, a whole Julia set; move c and the set breathes between connected and dust. Parameter space made visible."),
 ("Lyapunov & escape-time",
  ["lyapunov_fractal", "lyapunov", "newton_fractal", "burning_ship"],
  ["stability", "exponent", "divergence"],
  "Colour by how fast nearby paths diverge, and stability itself becomes a fractal landscape."),
 ("Iterated function systems (IFS)",
  ["barnsley_fern", "barnsley", "ifs_", "chaos_game"],
  ["affine", "chaos game", "attractor"],
  "Four affine maps and a chaos game: throw a point, fold it, repeat — and a fern appears with no fern ever drawn."),
 ("Golden spiral & phyllotaxis",
  ["fibonacci_sequences", "golden_rectangle", "romanesco", "fibonacci_terrain", "fibonacci_pagoda", "fibonacci"],
  ["golden ratio", "137.5", "spiral", "phyllotaxis"],
  "137.5° and the golden ratio: how a sunflower packs seeds and a romanesco stacks cones — the fractal that grows."),
 ("Diffusion-limited aggregation",
  ["diffusion_limited_aggregation", "fractal_hydra", "dla"],
  ["aggregation", "dendrite", "accretion", "lightning"],
  "Random walkers that stick where they land grow a coral, a frost, a lightning — fractal branching from pure chance."),
 ("Strange attractors",
  ["strange_attractors", "lorenz", "rossler", "strange_attractor"],
  ["chaos", "butterfly", "phase space"],
  "A deterministic path that never repeats and never escapes — chaos with a fractal shape, the butterfly given structure."),
 ("Fractal terrain & clouds",
  ["fractal_clouds", "fractal_space", "fractal_terrain", "fbm"],
  ["midpoint displacement", "fbm", "brownian", "landscape"],
  "Stack noise at every scale (fractional Brownian motion) and randomness becomes a mountain, a cloud, a coastline."),
 ("Space-filling curves",
  ["space_filling_curve_gallery", "hilbert3d", "space_filling_floor", "space_filling", "peano"],
  ["fill the volume", "traversal", "hilbert"],
  "A line, recursed, that visits every point of a volume — the bridge to L-systems and to efficient traversal."),
 ("Fractal furniture",
  ["recursive_chair", "recursive_table", "cube_bookshelf", "cube_cabin", "cube_desk", "cube_chair", "recursive_boolean_cube"],
  ["chair", "table", "shelf", "furniture"],
  "Recurse a strut and you get a chair that is chairs; the branching that holds a tree up holds a shelf up too."),
 ("Fractal architecture",
  ["cantor_pagoda", "fibonacci_pagoda", "fractal_scene", "cube_cabin", "cube_staircase", "pagoda"],
  ["facade", "tracery", "tower", "stair"],
  "From Gothic tracery to the Eiffel tower: self-similar structure is how you span the most with the least."),
 ("Fractal antennas & structures",
  ["fractal_antenna", "fractal_heat_exchanger", "fractal_truss", "fractal_radiator", "space_filling_antenna"],
  ["antenna", "heat exchanger", "truss", "multi-band", "surface area"],
  "A self-similar antenna hears every band; a space-filling pipe is all surface; the fractal is the engineer's trick for infinite edge in finite room."),
]

# furniture/architecture/tools are the APPLIED 'useful structure' rung; explorers/dives are tools.
APPLIED_KW = ["explorer", "_dive", "workbench", "gallery", "sculptor", "generator", "_chair", "_table",
              "bookshelf", "cabin", "_desk", "pagoda", "antenna", "exchanger", "truss", "radiator",
              "_scene", "staircase", "_cube"]
LARGE_KW = ["_room", "_hall", "sponge", "pyramid", "_wall", "tower", "_space", "_clouds"]
def tier_of(lookup, name, fp):
    low = (lookup + " " + name).lower()
    if any(k in low for k in APPLIED_KW): return "applied"
    if any(k in low for k in LARGE_KW) or fp >= 9: return "large"
    if fp >= 3: return "medium"
    return "small"

FORCE = {
  "fractal_antenna_toy": ("Fractal antennas & structures", "small"),
  "fractal_heat_exchanger": ("Fractal antennas & structures", "medium"),
  "fractal_truss_tower": ("Fractal antennas & structures", "large"),
  "fractal_antenna": ("Fractal antennas & structures", "applied"),
  "fractal_stool_toy": ("Fractal furniture", "small"),
  "furniture_recursion_bench": ("Fractal furniture", "medium"),
  "fractal_furniture_room": ("Fractal furniture", "large"),
  "fractal_facade_toy": ("Fractal architecture", "small"),
  "fractal_arch_bench": ("Fractal architecture", "medium"),
  "fractal_skyline_room": ("Fractal architecture", "large"),
  "recursion_bench": ("Recursion (calls itself)", "medium"),
  "recursive_tree_bench": ("Recursive trees", "medium"),
  "recursion_animator": ("Recursive trees", "applied"),
  "dimension_bench": ("Fractal dimension", "medium"),
  "dimension_room": ("Fractal dimension", "large"),
  "dimension_meter": ("Fractal dimension", "applied"),
  "cantor_bench": ("Cantor set", "medium"),
  "koch_snowflake_press": ("Koch curve & snowflake", "applied"),
  "sierpinski_bench": ("Sierpinski", "medium"),
  "sierpinski_stamp": ("Sierpinski", "applied"),
  "menger_toy": ("Menger sponge", "small"),
  "menger_bench": ("Menger sponge", "medium"),
  "menger_filter": ("Menger sponge", "applied"),
  "mandelbrot_bench": ("Mandelbrot set", "medium"),
  "julia_bench": ("Julia sets", "medium"),
  "lyapunov_bench": ("Lyapunov & escape-time", "medium"),
  "escape_time_room": ("Lyapunov & escape-time", "large"),
  "newton_fractal_tool": ("Lyapunov & escape-time", "applied"),
  "ifs_bench": ("Iterated function systems (IFS)", "medium"),
  "ifs_room": ("Iterated function systems (IFS)", "large"),
  "chaos_game_tool": ("Iterated function systems (IFS)", "applied"),
  "golden_spiral_bench": ("Golden spiral & phyllotaxis", "medium"),
  "dla_bench": ("Diffusion-limited aggregation", "medium"),
  "dla_grower": ("Diffusion-limited aggregation", "applied"),
  "attractor_bench": ("Strange attractors", "medium"),
  "attractor_room": ("Strange attractors", "large"),
  "attractor_plotter": ("Strange attractors", "applied"),
  "terrain_toy": ("Fractal terrain & clouds", "small"),
  "terrain_bench": ("Fractal terrain & clouds", "medium"),
  "terrain_forge": ("Fractal terrain & clouds", "applied"),
  "space_filling_bench": ("Space-filling curves", "medium"),
  "space_filling_room": ("Space-filling curves", "large"),
}


def _hit(text, kw):
    if kw.startswith("re:"):
        return re.search(kw[3:], text) is not None
    return kw in text

def score(text, strong, weak):
    return sum(3 for k in strong if _hit(text, k)) + sum(1 for k in weak if _hit(text, k))

def main():
    groups = {c[0]: [] for c in CONCEPTS}
    truth_by_concept = {c[0]: c[3] for c in CONCEPTS}
    seen = set()
    for r in sorted(glob.glob(os.path.join(ROOT, "commons", "artifacts", "registry", "*.json"))):
        try:
            d = json.load(open(r, encoding="utf-8"))
        except Exception:
            continue
        reg = os.path.basename(r)
        for k, v in (d.get("artifacts", {}) or {}).items():
            if not isinstance(v, dict) or k in seen:
                continue
            lookup = v.get("lookup_name", k)
            if not is_candidate(reg, lookup):
                continue
            name = str(v.get("name", lookup))
            tags = v.get("tags", []) if isinstance(v.get("tags"), list) else []
            text = " ".join([k, lookup, name, str(v.get("category", "")), str(v.get("class_name", "")),
                             " ".join(str(t) for t in tags), str(v.get("description", ""))[:200]]).lower()
            low_lookup = lookup.lower()
            forced = FORCE.get(lookup)
            if forced:
                best, bestscore = forced[0], 99
            else:
                best, bestscore = None, 0
                for cname, strong, weak, _truth in CONCEPTS:
                    sc = score(text, strong, weak)
                    if any(_hit(low_lookup, kk) for kk in strong):
                        sc += 3
                    if sc > bestscore:
                        best, bestscore = cname, sc
            if best and bestscore >= 3:
                seen.add(k)
                snfp = (v.get("spatial_needs", {}) or {}).get("footprint_cells", 1)
                if isinstance(snfp, list):
                    nums = [int(x) for x in snfp if x]
                    snfp = max(nums) if nums else 1
                else:
                    snfp = int(snfp or 1)
                groups[best].append({
                    "lookup": lookup, "name": name, "registry": reg,
                    "category": str(v.get("category", "")),
                    "map_ready": bool(v.get("map_ready")),
                    "has_image": os.path.exists(os.path.join(IMG_DIR, lookup + ".png")),
                    "score": bestscore, "fp": snfp,
                    "tier": forced[1] if forced else tier_of(lookup, name, snfp),
                })
    for c in groups:
        groups[c].sort(key=lambda a: (not a["has_image"], not a["map_ready"], -a["score"], a["lookup"].lower()))

    ACTS = {
        "Act I — recursion & dimension": ["Recursion (calls itself)", "Recursive trees", "Fractal dimension"],
        "Act II — the classic sets": ["Cantor set", "Koch curve & snowflake", "Sierpinski", "Menger sponge"],
        "Act III — escape-time": ["Mandelbrot set", "Julia sets", "Lyapunov & escape-time"],
        "Act IV — IFS, spirals & growth": ["Iterated function systems (IFS)", "Golden spiral & phyllotaxis", "Diffusion-limited aggregation"],
        "Act V — chaos & landscapes": ["Strange attractors", "Fractal terrain & clouds", "Space-filling curves"],
        "Act VI — useful structures": ["Fractal furniture", "Fractal architecture", "Fractal antennas & structures"],
    }
    concept_act = {cc: act for act, cs in ACTS.items() for cc in cs}
    meta = {}
    for c in groups:
        arts = groups[c]
        TIERS = ["small", "medium", "large", "applied"]
        by_tier = {t: [a["lookup"] for a in arts if a["tier"] == t] for t in TIERS}
        best = next((a["lookup"] for a in arts if a["has_image"] and a["map_ready"]), None)
        if not best and arts:
            best = arts[0]["lookup"]
        meta[c] = {
            "count": len(arts), "map_ready": sum(1 for a in arts if a["map_ready"]),
            "has_image": sum(1 for a in arts if a["has_image"]), "best": best,
            "truth": truth_by_concept[c], "act": concept_act.get(c, ""),
            "thin": len(arts) <= 1, "tiers": by_tier,
            "missing_tiers": [t for t in TIERS if not by_tier[t]],
        }
    total = sum(len(v) for v in groups.values())
    out = {
        "title": "Fractals — every example, by concept",
        "note": "Every fractal artifact in the project, grouped by the problem it solves and laddered "
                "small -> medium -> large -> applied. Fractals are their own chapter — recursion, dimension "
                "between integers, escape-time, IFS, chaos. Act VI is the applications act: fractals as useful "
                "structure (furniture, architecture, antennas) — infinite edge in finite room. Koch/Sierpinski/"
                "Hilbert are light bridges shared with the L-system and CA maps. Generated by tools/build_fractal_concept_map.py.",
        "acts": list(ACTS.keys()), "concepts": [c[0] for c in CONCEPTS], "concept_meta": meta,
        "total": total, "map_ready_total": sum(1 for c in groups for a in groups[c] if a["map_ready"]),
        "image_total": sum(1 for c in groups for a in groups[c] if a["has_image"]),
        "empty_slots": sum(len(meta[c]["missing_tiers"]) for c in groups), "groups": groups,
    }
    outpath = os.path.join(ROOT, "doc", "fractal_concept_map.json")
    json.dump(out, open(outpath, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    print(f"wrote {outpath}")
    print(f"TOTAL {total} artifacts across {len(CONCEPTS)} concepts | empty slots: {out['empty_slots']}")
    for c in CONCEPTS:
        arts = groups[c[0]]
        t = {x: 0 for x in ["small", "medium", "large", "applied"]}
        for a in arts: t[a["tier"]] += 1
        miss = ",".join(meta[c[0]]["missing_tiers"]) or "-"
        print(f"  {len(arts):2d}  S{t['small']} M{t['medium']} L{t['large']} A{t['applied']}  miss[{miss:22s}]  {c[0]}")

if __name__ == "__main__":
    main()
