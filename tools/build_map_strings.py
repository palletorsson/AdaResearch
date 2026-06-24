#!/usr/bin/env python3
"""Build the per-map STRING OF PEARLS (the table of contents) for each spine map.

For every map: take its existing artifacts in curriculum order, then ENRICH — fold in the sequence's
concept-map artifacts that aren't placed anywhere yet, each inserted next to its nearest existing
neighbour (ontological cosine). Every pearl is tagged size (small/large by measured footprint, the
landmark/cluster split), source (existing/added), and concept. Writes doc/map_strings/<Map>.json —
the shared truth the encyclopedia editor edits and Godot unfolds.

Run: python tools/build_map_strings.py            # all 22 spine sequences
     python tools/build_map_strings.py --seq primitives
"""
import argparse
import json
import os
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from build_corridor import (load_embeddings, load_sizes, roster_from_map_groups,  # noqa: E402
                            ALIASES, LARGE_M, INFRA)

SPINE = ["primitives", "transformation", "array_tutorial", "color", "change", "forces",
         "wavefunctions", "randomness", "noise", "cellularautomata", "fractals", "lsystems",
         "proceduralgeneration", "softbodies", "isosurfaces", "boolean_surfaces", "swarmintelligence",
         "machinelearning", "graphtheory", "foundationscrisis", "qfeplaboratory", "postfoundationscrisis"]


def concept_roster(seq):
    """name -> {concept, name} from the sequence's concept map ladder (best + tiers)."""
    for cand in (ALIASES.get(seq, seq), seq):
        p = os.path.join(ROOT, "doc", "%s_concept_map.json" % cand)
        if os.path.exists(p):
            d = json.load(open(p, encoding="utf-8"))
            cm = d.get("concept_meta", {})
            disp = {}
            for c in d.get("concepts", []):
                meta = cm.get(c, {})
                names = ([meta["best"]] if meta.get("best") else [])
                for tier in ("small", "medium", "large", "applied"):
                    names += (meta.get("tiers", {}) or {}).get(tier, [])
                for n in names:
                    disp.setdefault(n, c)
            return disp
    return {}


def _display_names():
    import glob
    disp = {}
    for f in glob.glob(os.path.join(ROOT, "commons", "artifacts", "registry", "*.json")):
        try:
            d = json.load(open(f, encoding="utf-8"))
        except Exception:
            continue
        for k, v in (d.get("artifacts", {}) or {}).items():
            if isinstance(v, dict):
                disp[v.get("lookup_name", k)] = v.get("name", k)
    return disp


def build_sequence(seq, idx, V, sizes, disp, cap):
    groups = roster_from_map_groups(seq)        # [(map_name, [existing names])]
    if not groups:
        return [], 0
    concepts = concept_roster(seq)              # name -> concept
    placed = set(n for _, arts in groups for n in arts)
    # enrichment candidates: concept-map artifacts not placed anywhere in this sequence + embedded
    candidates = [n for n in concepts if n not in placed and n in idx and n not in INFRA]

    # assign each candidate to the map whose existing-artifact centroid is nearest (cosine)
    centroids = {}
    for mp, arts in groups:
        rows = [idx[a] for a in arts if a in idx]
        centroids[mp] = V[rows].mean(axis=0) if rows else None
    assign = {mp: [] for mp, _ in groups}
    for n in candidates:
        v = V[idx[n]]
        best, bestd = None, -1.0
        for mp, c in centroids.items():
            if c is None:
                continue
            s = float(np.dot(v, c) / (np.linalg.norm(c) + 1e-9))
            if s > bestd:
                bestd, best = s, mp
        if best:
            assign[best].append(n)

    # Cap suggestions per map to the best-fitting few (keep it curatable; add the rest by hand in the editor).
    for mp, cand in assign.items():
        c = centroids[mp]
        if c is not None and len(cand) > cap:
            cand.sort(key=lambda n: -float(np.dot(V[idx[n]], c) / (np.linalg.norm(c) + 1e-9)))
            assign[mp] = cand[:cap]

    def size_of(n):
        sp = sizes.get(n)
        return "large" if (sp is not None and max(sp[0], sp[1]) > LARGE_M) else "small"

    def pearl(n, source):
        sp = sizes.get(n) or (1.0, 1.0)
        return {"id": n, "name": disp.get(n, n), "size": size_of(n), "source": source,
                "concept": concepts.get(n, ""), "footprint": [round(sp[0], 1), round(sp[1], 1)]}

    out, added_total = [], 0
    for mp, arts in groups:
        # existing pearls in curriculum order
        string = [pearl(n, "existing") for n in arts if n not in INFRA]
        # insert each assigned candidate after its nearest existing neighbour (ontological)
        existing_rows = [(p["id"], idx[p["id"]]) for p in string if p["id"] in idx]
        for n in assign[mp]:
            v = V[idx[n]]
            pos = len(string)
            if existing_rows:
                best_i, best_s = 0, -1.0
                for i, (eid, er) in enumerate(existing_rows):
                    s = float(np.dot(v, V[er]))
                    if s > best_s:
                        best_s, best_i = s, i
                # find that neighbour's index in `string`, insert just after it
                nbr_id = existing_rows[best_i][0]
                pos = next((j for j, p in enumerate(string) if p["id"] == nbr_id), len(string)) + 1
            string.insert(pos, pearl(n, "added"))
            added_total += 1
        out.append({
            "map": mp, "sequence": seq,
            "counts": {"existing": sum(1 for p in string if p["source"] == "existing"),
                       "added": sum(1 for p in string if p["source"] == "added"),
                       "large": sum(1 for p in string if p["size"] == "large")},
            "pearls": string,
        })
    return out, added_total


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seq")
    ap.add_argument("--cap", type=int, default=6, help="max enrichment suggestions per map")
    args = ap.parse_args()
    seqs = [args.seq] if args.seq else SPINE
    idx, V = load_embeddings()
    sizes = load_sizes()
    disp = _display_names()
    out_dir = os.path.join(ROOT, "doc", "map_strings")
    os.makedirs(out_dir, exist_ok=True)
    index = []
    grand_added = grand_maps = 0
    for seq in seqs:
        strings, added = build_sequence(seq, idx, V, sizes, disp, args.cap)
        for s in strings:
            json.dump(s, open(os.path.join(out_dir, s["map"] + ".json"), "w", encoding="utf-8"),
                      indent=1, ensure_ascii=False)
            index.append({"map": s["map"], "sequence": seq, **s["counts"]})
            grand_maps += 1
        grand_added += added
        print("  %-22s %2d maps, +%d pearls enriched" % (seq, len(strings), added))
    json.dump({"maps": index}, open(os.path.join(out_dir, "_index.json"), "w", encoding="utf-8"),
              indent=1, ensure_ascii=False)
    print("\n%d maps, +%d enrichment pearls -> doc/map_strings/" % (grand_maps, grand_added))


if __name__ == "__main__":
    main()
