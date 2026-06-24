#!/usr/bin/env python3
"""Rank artifacts by ontological proximity to a given set (the fold-studio table of contents).

Given a roster of artifact ids, score every other artifact by its MAX cosine similarity to any roster
member (the atlas vectors are L2-normalized, so dot == cosine) and return the nearest N not already in
the roster — each tagged with its family (source) and a derived role/register so it can drop straight
into the editor. The "look for artifacts from other maps" search behind /fold-studio.

Run: python tools/artifact_neighbors.py --ids '["origin","grid_lines"]' --topn 40
"""
import argparse
import json
import os
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from build_corridor import load_sizes, LARGE_M           # noqa: E402
from build_map_strings import load_edges, CRITICAL_EDGES  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ids", required=True, help="JSON list of roster artifact ids")
    ap.add_argument("--topn", type=int, default=40)
    args = ap.parse_args()

    roster = set(json.loads(args.ids))
    npz = np.load(os.path.join(ROOT, "doc", "atlas", "artifact_embeddings.npz"), allow_pickle=True)
    ids = [str(a) for a in npz["ids"]]
    fam = [str(f) for f in npz["families"]]
    V = npz["vectors"]
    idx = {a: i for i, a in enumerate(ids)}

    ri = [idx[r] for r in roster if r in idx]
    if not ri:
        print(json.dumps([]))
        return
    score = (V @ V[ri].T).max(axis=1)        # nearest distance to ANY roster member
    order = np.argsort(-score)

    sizes, edges = load_sizes(), load_edges()
    out = []
    for i in order:
        aid = ids[i]
        if aid in roster:
            continue
        sp = sizes.get(aid)
        large = sp is not None and max(sp[0], sp[1]) > LARGE_M
        out.append({
            "id": aid,
            "sim": round(float(score[i]), 3),
            "source": fam[i],
            "role": "grid" if large else "wall",
            "register": "critical" if edges.get(aid) in CRITICAL_EDGES else "formal",
        })
        if len(out) >= args.topn:
            break
    print(json.dumps(out))


if __name__ == "__main__":
    main()
