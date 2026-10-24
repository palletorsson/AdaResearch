"""build_void_spawnlists.py — the spawn menu's data: what the sequences built, as one tree.

Palle, 2026-10-22: a prefab add menu like Garry's Mod's spawnmenu, but "we should
not use the outside prefabs; the prefabs we have built in the sequences we can use".
So the list is DERIVED from the spine, never hand-written:

    curriculum_spine.json (25 sequences, in order)
      -> commons/maps/sequences/<name>.json  (its maps, in order)
        -> commons/maps/<Map>/map_data.json  (interactables layer: the artifacts standing there)
          -> the artifact catalog (tools/validate_void_rooms.py --catalog: name, scene,
             footprint, map_ready, category) and the capture manifest
             (ada_encyclopedia/public/artifact-gallery/captures/manifest.json: thumbnails)

Output: commons/data/void_spawnlists.json — a tree sequence -> map -> items (the
Garry's Mod left pane) and a flat `items` dict (the thumbnail grid), each item with
label, scene, footprint, thumbnail URL and where it stands. Every editor reads the
same file: the web palette and native desktop/world-board menus. Version 2 adds
the existing construction kit and configured saved-spine variants through
void_prefab_library.enrich; original scenes are never rewritten.

  python tools/build_void_spawnlists.py            # write the file, print the summary
  python tools/build_void_spawnlists.py --check    # exit 1 if the file on disk is stale
"""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENC = ROOT.parent / "ada_encyclopedia"
OUT = ROOT / "commons" / "data" / "void_spawnlists.json"
CAPTURES = ENC / "public" / "artifact-gallery" / "captures" / "manifest.json"
# cell prefixes that are families / directives, not a placeable artifact
NOT_AN_ARTIFACT = {"", "mc", "gridagent", "cluster", "criticalinfo", "sub", "an", "t", "sp", "ds", "r", "m", "3t"}
ANGLE_ORDER = ("front", "above", "left", "right", "top")


def load(p: Path):
    return json.loads(p.read_text(encoding="utf-8"))


def spine_order() -> list[dict]:
    return sorted(load(ROOT / "commons/maps/curriculum_spine.json")["spine"]["sequences"], key=lambda s: s.get("order", 0))


def sequence_maps(name: str) -> tuple[list[str], dict]:
    f = ROOT / "commons/maps/sequences" / f"{name}.json"
    if not f.exists():
        return [], {}
    doc = load(f)
    seqs = doc.get("sequences", [])
    seqs = seqs if isinstance(seqs, list) else list(seqs.values())
    entry = next((s for s in seqs if s.get("name") == name), seqs[0] if seqs else {})
    maps = [m for m in entry.get("maps", []) if isinstance(m, str)]
    return maps, entry


def map_tokens(map_name: str) -> list[str]:
    """Lookup names in the interactables layer, in reading order, unique."""
    f = ROOT / "commons/maps" / map_name / "map_data.json"
    if not f.exists():
        return []
    rows = (load(f).get("layers") or {}).get("interactables") or []
    seen: list[str] = []
    for row in rows:
        cells = row if isinstance(row, list) else str(row).split(",")
        for c in cells:
            tok = str(c or "").split("#")[0].split(":")[0].strip()
            if tok in NOT_AN_ARTIFACT or tok in seen:
                continue
            seen.append(tok)
    return seen


def catalog() -> dict:
    r = subprocess.run([sys.executable, str(ROOT / "tools/validate_void_rooms.py"), "--catalog"],
                       capture_output=True, text=True, encoding="utf-8")
    if r.returncode != 0:
        raise SystemExit("artifact catalog unavailable: " + r.stderr[-400:])
    return json.loads(r.stdout)


def thumbnails() -> dict:
    if not CAPTURES.exists():
        return {}
    return load(CAPTURES).get("captures", {})


def thumb_url(token: str, caps: dict) -> str | None:
    """The capture manifest first; else a PNG that stands in the gallery folder without a
    manifest row (265 such tokens on 2026-10-22: older captures the sync never listed)."""
    e = caps.get(token)
    angles = list(e.get("angles") or []) if e else []
    if not angles:
        folder = CAPTURES.parent / token
        if folder.is_dir():
            angles = sorted(p.stem for p in folder.glob("*.png"))
    if not angles:
        return None
    angle = next((a for a in ANGLE_ORDER if a in angles), angles[0])
    return f"/artifact-gallery/captures/{token}/{angle}.png"


def build() -> dict:
    cat = catalog()
    caps = thumbnails()
    items: dict[str, dict] = {}
    tree = []
    unknown: dict[str, int] = {}
    for s in spine_order():
        name = s["name"]
        maps, entry = sequence_maps(name)
        seq_node = {"id": name, "label": str(entry.get("truth") or name).strip()[:80] if entry else name,
                    "title": name.replace("_", " "), "order": s.get("order"), "phase": s.get("phase"),
                    "children": [], "items": []}
        for m in maps:
            toks = map_tokens(m)
            node = {"id": m, "label": m.replace("_", " "), "items": []}
            for t in toks:
                c = cat.get(t)
                if c is None:
                    unknown[t] = unknown.get(t, 0) + 1
                    continue
                node["items"].append(t)
                if t not in seq_node["items"]:
                    seq_node["items"].append(t)
                it = items.setdefault(t, {
                    "label": c.get("name") or t, "scene": c.get("scene"), "category": c.get("category"),
                    "description": (c.get("description") or "")[:240], "footprint": c.get("footprint"),
                    "map_ready": bool(c.get("map_ready")), "thumbnail": thumb_url(t, caps),
                    "sequences": [], "maps": []})
                if name not in it["sequences"]:
                    it["sequences"].append(name)
                if m not in it["maps"]:
                    it["maps"].append(m)
            seq_node["children"].append(node)
        tree.append(seq_node)
    # the modular class system's terms as a second tree (chapter -> terms), tokens mod_<term>
    modular_tree = None
    terms_file = ROOT / "commons/modular/terms.json"
    if terms_file.exists():
        tdoc = load(terms_file)
        chapters = {}
        for tid, t in tdoc.get("terms", {}).items():
            tok = f"mod_{tid}"
            c = cat.get(tok)
            if c is None:
                continue
            ch = str(t.get("chapter", "other"))
            chapters.setdefault(ch, []).append(tok)
            items[tok] = {"label": t.get("label", tid), "scene": c.get("scene"), "category": "modular",
                          "description": f"{t.get('label', tid)} = {t.get('expr', '')}", "footprint": c.get("footprint"),
                          "map_ready": True, "thumbnail": thumb_url(tok, caps), "sequences": [], "maps": [],
                          "modular": {"term": tid, "from": t.get("from", []), "expr": t.get("expr", "")}}
        order = tdoc.get("chapters", list(chapters))
        modular_tree = {"id": "modular", "label": "Built from the grammar", "children": [
            {"id": "modular/" + ch, "title": ch, "label": ch, "order": i + 1, "children": [], "items": chapters.get(ch, [])}
            for i, ch in enumerate(order) if ch in chapters]}
    srcs = [ROOT / "commons/maps/curriculum_spine.json", CAPTURES]
    return {
        "_doc": "Generated by tools/build_void_spawnlists.py from the spine; do not edit. The spawn menu of The Void: "
                "only artifacts that stand in a spine map. Thumbnails are the artifact-gallery captures.",
        "generated_at": int(time.time()),
        "source_files": {str(p.relative_to(ROOT) if p.is_relative_to(ROOT) else p.name): hashlib.sha256(p.read_bytes()).hexdigest()[:16] for p in srcs if p.exists()},
        "trees": [{"id": "sequences", "label": "Built in the sequences", "children": tree}] + ([modular_tree] if modular_tree else []),
        "items": items,
        "unknown_tokens": dict(sorted(unknown.items(), key=lambda kv: -kv[1])),
        "summary": {
            "sequences": len(tree), "maps": sum(len(s["children"]) for s in tree), "items": len(items),
            "with_thumbnail": sum(1 for i in items.values() if i["thumbnail"]),
            "map_ready": sum(1 for i in items.values() if i["map_ready"]),
            "unknown_tokens": len(unknown),
        },
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true", help="compare with the file on disk; exit 1 when stale")
    ap.add_argument("--out", default=str(OUT))
    a = ap.parse_args()
    from void_prefab_library import enrich
    doc = enrich(build(), ROOT, ENC)
    out = Path(a.out)
    body = json.dumps(doc, indent=1, ensure_ascii=False) + "\n"
    if a.check:
        if not out.exists():
            print("missing:", out)
            return 1
        old = load(out)
        same = {k: v for k, v in old.items() if k not in ("generated_at",)} == {k: v for k, v in doc.items() if k not in ("generated_at",)}
        print("up to date" if same else "STALE", out, doc["summary"])
        return 0 if same else 1
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(body, encoding="utf-8")
    s = doc["summary"]
    print(f"wrote {out.relative_to(ROOT)}: {s['sequences']} sequences, {s['maps']} maps, {s['items']} artifacts "
          f"({s['with_thumbnail']} with a thumbnail, {s['map_ready']} map_ready), {s['unknown_tokens']} token(s) not in the catalog")
    for seq in doc["trees"][0]["children"]:
        print(f"  {seq['order']:>2} {seq['id']:<28} {len(seq['children']):>3} maps {len(seq['items']):>4} artifacts")
    if doc["unknown_tokens"]:
        print("  not in the catalog:", ", ".join(list(doc["unknown_tokens"])[:12]) + (" …" if len(doc["unknown_tokens"]) > 12 else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
