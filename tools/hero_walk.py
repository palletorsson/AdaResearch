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


def main() -> int:
    ch = sys.argv[1] if len(sys.argv) > 1 else "noise"
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
