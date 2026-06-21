"""Build the comprehensive Procedural-Generation concept map.

Seventh concept map — and the SYNTHESIS chapter. The other six (vectors, randomness, CA, L-systems,
fractals, soft-bodies) each laddered one primitive. Procedural generation is categorically different:
it's the meta-discipline that USES the primitives to build things. So this map deliberately focuses on
the generation-specific technique families — marching cubes / implicit surfaces, constraint solving (WFC),
growth & agents, partition & scatter, grammars, and WORLDS — and threads the prior six as the toolkit
(noise -> terrain, L-systems -> forests, CA -> caves, fractals -> coastlines). It does NOT re-list the
fractal/L-system/noise primitives that are already their own chapters (those are gated out).

20 concepts across 6 acts. The final act, "worlds (design without a designer)", is the capstone: where
the techniques stack into a whole place, ending at seed -> world (one number becomes a world). Threads
the project's own generators (grow_map, zone_grammar, generative maps) as the living edge.

Run from repo root:  python tools/build_procgen_concept_map.py
"""
import json, glob, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG_DIR = os.path.normpath(os.path.join(ROOT, "..", "ada_encyclopedia", "public", "scene-catalog"))

# Clean, dedicated procgen registries — everything in these is in-scope.
HIGH_SIGNAL = {"isosurfaces.json", "mesh_grammar.json", "grammar_systems.json", "procedural_generation.json"}
# Generation-technique names that pull real procgen artifacts out of the grab-bag (procgen_extra etc.)
GATE = re.compile(
    r"march|isosurf|metaball|gyroid|voxel_noise|implicit_surface|fountain_demo|raymarched|sculpt|"
    r"animated_noise|wave_function|wfc|model_synth|modelsynthesis|voronoi|delaunay|poisson|binary_space|"
    r"boolean_pattern|constraint_sculptor|maze|cave|rhizome|slime|genetic|space_coloniz|branching_growth|"
    r"percolation|crackpropagation|crack_propagation|diffusion_limited|reaction_diff|gray_scott|rd_coral|"
    r"room_grammar|markov|mesh_grammar|facade_grammar|pattern_tunnel|penrose|truchet|tessellat|tile_patterns|"
    r"tesseract|penteract|sixteen_cell|terrain_erosion|liquid_simulation|cube_mound|spherenetwork|fatwireframe|"
    r"world_forge|seed_world|world_seed|seed_garden|seed_to_world", re.I)
# Items that match a gate word but belong to another chapter (fractals/L-systems) or are junk.
EXCLUDE = {
    "genetic_tree_sculptor",            # L-system map
    "layered_membrane", "dewcoveredfol",
    "mirror_cellular_texture_for_3d",
    "stochastic_tree_separated", "tree_gen",
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

# concept -> (strong [w3, lookup bonus], weak [w1], truth). Order: specific first; ties break earlier.
CONCEPTS = [
 ("Marching cubes",
  ["marching_cubes", "marchingcube", "marchingcave", "mc_base", "mc_cave", "mc_terrain", "mc_flat",
   "mc_overhang", "mc_portal", "mc_inside", "mc_torus", "mc_shapes", "voxel_noise", "fifteen_cases",
   "destructible_marching"],
  ["lookup table", "256 cases", "isosurface", "voxel"],
  "A field says how 'inside' each point is; marching cubes walks the grid and stitches a surface where inside meets outside — 256 cases, and a noise becomes a cave."),
 ("Metaballs & implicit surfaces",
  ["metaball", "gyroid", "implicit_surface", "fountain_demo", "raymarched", "nakama"],
  ["blob", "distance field", "minimal surface", "merge"],
  "Sum a few smooth fields and where they cross a threshold a single skin appears — drops that merge into one body, a surface with no vertices until you ask for it."),
 ("SDF sculpting",
  ["sculpt", "animated_noise_explorer"],
  ["signed distance", "carve", "real-time", "blobs"],
  "Hold the field in your hands: add a blob, subtract a blob, smooth the union, and the surface re-forms live. Modelling by editing the function, not the mesh."),
 ("Wave function collapse",
  ["wave_function", "wfc", "wfccav", "modelsynthesis", "model_synthesis"],
  ["adjacency", "propagate", "entropy", "tiles"],
  "Give every cell all possibilities, collapse the least-uncertain one, and let the constraints ripple out. The tiles agree on a world none of them chose alone."),
 ("WFC structures & rooms",
  ["wfc_dungeon", "wfc_office", "wfc_maze", "wfcsculpture", "room_grammar", "wfc3d", "wfc_3d"],
  ["dungeon", "rooms", "building", "doors"],
  "The same collapse, scaled to rooms: a corridor meets a door meets a room because the adjacency rules forbid anything else. Architecture as a satisfied constraint."),
 ("Boolean & space partition",
  ["boolean_pattern", "binary_space", "bsp", "constraint_sculptor"],
  ["carve", "subdivide", "split", "partition"],
  "Cut space in two, then cut each half — recursive binary partition is how a blank box becomes rooms, how subtraction becomes architecture."),
 ("Space colonization",
  ["space_coloniz", "branching_growth"],
  ["attractor", "venation", "reach", "toward"],
  "Scatter attractors, grow branches toward the nearest, retire the reached — and a tree, a leaf vein, a river network draws itself toward what it feeds on."),
 ("Genetic & evolutionary",
  ["genetic", "geneticprogramming", "evolution"],
  ["fitness", "mutation", "selection", "crossover"],
  "No designer — only variation, selection, and time. Forms you never drew appear because they outlived the ones you did."),
 ("Agent walks & caves",
  ["cave", "caverandomwalk", "rhizome", "queer_marching_cave", "cavetest"],
  ["random walk", "dig", "tunnel", "drunkard"],
  "A walker digs where it wanders; thousands of drunk steps carve a cave system no architect would draw and every spelunker would recognise."),
 ("Slime, DLA & aggregation",
  ["slime", "diffusion_limited", "aggregation"],
  ["chemotaxis", "dendrite", "stick", "trail"],
  "Agents that follow their own trail, or particles that stick where they land — transport networks and corals self-organising from nothing but local rules."),
 ("Reaction-diffusion & phase transition",
  ["reaction_diff", "gray_scott", "rd_coral", "percolation", "crackpropagation", "crack_propagation"],
  ["turing", "threshold", "spots", "connectivity"],
  "Two chemicals, one inhibiting the other, and spots and stripes emerge — Turing's morphogenesis, kin to the sudden moment a random network percolates into one connected whole."),
 ("Voronoi & Delaunay",
  ["voronoi", "delaunay"],
  ["cells", "nearest", "triangulation", "dual"],
  "Every point claims the territory nearest it — Voronoi cells are how cracked mud, a giraffe's coat, and living tissue all partition a plane the same way."),
 ("Poisson-disk & scatter",
  ["poisson", "scatter"],
  ["even", "packing", "minimum distance", "blue noise"],
  "Random, but never too close — Poisson-disk scatter places a forest, freckles, or stars so they read as natural and never clump."),
 ("Mazes",
  ["maze"],
  ["backtrack", "corridor", "perfect maze", "passage"],
  "Carve passages without ever crossing your own path and a perfect maze appears — every cell reachable, exactly one route between any two."),
 ("Markov & probabilistic grammars",
  ["markov"],
  ["state", "transition", "chain", "n-gram"],
  "What comes next depends only on where you are — a Markov chain hums out text, terrain, or a tree from a table of 'what usually follows'."),
 ("Mesh & shape grammars",
  ["mesh_grammar", "facade_grammar", "shape_grammar"],
  ["extrude", "inset", "subdivide", "rule"],
  "Start with a shape, apply a rule, apply it again — extrude, inset, bud — and a plain mesh grows barnacles, coral, armour, towers."),
 ("Tilings & symmetry",
  ["penrose", "truchet", "tile_patterns", "pattern_tunnel", "tessellat"],
  ["wallpaper", "aperiodic", "symmetry group", "fivefold"],
  "Tiles that lock by rule alone — Truchet's coin-flip arcs, Penrose's never-repeating fivefold — pattern out of constraint, not out of a plan."),
 ("Higher-dimensional generation",
  ["tesseract", "penteract", "sixteen_cell", "net_space"],
  ["4d", "projection", "unfold", "polytope"],
  "Generate in four dimensions and project down — a tesseract's shadow, a polytope's net unfolding — structure from a space you can't quite stand inside."),
 ("Generated worlds",
  ["metaball_world", "cube_mound", "terrain_erosion", "spherenetwork", "fatwireframe", "liquid_simulation"],
  ["walkable", "assembled", "world", "extracted live"],
  "Stack the techniques and a whole place appears — eroded terrain, a mound that builds itself, a world meshed live as you walk into it."),
 ("Seed -> world",
  ["seed_world", "world_forge", "world_seed", "seed_garden", "seed_to_world"],
  ["one seed", "full stack", "pipeline", "design without a designer"],
  "One number becomes a world: the seed picks the noise, the noise the terrain, the terrain the structures, the structures the life. Design without a designer, all the way down."),
]

APPLIED_KW = ["generator", "_gen", "sculpt", "forge", "explorer", "_machine", "sculptor", "_ui",
              "comparison", "dungeon", "office", "_lab", "_demo", "selector"]
LARGE_KW = ["_world", "_system", "gallery", "showcase", "landscape", "_scene", "cave_gallery"]
def tier_of(lookup, name, fp):
    low = (lookup + " " + name).lower()
    if any(k in low for k in APPLIED_KW): return "applied"
    if any(k in low for k in LARGE_KW) or fp >= 9: return "large"
    if fp >= 3: return "medium"
    return "small"

FORCE = {
  "seed_world_toy": ("Seed -> world", "small"),
  "seed_world_bench": ("Seed -> world", "medium"),
  "seed_world_room": ("Seed -> world", "large"),
  "world_forge": ("Seed -> world", "applied"),
}


def score(text, strong, weak):
    return sum(3 for k in strong if k in text) + sum(1 for k in weak if k in text)

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
                    if any(kk in low_lookup for kk in strong):
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
        "Act I — fields become surface": ["Marching cubes", "Metaballs & implicit surfaces", "SDF sculpting"],
        "Act II — constraints that agree": ["Wave function collapse", "WFC structures & rooms", "Boolean & space partition"],
        "Act III — growth & agents": ["Space colonization", "Genetic & evolutionary", "Agent walks & caves", "Slime, DLA & aggregation", "Reaction-diffusion & phase transition"],
        "Act IV — partition & scatter": ["Voronoi & Delaunay", "Poisson-disk & scatter", "Mazes"],
        "Act V — grammars & rules": ["Markov & probabilistic grammars", "Mesh & shape grammars", "Tilings & symmetry", "Higher-dimensional generation"],
        "Act VI — worlds (design without a designer)": ["Generated worlds", "Seed -> world"],
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
        "title": "Procedural generation — every technique, by family",
        "note": "The seventh concept map and the synthesis chapter: the generation-specific technique families "
                "(marching cubes, WFC, growth & agents, partition & scatter, grammars, worlds), laddered "
                "small -> medium -> large -> applied. It threads the other six maps as its toolkit (noise -> "
                "terrain, L-systems -> forests, CA -> caves, fractals -> coastlines) rather than re-listing them. "
                "The final act ends at seed -> world: design without a designer. "
                "Generated by tools/build_procgen_concept_map.py.",
        "acts": list(ACTS.keys()), "concepts": [c[0] for c in CONCEPTS], "concept_meta": meta,
        "total": total, "map_ready_total": sum(1 for c in groups for a in groups[c] if a["map_ready"]),
        "image_total": sum(1 for c in groups for a in groups[c] if a["has_image"]),
        "empty_slots": sum(len(meta[c]["missing_tiers"]) for c in groups), "groups": groups,
    }
    outpath = os.path.join(ROOT, "doc", "procgen_concept_map.json")
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
