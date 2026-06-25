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


def _map_artifact_ids(map_name):
    """Artifact lookup-names actually placed in a map's interactables layer, in Z (row) order."""
    p = os.path.join(ROOT, "commons", "maps", map_name, "map_data.json")
    if not os.path.exists(p):
        return []
    try:
        m = json.load(open(p, encoding="utf-8"))
    except Exception:
        return []
    out, seen = [], set()
    for row in m.get("layers", {}).get("interactables", []):
        for c in (row if isinstance(row, list) else str(row).split(",")):
            c = str(c).strip()
            if c and not c.startswith("#"):
                base = c.split(":")[0].split("#")[0].strip()   # lookup:rot:y / lookup#config -> lookup
                if base and base not in seen:
                    seen.add(base)
                    out.append(base)
    return out


def roster_from_map_groups(seq):
    """Ordered [(map_name, [artifact names])] per map. The roster is what's ACTUALLY placed in the map's
    interactables (Z-order, the truth), supplemented by any artifact_groups names not on the grid yet."""
    d, node = _seq_node(seq)
    if not node:
        return []
    ag = node.get("artifact_groups") or (d.get("artifact_groups") if isinstance(d, dict) else None) or []
    out = []
    for g in ag:
        if isinstance(g, dict) and g.get("map"):
            mp = g["map"]
            names, seen = [], set()
            for a in _map_artifact_ids(mp):                    # actually placed, in walk order
                if a not in seen and a not in INFRA:
                    seen.add(a)
                    names.append(a)
            for a in g.get("artifacts", []):                   # artifact_groups extras (intent, not yet placed)
                base = str(a).split(":")[0].split("#")[0].strip()
                if base and base not in seen and base not in INFRA:
                    seen.add(base)
                    names.append(base)
            out.append((mp, names))
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


def corridor_map(name, title, desc, ordered, next_map, spans, thread=False):
    bands = _bands(ordered, spans)

    def fp(n):
        return spans.get(n) or (1.0, 1.0)
    # Width = wide enough to set the widest large BESIDE a clear central walkway (footprint + pathfinding).
    max_lw = max([int(fp(items[0])[0]) for k, items in bands if k == "large"] + [0])
    if thread:
        cols = min(max(max_lw, 13) + 3, 30)   # thin ribbon — larges run inline, no side clearance needed
    else:
        cols = min(max(COLS, max_lw + 10), 30)
    center = cols // 2

    z, placements, side, foots = 2, [], -1, []
    for kind, items in bands:
        if kind == "cluster":
            depth, x = 7, center
            hw = min(len(items) + 1, center - 2)             # the bay's floor half-width
            token = ("curation_station#artifacts:" + ",".join(items)
                     + "#layout:row#with_wall:false#with_pillars:false#with_barrier:false")
        else:
            w, d = fp(items[0])
            depth = min(max(int(d) + 3, 5), 12)   # footprint-sized Z band, clamped for swarms/effects
            hw = int(w) // 2 + 1
            if thread:
                x = center                        # inline on the spine — no side offset (removed for now)
            else:
                # offset to alternating sides, keeping the centre walkway clear
                x = max(2, center - 3 - hw) if side < 0 else min(cols - 3, center + 3 + hw)
                side = -side
            token = items[0]
        za = z + depth // 2
        placements.append((za, x, token))
        foots.append((za, x, hw, z, z + depth))
        z += depth + 1
    rows_total = max(z + 2, 8)
    tele_z = rows_total - 2

    if thread:
        # THE GRID AS A CONSEQUENCE: floor exists ONLY where the walk threads, where a bay sits, and
        # under a large's footprint — void everywhere else (string of pearls). pathfind + wall-hangar +
        # artifact-footprint YIELD the grid, instead of placing things on a pre-made open floor.
        struct = [["0"] * cols for _ in range(rows_total)]
        for xx in range(1, center + 1):                       # spawn(0,0) corner -> spine connector
            struct[1][xx] = "1"
        for zz in range(1, tele_z):                           # central walk spine (3 wide)
            for xx in range(center - 1, center + 2):
                struct[zz][xx] = "1"
        for (za, x, hw, z0, z1) in foots:                     # each bay / large footprint + its spur
            for zz in range(max(1, z0), min(rows_total - 1, z1 + 1)):
                for xx in range(max(1, x - hw), min(cols - 1, x + hw + 1)):
                    struct[zz][xx] = "1"
            lo, hi = sorted((center, x))
            for xx in range(lo, hi + 1):
                struct[za][xx] = "1"
    else:
        struct = [["1"] * cols for _ in range(rows_total)]
    for x in range(cols):
        struct[0][x] = "2"; struct[rows_total - 1][x] = "2"
    for zz in range(rows_total):
        struct[zz][0] = "2"; struct[zz][cols - 1] = "2"
    util = [["" for _ in range(cols)] for _ in range(rows_total)]
    inter = [["" for _ in range(cols)] for _ in range(rows_total)]
    util[1][1 if thread else center] = "s"
    struct[tele_z][center] = "0"
    util[tele_z][center] = "t:" + next_map
    for za, x, token in placements:
        inter[za][x] = token
    n_cl = sum(1 for k, _ in bands if k == "cluster")
    n_lg = sum(1 for k, _ in bands if k == "large")
    return {
        "map_info": {
            "name": name, "lookup_name": name, "title": title, "description": desc,
            "dimensions": {"width": cols, "depth": rows_total, "max_height": 2},
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


# UNFOLD (layered): read the edited string of pearls (doc/map_strings/<Map>.json) and lay it out
# honoring the flags — `role` decides cluster(wall) vs landmark(grid); `register`=critical puts the
# artifact on a parallel LEFT track (the poetics/critique layer made spatial). Formal teaching runs
# down the centre (clusters) + right (landmarks); the player walks the centre between the two voices.
def corridor_layered(name, title, desc, pearls, next_map, spans):
    cols, center, left, right = 30, 15, 8, 22

    def role_of(p):
        r = p.get("role")
        if r in ("wall", "grid"):
            return r
        sp = spans.get(p["id"])
        return "grid" if (sp is not None and max(sp[0], sp[1]) > LARGE_M) else "wall"

    # bands honour role; consecutive wall pearls of the SAME register cluster together (formal clusters
    # and critical clusters never mix).
    bands, buf, buf_reg = [], [], None
    for p in pearls:
        reg = "critical" if p.get("register") == "critical" else "formal"
        if role_of(p) == "grid":
            if buf:
                bands.append(("cluster", buf_reg, buf)); buf = []
            bands.append(("large", reg, [p["id"]]))
        else:
            if buf and buf_reg != reg:
                bands.append(("cluster", buf_reg, buf)); buf = []
            buf.append(p["id"]); buf_reg = reg
            if len(buf) == 5:
                bands.append(("cluster", buf_reg, buf)); buf = []
    if buf:
        bands.append(("cluster", buf_reg, buf))

    z, placements = 2, []
    for kind, reg, items in bands:
        crit = reg == "critical"
        if kind == "cluster":
            depth = 7
            x = left if crit else center
            token = ("curation_station#artifacts:" + ",".join(items)
                     + "#layout:row#with_wall:false#with_pillars:false#with_barrier:false")
        else:
            sp = spans.get(items[0]) or (1.0, 1.0)
            depth = min(max(int(sp[1]) + 3, 5), 12)
            x = left if crit else right
            token = items[0]
        placements.append((z + depth // 2, x, token))
        z += depth + 1
    rows_total = max(z + 2, 8)

    struct = [["1"] * cols for _ in range(rows_total)]
    for x in range(cols):
        struct[0][x] = "2"; struct[rows_total - 1][x] = "2"
    for zz in range(rows_total):
        struct[zz][0] = "2"; struct[zz][cols - 1] = "2"
    util = [["" for _ in range(cols)] for _ in range(rows_total)]
    inter = [["" for _ in range(cols)] for _ in range(rows_total)]
    util[1][center] = "s"
    tele_z = rows_total - 2
    struct[tele_z][center] = "0"
    util[tele_z][center] = "t:" + next_map
    for za, x, token in placements:
        inter[za][x] = token

    n_cl = sum(1 for k, _, _ in bands if k == "cluster")
    n_lg = sum(1 for k, _, _ in bands if k == "large")
    n_crit = sum(1 for _, r, _ in bands if r == "critical")
    return {
        "map_info": {"name": name, "lookup_name": name, "title": title, "description": desc,
                     "dimensions": {"width": cols, "depth": rows_total, "max_height": 2}},
        "subtitles": {}, "lighting": {},
        "settings": {"cube_size": 1, "gutter": 0, "show_grid": True, "enable_physics": True,
                     "auto_reveal_on_entry": True, "initial_tile_visibility": "visible", "disable_biome": True,
                     "background": {"type": "sky", "color": [0.10, 0.11, 0.16]}},
        "layers": {"structure": struct, "utilities": util, "interactables": inter},
    }, (n_cl, n_lg, n_crit, rows_total)


def run_from_string(map_name, spans):
    p = os.path.join(ROOT, "doc", "map_strings", map_name + ".json")
    if not os.path.exists(p):
        print("no string for", map_name, "(run build_map_strings.py first)")
        return
    d = json.load(open(p, encoding="utf-8"))
    pearls = [pl for pl in d.get("pearls", []) if pl.get("include", True)]
    if not pearls:
        print("no kept pearls in", map_name)
        return
    name = "Corridor_" + map_name
    m, (nc, nl, ncrit, rows) = corridor_layered(
        name, "%s — unfolded (role + critical layer)" % map_name, "placeholder", pearls, name, spans)
    m["map_info"]["description"] = ("Unfolded from doc/map_strings/%s.json honoring role + register: "
                                    "%d clusters + %d landmarks; %d critical bands on the left track."
                                    % (map_name, nc, nl, ncrit))
    _write(name, m)
    print("unfolded %s: %d pearls -> %d clusters + %d landmarks, %d critical bands (%d-deep, layered)"
          % (name, len(pearls), nc, nl, ncrit, rows))


def run_single_map(map_name, mode, idx, V, spans):
    """CONSUME one arbitrary map: take its placed artifacts, order them ontologically (atlas), and
    reassemble as a wall-hangar corridor — smalls into curation_station bays, larges solo on the grid,
    spawn at the (0,0) origin corner, exit teleporter at the far end. Emits Corridor_<MapName>."""
    arts = [a for a in _map_artifact_ids(map_name) if a not in INFRA]
    if not arts:
        print("no artifacts placed in", map_name)
        return None
    ordered = nn_order(arts, idx, V) if mode == "replace" else arts
    name = "Corridor_%s" % map_name
    m, (nc, nl, rows) = corridor_map(
        name, "%s — wall-hangar corridor (%s)" % (map_name, mode), "placeholder", ordered, name, spans,
        thread=True)   # the grid is CARVED from the walk + bay/large footprints; void elsewhere
    n_emb = sum(1 for a in arts if a in idx)
    m["map_info"]["description"] = (
        "Wall-hangar corridor consuming %s (%s): %d artifacts (%d atlas-ordered) -> %d curation bays + "
        "%d large-on-grid; walk spawn(0,0) -> all -> exit." % (map_name, mode, len(arts), n_emb, nc, nl))
    _write(name, m)
    print("consumed %s: %d arts (%d embedded) -> %d bays + %d large-on-grid (%d-deep, %s) -> %s"
          % (map_name, len(arts), n_emb, nc, nl, rows, mode, name))
    return name


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seq")
    ap.add_argument("--map", help="consume ONE map's placed artifacts into a wall-hangar corridor (Corridor_<Name>)")
    ap.add_argument("--from-string", dest="from_string", help="unfold one map from its edited doc/map_strings/<Map>.json")
    ap.add_argument("--per-map", action="store_true", help="recreate each map (THE spine target)")
    ap.add_argument("--mode", choices=["blend", "replace"], default="blend")
    ap.add_argument("--per-concept", type=int, default=1)
    args = ap.parse_args()
    idx, V = load_embeddings()
    spans = load_sizes()
    if args.from_string:
        run_from_string(args.from_string, spans)
        return
    if args.map:
        run_single_map(args.map, args.mode, idx, V, spans)
        return
    if not args.seq:
        ap.error("pass --map <Name>, --from-string <Map>, or --seq <id> [--per-map]")
    if args.per_map:
        run_per_map(args.seq, args.mode, idx, V, spans)
    else:
        run_essence(args.seq, args.mode, args.per_concept, idx, V, spans)


if __name__ == "__main__":
    main()
