#!/usr/bin/env python3
"""Does the want gate actually bite? Feed it wants that ARE closed dishonestly.

    python tools/test_want_gate.py

Three of the gate's failing verdicts are at zero on the real corpus today —
BROKEN BODY, HERO GHOST, and every ECHO variant that is not already there. A rule
at zero is indistinguishable from a rule that does not run, and this project has
shipped that mistake before: a sweep reporting INERT because the axis was never
set, every stage green. So each verdict gets a synthetic case built to trip it,
and one built NOT to.

The pair matters more than the trip. ECHO must fire on two works with different
scenes and stay silent on two names for one scene — a dozen honest shared
vocabularies in the real book depend on exactly that distinction, and a gate that
cannot tell a family from a copy-paste would condemn them all.

And ECHO? must fire where neither work declares a scene, because there the gate
has no evidence either way. That case had zero instances on the corpus and was
being silently condemned as ECHO; it is exactly the kind of rule a real-data run
can never exercise, which is what this file is for.
"""
from __future__ import annotations

import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
from want_gate import want_1, want_2, FAILING  # noqa: E402

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

REAL_SCENE = "commons/primitives/arrays/pattern_tile_puzzle.tscn"
FAILS = []


def line(tok, text, chapter="test", pearl="p", map_="TestMap", li=0):
    return {"chapter": chapter, "pearl": pearl, "map": map_, "hero": "", "pi": 0,
            "li": li, "token": tok, "text": text, "note": "", "note_src": None}


def verdicts(rows, tok):
    return sorted({r["verdict"] for r in rows if r["token"] == tok})


def check(name, got, want):
    ok = want in got
    print("  %-5s %-46s got %s" % ("ok" if ok else "FAIL", name, got or "[]"))
    if not ok:
        FAILS.append(name)


def check_not(name, got, unwanted):
    ok = unwanted not in got
    print("  %-5s %-46s got %s" % ("ok" if ok else "FAIL", name, got or "[]"))
    if not ok:
        FAILS.append(name)


print("WANT 1 — work -> text")
reg = {"a": {"scene": "res://" + REAL_SCENE}, "b": {"scene": "res://" + REAL_SCENE},
       "c": {"scene": "res://commons/primitives/triangle/triangle.tscn"}}
place = {"a": {"TestMap"}, "b": {"TestMap"}, "c": {"OtherMap"}}

# two names, ONE scene, one sentence — an honest family, must NOT fail
sib = want_1(reg, place, [line("a", "one argument in two dresses", li=0),
                          line("b", "one argument in two dresses", li=1)])
check("SIBLING fires on two names for one scene", verdicts(sib, "a"), "SIBLING")
check_not("...and does NOT fail them", verdicts(sib, "a"), "ECHO")

# two works, DIFFERENT scenes, one sentence — the copy-paste, must fail
ech = want_1(reg, place, [line("a", "the same words for two objects", li=0),
                          line("c", "the same words for two objects", li=1)])
check("ECHO fires on different scenes", verdicts(ech, "a"), "ECHO")

# THE UNDECIDABLE CASE. Two different works that both declare no scene: the
# evidence for "one body" is a shared scene and neither has one. The gate must
# say so rather than pick, and must NOT fail — an evaluator found the first draft
# condemning exactly this as fraud.
noscene = {"x": {"name": "X"}, "y": {"name": "Y"}}
und = want_1(noscene, {"x": {"TestMap"}, "y": {"TestMap"}},
             [line("x", "one sentence for both", li=0), line("y", "one sentence for both", li=1)])
check("ECHO? fires when neither work declares a scene", verdicts(und, "x"), "ECHO?")
check_not("...and it does NOT become ECHO", verdicts(und, "x"), "ECHO")

check("GHOST fires on an unregistered token",
      verdicts(want_1(reg, place, [line("zzz", "words about nothing")]), "zzz"), "GHOST")
check("EMPTY fires on a name with no words",
      verdicts(want_1(reg, place, [line("a", "   ")]), "a"), "EMPTY")
check("STUB fires on three words",
      verdicts(want_1(reg, place, [line("a", "laser, and light")]), "a"), "STUB")
check_not("...and NOT on four",
          verdicts(want_1(reg, place, [line("a", "a laser and some light")]), "a"), "STUB")
check("ELSEWHERE fires when the work is not in the hall",
      verdicts(want_1(reg, place, [line("c", "a full sentence about the work")]), "c"), "ELSEWHERE")
check_not("...and not when it is",
          verdicts(want_1(reg, place, [line("a", "a full sentence about the work")]), "a"), "ELSEWHERE")

print()
print("WANT 2 — text -> work")
reg2 = {"has_body": {"scene": "res://" + REAL_SCENE},
        "no_scene": {"name": "Promised"},
        "gone": {"scene": "res://commons/does/not/exist_at_all.tscn"}}
place2 = {"has_body": {"TestMap"}}
check("NO REGISTRY fires", verdicts(want_2({}, {}, [line("nope", "x")]), "nope"), "NO REGISTRY")
check("NO BODY fires on a row with no scene",
      verdicts(want_2(reg2, place2, [line("no_scene", "x")]), "no_scene"), "NO BODY")
check("BROKEN BODY fires on a scene not on disk",
      verdicts(want_2(reg2, place2, [line("gone", "x")]), "gone"), "BROKEN BODY")
check("UNPLACED fires on a body standing nowhere",
      verdicts(want_2(reg2, {}, [line("has_body", "x")]), "has_body"), "UNPLACED")
check_not("...and a placed, built work is clean",
          verdicts(want_2(reg2, place2, [line("has_body", "x")]), "has_body"), "UNPLACED")

print()
print("THE FAILING SET is what decides exit 1:")
print("  " + ", ".join(sorted(FAILING)))
for v in ("EMPTY", "STUB", "ELSEWHERE", "SIBLING", "ECHO?", "NO BODY", "UNPLACED",
          "NO SUBJECT", "HERO ABSENT"):
    if v in FAILING:
        FAILS.append("%s must NOT fail — an open want is not a debt" % v)
        print("  FAIL  %s is in FAILING and should not be" % v)

print()
if FAILS:
    print("%d CHECK(S) FAILED" % len(FAILS))
    for f in FAILS:
        print("   %s" % f)
    raise SystemExit(1)
print("all checks passed — every failing verdict bites, and no open want does")
raise SystemExit(0)
