"""Build the Post-Crisis concept map.

Tenth concept map — and the third panel of the final-arc trilogy (foundations -> QFEP -> post-crisis).
"Knowing the limits of formalization, what do we build?" The constructive turn: incompleteness, bias,
contradiction, and rhizomatic thinking become DESIGN MATERIALS, not problems. Eight concepts across three
acts (critical algorithms / speculative computation / building on the edge), laddered small/medium/large/
applied. Writes doc/postcrisis_concept_map.json. Page: /postcrisis-map.

This is the sparsest sequence — most concepts start with 0-1 artifacts; the gaps are the point.

Run from repo root:  python tools/build_postcrisis_concept_map.py
"""
import json, glob, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG_DIR = os.path.normpath(os.path.join(ROOT, "..", "ada_encyclopedia", "public", "scene-catalog"))

HIGH_SIGNAL = {"postfoundations_crisis.json"}
GATE = re.compile(r"bias_from_inside|bias_visualiz|bias_|situated|wiki_fragment|rhizome|molecular_design|"
                  r"moleculardesigner|paraconsistent_eng|merge_conflict|cap_theorem|cap_walk|the_commons|"
                  r"commons_|collective_know|edge_is_ground|excluded_class|room_shape|valence|ethics_after|"
                  r"incompleteness_ethic|peer_produc|standpoint", re.I)
EXCLUDE = set()
def is_candidate(reg, lookup):
    if lookup.lower() in EXCLUDE:
        return False
    if lookup in FORCE:
        return True
    if reg in HIGH_SIGNAL:
        return True
    return bool(GATE.search(lookup))

CONCEPTS = [
 ("Bias as structural incompleteness",
  ["bias_from_inside", "bias_visualiz", "bias_", "excluded_class", "room_shape"],
  ["bias", "what the model can't see", "training data"],
  "Every model leaves something out — that's not a fixable bug, it's Gödel in the training data. Bias is the shape of what a system can't see from inside itself; you make it visible, you don't make it vanish."),
 ("Ethical design after incompleteness",
  ["ethics_after", "incompleteness_ethic", "applied_ethics"],
  ["ethics", "answerable", "choose what to exclude"],
  "If no system can be complete or neutral, ethics isn't a checkbox you pass — it's the ongoing work of choosing what to exclude, out loud, and staying answerable for it."),
 ("Paraconsistent engineering",
  ["paraconsistent_eng", "merge_conflict", "cap_theorem", "cap_walk", "dual_state"],
  ["contradiction in practice", "CAP", "merge", "survive the contradiction"],
  "Real systems hold contradictions every day — a merge conflict, the CAP theorem, two replicas that disagree. The post-crisis engineer doesn't resolve the contradiction; they build to survive it."),
 ("Situated computation",
  ["situated", "standpoint"],
  ["knowledge with a body", "view from nowhere", "Haraway"],
  "There is no view from nowhere. Every computation runs somewhere, on some body, from some angle — and saying so, instead of faking objectivity, is the stronger knowledge."),
 ("Collective knowledge / the commons",
  ["wiki_fragment", "the_commons", "commons_", "collective_know", "peer_produc"],
  ["commons", "the wiki not the encyclopedia", "many over one"],
  "After the single authoritative system fails, knowledge becomes a commons — edited by many, never finished, true-enough-for-now. The wiki, not the encyclopedia."),
 ("Rhizome networks",
  ["rhizome"],
  ["no center", "no hierarchy", "any point connects", "Deleuze"],
  "Deleuze & Guattari's rhizome: any point connects to any other, no center, no root, no hierarchy. A network you can cut anywhere and it regrows — the post-crisis shape of knowledge itself."),
 ("Molecular design after crisis",
  ["molecular", "valence"],
  ["build from valence", "geometry is constraint", "post-reductionist"],
  "Build from valence, not from blueprint — design at the molecular level where geometry is the constraint and the limits are the material. Making after reductionism."),
 ("The edge is the ground",
  ["edge_is_ground", "qfep_formula", "postcrisis_synth"],
  ["the limit is the foundation", "the edge is constitutive", "build on the outside"],
  "The whole arc lands here: the edge — incompleteness, bias, contradiction, the outside — was never the failure to overcome. It's the ground you build on. The limit is the foundation."),
]

APPLIED_KW = ["visualiz", "readout", "designer", "workbench", "tool", "engine", "_demo", "console",
              "walk", "press", "machine", "scanner", "meter", "press"]
LARGE_KW = ["_room", "_network", "rhizome", "_world", "_lab", "commons", "_field", "_hall"]
def tier_of(lookup, name, fp):
    low = (lookup + " " + name).lower()
    if any(k in low for k in APPLIED_KW): return "applied"
    if any(k in low for k in LARGE_KW) or fp >= 9: return "large"
    if fp >= 2: return "medium"
    return "small"

FORCE = {
  "bias_blindspot_toy": ("Bias as structural incompleteness", "small"),
  "bias_atlas_room": ("Bias as structural incompleteness", "large"),
  "ethics_toy": ("Ethical design after incompleteness", "small"),
  "ethics_bench": ("Ethical design after incompleteness", "medium"),
  "ethics_room": ("Ethical design after incompleteness", "large"),
  "accountability_ledger": ("Ethical design after incompleteness", "applied"),
  "merge_conflict_toy": ("Paraconsistent engineering", "small"),
  "cap_theorem_bench": ("Paraconsistent engineering", "medium"),
  "replica_room": ("Paraconsistent engineering", "large"),
  "situated_bench": ("Situated computation", "medium"),
  "standpoint_room": ("Situated computation", "large"),
  "commons_bench": ("Collective knowledge / the commons", "medium"),
  "commons_room": ("Collective knowledge / the commons", "large"),
  "peer_production_tool": ("Collective knowledge / the commons", "applied"),
  "rhizome_toy": ("Rhizome networks", "small"),
  "rhizome_bench": ("Rhizome networks", "medium"),
  "rhizome_grower": ("Rhizome networks", "applied"),
  "molecular_toy": ("Molecular design after crisis", "small"),
  "molecular_bench": ("Molecular design after crisis", "medium"),
  "molecular_room": ("Molecular design after crisis", "large"),
  "edge_ground_toy": ("The edge is the ground", "small"),
  "edge_ground_bench": ("The edge is the ground", "medium"),
  "edge_ground_room": ("The edge is the ground", "large"),
  "edge_ground_synthesis": ("The edge is the ground", "applied"),
  "bias_from_inside": ("Bias as structural incompleteness", "medium"),
  "bias_visualizer": ("Bias as structural incompleteness", "applied"),
  "situated_readout": ("Situated computation", "applied"),
  "wiki_fragment": ("Collective knowledge / the commons", "small"),
  "rhizome_cave_demo": ("Rhizome networks", "large"),
  "MolecularDesigner": ("Molecular design after crisis", "applied"),
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
        "Act I — critical algorithms": ["Bias as structural incompleteness", "Ethical design after incompleteness"],
        "Act II — speculative computation": ["Paraconsistent engineering", "Situated computation",
                                             "Collective knowledge / the commons", "Rhizome networks"],
        "Act III — building on the edge": ["Molecular design after crisis", "The edge is the ground"],
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
        "title": "Post-Crisis — every example, by design material",
        "note": "Knowing the limits of formalization, what do we build? The constructive turn — bias, "
                "incompleteness, contradiction, rhizome as design materials. The tenth concept map, third of "
                "the final-arc trilogy. Generated by tools/build_postcrisis_concept_map.py.",
        "acts": list(ACTS.keys()), "concepts": [c[0] for c in CONCEPTS], "concept_meta": meta,
        "total": total, "map_ready_total": sum(1 for c in groups for a in groups[c] if a["map_ready"]),
        "image_total": sum(1 for c in groups for a in groups[c] if a["has_image"]),
        "empty_slots": sum(len(meta[c]["missing_tiers"]) for c in groups), "groups": groups,
    }
    outpath = os.path.join(ROOT, "doc", "postcrisis_concept_map.json")
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
