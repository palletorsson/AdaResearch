"""Build the comprehensive Cellular Automata concept map.

Sister to build_randomness_concept_map.py / build_vector_force_concept_map.py. Scans the registries
(cellular_automata.json is the ~54-artifact core), classifies each genuine CA artifact into one of 20
concepts across 6 acts, tiers each small/medium/large/applied, and writes doc/ca_concept_map.json.

The per-concept truths carry a "queer Wolfram" reading: computational irreducibility (you must run it —
the deep is the run, not the rule), the edge of chaos / Class 4 as the generative middle, and each rule
as one contingent universe among many — refusing the flattening of the Principle of Computational
Equivalence. CA is Ada's lambda_edge layer; the theory ships with the catalog.

Run from repo root:  python tools/build_ca_concept_map.py
"""
import json, glob, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG_DIR = os.path.normpath(os.path.join(ROOT, "..", "ada_encyclopedia", "public", "scene-catalog"))

HIGH_SIGNAL = {"cellular_automata.json"}
GATE = re.compile(r"cellular|automat|conway|wolfram|rule_?(30|90|110|184)|game_of_life|gameoflife|"
                  r"lenia|wireworld|langton|brian|reaction_?diff|gray_?scott|turing_pattern|totalistic|"
                  r"elementary_ca|sandpile|stigmergy|percolation|crackprop|crack_prop|_ca\b|\bca_|"
                  r"crossway|lifelike|7_[0-9]_|dendrite|recrystall|lattice_gas|sierpinski", re.I)
EXCLUDE = {
    "automatic_writing_desk",      # surrealist automatic writing, not CA
    "fold_theatre_runner",         # fold system runner
    "shader_08_cellularnoise",     # cellular *noise* — lives in the randomness map (kept there)
}
def is_candidate(reg, lookup):
    if lookup in EXCLUDE:
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
 ("Elementary CA (1D rules)",
  ["elementary_ca", "7_1_elementary", "cellular_automata_1d", "ca_rule_explorer", "ca_rules_workbench",
   "ca_showcase", "cellular_automata_basic", "cellular_automata_grabable", "line_network_ca", "wolfram"],
  ["1d", "elementary", "256 rules"],
  "256 rules, each a tiny universe with its own physics; the rule is a worldview you can dial."),
 ("Rule 30 — order to randomness",
  ["grid2d_rule30", "living_paper_rule30", "rule_30", "rule30"],
  ["rule 30"],
  "Pure order, run forward, becomes indistinguishable from chance — determinism no shortcut can outrun. The run is the only oracle."),
 ("Rule 90 — Sierpinski",
  ["grid2d_rule90", "sierpinski_pyramid", "rule_90", "rule90"],
  ["sierpinski"],
  "The same local step, drawn through time, IS the Sierpinski triangle — the fractal was hiding in the rule all along."),
 ("Rule 110 — universal computation",
  ["grid2d_rule110", "living_paper_rule110", "rule_110", "rule110", "rule_30_110"],
  ["turing complete", "universal"],
  "Four cells of memory are enough to compute anything — the universe needs almost nothing to become everything. Origination from a rule that never meant to originate."),
 ("Conway's Game of Life",
  ["game_of_life", "7_2_game_of_life", "7_3_game_of_life", "game_of_life_oop", "game_of_life_petri",
   "ca_conway_city", "conway", "cellular_automata_2d", "mirrored_cellular_automata"],
  ["glider", "oscillator"],
  "Three numbers — born on 3, live on 2 or 3 — and gliders walk, guns fire, computers run. No designer, only neighbours."),
 ("Life patterns & variants",
  ["pulsing_ca", "ca_columns", "ca_bridge", "highlife", "seeds_ca", "daynight", "lifelike"],
  ["still life", "spaceship", "variant"],
  "Same neighbour-count, a different birth rule, a different zoo — life-like is a family of laws, not the law."),
 ("Brian's Brain / multi-state",
  ["brians_brain", "grid2d_brians_brain", "living_paper_brians_brain", "brian"],
  ["three-state", "refractory", "dying"],
  "Add a dying state and the field never rests — perpetual motion from a rule that only knows on, fading, off."),
 ("Wireworld / CA circuits",
  ["wireworld", "grid2d_wireworld", "wireworld_circuit"],
  ["circuit", "logic gate"],
  "Four states make wires, and wires make logic — a universe whose entire physics is electronics."),
 ("Langton's ant / turmites",
  ["langton", "grid2d_langtons_ant", "turmite"],
  ["ant", "highway"],
  "One ant, two rules; ten thousand steps of chaos, then it builds a highway — order that arrives only if you are willing to wait for it."),
 ("Alternative neighbourhoods (hex)",
  ["hexagon_ca", "7_8_hexagon_ca", "hexagon_cave", "hex_ca"],
  ["hexagon", "neighbourhood", "moore", "von neumann"],
  "Change the shape of 'nearby' and you change what can live — the neighbourhood is a politics, not a given."),
 ("Continuous CA (Lenia)",
  ["lenia", "ca_sphere", "smoothlife", "continuous_ca"],
  ["continuous", "smooth"],
  "Let the cells be fractions, not bits, and the gliders grow soft bodies — life at the edge, made smooth."),
 ("Reaction-diffusion (Turing)",
  ["reaction_diffusion", "reaction_diff", "gray_scott", "grayscott", "turing_pattern",
   "turing_pattern_generator", "shader_10_reactiondiffusion", "living_paper_reaction_diffusion"],
  ["morphogenesis", "spots", "stripes", "gray-scott"],
  "Two chemicals and two numbers paint every animal's coat — Turing's answer to how a uniform egg becomes a striped thing. Form from a seed, with no blueprint."),
 ("Lattice gas / physical CA",
  ["lattice_gas", "lattice_gas_automata", "hpp", "fhp"],
  ["fluid", "momentum", "lattice"],
  "Make the cells conserve momentum and the grid becomes a fluid — physics as bookkeeping on a lattice."),
 ("The four Wolfram classes",
  ["ca_rule_comparison", "rule_30_110", "four_classes", "wolfram_class"],
  ["class", "comparison"],
  "Frozen, periodic, chaotic, complex — Wolfram's four weathers. The Principle of Computational Equivalence says they are all the same; the queer reading says only the fourth, the edge, is alive."),
 ("Edge of chaos / self-organisation",
  ["self_organization_ca", "ca_screen", "edge_of_chaos", "recrystallization_ca", "ecosystem_ca"],
  ["edge", "self-organiz", "emergence", "criticality"],
  "Between the rule that dies and the rule that screams is a narrow band where structure persists by moving — lambda_edge, the queer middle that refuses both order and noise."),
 ("3D / volumetric CA",
  ["cellular_automata_3d", "cellularautomata3dstacked", "cellular_automata_3d_stacked",
   "cellularautomata3dtree", "cellular_automata_3d_tree", "volumetric_fog_ca", "crossway_ca", "ca_sphere"],
  ["3d", "volumetric", "voxel", "stacked"],
  "Stack the rule into a third dimension and the pattern stops being a picture and becomes a place you can walk."),
 ("Growth & dendrites",
  ["ca_growth_network", "dendrite_growth_ca", "structure_growth", "ca_chair_test", "decaying_bridge", "growth_network"],
  ["growth", "dendrite", "accretion", "dla"],
  "Local accretion with no plan grows a coral, a crack, a chair — structure as frozen history, the run you cannot un-run."),
 ("Caves / percolation / cracks",
  ["percolation_ca", "percolationnetwork_ca", "crack_propagation_ca", "crackpropagation_ca", "hexagon_cave", "cave_system"],
  ["cave", "percolation", "crack", "maze"],
  "Vote with your neighbours and a noise field becomes a walkable cave — randomness smoothed, by a rule, into a place. (Bridges back to the randomness ladder.)"),
 ("Stigmergy & ecological CA",
  ["stigmergy_grid", "disease_spread_ca", "ecosystem_ca", "mold_network"],
  ["stigmergy", "trail", "disease", "ecosystem", "pheromone"],
  "The trail IS the memory — agents that write on the world and read it back are a cellular automaton wearing legs."),
 ("CA materials & texture",
  ["mirror_cellular_texture", "mirrored_cellular_automata", "persian_rug", "cellular_texture"],
  ["texture", "material", "rug", "tile"],
  "A rule run to equilibrium is a texture; the Persian rug is an algorithm that forgot it was ever running."),
]

# small (held, fp<=2) -> medium (bench, 3-8) -> large (room, fp>=9 / walk-in) -> applied (a tool/scenario)
APPLIED_KW = ["explorer", "workbench", "showcase", "conway_city", "_city", "cave", "circuit",
              "writing_desk", "ecosystem", "disease", "stigmergy", "comparison", "persian_rug",
              "recrystall", "crack", "dendrite", "mold", "generator", "_garden", "texture",
              "decaying", "_fog", "_chair", "_bridge", "_columns", "rule_explorer", "growth_network"]
LARGE_KW = ["pyramid", "structure_growth", "_3d_tree", "3dtree", "stacked", "crossway", "_wall",
            "_screen", "tower", "_hall", "mirrored"]
def tier_of(lookup, name, fp):
    low = (lookup + " " + name).lower()
    if any(k in low for k in APPLIED_KW): return "applied"
    if any(k in low for k in LARGE_KW) or fp >= 9: return "large"
    if fp >= 3: return "medium"
    return "small"

# explicit (concept, tier) overrides — gap-fillers / re-homings land deterministically here
FORCE = {
  "elementary_ca_bench": ("Elementary CA (1D rules)", "medium"),
  "rule30_bench": ("Rule 30 — order to randomness", "medium"),
  "rule30_rng": ("Rule 30 — order to randomness", "applied"),
  "rule90_toy": ("Rule 90 — Sierpinski", "small"),
  "rule90_bench": ("Rule 90 — Sierpinski", "medium"),
  "rule90_loom": ("Rule 90 — Sierpinski", "applied"),
  "rule110_bench": ("Rule 110 — universal computation", "medium"),
  "rule110_computer": ("Rule 110 — universal computation", "applied"),
  "life_bench": ("Conway's Game of Life", "medium"),
  "life_zoo_bench": ("Life patterns & variants", "medium"),
  "life_rules_room": ("Life patterns & variants", "large"),
  "brians_brain_bench": ("Brian's Brain / multi-state", "medium"),
  "brians_brain_display": ("Brian's Brain / multi-state", "applied"),
  "wireworld_toy": ("Wireworld / CA circuits", "small"),
  "wireworld_bench": ("Wireworld / CA circuits", "medium"),
  "langton_toy": ("Langton's ant / turmites", "small"),
  "langton_bench": ("Langton's ant / turmites", "medium"),
  "langton_swarm": ("Langton's ant / turmites", "applied"),
  "hex_ca_toy": ("Alternative neighbourhoods (hex)", "small"),
  "neighbourhood_bench": ("Alternative neighbourhoods (hex)", "medium"),
  "lenia_room": ("Continuous CA (Lenia)", "large"),
  "lenia_aquarium": ("Continuous CA (Lenia)", "applied"),
  "reaction_diffusion_bench": ("Reaction-diffusion (Turing)", "medium"),
  "lattice_gas_bench": ("Lattice gas / physical CA", "medium"),
  "lattice_gas_room": ("Lattice gas / physical CA", "large"),
  "lattice_gas_pump": ("Lattice gas / physical CA", "applied"),
  "four_classes_toy": ("The four Wolfram classes", "small"),
  "four_classes_bench": ("The four Wolfram classes", "medium"),
  "four_classes_room": ("The four Wolfram classes", "large"),
  "edge_of_chaos_bench": ("Edge of chaos / self-organisation", "medium"),
  "dendrite_toy": ("Growth & dendrites", "small"),
  "dendrite_bench": ("Growth & dendrites", "medium"),
  "cave_bench": ("Caves / percolation / cracks", "medium"),
  "stigmergy_toy": ("Stigmergy & ecological CA", "small"),
  "stigmergy_bench": ("Stigmergy & ecological CA", "medium"),
  "stigmergy_room": ("Stigmergy & ecological CA", "large"),
  "ca_texture_toy": ("CA materials & texture", "small"),
  "ca_texture_bench": ("CA materials & texture", "medium"),
  "ca_texture_wall": ("CA materials & texture", "large"),
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
        "Act I — one dimension (the rule)": ["Elementary CA (1D rules)", "Rule 30 — order to randomness", "Rule 90 — Sierpinski", "Rule 110 — universal computation"],
        "Act II — two dimensions (life)": ["Conway's Game of Life", "Life patterns & variants"],
        "Act III — beyond binary (states & neighbours)": ["Brian's Brain / multi-state", "Wireworld / CA circuits", "Langton's ant / turmites", "Alternative neighbourhoods (hex)"],
        "Act IV — matter & chemistry": ["Continuous CA (Lenia)", "Reaction-diffusion (Turing)", "Lattice gas / physical CA"],
        "Act V — the edge of chaos": ["The four Wolfram classes", "Edge of chaos / self-organisation", "3D / volumetric CA"],
        "Act VI — structure & world": ["Growth & dendrites", "Caves / percolation / cracks", "Stigmergy & ecological CA", "CA materials & texture"],
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
        "title": "Cellular Automata — every example, by concept",
        "note": "Every CA artifact in the project, grouped by the problem it solves and laddered "
                "small -> medium -> large -> applied. Duplicates kept. A queer-Wolfram reading runs through "
                "the truths: the run is the deep (computational irreducibility), the edge of chaos is the "
                "alive middle, and each rule is one contingent universe — not 'all the same' as the PCE claims. "
                "Generated by tools/build_ca_concept_map.py.",
        "acts": list(ACTS.keys()), "concepts": [c[0] for c in CONCEPTS], "concept_meta": meta,
        "total": total, "map_ready_total": sum(1 for c in groups for a in groups[c] if a["map_ready"]),
        "image_total": sum(1 for c in groups for a in groups[c] if a["has_image"]),
        "empty_slots": sum(len(meta[c]["missing_tiers"]) for c in groups), "groups": groups,
    }
    outpath = os.path.join(ROOT, "doc", "ca_concept_map.json")
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
