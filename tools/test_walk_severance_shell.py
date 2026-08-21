#!/usr/bin/env python3
"""Prove the severance detector's shell-only degrade bites, and un-bites.

On 2026-08-21 `check_walk_severance.py` returned PASS (flood z=77 of 77, 0
cuts) in the same hour gate F died at z=21.2 with a fourteen-cell cut list. The
detector was not wrong about its grid — it was reading the UNDRESSED SHELL,
because `endless_museum.gd` stamps a segment's cell grid in `_write_built`
(:3453) and the dressing pass that erases bench and prop cells is queued
(:3319) and drained frames later. So the detector now degrades a would-be PASS
to SKIP when any segment carries `replay: true`.

That degrade is only sound because dressing is SUBTRACTIVE — every dress call
site erases walk cells and none assigns them — so a cut in the shell is a cut
in the dressed museum, and FAIL must survive the change untouched. This test is
the negative half: a degrade that also swallowed FAIL would have made the
instrument quieter, not more honest.

Four cases, no Godot, under a second:

  dressed + whole -> PASS   the green is still earnable
  shell   + whole -> SKIP   the fault this file was written for
  dressed + cut   -> FAIL   unchanged
  shell   + cut   -> FAIL   unchanged: the degrade never touches this branch

  python tools/test_walk_severance_shell.py

Prints `WALK SEVERANCE SHELL: PASS|FAIL — …` and exits with the number of
failing cases, so run_em_gates.py can record it.
"""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DETECTOR = REPO / "tools" / "check_walk_severance.py"

# z rows, one string per row, x starting at 0.
WHOLE = ["...", "...", "...", "..."]
# z=1 open {0,1}; z=2 open {2,3}. No shared column: nothing steps across.
CUT = ["..##", "..##", "##..", "##.."]

LEGEND = {"#": "not floor", ".": "floor", "b": "bench", "p": "prop",
          "s": "sealed by a body", "x": "erased"}

CASES = [
    ("dressed_whole", WHOLE, False, "PASS", 0),
    ("shell_whole", WHOLE, True, "SKIP", 0),
    ("dressed_cut", CUT, False, "FAIL", 1),
    ("shell_cut", CUT, True, "FAIL", 1),
]


def verdict_of(tmp: Path, name: str, cells: list[str], replay: bool) -> tuple[str, int]:
    path = tmp / f"{name}.json"
    path.write_text(json.dumps({
        "schema": "adaresearch.em_built.v1",
        "segments": [{
            "segment": 0, "museum": "test-museum", "z0": 0, "cell_x0": 0,
            "replay": replay, "cells": cells, "legend": LEGEND,
        }],
    }), encoding="utf-8")
    proc = subprocess.run(
        [sys.executable, str(DETECTOR), f"--built={path}"],
        capture_output=True, text=True, encoding="utf-8", errors="replace")
    lines = [ln for ln in proc.stdout.splitlines() if "WALK SEVERANCE:" in ln]
    return (lines[-1] if lines else "<no verdict line>"), proc.returncode


def classify(line: str) -> str:
    for word in ("PASS", "FAIL", "SKIP"):
        if f"WALK SEVERANCE: {word}" in line:
            return word
    return "?"


def main() -> int:
    bad = 0
    with tempfile.TemporaryDirectory() as td:
        tmp = Path(td)
        for name, cells, replay, want, want_rc in CASES:
            line, rc = verdict_of(tmp, name, cells, replay)
            got = classify(line)
            ok = got == want and rc == want_rc
            bad += 0 if ok else 1
            print(f"  [{'ok ' if ok else 'BAD'}] {name:<14} want {want}/rc{want_rc}"
                  f"  got {got}/rc{rc}")
            if not ok:
                print("        " + line[:160])
    total = len(CASES)
    if bad:
        print(f"WALK SEVERANCE SHELL: FAIL — {total - bad}/{total} cases;"
              " the degrade is either not biting on a shell or it is swallowing"
              " a cut")
    else:
        print(f"WALK SEVERANCE SHELL: PASS — {total}/{total} cases;"
              " shell degrades to SKIP, dressed still earns PASS, FAIL untouched"
              " in both")
    return bad


if __name__ == "__main__":
    sys.exit(main())
