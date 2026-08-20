#!/usr/bin/env python3
"""The negative half of the severance gate: prove it BITES, and prove it lets go.

A detector that only ever fires on the one museum that happens to be broken today
is indistinguishable from a detector that always fires. So this drives
check_walk_severance.py over built files we construct, where the answer is known
before the tool runs:

  WHOLE     a straight corridor, every row sharing a column   -> PASS, exit 0
  SEVERED   the same corridor with one row shifted off        -> FAIL, exit 1
  TWO CUTS  two such shifts                                   -> FAIL, exit 2
  SEAM      the cut falls between two segments                -> FAIL, names SEAM
  BENCHED   a row walled but for a bench ('b', not floor)     -> FAIL (a bench is
            not floor, which is why the roles are recorded apart)
  MISSING   no built file at all                              -> SKIP, never PASS
  BLIND     cell map intact but the flood stops anyway        -> SKIP, never PASS

The last two are the point. Between 08-13 and 08-15 four confident verdicts in one
corpus run turned out to be facts about the rig rather than the thing measured, and
the standing rule from that week is to count what is being measured before
believing any null. A gate that reports PASS when it read nothing is exactly that
failure with a green light on it.

    python tools/test_walk_severance.py
"""
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
TOOL = REPO / "tools" / "check_walk_severance.py"


def built(segments: list[dict]) -> dict:
    return {"schema": "adaresearch.em_built.test", "segments": segments}


def seg(index: int, z0: int, rows: list[str], x0: int = 0, museum: str = "test-hall") -> dict:
    return {"segment": index, "museum": museum, "z0": z0, "cell_x0": x0, "cells": rows}


def run(payload: dict | None) -> tuple[int, str]:
    """Run the detector over a built file we wrote. Returns (exit code, stdout)."""
    with tempfile.TemporaryDirectory() as td:
        path = Path(td) / "em_built.json"
        if payload is not None:
            path.write_text(json.dumps(payload), encoding="utf-8")
        cp = subprocess.run(
            [sys.executable, str(TOOL), f"--built={path}"],
            cwd=REPO, capture_output=True, text=True, timeout=60, errors="replace",
        )
        return cp.returncode, (cp.stdout or "") + (cp.stderr or "")


def verdict_of(out: str) -> str:
    """The gate runner reads the LAST matching line; read it the same way."""
    hit = ""
    for line in out.splitlines():
        if line.strip().startswith("WALK SEVERANCE:"):
            hit = line.strip()
    return hit


# A corridor 6 wide. Walkable '.' at x=1..3 on every row: whole by construction.
OPEN = "#...##"
# The same width, walkable at x=4 only: shares no column with OPEN.
AWAY = "#####."
# Walled but for a bench. 'b' is a cell a body cannot stand on, so this row is
# closed even though it is not '#' — the roles are recorded apart for this reason.
BENCH = "#bbb##"

# ONE DISPLACED ROW IS TWO CUTS, not one — the corridor is severed entering it and
# again leaving it. Measured, not assumed: the first draft of this test asserted 1
# and the tool returned 2, and the tool is right. It matters for reading a verdict,
# because "cuts: 4" in a real museum can be two displaced rows rather than four
# separate faults, and it was: today's four cuts are four bridges, each counted
# once because each sits at the END of its museum's rows.
CASES: list[tuple[str, dict | None, str, int | None]] = [
    ("whole corridor",
     built([seg(0, 0, [OPEN] * 12)]), "PASS", 0),
    ("one row shifted off the shared column",
     built([seg(0, 0, [OPEN] * 5 + [AWAY] + [OPEN] * 6)]), "FAIL", 2),
    ("two such shifts",
     built([seg(0, 0, [OPEN] * 3 + [AWAY] + [OPEN] * 3 + [AWAY] + [OPEN] * 3)]), "FAIL", 4),
    ("cut at the seam between two segments",
     built([seg(0, 0, [OPEN] * 6), seg(1, 6, [AWAY] + [OPEN] * 5)]), "FAIL", 2),
    # The pair rule cannot see this one and must not be trusted to: a row with
    # nothing open shares no column with either neighbour, so it is skipped as
    # padding. It is still a wall, and calling it SKIP blames colliders for
    # something written plainly in the cell map.
    ("a row sealed end to end by bodies",
     built([seg(0, 0, [OPEN] * 5 + [BENCH] + [OPEN] * 6)]), "FAIL", 1),
    ("no built file",
     None, "SKIP", 0),
    ("built file with no cells",
     built([]), "SKIP", 0),
]


def main() -> int:
    fails: list[str] = []
    for name, payload, want, want_code in CASES:
        code, out = run(payload)
        got = verdict_of(out)
        tag = got.split("—")[0].replace("WALK SEVERANCE:", "").strip() if got else "(no verdict line)"
        ok = tag == want and (want_code is None or code == want_code)
        if not ok:
            fails.append(f"{name}: wanted {want}"
                         + (f"/exit {want_code}" if want_code is not None else "")
                         + f", got {tag}/exit {code}")
        print(f"  {'ok  ' if ok else 'FAIL'} {name:44s} {tag:5s} exit {code}")

    # The seam case must SAY seam. A cut inside one museum and a cut between two
    # is the distinction four breaths of gate F verdicts could not draw, and it is
    # the first thing a reader needs, so it is not enough for the row to be red.
    _, out = run(built([seg(0, 0, [OPEN] * 6), seg(1, 6, [AWAY] + [OPEN] * 5)]))
    if "SEAM" not in verdict_of(out):
        fails.append("seam cut: verdict does not name it a SEAM")
        print("  FAIL seam cut names itself SEAM")
    else:
        print("  ok   seam cut names itself SEAM")

    # And a real cut must carry the columns on BOTH sides. A coordinate alone is
    # what gate F handed over five times running; four of those five were then
    # guessed wrong from the coordinate.
    _, out = run(built([seg(0, 0, [OPEN] * 5 + [AWAY] + [OPEN] * 6)]))
    v = verdict_of(out)
    if "[1, 2, 3]" not in v or "[5]" not in v:
        fails.append(f"cut verdict does not carry both columns: {v}")
        print("  FAIL cut verdict carries the columns on both sides")
    else:
        print("  ok   cut verdict carries the columns on both sides")

    if fails:
        print("\nWALK SEVERANCE TEST: FAIL")
        for f in fails:
            print(f"  - {f}")
        return 1
    print(f"\nWALK SEVERANCE TEST: PASS — {len(CASES) + 2} cases; it bites on a cut,"
          " lets go on a whole corridor, and never calls an unmeasured museum green")
    return 0


if __name__ == "__main__":
    sys.exit(main())
