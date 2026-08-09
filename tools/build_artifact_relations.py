#!/usr/bin/env python3
"""
build_artifact_relations.py — how every DNA-gallery artifact relates to every
spine artifact, as TYPED edges.

WHY MORE THAN ONE SIGNAL. The obvious source is the @identity `relationships:`
field, and it is the weakest thing that looks strong: 16,697 words across 1,100
artifacts, of which only 2,113 (13%) resolve to a real registry token. The rest
is prose — "paired with", "central to every QFEP map" — excellent for a reader
and useless for a placer. So five signals are gathered and each edge carries its
KIND, because the kind is what decides the placement grammar:

  named      an @identity relationships field names the other token.
             AUTHORED intent. Placement: put it in the sightline — the author
             already said these two are about each other.
  sibling    same scene file, different registry token (the corpus's most common
             hidden family — curation_station's booleans, the grab spheres, the
             pickup cubes). Placement: a ROW or a set. Siblings shown apart read
             as unrelated; shown together they read as a vocabulary.
  axis_kin   both declare an axis of the SAME NAME (two artifacts that can each
             argue `pose`, or `housing`, or `register`). This is the strongest
             signal nobody authored: it means two objects can make the same
             ARGUMENT. Placement: adjacent, at DIFFERENT values, so the room
             stages a comparison rather than a repetition.
  co_placed  already stand in >= 1 map together. Empirically compatible; costs
             nothing to trust.
  family     same registry category and same declared sequence. Weak, wide, and
             only used to pad a thin room.

MULTIPLES ARE A FIRST-CLASS RESULT. The AAA critique named density as the single
biggest tell ("a 2 m2 wall crop contains exactly one feature; a player reads
BLOCKOUT before they read materials"). An artifact with declared axes can be
placed MORE THAN ONCE at different values — that is what a family is for, and
`same_token_multiples` reports how many distinct values each spine artifact
could legitimately show at once.

Output: commons/data/artifact_relations.json
  { spine_artifact: { multiples: N, relations: [ {token, kind, why, dna} ] } }

  python tools/build_artifact_relations.py
  python tools/build_artifact_relations.py --token=random_walk_bench
"""
from __future__ import annotations
import argparse
import glob
import json
import os
import re
import sys
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
OUT = os.path.join(ROOT, "commons", "data", "artifact_relations.json")


def load_registry() -> dict:
    reg = {}
    for f in glob.glob(os.path.join(ROOT, "commons", "artifacts", "registry", "*.json")):
        try:
            arts = json.load(open(f, encoding="utf-8")).get("artifacts", {})
        except (json.JSONDecodeError, OSError):
            continue
        for k, v in arts.items():
            if isinstance(v, dict):
                reg[k] = v
    return reg


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--token", default="")
    a = ap.parse_args()

    reg = load_registry()
    toks = set(reg)
    dna = {k: v["dna"]["axes"] for k, v in reg.items()
           if isinstance(v.get("dna"), dict) and v["dna"].get("axes")}

    # ── signal 1: authored relationships that resolve
    named = defaultdict(set)
    for k, v in reg.items():
        p = str(v.get("scene", "")).replace("res://", "").replace(".tscn", ".gd")
        fp = os.path.join(ROOT, p)
        if not os.path.exists(fp):
            continue
        try:
            t = open(fp, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        m = re.search(r"#\s*relationships:\s*(.+)", t)
        if not m:
            continue
        for w in re.findall(r"[A-Za-z_][A-Za-z0-9_]{3,}", m.group(1)):
            if w in toks and w != k:
                named[k].add(w)
                named[w].add(k)          # relatedness is symmetric even when the note is not

    # ── signal 2: siblings (one scene, many registry names)
    by_scene = defaultdict(set)
    for k, v in reg.items():
        s = str(v.get("scene", "")).strip()
        if s:
            by_scene[s].add(k)
    sibling = defaultdict(set)
    for s, ks in by_scene.items():
        if len(ks) > 1:
            for k in ks:
                sibling[k] |= (ks - {k})

    # ── signal 3: axis kin (both can make the same argument)
    axis_owners = defaultdict(set)
    for k, ax in dna.items():
        for name in ax:
            axis_owners[name].add(k)
    axis_kin = defaultdict(set)
    for name, ks in axis_owners.items():
        if 1 < len(ks) <= 40:            # an axis on 200 artifacts says nothing
            for k in ks:
                axis_kin[k] |= (ks - {k})

    # ── signal 4: co-placement in the shipped corpus
    co = defaultdict(lambda: defaultdict(int))
    for md in glob.glob(os.path.join(ROOT, "commons", "maps", "*", "map_data.json")):
        try:
            d = json.load(open(md, encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            continue
        cast = set()
        for row in d.get("layers", {}).get("interactables", []):
            for c in row:
                t = str(c).split("#")[0].split(":")[0].strip()
                if t in toks:
                    cast.add(t)
        cast = list(cast)
        for i in range(len(cast)):
            for j in range(i + 1, len(cast)):
                co[cast[i]][cast[j]] += 1
                co[cast[j]][cast[i]] += 1

    # ── signal 5: family (category + sequence)
    fam = defaultdict(set)
    key_of = {}
    for k, v in reg.items():
        key_of[k] = (str(v.get("category", "")), str(v.get("sequence", "")))
    byfam = defaultdict(set)
    for k, kk in key_of.items():
        if kk[0] or kk[1]:
            byfam[kk].add(k)
    for kk, ks in byfam.items():
        if 1 < len(ks) <= 30:
            for k in ks:
                fam[k] |= (ks - {k})

    # ── the spine's own artifacts, in walk order
    order_p = os.path.join(ROOT, "commons", "data", "spine_artifact_order.json")
    spine_tokens = []
    if os.path.exists(order_p):
        spine_tokens = [r["lookup"] for r in
                        json.load(open(order_p, encoding="utf-8")).get("order", [])]

    out = {}
    for tok in spine_tokens:
        rels = {}

        def add(other: str, kind: str, why: str) -> None:
            if other == tok or other not in reg:
                return
            if other in rels:               # first (strongest) kind wins
                return
            rels[other] = {"token": other, "kind": kind, "why": why,
                           "dna": sorted(dna.get(other, {}).keys()),
                           "placements_together": co[tok].get(other, 0)}

        for o in sorted(named.get(tok, ())):
            add(o, "named", "an @identity relationships field names it")
        for o in sorted(sibling.get(tok, ())):
            add(o, "sibling", "same scene file, different registry name")
        for o in sorted(axis_kin.get(tok, ())):
            shared = sorted(set(dna.get(tok, {})) & set(dna.get(o, {})))
            add(o, "axis_kin", "can argue the same axis: " + ", ".join(shared))
        for o, n in sorted(co.get(tok, {}).items(), key=lambda x: -x[1])[:12]:
            add(o, "co_placed", f"already stand together in {n} map(s)")
        for o in sorted(fam.get(tok, ()))[:12]:
            add(o, "family", "same category and sequence")

        my_axes = dna.get(tok, {})
        multiples = max([len(v) for v in my_axes.values()] or [1])
        out[tok] = {"multiples": multiples,
                    "axes": {k: list(v) for k, v in my_axes.items()},
                    "relations": sorted(rels.values(),
                                        key=lambda r: (["named", "sibling", "axis_kin",
                                                        "co_placed", "family"].index(r["kind"]),
                                                       -r["placements_together"]))}

    if a.token:
        r = out.get(a.token)
        if not r:
            print(f"{a.token}: not a spine artifact")
            return 1
        print(f"{a.token}  multiples={r['multiples']}  axes={list(r['axes'])}")
        for x in r["relations"][:20]:
            print(f"  {x['kind']:10} {x['token']:34} {x['why'][:58]}")
        return 0

    kinds = defaultdict(int)
    for v in out.values():
        for r in v["relations"]:
            kinds[r["kind"]] += 1
    json.dump({"_readme": "How every DNA-gallery artifact relates to each spine artifact, "
                          "as typed edges. kind decides the placement grammar: named -> "
                          "sightline, sibling -> row, axis_kin -> adjacent at DIFFERENT "
                          "values, co_placed -> already proven, family -> padding only. "
                          "multiples = how many distinct values this artifact could show "
                          "at once (a family exists to be seen more than once).",
               "spine_artifacts": len(out), "edges_by_kind": dict(kinds), "artifacts": out},
              open(OUT, "w", encoding="utf-8"), indent=1)
    print(f"spine artifacts .... {len(out)}")
    for k in ("named", "sibling", "axis_kin", "co_placed", "family"):
        print(f"  {k:10} {kinds[k]}")
    multi = sum(1 for v in out.values() if v["multiples"] > 1)
    print(f"can show >1 value .. {multi}")
    print(f"-> {os.path.relpath(OUT, ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
