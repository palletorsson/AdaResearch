#!/usr/bin/env python3
"""The construction path: every thing Ada has, in one order, from the point to the last object.

Palle, 25 Oct 2026: "make every artifact or every thing that we have into a larger map of
objects … we can go from the point to the last Ada object … a next and previous gallery where
we can decide the order of the artifacts, starting in point. So the object and how it is being
constructed?"

Three kinds of step, each honest about how much of it the grammar knows:
  term      a grammar term (commons/modular/terms.json): its recipe in the notation, its parents
  artifact  a registry artifact the spine places: its elements as the disassembly read them
            off the tree it built (commons/data/spine_disassembly.json), not yet a term
  void      a token with no registry scene: a work The Void builds itself from rooms.json

The DEFAULT order: for each spine sequence in spine order, first the terms that belong there,
then the sequence's artifacts in map order (each where it is first placed). A term belongs to
the sequence its chapter maps to, or to a later one if one of its parents lives later — so a
term never comes before what it is made of. Within a sequence, terms in derivation order.

An AUTHORED order (saved from /construction-path) wins: this tool keeps it, drops ids that no
longer exist and inserts new ones right after their default predecessor.

    python tools/construction_path.py          # writes commons/data/construction_path.json
"""
from __future__ import annotations

import heapq
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from visual_memory_atlas import to_text  # noqa: E402  (the notation, one printer)

TERMS = ROOT / "commons/modular/terms.json"
SPINE = ROOT / "commons/maps/curriculum_spine.json"
SPAWNLISTS = ROOT / "commons/data/void_spawnlists.json"
DISASSEMBLY = ROOT / "commons/data/spine_disassembly.json"
OUT = ROOT / "commons/data/construction_path.json"

CHAPTER_SEQ = {"point": "primitives", "line": "primitives", "association": "primitives", "triangle": "primitives",
               "solid": "primitives", "assemblage": "primitives", "transformation": "transformation",
               "array": "array_tutorial", "motion": "change", "logic": "cellularautomata"}


def load():
    terms_doc = json.loads(TERMS.read_text(encoding="utf-8"))
    spine = sorted(json.loads(SPINE.read_text(encoding="utf-8"))["spine"]["sequences"], key=lambda s: s["order"])
    sl = json.loads(SPAWNLISTS.read_text(encoding="utf-8"))
    dis = json.loads(DISASSEMBLY.read_text(encoding="utf-8")) if DISASSEMBLY.exists() else {"artifacts": {}}
    return terms_doc, spine, sl, dis


def term_blocks(terms: dict, seq_index: dict) -> dict:
    """the sequence index each term lives in: its chapter's, or later if a parent lives later"""
    block: dict[str, int] = {}
    def of(tid: str, seen=()) -> int:
        if tid in block:
            return block[tid]
        if tid in seen or tid not in terms:
            return 0
        t = terms[tid]
        own = seq_index.get(CHAPTER_SEQ.get(t.get("chapter", ""), "primitives"), 0)
        parents = [p for p in t.get("from", []) if p in terms and p != tid]
        b = max([own] + [of(p, seen + (tid,)) for p in parents])
        block[tid] = b
        return b
    for tid in terms:
        of(tid)
    return block


def derivation_order(ids: list[str], terms: dict, chapters: list[str], index: dict) -> list[str]:
    """parents first (Kahn), ties by chapter then by place in terms.json — the point first"""
    idset = set(ids)
    deps = {t: {p for p in terms[t].get("from", []) if p in idset and p != t} for t in ids}
    users: dict[str, set] = {t: set() for t in ids}
    for t, ps in deps.items():
        for p in ps:
            users[p].add(t)
    key = lambda t: (0 if t == "point" else 1, chapters.index(terms[t].get("chapter")) if terms[t].get("chapter") in chapters else 99, index[t])
    ready = [(key(t), t) for t in ids if not deps[t]]
    heapq.heapify(ready)
    out = []
    while ready:
        _, t = heapq.heappop(ready)
        out.append(t)
        for u in users[t]:
            deps[u].discard(t)
            if not deps[u]:
                heapq.heappush(ready, (key(u), u))
    out += [t for t in ids if t not in out]   # a cycle, if any, keeps file order at the end
    return out


def build() -> dict:
    terms_doc, spine, sl, dis = load()
    terms = terms_doc["terms"]
    chapters = terms_doc.get("chapters", [])
    index = {t: i for i, t in enumerate(terms)}
    seq_names = [s["name"] for s in spine]
    seq_index = {n: i for i, n in enumerate(seq_names)}
    block = term_blocks(terms, seq_index)
    tree = {c["id"]: c for c in sl["trees"][0]["children"]}
    spawn_items = sl.get("items", {})
    items: dict[str, dict] = {}
    default: list[str] = []
    seen_art: set[str] = set()
    for si, seq in enumerate(spine):
        name = seq["name"]
        in_block = [t for t in terms if block.get(t, 0) == si]
        for tid in derivation_order(in_block, terms, chapters, index):
            t = terms[tid]
            iid = "t:" + tid
            items[iid] = {"kind": "term", "id": tid, "label": t.get("label", tid), "seq": name, "seq_order": seq["order"],
                          "chapter": t.get("chapter", ""), "thumb": f"/artifact-gallery/captures/mod_{tid}/front.png",
                          "expr": to_text(t.get("build", {})), "words": t.get("expr", ""),
                          "parents": ["t:" + p for p in t.get("from", []) if p in terms and p != tid],
                          "logic": bool(t.get("logic"))}
            default.append(iid)
        for m in tree.get(name, {"children": []})["children"]:
            for raw in m["items"]:
                tok = raw.split("@")[0]
                if tok in seen_art:
                    continue
                seen_art.add(tok)
                d = dis.get("artifacts", {}).get(tok, {})
                info = spawn_items.get(tok) or spawn_items.get("kit:" + tok) or spawn_items.get("prop:" + tok) or {}
                void = d.get("category") == "void-built" or (not info.get("scene") and not d)
                iid = "a:" + tok
                items[iid] = {"kind": "void" if void else "artifact", "id": tok, "label": info.get("label") or tok, "seq": name,
                              "seq_order": seq["order"], "map": m.get("id"), "thumb": info.get("thumbnail"),
                              "expr": d.get("expr") if d.get("expr") not in (None, "?") else "",
                              "category": d.get("category", ""), "bounds": d.get("bounds")}
                default.append(iid)
    for i, iid in enumerate(default):
        items[iid]["default_index"] = i
    # an authored order wins; new ids go in after their default predecessor
    authored, edited = None, None
    if OUT.exists():
        prev = json.loads(OUT.read_text(encoding="utf-8"))
        if prev.get("authored"):
            authored, edited = prev.get("order", []), prev.get("edited_at")
    if authored:
        order = [i for i in authored if i in items]
        have = set(order)
        for i, iid in enumerate(default):
            if iid in have:
                continue
            pred = next((default[j] for j in range(i - 1, -1, -1) if default[j] in have), None)
            pos = order.index(pred) + 1 if pred else 0
            order.insert(pos, iid)
            have.add(iid)
    else:
        order = default
    kinds = {k: sum(1 for i in items.values() if i["kind"] == k) for k in ("term", "artifact", "void")}
    return {"_doc": "The construction path: from the point to the last Ada object. GENERATED by tools/construction_path.py "
                    "(items); the ORDER is authored when `authored` is true (saved from /construction-path) and kept by the tool.",
            "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"), "authored": bool(authored), "edited_at": edited,
            "counts": kinds, "order": order, "items": items}


def main() -> int:
    doc = build()
    OUT.write_text(json.dumps(doc, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    c = doc["counts"]
    print(f"wrote {OUT.relative_to(ROOT)} — {len(doc['order'])} steps: {c['term']} terms, {c['artifact']} artifacts, {c['void']} Void works"
          f"{' (authored order kept)' if doc['authored'] else ' (default order)'}; first: {doc['order'][:4]} … last: {doc['order'][-1]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
