"""Build the comprehensive Vector & Force concept map.

Scans every artifact registry, classifies each genuine vector/force artifact into one of
25 concepts (keeping ALL duplicates that solve the same problem), records whether a
scene-catalog image exists, and writes doc/vector_forces_concept_map.json — the data
behind the encyclopedia /vector-force-map page.

Run from repo root:  python tools/build_vector_force_concept_map.py
"""
import json, glob, os, sys, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG_DIR = os.path.normpath(os.path.join(ROOT, "..", "ada_encyclopedia", "public", "scene-catalog"))

# Candidate gating — keep precision high. Registries that are dominantly vector/force get all
# their concept-matching artifacts; every other registry must have a force/vector token in the
# LOOKUP name (so a fractal/hashmap/window that merely mentions a keyword in its description is
# excluded). The concept-score requirement then filters the gate-passers.
HIGH_SIGNAL = {"vectors.json", "vectors_demos.json", "physics_simulation.json"}
GATE = re.compile(r"vector|force|pendulum|spring|orbit|gravit|momentum|torque|drag|friction|"
                  r"projectile|centrifug|centripet|launch|catapult|lever|calder|bounce|"
                  r"restitution|coordinate|basis_vector|normaliz|magnitude|scale|scalar|"
                  r"dot_product|cross_product|projection|reflection|weather_vane|windmill|"
                  r"attractor|nbody|n_body|velocit|cradle|impulse|workbench|field|flow", re.I)
# clear strays that match a keyword but aren't vector/force curriculum examples
EXCLUDE = {
    "strange_attractors", "chaos_attractor",          # dynamical-systems attractors, not gravity
    "rule_30_110_gravity",                            # a cellular automaton
    "simulation_instability", "profile_spring", "profile_gradient_descent",  # profiling/test scenes
    "gravity_gun_test_scene",                         # test scene
}
def is_candidate(reg, lookup):
    if lookup in EXCLUDE:
        return False
    if reg in HIGH_SIGNAL:
        return True
    if re.fullmatch(r"[a-z0-9_]+\.json", reg) and GATE.search(lookup):  # per-artifact / gated reg
        return True
    return bool(GATE.search(lookup))

# concept -> (strong keywords [weight 3], weak keywords [weight 1]). Order = specific first;
# ties break to the earlier (more specific) concept. "General force / pad" is the catch-all.
CONCEPTS = [
 ("Coordinate system", ["coordinate","basis vector","basis_vector","cartesian","coordinatesystem","homogeneous_coordinates","xyz_coordinates","polar_to_cartesian"], []),
 ("Vector basics", ["vectorbasics","vector basics","what is a vector","build a vector","build_a_vector","vector_intro","free_vector"], []),
 ("Magnitude / length", ["magnitude","length_lantern","vector length","vector_magnitude","stretch_bench"], [r"re:\bnorm\b"]),
 ("Unit vector / normalize", ["normalize","normaliz","unit vector","vector_normalize"], []),
 ("Addition", ["vector_add","vectoraddition","vector addition","adder_board","vector_addition",r"re:\bresultant\b","head to tail","tip to tail"], []),
 ("Subtraction", ["vector_sub","vectorsubtraction","vector subtraction","vector_subtraction","difference vector"], []),
 ("Scaling", ["scaleme","scale_me","scalar","vector multiplication","multiplication_vr","scaled_by_mass","pickup_cube_scaling","array_scale","scale_lines"], ["scaling"]),
 ("Dot product", ["dot_product","dotproduct","dot_aligner","dot product","vectordotproduct"], ["agreement","alignment"]),
 ("Projection / reflection", ["projection_shadow","projectionreflection","vectorprojection","projection vector","reflection vector","reflection_hall"], [r"re:\bprojection\b",r"re:\breflect"]),
 ("Cross product / torque", ["cross_product","crossproduct","vectorcross","vectortorque","torque_crank","cross product","torque"], ["perpendicular"]),
 ("Vector field / flow", ["vector_field","vectorfield","vectorfieldflow","flow_field","flowfield","weather_vector_field","vector field","flow field","streamline"], [r"re:\bflow field\b"]),
 ("Motion / velocity", ["vectormotion","vector_motion","velocity","kinematic","motion vector","bubble_blaster","smart_rocket"], [r"re:\bmotion\b","accelerat"]),
 ("Work (F.d)", ["force_mower","work_meter","work done","f.d","f·d","cos_theta_work","mower"], [r"re:\bwork\b"]),
 ("Friction / drag", ["friction","drag_lane","drag_corridor","fluid_resistance","fluid resistance","air resistance","example_2_5"], [r"re:\bdrag\b","resistance","damper"]),
 ("Projectile / launch", ["projectile","launch_arc","launcher","catapult","ballistic","vectorthrowing","projectile motion","trajectory","return_launcher","human_catapult","mortar_vector"], [r"re:\blaunch\b",r"re:\bthrow"]),
 ("Centripetal", ["centripet","centrifuge","circle_train","circular motion","uniform circular"], []),
 ("Gravity / orbit", ["gravit","attractor","attraction","barycenter","orbital","n-body","n_body","nbody","two_body","three_body","kepler","gravity_well","orbit_pair","orbit_walk"], []),
 ("Spring / Hooke", ["spring","hooke","springsuspension","mass_spring","spring_bob","spring_tower"], ["oscillat","coil"]),
 ("Pendulum", ["pendulum","chainswing","coupled_pendulum","doublependulum"], [r"re:\bswing\b"]),
 ("Momentum / collision", ["momentum","newton_cradle","newton cradle","cradle","impulse","collision_cart","collision_crasher","impulse_collision"], []),
 ("Restitution / bounce", ["restitution","bounce_well","coefficient of restitution","bounce height","bouncing ball"], [r"re:\bbounce\b","rebound"]),
 ("Lever / balance", ["lever","calder","seesaw","fulcrum","torque balance","balance_puzzle","lever_balance","calder_mobile","calder_object"], [r"re:\bbalance\b"]),
 ("Wind / weather", ["weather_vane","windmill",r"re:\bwind\b","breeze","weather vector"], ["flag"]),
 ("Force field (zone)", ["force_field","force_field_zone","field zone","void crossing","force_vortex","vector_machine"], []),
 ("General force / pad", ["force_pad","force_cube","forcemagnitude","f = ma","f=ma","newtons_laws","applied force","vectorforces","example_2_1","example_2_2","example_2_3","example_3_2","exercise_1"], [r"re:\bforce\b",r"re:\bnewton\b"]),
]

# Four slots per concept, smallest→biggest in space and abstract→applied:
#   small   — intimate, held (footprint <=2)
#   medium  — bench / console (footprint 3-8)
#   large   — room-scale walk-in installation (footprint >=9 or a walk-in name)
#   applied — the concept doing a real job (a tool or scenario), regardless of size
# Heuristic only — the picker UI lets the human override per slot.
APPLIED_KW = ["mower", "catapult", "launcher", "slingshot", "mobile", "weather_vane", "windmill",
              "cradle", "bounce_well", "force_field_zone", "vortex", "_gun", "gun_test", "siege",
              "mortar", "return_", "human_", "wind_tunnel", "drone", "arena", "_game"]
LARGE_KW = ["_xl", "xl_", "_walk", "_hall", "_tower", "_ring", "corridor", "chamber", "storm", "centrifuge"]
def tier_of(lookup, name, fp):
    low = (lookup + " " + name).lower()
    if any(k in low for k in APPLIED_KW): return "applied"
    if any(k in low for k in LARGE_KW) or fp >= 9: return "large"
    if fp >= 3: return "medium"
    return "small"

def _hit(text, kw):
    if kw.startswith("re:"):
        return re.search(kw[3:], text) is not None
    return kw in text

def score(text, strong, weak):
    return sum(3 for k in strong if _hit(text, k)) + sum(1 for k in weak if _hit(text, k))

def main():
    groups = {c[0]: [] for c in CONCEPTS}
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
            best, bestscore = None, 0
            for cname, strong, weak in CONCEPTS:
                sc = score(text, strong, weak)
                if any(_hit(low_lookup, k) for k in strong):
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
                    "tier": tier_of(lookup, name, snfp),
                })
    # mark the recommended artifact per concept, read from the tutorial spines (the curated pick)
    recommended = {}
    truth_by_art = {}
    for sp in glob.glob(os.path.join(ROOT, "doc", "*_tutorial_spine.json")):
        try:
            s = json.load(open(sp, encoding="utf-8"))
        except Exception:
            continue
        sid = str(s.get("id", os.path.basename(sp)))
        for cc in s.get("concepts", []):
            art = cc.get("artifact")
            if art:
                recommended.setdefault(art, []).append(sid)
                if cc.get("truth") and art not in truth_by_art:
                    truth_by_art[art] = cc["truth"]
    for c in groups:
        for a in groups[c]:
            a["recommended"] = a["lookup"] in recommended
            a["spines"] = recommended.get(a["lookup"], [])
        # recommended first, then has-image, then map-ready, then name
        groups[c].sort(key=lambda a: (not a["recommended"], not a["has_image"], not a["map_ready"], a["lookup"].lower()))

    # the five acts (the tutorial arc), so the page can group concepts
    ACTS = {
        "Act I — what a vector is": ["Coordinate system", "Vector basics", "Magnitude / length", "Unit vector / normalize"],
        "Act II — vector arithmetic": ["Addition", "Subtraction", "Scaling", "Dot product", "Projection / reflection", "Cross product / torque"],
        "Act III — fields & motion": ["Vector field / flow", "Motion / velocity"],
        "Act IV — forces": ["Work (F.d)", "Friction / drag", "Projectile / launch", "Centripetal", "Gravity / orbit", "Spring / Hooke", "Pendulum", "Momentum / collision", "Restitution / bounce", "Lever / balance", "Wind / weather"],
        "Act V — force as place": ["Force field (zone)", "General force / pad"],
    }
    concept_act = {cc: act for act, cs in ACTS.items() for cc in cs}
    vector_acts = {"Act I — what a vector is", "Act II — vector arithmetic", "Act III — fields & motion"}
    meta = {}
    for c in groups:
        arts = groups[c]
        act = concept_act.get(c, "")
        best = next((a["lookup"] for a in arts if a["recommended"]), None)
        TIERS = ["small", "medium", "large", "applied"]
        by_tier = {t: [a["lookup"] for a in arts if a["tier"] == t] for t in TIERS}
        meta[c] = {
            "count": len(arts),
            "map_ready": sum(1 for a in arts if a["map_ready"]),
            "best": best,
            "truth": truth_by_art.get(best, ""),
            "act": act,
            "kind": "vector" if act in vector_acts else "force",
            "thin": len(arts) <= 1 or not any(a["map_ready"] for a in arts),
            "tiers": by_tier,
            "missing_tiers": [t for t in TIERS if not by_tier[t]],
        }
    total = sum(len(v) for v in groups.values())
    out = {
        "title": "Vectors & Forces — every example, by concept",
        "note": "Comprehensive map of all vector and force artifacts, grouped by the problem each solves. Duplicates (multiple artifacts for the same concept) are kept on purpose. Recommended pick per concept comes from the tutorial spines. Generated by tools/build_vector_force_concept_map.py.",
        "acts": list(ACTS.keys()),
        "concepts": [c[0] for c in CONCEPTS],
        "concept_meta": meta,
        "total": total,
        "recommended_total": sum(1 for c in groups for a in groups[c] if a["recommended"]),
        "map_ready_total": sum(1 for c in groups for a in groups[c] if a["map_ready"]),
        "groups": groups,
    }
    outpath = os.path.join(ROOT, "doc", "vector_forces_concept_map.json")
    json.dump(out, open(outpath, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    print(f"wrote {outpath}")
    print(f"TOTAL {total} artifacts across {len(CONCEPTS)} concepts")
    for c in CONCEPTS:
        arts = groups[c[0]]
        imgs = sum(1 for a in arts if a["has_image"])
        print(f"  {len(arts):2d} ({imgs} img)  {c[0]}")

if __name__ == "__main__":
    main()
