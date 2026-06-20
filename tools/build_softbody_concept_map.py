"""Build the comprehensive Soft-Body concept map.

Sixth concept map — the keystone. Soft bodies are the project's `integration` layer: they pull together
forces (springs), CA (the edge of chaos), morphogenesis (form), and gradient descent (machine learning).
Scans the registries (soft_bodies.json is the core), classifies soft-body artifacts into 17 concepts
across 6 acts (the spring & the mass / finding its shape / cloth, jelly, flesh / the membrane / the soft
creature / soft as the lambda_edge), tiers each small/medium/large/applied. Writes doc/softbody_concept_map.json.

The truths carry the QFEP / affect thread the work asked for: soft is the lambda_edge made flesh (rigid-
but-not-structureless); a soft body settling is gradient descent seeking MAX Q (the liveliest minimum, not
the deepest); the membrane is the Markov blanket made literal; the abject is a force; the octopus is the
queer body. Reuses the soft_body_sim / SpringMassSystem engine. Ties to the morphogenesis DNA bridge.

Run from repo root:  python tools/build_softbody_concept_map.py
"""
import json, glob, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG_DIR = os.path.normpath(os.path.join(ROOT, "..", "ada_encyclopedia", "public", "scene-catalog"))

HIGH_SIGNAL = {"soft_bodies.json"}
GATE = re.compile(r"soft|jelly|cloth|squish|verlet|spring_mass|mass_spring|membrane|blob|octopus|tentacle|"
                  r"miura|flagdanc|radiolaria|pressure_soft|\bfold|breathing|affect_theory|abject|"
                  r"morpho|viscous|gelatin|wobble|deform", re.I)
EXCLUDE = {
    "frozen_glass_vessel", "gallery_marker_soft-body", "soft_stage_dashboard",
    "fold_theatre_runner", "noise_terrain_with_blobs",   # CA runner / a noise terrain (kept elsewhere)
    "bigpipe_crossmanifold", "glassrack_sbendmanifold",
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
 ("Mass-spring networks",
  ["spring_mass_system", "spring_mass_bouncer", "mass_spring_damper", "softmill", "mass_spring"],
  ["spring", "rest length", "node"],
  "A soft body is a graph of masses and springs: each spring pulls toward its rest length, and the whole settles into a shape nobody specified."),
 ("Verlet & the soft-body sim",
  ["verlet_integration", "softbody3d", "softbodytest", "soft_bodies", "rounded_softbody", "soft_body_sim"],
  ["verlet", "constraint", "integrate"],
  "Integrate position from position, not velocity, and the constraints hold without ever being solved — Verlet, the cheap physics of cloth and flesh."),
 ("Strain, pressure & elasticity",
  ["pressure_soft_body", "rounded_softbody", "strain_energy"],
  ["strain", "pressure", "elastic", "stiffness"],
  "What lets a soft body keep its shape: internal pressure pushing out, strain energy pulling back — a balance held, not a skeleton imposed."),
 ("Settling: gradient descent toward max Q",
  ["settle_to_shape", "gradient_descent_soft", "relaxation_body"],
  ["equilibrium", "relax", "energy landscape", "minimum"],
  "A soft body finds its shape by descending an energy landscape — the same motion as an optimiser finding a minimum. A rigid body sits in one deep well (dead); a soft body lives in a shallow, moving one (alive). Max Q is the liveliest minimum, not the deepest."),
 ("Jelly & deformation",
  ["jelly_cube", "jelly_variants", "soft_body_slicer", "jelly"],
  ["deform", "wobble", "elastic return"],
  "Push it and it pushes back, then forgets — elastic deformation, the body that returns to itself."),
 ("Cloth physics",
  ["cloth_simulation", "cloth_straps", "flex_cloth_pad", "softstopscene", "cloth"],
  ["drape", "tear", "wind", "fabric"],
  "A grid of springs draping under gravity: cloth is the simplest soft body, all surface and no inside, the one that learns to fold from nothing but its own weight."),
 ("Bounce & play",
  ["soft_trampoline", "squishy_ball_pit", "revolving_joy_ride", "pendulum_slap", "bouncer"],
  ["bounce", "rebound", "trampoline", "pit"],
  "Store the impact in the springs and give it back — the trampoline, the ball pit, the joy of a body that bounces instead of breaking."),
 ("Viscous & flowing",
  ["viscous_fluid_blob", "soft_mushroom", "soft_mushrooms", "blob", "viscous"],
  ["flow", "ooze", "fluid", "mushroom"],
  "Turn down the stiffness and the soft body starts to flow — the blob, the mushroom, the edge where soft becomes fluid."),
 ("The membrane",
  ["layered_membrane", "membrane", "cell_membrane"],
  ["permeable", "boundary", "blanket"],
  "The original soft body: a selectively-permeable boundary that makes an inside while letting the world cross. The Markov blanket made flesh — the edge an organism holds by exchanging."),
 ("Breathing & the abject boundary",
  ["breathing_room", "pressure_soft", "breathing"],
  ["breathe", "bulge", "burst", "swell"],
  "A boundary that holds by moving — it breathes, it bulges, it could burst. The abject: the edge that troubles the line between inside and out."),
 ("Origami & the Miura fold",
  ["folded_strip", "foldedpaper", "folding_cube", "helix_fold", "folding_past", "miura_fold", "origami"],
  ["crease", "miura", "flat-foldable"],
  "Crease a flat sheet and it remembers how to become solid — the Miura fold packs a map, a solar array, a wing into a line."),
 ("Folding creatures",
  ["miura_crawler", "fold_demo_critter", "folding_zoo", "fold_wall", "folding_cube_interactive"],
  ["crawler", "critter", "fold to move"],
  "A creature that is a fold: it moves by folding and unfolding — structure that walks by changing its shape, not by pushing against bone."),
 ("Tentacle & octopus",
  ["tentacle_cube", "tentacle_placer", "octopus", "tentacle"],
  ["arm", "boneless", "distributed"],
  "No skeleton, not a puddle — the octopus is all soft middle: distributed cognition across eight arms, a body that pours through any gap. The queer body par excellence."),
 ("Soft morphology",
  ["morphobody", "morphogen_tide_pool", "morpho_egg", "morphogenesis_bench", "morpho_menagerie", "radiolaria", "morphology"],
  ["morphogen", "emerge", "form-process"],
  "Form is not imposed — it emerges from the material's own dynamics. Soft morphology is where the body keeps finding its shape after it is grown; the body to the L-system's grammar and the RD bridge's skin."),
 ("Soft vs rigid (the alive middle)",
  ["soft_vs_rigid", "rigidity_dial", "lambda_soft"],
  ["rigid", "stiffness sweep", "edge of soft"],
  "Rigid has one shape and is dead; fluid has none and is dead; soft is the only state that holds a form and still flows — the lambda_edge made flesh."),
 ("The abject as force",
  ["affect_theory_visualization", "affect_theory", "queer_morphology_specimen", "abject"],
  ["affect", "abjection", "kristeva", "the body that troubles"],
  "Kristeva's abject: the soft body that troubles the boundary, the membrane that leaks, the flesh that won't stay bounded — abjection as a generative force, softness as a feeling."),
 ("Matter that finds its shape",
  ["entropy_morphogenesis", "matter_finds_shape", "soft_thesis"],
  ["thesis", "self-organise", "becoming"],
  "Entropy becoming morphology: the soft body is the project's thesis made flesh — gradient descent toward max Q, structure that persists by moving, the edge of chaos you can poke."),
 ("Grab & stretch (native soft bodies)",
  ["grab_jelly", "stretch_blob", "taffy_pull"],
  ["grab", "pin", "stretch", "handle"],
  "A real SoftBody3D pinned to grabbable handles: take hold of a corner and the jelly stretches like taffy, let go and it wobbles back. The soft body you can grab."),
 ("Poke & dent (native soft bodies)",
  ["poke_dough", "pressure_balloon", "poke_pillar", "squish_press"],
  ["poke", "dent", "press", "pressure"],
  "Its collision skin carries the player layer, so a hand or body pushing in dents it and it springs back. Pressure pushes out, the poke pushes in - strain you can feel."),
 ("Bounce & pile (native soft bodies)",
  ["bounce_blob", "bounce_membrane", "jelly_ball_pit", "soft_catapult"],
  ["bounce", "trampoline", "pile", "pit", "sling"],
  "Soft bodies that store an impact and give it back: a trampoline membrane, a pit of squishy balls you wade through, a sling that stores the throw."),
 ("Soft pets & membranes (native)",
  ["blob_pet", "tentacle_grab", "curtain_membrane", "soft_handshake"],
  ["pet", "tentacle", "curtain", "handshake", "creature"],
  "Soft bodies as beings and boundaries you touch: a pet you grab by the scruff, a boneless tentacle that follows your hand, a curtain you part, a paw that squeezes back."),
]

APPLIED_KW = ["slicer", "placer", "mill", "trampoline", "ball_pit", "_pit", "joy_ride", "tide_pool",
              "specimen", "visualization", "gallery", "_zoo", "menagerie", "crawler", "bouncer", "dashboard"]
LARGE_KW = ["_hall", "tower", "_past"]
def tier_of(lookup, name, fp):
    low = (lookup + " " + name).lower()
    if any(k in low for k in APPLIED_KW): return "applied"
    if any(k in low for k in LARGE_KW) or fp >= 9: return "large"
    if fp >= 3: return "medium"
    return "small"

FORCE = {
  "grab_jelly_toy": ("Grab & stretch (native soft bodies)", "small"),
  "grab_jelly_bench": ("Grab & stretch (native soft bodies)", "medium"),
  "stretch_blob_room": ("Grab & stretch (native soft bodies)", "large"),
  "taffy_pull": ("Grab & stretch (native soft bodies)", "applied"),
  "poke_dough_toy": ("Poke & dent (native soft bodies)", "small"),
  "pressure_balloon": ("Poke & dent (native soft bodies)", "medium"),
  "poke_pillar_room": ("Poke & dent (native soft bodies)", "large"),
  "squish_press": ("Poke & dent (native soft bodies)", "applied"),
  "bounce_blob_toy": ("Bounce & pile (native soft bodies)", "small"),
  "bounce_membrane": ("Bounce & pile (native soft bodies)", "medium"),
  "jelly_ball_pit_room": ("Bounce & pile (native soft bodies)", "large"),
  "soft_catapult": ("Bounce & pile (native soft bodies)", "applied"),
  "blob_pet_toy": ("Soft pets & membranes (native)", "small"),
  "tentacle_grab_bench": ("Soft pets & membranes (native)", "medium"),
  "curtain_membrane_room": ("Soft pets & membranes (native)", "large"),
  "soft_handshake": ("Soft pets & membranes (native)", "applied"),
  "spring_node_toy": ("Mass-spring networks", "small"),
  "mass_spring_bench": ("Mass-spring networks", "medium"),
  "verlet_workbench": ("Verlet & the soft-body sim", "applied"),
  "pressure_dome_room": ("Strain, pressure & elasticity", "large"),
  "elasticity_press": ("Strain, pressure & elasticity", "applied"),
  "descent_marble_toy": ("Settling: gradient descent toward max Q", "small"),
  "energy_landscape_bench": ("Settling: gradient descent toward max Q", "medium"),
  "max_q_basin_room": ("Settling: gradient descent toward max Q", "large"),
  "gradient_descent_optimizer": ("Settling: gradient descent toward max Q", "applied"),
  "jelly_room": ("Jelly & deformation", "large"),
  "cloth_loom": ("Cloth physics", "applied"),
  "bounce_egg_toy": ("Bounce & play", "small"),
  "bounce_arena_room": ("Bounce & play", "large"),
  "viscous_bench": ("Viscous & flowing", "medium"),
  "lava_lamp_tool": ("Viscous & flowing", "applied"),
  "membrane_toy": ("The membrane", "small"),
  "membrane_bench": ("The membrane", "medium"),
  "membrane_filter": ("The membrane", "applied"),
  "breathing_toy": ("Breathing & the abject boundary", "small"),
  "breathing_hall_room": ("Breathing & the abject boundary", "large"),
  "pressure_valve_tool": ("Breathing & the abject boundary", "applied"),
  "miura_press": ("Origami & the Miura fold", "applied"),
  "folding_menagerie_room": ("Folding creatures", "large"),
  "octopus_bench": ("Tentacle & octopus", "medium"),
  "octopus_room": ("Tentacle & octopus", "large"),
  "rigidity_toy": ("Soft vs rigid (the alive middle)", "small"),
  "rigidity_dial_bench": ("Soft vs rigid (the alive middle)", "medium"),
  "lambda_edge_room": ("Soft vs rigid (the alive middle)", "large"),
  "aliveness_meter": ("Soft vs rigid (the alive middle)", "applied"),
  "abject_toy": ("The abject as force", "small"),
  "abject_bench": ("The abject as force", "medium"),
  "abject_room": ("The abject as force", "large"),
  "becoming_toy": ("Matter that finds its shape", "small"),
  "becoming_bench": ("Matter that finds its shape", "medium"),
  "self_shaping_forge": ("Matter that finds its shape", "applied"),
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
        "Act I — the spring & the mass": ["Mass-spring networks", "Verlet & the soft-body sim"],
        "Act II — finding its shape": ["Strain, pressure & elasticity", "Settling: gradient descent toward max Q"],
        "Act III — cloth, jelly, flesh": ["Jelly & deformation", "Cloth physics", "Bounce & play", "Viscous & flowing"],
        "Act IV — the membrane": ["The membrane", "Breathing & the abject boundary"],
        "Act V — the soft creature": ["Origami & the Miura fold", "Folding creatures", "Tentacle & octopus", "Soft morphology"],
        "Act VI — soft as the lambda_edge": ["Soft vs rigid (the alive middle)", "The abject as force", "Matter that finds its shape"],        "Act VII — touch it (native SoftBody3D)": ["Grab & stretch (native soft bodies)", "Poke & dent (native soft bodies)", "Bounce & pile (native soft bodies)", "Soft pets & membranes (native)"],
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
        "title": "Soft Bodies — every example, by concept",
        "note": "Every soft-body artifact in the project, grouped by the problem it solves and laddered "
                "small -> medium -> large -> applied. Soft bodies are the keystone (the integration layer): "
                "forces + CA + morphogenesis + gradient descent become one body seeking max Q. The truths carry "
                "the QFEP/affect thread — soft is the lambda_edge made flesh, settling is gradient descent toward "
                "the liveliest minimum, the membrane is the Markov blanket, the octopus is the queer body. "
                "Generated by tools/build_softbody_concept_map.py.",
        "acts": list(ACTS.keys()), "concepts": [c[0] for c in CONCEPTS], "concept_meta": meta,
        "total": total, "map_ready_total": sum(1 for c in groups for a in groups[c] if a["map_ready"]),
        "image_total": sum(1 for c in groups for a in groups[c] if a["has_image"]),
        "empty_slots": sum(len(meta[c]["missing_tiers"]) for c in groups), "groups": groups,
    }
    outpath = os.path.join(ROOT, "doc", "softbody_concept_map.json")
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
