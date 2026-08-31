#!/usr/bin/env python3
"""Which placements sit on cells the structure grid does not have?

    python tools/check_offworld_cells.py            # human report, exit = maps affected
    python tools/check_offworld_cells.py --json     # machine report
    python tools/check_offworld_cells.py --selftest # the detector's own pair tests

WHY THIS EXISTS, WHEN FOUR INSTRUMENTS ALREADY READ THESE FILES

A map's three layers are separate grids that are only related by CONVENTION: cell
(z, x) of `interactables` means the artifact standing on cell (z, x) of `structure`.
Nothing enforces the shapes match. When they don't, the extra cells are not an error
anywhere -- the loader walks the structure and simply never asks about the rows past
its end, so the artifact is authored, registered, resolvable, spelled correctly, and
absent from the world.

Measured on this corpus the day the detector was written (2026-08-31):

    62 non-empty cells across 29 maps stand on coordinates the structure does not have
      36 PAST_END   -- row index >= len(structure)
      26 PAST_EDGE  -- column index >= len(structure[row])

and every gate was green over them:

    gate C  Map Validation ......... PASS
    gate G  Map Token Resolution ... PASS  (231 maps, 1323 placements, 0 unresolved --
                                            it asks whether a token NAMES something,
                                            never whether the cell EXISTS)

The pathfinder is the sharpest case, because it is not blind -- it is unweighted.
On Tutorial_Single it prints, in plain English:

    Rule 2 [WARN] Teleport at (2,18) -- no structure row at z=19 to catch player
    Rule 3 [WARN] Teleport at (2,18) is NOT reachable from spawn via walking
    === 1 maps checked: 1 OK, 0 FAIL (0 issues) ===   exit 0

A tutorial map whose only exit teleporter stands two rows past the end of the world,
reported as OK. Same shape in Forces_1 through Forces_4, where the `sp` spawn sits at
column 7 of a 7-wide row, and in Atlas_SDF_Gallery, whose `t` is one column past the
edge. Those are not decoration: they are the entrance and the exit.

WHAT THIS DOES NOT CLAIM

A ragged structure is normal -- rows of a map are allowed to be different widths, and
a short row is not damage. This only convicts a NON-EMPTY cell in `interactables` or
`utilities` whose coordinate has no structure cell under it at all. Whitespace-only
cells are the filler that keeps a row rectangular and are ignored, which is what makes
the ragged-row case safe; the self-test pins that in both directions.

It also does not repair. Where the artifact was MEANT to stand is an authoring
question -- the honest fixes (move it inside, extend the structure, or drop it) are
different decisions with different consequences for a walked map, and picking one from
a script is how 41 maps got stamped at a phantom depth in the first place. See the
standing note: map_info.dimensions is testimony, layers.structure is the fact.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
MAPS = REPO / "commons" / "maps"
LAYERS = ("interactables", "utilities")


def offworld(map_data: dict) -> list[dict]:
    """Every non-empty overlay cell with no structure cell beneath it."""
    layers = map_data.get("layers")
    if not isinstance(layers, dict):
        return []
    structure = layers.get("structure")
    if not isinstance(structure, list) or not structure:
        return []

    out: list[dict] = []
    for layer_name in LAYERS:
        grid = layers.get(layer_name)
        if not isinstance(grid, list):
            continue
        for z, row in enumerate(grid):
            if not isinstance(row, list):
                continue
            if z >= len(structure):
                kind, width = "PAST_END", -1
            else:
                srow = structure[z]
                width = len(srow) if isinstance(srow, list) else 0
                kind = "PAST_EDGE"
            for x, cell in enumerate(row):
                if not isinstance(cell, str) or not cell.strip():
                    continue
                if kind == "PAST_END" or x >= width:
                    out.append(
                        {
                            "layer": layer_name,
                            "z": z,
                            "x": x,
                            "cell": cell.strip(),
                            "kind": kind,
                            "structure_depth": len(structure),
                            "row_width": width,
                        }
                    )
    return out


def scan() -> tuple[dict[str, list[dict]], int]:
    findings: dict[str, list[dict]] = {}
    scanned = 0
    for path in sorted(MAPS.glob("*/map_data.json")):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        scanned += 1
        hits = offworld(data)
        if hits:
            findings[path.parent.name] = hits
    return findings, scanned


# --- the detector's own pair tests -------------------------------------------
# Each rule gets a case built to fire and a case built to stay silent. A rule that
# only ever returns zero on the real corpus is indistinguishable from one that does
# not run, and this one WILL return zero once the corpus is repaired.

def _m(structure, interactables=None, utilities=None) -> dict:
    layers = {"structure": structure}
    if interactables is not None:
        layers["interactables"] = interactables
    if utilities is not None:
        layers["utilities"] = utilities
    return {"layers": layers}


def selftest() -> int:
    checks: list[tuple[str, bool]] = []

    def check(label, cond):
        checks.append((label, bool(cond)))

    print("A ROW PAST THE END OF THE STRUCTURE IS OFF-WORLD")
    hits = offworld(_m([["1", "1"], ["1", "1"]], [[" ", " "], [" ", " "], [" ", "t"]]))
    check("teleporter one row past the last structure row",
          len(hits) == 1 and hits[0]["kind"] == "PAST_END" and hits[0]["cell"] == "t")
    hits = offworld(_m([["1", "1"], ["1", "1"]], [[" ", " "], [" ", "t"]]))
    check("the same teleporter on the last row is fine", hits == [])

    print()
    print("A COLUMN PAST THE EDGE OF ITS OWN ROW IS OFF-WORLD")
    hits = offworld(_m([["1", "1", "1"]], [[" ", " ", " ", "sp"]]))
    check("spawn one column past a 3-wide row",
          len(hits) == 1 and hits[0]["kind"] == "PAST_EDGE" and hits[0]["cell"] == "sp")
    hits = offworld(_m([["1", "1", "1"]], [[" ", " ", "sp"]]))
    check("the same spawn on the last column is fine", hits == [])

    print()
    print("A RAGGED STRUCTURE IS NOT DAMAGE -- THE ROW'S OWN WIDTH IS THE RULE")
    # Row 0 is 4 wide, row 1 only 2. A cell at x=3 is inside row 0 and outside row 1.
    ragged = [["1", "1", "1", "1"], ["1", "1"]]
    hits = offworld(_m(ragged, [[" ", " ", " ", "cube"], [" ", " "]]))
    check("x=3 on the 4-wide row stays silent", hits == [])
    hits = offworld(_m(ragged, [[" ", " ", " ", " "], [" ", " ", " ", "cube"]]))
    check("x=3 on the 2-wide row convicts",
          len(hits) == 1 and hits[0]["kind"] == "PAST_EDGE" and hits[0]["row_width"] == 2)

    print()
    print("FILLER IS NOT A PLACEMENT")
    hits = offworld(_m([["1"]], [[" "], ["   "], [""]]))
    check("blank and whitespace cells past the end stay silent", hits == [])
    hits = offworld(_m([["1"]], [[" "], [" ", "x"]]))
    check("one real token among the filler still convicts", len(hits) == 1)

    print()
    print("BOTH OVERLAY LAYERS ARE READ, AND STRUCTURE IS NEVER ITS OWN VICTIM")
    hits = offworld(_m([["1"]], utilities=[[" "], ["t"]]))
    check("utilities is checked, not just interactables",
          len(hits) == 1 and hits[0]["layer"] == "utilities")
    hits = offworld(_m([["1"], ["1"], ["1"]]))
    check("a map with no overlay layers at all is silent", hits == [])
    hits = offworld({"layers": {"interactables": [["cube"]]}})
    check("no structure means no verdict, not a false conviction", hits == [])

    print()
    for label, ok in checks:
        print("  [%s]  %s" % ("ok" if ok else "FAIL", label))
    bad = [label for label, ok in checks if not ok]
    print()
    if bad:
        print("%d check(s) failed -- the detector does not do what it says" % len(bad))
        return 1
    print("all %d checks passed -- the detector convicts an off-world cell and "
          "acquits a ragged row" % len(checks))
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--json", action="store_true", help="machine-readable report")
    ap.add_argument("--selftest", action="store_true", help="run the detector's pair tests")
    args = ap.parse_args()

    if args.selftest:
        return selftest()

    findings, scanned = scan()
    cells = sum(len(v) for v in findings.values())
    past_end = sum(1 for v in findings.values() for h in v if h["kind"] == "PAST_END")

    if args.json:
        print(json.dumps(
            {
                "maps_scanned": scanned,
                "maps_affected": len(findings),
                "cells": cells,
                "past_end": past_end,
                "past_edge": cells - past_end,
                "findings": findings,
            },
            indent=1,
        ))
        return len(findings)

    print("=== OFF-WORLD CELLS ===")
    print("%d maps scanned" % scanned)
    if not findings:
        print()
        print("OK: every placement stands on a cell the structure has.")
        return 0

    for name in sorted(findings, key=lambda n: -len(findings[n])):
        hits = findings[name]
        print()
        print("  %s  (%d)" % (name, len(hits)))
        for h in hits:
            where = ("structure ends at row %d" % h["structure_depth"]
                     if h["kind"] == "PAST_END"
                     else "row %d is %d wide" % (h["z"], h["row_width"]))
            print("    %-13s (z=%d, x=%d)  %-38s %s"
                  % (h["layer"], h["z"], h["x"], h["cell"], where))

    print()
    print("FAIL: %d cell(s) in %d map(s) stand on coordinates the structure does not "
          "have -- %d past the last row, %d past their row's edge. The tokens resolve, "
          "the gates are green, and nothing is there."
          % (cells, len(findings), past_end, cells - past_end))
    return len(findings)


if __name__ == "__main__":
    sys.exit(main())
