#!/usr/bin/env python3
"""Pairwise cosine similarity among a SET of artifacts, from the atlas embeddings.

Unlike artifact_neighbors.py (which ranks the rest of the corpus against a
roster), this returns the similarities WITHIN the given set — the semantic
distances among the artifacts of one map. The /book harmony meter compares
these to the artifacts' spatial distances in the map layout: the gap between
"close in meaning" and "close in space" is the tension to harmonise toward the
QFEP/Ada ontology.

Usage:  python tools/artifact_pairs.py --ids '["point","line","plane"]'
Output: {"have":[...], "missing":[...], "pairs":[{"a","b","sim"}...]}
"""
from __future__ import annotations
import argparse, json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NPZ = ROOT / "doc" / "atlas" / "artifact_embeddings.npz"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--ids", required=True, help='JSON array of artifact lookup names')
    args = ap.parse_args()
    try:
        ids_in = [str(x) for x in json.loads(args.ids)]
    except Exception:
        print(json.dumps({"error": "bad --ids", "have": [], "missing": [], "pairs": []}))
        return

    if not NPZ.exists():
        print(json.dumps({"error": "no embeddings", "have": [], "missing": ids_in, "pairs": []}))
        return

    import numpy as np
    z = np.load(NPZ, allow_pickle=True)
    all_ids = [str(x) for x in z["ids"]]
    V = z["vectors"]  # L2-normalised, so dot == cosine
    idx = {x: i for i, x in enumerate(all_ids)}

    # de-dupe but keep order
    seen, ordered = set(), []
    for x in ids_in:
        if x not in seen:
            seen.add(x); ordered.append(x)
    have = [x for x in ordered if x in idx]
    missing = [x for x in ordered if x not in idx]

    pairs = []
    for i in range(len(have)):
        vi = V[idx[have[i]]]
        for j in range(i + 1, len(have)):
            sim = float(np.dot(vi, V[idx[have[j]]]))
            pairs.append({"a": have[i], "b": have[j], "sim": round(sim, 4)})

    print(json.dumps({"have": have, "missing": missing, "pairs": pairs}))


if __name__ == "__main__":
    main()
