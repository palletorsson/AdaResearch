#!/usr/bin/env python3
"""EVERY WISH LEFT IN A MAP — what was asked for, where, and whether it exists.

2026-08-27, Palle: "add a new instruction artifact for a
if_not_exist_create:what to create. That can be read by AI and the artifact is
created if not exist and placed in the map."

The marker is `if_not_exist_create`, placed in layers.interactables at the cell
that wants the thing. This is the reader: it finds every one, resolves what it
asks for against the artifact registry, and says which wishes are already met.

    python tools/if_not_exist.py                 # every wish, grouped by map
    python tools/if_not_exist.py --open          # only the ones not yet built
    python tools/if_not_exist.py --json          # for an agent to act on
    python tools/if_not_exist.py --check         # exit 1 if any wish is open

WHY A COORDINATE AND NOT A BACKLOG. A backlog says "forces wants something for
torque". This says it at (14,9) in VFM_02_Operations, at the size the gap
actually is, and you meet it while walking the hall. When the thing is built
the marker is REPLACED by it, so the map is both the request and the record of
it being met — there is no second list to keep in sync, and a wish cannot rot
in a file nobody opens.

THE TAIL IS THE SYNTAX, and the head cannot be. `if_not_exist_create:torque`
is read by GridInteractablesComponent as name:rotation — float("torque") is 0,
the words are dropped, and nothing reports it. So:

    if_not_exist_create#make:torque_bench#why:the_hall_shows_force_but_not_turning
    if_not_exist_create#make:torque_bench#like:mass_spring_bench#cells:2x2

FULFILLED MEANS THE REGISTRY KNOWS IT AND THE SCENE IS ON DISK. Not "somebody
said it was done": the same two conditions endless_museum.gd:2200 uses to
decide whether a token is alive, so a wish reported met is a wish the museum
can actually build.
"""
from __future__ import annotations

import argparse
import glob
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAPS = os.path.join(ROOT, "commons", "maps")
REGISTRY = os.path.join(ROOT, "commons", "artifacts", "registry")
MARKER = "if_not_exist_create"


def registry():
    """token -> entry, across every registry file."""
    out = {}
    for p in glob.glob(os.path.join(REGISTRY, "*.json")):
        try:
            with open(p, encoding="utf-8") as fh:
                doc = json.load(fh)
        except Exception:
            continue
        arts = doc.get("artifacts")
        if isinstance(arts, dict):
            out.update(arts)
    return out


def parse_tail(cell: str) -> dict:
    """The #key:value tail of a placement, as a dict. Underscores become spaces
    the way every other text-carrying artifact in this corpus does."""
    out = {}
    for seg in str(cell).split("#")[1:]:
        i = seg.find(":")
        if i < 0:
            out[seg.strip()] = True
            continue
        k = seg[:i].strip()
        v = seg[i + 1:].strip()
        if k:
            out[k] = v
    return out


def alive(entry: dict) -> bool:
    """The museum's own test: a scene declared AND on disk, and map_ready."""
    scene = str(entry.get("scene", ""))
    if scene == "" or not bool(entry.get("map_ready", False)):
        return False
    rel = scene.replace("res://", "")
    return os.path.exists(os.path.join(ROOT, rel))


STOP = set("""a an and are as at be but by for from has have in is it its of on or
that the their this to was were what when where which who will with your you not
no yes if then than so such can could would should may might must does do did
one two three thing things something anything each every all any some more most
here there hall room map show shows showing need needs needed want wants make
made creating create build built place placed""".split())


# THE CORPUS'S FURNITURE VOCABULARY, which is not concept vocabulary. Nearly
# every artifact is a something-bench, something-stand or something-demo, so a
# wish for a "tip_to_tail_bench" scores 5 perfect hits on the word `bench` and
# ranks crossing_bench, attractor_bench, brians_brain_bench — five artifacts
# with nothing in common but their mount. Measured: with these weighted like
# concept words the first real wish matched on furniture ONLY.
MOUNT = set("""bench stand table cabinet vitrine wall board plaque screen panel
station rack shelf case desk deck plinth pedestal column demo lab room hall
gallery kit set toy console workbench playground field chamber walk xl laser
sandbox exhibit display machine device apparatus rig""".split())


def stem(w: str) -> str:
    """Crude, and it has to be. `vectors` must reach `vector` and `adds` must
    reach `add` or the check silently finds nothing — which is the one failure
    mode that matters here, because finding nothing reads exactly like a
    concept being genuinely absent."""
    if len(w) > 5 and w.endswith("ing"):
        w = w[:-3]
    elif len(w) > 4 and w.endswith("ed"):
        w = w[:-2]
    if len(w) > 3 and w.endswith("es") and not w.endswith("ses"):
        w = w[:-2]
    elif len(w) > 3 and w.endswith("s") and not w.endswith("ss"):
        w = w[:-1]
    return w


def words(*parts) -> set:
    out = set()
    for s in parts:
        cur = ""
        for ch in str(s).lower() + " ":
            if ch.isalnum():
                cur += ch
            else:
                if len(cur) > 2 and cur not in STOP:
                    out.add(stem(cur))
                cur = ""
    return out


def near(reg: dict, wish: dict, limit: int = 5):
    """WHAT ALREADY EXISTS THAT NOBODY THOUGHT TO LOOK FOR.

    This is the whole safety of the marker. A wish names a token; a token that
    is absent reads as "does not exist" — and that inference is wrong far more
    often than it is right. Measured 2026-09-01 on the first wish ever written:
    a search for tip_to_tail, parallelogram and resultant returned NOTHING in
    2887 entries, and vector addition is in the corpus TEN TIMES (vector_add,
    vector_addition_xl, VectorAddition, tug_of_war, combined_forces_demo, ...).
    A marker acted on without this check builds the eleventh.

    So the words of the wish are matched against every name AND description,
    not just names — the concept nouns a person reaches for are in the prose,
    almost never in the token.
    """
    want = words(wish.get("make", ""), wish.get("why", ""))
    if not want:
        return []
    hits = []
    for token, entry in reg.items():
        if not isinstance(entry, dict):
            continue
        nm = words(token, entry.get("name", ""))
        ds = words(entry.get("description", ""), " ".join(
            [str(t) for t in (entry.get("tags") or [])]))
        # A shared CONCEPT is evidence; a shared MOUNT is not. Both still count,
        # because a wish naming only furniture should surface something rather
        # than nothing, but a furniture hit can never outrank a concept hit.
        concept_n = len((want & nm) - MOUNT)
        concept_d = len((want & ds) - MOUNT)
        mount_n = len(want & nm & MOUNT)
        score = 4 * concept_n + concept_d + mount_n
        if score >= 4 and concept_n + concept_d > 0:
            hits.append((score, token, str(entry.get("description", ""))[:70]))
    hits.sort(key=lambda h: (-h[0], h[1]))
    return hits[:limit]


def wishes():
    reg = registry()
    found = []
    for p in sorted(glob.glob(os.path.join(MAPS, "*", "map_data.json"))):
        try:
            with open(p, encoding="utf-8") as fh:
                doc = json.load(fh)
        except Exception:
            continue
        name = os.path.basename(os.path.dirname(p))
        for z, row in enumerate((doc.get("layers") or {}).get("interactables", []) or []):
            for x, cell in enumerate(row):
                s = str(cell).strip()
                if not s or s.split("#")[0].split(":")[0] != MARKER:
                    continue
                t = parse_tail(s)
                make = str(t.get("make") or t.get("create") or t.get("token") or "")
                entry = reg.get(make) if make else None
                found.append({
                    "map": name, "cell": [x, z], "raw": s,
                    "make": make,
                    "why": str(t.get("why") or t.get("text") or ""),
                    "like": str(t.get("like") or ""),
                    "cells": str(t.get("cells") or ""),
                    # THREE STATES, not two. A wish with no `make` cannot be
                    # fulfilled or unfulfilled — it is a gap somebody marked
                    # before they could name it, and reporting it as "open"
                    # alongside the nameable ones hides the difference.
                    "state": ("unnamed" if not make
                              else "fulfilled" if entry is not None and alive(entry)
                              else "open"),
                })
                if found[-1]["state"] != "fulfilled":
                    found[-1]["near"] = [
                        {"token": t, "score": sc, "description": d}
                        for sc, t, d in near(reg, found[-1])
                    ]
                else:
                    found[-1]["near"] = []
    return found


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--open", action="store_true", help="only wishes not yet built")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--check", action="store_true", help="exit 1 if any wish is open")
    args = ap.parse_args()

    rows = wishes()
    if args.open:
        rows = [r for r in rows if r["state"] != "fulfilled"]

    if args.json:
        print(json.dumps({"wishes": rows}, ensure_ascii=False))
        return 1 if args.check and any(r["state"] == "open" for r in rows) else 0

    if not rows:
        print("no if_not_exist_create markers in %d map(s)"
              % len(glob.glob(os.path.join(MAPS, "*", "map_data.json"))))
        return 0

    print("WISHES LEFT IN THE MAPS — %d marker(s)\n" % len(rows))
    by_map = {}
    for r in rows:
        by_map.setdefault(r["map"], []).append(r)
    for m in sorted(by_map):
        print("  %s" % m)
        for r in by_map[m]:
            mark = {"fulfilled": "built", "open": "OPEN", "unnamed": "unnamed"}[r["state"]]
            print("     (%2d,%2d) %-8s %-28s %s"
                  % (r["cell"][0], r["cell"][1], mark, r["make"] or "-",
                     ("%s " % r["cells"]) + r["why"]))
            if r["like"]:
                print("              like %s" % r["like"])
            for n in r.get("near", []):
                print("              already exists? %-26s %s" % (n["token"], n["description"]))
    n_open = sum(1 for r in rows if r["state"] == "open")
    n_named = sum(1 for r in rows if r["state"] == "unnamed")
    print("\n  %d open, %d built, %d unnamed"
          % (n_open, sum(1 for r in rows if r["state"] == "fulfilled"), n_named))
    n_near = sum(1 for r in rows if r["state"] != "fulfilled" and r.get("near"))
    if n_near:
        print("  %d wish(es) have a NEAR MATCH already in the registry — read those before"
              % n_near)
        print("  building anything. A token that is absent is not a concept that is absent.")
    if n_open:
        print("  to act on one: build the artifact, then replace the marker cell with its token")
    return 1 if args.check and n_open else 0


if __name__ == "__main__":
    sys.exit(main())
