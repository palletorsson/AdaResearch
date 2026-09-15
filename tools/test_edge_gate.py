#!/usr/bin/env python3
"""Does the edge gate still bite? Feed it anchors that ARE broken.

    python tools/test_edge_gate.py

Written 2026-08-30, the day the matcher was loosened. LOST fell 3 -> 0 in one
pass, and a gate that goes green the moment you touch its comparison is the exact
shape of an instrument that stopped checking. Every LOST verdict in the corpus is
now zero, which is the state this project has learned to distrust: a rule at zero
is indistinguishable from a rule that does not run.

WHAT CHANGED, AND WHAT EACH CHANGE MUST NOT COST:

  the math table  norm() now spells pi, theta, sqrt, -> and friends into the
                  Latin alphabet on BOTH sides, because a model reading
                  "T = 2pi*sqrt(L/g)" out of a file that says "T = 2pi*sqrt(L/g)"
                  has not drifted, it has transliterated. The table must not make
                  a quote match a file that does not contain it.

  the ellipsis    a quote written "line A ... line B" is two readings joined, and
                  matching it as one span could never succeed. Each fragment is
                  now required. That is STRICTER than what it replaced, and the
                  test below proves it: one true half and one false half is LOST,
                  not HELD.

The pair matters more than the trip. Each check has a case built to fire and a
case built to stay silent.
"""
from __future__ import annotations

import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
import edge_gate as _edge_gate  # noqa: E402
from edge_gate import verdict, norm  # noqa: E402

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

FAILS: list[str] = []

# FROZEN FIXTURES, not live files. Until 2026-09-15 MATH_FILE was the real
# commons/maps/Vectors_Act4b_Oscillation/intent.md, and on 2026-09-11 a room
# rewrite (uncommitted, idle four days) replaced its "Technical angle" paragraph.
# The positive case read LOST, the self-test failed, and gate I printed
# detector_selftest FAIL -- a verdict about a writer's prose, reported as a fault
# in the matcher. A self-test tests the MATCHER; the corpus is edge_gate's own
# job. So the bodies below are the exact lines those files held (HEAD 69a6c51e1
# and random_space.tscn lines 13-18), seeded into edge_gate's read cache under
# paths no real file can have. The live paths stay named for provenance only.
MATH_FILE = "fixture://Vectors_Act4b_Oscillation/intent.md"
SPLIT_FILE = "fixture://walkgrids/random_space.tscn"

_edge_gate._CACHE[MATH_FILE] = norm(
    "Technical angle: A 30×30 hall, max height 2. Interactables: spring_tower "
    "(stiffen the coil and it gives less and ticks faster — F = −kx), pendulum_hall "
    "(lengthen the string and the swing slows — T = 2π√(L/g), restoring force "
    "mg sin θ), momentum_cradle (lift and release; momentum passes through the "
    "still middle, conserved), bounce_well (set the bounciness e; each bounce a "
    "fraction of the last, h' = e·h).\n")
_edge_gate._CACHE[SPLIT_FILE] = norm(
    '[node name="RandomSpace" type="Node3D"]\n'
    'script = ExtResource("1_n8dtw")\n'
    "seed_value = 1\n"
    "space_size = Vector2(11, 20)\n"
    "resolution = 50\n"
    "chaos_level = 1.0\n"
    "height_scale = 0.12\n"
    "enable_animation = false\n"
    "position_offset = Vector3(0, 0, 0)\n")


def edge(rel: str, quote: str) -> dict:
    return {"chapter": "test", "map": "TestMap", "where": "line",
            "edge": "a sentence", "src": {"file": rel, "quote": quote}}


def check(label: str, got: str, want: str) -> None:
    if got == want:
        print("  [ok]   %-58s %s" % (label, got))
    else:
        print("  [FAIL] %-58s got %s, wanted %s" % (label, got, want))
        FAILS.append("%s: got %s, wanted %s" % (label, got, want))


print("THE GATE MUST STILL FIND A BROKEN ANCHOR")
check("a file that is not in the repo",
      verdict(edge("algorithms/no/such/file.gd", "anything at all"))[0], "LOST")
check("a sentence genuinely absent from a real file",
      verdict(edge(MATH_FILE,
                   "the hall is lit by a single candle and smells of pine"))[0], "LOST")
check("an anchor with no file recorded",
      verdict(edge("", "a quote with nowhere to stand"))[0], "UNGROUNDED")
check("an anchor with a file but no quote",
      verdict(edge(MATH_FILE, ""))[0], "UNGROUNDED")

print()
print("THE MATH TABLE MUST TRANSLITERATE, NOT EXCUSE")
check("pi/sqrt/theta spelled out against the Unicode source",
      verdict(edge(MATH_FILE,
                   "pendulum_hall (lengthen the string and the swing slows - "
                   "T = 2pi*sqrt(L/g), restoring force mg sin theta)"))[0], "HELD")
check("the same shape with the WRONG variable is not rescued",
      verdict(edge(MATH_FILE,
                   "pendulum_hall (shorten the string and the swing slows - "
                   "T = 2pi*sqrt(Q/g), restoring force mq cos theta)"))[0], "LOST")
# Two distinct symbols must not collapse onto one token, or the table would let a
# quote about intersection match a file about union.
if norm("∪") == norm("∩"):
    FAILS.append("the math table collapses union and intersection onto one token")
    print("  [FAIL] union and intersection normalise to the same string")
else:
    print("  [ok]   union and intersection stay distinct after normalisation")

print()
print("THE ELLIPSIS MUST REQUIRE EVERY FRAGMENT, NOT MOST OF THEM")
check("both halves present, five lines apart",
      verdict(edge(SPLIT_FILE, "seed_value = 1 ... enable_animation = false"))[0], "HELD")
check("first half true, second half invented",
      verdict(edge(SPLIT_FILE, "seed_value = 1 ... enable_animation = true"))[0], "LOST")
check("first half invented, second half true",
      verdict(edge(SPLIT_FILE, "seed_value = 99 ... enable_animation = false"))[0], "LOST")

print()
if FAILS:
    print("%d CHECK(S) FAILED" % len(FAILS))
    for f in FAILS:
        print("   %s" % f)
    raise SystemExit(1)
print("all checks passed — the loosened matcher still convicts a broken anchor")
raise SystemExit(0)
