#!/usr/bin/env python3
"""Build artifact.md — one cognitive-space node per artifact.

For each artifact it fuses four things into a single Ada-Research summary:
  1. code identity  — the @identity block (essence/desire/truth/lineage/…) +
     class/extends + @export "DNA" from the artifact's .gd
  2. game prose      — the map it lives in, and that map's summary/intent text
  3. image           — /scene-catalog/<lookup>.png
  4. links           — ontology-close kin (atlas embeddings), the artifact's own
                       small/medium/large/applied VERSIONS (concept ladder),
                       its map and its sequence.

Cross-linked (every node links its kin, its scaled siblings, its home), the
corpus is a walkable image of the cognitive space.

Usage:
  python tools/build_artifact_md.py --ids point,recursion_bench
  python tools/build_artifact_md.py --all
  python tools/build_artifact_md.py --ids recursion_bench --in-place   # also write commons/artifacts/<t>/artifact.md

Output: ada_encyclopedia/public/artifact-md/<lookup>.md  (web-servable; images resolve)
"""
from __future__ import annotations
import argparse, json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENC = ROOT.parent / "ada_encyclopedia"
ORDER_JSON = ENC / "public" / "order_of_things.json"
MAPS_DIR = ROOT / "commons" / "maps"
REG_DIR = ROOT / "commons" / "artifacts" / "registry"
ATLAS_NPZ = ROOT / "doc" / "atlas" / "artifact_embeddings.npz"
OUT_DIR = ENC / "public" / "artifact-md"
DOC_DIR = ROOT / "doc"

SECTIONS = ["summary", "intent", "tutorial", "critical"]
TIERS = ["small", "medium", "large", "applied"]
CANON_DOCS = [
    "vector_forces_concept_map.json", "randomness_concept_map.json", "ca_concept_map.json",
    "lsystem_concept_map.json", "fractal_concept_map.json", "softbody_concept_map.json",
    "procgen_concept_map.json", "foundations_concept_map.json", "qfep_concept_map.json",
    "postcrisis_concept_map.json",
]
# @identity keys we surface, in display order
ID_KEYS = ["name", "tier", "lineage", "essence", "desire", "critical_parameter",
           "applications", "truth", "emerges", "needs", "triggers", "relationships"]


# ── load shared indexes once ────────────────────────────────────────────────
def load_order():
    d = json.loads(ORDER_JSON.read_text(encoding="utf-8"))
    by = {}
    for arr in ("spine", "branch", "dna", "rest"):
        for it in d.get(arr, []):
            by.setdefault(it["lookup"], it)
    return d, by


def index_gd():
    idx = {}
    for base in (ROOT / "commons", ROOT / "algorithms"):
        for p in base.rglob("*.gd"):
            idx.setdefault(p.stem, p)
    return idx


def load_registry():
    meta = {}
    for f in REG_DIR.glob("*.json"):
        try:
            d = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        for lk, m in (d.get("artifacts") or {}).items():
            meta.setdefault(lk, m)
    return meta


def build_ladder_index():
    """lookup -> (map_title, concept, tiers dict, count); smallest concept wins."""
    idx = {}
    for f in CANON_DOCS:
        p = DOC_DIR / f
        if not p.exists():
            continue
        d = json.loads(p.read_text(encoding="utf-8"))
        meta = d.get("concept_meta", {})
        title = (d.get("title") or f).split(" — ")[0]
        for concept in d.get("concepts", []):
            tiers = meta.get(concept, {}).get("tiers")
            if not tiers:
                continue
            count = meta[concept].get("count") or sum(len(tiers.get(t, [])) for t in TIERS)
            for t in TIERS:
                for lk in tiers.get(t, []):
                    prev = idx.get(lk)
                    if prev is None or count < prev[3]:
                        idx[lk] = (title, concept, tiers, count)
    return idx


def load_embeddings():
    try:
        import numpy as np
    except Exception:
        return None
    if not ATLAS_NPZ.exists():
        return None
    z = np.load(ATLAS_NPZ, allow_pickle=True)
    ids = [str(x) for x in z["ids"]]
    vecs = z["vectors"]
    return {"np": np, "ids": ids, "id2i": {x: i for i, x in enumerate(ids)}, "vecs": vecs}


def neighbors(emb, lk, topn=8):
    if not emb:
        return []
    i = emb["id2i"].get(lk)
    if i is None:
        return []
    scores = emb["vecs"] @ emb["vecs"][i]
    order = emb["np"].argsort(-scores)
    out = []
    for j in order:
        if int(j) == i:
            continue
        out.append((emb["ids"][int(j)], float(scores[int(j)])))
        if len(out) >= topn:
            break
    return out


# ── .gd @identity parser ─────────────────────────────────────────────────────
def parse_gd(path: Path):
    cls = ext = None
    identity, exports = {}, []
    in_id = False
    cur = None
    try:
        lines = path.read_text(encoding="utf-8", errors="ignore").splitlines()
    except Exception:
        return {"class": None, "extends": None, "identity": {}, "exports": []}
    for ln in lines:
        s = ln.strip()
        if cls is None and s.startswith("class_name"):
            cls = s.split("class_name", 1)[1].strip()
        if ext is None and s.startswith("extends"):
            ext = s.split("extends", 1)[1].strip().strip('"')
        if re.match(r"#+\s*@identity\b", s):
            in_id = True
            continue
        if in_id:
            cm = re.match(r"#+\s?(.*)", s)
            if cm is None:                      # a real code line — identity block ended
                in_id = False
                cur = None
            else:
                body = cm.group(1).rstrip()
                kv = re.match(r"([a-zA-Z_]\w*):\s*(.*)", body)
                if kv:
                    cur = kv.group(1).lower()
                    identity[cur] = kv.group(2).strip().strip('"')
                elif cur and body.strip():
                    identity[cur] = (identity[cur] + " " + body.strip()).strip()
        em = re.match(r"@export(?:_\w+)?\s+var\s+(\w+)\s*:?\s*([\w\[\].]+)?\s*(?:=\s*(.*))?", s)
        if em:
            exports.append((em.group(1), (em.group(2) or "").strip(), (em.group(3) or "").strip()))
    return {"class": cls, "extends": ext, "identity": identity, "exports": exports}


def read_section(map_name: str, section: str, limit: int = 900) -> str:
    if not map_name:
        return ""
    p = MAPS_DIR / map_name / f"{section}.md"
    if not p.exists():
        return ""
    t = p.read_text(encoding="utf-8", errors="ignore").strip()
    return t if len(t) <= limit else t[:limit].rsplit(" ", 1)[0] + " …"


# ── render one artifact.md ───────────────────────────────────────────────────
def render(lk, order_by, gd_idx, reg, ladder, emb):
    it = order_by.get(lk, {})
    name = it.get("name") or (reg.get(lk, {}).get("name")) or lk
    image = it.get("image")
    mp = it.get("map") or ""
    seq = it.get("sequence") or ""
    phase = it.get("phase") or ""
    pos = it.get("pos")
    why = it.get("why") or reg.get(lk, {}).get("description") or ""

    gd = gd_idx.get(lk)
    parsed = parse_gd(gd) if gd else {"class": None, "extends": None, "identity": {}, "exports": []}
    ident = parsed["identity"]

    L = []
    L.append(f"# {name}")
    L.append(f"`{lk}`" + (f" · spine #{pos}" if pos else "") + (f" · {phase}" if phase else ""))
    L.append("")
    if image:
        L.append(f'![{name}]({image})')
        L.append("")
    head = ident.get("truth") or ident.get("essence") or why
    if head:
        L.append(f"> {head}")
        L.append("")

    # where it lives
    where = []
    if seq:
        where.append(f"**Sequence:** {seq}")
    if mp:
        where.append(f"**Map:** [{mp}](../order_of_things.json) ")
    if ident.get("tier"):
        where.append(f"**Tier:** {ident['tier']}")
    if where:
        L.append(" · ".join(where))
        L.append("")

    # identity
    body_keys = [k for k in ID_KEYS if k in ident and k not in ("name", "tier", "truth")]
    if body_keys:
        L.append("## Identity")
        for k in body_keys:
            L.append(f"- **{k.replace('_', ' ')}** — {ident[k]}")
        L.append("")

    # game prose
    if mp:
        prose = []
        for s in SECTIONS:
            t = read_section(mp, s)
            if t:
                prose.append(f"**{s.capitalize()} — {mp}**\n\n{t}")
        if prose:
            L.append("## In the game")
            L.append("\n\n".join(prose))
            L.append("")

    # code
    code = []
    if parsed["class"]:
        code.append(f"- **class** `{parsed['class']}`" + (f" extends `{parsed['extends']}`" if parsed["extends"] else ""))
    if gd:
        rel = gd.relative_to(ROOT).as_posix()
        code.append(f"- **file** `{rel}`")
    if parsed["exports"]:
        dna = ", ".join(f"`{n}`" + (f": {ty}" if ty else "") for n, ty, _ in parsed["exports"][:14])
        code.append(f"- **DNA** {dna}")
    if code:
        L.append("## Code")
        L.extend(code)
        L.append("")

    # versions — the ladder
    lad = ladder.get(lk)
    if lad:
        title, concept, tiers, _ = lad
        L.append("## Versions — the same idea at every scale")
        L.append(f"*{title} · {concept}*")
        L.append("")
        for t in TIERS:
            items = tiers.get(t, [])
            if not items:
                continue
            links = ", ".join(f"[{order_by.get(x, {}).get('name', x)}]({x}.md)" + (" ←" if x == lk else "") for x in items)
            L.append(f"- **{t}** — {links}")
        L.append("")

    # ontology-close kin
    kin = neighbors(emb, lk, topn=8)
    if kin:
        L.append("## Close in the cognitive space")
        for nid, sim in kin:
            nm = order_by.get(nid, {}).get("name", nid)
            L.append(f"- [{nm}]({nid}.md) · {sim*100:.0f}%")
        L.append("")

    L.append("---")
    L.append(f"*Cognitive-space node generated by `tools/build_artifact_md.py` from {('`'+gd.name+'`') if gd else 'registry'}"
             + (f", {mp} prose" if mp else "") + ", atlas neighbours and the concept ladder.*")
    return "\n".join(L)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ids", help="comma-separated artifact lookups")
    ap.add_argument("--all", action="store_true", help="every artifact in order_of_things.json")
    ap.add_argument("--in-place", action="store_true", help="also write commons/artifacts/<token>/artifact.md when a folder exists")
    args = ap.parse_args()

    order, order_by = load_order()
    gd_idx = index_gd()
    reg = load_registry()
    ladder = build_ladder_index()
    emb = load_embeddings()

    if args.all:
        ids = list(order_by.keys())
    elif args.ids:
        ids = [x.strip() for x in args.ids.split(",") if x.strip()]
    else:
        print("give --ids a,b,c or --all"); sys.exit(1)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    n = 0
    for lk in ids:
        md = render(lk, order_by, gd_idx, reg, ladder, emb)
        (OUT_DIR / f"{lk}.md").write_text(md, encoding="utf-8")
        n += 1
        if args.in_place:
            gd = gd_idx.get(lk)
            if gd and gd.parent.name == lk:   # has its own folder
                (gd.parent / "artifact.md").write_text(md, encoding="utf-8")
    print(f"wrote {n} artifact.md node(s) -> {OUT_DIR}")
    print(f"  embeddings: {'loaded' if emb else 'MISSING (no neighbours)'} · ladder entries: {len(ladder)} · gd index: {len(gd_idx)}")


if __name__ == "__main__":
    main()
