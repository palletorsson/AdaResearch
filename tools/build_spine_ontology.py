"""Build a spine sequence's ontology from its beat score — automatically.

The beat score already IS the ontology: an ordered list of concepts, each owning a set of maps.
So the classification is structural, not guessed: artifact -> the map it sits in -> that map's
beat -> the concept. Concept distance comes from TF-IDF over each beat's concept text + its maps'
blurb/intent prose. Emits doc/<seq>_concept_map.json in the shape tools/mindmap_graph.py consumes,
so the sequence flows straight into /mind-map, /q-maps, and the editor ontology comparison.

Run:  python tools/build_spine_ontology.py                 # all *.beats.json without an existing map
      python tools/build_spine_ontology.py color noise     # named sequences
"""
import json, glob, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import concept_distance_text as T

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(ROOT, "doc")
REG = os.path.join(ROOT, "commons", "artifacts", "registry")
MAPS = os.path.join(ROOT, "commons", "maps")
SEQ = os.path.join(MAPS, "sequences")
IMG_DIR = os.path.normpath(os.path.join(ROOT, "..", "ada_encyclopedia", "public", "scene-catalog"))
MAIN_ROLES = {"INTRODUCE", "DEMONSTRATE", "SYNTHESIZE", "PRACTICE"}
ACTS = ["Act I", "Act II", "Act III", "Act IV"]


def load_registry_maps():
    fp, nm = {}, {}
    for p in glob.glob(os.path.join(REG, "*.json")):
        try:
            d = json.load(open(p, encoding="utf-8"))
        except Exception:
            continue
        a = d.get("artifacts", d)
        if not isinstance(a, dict):
            continue
        for lk, v in a.items():
            if not isinstance(v, dict):
                continue
            f = v.get("footprint") or v.get("parameters", {}).get("footprint")
            if isinstance(f, list) and len(f) >= 3:
                fp[lk] = max(1, int(round(f[0])) * int(round(f[2])))
            nm[lk] = v.get("name", lk)
    return fp, nm


def map_artifacts(mapname):
    p = os.path.join(MAPS, mapname, "map_data.json")
    if not os.path.exists(p):
        return []
    try:
        inter = json.load(open(p, encoding="utf-8")).get("layers", {}).get("interactables") or []
    except Exception:
        return []
    out = []
    for row in inter:
        for cell in row or []:
            if isinstance(cell, str) and cell.strip():
                lk = cell.split(":")[0].strip()
                if lk and not lk.startswith("#") and not lk.startswith("sub"):
                    out.append(lk)
    return out


def map_text(mapname):
    txt = ""
    for fn in ("blurb.md", "intent.md"):
        p = os.path.join(MAPS, mapname, fn)
        if os.path.exists(p):
            txt += " " + open(p, encoding="utf-8").read()
    return txt


def rescale(M):
    n = len(M)
    raw = [M[i][j] for i in range(n) for j in range(i + 1, n)]
    if raw and max(raw) > min(raw):
        lo, hi = min(raw), max(raw)
        return [[0.0 if i == j else round((M[i][j] - lo) / (hi - lo), 4) for j in range(n)] for i in range(n)]
    return M


def build(seq, FP, NM):
    beats = json.load(open(os.path.join(SEQ, seq + ".beats.json"), encoding="utf-8")).get("beats", [])
    concepts, meta, groups, texts = [], {}, {}, []
    used = set()
    for b in beats:
        maps = b.get("maps") or []
        if not maps:
            continue
        concept = (b.get("concept") or b.get("id") or "").strip()
        key = re.split(r"[—\-:]", concept)[0].strip()[:38] or b.get("id", "beat")
        if key in used:
            key = "%s (%s)" % (key, b.get("id", len(concepts)))
        used.add(key)
        arts, seen, ctext = [], set(), concept
        for m in maps:
            ctext += " " + map_text(m)
            for lk in map_artifacts(m):
                if lk in seen:
                    continue
                seen.add(lk)
                fp = FP.get(lk, 4)
                tier = "large" if fp >= 9 else "medium" if fp >= 3 else "small"
                arts.append({"lookup": lk, "name": NM.get(lk, lk), "tier": tier, "fp": fp,
                             "has_image": os.path.exists(os.path.join(IMG_DIR, lk + ".png")),
                             "recommended": b.get("role") in MAIN_ROLES})
        if not arts:
            continue
        concepts.append(key)
        groups[key] = arts
        meta[key] = {"truth": concept[:220], "role": b.get("role", ""), "id": b.get("id", "")}
        texts.append(ctext)

    n = len(concepts)
    for idx, key in enumerate(concepts):
        meta[key]["act"] = ACTS[min(3, int(idx * 4 / max(1, n)))]
        tiers = {"small": [], "medium": [], "large": [], "applied": []}
        for a in groups[key]:
            tiers[a["tier"]].append(a["lookup"])
        meta[key]["tiers"] = tiers
        meta[key]["count"] = len(groups[key])

    vecs, _ = T.tfidf(texts) if texts else ([], [])
    CD = rescale([[0.0 if i == j else T.cos_d(vecs[i], vecs[j]) for j in range(n)] for i in range(n)]) if n else []

    return {
        "title": seq, "domain": seq,
        "note": "Ontology derived from the beat score by tools/build_spine_ontology.py (concepts = beats, artifacts = their maps').",
        "acts": [], "concepts": concepts,
        "concept_meta": {k: meta[k] for k in concepts},
        "concept_distance": CD,
        "groups": {k: groups[k] for k in concepts},
        "total": sum(len(groups[k]) for k in concepts), "total_concepts": n,
        "recommended_total": sum(1 for k in concepts for a in groups[k] if a["recommended"]),
        "map_ready_total": sum(1 for k in concepts for a in groups[k] if a["recommended"]),
    }


def main():
    args = sys.argv[1:]
    have = {os.path.basename(p)[:-len("_concept_map.json")] for p in glob.glob(os.path.join(DOC, "*_concept_map.json"))}
    beat_seqs = [os.path.basename(p).replace(".beats.json", "") for p in sorted(glob.glob(os.path.join(SEQ, "*.beats.json")))]
    targets = args if args else [s for s in beat_seqs if s not in have]
    FP, NM = load_registry_maps()
    for seq in targets:
        if not os.path.exists(os.path.join(SEQ, seq + ".beats.json")):
            print("skip %s: no beats file" % seq); continue
        out = build(seq, FP, NM)
        if out["total_concepts"] == 0:
            print("skip %s: no beats with placed artifacts" % seq); continue
        json.dump(out, open(os.path.join(DOC, seq + "_concept_map.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
        print("%-22s %2d concepts · %3d artifacts -> doc/%s_concept_map.json" % (seq, out["total_concepts"], out["total"], seq))


if __name__ == "__main__":
    main()
