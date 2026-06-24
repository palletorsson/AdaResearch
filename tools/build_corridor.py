#!/usr/bin/env python3
"""Build an ONTOLOGICAL CORRIDOR map for a sequence — a procession down the Z (walk) axis assembled
from the sequence's curated concept-map artifacts:

  - roster = the curated `best` pick per concept (the /<seq>-map ladder), atlas-embedded, deduped
  - SIZE SPLIT at 3 m (atlas card [w,h,d]): small -> grouped into curation clusters (open plinth rows);
    large (>3 m, map-scale) -> placed solo on the grid by footprint (pathfinding refinement: TODO)
  - Z-ORDER:
      --mode replace : pure ontological nearest-neighbour order (for generic maps to swap)
      --mode blend   : curriculum (concept) order primary, ontology within (for curated maps to enrich)
  - emits a SIBLING map Corridor_<seq>  (never overwrites an authored map)

Reuses the atlas embeddings + the curation clustering + the compact serializer — recomputes nothing.

Run: python tools/build_corridor.py --seq randomness --mode replace
"""
import argparse
import json
import os
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import compact_map_json                      # noqa: E402
from build_curation_bays import load_embeddings, load_card_spans, INFRA  # noqa: E402

LARGE_M = 3.0
COLS = 24
CENTER = COLS // 2

# rich domain-named concept-map docs that alias a spine sequence id
ALIASES = {
    "cellularautomata": "ca", "fractals": "fractal", "lsystems": "lsystem", "softbodies": "softbody",
    "proceduralgeneration": "procgen", "foundationscrisis": "foundations",
    "qfeplaboratory": "qfep", "postfoundationscrisis": "postcrisis", "forces": "vector_forces",
}


def roster_from_concept_map(seq, per_concept):
    """[(name, concept)] — the curated best (+ optional tier) picks, in concept (curriculum) order."""
    for cand in (ALIASES.get(seq, seq), seq):
        p = os.path.join(ROOT, "doc", "%s_concept_map.json" % cand)
        if os.path.exists(p):
            d = json.load(open(p, encoding="utf-8"))
            cm = d.get("concept_meta", {})
            out, seen = [], set()
            for c in d.get("concepts", []):
                meta = cm.get(c, {})
                picks = []
                if meta.get("best"):
                    picks.append(meta["best"])
                for tier in ("small", "medium", "large", "applied"):
                    for a in (meta.get("tiers", {}) or {}).get(tier, []):
                        picks.append(a)
                for n in picks[:per_concept]:
                    if n not in seen:
                        seen.add(n)
                        out.append((n, c))
            return out
    return []


def nn_order(rows, V):
    """Nearest-neighbour TSP path over cosine distance -> order of indices into `rows`."""
    k = len(rows)
    if k <= 2:
        return list(range(k))
    sub = V[rows]
    D = 1.0 - sub @ sub.T               # vectors are L2-normalized -> dot == cosine
    np.fill_diagonal(D, 1e9)
    order, used = [0], {0}
    for _ in range(k - 1):
        last = order[-1]
        nxt = min((j for j in range(k) if j not in used), key=lambda j: D[last][j])
        order.append(nxt)
        used.add(nxt)
    return order


def build(seq, mode, per_concept):
    idx, V = load_embeddings()
    spans = load_card_spans()
    roster = [(n, c) for n, c in roster_from_concept_map(seq, per_concept)
              if n in idx and n not in INFRA]   # coverage gate + drop infra/decor (dark_sphere etc.)
    if not roster:
        print("no embedded concept-map roster for", seq)
        return None

    def is_large(n):
        sp = spans.get(n)
        return sp is not None and max(sp[0], sp[1]) > LARGE_M

    if mode == "replace":
        rows = [idx[n] for n, _ in roster]
        roster = [roster[i] for i in nn_order(rows, V)]
    # blend: roster already in concept (curriculum) order

    # Walk the order; consecutive smalls -> a cluster (<=5); each large -> its own solo band.
    bands, buf = [], []
    for n, _c in roster:
        if is_large(n):
            if buf:
                bands.append(("cluster", buf)); buf = []
            bands.append(("large", [n]))
        else:
            buf.append(n)
            if len(buf) == 5:
                bands.append(("cluster", buf)); buf = []
    if buf:
        bands.append(("cluster", buf))

    # Lay the bands down Z. Spawn at z0, teleporter at z_max.
    z = 2
    placements = []   # (z_anchor, depth, kind, token)
    for kind, items in bands:
        if kind == "cluster":
            depth = 7
            token = ("curation_station#artifacts:" + ",".join(items)
                     + "#layout:row#with_wall:false#with_pillars:false#with_barrier:false")
        else:
            sp = spans.get(items[0]) or (1.0, 1.0, 1.0)
            depth = max(int(sp[1]) + 3, 4)
            token = items[0]
        placements.append((z + depth // 2, depth, kind, token))
        z += depth + 1
    rows_total = z + 2

    struct = [["1"] * COLS for _ in range(rows_total)]
    for x in range(COLS):
        struct[0][x] = "2"; struct[rows_total - 1][x] = "2"
    for zz in range(rows_total):
        struct[zz][0] = "2"; struct[zz][COLS - 1] = "2"
    util = [["" for _ in range(COLS)] for _ in range(rows_total)]
    inter = [["" for _ in range(COLS)] for _ in range(rows_total)]
    util[1][CENTER] = "s"
    tele_z = rows_total - 2
    struct[tele_z][CENTER] = "0"
    util[tele_z][CENTER] = "t:Corridor_" + seq
    for za, _depth, _kind, token in placements:
        inter[za][CENTER] = token

    name = "Corridor_" + seq
    n_clusters = sum(1 for k, _ in bands if k == "cluster")
    n_large = sum(1 for k, _ in bands if k == "large")
    return name, {
        "map_info": {
            "name": name, "lookup_name": name, "title": "%s — ontological corridor (%s)" % (seq, mode),
            "description": "Ontological corridor: %s's curated concept artifacts ordered down Z by %s; "
                           "%d small-clusters + %d large on the grid." % (seq, mode, n_clusters, n_large),
            "dimensions": {"width": COLS, "depth": rows_total, "max_height": 2},
        },
        "subtitles": {}, "lighting": {},
        "settings": {
            "cube_size": 1, "gutter": 0, "show_grid": True, "enable_physics": True,
            "auto_reveal_on_entry": True, "initial_tile_visibility": "visible", "disable_biome": True,
            "background": {"type": "sky", "color": [0.10, 0.11, 0.16]},
        },
        "layers": {"structure": struct, "utilities": util, "interactables": inter},
    }, (len(roster), n_clusters, n_large, rows_total)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seq", required=True)
    ap.add_argument("--mode", choices=["replace", "blend"], default="replace")
    ap.add_argument("--per-concept", type=int, default=1)
    args = ap.parse_args()
    res = build(args.seq, args.mode, args.per_concept)
    if not res:
        return
    name, m, (k, nc, nl, rows) = res
    out = os.path.join(ROOT, "commons", "maps", name)
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, "map_data.json"), "w", encoding="utf-8") as f:
        f.write(compact_map_json._ser(m, 0))
    print("wrote %s: %d artifacts -> %d clusters + %d large, %d-deep corridor (%s)"
          % (name, k, nc, nl, rows, args.mode))


if __name__ == "__main__":
    main()
