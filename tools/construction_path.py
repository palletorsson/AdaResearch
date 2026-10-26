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

The DEFAULT order is the MAIN TRACK (commons/data/capacity_track.json, tools/capacity_track.py):
each track step gives the thing one new capacity, and is followed by its BRANCHES — the terms
and artifacts nearest to it in capacity, closest first. A step with no term yet is a HOLE item
(h:<index>), kept visible with what waits on it. Within a step a term still never comes before
what it is made of: a branch term moves later to follow its parents, and the parts a track
term is built from move earlier to come before it. Artifacts the disassembly could not read
(Void works, scenes that hung) close the path, in sequence order.

`order_by_sequence` keeps the older order: for each spine sequence in spine order, the terms
that belong there (by chapter, or later if a parent lives later) in derivation order, then the
sequence's artifacts in map order; holes at the end. Without a capacity track it is the default.

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
TRACK = ROOT / "commons/data/capacity_track.json"
OUT = ROOT / "commons/data/construction_path.json"

CHAPTER_SEQ = {"point": "primitives", "line": "primitives", "association": "primitives", "triangle": "primitives",
               "solid": "primitives", "assemblage": "primitives", "transformation": "transformation",
               "array": "array_tutorial", "color": "color", "tiling": "tiling", "change": "change",
               "motion": "change", "forces": "forces", "formfinding": "formfinding", "waves": "wavefunctions",
               "randomness": "randomness", "noise": "noise", "logic": "cellularautomata", "fractals": "fractals",
               "lsystems": "lsystems"}


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


def track_order(items: dict, seq_default: list[str], terms: dict, index: dict, ct: dict) -> tuple[list[str], list[str]]:
    """the main track, each step followed by its branches; returns (order, parent-after-child violations)"""
    steps = ct.get("track", [])
    step_of_node = {}                                   # capacity_track's branch_of → step index
    for i, st in enumerate(steps):
        step_of_node[st["term"] if st.get("term") else f"hole:{i}"] = i
    step_iid = {i: ("t:" + st["term"] if st.get("term") else f"h:{i}") for i, st in enumerate(steps)}
    ct_terms, ct_art = ct.get("terms", {}), ct.get("artifacts", {})
    for i, st in enumerate(steps):                      # the holes become items of their own
        if not st.get("term"):
            items[f"h:{i}"] = {"kind": "hole", "id": f"h:{i}", "label": st.get("adds", "a hole"), "seq": "", "seq_order": 0,
                               "lane": "hole", "step": i, "adds": st.get("adds"), "axis": st.get("axis"), "hole": st.get("hole")}
    track_set = {st["term"] for st in steps if st.get("term")}
    slot: dict[str, int] = {}
    last = len(steps) - 1
    for tid in terms:
        info = ct_terms.get(tid)
        it = items.get("t:" + tid)
        if it is None:
            continue
        if tid in track_set:
            slot[tid] = step_of_node[tid]
            it.update(lane="track", step=slot[tid], adds=steps[slot[tid]].get("adds"), axis=steps[slot[tid]].get("axis"), sig=(info or {}).get("sig"))
        elif info:
            slot[tid] = step_of_node.get(info["branch_of"], last)
            it.update(lane="branch", branch_of=step_iid.get(slot[tid]), distance=info.get("distance"), beyond=info.get("beyond", []), sig=info.get("sig"))
        else:
            it.update(lane="unread")                    # the disassembly has no tree for it (a term that did not build)
    # a branch term follows its parents (max over the parents' steps) …
    parents = {t: [p for p in terms[t].get("from", []) if p in slot and p != t] for t in slot}
    for _ in range(len(slot)):
        changed = False
        for t in slot:
            if t in track_set:
                continue
            m = max([slot[t]] + [slot[p] for p in parents[t]])
            if m != slot[t]:
                slot[t], changed = m, True
        if not changed:
            break
    # … and the parts a track term is built from come before it (min over its track descendants)
    def ancestors(t: str, acc: set) -> set:
        for p in parents.get(t, []):
            if p not in acc:
                acc.add(p); ancestors(p, acc)
        return acc
    for t in track_set:
        if t not in slot:
            continue
        for a in ancestors(t, set()):
            if a not in track_set and slot[a] > slot[t]:
                slot[a] = slot[t]
    violations = [f"{t} (step {slot[t]}) is made of {p} (step {slot[p]})" for t in track_set if t in slot
                  for p in parents[t] if p in track_set and slot[p] > slot[t]]
    for t, k in slot.items():
        items["t:" + t]["step"] = k
        if items["t:" + t].get("lane") == "branch":
            items["t:" + t]["branch_of"] = step_iid.get(k)
    for iid in seq_default:
        it = items[iid]
        if it["kind"] == "term":
            continue
        info = ct_art.get(it["id"])
        if info and info.get("lane") == "branch":
            k = step_of_node.get(info["branch_of"], last)
            it.update(lane="branch", step=k, branch_of=step_iid.get(k), distance=info.get("distance"), beyond=info.get("beyond", []),
                      staged=info.get("staged", []), sig=info.get("sig"))
        else:
            it.update(lane="unread", why=(info or {}).get("why") or ("built by The Void itself" if it["kind"] == "void" else "no tree read"))
    order: list[str] = []
    seq_pos = {iid: i for i, iid in enumerate(seq_default)}
    for k in range(len(steps)):
        if step_iid[k].startswith("h:"):
            order.append(step_iid[k])
        block = [t for t, s in slot.items() if s == k]
        ids = set(block)
        deps = {t: {p for p in parents[t] if p in ids} for t in block}
        users: dict[str, set] = {t: set() for t in block}
        for t, ps in deps.items():
            for p in ps:
                users[p].add(t)
        # the step leads its block: its track term, and just ahead of it the parts it is made of
        lead = set().union(*[ancestors(t, set()) for t in block if t in track_set]) & ids
        key = lambda t: (0 if t in track_set or t in lead else 1, items["t:" + t].get("distance") or 0, index[t])
        ready = [(key(t), t) for t in block if not deps[t]]
        heapq.heapify(ready)
        while ready:
            _, t = heapq.heappop(ready)
            order.append("t:" + t)
            for u in users[t]:
                deps[u].discard(t)
                if not deps[u]:
                    heapq.heappush(ready, (key(u), u))
        arts = [iid for iid in seq_default if items[iid]["kind"] != "term" and items[iid].get("lane") == "branch" and items[iid]["step"] == k]
        order += sorted(arts, key=lambda iid: (items[iid].get("distance") or 0, seq_pos[iid]))
    have = set(order)
    order += [iid for iid in seq_default if iid not in have]   # what the disassembly could not read closes the path
    return order, violations


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
    seq_default, violations, gate_ok = default, [], None
    if TRACK.exists():
        ct = json.loads(TRACK.read_text(encoding="utf-8"))
        default, violations = track_order(items, seq_default, terms, index, ct)
        gate_ok = ct.get("gate_ok")
    order_by_sequence = seq_default + [i for i in default if i not in set(seq_default)]   # holes at the end
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
    kinds = {k: sum(1 for i in items.values() if i["kind"] == k) for k in ("term", "artifact", "void", "hole")}
    lanes = {k: sum(1 for i in items.values() if i.get("lane") == k) for k in ("track", "branch", "hole", "unread")}
    return {"_doc": "The construction path: from the point to the last Ada object. GENERATED by tools/construction_path.py "
                    "(items); the ORDER is authored when `authored` is true (saved from /construction-path) and kept by the tool. "
                    "The default order is the main track (commons/data/capacity_track.json), each step followed by its branches.",
            "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"), "authored": bool(authored), "edited_at": edited,
            "counts": kinds, "lanes": lanes, "gate_ok": gate_ok, "violations": violations,
            "order": order, "order_by_sequence": order_by_sequence, "items": items}


def main() -> int:
    doc = build()
    OUT.write_text(json.dumps(doc, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    c, ln = doc["counts"], doc["lanes"]
    print(f"wrote {OUT.relative_to(ROOT)} — {len(doc['order'])} steps: {c['term']} terms, {c['artifact']} artifacts, {c['void']} Void works, {c['hole']} holes"
          f"{' (authored order kept)' if doc['authored'] else ' (default order)'}; first: {doc['order'][:4]} … last: {doc['order'][-1]}")
    print(f"lanes: {ln['track']} on the track, {ln['branch']} branches, {ln['hole']} holes, {ln['unread']} unread; gate {'OK' if doc['gate_ok'] else doc['gate_ok']}")
    for v in doc["violations"]:
        print("  VIOLATION", v)
    return 1 if doc["violations"] else 0


if __name__ == "__main__":
    sys.exit(main())
