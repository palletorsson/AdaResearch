#!/usr/bin/env python3
"""The hero's walk — a chapter's cast read from the trunk, when the hand has
spoken.

A chapter whose trunk node has a HERO and at least one HAND branch is dealt
as the hero's walk instead of the whole spine list:

    hero                         the thesis, first
    extends      (thesis field)  relatives that push it — on the axis
    varies       (context)       DNA values — the wall series
    edge         (the limit)     what it cannot hold — the court, the joint
    contradicts  (antithesis)    the reading that negates — across the room
    queers       (the possible)  the reading that undoes the category
    synthesizes  (synthesis)     thesis + antithesis made — the threshold

in that order, each body carrying its KIND into the plan (`walk_kind`) so
the assembler can honour it. Nothing here places; it names the cast and why.

GATE: no hero, or no hand branch on the node -> returns None and the caller
builds exactly as before. The hand's presence is the switch, on purpose:
a derived-only walk would just be the spine list re-sorted, and the whole
point is that a curator has READ the node.

    python tools/hero_walk.py noise         # print the walk, or why there is none
"""
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parent.parent
TRUNK = REPO / "commons" / "data" / "trunk_branches.json"

WALK_ORDER = ["hero", "extends", "varies", "edge", "contradicts", "queers", "synthesizes"]
#: how many derived branches of each kind ride along with the hand's — a walk
#: is a sequence, not a census. Hand branches always ride.
DERIVED_CAP = {"extends": 6, "varies": 4, "edge": 3, "synthesizes": 3, "contradicts": 0, "queers": 0}


def load_trunk() -> dict[str, Any] | None:
    try:
        return json.loads(TRUNK.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None


def hero_walk(chapter: str, trunk: dict[str, Any] | None = None) -> dict[str, Any] | None:
    """The cast for `chapter` as the hero's walk, or None (build as before)."""
    trunk = trunk if trunk is not None else load_trunk()
    if not trunk:
        return None
    node = next((t for t in trunk.get("trunk", []) if t.get("node") == chapter), None)
    if not node:
        return None
    hero = node.get("hero_hand") or (node.get("heroes") or [None])[0]
    if not hero:
        return None
    branches = [b for b in trunk.get("branches", []) if b.get("anchor") == chapter]
    hand = [b for b in branches if b.get("provenance") == "hand"]
    if not hand:
        return None                     # THE GATE: no reading, no walk

    cast: list[dict[str, Any]] = [{"lookup": hero, "walk_kind": "hero", "why": "the hero — the thesis", "provenance": "trunk"}]
    seen = {hero}
    for kind in WALK_ORDER[1:]:
        rows = [b for b in branches if b.get("kind") == kind]
        rows.sort(key=lambda b: (0 if b.get("provenance") == "hand" else 1))   # hand first
        cap = DERIVED_CAP.get(kind, 4)
        n_derived = 0
        for b in rows:
            tok = b.get("token")
            if not tok:
                continue
            # a token may hold TWO roles when the hand says so — the hero can
            # be its own contradiction (white noise: the signal with no signal).
            # The trial found this: the hero's hand-authored contradicts was
            # dropped as "already seen". Hand rows re-enter; derived don't.
            if tok in seen and b.get("provenance") != "hand":
                continue
            if b.get("provenance") != "hand":
                if n_derived >= cap:
                    continue
                n_derived += 1
            seen.add(tok)
            cast.append({"lookup": tok, "walk_kind": kind, "why": b.get("why", ""),
                         "provenance": b.get("provenance", "derived"), "via": b.get("via", ""),
                         "space": b.get("space", "wall")})
    # the negotiator places a token once; a second role is carried as the
    # row's `also` so the plan (and the room) can say the hero is ALSO the
    # antithesis, without dealing it twice
    uniq: list[str] = []
    for c in cast:
        if c["lookup"] not in uniq:
            uniq.append(c["lookup"])
    return {"chapter": chapter, "hero": hero, "hand_branches": len(hand),
            "cast": uniq, "rows": cast,
            "why": (f"the hero's walk: {hero} + {len(cast) - 1} branches "
                    f"({len(hand)} hand-authored) instead of the {node.get('tokens', '?')}-token spine list")}


# ── the pearls' walks (2026-08-18) ────────────────────────────────────
#
# A node is a STRING of heroes (build_trunk_pearls.py): its maps in book
# order, each with a hero and sibling tokens. The museum builds ONE SEGMENT
# PER PEARL, so each pearl casts its own walk: hero first, then its own
# siblings (walk_kind "sibling" — the map's bodies, spine order), then the
# branches anchored on that pearl in the same kind order as hero_walk. NO
# HAND GATE here: the string IS the maps, which the book already walks, so
# a pearl walks whether or not anyone has read it yet; a hand branch on the
# pearl enriches the walk instead of switching it on.
SIBLING_CAP = 12       # a 20-token map (primitives/ignorance) still fits its segment


def pearl_walks(chapter: str, trunk: dict[str, Any] | None = None) -> list[dict[str, Any]]:
    """One walk per pearl of `chapter`, in string order; [] when the node has no pearls."""
    trunk = trunk if trunk is not None else load_trunk()
    if not trunk:
        return []
    node = next((t for t in trunk.get("trunk", []) if t.get("node") == chapter), None)
    if not node or not node.get("pearls"):
        return []
    branches = [b for b in trunk.get("branches", []) if b.get("anchor") == chapter]
    walks: list[dict[str, Any]] = []
    pearls_all = list(node["pearls"])
    for pi, p in enumerate(pearls_all):
        name = p.get("pearl", "")
        if p.get("join") and pi > 0:
            continue                       # a page of the pearl before: dealt there (see below)
        hero = p.get("hero") or (p.get("tokens") or [""])[0]
        if not hero:
            continue
        if p.get("ordered"):
            # THE POEM IS THE CAST: the hand's order, every token, no derived
            # branch or relation added — what is a line is in the hall, in that
            # order (tools/em_speak.py, /speak). Hand branches still ride.
            rows_o: list[dict[str, Any]] = []
            foyer = set(p.get("foyer", []))
            for tok in p.get("tokens", []):
                if tok in foyer:
                    continue                       # the foyer's lines: placed by the lobby builder
                rows_o.append({"lookup": tok, "walk_kind": "hero" if tok == hero else "sibling",
                               "why": f"a line of the {name} poem", "provenance": "hand", "space": "wall",
                               **({"support_m": float(p["supports"][tok])} if (p.get("supports") or {}).get(tok) else {}),
                               **({"lock": list(p["locks"][tok])} if (p.get("locks") or {}).get(tok) else {}),
                               **({"config": dict(p["configs"][tok])} if (p.get("configs") or {}).get(tok) else {}),
                               **({"pose": dict(p["poses"][tok])} if (p.get("poses") or {}).get(tok) else {}),
                               **({"footprint": list(p["footprints"][tok])} if (p.get("footprints") or {}).get(tok) else {}),
                               **({"reach": dict(p["reaches"][tok])} if (p.get("reaches") or {}).get(tok) else {}),
                               **({"count": dict(p["counts"][tok])} if (p.get("counts") or {}).get(tok) else {})})
            for b in branches:
                if b.get("pearl") == name and b.get("provenance") == "hand" and b.get("token") and b["token"] not in p.get("tokens", []):
                    rows_o.append({"lookup": b["token"], "walk_kind": b.get("kind", "extends"), "why": b.get("why", ""), "provenance": "hand",
                                   "via": b.get("via", ""), "space": b.get("space", "wall")})
            # the pages that join this pearl's hall: their lines follow, in order
            pages = [{"pearl": name, "tokens": [r["lookup"] for r in rows_o]}]
            rooms_total = int(p.get("rooms") or 0)
            excl = set(p.get("excluded", []))
            q_i = pi + 1
            while q_i < len(pearls_all) and pearls_all[q_i].get("join"):
                q = pearls_all[q_i]
                q_foyer = set(q.get("foyer", []))
                q_toks = [t for t in q.get("tokens", []) if t not in q_foyer]
                for tok in q_toks:
                    if tok in [r["lookup"] for r in rows_o]:
                        continue
                    rows_o.append({"lookup": tok, "walk_kind": "sibling", "why": f"a line of the {q.get('pearl')} page", "provenance": "hand", "space": "wall", "page": q.get("pearl"),
                                   **({"support_m": float(q["supports"][tok])} if (q.get("supports") or {}).get(tok) else {}),
                                   **({"lock": list(q["locks"][tok])} if (q.get("locks") or {}).get(tok) else {}),
                                   **({"config": dict(q["configs"][tok])} if (q.get("configs") or {}).get(tok) else {}),
                                   **({"pose": dict(q["poses"][tok])} if (q.get("poses") or {}).get(tok) else {}),
                                   **({"footprint": list(q["footprints"][tok])} if (q.get("footprints") or {}).get(tok) else {}),
                                   **({"reach": dict(q["reaches"][tok])} if (q.get("reaches") or {}).get(tok) else {}),
                                   **({"count": dict(q["counts"][tok])} if (q.get("counts") or {}).get(tok) else {})})
                pages.append({"pearl": q.get("pearl"), "tokens": q_toks, "map": q.get("map", "")})
                rooms_total += int(q.get("rooms") or 0)
                excl |= set(q.get("excluded", []))
                q_i += 1
            excl -= {r["lookup"] for r in rows_o}     # a line of any page in this hall is never excluded by another page
            walks.append({"chapter": chapter, "pearl": name, "pearl_index": int(p.get("index", len(walks))), "map": p.get("map", ""),
                          "stages": list(p.get("stages", [])), "gaps": list(p.get("gaps", [])), "ramps": list(p.get("ramps", [])),
                          "rooms": (rooms_total or p.get("rooms")), "exclude": sorted(excl), "ordered": True, "pages": pages,
                          "hero": hero, "hand_branches": sum(1 for r in rows_o if r["walk_kind"] not in ("hero", "sibling")),
                          "cast": [r["lookup"] for r in rows_o], "rows": rows_o,
                          "why": f"pearl {name}: the poem's order, {len(rows_o)} lines" + (f", {len(pages)} pages" if len(pages) > 1 else "")})
            continue
        rows: list[dict[str, Any]] = [{"lookup": hero, "walk_kind": "hero", "why": f"the hero of {name} ({p.get('hero_by', '')})", "provenance": "trunk", "space": "wall"}]
        seen = {hero}
        sib = 0
        for tok in p.get("tokens", []):
            if tok in seen or sib >= SIBLING_CAP:
                continue
            seen.add(tok); sib += 1
            rows.append({"lookup": tok, "walk_kind": "sibling", "why": f"a body of the {name} pearl ({p.get('map', '')})", "provenance": "map", "space": "wall"})
        # branches on THIS pearl — plus the un-pearled ones (a hand reading
        # written on the node before pearls existed, or a derived branch whose
        # via-token is not in any map): they ride with the pearl that holds
        # their via, else the pearl that holds the node's hero, else the first
        mine = [b for b in branches if b.get("pearl") == name]
        for b in branches:
            if b.get("pearl"):
                continue
            via = b.get("via") or ""
            home = None
            for q in node["pearls"]:
                if via and via in (q.get("tokens") or []):
                    home = q.get("pearl"); break
            if home is None:
                node_hero = node.get("hero_hand") or (node.get("heroes") or [""])[0]
                for q in node["pearls"]:
                    if node_hero and node_hero in (q.get("tokens") or []):
                        home = q.get("pearl"); break
            if home is None:
                home = node["pearls"][0].get("pearl")
            if home == name:
                mine.append(b)
        hand = [b for b in mine if b.get("provenance") == "hand"]
        for kind in WALK_ORDER[1:]:
            ks = [b for b in mine if b.get("kind") == kind]
            ks.sort(key=lambda b: (0 if b.get("provenance") == "hand" else 1))
            cap = DERIVED_CAP.get(kind, 4)
            n_der = 0
            for b in ks:
                tok = b.get("token")
                if not tok:
                    continue
                if tok in seen and b.get("provenance") != "hand":
                    continue
                if b.get("provenance") != "hand":
                    if n_der >= cap:
                        continue
                    n_der += 1
                seen.add(tok)
                rows.append({"lookup": tok, "walk_kind": kind, "why": b.get("why", ""), "provenance": b.get("provenance", "derived"),
                             "via": b.get("via", ""), "space": b.get("space", "wall")})
        uniq: list[str] = []
        for r in rows:
            if r["lookup"] not in uniq:
                uniq.append(r["lookup"])
        walks.append({"chapter": chapter, "pearl": name, "pearl_index": int(p.get("index", len(walks))), "map": p.get("map", ""), "stages": list(p.get("stages", [])), "gaps": list(p.get("gaps", [])), "ramps": list(p.get("ramps", [])), "rooms": p.get("rooms"), "exclude": list(p.get("excluded", [])),
                      "hero": hero, "hand_branches": len(hand), "cast": uniq, "rows": rows,
                      "why": f"pearl {name}: {hero} + {sib} siblings + {len(rows) - 1 - sib} branches ({len(hand)} hand)"})
    return walks


def main() -> int:
    ch = sys.argv[1] if len(sys.argv) > 1 else "noise"
    if len(sys.argv) > 2 and sys.argv[2] == "--pearls":
        ws = pearl_walks(ch)
        if not ws:
            print(f"{ch}: no pearls (run tools/build_trunk_pearls.py)"); return 1
        for w in ws:
            print(f"{w['pearl_index'] + 1:2d}. {w['why']}")
            for r in w["rows"]:
                print(f"      {r['walk_kind']:12s} {r['lookup']:34s} {r['provenance']:8s} {r['why'][:60]}")
        return 0
    w = hero_walk(ch)
    if not w:
        t = load_trunk()
        node = next((x for x in (t or {}).get("trunk", []) if x.get("node") == ch), None)
        hand = [b for b in (t or {}).get("branches", []) if b.get("anchor") == ch and b.get("provenance") == "hand"]
        print(f"{ch}: NO WALK — hero {node.get('heroes') if node else '?'}, hand branches {len(hand)}. "
              f"The chapter builds from the spine list as before. Author a contradicts/queers branch on /trunk to switch.")
        return 1
    print(w["why"])
    for r in w["rows"]:
        print(f"  {r['walk_kind']:12s} {r['lookup']:34s} {r['provenance']:8s} {r['why'][:70]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
