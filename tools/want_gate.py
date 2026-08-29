#!/usr/bin/env python3
"""THE WANT GATE — was this want closed honestly, or just ticked off?

    python tools/want_gate.py               # all three directions
    python tools/want_gate.py --want=2      # one direction
    python tools/want_gate.py --json
    exit 1 when a want has been closed dishonestly

2026-08-29, Palle: "build the gate for the other three wants."

A WANT IS NOT A FAILURE. 1638 works with no words is the shape of the project, not
a bug — most of the corpus stands in halls nobody has walked. Counting that as an
error would be a scoreboard, and the sieve pass on the edges corpus already named
the danger: an index that rewards filling in zeros pushes toward 2078 more thin
lines rather than toward the 219 reflections becoming 400.

So this gate does not measure how many wants are open. It asks the only question
that can actually go wrong: WHEN A WANT CLOSES, DID IT CLOSE HONESTLY? A line that
names nothing real, a sentence doing duty for two different works, a hall whose
hero is not in it — those are wants that look closed and are not. They FAIL.
Everything else is REPORTED, with its number, and reported is not a reproach.

THE THREE DIRECTIONS, and what closing each one claims:

    work -> text   a line now speaks for this work.
                   Claim: these words are about THIS thing.
    text -> work   the thing the book promised now exists.
                   Claim: there is a body, and you can stand in front of it.
    text -> body   the thought now has a subject.
                   Claim: the hall's hero is a real work, and it is in the hall.

THE ECHO RULE, AND WHY IT NEARLY WENT WRONG. The obvious anti-cheat is: the same
sentence on two lines means somebody templated the fill. Measured, 16 lines share
their words with another line and ZERO are one work repeated across halls — so as
a blind rule it would have fired on all 16.

It would have been wrong on twelve of them. `pattern_tile_4x4`, `_brick`,
`_herringbone`, `_mirror` and `_puzzle` all resolve to the SAME .tscn: one scene
under five registry names, which CLAUDE.md calls the corpus's most common hidden
family. Five names for one object honestly share one sentence. So ECHO fires only
when the sharing works resolve to DIFFERENT scenes, and one of those cases
(`laser_sword` / `laser_measure`) shares the single word "laser,".

That is the standing lesson arriving in a new place: when a shared vocabulary is
honest the siblings measure alike, and a gate that cannot tell a family from a
copy-paste will condemn the family.

AND THERE IS A THIRD OUTCOME, added after an evaluator found the rule guessing.
Two DIFFERENT works that both declare no scene are not decidable either way: the
evidence for "one body" is a shared .tscn, and neither has one. The first draft
collapsed them to {""}, failed all(), and condemned both as ECHO — inventing
fraud from an absence. 30 works in the book have no scene, so the population is
real and waiting. Undecidable cases are ECHO? and do not fail, the way edge_gate
says INERT? when nobody has looked from a second standpoint. A gate may say "I
cannot tell". It may not guess.

The counts in this file move; do not quote them as fixed. Run it.
"""
from __future__ import annotations

import argparse
import collections
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
from concord import registry, placements, book_lines, BOOK  # noqa: E402

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

# Which verdicts mean a want was closed dishonestly. Everything not here is a
# want that is honestly still open, or a finding worth a look — neither fails.
FAILING = {"GHOST", "ECHO", "NO REGISTRY", "BROKEN BODY", "HERO GHOST"}

_norm = lambda s: re.sub(r"\s+", " ", str(s).strip().lower())


def scene_of(meta: dict) -> str:
    return str((meta or {}).get("scene", "")).strip()


def want_1(reg: dict, place: dict, bl: list) -> list:
    """work -> text. A line that claims to speak for a work."""
    rows = []
    lines = [l for l in bl if l["token"]]

    # ECHO / SIBLING — the same words on works that are, or are not, one object.
    groups = collections.defaultdict(list)
    for l in lines:
        if l["text"].strip():
            groups[_norm(l["text"])].append(l)
    for words, grp in groups.items():
        toks = sorted({l["token"] for l in grp})
        if len(toks) < 2:
            continue
        scenes = {scene_of(reg.get(t, {})) for t in toks}
        # THREE OUTCOMES, NOT TWO. The first draft asked `len(scenes) == 1 and
        # all(scenes)` and called everything else ECHO. That silently condemned a
        # case it cannot actually judge: two DIFFERENT works that both declare no
        # scene collapse to {""}, all("") is False, and both are marked a cheat.
        # There are 30 such scene-less works in the book right now, so the day
        # somebody writes one line for a pair of unbuilt siblings the gate calls
        # it fraud on no evidence — the family-condemning failure this rule exists
        # to prevent, displaced onto works that are merely unbuilt.
        #
        # So an undecidable case gets its own verdict and does NOT fail, the way
        # edge_gate says INERT? rather than INERT when nobody has looked from a
        # second standpoint. A gate may say "I cannot tell"; it may not guess.
        known = {s for s in scenes if s}
        if len(scenes) == 1 and known:
            v = "SIBLING"
            why = "%d names for one scene — an honest shared vocabulary" % len(toks)
        elif len(known) < len(toks):
            v = "ECHO?"
            why = ("%d works share one sentence and %d of them declare no scene, "
                   "so whether they are one body cannot be decided: %s"
                   % (len(toks), len(toks) - len(known), ", ".join(toks)))
        else:
            v = "ECHO"
            why = "%d works with DIFFERENT scenes given one sentence: %s" % (len(toks), ", ".join(toks))
        for l in grp:
            rows.append({**l, "verdict": v, "why": why})

    # Every rule is tested independently, and a line trips as many as it trips.
    # An earlier draft short-circuited — first verdict wins — and a line that was
    # both SIBLING and ELSEWHERE reported only the first, so ELSEWHERE read 23
    # against a true 36. A gate that hides one finding behind another lies in the
    # most convincing way available to it: quietly, with a smaller number.
    for l in lines:
        words = l["text"].split()
        if l["token"] not in reg:
            rows.append({**l, "verdict": "GHOST", "why": "names no work in any registry"})
        if not l["text"].strip():
            rows.append({**l, "verdict": "EMPTY", "why": "a name with no words — the want, still open"})
        elif len(words) < 4:
            rows.append({**l, "verdict": "STUB", "why": "%d word(s) — closed in name only" % len(words)})
        if l["map"] and l["token"] in place and l["map"] not in place[l["token"]]:
            rows.append({**l, "verdict": "ELSEWHERE",
                         "why": "speaks for a work that does not stand in %s" % l["map"]})
    return rows


def want_2(reg: dict, place: dict, bl: list) -> list:
    """text -> work. A work the book has promised. Can you stand in front of it?

    Four hops, each able to fail on its own: the book names it, the registry has a
    row, the row declares a scene, the scene is on disk, and something places it."""
    rows = []
    first = {}
    for l in bl:
        if l["token"]:
            first.setdefault(l["token"], l)
    for tok, l in sorted(first.items()):
        meta = reg.get(tok)
        if meta is None:
            rows.append({**l, "verdict": "NO REGISTRY",
                         "why": "the book speaks about it and no registry has a row"})
            continue
        sc = scene_of(meta)
        if not sc:
            rows.append({**l, "verdict": "NO BODY",
                         "why": "a registry row with no scene — promised, never built"})
            continue
        p = REPO / sc.replace("res://", "")
        if not p.exists():
            rows.append({**l, "verdict": "BROKEN BODY", "why": "scene declared and missing: %s" % sc})
            continue
        if tok not in place:
            rows.append({**l, "verdict": "UNPLACED",
                         "why": "built, and standing in no map — nobody can walk to it"})
    return rows


def want_3(reg: dict, place: dict) -> list:
    """text -> body. A thought and the work it is about."""
    rows = []
    for f in sorted(BOOK.glob("*.json")):
        try:
            doc = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        for p in doc.get("pearls", []):
            hero = str(p.get("hero", "")).strip()
            mp = str(p.get("map", ""))
            base = {"chapter": f.stem, "pearl": str(p.get("pearl", "")), "map": mp,
                    "token": hero, "text": str(p.get("edge", "")), "li": -1}
            if not hero:
                if isinstance(p.get("edge_src"), dict) or str(p.get("edge", "")).strip():
                    rows.append({**base, "verdict": "NO SUBJECT",
                                 "why": "an edge with no hero and %d line(s) — a thought with no body"
                                        % len(p.get("lines", []))})
                continue
            if hero not in reg:
                rows.append({**base, "verdict": "HERO GHOST", "why": "the hall's hero names no work"})
            elif mp and hero not in place:
                rows.append({**base, "verdict": "HERO ABSENT", "why": "the hero stands in no map at all"})
            elif mp and mp not in place.get(hero, set()):
                rows.append({**base, "verdict": "HERO ABSENT",
                             "why": "the hall is about a work that is not in the hall"})
    return rows


TITLES = {1: ("work -> text", "a line that speaks for a work"),
          2: ("text -> work", "a work the book has promised"),
          3: ("text -> body", "a thought and the work it is about")}


def main() -> int:
    ap = argparse.ArgumentParser(description="was this want closed honestly, or just ticked off")
    ap.add_argument("--want", type=int, default=0, choices=[0, 1, 2, 3])
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--quiet", action="store_true")
    a = ap.parse_args()

    reg, place, bl = registry(), placements(), book_lines()
    sets = {1: want_1(reg, place, bl), 2: want_2(reg, place, bl), 3: want_3(reg, place)}
    pick = [a.want] if a.want else [1, 2, 3]
    failing_rows = [r for w in pick for r in sets[w] if r["verdict"] in FAILING]
    fails = len(failing_rows)
    # fails COUNTS ROWS, and one broken thing can raise two of them: an
    # unregistered token is GHOST in want 1 and NO REGISTRY in want 2, so a single
    # ghost reads as 2. Report both numbers — a row count is what the gate acts
    # on, a distinct count is how many things are actually wrong, and quoting the
    # first as the second overstates the damage.
    distinct = len({r.get("token") or (r["chapter"] + "|" + r["pearl"]) for r in failing_rows})

    if a.json:
        # `checked` is the denominator the release gate asserts is non-zero. A run
        # over an empty book reports zero dishonest closures, which is exactly what
        # a clean book reports; without a size the gate cannot tell them apart, and
        # gate G in this repo went green on a scan of nothing for a day.
        tally = collections.Counter(r["verdict"] for w in pick for r in sets[w])
        print(json.dumps({"fails": fails, "distinct_problems": distinct,
                          "checked": {"book_lines": len(bl),
                                      "token_lines": sum(1 for l in bl if l["token"]),
                                      "registry": len(reg), "placed": len(place)},
                          "verdicts": dict(tally),
                          "wants": {str(w): {"direction": TITLES[w][0], "rows": sets[w]} for w in pick}},
                         ensure_ascii=False, indent=1))
        return 1 if fails else 0

    print("THE WANT GATE — a want is not a failure; a want closed dishonestly is")
    for w in pick:
        rows = sets[w]
        tally = collections.Counter(r["verdict"] for r in rows)
        print()
        print("  %d. %-14s %s" % (w, TITLES[w][0], TITLES[w][1]))
        for v, n in sorted(tally.items(), key=lambda x: (x[0] not in FAILING, -x[1])):
            print("       %-13s %4d   %s" % (v, n, "FAILS" if v in FAILING else ""))
        for v in sorted({r["verdict"] for r in rows}, key=lambda x: x not in FAILING):
            if a.quiet and v not in FAILING:
                continue
            show = [r for r in rows if r["verdict"] == v]
            if v in ("EMPTY", "ELSEWHERE", "NO BODY", "NO SUBJECT", "SIBLING") and len(show) > 4:
                show = show[:4]
            print("     %s:" % v)
            for r in show:
                print("       %-16s %-26s %-30s %s" % (r["chapter"][:16], (r["map"] or "")[:26],
                                                       (r["token"] or "")[:30], r["why"][:74]))
            rest = tally[v] - len(show)
            if rest > 0:
                print("       ... and %d more" % rest)

    print()
    if fails:
        print("  %d failing row(s) over %d distinct problem(s) — one unregistered token raises" % (fails, distinct))
        print("  both GHOST in want 1 and NO REGISTRY in want 2, so the row count overstates it.")
        print("  A GHOST or a NO REGISTRY means the book")
        print("  speaks about something that does not exist. An ECHO means one sentence was")
        print("  asked to be about two different objects. A HERO GHOST means a hall is named")
        print("  for nothing. None of these are open wants — they are wants marked done.")
    else:
        print("  Every closed want closed honestly. The open ones are open, and that is the")
        print("  shape of the project, not a debt.")
    return 1 if fails else 0


if __name__ == "__main__":
    raise SystemExit(main())
