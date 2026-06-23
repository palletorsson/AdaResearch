#!/usr/bin/env python3
"""Generate Curation_Bay maps for sequences, grouping each sequence's artifacts into bays of <=5
by ONTOLOGICAL DISTANCE (cosine on the atlas TF-IDF embeddings).

Each bay = a standard grid map_data.json with ONE `curation_station` token (the proven pattern from
build_curation_bay_demo.py). The composer measures + assembles the whole bay at _ready. Bays within a
sequence chain via teleporter into a walking tour, ordered by curriculum (artifact_groups map order);
members within a bay are grouped by ontological proximity (so near things share a stage).

  Distance source : doc/atlas/artifact_embeddings.npz  (cosine on 128-D, L2-normalized => dot==cosine)
  Sequence source : commons/maps/sequences/<seq>.json -> sequences.<seq>.artifact_groups[].artifacts
  Footprint filter: registry spatial_needs.footprint_cells (bay-able iff None or <=16; the composer
                    caps each item at 4x4, so lab_room/curation_station/weather_vector_field bow out)

Run:
  python tools/build_curation_bays.py --seq fractals     # one sequence (proof)
  python tools/build_curation_bays.py --spine            # the 22 spine sequences
  python tools/build_curation_bays.py --all              # every sequence with artifact_groups
Then: python tools/compact_map_json.py --all   (maps are already written compact via _ser)
"""
import argparse
import glob
import json
import math
import os
import shutil
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import compact_map_json  # noqa: E402  (for the canonical compact-rows serializer)

NPZ = os.path.join(ROOT, "doc", "atlas", "artifact_embeddings.npz")

# Cross-cutting UI / decor that should never occupy a bay stage.
INFRA = {
    "tt", "code_display", "science_screen", "ca_screen", "clipboard", "vr_map_loader_kiosk",
    "monitorsystem", "catalyst_target", "catalyst_pedestal", "spawn_marker", "fps_counter",
    "menu_panel", "dark_sphere",
}

ROWS, COLS = 18, 38
ANCHOR, SPAWN, TELE = (7, 19), (14, 19), (16, 19)

# Artifacts wider/deeper than this (metres ~= cells) sprawl past a display plinth (the composer caps a
# plinth at 4x4). Room-scale things — fractal trees at d=13, menger at 9x10 — bow out of bays.
MAX_SPAN = 5

# Non-content sequence files (scratch / scaffolding) — kept out of the bay collection.
EXCLUDE_SEQS = {"testmaps", "unused", "devexamples"}

SPINE = [
    "primitives", "transformation", "array_tutorial", "color", "change", "forces", "wavefunctions",
    "randomness", "noise", "cellularautomata", "fractals", "lsystems", "proceduralgeneration",
    "softbodies", "isosurfaces", "boolean_surfaces", "swarmintelligence", "machinelearning",
    "graphtheory", "foundationscrisis", "qfeplaboratory", "postfoundationscrisis",
]


def load_embeddings():
    z = np.load(NPZ, allow_pickle=True)
    ids = list(z["ids"])
    idx = {n: i for i, n in enumerate(ids)}
    return idx, z["vectors"]


def load_footprints():
    fp = {}
    for f in glob.glob(os.path.join(ROOT, "commons", "artifacts", "registry", "*.json")):
        try:
            d = json.load(open(f, encoding="utf-8"))
        except Exception:
            continue
        arts = d.get("artifacts", {})
        if not isinstance(arts, dict):
            continue
        for name, e in arts.items():
            if isinstance(e, dict):
                sn = e.get("spatial_needs", {})
                if isinstance(sn, dict) and "footprint_cells" in sn:
                    v = sn["footprint_cells"]
                    if isinstance(v, list):
                        v = max(v) if v else 1
                    fp[name] = v
    return fp


def load_card_spans():
    """lookup_name -> (width_m, depth_m) from the atlas cards' [w,h,d] footprint."""
    spans = {}
    cards = json.load(open(os.path.join(ROOT, "doc", "atlas", "artifact_cards.json"), encoding="utf-8"))
    for c in cards:
        fpv = c.get("footprint")
        if isinstance(fpv, list) and len(fpv) == 3:
            spans[c["lookup_name"]] = (float(fpv[0]), float(fpv[2]))
    return spans


def seq_artifacts(seq):
    """Ordered unique artifact names with their first-appearance map index (for walk order)."""
    path = os.path.join(ROOT, "commons", "maps", "sequences", seq + ".json")
    if not os.path.exists(path):
        return []
    try:
        d = json.load(open(path, encoding="utf-8"))
    except Exception:
        return []
    node = d if isinstance(d, dict) else {}
    if isinstance(d, dict):
        seqs = d.get("sequences")
        if isinstance(seqs, dict) and isinstance(seqs.get(seq), dict):
            node = seqs[seq]
    ag = node.get("artifact_groups") or (d.get("artifact_groups") if isinstance(d, dict) else None) or []
    order = {}
    for gi, g in enumerate(ag):
        if not isinstance(g, dict):
            continue
        for a in g.get("artifacts", []):
            if a not in order:
                order[a] = gi
    return list(order.items())


def _cluster_le5(idxs, V):
    """Recursively partition global row-indices into clusters each <=5 by cosine distance."""
    from sklearn.cluster import AgglomerativeClustering
    k = len(idxs)
    if k <= 5:
        return [list(idxs)]
    nc = math.ceil(k / 5)
    labels = AgglomerativeClustering(
        n_clusters=nc, metric="cosine", linkage="average"
    ).fit_predict(V[idxs])
    out = []
    for c in sorted(set(labels)):
        grp = [idxs[i] for i in range(k) if labels[i] == c]
        if len(grp) <= 5:
            out.append(grp)
        else:
            out.extend(_cluster_le5(grp, V))
    return out


def make_bays(seq, idx, V, fp, spans):
    """Return a list of bays; each bay is an ordered list of <=5 artifact lookup-names."""
    kept = []
    for name, mi in seq_artifacts(seq):
        if name in INFRA:
            continue
        f = fp.get(name)
        if f is not None and f > 16:   # architectural — can't ride the 4x4 composer cap
            continue
        sp = spans.get(name)
        if sp is not None and (sp[0] > MAX_SPAN or sp[1] > MAX_SPAN):   # sprawls past a display plinth
            continue
        kept.append((name, mi))
    if not kept:
        return []
    present = [(n, mi) for n, mi in kept if n in idx]
    missing = [(n, mi) for n, mi in kept if n not in idx]

    bays = []
    if present:
        rows = [idx[n] for n, _ in present]
        row2 = {idx[n]: (n, mi) for n, mi in present}
        for cl in _cluster_le5(rows, V):
            bays.append([row2[r] for r in cl])

    # Missing-from-embeddings names (rare, min_df=2 dropouts): drop into the smallest bay.
    for nm in missing:
        if not bays or all(len(b) >= 5 for b in bays):
            bays.append([])
        min(bays, key=len).append(nm)

    # Orphan merge: fold singleton bays into the nearest sub-cap bay by centroid cosine.
    def centroid(bay):
        rs = [idx[n] for n, _ in bay if n in idx]
        return V[rs].mean(axis=0) if rs else None

    changed = True
    while changed and len(bays) > 1:
        changed = False
        bays.sort(key=len)
        if len(bays[0]) == 1:
            orphan = bays[0]
            oc = centroid(orphan)
            best, best_d = None, 2.0
            for b in bays[1:]:
                if len(b) >= 5:
                    continue
                bc = centroid(b)
                if oc is None or bc is None:
                    continue
                d = 1.0 - float(np.dot(oc, bc) / (np.linalg.norm(oc) * np.linalg.norm(bc) + 1e-9))
                if d < best_d:
                    best_d, best = d, b
            if best is not None:
                best.extend(orphan)
                bays.remove(orphan)
                changed = True

    bays.sort(key=lambda b: sum(mi for _, mi in b) / len(b))          # walk order
    for b in bays:
        b.sort(key=lambda nm: (fp.get(nm[0]) or 1))                   # small teaching pieces first
    return [[n for n, _ in b] for b in bays]


def build_map(name, title, arts, nxt):
    struct = [["1"] * COLS for _ in range(ROWS)]
    for x in range(COLS):
        struct[0][x] = "2"
        struct[ROWS - 1][x] = "2"
    for z in range(ROWS):
        struct[z][0] = "2"
        struct[z][COLS - 1] = "2"
    struct[TELE[0]][TELE[1]] = "0"
    util = [["" for _ in range(COLS)] for _ in range(ROWS)]
    inter = [["" for _ in range(COLS)] for _ in range(ROWS)]
    util[SPAWN[0]][SPAWN[1]] = "s"
    util[TELE[0]][TELE[1]] = "t:" + nxt
    token = ("curation_station#artifacts:" + ",".join(arts)
             + "#with_wall:true#with_pillars:true#with_barrier:true")
    inter[ANCHOR[0]][ANCHOR[1]] = token
    return {
        "map_info": {
            "name": name, "lookup_name": name, "title": title,
            "description": "Ontological-distance curation bay: " + ", ".join(arts)
                           + ". One curation_station token in a standard grid map_data.json.",
            "dimensions": {"width": COLS, "depth": ROWS, "max_height": 2},
        },
        "subtitles": {}, "lighting": {},
        "settings": {
            "cube_size": 1, "gutter": 0, "show_grid": True, "enable_physics": True,
            "auto_reveal_on_entry": True, "initial_tile_visibility": "visible",
            "disable_biome": True,
            "background": {"type": "sky", "color": [0.10, 0.11, 0.16]},
        },
        "layers": {"structure": struct, "utilities": util, "interactables": inter},
    }


def emit_sequence(seq, idx, V, fp, spans):
    # Clear this sequence's existing bays first — counts change between runs (filters, re-clustering),
    # so stale Curation_Bay_<seq>_N directories must not linger.
    for old in glob.glob(os.path.join(ROOT, "commons", "maps", "Curation_Bay_%s_*" % seq)):
        shutil.rmtree(old, ignore_errors=True)
    bays = make_bays(seq, idx, V, fp, spans)
    if not bays:
        return 0
    names = ["Curation_Bay_%s_%d" % (seq, i) for i in range(len(bays))]
    for i, arts in enumerate(bays):
        nxt = names[(i + 1) % len(bays)]            # chain into a loop tour
        title = "%s — Bay %d of %d" % (seq, i + 1, len(bays))
        m = build_map(names[i], title, arts, nxt)
        out = os.path.join(ROOT, "commons", "maps", names[i])
        os.makedirs(out, exist_ok=True)
        with open(os.path.join(out, "map_data.json"), "w", encoding="utf-8") as fh:
            fh.write(compact_map_json._ser(m, 0))
    print("  %-22s -> %2d bays (%s)" % (seq, len(bays), ", ".join("%d" % len(b) for b in bays)))
    return len(bays)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seq")
    ap.add_argument("--spine", action="store_true")
    ap.add_argument("--all", action="store_true")
    args = ap.parse_args()

    if args.seq:
        seqs = [args.seq]
    elif args.spine:
        seqs = SPINE
    elif args.all:
        seqs = sorted(os.path.splitext(os.path.basename(p))[0]
                      for p in glob.glob(os.path.join(ROOT, "commons", "maps", "sequences", "*.json"))
                      if not p.endswith(".beats.json"))
        seqs = [s for s in seqs if s not in EXCLUDE_SEQS]
    else:
        ap.error("pass --seq <id>, --spine, or --all")

    idx, V = load_embeddings()
    fp = load_footprints()
    spans = load_card_spans()
    total = 0
    for s in seqs:
        total += emit_sequence(s, idx, V, fp, spans)
    print("\n%d bays written across %d sequences." % (total, len(seqs)))


if __name__ == "__main__":
    main()
