"""Build the QFEP-Laboratory concept map.

Ninth concept map. Ladders the formula QFE = F - λE(S) + φΔE(S,t) by its TERMS — free energy & order (F),
entropy as possibility (E), the order-chaos dial (λ), rate & becoming (φ) — then where they meet (the edge
of chaos, the reactor) and the formula made yours (synthesis, the artist labs). Tiers small/medium/large/
applied (held term-sphere -> bench instrument -> room-scale field -> a console/reactor you operate).
Writes doc/qfep_concept_map.json. Page: /qfep-map.

Run from repo root:  python tools/build_qfep_concept_map.py
"""
import json, glob, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG_DIR = os.path.normpath(os.path.join(ROOT, "..", "ada_encyclopedia", "public", "scene-catalog"))

HIGH_SIGNAL = {"qfep.json"}
GATE = re.compile(r"qfep|lambda_slider|phi_slider|entropy|edge_of_chaos|turing_pattern|grab_sphere|"
                  r"shannon_workbench|emergence_zone|bifurcation_walkway", re.I)
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
 ("F — free energy & order",
  ["crystal", "ordered_grid", "snap_", "rigid_sculpture", "shannon", "grab_sphere_f"],
  ["order", "free energy", "structure", "low entropy"],
  "F is the cost and the comfort of order — the crystal, the lattice, the snapped-together solid. Minimize F alone and you get a perfect, frozen, dead thing. Necessary, and never enough."),
 ("E — entropy as possibility",
  ["entropy", "microstate", "possibility_space", "particle_chaos", "chaos_particles", "random_cubes",
   "fuzzy_cloud", "phase_cube", "grab_sphere_e"],
  ["possibility", "disorder", "microstates", "spread"],
  "E isn't disorder — it's count: the number of ways a thing could be. S = k log W. The pull toward the larger space of what's possible, the term that keeps the system from freezing solid."),
 ("λ — the order-chaos dial",
  ["lambda", "bifurcation_walkway", "complexity_pattern", "dissolving_form", "grab_sphere_lambda"],
  ["dial", "spectrum", "order to chaos", "balance"],
  "λ weights how hard entropy pulls. Turn it to zero and you get crystal; turn it to one and you get noise. Life sits at λ ≈ 0.3–0.5 — the dial-setting between the two deaths."),
 ("φ — rate & becoming",
  ["phi_slider", "transforming_pattern", "preserved_pattern", "fluid_form", "grab_sphere_phi"],
  ["rate", "becoming", "change over time", "sensitivity"],
  "φ cares not how much entropy but how fast it changes — ΔE over time. The term of becoming: a system sensitive to its own rate of change can preserve a pattern by keeping it moving."),
 ("The edge of chaos",
  ["edge_", "emergence", "turing_pattern"],
  ["edge of chaos", "critical", "complexity emerges"],
  "Where the four terms balance, complexity ignites — Turing patterns, emergence, the critical band that is neither frozen nor boiling. The edge isn't a failure state; it's the only place anything happens."),
 ("The reactor — the whole formula",
  ["qfep_reactor", "qfep_sandbox", "reactive_particle", "qfep_oscilloscope", "qfep_balance",
   "qfep_term_compass"],
  ["reactor", "sandbox", "all terms live", "full formula"],
  "All four knobs at once: the reactor where you set F, λ, φ and watch a dead-ordered or dead-random system flicker into life. The formula stops being written and starts being driven."),
 ("The formula made yours",
  ["qfep_formula_3d", "russell_paradox_workbench", "cantor_diagonal", "science_desk", "science_glasses",
   "anickayilab", "pipilottirist", "earths_delight"],
  ["synthesis", "made yours", "applied", "art"],
  "The formula handed over — the 3D equation you assemble, the artist's labs where QFEP drives a whole world. Not a claim to read but a machine to think with."),
]

APPLIED_KW = ["slider", "workbench", "console", "reactor", "oscilloscope", "compass", "detector", "meter",
              "puzzle", "_desk", "glasses", "sandbox"]
LARGE_KW = ["_world", "_lab", "walkway", "_zone", "_field", "_orb", "_core", "_delight", "particles",
            "_cloud", "phase_cube"]
def tier_of(lookup, name, fp):
    low = (lookup + " " + name).lower()
    if any(k in low for k in APPLIED_KW): return "applied"
    if any(k in low for k in LARGE_KW) or fp >= 9: return "large"
    if fp >= 2: return "medium"
    return "small"

FORCE = {}


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
        "Act I — the four terms": ["F — free energy & order", "E — entropy as possibility",
                                    "λ — the order-chaos dial", "φ — rate & becoming"],
        "Act II — where they meet": ["The edge of chaos", "The reactor — the whole formula"],
        "Act III — the formula made yours": ["The formula made yours"],
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
        "title": "QFEP Laboratory — every example, by term",
        "note": "The formula QFE = F - λE(S) + φΔE(S,t) laddered by its terms, small -> medium -> large -> "
                "applied. The ninth concept map. Truth: life exists at λ ≈ 0.3-0.5. "
                "Generated by tools/build_qfep_concept_map.py.",
        "acts": list(ACTS.keys()), "concepts": [c[0] for c in CONCEPTS], "concept_meta": meta,
        "total": total, "map_ready_total": sum(1 for c in groups for a in groups[c] if a["map_ready"]),
        "image_total": sum(1 for c in groups for a in groups[c] if a["has_image"]),
        "empty_slots": sum(len(meta[c]["missing_tiers"]) for c in groups), "groups": groups,
    }
    outpath = os.path.join(ROOT, "doc", "qfep_concept_map.json")
    json.dump(out, open(outpath, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    print(f"wrote {outpath}")
    print(f"TOTAL {total} across {len(CONCEPTS)} concepts | empty slots: {out['empty_slots']}")
    for c in CONCEPTS:
        arts = groups[c[0]]; t = {x: 0 for x in ["small", "medium", "large", "applied"]}
        for a in arts: t[a["tier"]] += 1
        miss = ",".join(meta[c[0]]["missing_tiers"]) or "-"
        cname = c[0].encode("ascii", "replace").decode()
        print(f"  {len(arts):2d}  S{t['small']} M{t['medium']} L{t['large']} A{t['applied']}  miss[{miss:22s}]  {cname}")

if __name__ == "__main__":
    main()
