#!/usr/bin/env python3
"""The trunk and its branches — the corpus as a brain, not a list.

    TRUNK    the curriculum's 24 sequences in taxonomy order (point -> line ->
             ... -> noise -> L-systems -> ... -> halting): stable, complete,
             walkable end to end. Each node names its HERO(ES).
    BRANCHES typed edges (anchor, token, kind, why, provenance) that grow off
             a trunk node without ever breaking the walk:
               extends      a relative that pushes the thesis further
               edge         the value the node cannot hold (a DNA end the
                            critic called dead, a body the negotiator refused
                            as a world)
               contradicts  the antithesis — the contradiction hidden in it
               queers       the queer possibility — the reading that undoes
                            the category
               synthesizes  thesis + antithesis made (a dna.sources artifact)
               varies       the same token at another DNA value (context)

This script DERIVES what the corpus already knows (provenance "derived"):
heroes from the dig policy, extends from named/family relations, synthesizes
from dna.sources, edge from plan refusals, varies from declared DNA axes.
It NEVER writes contradicts or queers — those are readings, hand-authored on
/trunk with provenance "hand" — and it never overwrites a hand branch: on
reseed, derived branches are refreshed, hand branches are kept verbatim.

    python tools/build_trunk_branches.py           # seed / reseed
    python tools/build_trunk_branches.py --node noise --show
"""
from __future__ import annotations

import argparse
import glob
import json
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "commons" / "data" / "trunk_branches.json"
SPINE = REPO / "commons" / "maps" / "curriculum_spine.json"
ORDER = REPO / "commons" / "data" / "spine_artifact_order.json"
POLICIES = REPO / "commons" / "data" / "artifact_order_policies.json"
RELATIONS = REPO / "commons" / "data" / "artifact_relations.json"
PLAN = REPO / "ada_run" / "em_plan.json"
REGISTRY = REPO / "commons" / "artifacts" / "registry"

KINDS = ["extends", "edge", "contradicts", "queers", "synthesizes", "varies"]
#: how much SPACE a branch asks of the corridor. wall = a remark on the node
#: (label / hung showing / mounted body on the corridor's own wall); alcove =
#: floor but not distance (rung 1's bay, opened off the corridor); room = a
#: side room off the enfilade, entered, threshold label = the reading. Derived
#: branches default to wall; the hand raises it.
SPACES = ["wall", "alcove", "room"]


def load(p: Path):
    return json.loads(p.read_text(encoding="utf-8"))


def registry_artifacts() -> dict[str, dict]:
    out: dict[str, dict] = {}
    for f in glob.glob(str(REGISTRY / "*.json")):
        try:
            d = json.loads(Path(f).read_text(encoding="utf-8"))
        except Exception:
            continue

        def walk(dd: dict):
            for k, v in dd.items():
                if isinstance(v, dict):
                    if "lookup_name" in v or "scene" in v:
                        out.setdefault(k, v)
                    else:
                        walk(v)
        walk(d)
    return out


def derive() -> dict:
    spine = load(SPINE)["spine"]["sequences"]
    trunk_names = [s["name"] for s in spine]
    order = load(ORDER)["order"]
    dig = load(POLICIES)["policies"]["dig"]
    rel = load(RELATIONS)["artifacts"]
    plan = load(PLAN) if PLAN.exists() else {"plans": []}
    reg = registry_artifacts()

    tokens_of: dict[str, list[str]] = {n: [] for n in trunk_names}
    seq_of: dict[str, str] = {}
    for r in order:
        if r["sequence"] in tokens_of:
            tokens_of[r["sequence"]].append(r["lookup"])
            seq_of.setdefault(r["lookup"], r["sequence"])

    trunk = []
    for i, s in enumerate(spine):
        n = s["name"]
        heroes = [r["lookup"] for r in dig if r["sequence"] == n and r["why"] == "load-bearing"]
        promoted = [r["lookup"] for r in dig if r["sequence"] == n and r["why"] == "promoted from depth"]
        trunk.append({"node": n, "index": i, "phase": s.get("phase", ""), "qfep_role": s.get("qfep_role", ""),
                      "heroes": heroes, "promoted": promoted, "tokens": len(tokens_of[n])})

    branches: list[dict] = []
    seen: set[tuple] = set()

    def add(anchor: str, token: str, kind: str, why: str, via: str = ""):
        key = (anchor, token, kind)
        if key in seen or token == anchor:
            return
        seen.add(key)
        branches.append({"anchor": anchor, "token": token, "kind": kind, "why": why,
                         "via": via, "provenance": "derived", "space": "wall"})

    # extends: named / family relations from a node's tokens to tokens NOT of the node
    for n in trunk_names:
        for t in tokens_of[n]:
            for e in rel.get(t, {}).get("relations", []):
                if e.get("kind") in ("named", "family"):
                    tgt = e["token"]
                    if seq_of.get(tgt) != n:      # a branch reaches OUT of the node
                        add(n, tgt, "extends", f"{e['kind']} relation of {t}: {e.get('why', '')[:80]}", via=t)
    # synthesizes: dna.sources touching the node's tokens
    for tok, v in reg.items():
        dna = v.get("dna") if isinstance(v.get("dna"), dict) else {}
        srcs = dna.get("sources") or []
        if not srcs:
            continue
        for n in trunk_names:
            hit = [s for s in srcs if s in tokens_of[n]]
            if hit:
                add(n, tok, "synthesizes", f"synthesis of {len(srcs)} sources, {len(hit)} from this node: {', '.join(hit[:4])}", via=hit[0])
    # edge: the negotiator's refusals in this node's chapter
    for p in plan.get("plans", []):
        n = p.get("sequence")
        if n not in tokens_of:
            continue
        for r in p.get("rejected", []):
            why = str(r.get("why", ""))
            add(n, r["token"], "edge", f"the museum could not hold it: {why[:110]}")
    # varies: declared DNA axes on the node's own tokens (context exploration)
    for n in trunk_names:
        for t in tokens_of[n]:
            axes = rel.get(t, {}).get("axes") or {}
            for ax, vals in axes.items():
                if isinstance(vals, list) and len(vals) >= 2:
                    add(n, t, "varies", f"{ax}: {' / '.join(str(v) for v in vals[:6])}", via=ax)

    return {"trunk": trunk, "branches": branches}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--node", default="")
    ap.add_argument("--show", action="store_true")
    a = ap.parse_args()

    prev = load(OUT) if OUT.exists() else {"branches": []}
    hand = [b for b in prev.get("branches", []) if b.get("provenance") == "hand"]
    hand_keys = {(b["anchor"], b["token"], b["kind"]) for b in hand}
    hand_drops = set(tuple(x) for x in prev.get("dropped", []))   # derived branches the hand dropped

    d = derive()
    derived = [b for b in d["branches"]
               if (b["anchor"], b["token"], b["kind"]) not in hand_keys
               and (b["anchor"], b["token"], b["kind"]) not in hand_drops]
    # heroes: hand-set hero on a node wins over dig
    hand_heroes = prev.get("hand_heroes", {})
    for t in d["trunk"]:
        if t["node"] in hand_heroes:
            t["hero_hand"] = hand_heroes[t["node"]]

    doc = {
        "schema": "adaresearch.trunk_branches.v1",
        "_readme": ("The trunk (curriculum in taxonomy order, with heroes) and its typed branches. "
                    "Derived branches are refreshed by tools/build_trunk_branches.py; hand branches "
                    "(provenance hand) and hand drops are kept verbatim. contradicts / queers are "
                    "NEVER derived — they are readings, authored on /trunk."),
        "generated": datetime.now().isoformat(timespec="seconds"),
        "kinds": KINDS,
        "spaces": SPACES,
        "trunk": d["trunk"],
        "branches": derived + hand,
        "dropped": sorted([list(x) for x in hand_drops]),
        "hand_heroes": hand_heroes,
        "counts": {"trunk": len(d["trunk"]), "derived": len(derived), "hand": len(hand),
                   "by_kind": {k: sum(1 for b in derived + hand if b["kind"] == k) for k in KINDS}},
    }
    OUT.write_text(json.dumps(doc, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"trunk {len(d['trunk'])} nodes · branches {len(derived)} derived + {len(hand)} hand -> {OUT.relative_to(REPO)}")
    print("  by kind:", doc["counts"]["by_kind"])
    if a.node:
        node = next((t for t in d["trunk"] if t["node"] == a.node), None)
        print(f"\n== {a.node}: heroes {node['heroes'] if node else '?'} promoted {node['promoted'] if node else '?'}")
        for k in KINDS:
            bs = [b for b in doc["branches"] if b["anchor"] == a.node and b["kind"] == k]
            print(f"  {k:12s} {len(bs)}")
            if a.show:
                for b in bs[:8]:
                    print(f"     {b['token']:32s} {b['why'][:70]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
