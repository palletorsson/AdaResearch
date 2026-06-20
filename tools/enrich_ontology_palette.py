"""Factor the full sequence artifact palette into the thin ontologies.

The beats- and maps-derived ontologies only hold artifacts that are PLACED in maps. But each
sequence has a fuller list — every artifact whose registry entry tags it with that sequence
(`map_sequences`), placed or not. Those unplaced artifacts are the palette you build maps FROM,
exactly what /randomness-map shows with its small→applied ladder and map-ready badges.

This pass reads each doc/<seq>_concept_map.json, finds the sequence's registry-tagged artifacts
that aren't in it yet, and adds them — assigned to the best-matching concept by name overlap,
else a "· palette (unplaced)" concept — marked map_ready:false. Placed artifacts are marked
map_ready:true. Rich domains already carrying their full ladder (randomness, vector_forces, ca,
primitives, transformation) are left alone (nothing to add).

Run:  python tools/enrich_ontology_palette.py        # then mindmap_graph.py + map_ontology_fidelity.py
"""
import json, glob, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(ROOT, "doc")
REG = os.path.join(ROOT, "commons", "artifacts", "registry")
IMG_DIR = os.path.normpath(os.path.join(ROOT, "..", "ada_encyclopedia", "public", "scene-catalog"))


def load_registry():
    fp, nm, seq2lk = {}, {}, {}
    for p in glob.glob(os.path.join(REG, "*.json")):
        try:
            a = json.load(open(p, encoding="utf-8"))
        except Exception:
            continue
        a = a.get("artifacts", a)
        if not isinstance(a, dict):
            continue
        for lk, v in a.items():
            if not isinstance(v, dict):
                continue
            f = v.get("footprint") or v.get("parameters", {}).get("footprint")
            if isinstance(f, list) and len(f) >= 3:
                fp[lk] = max(1, int(round(f[0])) * int(round(f[2])))
            nm[lk] = v.get("name", lk)
            for s in v.get("map_sequences") or []:
                seq2lk.setdefault(s, set()).add(lk)
    return fp, nm, seq2lk


def words(s):
    return set(re.findall(r"[a-z]{3,}", s.lower()))


def tier_of(fp):
    return "large" if fp >= 9 else "medium" if fp >= 3 else "small"


def enrich(seq, fp, nm, palette, cm):
    concepts = cm["concepts"]
    orig = list(concepts)
    cwords = {k: words(k) for k in orig}
    pal_key = None
    added = 0
    for lk in sorted(palette):
        name = nm.get(lk, lk)
        aw = words(lk + " " + name)
        best, ov = None, 0
        for k in orig:
            o = len(cwords[k] & aw)
            if o > ov:
                ov, best = o, k
        f = fp.get(lk, 4)
        ent = {"lookup": lk, "name": name, "registry": "", "tier": tier_of(f), "fp": f,
               "has_image": os.path.exists(os.path.join(IMG_DIR, lk + ".png")),
               "recommended": False, "map_ready": False}
        if best and ov > 0:
            cm["groups"][best].append(ent)
        else:
            if pal_key is None:
                pal_key = "· palette (unplaced)"
                if pal_key not in cm["groups"]:
                    concepts.append(pal_key)
                    cm["groups"][pal_key] = []
                    cm["concept_meta"][pal_key] = {"act": "Act IV", "truth": "sequence artifacts available but not yet placed in a map", "tiers": {}, "count": 0}
            cm["groups"][pal_key].append(ent)
        added += 1
    # recompute tiers + count for every concept
    for k in concepts:
        tiers = {"small": [], "medium": [], "large": [], "applied": []}
        for a in cm["groups"][k]:
            tiers.setdefault(a["tier"], []).append(a["lookup"])
        cm["concept_meta"][k]["tiers"] = tiers
        cm["concept_meta"][k]["count"] = len(cm["groups"][k])
    cm["total"] = sum(len(cm["groups"][k]) for k in concepts)
    cm["total_concepts"] = len(concepts)
    cm["palette_total"] = sum(1 for k in concepts for a in cm["groups"][k] if not a.get("map_ready", True))
    return added


def main():
    fp, nm, seq2lk = load_registry()
    for p in sorted(glob.glob(os.path.join(DOC, "*_concept_map.json"))):
        seq = os.path.basename(p)[:-len("_concept_map.json")]
        if seq not in seq2lk:
            continue
        cm = json.load(open(p, encoding="utf-8"))
        placed = {a["lookup"] for k in cm["concepts"] for a in cm["groups"][k]}
        for k in cm["concepts"]:
            for a in cm["groups"][k]:
                a.setdefault("map_ready", True)
        palette = seq2lk[seq] - placed
        if not palette:
            continue
        added = enrich(seq, fp, nm, palette, cm)
        json.dump(cm, open(p, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
        print("%-22s +%d palette artifacts (now %d total, %d unplaced)" % (seq, added, cm["total"], cm.get("palette_total", 0)))


if __name__ == "__main__":
    main()
