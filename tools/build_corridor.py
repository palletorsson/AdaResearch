#!/usr/bin/env python3
"""Build ONTOLOGICAL CORRIDOR maps — reassemble a sequence's maps as processions down the Z (walk)
axis. Small artifacts grouped into curation clusters (open plinth rows); large (>3 m, map-scale) ones
placed solo on the grid by footprint. Builds ON the existing ontology work (concept maps + atlas
embeddings); recomputes nothing.

Two units:
  --seq <id> --per-map   : recreate/update EACH map in the sequence (roster = that map's artifact_groups),
                           emitting chained siblings Corridor_<MapName>. THE SPINE TARGET.
  --seq <id>             : one whole-sequence 'essence' corridor (roster = concept-map best picks).

Two modes:
  --mode blend   : keep the curriculum order (artifact_groups / concept order), add clustering + the
                   size split. Order needs NO embeddings, so it's robust. Default — for curated maps.
  --mode replace : pure ontological nearest-neighbour Z-order (needs atlas embeddings). For generic maps.

Always emits SIBLING maps (Corridor_*) — never overwrites an authored map.
Run: python tools/build_corridor.py --seq primitives --per-map --mode blend
"""
import argparse
import glob
import json
import os
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import compact_map_json                      # noqa: E402
from build_curation_bays import load_embeddings, load_card_spans, INFRA  # noqa: E402


def load_sizes():
    """name -> (w, d) footprint in cells. Prefers the real measured AABB (registry
    measurements.grid_cells, ~67% coverage) over the atlas card span (~22% measured)."""
    sizes = dict(load_card_spans())   # (w, d) from atlas cards — fallback
    for f in glob.glob(os.path.join(ROOT, "commons", "artifacts", "registry", "*.json")):
        try:
            d = json.load(open(f, encoding="utf-8"))
        except Exception:
            continue
        for k, v in (d.get("artifacts", {}) or {}).items():
            if isinstance(v, dict):
                gc = (v.get("measurements", {}) or {}).get("grid_cells")
                if isinstance(gc, list) and len(gc) >= 2:
                    sizes[v.get("lookup_name", k)] = (float(gc[0]), float(gc[1]))   # measured wins
    return sizes

LARGE_M = 3.0
COLS = 24
CENTER = COLS // 2
ALIASES = {
    "cellularautomata": "ca", "fractals": "fractal", "lsystems": "lsystem", "softbodies": "softbody",
    "proceduralgeneration": "procgen", "foundationscrisis": "foundations",
    "qfeplaboratory": "qfep", "postfoundationscrisis": "postcrisis", "forces": "vector_forces",
}


def _seq_node(seq):
    p = os.path.join(ROOT, "commons", "maps", "sequences", seq + ".json")
    if not os.path.exists(p):
        return None, None
    d = json.load(open(p, encoding="utf-8"))
    node = d.get("sequences", {}).get(seq, d) if isinstance(d, dict) else {}
    if not (isinstance(node, dict) and node.get("artifact_groups")):
        node = d if isinstance(d, dict) else {}
    return d, node


def roster_from_map_groups(seq):
    """Ordered [(map_name, [artifact names])] — one entry per map, in sequence order."""
    d, node = _seq_node(seq)
    if not node:
        return []
    ag = node.get("artifact_groups") or (d.get("artifact_groups") if isinstance(d, dict) else None) or []
    out = []
    for g in ag:
        if isinstance(g, dict) and g.get("map"):
            names, seen = [], set()
            for a in g.get("artifacts", []):
                if a and a not in seen and a not in INFRA:
                    seen.add(a)
                    names.append(a)
            out.append((g["map"], names))
    return out


def roster_from_concept_map(seq, per_concept):
    for cand in (ALIASES.get(seq, seq), seq):
        p = os.path.join(ROOT, "doc", "%s_concept_map.json" % cand)
        if os.path.exists(p):
            d = json.load(open(p, encoding="utf-8"))
            cm = d.get("concept_meta", {})
            out, seen = [], set()
            for c in d.get("concepts", []):
                meta = cm.get(c, {})
                picks = ([meta["best"]] if meta.get("best") else [])
                for tier in ("small", "medium", "large", "applied"):
                    picks += (meta.get("tiers", {}) or {}).get(tier, [])
                for n in picks[:per_concept]:
                    if n not in seen and n not in INFRA:
                        seen.add(n)
                        out.append(n)
            return out
    return []


def nn_order(names, idx, V):
    """Nearest-neighbour TSP over cosine distance for the embedded names; non-embedded appended."""
    emb = [n for n in names if n in idx]
    if len(emb) < 2:
        return names
    rows = [idx[n] for n in emb]
    sub = V[rows]
    D = 1.0 - sub @ sub.T
    np.fill_diagonal(D, 1e9)
    order, used = [0], {0}
    for _ in range(len(emb) - 1):
        last = order[-1]
        nxt = min((j for j in range(len(emb)) if j not in used), key=lambda j: D[last][j])
        order.append(nxt)
        used.add(nxt)
    return [emb[i] for i in order] + [n for n in names if n not in idx]


def _bands(ordered, spans):
    """[(kind, items)] — consecutive smalls chunk into <=5 clusters; each large is its own band."""
    def is_large(n):
        sp = spans.get(n)
        return sp is not None and max(sp[0], sp[1]) > LARGE_M
    bands, buf = [], []
    for n in ordered:
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
    return bands


def corridor_map(name, title, desc, ordered, next_map, spans):
    bands = _bands(ordered, spans)
    z, placements = 2, []
    for kind, items in bands:
        if kind == "cluster":
            depth = 7
            token = ("curation_station#artifacts:" + ",".join(items)
                     + "#layout:row#with_wall:false#with_pillars:false#with_barrier:false")
        else:
            sp = spans.get(items[0]) or (1.0, 1.0)
            depth = min(max(int(sp[1]) + 3, 5), 12)   # footprint-sized Z band, clamped for swarms/effects
            token = items[0]
        placements.append((z + depth // 2, token))
        z += depth + 1
    rows_total = max(z + 2, 8)
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
    util[tele_z][CENTER] = "t:" + next_map
    for za, token in placements:
        inter[za][CENTER] = token
    n_cl = sum(1 for k, _ in bands if k == "cluster")
    n_lg = sum(1 for k, _ in bands if k == "large")
    return {
        "map_info": {
            "name": name, "lookup_name": name, "title": title, "description": desc,
            "dimensions": {"width": COLS, "depth": rows_total, "max_height": 2},
        },
        "subtitles": {}, "lighting": {},
        "settings": {
            "cube_size": 1, "gutter": 0, "show_grid": True, "enable_physics": True,
            "auto_reveal_on_entry": True, "initial_tile_visibility": "visible", "disable_biome": True,
            "background": {"type": "sky", "color": [0.10, 0.11, 0.16]},
        },
        "layers": {"structure": struct, "utilities": util, "interactables": inter},
    }, (n_cl, n_lg, rows_total)


def _write(name, mapdict):
    out = os.path.join(ROOT, "commons", "maps", name)
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, "map_data.json"), "w", encoding="utf-8") as f:
        f.write(compact_map_json._ser(mapdict, 0))


def run_per_map(seq, mode, idx, V, spans):
    groups = roster_from_map_groups(seq)
    if not groups:
        print("no artifact_groups for", seq)
        return
    names = ["Corridor_%s" % m for m, _ in groups]
    for i, (mp, arts) in enumerate(groups):
        ordered = nn_order(arts, idx, V) if mode == "replace" else arts  # blend keeps curriculum order
        nxt = names[(i + 1) % len(names)]
        m, (nc, nl, rows) = corridor_map(
            names[i], "%s — corridor (%s)" % (mp, mode),
            "Ontological corridor of %s (%s): %d clusters + %d large-on-grid." % (mp, mode, nc if False else 0, 0),
            ordered, nxt, spans)
        # fill real counts into the description
        m["map_info"]["description"] = ("Ontological corridor regenerating %s (%s mode): "
                                        "%d small-clusters + %d large-on-grid." % (mp, mode, nc, nl))
        _write(names[i], m)
        print("  %-32s -> %2d arts -> %d clusters + %d large (%d-deep)" % (names[i], len(arts), nc, nl, rows))
    print("%d map-corridors for %s (mode=%s)" % (len(groups), seq, mode))


def run_essence(seq, mode, per_concept, idx, V, spans):
    roster = [n for n in roster_from_concept_map(seq, per_concept) if n in idx]
    if not roster:
        print("no embedded concept-map roster for", seq)
        return
    ordered = nn_order(roster, idx, V) if mode == "replace" else roster
    name = "Corridor_%s" % seq
    m, (nc, nl, rows) = corridor_map(
        name, "%s — ontological corridor (%s)" % (seq, mode),
        "Whole-sequence essence corridor.", ordered, name, spans)
    m["map_info"]["description"] = ("Ontological essence corridor of %s (%s): %d clusters + %d large-on-grid."
                                    % (seq, mode, nc, nl))
    _write(name, m)
    print("wrote %s: %d arts -> %d clusters + %d large (%d-deep, %s)" % (name, len(roster), nc, nl, rows, mode))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seq", required=True)
    ap.add_argument("--per-map", action="store_true", help="recreate each map (THE spine target)")
    ap.add_argument("--mode", choices=["blend", "replace"], default="blend")
    ap.add_argument("--per-concept", type=int, default=1)
    args = ap.parse_args()
    idx, V = load_embeddings()
    spans = load_sizes()
    if args.per_map:
        run_per_map(args.seq, args.mode, idx, V, spans)
    else:
        run_essence(args.seq, args.mode, args.per_concept, idx, V, spans)


if __name__ == "__main__":
    main()
