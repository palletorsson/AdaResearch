#!/usr/bin/env python3
"""WHAT EACH ARTIFACT IS TO ITS MAP — primary, secondary, decoration.

    python tools/artifact_roles.py --stats
    python tools/artifact_roles.py --seq primitives
    python tools/artifact_roles.py --seq primitives --json        # what the page serves
    python tools/artifact_roles.py --set --map Point_One --token folding_past --role secondary

2026-09-04, Palle: "not all artifacts are part of the main order. Some are heroes,
others are siblings and others are decoration or substrates ... the hero artifact
will be the main starting point for making the book. We need to move many
artifacts from the main red thread."

THE THREE ROLES, and why the default is `primary`.

    primary     carries the map's argument; the text is about it.
    secondary   stands in the map and is met, but the text does not turn on it.
    decoration  props, substrates, furniture. Present, not addressed.

HERO IS NOT A COLUMN HERE (removed 2026-09-04 at Palle's word). The book already
names one per pearl — 218 of 269 — and that is where it belongs; re-sorting it in
a triage board would give the same fact two owners that can disagree. Cards the
book calls hero still carry a star, so the information is on screen without being
something you drag.

Everything unruled defaults to `primary`, because that is the state the corpus is
actually in: every placement is implicitly in the red thread today, and the work
Palle described is DEMOTION — moving many artifacts out of it. A default of
`decoration` would silently empty the thread and call it progress.

GROUPS (2026-09-04, Palle: "Some artifacts should be understood as a group").
A column can hold named boxes, and a card can sit in one. A group belongs to a
(map, role) pair — move a card to another column and it leaves the group, because
"the three verbs" is a claim about works standing together IN THAT ROLE, not a
label that follows one of them into the props.

    groups: {"<Map>": [{"id": "...", "title": "...", "role": "primary"}]}

ORDER (2026-09-04, "the order within the primary group should also matter").
Cards arrive in map row-major order — the order you meet them walking in — and
that is a fact about the floor, not about the argument. A bucket (a column, or a
box inside one) can carry an explicit sequence, because the book reads them in
that order:

    order: {"<Map>": {"primary": [...], "primary|the-3d-coordinate-system": [...]}}

Only what has been deliberately arranged is recorded; anything not in the list
follows it, still in map order. So an untouched bucket has no entry at all rather
than a frozen copy of the floor.

A ruling is either a bare role string (the original shape, still written when
there is no group) or {"role": ..., "group": "<id>"}. Both are read; the string
form is kept for the ungrouped majority so the file does not double in size to
record a null.

WHY THE RULINGS ARE KEYED (map, token) AND NOT BY TOKEN ALONE. The same artifact
is a different thing in different rooms: fontana_puncture is the subject in one
map and a prop in the next. 909 distinct tokens fill 1601 placements across 213
spine maps, so a token-keyed file would collapse 692 of those judgements.
"""
from __future__ import annotations

import argparse
import io
import json
import os
import re
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MAPS = ROOT / "commons" / "maps"
SPINE = ROOT / "commons" / "data" / "spine_artifact_order.json"
BOOK = ROOT / "commons" / "data" / "book"
ROLES = ROOT / "commons" / "data" / "artifact_roles.json"
SHOTS = Path(os.environ.get("APPDATA", "")) / "Godot" / "app_userdata" / \
    "Ada Research Zero One" / "multi_shots"
# THE SECOND PICTURE STORE, and it is the bigger one. multi_shots holds 504 of the
# 909 spine tokens; the encyclopedia's scene-catalog holds 3232 flat <token>.png
# files and covers 360 of the 405 multi_shots misses — 88% of the gap, with no
# Godot run. Checking one store and calling the rest uncaptured was wrong about
# 40% of the board.
CATALOG = Path(os.environ.get("ADA_ENCYCLOPEDIA_PATH",
                              str(ROOT.parent / "ada_encyclopedia"))) / "public" / "scene-catalog"

REGISTRY = ROOT / "commons" / "artifacts" / "registry"
ROLE_NAMES = ["primary", "secondary", "decoration"]
DEFAULT_ROLE = "primary"


def load_roles() -> dict:
    if ROLES.exists():
        try:
            return json.loads(ROLES.read_text(encoding="utf-8"))
        except Exception:  # noqa: BLE001
            pass
    return {"_meta": {}, "roles": {}, "groups": {}, "order": {}, "notes": {}}


def read_ruling(v) -> tuple[str, str]:
    """A ruling is a bare role string, or {role, group}. Both shapes are live —
    the string is kept for the ungrouped majority so the file does not double in
    size to record a null. Returns (role, group_id)."""
    if isinstance(v, dict):
        r = str(v.get("role", ""))
        return (r if r in ROLE_NAMES else DEFAULT_ROLE, str(v.get("group", "")))
    r = str(v) if v is not None else ""
    return (r if r in ROLE_NAMES else DEFAULT_ROLE, "")


def save_roles(doc: dict) -> None:
    doc["_meta"] = {
        "written": date.today().isoformat(),
        "writer": "tools/artifact_roles.py",
        "roles": ROLE_NAMES,
        "default": DEFAULT_ROLE,
        "note": "keyed (map, token) — the same artifact is a different thing in "
                "different rooms; unruled placements are primary",
    }
    ROLES.parent.mkdir(parents=True, exist_ok=True)
    ROLES.write_text(json.dumps(doc, indent=1, ensure_ascii=False) + "\n",
                     encoding="utf-8", newline="\n")


def book_heroes() -> dict[str, str]:
    """The hero each book pearl already names, by map. 218 of 269 have one."""
    out: dict[str, str] = {}
    if not BOOK.is_dir():
        return out
    for p in sorted(BOOK.glob("*.json")):
        try:
            d = json.loads(p.read_text(encoding="utf-8"))
        except Exception:  # noqa: BLE001
            continue
        for pl in d.get("pearls", []) or []:
            h = pl.get("hero")
            m = pl.get("map")
            if h and m:
                out[m] = str(h)
    return out


def spine() -> tuple[list[str], dict[str, str]]:
    """Maps in spine order, and each map's sequence. Order is the whole point:
    this is the walk, not an alphabetical list."""
    d = json.loads(SPINE.read_text(encoding="utf-8"))
    order: list[str] = []
    seq_of: dict[str, str] = {}
    for r in d.get("order", []):
        m = r.get("map")
        if m and m not in seq_of:
            seq_of[m] = r.get("sequence", "")
            order.append(m)
    return order, seq_of


def placements(map_name: str) -> list[dict]:
    """Every interactable in one map, in row-major order — the order you meet
    them walking in. Duplicates of a token collapse to one card: a role is a
    judgement about the WORK, not about each copy of it."""
    p = MAPS / map_name / "map_data.json"
    if not p.exists():
        return []
    try:
        layers = json.loads(p.read_text(encoding="utf-8")).get("layers", {})
    except Exception:  # noqa: BLE001
        return []
    seen: dict[str, dict] = {}
    for r, row in enumerate(layers.get("interactables", []) or []):
        for c, cell in enumerate(row):
            v = str(cell).strip()
            if not v or v == "-":
                continue
            tok = v.split(":")[0].split("#")[0]
            if not tok:
                continue
            if tok in seen:
                seen[tok]["count"] += 1
                continue
            src = shot_src(tok)
            seen[tok] = {"token": tok, "row": r, "col": c, "count": 1,
                         "shot": src != "", "shot_src": src}
    return list(seen.values())


# ── ADDING ONE ────────────────────────────────────────────────────────────────


def shot_src(token: str) -> str:
    if (SHOTS / token / "front.png").is_file():
        return "multi"
    if (CATALOG / (token + ".png")).is_file():
        return "catalog"
    return ""


def registry_index() -> dict[str, dict]:
    """Every artifact the corpus knows, by lookup name. 227 files, each
    {"artifacts": {token: {...}}} — read once, not per query."""
    out: dict[str, dict] = {}
    if not REGISTRY.is_dir():
        return out
    for p in sorted(REGISTRY.glob("*.json")):
        try:
            d = json.loads(p.read_text(encoding="utf-8"))
        except Exception:  # noqa: BLE001
            continue
        for tok, v in (d.get("artifacts") or {}).items():
            if not isinstance(v, dict) or tok in out:
                continue
            scene = str(v.get("scene") or "")
            # 622 of 2974 entries carry no category, or the word "unknown".
            # Naming the folder is at least true; "unknown" on a tile tells
            # you nothing and reads as a fault in the picker.
            cat = str(v.get("category") or "").strip()
            if cat in ("", "unknown"):
                seg = scene.replace("res://", "").rsplit("/", 1)[0].split("/")
                cat = "/".join(seg[-2:]) if len(seg) >= 2 else (seg[0] if seg else p.stem)
            out[tok] = {
                "token": tok,
                "name": str(v.get("name") or tok),
                "category": cat,
                "scene": scene,
                "dir": scene.rsplit("/", 1)[0] if "/" in scene else "",
                "ready": bool(v.get("map_ready", True)),
                "type": str(v.get("artifact_type") or ""),
                "description": str(v.get("description") or "")[:400],
            }
    return out


def map_grid(map_name: str) -> dict:
    p = MAPS / map_name / "map_data.json"
    if not p.exists():
        return {}
    try:
        return json.loads(p.read_text(encoding="utf-8")).get("layers", {}) or {}
    except Exception:  # noqa: BLE001
        return {}


def _cell(layer: list, r: int, c: int) -> str:
    if r < 0 or r >= len(layer):
        return ""
    row = layer[r]
    if c < 0 or c >= len(row):
        return ""
    v = str(row[c]).strip()
    return "" if v in ("-", " ") else v


def standable(h: str) -> bool:
    """The pathfinder's own vocabulary: 'w' is wall, 'p'/'p:N' a platform, a
    number is a height and 0 is void. Anything you can stand on is > 0."""
    v = str(h).strip()
    if v == "w":
        return False
    if v == "p" or v.startswith("p:"):
        return True
    try:
        return int(v) > 0
    except (ValueError, TypeError):
        return False


def free_cells(map_name: str, limit: int = 40) -> list[dict]:
    """Cells an artifact could take: floor, empty of interactables AND of
    utilities (a spawn, teleporter or hazard is not free ground), ranked by how
    close they stand to something already placed — a neighbour of a reachable
    cell is the least likely to strand anything. The pathfinder still decides;
    this only proposes."""
    L = map_grid(map_name)
    struct = L.get("structure") or []
    ints = L.get("interactables") or []
    utils = L.get("utilities") or []
    taken = [(r, c) for r, row in enumerate(ints)
             for c in range(len(row)) if _cell(ints, r, c)]
    out: list[dict] = []
    for r, row in enumerate(struct):
        for c in range(len(row)):
            if not standable(_cell(struct, r, c)):
                continue
            if _cell(ints, r, c) or _cell(utils, r, c):
                continue
            d = min((abs(r - tr) + abs(c - tc) for tr, tc in taken), default=99)
            out.append({"row": r, "col": c, "near": d,
                        "height": _cell(struct, r, c)})
    # a neighbour of a placed work first, but never ON it; ties by reading order
    out.sort(key=lambda x: (0 if x["near"] == 1 else 1, x["near"], x["row"], x["col"]))
    return out[:limit]


def candidates(map_name: str, q: str = "", limit: int = 80) -> dict:
    """Artifacts NOT in this map, ranked by this map's own vocabulary first.

    Palle, 2026-09-04, asked for related to mean "same map": the works that
    share a scene directory or a registry category with what already stands
    here. That is the hall's dialect, and it is a better first guess than
    anything alphabetical."""
    if not (MAPS / map_name / "map_data.json").exists():
        return {"ok": False, "error": "no such map: %s" % map_name}
    reg = registry_index()
    here = {c["token"] for c in placements(map_name)}
    dirs = {reg[t]["dir"] for t in here if t in reg and reg[t]["dir"]}
    cats = {reg[t]["category"] for t in here if t in reg}
    words = [w for w in re.split(r"[^a-z0-9]+", q.lower()) if w]

    items: list[dict] = []
    for tok, v in reg.items():
        if tok in here:
            continue
        hay = (tok + " " + v["name"] + " " + v["category"] + " "
               + v["description"]).lower()
        if words and not all(w in hay for w in words):
            continue
        why = []
        score = 0
        if v["dir"] and v["dir"] in dirs:
            score += 3
            why.append("same folder as a work here")
        if v["category"] in cats:
            score += 1
            why.append("same category")
        if words:
            # a name match beats a description match, so typing a token finds it
            if tok.lower().startswith(words[0]):
                score += 4
            elif words[0] in v["name"].lower():
                score += 2
        src = shot_src(tok)
        items.append({**v, "score": score, "why": why, "related": score > 0,
                      "shot": src != "", "shot_src": src})
    items.sort(key=lambda x: (-x["score"], 0 if x["shot"] else 1,
                              0 if x["ready"] else 1, x["token"]))
    return {"ok": True, "map": map_name, "placed": sorted(here),
            "total": len(items), "items": items[:limit],
            "cells": free_cells(map_name)}


def board(only_seq: str = "") -> dict:
    order, seq_of = spine()
    heroes = book_heroes()
    _doc = load_roles()
    ruled = _doc.get("roles", {})
    grouped = _doc.get("groups", {})
    ordering = _doc.get("order", {})
    noted = _doc.get("notes", {})
    seqs: list[dict] = []
    by_seq: dict[str, list[dict]] = {}
    counts = {r: 0 for r in ROLE_NAMES}
    shots = 0
    total = 0

    for m in order:
        s = seq_of.get(m, "")
        if only_seq and s != only_seq:
            continue
        cards = placements(m)
        if not cards:
            continue
        mr = ruled.get(m, {})
        hero_tok = heroes.get(m, "")
        mg = [g for g in (grouped.get(m) or []) if g.get("role") in ROLE_NAMES]
        mn = [x for x in (noted.get(m) or []) if x.get("role") in ROLE_NAMES]
        for c in cards:
            # an explicit ruling always wins; everything else starts in the thread
            role, grp = read_ruling(mr.get(c["token"]))
            # a group deleted under a card, or one that belongs to another column,
            # leaves the card loose rather than invisible
            if grp and not any(g["id"] == grp and g["role"] == role for g in mg):
                grp = ""
            c["role"] = role
            c["group"] = grp
            c["ruled"] = c["token"] in mr
            c["from_book"] = (c["token"] == hero_tok)
            counts[role] += 1
            total += 1
            if c["shot"]:
                shots += 1
        # arrange each bucket: the recorded sequence first, then whatever has
        # never been arranged, still in the order you meet it walking in
        mo = ordering.get(m, {})
        if mo:
            buckets: dict[str, list[dict]] = {}
            for c in cards:
                buckets.setdefault(bucket_key(c["role"], c["group"]), []).append(c)
            arranged: list[dict] = []
            for bk, group_cards in buckets.items():
                want = mo.get(bk) or []
                by_tok = {c["token"]: c for c in group_cards}
                first = [by_tok.pop(t) for t in want if t in by_tok]
                arranged.extend(first)
                arranged.extend(c for c in group_cards if c["token"] in by_tok)
            cards = arranged
        for g in mg:
            g["count"] = sum(1 for c in cards if c["group"] == g["id"])
        # ONE ORDERED RUN PER COLUMN — boxes and loose cards in the sequence the
        # writer set. Anything never arranged follows, boxes first, then cards in
        # the order you meet them walking in.
        layout: dict[str, list[dict]] = {}
        for role in ROLE_NAMES:
            want = (mo.get(role) or []) if mo else []
            boxes = [g["id"] for g in mg if g["role"] == role]
            notes = {x["id"]: x for x in mn if x["role"] == role}
            loose = [c["token"] for c in cards
                     if c["role"] == role and not c["group"]]
            run: list[dict] = []
            seen_i: set[str] = set()

            def _note(nid: str) -> dict:
                return {"kind": "note", "id": nid, "text": notes[nid]["text"]}

            for t in want:
                if t in seen_i:
                    continue
                if t.startswith("@") and t[1:] in boxes:
                    run.append({"kind": "group", "id": t[1:]}); seen_i.add(t)
                elif t.startswith("#") and t[1:] in notes:
                    run.append(_note(t[1:])); seen_i.add(t)
                elif t in loose:
                    run.append({"kind": "card", "token": t}); seen_i.add(t)
            for b in boxes:
                if ("@" + b) not in seen_i:
                    run.append({"kind": "group", "id": b})
            for nid in notes:
                if ("#" + nid) not in seen_i:
                    run.append(_note(nid))
            for t in loose:
                if t not in seen_i:
                    run.append({"kind": "card", "token": t})
            layout[role] = run
        by_seq.setdefault(s, []).append({"map": m, "cards": cards, "groups": mg,
                                         "notes": mn, "layout": layout})

    for s, maps in by_seq.items():
        seqs.append({"seq": s, "maps": maps,
                     "placements": sum(len(x["cards"]) for x in maps)})
    return {
        "sequences": seqs,
        "roles": ROLE_NAMES,
        "totals": {"maps": sum(len(s["maps"]) for s in seqs), "placements": total,
                   "with_shot": shots, "by_role": counts,
                   "ruled": sum(len(v) for v in ruled.values())},
    }


def overview() -> dict:
    """Sequence list with counts — what the page loads first, so 1601 cards are
    never all on screen at once."""
    order, seq_of = spine()
    heroes = book_heroes()
    _doc = load_roles()
    ruled = _doc.get("roles", {})
    grouped = _doc.get("groups", {})
    noted = _doc.get("notes", {})
    agg: dict[str, dict] = {}
    for m in order:
        s = seq_of.get(m, "")
        cards = placements(m)
        if not cards:
            continue
        a = agg.setdefault(s, {"seq": s, "maps": 0, "placements": 0, "ruled": 0,
                               "hero": 0, "groups": 0, "notes": 0})
        a["maps"] += 1
        a["placements"] += len(cards)
        mr = ruled.get(m, {})
        a["ruled"] += sum(1 for c in cards if c["token"] in mr)
        a["groups"] += len(grouped.get(m) or [])
        a["notes"] += len(noted.get(m) or [])
        if heroes.get(m):
            a["hero"] += 1
    return {"sequences": list(agg.values()), "roles": ROLE_NAMES}


def bucket_key(role: str, group: str) -> str:
    """A bucket is a column, or one box inside a column."""
    return role + "|" + group if group else role


def set_order(map_name: str, role: str, group: str, tokens: list[str]) -> dict:
    """The page sends the WHOLE new sequence for one bucket, not an index move.
    A bucket holds a handful of cards, so shipping the list is atomic and there
    is no index arithmetic to disagree about between the two ends."""
    if role not in ROLE_NAMES:
        return {"ok": False, "error": "role must be one of %s" % ROLE_NAMES}
    doc = load_roles()
    if group:
        ok = any(g.get("id") == group and g.get("role") == role
                 for g in doc.get("groups", {}).get(map_name, []))
        if not ok:
            return {"ok": False, "error": "no group %s in %s/%s" % (group, map_name, role)}
    live = {c["token"] for c in placements(map_name)}
    # A COLUMN'S SEQUENCE CAN NAME A BOX. "@<group-id>" is the box's place in the
    # run, so a group sits between loose cards instead of always on top — which
    # is what "the group should also be in the order" asks for. Inside a box the
    # entries are cards only; a box cannot contain a box.
    gids = {g["id"] for g in doc.get("groups", {}).get(map_name, [])
            if g.get("role") == role}
    nids = {x["id"] for x in doc.get("notes", {}).get(map_name, [])
            if x.get("role") == role}

    def _known(t: str) -> bool:
        if t.startswith("@"):
            return t[1:] in gids
        if t.startswith("#"):
            return t[1:] in nids
        return t in live

    keep = [t for t in tokens if _known(t)]
    if len(keep) != len(tokens):
        return {"ok": False, "error": "some entries are not in %s/%s" % (map_name, role)}
    if group and any(t[:1] in "@#" for t in keep):
        return {"ok": False, "error": "a box holds works only"}
    rooms = doc.setdefault("order", {})
    room = rooms.setdefault(map_name, {})
    if keep:
        room[bucket_key(role, group)] = keep
    else:
        room.pop(bucket_key(role, group), None)
    save_roles(doc)
    return {"ok": True, "map": map_name, "role": role, "group": group, "order": keep}


def _slug(t: str) -> str:
    out = re.sub(r"[^a-z0-9]+", "-", t.lower()).strip("-")
    return out[:32] or "group"


def new_group(map_name: str, role: str, title: str) -> dict:
    """A named box inside one column. The id is derived from the title but never
    changes with it — a rename must not orphan every card pointing at it."""
    if role not in ROLE_NAMES:
        return {"ok": False, "error": "role must be one of %s" % ROLE_NAMES}
    title = title.strip()
    if not title:
        return {"ok": False, "error": "a group needs a title"}
    if not (MAPS / map_name / "map_data.json").exists():
        return {"ok": False, "error": "no such map: %s" % map_name}
    doc = load_roles()
    rooms = doc.setdefault("groups", {})
    lst = rooms.setdefault(map_name, [])
    base = _slug(title)
    gid = base
    n = 2
    while any(g.get("id") == gid for g in lst):
        gid = "%s-%d" % (base, n)
        n += 1
    lst.append({"id": gid, "title": title, "role": role})
    save_roles(doc)
    return {"ok": True, "map": map_name, "group": gid, "title": title, "role": role}


def rename_group(map_name: str, gid: str, title: str) -> dict:
    title = title.strip()
    if not title:
        return {"ok": False, "error": "a group needs a title"}
    doc = load_roles()
    for g in doc.get("groups", {}).get(map_name, []):
        if g.get("id") == gid:
            g["title"] = title
            save_roles(doc)
            return {"ok": True, "map": map_name, "group": gid, "title": title}
    return {"ok": False, "error": "no group %s in %s" % (gid, map_name)}


def delete_group(map_name: str, gid: str) -> dict:
    """Deleting a box does not delete its cards — they fall loose in the same
    column. A group is a reading of works, not a container that owns them."""
    doc = load_roles()
    lst = doc.get("groups", {}).get(map_name, [])
    keep = [g for g in lst if g.get("id") != gid]
    if len(keep) == len(lst):
        return {"ok": False, "error": "no group %s in %s" % (gid, map_name)}
    doc["groups"][map_name] = keep
    freed = 0
    for tok, v in list(doc.get("roles", {}).get(map_name, {}).items()):
        role, grp = read_ruling(v)
        if grp == gid:
            doc["roles"][map_name][tok] = role   # back to the bare string form
            freed += 1
    save_roles(doc)
    return {"ok": True, "map": map_name, "group": gid, "freed": freed}


# ── NOTES ─────────────────────────────────────────────────────────────────────
# The relation, in words. A role is a fact about ONE work; a note is a fact about
# several, and it is the half the writer cannot get from the floor. It belongs to
# a (map, column) pair and takes a place in that column's run, so it stands next
# to the works it is about. There can be as many as the reading needs.


def _note_id(lst: list[dict]) -> str:
    n = 1
    while any(x.get("id") == "note-%d" % n for x in lst):
        n += 1
    return "note-%d" % n


def new_note(map_name: str, role: str, text: str) -> dict:
    """A new note lands at the END of the column and freezes the run as it
    stands — appending to a sequence nobody has arranged would otherwise
    reshuffle everything around it the first time the column is ordered."""
    if role not in ROLE_NAMES:
        return {"ok": False, "error": "role must be one of %s" % ROLE_NAMES}
    text = text.strip()
    if not text:
        return {"ok": False, "error": "a note needs something to say"}
    if not (MAPS / map_name / "map_data.json").exists():
        return {"ok": False, "error": "no such map: %s" % map_name}
    doc = load_roles()
    lst = doc.setdefault("notes", {}).setdefault(map_name, [])
    nid = _note_id(lst)
    lst.append({"id": nid, "role": role, "text": text})
    save_roles(doc)
    # record the run it can see, with the note last
    run = [it["token"] if it["kind"] == "card"
           else ("@" + it["id"] if it["kind"] == "group" else "#" + it["id"])
           for it in run_of(map_name, role)]
    set_order(map_name, role, "", run)
    return {"ok": True, "map": map_name, "note": nid, "role": role, "text": text}


def edit_note(map_name: str, nid: str, text: str) -> dict:
    text = text.strip()
    if not text:
        return {"ok": False, "error": "a note needs something to say"}
    doc = load_roles()
    for x in doc.get("notes", {}).get(map_name, []):
        if x.get("id") == nid:
            x["text"] = text
            save_roles(doc)
            return {"ok": True, "map": map_name, "note": nid, "text": text}
    return {"ok": False, "error": "no note %s in %s" % (nid, map_name)}


def delete_note(map_name: str, nid: str) -> dict:
    doc = load_roles()
    lst = doc.get("notes", {}).get(map_name, [])
    keep = [x for x in lst if x.get("id") != nid]
    if len(keep) == len(lst):
        return {"ok": False, "error": "no note %s in %s" % (nid, map_name)}
    doc["notes"][map_name] = keep
    # and out of every run that named it, or the order carries a ghost
    room = doc.get("order", {}).get(map_name, {})
    for bk, seq in list(room.items()):
        if ("#" + nid) in seq:
            room[bk] = [t for t in seq if t != "#" + nid]
    save_roles(doc)
    return {"ok": True, "map": map_name, "note": nid}


def run_of(map_name: str, role: str) -> list[dict]:
    """One column's run — the same list the board draws, for callers that only
    want the arrangement and not the whole sequence."""
    for s in board().get("sequences", []):
        for m in s["maps"]:
            if m["map"] == map_name:
                return m["layout"].get(role) or []
    return []


def room(map_name: str) -> dict:
    """ONE MAP AS JSON, the row the board draws: cards (with role, group and the
    book's hero mark), the boxes, and each column's RUN as kinds - card, group,
    note - in the arranged order. This is the necklace page's data (2026-09-05,
    Palle: "artifacts, group and text ... a connected 2d graph ... beads on a
    necklace"). It is the same row _map_brief renders, so the page and the
    writer's outline cannot disagree about the arrangement."""
    order, seq_of = spine()
    for s in board(seq_of.get(map_name, "")).get("sequences", []):
        for m in s["maps"]:
            if m["map"] == map_name:
                out = dict(m)
                out["seq"] = s.get("seq", seq_of.get(map_name, ""))
                out["ok"] = True
                return out
    return {"ok": False, "error": "no such map on the spine: %s" % map_name}


def brief_seq(seq_id: str, only_role: str = "") -> str:
    """Every map in one sequence, read down. This is what a writer opens before
    a session: the arrangement and the relation notes for a whole arc."""
    b = board(seq_id)
    maps = [m for s in b.get("sequences", []) for m in s["maps"]]
    if not maps:
        return "no maps on the spine for sequence: %s" % seq_id
    out = ["# %s" % seq_id, "",
           "%d maps, %d placements." % (len(maps),
                                        sum(len(m["cards"]) for m in maps)), ""]
    for m in maps:
        out.append(_map_brief(m, only_role, level=2))
    return "\n".join(x for x in out if x is not None).rstrip() + "\n"


def brief_all() -> str:
    """The spine as a table — which sequences have been arranged and which have
    not been touched. `ruled` is the only honest progress number here: a role
    nobody set is not a judgement, it is a default."""
    d = overview()
    rows = sorted(d.get("sequences", []), key=lambda x: -x["placements"])
    out = ["# Spine roles", "",
           "What each artifact is to its map. `ruled` counts hand judgements;",
           "everything else sits at the default (primary).", "",
           "| sequence | maps | works | ruled | boxes | notes |",
           "|---|--:|--:|--:|--:|--:|"]
    for r in rows:
        out.append("| %s | %d | %d | %d | %d | %d |"
                   % (r["seq"], r["maps"], r["placements"], r["ruled"],
                      r.get("groups", 0), r.get("notes", 0)))
    t = [sum(r[k] for r in rows) for k in ("maps", "placements", "ruled")]
    out += ["| **all** | **%d** | **%d** | **%d** | **%d** | **%d** |"
            % (t[0], t[1], t[2], sum(r.get("groups", 0) for r in rows),
               sum(r.get("notes", 0) for r in rows)), "",
            "`?seq=<id>&format=markdown` for one arc, "
            "`?map=<Name>&format=markdown` for one hall."]
    return "\n".join(out) + "\n"


def _map_brief(rows: dict, only_role: str = "", level: int = 1) -> str:
    """One map's columns as an outline: notes as paragraphs, a box as a heading
    with its works under it, in the arranged order rather than walk order."""
    h = "#" * level
    out = ["%s %s" % (h, rows["map"]), ""]
    for role in ROLE_NAMES:
        if only_role and role != only_role:
            continue
        run = rows["layout"].get(role) or []
        if not run:
            continue
        out.append("%s %s" % (h + "#", role))
        out.append("")
        for it in run:
            if it["kind"] == "note":
                # a paragraph glued to the list above it is a list item in
                # every markdown reader, which is not what the note is
                if out and out[-1]:
                    out.append("")
                out.append(it["text"])
                out.append("")
            elif it["kind"] == "card":
                out.append("- %s" % it["token"])
            else:
                g = next((x for x in rows["groups"] if x["id"] == it["id"]), None)
                out.append("- **%s**" % (g["title"] if g else it["id"]))
                inside = [c["token"] for c in rows["cards"]
                          if c["role"] == role and c["group"] == it["id"]]
                out.extend("  - %s" % t for t in inside)
        out.append("")
    if len(out) == 2:
        return "%s %s\n\n_nothing arranged yet._\n" % (h, rows["map"])
    return "\n".join(out)


def brief(map_name: str, only_role: str = "") -> str:
    """One map. Kept as its own entry point because it is the writer's most
    common call — `--map <X> --brief` before writing that room's final.md."""
    for s in board().get("sequences", []):
        for m in s["maps"]:
            if m["map"] == map_name:
                return _map_brief(m, only_role).rstrip() + "\n"
    return "no such map on the spine: %s" % map_name


def set_role(map_name: str, token: str, role: str, group: str | None = None) -> dict:
    if role not in ROLE_NAMES:
        return {"ok": False, "error": "role must be one of %s" % ROLE_NAMES}
    if not (MAPS / map_name / "map_data.json").exists():
        return {"ok": False, "error": "no such map: %s" % map_name}
    toks = {c["token"] for c in placements(map_name)}
    if token not in toks:
        return {"ok": False, "error": "%s is not placed in %s" % (token, map_name)}

    doc = load_roles()
    rooms = doc.setdefault("roles", {})
    room = rooms.setdefault(map_name, {})
    # group=None means "leave whatever grouping it had"; "" clears it
    keep = read_ruling(room.get(token))[1] if group is None else group
    if keep:
        ok = any(g.get("id") == keep and g.get("role") == role
                 for g in doc.get("groups", {}).get(map_name, []))
        if not ok:
            # a card cannot carry a group that belongs to another column
            keep = ""
    room[token] = {"role": role, "group": keep} if keep else role
    save_roles(doc)
    return {"ok": True, "map": map_name, "token": token, "role": role, "group": keep}


def main() -> int:
    ap = argparse.ArgumentParser(description="artifact roles across the spine")
    ap.add_argument("--seq", default="")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--stats", action="store_true")
    ap.add_argument("--set", action="store_true")
    ap.add_argument("--map", default="")
    ap.add_argument("--token", default="")
    ap.add_argument("--role", default="")
    ap.add_argument("--group", default=None,
                    help="with --set: join this group, or \"\" to leave one")
    ap.add_argument("--new-group", metavar="TITLE")
    ap.add_argument("--rename-group", metavar="TITLE")
    ap.add_argument("--delete-group", action="store_true")
    ap.add_argument("--set-order", metavar="TOKENS",
                    help="comma-separated new sequence for one bucket")
    ap.add_argument("--note", default="",
                    help="a note id, for --edit-note and --delete-note")
    ap.add_argument("--new-note", metavar="TEXT",
                    help="say what these works are to each other")
    ap.add_argument("--edit-note", metavar="TEXT")
    ap.add_argument("--delete-note", action="store_true")
    ap.add_argument("--candidates", action="store_true",
                    help="artifacts NOT in --map, ranked by the map's own vocabulary")
    ap.add_argument("--q", default="", help="search filter for --candidates")
    ap.add_argument("--room", action="store_true",
                    help="one map as JSON: cards, boxes, and each column's run - the necklace page's data")
    ap.add_argument("--brief", action="store_true",
                    help="read one map's columns down, notes and all — for the writer")
    args = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")

    if args.set_order is not None:
        if not (args.map and args.role):
            ap.error("--set-order needs --map and --role")
        toks = [t.strip() for t in args.set_order.split(",") if t.strip()]
        res = set_order(args.map, args.role, args.group or "", toks)
        print(json.dumps(res, ensure_ascii=False))
        return 0 if res.get("ok") else 1

    if args.new_note:
        if not (args.map and args.role):
            ap.error("--new-note needs --map and --role")
        res = new_note(args.map, args.role, args.new_note)
        print(json.dumps(res, ensure_ascii=False))
        return 0 if res.get("ok") else 1

    if args.edit_note:
        if not (args.map and args.note):
            ap.error("--edit-note needs --map and --note")
        res = edit_note(args.map, args.note, args.edit_note)
        print(json.dumps(res, ensure_ascii=False))
        return 0 if res.get("ok") else 1

    if args.delete_note:
        if not (args.map and args.note):
            ap.error("--delete-note needs --map and --note")
        res = delete_note(args.map, args.note)
        print(json.dumps(res, ensure_ascii=False))
        return 0 if res.get("ok") else 1

    if args.candidates:
        if not args.map:
            ap.error("--candidates needs --map")
        res = candidates(args.map, args.q)
        if args.json or True:
            print(json.dumps(res, ensure_ascii=False))
        return 0 if res.get("ok") else 1

    if args.room:
        if not args.map:
            ap.error("--room needs --map")
        res = room(args.map)
        print(json.dumps(res, ensure_ascii=False))
        return 0 if res.get("ok") else 1

    if args.brief:
        if args.map:
            print(brief(args.map, args.role))
        elif args.seq:
            print(brief_seq(args.seq, args.role))
        else:
            print(brief_all())
        return 0

    if args.new_group:
        if not (args.map and args.role):
            ap.error("--new-group needs --map and --role")
        res = new_group(args.map, args.role, args.new_group)
        print(json.dumps(res, ensure_ascii=False))
        return 0 if res.get("ok") else 1

    if args.rename_group:
        if not (args.map and args.group):
            ap.error("--rename-group needs --map and --group")
        res = rename_group(args.map, args.group, args.rename_group)
        print(json.dumps(res, ensure_ascii=False))
        return 0 if res.get("ok") else 1

    if args.delete_group:
        if not (args.map and args.group):
            ap.error("--delete-group needs --map and --group")
        res = delete_group(args.map, args.group)
        print(json.dumps(res, ensure_ascii=False))
        return 0 if res.get("ok") else 1

    if args.set:
        if not (args.map and args.token and args.role):
            ap.error("--set needs --map, --token and --role")
        res = set_role(args.map, args.token, args.role, args.group)
        print(json.dumps(res, ensure_ascii=False))
        return 0 if res.get("ok") else 1

    if args.stats or (not args.seq and not args.json):
        b = board()
        t = b["totals"]
        print("SPINE ROLES — %d maps, %d placements, %d ruled by hand"
              % (t["maps"], t["placements"], t["ruled"]))
        print("  captures available: %d of %d (%d%%)"
              % (t["with_shot"], t["placements"],
                 100 * t["with_shot"] // max(1, t["placements"])))
        print()
        for r in ROLE_NAMES:
            n = t["by_role"][r]
            print("  %-11s %4d  %s" % (r, n, "#" * (n * 40 // max(1, t["placements"]))))
        print()
        for s in sorted(b["sequences"], key=lambda x: -x["placements"])[:10]:
            print("  %-24s %3d maps  %4d placements" % (s["seq"], len(s["maps"]), s["placements"]))
        return 0

    data = board(args.seq) if args.seq else overview()
    if args.json:
        print(json.dumps(data, ensure_ascii=False))
        return 0
    for s in data.get("sequences", []):
        if "maps" in s and isinstance(s["maps"], list):
            print("\n== %s" % s["seq"])
            for mm in s["maps"]:
                by = {}
                for c in mm["cards"]:
                    by.setdefault(c["role"], []).append(c["token"])
                print("  %-32s %s" % (mm["map"], " · ".join(
                    "%s %d" % (r, len(by.get(r, []))) for r in ROLE_NAMES if by.get(r))))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
