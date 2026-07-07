#!/usr/bin/env python3
"""Build 'The Order of Things' — every artifact in spine order, then DNA, then gallery.

Walks the curriculum spine (sequence order -> map order -> interactable reading
order), recording the FIRST appearance of each artifact. That ordered list is the
curricular spine of objects, starting at `point`. Then appends artifacts from
non-spine (branch) maps, then the DNA gallery, then any remaining registry
artifacts. Joins each with its registry metadata, @identity rationale, and a
scene-catalog image.

Output: ada_encyclopedia/public/order_of_things.json
"""
import json, os, glob, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.path.join(os.path.dirname(ROOT), "ada_encyclopedia")
SCENE_CAT = os.path.join(ENC, "public", "scene-catalog")
DNA_DIR = os.path.join(ENC, "public", "props-dna-gallery")

def load(p):
    with open(p, encoding="utf-8") as f:
        return json.load(f)

# ---- spine order -----------------------------------------------------------
spine = load(os.path.join(ROOT, "commons/maps/curriculum_spine.json"))
spine_seqs = sorted(spine["spine"]["sequences"], key=lambda q: float(q.get("order", 999)))

def seq_file(name):
    p = os.path.join(ROOT, "commons/maps/sequences", name + ".json")
    return p if os.path.exists(p) else None

def seq_maps(name):
    """Ordered map list for a spine sequence (concat of its sub-sequences)."""
    p = seq_file(name)
    if not p:
        return [], {}
    data = load(p)
    maps, meta = [], {}
    subs = data.get("sequences", {})
    for key, sub in subs.items():
        if not meta:  # first sub-seq supplies the headline pedagogy
            meta = {k: sub.get(k) for k in ("name", "truth", "qfep_connection", "formula", "description")}
        for m in sub.get("maps", []):
            if m not in maps:
                maps.append(m)
    return maps, meta

# ---- registry index --------------------------------------------------------
registry = {}   # lookup_name -> entry
def index_entry(e):
    if isinstance(e, dict) and isinstance(e.get("lookup_name"), str):
        registry.setdefault(e["lookup_name"], e)
    if isinstance(e, dict):
        for v in e.values():
            index_entry(v)
    elif isinstance(e, list):
        for v in e:
            index_entry(v)

for rf in glob.glob(os.path.join(ROOT, "commons/artifacts/registry/*.json")):
    try:
        index_entry(load(rf))
    except Exception:
        pass

# ---- map interactables -----------------------------------------------------
def map_tokens(map_name):
    """Artifact lookup_names in a map, reading order (row-major).
    Skips `#`-prefixed COMMENT tokens (not placed). Strips `:rot:off` and
    `#config` suffixes to the bare lookup_name."""
    p = os.path.join(ROOT, "commons/maps", map_name, "map_data.json")
    if not os.path.exists(p):
        return []
    try:
        m = load(p)
    except Exception:
        return []
    grid = m.get("layers", {}).get("interactables", [])
    out = []
    for row in grid:
        if not isinstance(row, list):
            continue
        for cell in row:
            if not (isinstance(cell, str) and cell.strip()):
                continue
            t = cell.strip()
            if t.startswith("#"):      # commented-out reference, never placed
                continue
            tok = t.split(":")[0].split("#")[0].strip()   # bare lookup
            if tok:
                out.append(tok)
    return out

# Global frequency: how many maps each artifact appears in. High-frequency
# tokens are scaffolding/infrastructure (you_are_here, lab_room, origin, science
# screens) — we demote them so each map's TEACHING artifacts lead the order.
_all_maps = glob.glob(os.path.join(ROOT, "commons/maps/*/map_data.json"))
freq = {}
for _p in _all_maps:
    _mn = os.path.basename(os.path.dirname(_p))
    for _t in set(map_tokens(_mn)):
        freq[_t] = freq.get(_t, 0) + 1

def ordered_tokens(map_name):
    """Map tokens with teaching artifacts (rare) before scaffolding (common)."""
    toks = map_tokens(map_name)
    seen_local, uniq = set(), []
    for i, t in enumerate(toks):
        if t not in seen_local:
            seen_local.add(t)
            uniq.append((freq.get(t, 1), i, t))
    uniq.sort(key=lambda x: (x[0], x[1]))   # frequency asc, then reading order
    return [t for _, _, t in uniq]

# ---- image lookup ----------------------------------------------------------
scene_imgs = {os.path.splitext(os.path.basename(p))[0]: "/scene-catalog/" + os.path.basename(p)
              for p in glob.glob(os.path.join(SCENE_CAT, "*.png"))}

def image_for(lookup):
    if lookup in scene_imgs:
        return scene_imgs[lookup]
    # loose match: scene-catalog name starts with lookup or vice versa
    for k, v in scene_imgs.items():
        if k == lookup:
            return v
    for k, v in scene_imgs.items():
        if k.startswith(lookup + "_") or lookup.startswith(k + "_"):
            return v
    return None

def meta_for(lookup):
    e = registry.get(lookup, {})
    ident = e.get("identity", {}) if isinstance(e.get("identity"), dict) else {}
    return {
        "name": e.get("name") or lookup.replace("_", " ").title(),
        "category": e.get("category") or "",
        "essence": ident.get("essence") or e.get("capacity") or "",
        "truth": ident.get("truth") or "",
        "description": e.get("description") or "",
    }

# ---- 1) SPINE walk ---------------------------------------------------------
seen = set()
spine_items = []
position = 0

# HYBRID: pin the foundational primitives to lead, in conceptual order, so the
# list starts at the point even though the maps comment that artifact out. The
# rest follows in spine-map order (scaffolding demoted) below.
FOUNDATION = ["point", "line", "plane", "triangle"]
FOUNDATION_NOTE = "Foundation — the atoms everything else is built from."
for tok in FOUNDATION:
    if tok in registry and tok not in seen:
        seen.add(tok)
        position += 1
        md = meta_for(tok)
        spine_items.append({
            "pos": position, "lookup": tok, "name": md["name"],
            "category": md["category"] or "primitives",
            "why": md["essence"] or md["truth"] or md["description"],
            "sequence": "Primitives: the foundation", "phase": "F_order",
            "seq_truth": FOUNDATION_NOTE, "map": "", "image": image_for(tok),
            "foundation": True,
        })

for q in spine_seqs:
    name = q.get("name")
    maps, smeta = seq_maps(name)
    seq_title = smeta.get("name") or name
    seq_truth = smeta.get("truth") or smeta.get("qfep_connection") or ""
    for mp in maps:
        for tok in ordered_tokens(mp):
            if tok in seen or tok not in registry:
                continue
            seen.add(tok)
            position += 1
            md = meta_for(tok)
            why = md["essence"] or md["truth"] or md["description"]
            spine_items.append({
                "pos": position, "lookup": tok, "name": md["name"],
                "category": md["category"], "why": why,
                "sequence": seq_title, "phase": q.get("phase", ""),
                "seq_truth": seq_truth, "map": mp,
                "image": image_for(tok),
            })

# ---- 2) BRANCH maps (non-spine maps) ---------------------------------------
spine_map_set = set()
for q in spine_seqs:
    for mp, _ in [(m, None) for m in seq_maps(q.get("name"))[0]]:
        spine_map_set.add(mp)

branch_items = []
for p in sorted(glob.glob(os.path.join(ROOT, "commons/maps/*/map_data.json"))):
    mp = os.path.basename(os.path.dirname(p))
    if mp in spine_map_set:
        continue
    for tok in ordered_tokens(mp):
        if tok in seen or tok not in registry:
            continue
        seen.add(tok)
        md = meta_for(tok)
        branch_items.append({
            "lookup": tok, "name": md["name"], "category": md["category"],
            "why": md["essence"] or md["truth"] or md["description"],
            "map": mp, "image": image_for(tok),
        })

# ---- 3) DNA gallery --------------------------------------------------------
dna_items = []
dna_manifest = os.path.join(DNA_DIR, "manifest.json")
if os.path.exists(dna_manifest):
    dm = load(dna_manifest)
    for e in dm.get("entries", []):
        img = e.get("image") or (e.get("id", "") + ".png")
        dna_items.append({
            "lookup": e.get("id") or e.get("prop"), "name": e.get("label") or e.get("id"),
            "prop": e.get("prop", ""), "why": e.get("description", ""),
            "image": "/props-dna-gallery/" + os.path.basename(img) if img else None,
        })

# ---- 4) REST (registry artifacts never placed) -----------------------------
rest_items = []
for lookup, e in sorted(registry.items()):
    if lookup in seen:
        continue
    if not isinstance(e, dict):
        continue
    md = meta_for(lookup)
    rest_items.append({
        "lookup": lookup, "name": md["name"], "category": md["category"],
        "why": md["essence"] or md["truth"] or md["description"],
        "image": image_for(lookup),
    })

out = {
    "generated_note": "The Order of Things — spine-first, then branch maps, then DNA, then the rest.",
    "counts": {
        "spine": len(spine_items), "branch": len(branch_items),
        "dna": len(dna_items), "rest": len(rest_items),
        "registry_total": len(registry),
    },
    "spine": spine_items,
    "branch": branch_items,
    "dna": dna_items,
    "rest": rest_items,
}
outp = os.path.join(ENC, "public", "order_of_things.json")
with open(outp, "w", encoding="utf-8") as f:
    json.dump(out, f, ensure_ascii=False, indent=1)

print("counts:", out["counts"])
print("with images — spine:", sum(1 for x in spine_items if x["image"]), "/", len(spine_items))
print("first 8 spine:", [(x["pos"], x["lookup"]) for x in spine_items[:8]])
print("wrote", outp)
