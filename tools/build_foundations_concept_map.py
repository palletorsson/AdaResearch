"""Build the Foundations-Crisis concept map.

Eighth concept map. Unlike the algorithmic domains, this one ladders a HISTORY — the 19th-20th century
crisis that shattered mathematical certainty — by the limit each idea stages: the parallel postulate,
non-Euclidean geometry, Russell's paradox, Gödel's incompleteness, the halting problem, Escher's
impossible objects, Brouwer's intuitionism, Florensky's paraconsistency, and the edge the whole crisis
points at. Tiers small/medium/large/applied (held token -> staging diagram -> room-scale space -> a
workbench/tool you operate). Writes doc/foundations_concept_map.json. Page: /foundations-map.

Run from repo root:  python tools/build_foundations_concept_map.py
"""
import json, glob, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG_DIR = os.path.normpath(os.path.join(ROOT, "..", "ada_encyclopedia", "public", "scene-catalog"))

HIGH_SIGNAL = {"foundations.json", "foundations_crisis.json"}
GATE = re.compile(
    r"euclid|parallel_line|angle_sum|postulate|non_euclid|noneuclid|hyperbolic|elliptic|poincare|"
    r"riemann_sphere|riemann_pi|riemann_torus|curvature|triangle_curvature|russell|barber_paradox|"
    r"liar_loop|self_membership|godel|incompleteness|provab|sentence_machine|halting|hilbert_hotel|"
    r"escher_stair|penrose_triangle|magritte|impossible_trident|brouwer|constructive|excluded_middle|"
    r"choice_sequence|florensky|paraconsist|both_true|schrodinger_box|superposition|quantum_superposition|"
    r"bifurcation_diagram|complexity_dial", re.I)
EXCLUDE = {
    "barber_pole", "florensky_in_production", "riemann_pump", "riemann_sum_workbench",
    "penrose_tilings", "loom_bolt_escher_pmm", "loom_escher_mirror", "mill_escher_p4g",
    "grammar_tessellation_field_alhambra_penrose_d_vertex",
    "grammar_tessellation_field_alhambra_penrose_decagon_patch",
    "grammar_tessellation_field_alhambra_penrose_sun",
}
def is_candidate(reg, lookup):
    if lookup.lower() in EXCLUDE:
        return False
    if lookup in FORCE:
        return True
    if reg in HIGH_SIGNAL:
        return True
    return bool(GATE.search(lookup))

# concept -> (strong [lookup bonus], weak, truth)
CONCEPTS = [
 ("Euclid & the parallel postulate",
  ["euclid", "parallel_line", "angle_sum", "postulate"],
  ["fifth postulate", "flat space", "self-evident"],
  "Five axioms held flat space together for two millennia — and the fifth, the one about parallels, was the one nobody could prove from the others. The crack starts where the obvious turns out to be a choice."),
 ("Non-Euclidean geometry",
  ["non_euclid", "noneuclid", "hyperbolic", "elliptic", "poincare", "riemann_sphere", "riemann_pi",
   "riemann_torus", "curvature"],
  ["negative curvature", "angles of a triangle", "the surface decides"],
  "Drop the fifth postulate and geometry doesn't break — it multiplies. On a sphere triangles bulge past 180°, on a saddle they fall short. There was never one geometry; the surface decides."),
 ("Russell's paradox",
  ["russell", "barber_paradox", "liar_loop", "self_membership"],
  ["set of all sets", "self-reference", "the barber"],
  "The set of all sets that don't contain themselves: does it contain itself? Either answer is its own refutation. Self-reference turned the foundations of set theory against themselves."),
 ("Gödel's incompleteness",
  ["godel", "incompleteness", "provab", "sentence_machine"],
  ["true but unprovable", "this is unprovable", "the gap"],
  "Any system strong enough to do arithmetic can write the sentence 'this is unprovable' — true, and forever out of its own reach. Consistency buys incompleteness; the gap never closes."),
 ("Halting & infinity",
  ["halting", "hilbert_hotel"],
  ["undecidable", "Turing", "countable infinity"],
  "Some questions have no algorithm — will this program stop? — and some infinities make room for more of themselves. The limits of computation and of counting, same crisis, different door."),
 ("Escher & impossible objects",
  ["escher", "penrose_triangle", "magritte", "impossible_trident"],
  ["impossible figure", "locally consistent", "blivet"],
  "The Penrose triangle and the endless staircase are consistent at every corner and impossible as a whole — a drawing that lies only when you take it all in. The local rules don't add up to a global truth."),
 ("Brouwer & intuitionism",
  ["brouwer", "constructive", "excluded_middle", "choice_sequence"],
  ["only the constructed", "reject excluded middle", "intuition"],
  "Brouwer refused to call a thing true until you could build it. No law of the excluded middle, no proof by contradiction from thin air — only what you can construct exists. Mathematics as an act, not a discovery."),
 ("Florensky & paraconsistency",
  ["florensky", "paraconsist", "both_true", "schrodinger_box", "superposition", "quantum_superposition"],
  ["both true", "contradiction survived", "no explosion"],
  "Classical logic says one contradiction proves everything. Florensky and the paraconsistent logicians said: hold the contradiction, and the world doesn't end. P and not-P, and reasoning carries on."),
 ("The crisis & the edge",
  ["bifurcation_diagram", "complexity_dial", "crisis"],
  ["the edge is constitutive", "lambda to zero", "incompleteness as feature"],
  "The crisis isn't a list of failures — it's one discovery: every formal system has an outside, and the edge where it meets that outside is where the life is. Pure order can't close. The limit is the feature."),
]

APPLIED_KW = ["workbench", "slider", "_demo", "scale", "dial", "sorter", "machine", "pump", "detector",
              "compass", "console", "oscilloscope", "puzzle"]
LARGE_KW = ["_space", "_torus", "riemann_pi", "tilings", "diagram", "walkway", "_room", "_world", "_lab"]
def tier_of(lookup, name, fp):
    low = (lookup + " " + name).lower()
    if any(k in low for k in APPLIED_KW): return "applied"
    if any(k in low for k in LARGE_KW) or fp >= 9: return "large"
    if fp >= 2: return "medium"
    return "small"

FORCE = {
  "euclid_parallel_bench": ("Euclid & the parallel postulate", "medium"),
  "flatland_room": ("Euclid & the parallel postulate", "large"),
  "curvature_bench": ("Non-Euclidean geometry", "medium"),
  "russell_paradox_room": ("Russell's paradox", "large"),
  "godel_incompleteness_room": ("Gödel's incompleteness", "large"),
  "halting_bench": ("Halting & infinity", "medium"),
  "hilbert_hotel_room": ("Halting & infinity", "large"),
  "escher_room": ("Escher & impossible objects", "large"),
  "impossible_object_press": ("Escher & impossible objects", "applied"),
  "constructive_room": ("Brouwer & intuitionism", "large"),
  "paraconsistent_room": ("Florensky & paraconsistency", "large"),
  "contradiction_engine": ("Florensky & paraconsistency", "applied"),
  "crisis_edge_toy": ("The crisis & the edge", "small"),
  "crisis_synthesis_bench": ("The crisis & the edge", "medium"),
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
                for cname, strong, weak, _t in CONCEPTS:
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
        "Act I — geometry cracks": ["Euclid & the parallel postulate", "Non-Euclidean geometry"],
        "Act II — self-reference": ["Russell's paradox", "Gödel's incompleteness", "Halting & infinity"],
        "Act III — the impossible & the constructive": ["Escher & impossible objects", "Brouwer & intuitionism"],
        "Act IV — living with the limit": ["Florensky & paraconsistency", "The crisis & the edge"],
    }
    concept_act = {cc: act for act, cs in ACTS.items() for cc in cs}
    meta = {}
    for c in groups:
        arts = groups[c]; TIERS = ["small", "medium", "large", "applied"]
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
        "title": "Foundations Crisis — every example, by limit",
        "note": "The 19th-20th century crisis of certainty, laddered by the limit each idea stages, "
                "small -> medium -> large -> applied. The eighth concept map. Truth: every formal system has "
                "an outside. Generated by tools/build_foundations_concept_map.py.",
        "acts": list(ACTS.keys()), "concepts": [c[0] for c in CONCEPTS], "concept_meta": meta,
        "total": total, "map_ready_total": sum(1 for c in groups for a in groups[c] if a["map_ready"]),
        "image_total": sum(1 for c in groups for a in groups[c] if a["has_image"]),
        "empty_slots": sum(len(meta[c]["missing_tiers"]) for c in groups), "groups": groups,
    }
    outpath = os.path.join(ROOT, "doc", "foundations_concept_map.json")
    json.dump(out, open(outpath, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    print(f"wrote {outpath}")
    print(f"TOTAL {total} across {len(CONCEPTS)} concepts | empty slots: {out['empty_slots']}")
    for c in CONCEPTS:
        arts = groups[c[0]]; t = {x: 0 for x in ["small", "medium", "large", "applied"]}
        for a in arts: t[a["tier"]] += 1
        miss = ",".join(meta[c[0]]["missing_tiers"]) or "-"
        print(f"  {len(arts):2d}  S{t['small']} M{t['medium']} L{t['large']} A{t['applied']}  miss[{miss:22s}]  {c[0]}")

if __name__ == "__main__":
    main()
