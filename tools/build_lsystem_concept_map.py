"""Build the comprehensive L-system concept map.

Fourth in the concept-map family (vectors, randomness, CA, L-systems). Scans the registries
(lsystems.json is the 17-artifact core), classifies each genuine L-system artifact into one of 18
concepts across 6 acts, tiers each small/medium/large/applied, writes doc/lsystem_concept_map.json.

L-systems are the grammar the biome runs on — so the per-concept truths carry two threads: grammar is
generative (parallel rewriting, axiom->forest, the genotype/phenotype split) AND the DNA/biome
connection (CritterDNA -> L-system params -> TreeMorphology -> trees). Act VI is the keystone where the
randomness seed->form bridge and the CA morphogenesis bridge converge: L-system = body, RD = skin, one DNA.

Run from repo root:  python tools/build_lsystem_concept_map.py
"""
import json, glob, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG_DIR = os.path.normpath(os.path.join(ROOT, "..", "ada_encyclopedia", "public", "scene-catalog"))

HIGH_SIGNAL = {"lsystems.json"}
GATE = re.compile(r"lsystem|l_system|lindenmayer|turtle|axiom|koch|dragon|hilbert3d|hilbert_curve|peano|"
                  r"gosper|barnsley|fern|space_filling|space.fill|bracket|branching|context_sensitive|"
                  r"context_free|contextfree|chomsky|parse_tree|parametric_l|citygenerator|city_gen|"
                  r"forestcompetition|forest_competition|animatedtree|grammar_provenance|grammar_recursive|"
                  r"branching_coral|genetic_tree|modulor_cypress|mesh_grammar_lsystem|mesh_grammar_branching|"
                  r"kochsnowflake|meander_floor", re.I)
EXCLUDE = {
    "dark_sphere",                     # generic atmospheric prop, not L-system
    "hilbert_hotel",                   # Hilbert's INFINITY HOTEL (foundations), not the curve
    "entropy_axiom",                   # randomness/entropy, not an L-system axiom
    "glassrack_branchingcondenser",    # a glass rack that happens to branch
    "branching_vine",                  # a vine hazard (kept in hazards)
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
 ("Axiom & production rules",
  ["lsystem_artifact", "lsystem_editor", "fractal_lsystem_string", "grammar_provenance", "axiom", "production"],
  ["rewrite", "rule", "lindenmayer"],
  "An axiom and a handful of replace-rules; run them and a sentence becomes a forest. The whole plant is in the rules, not the picture."),
 ("Parallel rewriting / generations",
  ["animatedtree", "animated_tree"],
  ["generation", "iterate", "parallel"],
  "Every symbol rewrites at once, each generation — not a serial head but a field dividing, which is why it grows like life and not like a list."),
 ("Formal grammars (Chomsky)",
  ["contextfreegrammars", "context_free_grammars", "chomsky", "parse_tree"],
  ["formal grammar", "context-free"],
  "Where Chomsky's hierarchy meets biology — a context-free grammar is a parse tree is a plant."),
 ("Turtle interpretation",
  ["turtle_meander_floor", "turtle"],
  ["forward", "heading", "draw"],
  "Read the string as a turtle — forward, turn, branch. The grammar is the genotype; the drawn path is the phenotype."),
 ("Koch & fractal curves",
  ["koch_curve", "kochsnowflake", "fractal_koch", "living_paper_koch", "koch"],
  ["snowflake", "fractal curve", "edge replace"],
  "Replace every edge with a smaller copy of the whole — infinite length around a finite area, the coastline that never ends."),
 ("Dragon & classic curves",
  ["living_paper_dragon", "dragon", "levy", "gosper_curve"],
  ["dragon curve", "paper fold"],
  "Fold a strip the same way forever and a dragon uncurls — order so deep it reads as chaos."),
 ("Space-filling curves (Hilbert)",
  ["hilbert3d", "hilbert", "space_filling_curve_gallery", "space_filling_floor", "space_filling", "peano"],
  ["space-filling", "fill the plane"],
  "A line that visits every point of a square — one dimension reaching, by recursion, to fill two."),
 ("Bracketed branching",
  ["grammar_negative_space_bracket", "grammar_recursive_branching_tree", "branching_growth_algorithm", "bracket"],
  ["push", "pop", "stack"],
  "The bracket is the trick: push the turtle's state, draw a limb, pop back. [ ] is where the line becomes a tree."),
 ("L-system trees",
  ["lsystem_tree", "lindenmayer_tube_tree", "fractal_lsystem_tree", "mesh_grammar_lsystem_tree", "modulor_cypress"],
  ["tree", "branch angle"],
  "A few rules and a branching angle, and the same grammar grows a fir, an oak, a willow — the whole tree latent in a line of symbols."),
 ("Ferns & self-similar plants",
  ["barnsley_fern", "living_paper_fern", "barnsley", "fern"],
  ["self-similar", "ifs", "frond"],
  "Barnsley's fern: the leaf is the plant is the frond — self-similarity all the way down, from four affine maps."),
 ("Coral & vines",
  ["branching_coral", "mesh_grammar_branching_coral"],
  ["coral", "vine", "accretion"],
  "Branching is cheaper than planning; the coral and the vine grow by the same greedy local rule."),
 ("Stochastic L-systems",
  ["stochastic_lsystem", "stochastic_l"],
  ["random rule", "probabilistic", "no two alike"],
  "Roll the dice on which rule fires and no two plants are the same — randomness is how a grammar makes a population, not a clone."),
 ("Parametric L-systems",
  ["parametric_lsystem", "parametric_l"],
  ["parameter", "module", "taper"],
  "Hang numbers on the symbols — a length, an angle, an age — and the grammar can taper, bend, and grow old."),
 ("Context-sensitive L-systems",
  ["contextsensitivetree", "context_sensitive"],
  ["neighbour", "environment", "pruning", "signal"],
  "Let a symbol read its neighbours and the plant answers its world — light, crowding, a signal passing up the stem."),
 ("Many substrates (the bridge)",
  ["mesh_grammar_lsystem", "mesh_grammar_branching", "mesh_grammar"],
  ["tube", "softbody", "substrate", "render mode"],
  "The same string is a line, a tube, a graph, a soft body, a Bauhaus sculpture — the grammar is the DNA, the material is a choice."),
 ("Grammar architecture (cities/dungeons)",
  ["citygenerator", "city_gen", "lsystem_dungeon", "dungeon"],
  ["city", "architecture", "pipe network"],
  "Point the rules at right angles instead of leaves and the same engine grows a city, a dungeon, a pipe network."),
 ("CritterDNA -> L-system tree",
  ["genetic_tree_sculptor", "tree_dna", "treemorphology", "dna_sprout", "genome_bench", "axiom_garden"],
  ["genome", "critterdna", "seed"],
  "The genome IS the grammar's parameters — segments, branch angle, decay — so a CritterDNA grows a unique tree through the L-system. Store the seed, regrow the plant. The body to the morphogenesis bridge's skin."),
 ("Forest & ecology (biome)",
  ["forestcompetition", "forest_competition", "forest_ecosystem"],
  ["competition", "ecology", "biome", "forest"],
  "Many grammars in one world, competing for light — the L-system stops being a plant and becomes the biome that plants it."),
]

APPLIED_KW = ["editor", "sculptor", "generator", "_garden", "competition", "dungeon", "city",
              "provenance", "gallery", "forest", "ecosystem"]
LARGE_KW = ["_hall", "_room", "_wall", "tower", "canopy"]
def tier_of(lookup, name, fp):
    low = (lookup + " " + name).lower()
    if any(k in low for k in APPLIED_KW): return "applied"
    if any(k in low for k in LARGE_KW) or fp >= 9: return "large"
    if fp >= 3: return "medium"
    return "small"

FORCE = {}


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
        "Act I — the rewriting rule": ["Axiom & production rules", "Parallel rewriting / generations", "Formal grammars (Chomsky)"],
        "Act II — the turtle": ["Turtle interpretation", "Koch & fractal curves", "Dragon & classic curves", "Space-filling curves (Hilbert)"],
        "Act III — branching plants": ["Bracketed branching", "L-system trees", "Ferns & self-similar plants", "Coral & vines"],
        "Act IV — variation": ["Stochastic L-systems", "Parametric L-systems", "Context-sensitive L-systems"],
        "Act V — substrates & architecture": ["Many substrates (the bridge)", "Grammar architecture (cities/dungeons)"],
        "Act VI — DNA & biome": ["CritterDNA -> L-system tree", "Forest & ecology (biome)"],
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
        "title": "L-systems — every example, by concept",
        "note": "Every L-system artifact in the project, grouped by the problem it solves and laddered "
                "small -> medium -> large -> applied. L-systems are the grammar the biome runs on, so the "
                "truths carry both threads: grammar is generative (axiom -> forest, parallel rewriting) and "
                "the DNA/biome connection (CritterDNA -> L-system -> TreeMorphology). Act VI is the keystone "
                "where the randomness seed->form bridge and the CA morphogenesis bridge meet. "
                "Generated by tools/build_lsystem_concept_map.py.",
        "acts": list(ACTS.keys()), "concepts": [c[0] for c in CONCEPTS], "concept_meta": meta,
        "total": total, "map_ready_total": sum(1 for c in groups for a in groups[c] if a["map_ready"]),
        "image_total": sum(1 for c in groups for a in groups[c] if a["has_image"]),
        "empty_slots": sum(len(meta[c]["missing_tiers"]) for c in groups), "groups": groups,
    }
    outpath = os.path.join(ROOT, "doc", "lsystem_concept_map.json")
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
