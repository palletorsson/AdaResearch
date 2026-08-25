#!/usr/bin/env python3
"""THE FOLD LEDGER — fold a sequence by ARTIFACT, not by map.

2026-08-25, Palle: "in Vectors & Forces there are too many maps but we do not
want to lose any essential artifacts. Is there any good way to do this?"

There is, and this is it. A map-first fold asks "which rooms can go?" and
answers from taste. An artifact-first fold asks "where does every token live
afterwards?" and answers from a set difference, which is checkable. Nothing is
lost quietly, because losing something quietly is what the exit code is for.

    python tools/fold_ledger.py --sequence=forces --keep=A,B,C
    python tools/fold_ledger.py --sequence=forces --plan=doc/folds/forces.json
    python tools/fold_ledger.py --sequence=forces --plan=... --check

An ORPHAN is a token placed in a dropped map and in no kept map. Every orphan
must appear in the plan with one of three verdicts:

    rescue  <map>       place it in a kept map — the map is named, and --check
                        fails until the token is actually in that map's grid
    rehome  <sequence>  it belongs to another sequence; the plan says which
    retire  <reason>    a test scene, a duplicate, or furniture — say what
                        supersedes it

TWO THINGS THAT MADE THE FIRST COUNT WRONG, both measured on forces:

1. DELEGATES. vector_dot_product_xl is a registry entry with no scene of its
   own and `delegate_to: VectorDotProduct` — the walk-inside 5x version of the
   algorithm scene. Five capitalised tokens read as orphans until the delegate
   edge was followed; they had been in the kept maps the whole time. A ledger
   that cannot see through a delegate invents losses and hides real ones.
2. UTILITY CODES. `3t` is a utility cell, not an artifact. A token that no
   registry knows is not an orphan, it is a parse error, and it is reported
   separately so it can never be silently "rehomed".
"""
from __future__ import annotations

import argparse
import glob
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VERDICTS = ("rescue", "rehome", "retire")


def load_registry():
    """token -> entry, across every registry file (they are token-keyed dicts
    under an `artifacts` key; a few older files are flat)."""
    reg = {}
    for path in glob.glob(os.path.join(ROOT, "commons", "artifacts", "registry", "*.json")):
        try:
            with open(path, encoding="utf-8") as fh:
                doc = json.load(fh)
        except Exception:
            continue
        arts = doc.get("artifacts") if isinstance(doc.get("artifacts"), dict) else doc
        if not isinstance(arts, dict):
            continue
        for tok, entry in arts.items():
            if not isinstance(entry, dict):
                continue
            # RICHER WINS, not first (2026-08-25). substrate_vectors.json is a
            # FLAT registry file — no `artifacts` wrapper — so under first-wins
            # its thin entries shadowed 127 real ones. No delegate_to edge was
            # affected, so no verdict in this ledger changed, but the loader is
            # the same one and would have been wrong the moment one was.
            old = reg.get(tok)
            if old is None or (len(entry) > len(old) and "delegate_to" not in old):
                reg[tok] = entry
    return reg


def delegates_of(tok, reg, seen=None):
    """Every token this one stands in for, transitively. An XL exhibit that
    delegates to an algorithm scene KEEPS THAT SCENE PLACED."""
    seen = seen or set()
    out = set()
    entry = reg.get(tok) or {}
    target = entry.get("delegate_to")
    if isinstance(target, str) and target and target not in seen:
        seen.add(target)
        out.add(target)
        out |= delegates_of(target, reg, seen)
    return out


def map_tokens(name):
    path = os.path.join(ROOT, "commons", "maps", name, "map_data.json")
    if not os.path.exists(path):
        return None
    with open(path, encoding="utf-8") as fh:
        doc = json.load(fh)
    out = []
    for row in doc.get("layers", {}).get("interactables", []):
        for cell in row:
            text = str(cell).strip()
            if text:
                out.append(text.split("#")[0].split(":")[0])
    return out


def corpus_homes(tokens, exclude):
    """How many OTHER maps in the whole corpus place each token. A retire
    verdict is only honest when this number is known."""
    counts = {t: 0 for t in tokens}
    for path in glob.glob(os.path.join(ROOT, "commons", "maps", "*", "map_data.json")):
        name = os.path.basename(os.path.dirname(path))
        if name in exclude:
            continue
        try:
            with open(path, encoding="utf-8") as fh:
                doc = json.load(fh)
        except Exception:
            continue
        seen = set()
        for row in doc.get("layers", {}).get("interactables", []):
            for cell in row:
                text = str(cell).strip()
                if text:
                    seen.add(text.split("#")[0].split(":")[0])
        for tok in seen & set(counts):
            counts[tok] += 1
    return counts


def sequence_maps(seq_id):
    path = os.path.join(ROOT, "commons", "maps", "sequences", "%s.json" % seq_id)
    with open(path, encoding="utf-8") as fh:
        doc = json.load(fh)
    seqs = doc["sequences"]
    block = seqs[0] if isinstance(seqs, list) else list(seqs.values())[0]
    names = []
    for entry in block.get("maps", []):
        names.append(entry if isinstance(entry, str)
                     else (entry.get("map_id") or entry.get("name") or entry.get("id")))
    return [n for n in names if n]


def build(seq_id, keep, plan):
    reg = load_registry()
    every = sequence_maps(seq_id)
    if plan and not keep:
        keep = plan.get("keep", [])
    keep = [m for m in (keep or []) if m]
    drop = [m for m in every if m not in keep]
    # a plan may name maps outside the sequence (forces held Vectors_Intro,
    # which lives in the deprecated vectors.json)
    for extra in (plan or {}).get("also_drop", []):
        if extra not in drop:
            drop.append(extra)

    covered, unknown = set(), set()
    for name in keep:
        toks = map_tokens(name)
        if toks is None:
            print("  !! kept map missing on disk: %s" % name)
            continue
        for tok in toks:
            covered.add(tok)
            covered |= delegates_of(tok, reg)
            if tok not in reg:
                unknown.add(tok)

    homes = {}
    for name in drop:
        toks = map_tokens(name)
        if toks is None:
            continue
        for tok in set(toks):
            homes.setdefault(tok, []).append(name)

    orphans, not_artifacts = {}, {}
    for tok, where in homes.items():
        if tok in covered:
            continue
        (not_artifacts if tok not in reg else orphans)[tok] = where
    return reg, keep, drop, covered, orphans, not_artifacts, unknown


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--sequence", required=True)
    ap.add_argument("--keep", default="", help="comma-separated maps to keep")
    ap.add_argument("--plan", default="", help="a fold plan JSON")
    ap.add_argument("--check", action="store_true",
                    help="exit non-zero unless every orphan has a verdict AND every "
                         "rescue is actually placed")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    plan = {}
    if args.plan:
        with open(os.path.join(ROOT, args.plan), encoding="utf-8") as fh:
            plan = json.load(fh)
    keep = [m.strip() for m in args.keep.split(",") if m.strip()]
    reg, keep, drop, covered, orphans, not_arts, unknown = build(args.sequence, keep, plan)

    verdicts = plan.get("verdicts", {})
    missing = sorted(t for t in orphans if t not in verdicts)
    unplaced = []
    for tok, spec in verdicts.items():
        parts = str(spec).split() if isinstance(spec, str) else []
        kind = parts[0] if parts else ""
        target = parts[1] if len(parts) > 1 else ""
        if kind == "rescue":
            if tok not in (map_tokens(target) or []):
                unplaced.append((tok, target))
        elif kind == "rehome":
            # A REHOME IS A PROMISE UNTIL THE DESTINATION PLACES IT. Naming a
            # sequence is not a home; triangle_curvature_workbench was rehomed
            # to computationalgeometry while standing in no map in the corpus,
            # which is an orphan wearing a destination label.
            room = parts[2] if len(parts) > 2 else ""
            if room:
                # the verdict names the ROOM, which is the only form that can
                # be checked without guessing
                if tok not in (map_tokens(room) or []):
                    unplaced.append((tok, "%s / %s (room does not place it)" % (target, room)))
                continue
            try:
                dest = sequence_maps(target)
            except Exception:
                unplaced.append((tok, "%s (no such sequence)" % target))
                continue
            if not any(tok in (map_tokens(m) or []) for m in dest):
                unplaced.append((tok, "%s (sequence places it nowhere)" % target))

    if args.json:
        print(json.dumps({"keep": keep, "drop": drop, "covered": len(covered),
                          "orphans": orphans, "not_artifacts": sorted(not_arts),
                          "unjudged": missing, "unplaced": unplaced}, indent=1))
    else:
        print("FOLD LEDGER — %s" % args.sequence)
        print("  keep %d map(s), drop %d — kept maps cover %d token(s) "
              "(delegates followed)" % (len(keep), len(drop), len(covered)))
        if unknown:
            print("  !! %d kept token(s) in NO registry: %s" % (len(unknown), ", ".join(sorted(unknown))))
        print("  orphans: %d" % len(orphans))
        elsewhere = corpus_homes(set(orphans), set(keep) | set(drop))
        for tok in sorted(orphans):
            spec = verdicts.get(tok, "-- NO VERDICT --")
            seqs = ",".join((reg.get(tok) or {}).get("map_sequences", []) or [])
            # THE CORPUS IS THE REAL DENOMINATOR: a token that stands in forty
            # other maps is not lost when this sequence stops placing it, and
            # saying so is the difference between a judgement and a fact.
            print("    %-46s %-30s %3d elsewhere  [%s]" % (tok, spec, elsewhere.get(tok, 0), seqs[:26]))
        if not_arts:
            print("  not artifacts (utility codes, never orphans): %s" % ", ".join(sorted(not_arts)))
        if missing:
            print("\n  %d ORPHAN(S) WITH NO VERDICT — the fold would lose them:" % len(missing))
            for tok in missing:
                print("    %-46s last seen in %s" % (tok, ", ".join(orphans[tok])))
        if unplaced:
            print("\n  %d RESCUE(S) NOT YET PLACED:" % len(unplaced))
            for tok, target in unplaced:
                print("    %-46s -> %s" % (tok, target))
        if args.check and not missing and not unplaced:
            print("\n  LEDGER BALANCES: every token has a home or a named destination.")

    if args.check:
        return len(missing) + len(unplaced)
    return 0


if __name__ == "__main__":
    sys.exit(main())
