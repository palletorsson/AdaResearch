"""Build the comprehensive Randomness & Noise concept map.

Sister tool to build_vector_force_concept_map.py. Scans every artifact registry, classifies each
genuine randomness/noise artifact into one of 19 concepts (keeping ALL duplicates that solve the
same problem), records whether a scene-catalog image exists, tiers each as small/medium/large/
applied, and writes doc/randomness_concept_map.json — the data behind the encyclopedia
/randomness-map page.

Run from repo root:  python tools/build_randomness_concept_map.py
"""
import json, glob, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG_DIR = os.path.normpath(os.path.join(ROOT, "..", "ada_encyclopedia", "public", "scene-catalog"))

# Candidate gating — randomness.json is the dominant domain registry (every artifact in it passes);
# every other registry must have a randomness token in the LOOKUP name (so a fractal/graph/window
# that merely mentions "random" in its description is excluded). The concept-score then filters.
HIGH_SIGNAL = {"randomness.json"}
GATE = re.compile(r"random|noise|perlin|simplex|worley|gauss|markov|monte_carlo|montecarlo|stochast|"
                  r"entropy|prng|trng|seed|probab|dice|coin_toss|galton|walk|scatter|shuffl|"
                  r"distribut|blue_noise|pollock|ten_print|molnar|annealing|bell_curve|plinko|"
                  r"dartboard|slot_machine|rejection|particle_randomness|whitenoise|cloudvolume", re.I)
# clear strays that match a keyword but aren't randomness curriculum examples
EXCLUDE = {
    "force_directed_layout", "graphspace", "small_world_network",   # graph layouts that merely seed randomly
    "astar", "karger_algorithm",                                    # graph algorithms
    "grid3d_random_graph", "rhizomatic_structure",                  # structure, not the teaching of randomness
    "latent_space_walk",                                            # ML latent traversal, not a random walk
    "walkingsphere",                                                # a walking-controller test, not a random walk
    "plane_manipulator", "pickup_cube_placer", "pickup_cube_scaling",  # editor/manip helpers
    "mobius_world", "mobius_strip_altgeo",                          # geometry
}
def is_candidate(reg, lookup):
    if lookup in EXCLUDE or lookup.startswith("profile_"):   # profile_* are profiling test scenes
        return False
    if lookup in FORCE:   # explicit gap-fillers / bridges always pass, even from non-randomness registries
        return True
    if reg in HIGH_SIGNAL:
        return True
    if re.fullmatch(r"[a-z0-9_]+\.json", reg) and GATE.search(lookup):  # gated per-artifact reg
        return True
    return bool(GATE.search(lookup))

# concept -> (strong keywords [weight 3], weak keywords [weight 1], truth). Order = specific first;
# ties break to the earlier (more specific) concept. Specific noise/process concepts precede the
# general "noise fields" / "random transformations" / "random art" catch-alls.
CONCEPTS = [
 ("Uniform random / RNG",
  ["randompoint","randompoints","randompoints_uniform","plane_random","random_space","randomup",
   "spawn_randomcubes","random_number_book","randomness_vis","2d_in_3d_randomness","randomlines"],
  ["uniform","rng","random number"],
  "Flat chance — every outcome equally likely; the rectangle of pure ignorance before structure arrives."),
 ("Coin / dice / discrete chance",
  ["coin_toss","dice_throw","slot_machine"],
  ["coin","dice","discrete","odds"],
  "Discrete chance — a finite set of faces, each with its slice of certainty."),
 ("Random walk",
  ["random_walk","walk_random","crystal_random_walk","random_walk_leash","random_walk_grab",
   "random_walk_collection","random_walk_128","random_walk_terrarium"],
  ["walker","brownian","drunkard"],
  "A path with no plan — each step a fresh coin, the whole a drunkard's signature."),
 ("Probability distribution",
  ["distribution_visualization","distribution_sampler","distribution_comparator",
   "probability_distributions","probability_distributions_3d","height_random","histogram",
   "bar_array_histogram"],
  ["probability","distribution"],
  "Not all outcomes are equal — a distribution is the shape chance prefers."),
 ("Gaussian / normal",
  ["gaussian_random","randompoints_gaussian","random_bell_curve","bell_alley","random_gaussian_texture",
   "randomgaussiantexture","gaussianblurcircle","gaussianblurshader","gaussianpaintsplatter",
   "noisecolors","galton_board","gaussian"],
  ["normal","bell curve","bell_curve","std dev"],
  "The bell is what many small accidents add up to — the central-limit attractor."),
 ("Custom / rejection sampling",
  ["rejection_sampling","accept_reject","custom_distribution"],
  ["rejection","custom distribution","probability function"],
  "Throw darts, keep the ones under the curve — sample any shape by refusing the rest."),
 ("Monte Carlo",
  ["monte_carlo","monte_carlo_dartboard","monte_carlo_estimator","monte_carlo_protein","dartboard"],
  ["monte carlo","estimate pi"],
  "Estimate the unknowable by throwing enough random darts at it."),
 ("Perlin noise",
  ["perlin_noise","perlin","perlinvolume","perlin_noise_clouds","perlin_noise_terrain",
   "particle_randomness_perlin","perlin_noise_bridge","perlin_terrain_sculptor"],
  ["perlin","gradient noise"],
  "Smooth, coherent randomness — noise with neighbours, the texture of the natural world."),
 ("Simplex / Worley / value noise",
  ["value_noise","simplex_noise","worley_noise","cellularnoise","shader_08_cellularnoise"],
  ["simplex","worley","value noise","cellular noise"],
  "Other ways to make coherent noise — lattices, cells, and gradients beyond Perlin."),
 ("Noise fields & textures",
  ["noise_mixer","noise_space","noiselayers","noisesphere","noisetorus","noisetext","noisecolors3d",
   "voxelnoise","voxel_noise","shader_07_noise","shader_noise_space","curl_noise","pool_hole_noise",
   "whitenoise","white_noise","cloudvolume","marchingcubes_voxel_noise","voxelnoiserois","neon_wave_grid"],
  ["noise field","noise texture","noise"],
  "Noise becomes a field — every point in space assigned a value that flows."),
 ("Noise terrain / landscapes",
  ["noise_terrain","noise_terrain_with_blobs","pheromone_terrain","noiseterrain"],
  ["terrain","landscape","heightmap"],
  "Let noise be height — and randomness becomes landscape."),
 ("Blue noise / sampling",
  ["blue_noise","instancingscatter","poisson"],
  ["blue noise","poisson","scatter","jitter","even spacing"],
  "Random but evenly spaced — chance without clumping, the eye's preferred scatter."),
 ("Markov chains",
  ["markov_chains","markov_chains_tree","markov"],
  ["markov","transition matrix","state machine"],
  "The next state remembers only the last — memoryless chains that still make patterns."),
 ("Seeds / PRNG vs TRNG",
  ["seed_replay","prng_crank","trng_vs_prng","prng","trng","hardware_entropy_decay","grid2d_seeds"],
  ["deterministic","reproducib","pseudo-random","pseudorandom","seed"],
  "Pseudo-randomness is deterministic in disguise — same seed, same 'chance' every time."),
 ("Entropy",
  ["entropy_jar","entropy_axiom","shannon_entropy_meter","extreme_randomness","hardware_entropy",
   "entropy_morphogenesis","digital_materiality_glitch","glitch_grid_floor","glitch_body"],
  ["entropy","disorder","surprise","bits"],
  "Randomness measured — how many bits of surprise a source actually carries."),
 ("Random transformations",
  ["random_transformations","random_rotate","rotate_random","randomize_cubes_over_z","randomize_cubes",
   "random_decay","random_edge_profile","remove_random","random_destructor","rotate_grid_cubes",
   "random_rotate_random_xyz","random_decay_multimesh","random_decay_objects","height_random","randomup"],
  ["random rotate","random transform","randomized","perturb"],
  "Perturb the regular — rotation, position, decay drawn from chance."),
 ("10 PRINT / generative grid",
  ["ten_print","ten_print_maze","ten_print_maze_3d"],
  ["10 print","maze","generative grid"],
  "One line of chance per cell builds a maze — the smallest generative grammar."),
 ("Random art / scatter",
  ["pollock","pollock_3d","pollock_painting","molnar","vera_molnar","random_butterflies","random_plants",
   "random_bubbles","bubbles_random","random_color_book","random_color_book_page","omoss","sculpt_one",
   "kitbashing","kitbash_station","constraint_sculptor"],
  ["scatter","splatter","drip","generative art"],
  "Chance as a brush — Pollock's drips, Molnar's disorder, the aesthetics of the unplanned."),
 ("Particle randomness",
  ["particle_randomness","particle_randomness_pure","particle_randomness_patterns",
   "particle_randomness_emergent","particle_randomness_evolutionary","bubble_particles",
   "instancingscatter","spawn_randomcubes"],
  ["particle","emergent","swarm"],
  "Give a thousand particles their own dice — emergent texture from individual chance."),
 ("Seeded growth / DNA -> form",
  ["dna_sprout","genome_bench","seed_vs_random","genetic_tree_sculptor"],
  ["dna","genome","l-system","morphology","seeded growth"],
  "The deep end of randomness: a short genome (CritterDNA) grown by an L-system into a unique, "
  "reproducible organism. Not flat chance — store the seed, replay the costly growth. Same seed, same form."),
]

# Four slots per concept, smallest->biggest in space and abstract->applied:
#   small   — intimate, held (footprint <=2)
#   medium  — bench / console (footprint 3-8)
#   large   — room-scale walk-in installation (footprint >=9 or a walk-in name)
#   applied — the concept doing a real job (a tool/instrument/scenario), regardless of size
# NB: coin_toss / dice_throw / ten_print are the SMALLEST primitives of their concept, not applied
# tools — leave them out so fp/size tiers them as small. slot_machine (_machine), galton_board (_board),
# monte_carlo_dartboard etc. are genuine applied instruments.
APPLIED_KW = ["galton", "dartboard", "slot_machine", "crank", "_meter",
              "_estimator", "_sculptor", "terrarium", "rejection_sampling", "seed_replay",
              "trng_vs_prng", "prng_crank", "monte_carlo", "plinko", "entropy_jar",
              "pollock", "molnar", "_machine", "_jar", "_comparator", "_bridge",
              "destructor", "remove_random", "_placer", "_station", "decay", "kitbash"]
LARGE_KW = ["_alley", "alley", "gallery", "_space", "volume", "_world", "_hall", "_128", "env_one",
            "terrain", "cloudvolume", "melting", "bernini", "landscape", "_collection", "neon_wave"]
def tier_of(lookup, name, fp):
    low = (lookup + " " + name).lower()
    if any(k in low for k in APPLIED_KW): return "applied"
    if any(k in low for k in LARGE_KW) or fp >= 9: return "large"
    if fp >= 3: return "medium"
    return "small"


# The 31 gap-filling artifacts built 2026-06-17 — explicit (concept, tier) so they land in their
# intended ladder rung deterministically, regardless of keyword/footprint heuristics.
FORCE = {
 "rejection_toy": ("Custom / rejection sampling", "small"), "rejection_bench": ("Custom / rejection sampling", "medium"), "rejection_room": ("Custom / rejection sampling", "large"),
 "pi_dart_toy": ("Monte Carlo", "small"), "pi_dart_bench": ("Monte Carlo", "medium"), "pi_dart_room": ("Monte Carlo", "large"),
 "coin_dice_bench": ("Coin / dice / discrete chance", "medium"), "dice_rain_room": ("Coin / dice / discrete chance", "large"),
 "random_walk_bench": ("Random walk", "medium"), "distribution_bench": ("Probability distribution", "medium"),
 "perlin_bench": ("Perlin noise", "medium"), "noise_compare_bench": ("Simplex / Worley / value noise", "medium"), "noise_displacer": ("Simplex / Worley / value noise", "applied"),
 "noise_flow_drones": ("Noise fields & textures", "applied"),
 "noise_height_toy": ("Noise terrain / landscapes", "small"), "noise_dunes_bench": ("Noise terrain / landscapes", "medium"), "noise_terrain_forge": ("Noise terrain / landscapes", "applied"),
 "blue_noise_toy": ("Blue noise / sampling", "small"), "blue_noise_bench": ("Blue noise / sampling", "medium"), "blue_noise_planter": ("Blue noise / sampling", "applied"),
 "seed_toy": ("Seeds / PRNG vs TRNG", "small"), "seed_bench": ("Seeds / PRNG vs TRNG", "medium"),
 "entropy_bench": ("Entropy", "medium"), "markov_melody": ("Markov chains", "applied"), "jitter_bench": ("Random transformations", "medium"),
 "ten_print_toy": ("10 PRINT / generative grid", "small"), "ten_print_bench": ("10 PRINT / generative grid", "medium"), "ten_print_textile": ("10 PRINT / generative grid", "applied"),
 "scatter_bench": ("Random art / scatter", "medium"), "random_fireworks": ("Particle randomness", "applied"), "lottery_drum": ("Uniform random / RNG", "applied"),
 # the seed -> form bridge (2026-06-18): randomness ladder meets the CritterDNA / L-system galleries
 "dna_sprout": ("Seeded growth / DNA -> form", "small"), "genome_bench": ("Seeded growth / DNA -> form", "medium"),
 "seed_vs_random": ("Seeded growth / DNA -> form", "large"), "genetic_tree_sculptor": ("Seeded growth / DNA -> form", "applied"),
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
            text = " ".join([k, lookup, name, str(v.get("category","")), str(v.get("class_name","")),
                             " ".join(str(t) for t in tags), str(v.get("description",""))[:200]]).lower()
            low_lookup = lookup.lower()
            forced = FORCE.get(lookup)
            if forced:
                best, bestscore = forced[0], 99   # explicit gap-filler — skip keyword classification
            else:
                best, bestscore = None, 0
                for cname, strong, weak, _truth in CONCEPTS:
                    sc = score(text, strong, weak)
                    if any(_hit(low_lookup, kk) for kk in strong):
                        sc += 3   # a strong match in the lookup NAME dominates description-only matches
                    if sc > bestscore:
                        best, bestscore = cname, sc
            if best and bestscore >= 3:           # require at least one strong (or 3 weak) match
                seen.add(k)
                snfp = (v.get("spatial_needs", {}) or {}).get("footprint_cells", 1)
                if isinstance(snfp, list):
                    nums = [int(x) for x in snfp if x]
                    snfp = max(nums) if nums else 1
                else:
                    snfp = int(snfp or 1)
                groups[best].append({
                    "lookup": lookup, "name": name, "registry": reg,
                    "category": str(v.get("category","")),
                    "map_ready": bool(v.get("map_ready")),
                    "has_image": os.path.exists(os.path.join(IMG_DIR, lookup + ".png")),
                    "score": bestscore,
                    "fp": snfp,
                    "tier": forced[1] if forced else tier_of(lookup, name, snfp),
                })
    for c in groups:
        # has-image, then map-ready, then higher score, then name
        groups[c].sort(key=lambda a: (not a["has_image"], not a["map_ready"], -a["score"], a["lookup"].lower()))

    # the five acts (the curriculum arc), so the page can group concepts
    ACTS = {
        "Act I — pure chance": ["Uniform random / RNG", "Coin / dice / discrete chance", "Random walk"],
        "Act II — distributions": ["Probability distribution", "Gaussian / normal", "Custom / rejection sampling", "Monte Carlo"],
        "Act III — noise": ["Perlin noise", "Simplex / Worley / value noise", "Noise fields & textures", "Noise terrain / landscapes", "Blue noise / sampling"],
        "Act IV — process & measure": ["Markov chains", "Seeds / PRNG vs TRNG", "Entropy"],
        "Act V — randomness as material": ["Random transformations", "10 PRINT / generative grid", "Random art / scatter", "Particle randomness"],
        "Act VI — randomness as growth": ["Seeded growth / DNA -> form"],
    }
    concept_act = {cc: act for act, cs in ACTS.items() for cc in cs}
    meta = {}
    for c in groups:
        arts = groups[c]
        TIERS = ["small", "medium", "large", "applied"]
        by_tier = {t: [a["lookup"] for a in arts if a["tier"] == t] for t in TIERS}
        # default "best" pick: prefer an artifact that has an image AND is map-ready, else first
        best = next((a["lookup"] for a in arts if a["has_image"] and a["map_ready"]), None)
        if not best and arts:
            best = arts[0]["lookup"]
        meta[c] = {
            "count": len(arts),
            "map_ready": sum(1 for a in arts if a["map_ready"]),
            "has_image": sum(1 for a in arts if a["has_image"]),
            "best": best,
            "truth": truth_by_concept[c],
            "act": concept_act.get(c, ""),
            "thin": len(arts) <= 1,
            "tiers": by_tier,
            "missing_tiers": [t for t in TIERS if not by_tier[t]],
        }
    total = sum(len(v) for v in groups.values())
    out = {
        "title": "Randomness & Noise — every example, by concept",
        "note": "Comprehensive map of all randomness/noise artifacts, grouped by the problem each solves. "
                "Duplicates (multiple artifacts for the same concept) are kept on purpose so you can pick "
                "the one you want. Each concept gets a small -> medium -> large -> applied ladder. "
                "Generated by tools/build_randomness_concept_map.py.",
        "acts": list(ACTS.keys()),
        "concepts": [c[0] for c in CONCEPTS],
        "concept_meta": meta,
        "total": total,
        "map_ready_total": sum(1 for c in groups for a in groups[c] if a["map_ready"]),
        "image_total": sum(1 for c in groups for a in groups[c] if a["has_image"]),
        "empty_slots": sum(len(meta[c]["missing_tiers"]) for c in groups),
        "groups": groups,
    }
    outpath = os.path.join(ROOT, "doc", "randomness_concept_map.json")
    json.dump(out, open(outpath, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    print(f"wrote {outpath}")
    print(f"TOTAL {total} artifacts across {len(CONCEPTS)} concepts | empty slots: {out['empty_slots']}")
    for c in CONCEPTS:
        arts = groups[c[0]]
        t = {x: 0 for x in ["small","medium","large","applied"]}
        for a in arts: t[a["tier"]] += 1
        miss = ",".join(meta[c[0]]["missing_tiers"]) or "-"
        print(f"  {len(arts):2d}  S{t['small']} M{t['medium']} L{t['large']} A{t['applied']}  miss[{miss:24s}]  {c[0]}")

if __name__ == "__main__":
    main()
