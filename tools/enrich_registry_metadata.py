#!/usr/bin/env python3
"""
Enrich artifact registry metadata: add missing complexity, tags, and dev_themes fields.

Uses heuristic inference based on:
- artifact description text
- category field
- registry file name (domain context)
- existing fields (scene path, qfep_connection, etc.)

Run from repo root:
    python tools/enrich_registry_metadata.py [--dry-run] [--file <specific_file.json>]
"""

import json
import os
import re
import sys
from pathlib import Path

REGISTRY_DIR = Path(__file__).parent.parent / "commons" / "artifacts" / "registry"

# ─── Complexity inference rules ───

# Keywords suggesting expert-level complexity
EXPERT_KEYWORDS = [
    "quantum", "lyapunov", "navier.stokes", "eigenvalue", "eigenvector",
    "tensor", "riemannian", "manifold", "homology", "cohomology",
    "fourier transform", "laplacian", "hamiltonian", "schrodinger",
    "topolog", "homotop", "non.euclidean", "hyperbolic geometry",
    "göd", "godel", "incompleteness", "undecidab", "turing.complete",
    "category theory", "functor", "monad(?!.*minecraft)",
    "stochastic differential", "measure theory",
]

ADVANCED_KEYWORDS = [
    "fractal", "attractor", "chaos", "bifurcation", "phase space",
    "neural network", "backpropagation", "gradient descent", "perceptron",
    "convolution", "recurrent", "transformer", "attention mechanism",
    "genetic algorithm", "evolutionary", "swarm intelligence",
    "wave equation", "interference", "superposition", "resonan",
    "graph theory", "petersen", "chromatic", "spanning tree",
    "markov", "bayesian", "monte carlo", "rejection sampling",
    "l.system", "grammar", "rewriting", "recursiv",
    "verlet", "constraint", "finite element", "simulation",
    "isosurface", "marching cubes", "signed distance",
    "voronoi", "delaunay", "convex hull",
    "shader", "gpu", "compute shader", "fragment shader",
    "wave function collapse", "wfc", "constraint propagation",
    "entropy", "information theory", "shannon",
    "paradox", "self.referen", "incompleteness",
    "qfep", "free energy", "variational",
    "erosion", "hydraulic", "thermal",
    "stigmergy", "pheromone", "ant colony",
    "flocking", "boid", "reynolds",
    "reaction.diffusion", "turing pattern",
    "strange attractor", "lorenz", "rossler",
    "mandelbrot", "julia set",
    "decision boundary", "classifier", "svm",
    "curl noise", "divergence.free",
    "inverse kinematics", "forward kinematics",
    "quaternion", "rotation matrix",
    "poisson", "distribution",
]

INTERMEDIATE_KEYWORDS = [
    "sort", "search", "binary", "algorithm",
    "array", "list", "stack", "queue", "tree", "graph", "hash",
    "random walk", "brownian", "noise", "perlin", "simplex", "worley",
    "cellular automata", "game of life", "rule \\d+",
    "oscillat", "pendulum", "spring", "harmonic",
    "collision", "physics", "rigid body", "soft body",
    "pathfind", "a.star", "dijkstra", "breadth.first", "depth.first",
    "bezier", "spline", "parametric", "curve",
    "matrix", "vector", "transform", "rotation", "scaling",
    "procedural", "generation", "terrain", "heightmap",
    "particle", "emitter", "particle system",
    "state machine", "automaton",
    "color space", "rgb", "hsv", "hsl",
    "pattern", "symmetry", "tessellation", "tiling",
    "interpolat", "lerp", "ease", "tween",
    "mesh", "polygon", "vertex", "edge",
    "data structure", "linked list", "binary tree",
    "recursion", "fibonacci", "factorial",
    "trigonometr", "sine", "cosine",
    "modular arithmetic", "prime", "divisib",
    "probability", "combinatorics",
    "force", "velocity", "acceleration",
    "coordinate", "cartesian", "polar",
    "projection", "perspective", "orthograph",
]

BEGINNER_KEYWORDS = [
    "menu", "ui ", "button", "label", "panel", "overlay",
    "origin", "point zero", "spawn", "teleport",
    "decoration", "furniture", "lamp", "chair", "table", "shelf",
    "primitive", "cube", "sphere", "cylinder", "box",
    "simple", "basic", "introduct", "tutorial", "demo",
    "color mix", "additive", "rgb light",
    "counter", "timer", "clock",
    "sign", "plaque", "display", "info.?board",
    "placeholder", "debug", "test",
]

# ─── Category → complexity mapping (fallback) ───
CATEGORY_COMPLEXITY = {
    "primitives": "beginner",
    "unknown": "beginner",
    "ui": "beginner",
    "menu": "beginner",
    "debug": "beginner",
    "decoration": "beginner",
    "furniture": "beginner",
    "hazards": "intermediate",
    "procedural": "intermediate",
    "emergence": "intermediate",
    "waves": "intermediate",
    "physics": "intermediate",
    "steering": "intermediate",
    "nature_of_code": "intermediate",
    "data_structures": "intermediate",
    "sorting": "intermediate",
    "searching": "intermediate",
    "fractals": "advanced",
    "chaos": "advanced",
    "quantum": "expert",
    "philosophy": "advanced",
    "integration": "advanced",
    "machine_learning": "advanced",
    "neural": "advanced",
    "biology": "advanced",
    "neuroscience": "advanced",
    "computational_biology": "advanced",
}

# ─── Registry file → domain themes ───
FILE_THEMES = {
    "cellular_automata.json": ["emergence", "cellular_automata", "computation"],
    "chaos.json": ["chaos", "dynamical_systems"],
    "color.json": ["color", "perception"],
    "computational_biology.json": ["biology", "simulation"],
    "datastructures.json": ["data_structures", "algorithms"],
    "foundations.json": ["philosophy", "qfep"],
    "furniture.json": ["environment", "decoration"],
    "grammar_systems.json": ["grammar", "formal_languages"],
    "grid2d.json": ["grid", "spatial"],
    "grid3d.json": ["grid", "spatial", "3d"],
    "hazards.json": ["hazards", "gameplay"],
    "isosurfaces.json": ["isosurfaces", "3d", "math"],
    "lab.json": ["lab", "interactive"],
    "living_paper.json": ["paper", "origami", "procedural"],
    "lsystems.json": ["l_systems", "procedural", "grammar"],
    "machinelearning.json": ["machine_learning", "ai"],
    "machinelearning_extra.json": ["machine_learning", "ai"],
    "mesh_grammar.json": ["mesh", "procedural", "grammar"],
    "nature_system.json": ["nature", "simulation"],
    "neuroscience.json": ["neuroscience", "biology"],
    "parametric.json": ["parametric", "math", "curves"],
    "physics_simulation.json": ["physics", "simulation"],
    "primitives.json": ["primitives", "core"],
    "procgen_extra.json": ["procedural", "generation"],
    "profile.json": ["profile", "edge", "procedural"],
    "qfep.json": ["qfep", "philosophy", "theory"],
    "quantumalgorithms.json": ["quantum", "algorithms"],
    "randomness.json": ["randomness", "probability"],
    "shaders.json": ["shaders", "visual"],
    "soft_bodies.json": ["physics", "soft_body"],
    "speech.json": ["speech", "audio", "language"],
    "statistics.json": ["statistics", "math", "probability"],
    "steering.json": ["steering", "autonomous_agents"],
    "substrate_vectors.json": ["vectors", "math"],
    "swarmintelligence.json": ["swarm", "emergence", "collective"],
    "transforms.json": ["transforms", "math", "geometry"],
    "vectors.json": ["vectors", "math", "linear_algebra"],
    "vectors_demos.json": ["vectors", "math", "linear_algebra"],
    "wavefunctions.json": ["waves", "oscillation", "physics"],
    "wavefunctions_extra.json": ["waves", "oscillation", "physics"],
    "arrays.json": ["arrays", "data_structures"],
    "algorithms_misc.json": ["algorithms", "misc"],
    "alternative_geometries.json": ["geometry", "non_euclidean"],
    "bar_array.json": ["arrays", "visualization"],
    "commons_artifacts.json": ["commons", "mixed"],
    "panel_bridge.json": ["panels", "ui"],
    "progression_debug.json": ["debug", "progression"],
    "random_cubes.json": ["randomness", "procedural"],
    "script_runner.json": ["scripting", "tools"],
}

# ─── Tag extraction ───

def extract_tags_from_description(desc: str, name: str, lookup: str, category: str) -> list[str]:
    """Extract meaningful tags from artifact description and metadata."""
    tags = set()
    text = f"{desc} {name}".lower()

    # Category as tag
    if category and category not in ("unknown", ""):
        tags.add(category.replace(" ", "_"))

    # Pattern-based tag extraction
    tag_patterns = {
        "interactive": r"\b(grab|click|interact|slider|button|toggle|press|touch)\b",
        "visualization": r"\b(visual|display|render|show|paint|draw|canvas)\b",
        "procedural": r"\b(procedural|generat|random|noise|perlin|simplex)\b",
        "animation": r"\b(animat|motion|movement|dynamic|real.?time|cycle|loop)\b",
        "physics": r"\b(physic|force|velocity|gravity|collision|rigid|spring|mass)\b",
        "vr": r"\b(vr|xr|immersive|hand|grab|controller)\b",
        "math": r"\b(math|equation|formula|theorem|proof|calcul|computation)\b",
        "3d": r"\b(3d|mesh|vertex|polygon|surface|volume)\b",
        "2d": r"\b(2d|pixel|tile|grid|floor|carpet|rug|canvas)\b",
        "sound": r"\b(sound|audio|music|tone|frequency|resonan|acoustic|pitch)\b",
        "color": r"\b(color|colour|rgb|hsl|hsv|hue|saturat|palette|chromat)\b",
        "pattern": r"\b(pattern|symmetr|tessellat|tiling|wallpaper|repeat)\b",
        "fractal": r"\b(fractal|mandelbrot|julia|self.similar|iterate)\b",
        "chaos": r"\b(chaos|attractor|lyapunov|bifurcat|sensitive dependence)\b",
        "wave": r"\b(wave|oscillat|pendulum|harmonic|frequenc|amplitude|resonan)\b",
        "cellular_automata": r"\b(cellular automata?|game of life|rule \d+|ca |wolfram)\b",
        "sorting": r"\b(sort|bubble|merge|quick|insertion|selection|heap.?sort)\b",
        "searching": r"\b(search|binary search|linear search|find|lookup)\b",
        "tree": r"\b(tree|binary tree|bst|avl|heap|trie)\b",
        "graph": r"\b(graph|node|edge|vertex|adjacen|connect|network)\b",
        "recursion": r"\b(recurs|fibonacci|factorial|divide.and.conquer)\b",
        "machine_learning": r"\b(neural.?net|perceptron|backprop|gradient.descent|machine.learn|deep.learn|classify|classifier|regression|svm|decision.boundary)\b",
        "geometry": r"\b(geometr|euclidean|non.euclidean|hyperbolic|sphere|torus|manifold)\b",
        "simulation": r"\b(simulat|model|system|agent|emerg)\b",
        "nature_of_code": r"\b(nature of code|noc|daniel shiffman|coding train)\b",
        "swarm": r"\b(swarm|flock|boid|collective|stigmerg|ant|colony|pheromone)\b",
        "l_system": r"\b(l.system|lindenmayer|rewriting|grammar|axiom|production)\b",
        "string": r"\b(string|text|character|ascii|unicode|parse)\b",
        "qfep": r"\b(qfep|free energy|variational|active inference|bayesian brain)\b",
        "cryptography": r"\b(encrypt|decrypt|cipher|hash|crypto)\b",
        "compression": r"\b(compress|huffman|lzw|entropy|encoding)\b",
        "topology": r"\b(topolog|genus|euler|connected|boundary|manifold|homolog)\b",
        "linear_algebra": r"\b(vector|matrix|eigen|determinant|linear|basis|span|dot product|cross product)\b",
        "probability": r"\b(probabilit|random|stochastic|distribut|gaussian|normal|uniform|sample)\b",
        "optimization": r"\b(optimiz|gradient descent|loss|minimize|maximize|converge)\b",
        "terrain": r"\b(terrain|landscape|heightmap|erosion|mountain|valley)\b",
        "hazard": r"\b(hazard|danger|enemy|attack|damage|trap|spike|projectile)\b",
        "origami": r"\b(origami|fold|crease|paper|waterbomb|crane)\b",
    }

    for tag, pattern in tag_patterns.items():
        if re.search(pattern, text, re.IGNORECASE):
            tags.add(tag)

    # Extract specific algorithm/concept names from lookup_name
    lookup_parts = lookup.lower().replace("_", " ").split()
    concept_tags = {
        "sort", "search", "tree", "graph", "hash", "stack", "queue",
        "array", "list", "matrix", "vector", "wave", "noise",
        "fractal", "spiral", "grid", "mesh", "voxel", "shader",
        "pendulum", "spring", "particle", "boid", "agent",
        "neuron", "synapse", "cell", "dna", "protein",
    }
    for part in lookup_parts:
        if part in concept_tags:
            tags.add(part)

    # Deduplicate singular/plural
    deduped = set()
    for t in tags:
        # If both "fractal" and "fractals" exist, keep "fractal"
        singular = t.rstrip("s") if t.endswith("s") and len(t) > 3 else t
        if singular in tags and singular != t:
            continue  # skip the plural form
        deduped.add(t)
    return sorted(deduped)


def infer_complexity(desc: str, name: str, lookup: str, category: str,
                     registry_file: str, existing_data: dict) -> str:
    """Infer complexity level from artifact metadata."""
    text = f"{desc} {name} {lookup}".lower()

    # Check for expert keywords first
    for kw in EXPERT_KEYWORDS:
        if re.search(kw, text, re.IGNORECASE):
            return "expert"

    # Check for advanced keywords
    advanced_score = 0
    for kw in ADVANCED_KEYWORDS:
        if re.search(kw, text, re.IGNORECASE):
            advanced_score += 1

    # Check for intermediate keywords
    intermediate_score = 0
    for kw in INTERMEDIATE_KEYWORDS:
        if re.search(kw, text, re.IGNORECASE):
            intermediate_score += 1

    # Check for beginner keywords
    beginner_score = 0
    for kw in BEGINNER_KEYWORDS:
        if re.search(kw, text, re.IGNORECASE):
            beginner_score += 1

    # Description length heuristic: longer = more complex
    desc_len = len(desc) if desc else 0
    if desc_len > 300:
        advanced_score += 1
    elif desc_len < 50:
        beginner_score += 1

    # Hazard enemies are at least intermediate (complex AI/mechanics)
    if re.search(r"\b(enemy|attack|swarm|ai|creature|boss|aggressive)\b", text, re.IGNORECASE):
        intermediate_score += 1

    # Has qfep_connection → at least intermediate
    if existing_data.get("qfep_connection"):
        advanced_score += 1

    # Score-based decision
    if advanced_score >= 2:
        return "advanced"
    if advanced_score == 1 and intermediate_score >= 1:
        return "advanced"
    if intermediate_score >= 2:
        return "intermediate"
    if beginner_score >= 2:
        return "beginner"
    if intermediate_score >= 1:
        return "intermediate"
    if beginner_score >= 1:
        return "beginner"

    # Fallback to category mapping
    cat = category.lower().replace(" ", "_") if category else ""
    if cat in CATEGORY_COMPLEXITY:
        return CATEGORY_COMPLEXITY[cat]

    # Fallback to registry file context
    file_basename = os.path.basename(registry_file)
    file_key = file_basename.replace(".json", "").lower()
    file_complexity = {
        "primitives": "beginner",
        "furniture": "beginner",
        "progression_debug": "beginner",
        "hazards": "intermediate",
        "steering": "intermediate",
        "arrays": "intermediate",
        "randomness": "intermediate",
        "wavefunctions": "intermediate",
        "wavefunctions_extra": "intermediate",
        "cellular_automata": "intermediate",
        "physics_simulation": "intermediate",
        "soft_bodies": "intermediate",
        "color": "intermediate",
        "vectors": "intermediate",
        "vectors_demos": "intermediate",
        "substrate_vectors": "intermediate",
        "transforms": "intermediate",
        "bar_array": "intermediate",
        "grid2d": "intermediate",
        "grid3d": "intermediate",
        "parametric": "intermediate",
        "profile": "intermediate",
        "nature_system": "intermediate",
        "statistics": "intermediate",
        "speech": "intermediate",
        "shaders": "advanced",
        "isosurfaces": "advanced",
        "machinelearning": "advanced",
        "machinelearning_extra": "advanced",
        "chaos": "advanced",
        "foundations": "advanced",
        "qfep": "advanced",
        "computational_biology": "advanced",
        "neuroscience": "advanced",
        "quantumalgorithms": "expert",
        "alternative_geometries": "advanced",
        "mesh_grammar": "advanced",
        "grammar_systems": "advanced",
        "lsystems": "intermediate",
        "living_paper": "intermediate",
        "swarmintelligence": "advanced",
        "procgen_extra": "intermediate",
        "algorithms_misc": "intermediate",
    }
    if file_key in file_complexity:
        return file_complexity[file_key]

    return "intermediate"  # safe default


def infer_dev_themes(desc: str, name: str, category: str, registry_file: str,
                     existing_tags: list) -> list[str]:
    """Infer dev_themes from context."""
    themes = set()
    file_basename = os.path.basename(registry_file)

    # Add file-level themes
    if file_basename in FILE_THEMES:
        for t in FILE_THEMES[file_basename]:
            themes.add(t)

    # Add from category
    cat = (category or "").lower()
    cat_theme_map = {
        "emergence": "emergence",
        "waves": "waves",
        "physics": "physics",
        "procedural": "procedural",
        "fractals": "fractals",
        "chaos": "chaos",
        "hazards": "hazards",
        "steering": "autonomous_agents",
        "quantum": "quantum",
        "biology": "biology",
        "sorting": "algorithms",
        "searching": "algorithms",
    }
    if cat in cat_theme_map:
        themes.add(cat_theme_map[cat])

    # Check description for theme signals
    text = f"{desc} {name}".lower()
    desc_theme_patterns = {
        "qfep": r"\bq.?fep|free energy|variational|active inference\b",
        "philosophy": r"\bphilosoph|göd|godel|russell|paradox|epistemolog\b",
        "art": r"\bart|painting|canvas|aesthetic|gallery|sculpture|molnár\b",
        "music": r"\bmusic|sound|audio|tone|instrument|pitch|melody|rhythm\b",
        "biology": r"\bbiol|dna|protein|cell|organism|evolution|genetic\b",
        "education": r"\bteach|learn|tutorial|lesson|student|pedagog\b",
    }
    for theme, pattern in desc_theme_patterns.items():
        if re.search(pattern, text, re.IGNORECASE):
            themes.add(theme)

    return sorted(themes)[:4]  # cap at 4 themes


def process_registry_file(filepath: str, dry_run: bool = False) -> dict:
    """Process a single registry file and enrich missing metadata."""
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)

    artifacts = data.get("artifacts", {})
    file_basename = os.path.basename(filepath)
    stats = {"total": 0, "complexity_added": 0, "tags_added": 0, "themes_added": 0}

    for key, entry in artifacts.items():
        if not isinstance(entry, dict):
            continue  # skip comment strings like _comment
        stats["total"] += 1
        desc = entry.get("description", "")
        name = entry.get("name", key)
        lookup = entry.get("lookup_name", key)
        category = entry.get("category", "")

        # Add complexity if missing
        if "complexity" not in entry or not entry["complexity"]:
            complexity = infer_complexity(desc, name, lookup, category, filepath, entry)
            entry["complexity"] = complexity
            stats["complexity_added"] += 1

        # Add tags if missing
        if "tags" not in entry or not entry["tags"]:
            tags = extract_tags_from_description(desc, name, lookup, category)
            if not tags:
                # Fallback: derive tags from category and registry domain
                fallback = set()
                if category and category not in ("unknown", ""):
                    fallback.add(category.lower().replace(" ", "_"))
                # Add domain tag from file name
                file_key = os.path.basename(filepath).replace(".json", "")
                domain_tags = {
                    "primitives": "primitive", "hazards": "hazard",
                    "furniture": "furniture", "procgen_extra": "procedural",
                    "cellular_automata": "cellular_automata", "lsystems": "l_system",
                    "wavefunctions": "wave", "randomness": "randomness",
                    "physics_simulation": "physics", "machinelearning": "machine_learning",
                    "shaders": "shader", "steering": "steering",
                    "vectors": "vector", "transforms": "transform",
                    "arrays": "array", "color": "color",
                    "soft_bodies": "soft_body", "isosurfaces": "isosurface",
                    "parametric": "parametric", "qfep": "qfep",
                    "swarmintelligence": "swarm", "speech": "speech",
                    "computational_biology": "biology", "lab": "interactive",
                    "algorithms_misc": "algorithm", "alternative_geometries": "geometry",
                    "commons_artifacts": "commons",
                }
                if file_key in domain_tags:
                    fallback.add(domain_tags[file_key])
                tags = sorted(fallback)
            if tags:
                entry["tags"] = tags
                stats["tags_added"] += 1

        # Add dev_themes if missing
        if "dev_themes" not in entry or not entry["dev_themes"]:
            existing_tags = entry.get("tags", [])
            themes = infer_dev_themes(desc, name, category, filepath, existing_tags)
            if themes:
                entry["dev_themes"] = themes
                stats["themes_added"] += 1

    if not dry_run and (stats["complexity_added"] or stats["tags_added"] or stats["themes_added"]):
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(data, f, indent="\t", ensure_ascii=False)
            f.write("\n")

    return stats


def main():
    dry_run = "--dry-run" in sys.argv
    specific_file = None
    if "--file" in sys.argv:
        idx = sys.argv.index("--file")
        if idx + 1 < len(sys.argv):
            specific_file = sys.argv[idx + 1]

    total_stats = {"total": 0, "complexity_added": 0, "tags_added": 0, "themes_added": 0}

    if specific_file:
        files = [REGISTRY_DIR / specific_file]
    else:
        files = sorted(REGISTRY_DIR.glob("*.json"))

    for filepath in files:
        if not filepath.exists():
            print(f"  SKIP {filepath.name} (not found)")
            continue

        stats = process_registry_file(str(filepath), dry_run)
        for k in total_stats:
            total_stats[k] += stats[k]

        if stats["complexity_added"] or stats["tags_added"] or stats["themes_added"]:
            print(f"  {filepath.name}: +{stats['complexity_added']} complexity, +{stats['tags_added']} tags, +{stats['themes_added']} themes (of {stats['total']})")
        else:
            print(f"  {filepath.name}: already enriched ({stats['total']} entries)")

    print(f"\n{'DRY RUN - ' if dry_run else ''}TOTALS:")
    print(f"  Artifacts processed: {total_stats['total']}")
    print(f"  Complexity added:    {total_stats['complexity_added']}")
    print(f"  Tags added:          {total_stats['tags_added']}")
    print(f"  Themes added:        {total_stats['themes_added']}")


if __name__ == "__main__":
    main()
