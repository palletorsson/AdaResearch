#!/usr/bin/env python3
"""build_critical_tutorial.py — the NOC-style critical tutorial, 8 pages per sequence.

The book (/book, 195 chapters in artifact order) is the ENCYCLOPEDIA — every
path. This is the TUTORIAL — one path: per spine sequence, exactly eight pages
of text + Godot illustration, assembled from the project's own truth sources:

  p1 THE QUESTION   sequence truth + formula + description        (hero render)
  p2 THE PRIMITIVE  first pearl: @identity essence + truth        (its render)
  p3 THE WALK I     pearls 2..6 in consensus three-orders order   (renders)
  p4 THE WALK II    pearls 7..11                                  (renders)
  p5 THE TURN       the knobs: registry parameters of the walked artifacts
  p6 THE CRITICAL   qfep_term + qfep_connection + artifact truth-claims
  p7 IN THE WORLD   the sequence's maps (dims, artifacts) — walk it in VR
  p8 THE SEED       learning objectives as exercises + next sequence

Usage:
  python tools/build_critical_tutorial.py fractals      # one sequence
  python tools/build_critical_tutorial.py --all         # every spine sequence

Output: ada_encyclopedia/public/tutorial/<seq>.json (+ index.json)
"""
from __future__ import annotations

import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.environ.get("ADA_ENCYCLOPEDIA_PATH", "C:/Users/palle/Documents/GitHub/ada_encyclopedia")
SEQ_DIR = os.path.join(REPO, "commons", "maps", "sequences")
REG_DIR = os.path.join(REPO, "commons", "artifacts", "registry")
SPINE = os.path.join(REPO, "commons", "maps", "curriculum_spine.json")
THREE_ORDERS = os.path.join(ENC, "public", "three-orders.json")
MAP_OVERVIEW = os.path.join(ENC, "public", "map-overview.json")
CAPTURES = os.path.join(ENC, "public", "artifact-gallery", "captures")
OUT_DIR = os.path.join(ENC, "public", "tutorial")

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass


def load_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def load_registry() -> dict:
    out = {}
    for f in sorted(os.listdir(REG_DIR)):
        if not f.endswith(".json"):
            continue
        d = load_json(os.path.join(REG_DIR, f))
        if not isinstance(d, dict):
            continue
        arts = d.get("artifacts") if isinstance(d.get("artifacts"), dict) else d
        for k, v in arts.items():
            if isinstance(v, dict) and k not in out:
                out[k] = v
    return out


def capture_url(name: str) -> str | None:
    p = os.path.join(CAPTURES, name, "front.png")
    return f"/artifact-gallery/captures/{name}/front.png" if os.path.exists(p) else None


def gd_identity(scene_path: str) -> dict:
    """Pull the @identity lines (essence / truth) from the artifact's .gd."""
    if not scene_path.startswith("res://"):
        return {}
    rel = scene_path[len("res://"):]
    gd = os.path.join(REPO, rel.replace(".tscn", ".gd"))
    if not os.path.exists(gd):
        return {}
    out = {}
    try:
        with open(gd, encoding="utf-8", errors="ignore") as f:
            head = f.read(6000)
        for key in ("essence", "truth", "desire"):
            m = re.search(rf"^#\s*{key}:\s*(.+)$", head, re.M)
            if m:
                out[key] = m.group(1).strip()
    except Exception:
        pass
    return out


def seq_def(seq_id: str) -> dict | None:
    d = load_json(os.path.join(SEQ_DIR, f"{seq_id}.json"))
    if not isinstance(d, dict):
        return None
    s = d.get("sequences")
    if isinstance(s, list) and s:
        return s[0]
    if isinstance(s, dict) and s:
        return next(iter(s.values()))
    return d


def apply_authored(t: dict, seq_id: str) -> dict:
    """Merge the human writing pass over the assembled skeleton.

    doc/tutorial_authored/<seq>.json survives regeneration — the skeleton is
    rebuilt from data, then the authored prose lands on top. Schema: keys are
    page kinds ("question", "primitive", "walk1", "walk2", "turn", "critical",
    "world", "seed"), each a dict of field overrides; "artifacts" maps an
    artifact name -> authored prose (rendered instead of its raw essence).
    """
    a = load_json(os.path.join(REPO, "doc", "tutorial_authored", f"{seq_id}.json"))
    if not isinstance(a, dict):
        return t
    walk_i = 0
    for p in t["pages"]:
        key = p["kind"]
        if key == "walk":
            walk_i += 1
            key = f"walk{walk_i}"
        o = a.get(key)
        if not isinstance(o, dict):
            continue
        for fld in ("text", "lead", "coda", "formula", "qfep_connection", "truth", "title"):
            if fld in o:
                p[fld] = o[fld]
        if "objectives" in o and p["kind"] == "world":
            p["objectives"] = o["objectives"]
        if "exercises" in o and p["kind"] == "seed":
            p["exercises"] = o["exercises"]
        arts = o.get("artifacts")
        if isinstance(arts, dict):
            if isinstance(p.get("artifact"), dict) and p["artifact"].get("name") in arts:
                p["artifact"]["prose"] = arts[p["artifact"]["name"]]
            for aa in p.get("artifacts") or []:
                if aa.get("name") in arts:
                    aa["prose"] = arts[aa["name"]]
    if "truth" in a:
        t["truth"] = a["truth"]
    # The ledger: named critical threads (declared in doc/manuscript_frame.json)
    # this chapter advances — {motif_name: one sentence}. Rendered by the
    # manuscript builder as the chapter's closing ledger entries.
    if isinstance(a.get("motifs"), dict):
        t["motifs"] = a["motifs"]
    # Declared blanks (R-008): open slots that couple book and game — an
    # unoccupied position in the chapter renders as an empty plinth in the map.
    if isinstance(a.get("blanks"), list):
        t["blanks"] = a["blanks"]
    t["authored"] = True
    return t


def build(seq_id: str, registry: dict, orders: dict, overview: dict, spine: list) -> dict | None:
    sd = seq_def(seq_id)
    if not sd:
        print(f"  !! no sequence def: {seq_id}")
        return None

    # Pearls in consensus (ped+onto+crit)/3 order, capped, image-first.
    entry = orders.get(seq_id)
    pearls: list[str] = []
    if entry:
        ranked = sorted(
            range(len(entry["pearls"])),
            key=lambda i: (entry["ped"][i] + entry["onto"][i] + entry["crit"][i]) / 3.0,
        )
        pearls = [entry["pearls"][i] for i in ranked]
    # prefer pearls that have BOTH a registry entry and a capture
    def enrich(name: str) -> dict:
        reg = registry.get(name, {})
        ident = gd_identity(str(reg.get("scene", "")))
        return {
            "name": name,
            "title": name.replace("_", " "),
            "image": capture_url(name),
            "description": str(reg.get("description", "")),
            "essence": ident.get("essence", ""),
            "truth": ident.get("truth", ""),
            "parameters": reg.get("parameters") if isinstance(reg.get("parameters"), dict) else None,
        }

    enriched = [enrich(p) for p in pearls]
    with_img = [e for e in enriched if e["image"]]
    walk = (with_img or enriched)[:11]
    # Hand-curated walk override: doc/tutorial_authored/<seq>.json "walk": [names…]
    # (written directly, or via tools/import_walk_from_graph.py from /spine-graph).
    # The [:11] above is the machine's edge decision; this one is the author's.
    curated = False
    a = load_json(os.path.join(REPO, "doc", "tutorial_authored", f"{seq_id}.json"))
    ov = a.get("walk") if isinstance(a, dict) else None
    if isinstance(ov, list) and ov:
        if len(ov) > 11:
            print(f"  !! {seq_id}: curated walk has {len(ov)}; page grammar holds 11 — extras dropped")
        walk = [enrich(str(n)) for n in ov[:11]]
        curated = True
    if not walk:
        print(f"  !! no pearls for {seq_id}")
        return None
    primitive = walk[0]

    # Maps of the sequence, from map-overview.
    seq_maps = []
    for s in overview if isinstance(overview, list) else []:
        if s.get("seq") == seq_id:
            for m in s.get("maps", []):
                seq_maps.append({
                    "name": m.get("name"), "cols": m.get("cols"), "rows": m.get("rows"),
                    "artifacts": len(m.get("arts", [])), "footprint": m.get("footprint"),
                })
    # Next sequence on the spine.
    nxt = None
    ids = [s.get("name") for s in spine]
    if seq_id in ids:
        i = ids.index(seq_id)
        if i + 1 < len(ids):
            nxt = ids[i + 1]

    # The knobs (p5): parameter tables from walked artifacts that expose them.
    knobs = [{"name": e["name"], "title": e["title"], "image": e["image"], "parameters": e["parameters"]}
             for e in walk if e["parameters"]][:4]
    # Critical claims (p6): artifact truths from the walk.
    claims = [{"name": e["name"], "truth": e["truth"]} for e in walk if e["truth"]][:8]

    objectives = sd.get("learning_objectives") or []
    exercises = [f"{o}" for o in objectives][:5]
    exercises += [
        f"Walk {seq_maps[0]['name']} in VR and find where the rule first breaks its own pattern." if seq_maps else "Walk the sequence in VR.",
        f"Open {primitive['name']} in the dressing-room viewer and change one parameter until it stops being itself.",
    ]

    pages = [
        {"kind": "question", "title": "The Question",
         "truth": sd.get("truth", ""), "formula": sd.get("formula", ""),
         "text": sd.get("description", ""), "hero": walk[0]["image"], "hero_name": walk[0]["title"]},
        {"kind": "primitive", "title": "The Primitive", "artifact": primitive},
        {"kind": "walk", "title": "The Walk — first steps", "artifacts": walk[1:6]},
        {"kind": "walk", "title": "The Walk — further in", "artifacts": walk[6:11]},
        {"kind": "turn", "title": "The Turn — parameters", "knobs": knobs,
         "text": sd.get("demonstration", "")},
        {"kind": "critical", "title": "The Critical Reading",
         "qfep_term": sd.get("qfep_term", ""), "qfep_connection": sd.get("qfep_connection", ""),
         "claims": claims},
        {"kind": "world", "title": "In the World", "maps": seq_maps,
         "objectives": objectives,
         # Fold 5: the machine's ride through the built room, filed back into
         # the chapter (tools/fold_ride.py writes doc/book/ride_logs/<seq>.json).
         "ride": load_json(os.path.join(REPO, "doc", "book", "ride_logs", f"{seq_id}.json"))},
        {"kind": "seed", "title": "The Seed", "truth": sd.get("truth", ""),
         "exercises": exercises, "next": nxt},
    ]
    return apply_authored({
        "seq": seq_id,
        "name": sd.get("name", seq_id),
        "truth": sd.get("truth", ""),
        # The dig: the [:11] cap above is an edge decision — record what it
        # buried so the manuscript's ledger can report it honestly. A curated
        # walk marks the cut as the author's hand, not the formula's.
        "dig": {"pearls": max(len(enriched), len(walk)), "walked": len(walk),
                **({"curated": 1} if curated else {})},
        "pages": pages,
    }, seq_id)


def main() -> int:
    args = [a for a in sys.argv[1:] if a]
    registry = load_registry()
    to = load_json(THREE_ORDERS) or {}
    orders = {s["seq"]: s for s in to.get("sequences", [])}
    overview = load_json(MAP_OVERVIEW) or []
    spine_d = load_json(SPINE) or {}
    # curriculum_spine.json nests the ordered list under "spine".
    spine_block = spine_d.get("spine") if isinstance(spine_d.get("spine"), dict) else spine_d
    spine = spine_block.get("sequences", []) or spine_d.get("sequences", [])
    os.makedirs(OUT_DIR, exist_ok=True)

    if "--all" in args:
        targets = [s.get("name") for s in spine if s.get("name")]
    else:
        targets = [a for a in args if not a.startswith("--")]
    if not targets:
        print("usage: build_critical_tutorial.py <seq_id> | --all")
        return 1

    index = load_json(os.path.join(OUT_DIR, "index.json")) or {"sequences": []}
    have = {s["seq"]: s for s in index.get("sequences", [])}
    built = 0
    for seq in targets:
        t = build(seq, registry, orders, overview, spine)
        if not t:
            continue
        with open(os.path.join(OUT_DIR, f"{seq}.json"), "w", encoding="utf-8") as f:
            json.dump(t, f, indent=1)
        have[seq] = {"seq": seq, "name": t["name"], "truth": t["truth"]}
        built += 1
        n_img = sum(1 for p in t["pages"] for a in (p.get("artifacts") or ([p.get("artifact")] if p.get("artifact") else [])) if a and a.get("image"))
        print(f"  ok {seq}: 8 pages, {n_img} illustrated artifacts")
    # keep spine order in the index
    ordered = [have[s.get("name")] for s in spine if s.get("name") in have]
    with open(os.path.join(OUT_DIR, "index.json"), "w", encoding="utf-8") as f:
        json.dump({"sequences": ordered}, f, indent=1)
    print(f"built {built} tutorial(s) -> {OUT_DIR}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
