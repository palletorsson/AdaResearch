#!/usr/bin/env python3
"""Which placements sit on cells the structure grid does not have?

    python tools/check_offworld_cells.py            # human report, exit = maps affected
    python tools/check_offworld_cells.py --json     # machine report
    python tools/check_offworld_cells.py --selftest # the detector's own pair tests

WHY THIS EXISTS, WHEN FOUR INSTRUMENTS ALREADY READ THESE FILES

A map's three layers are separate grids that are only related by CONVENTION: cell
(z, x) of `interactables` means the artifact standing on cell (z, x) of `structure`.
Nothing enforces the shapes match. When they don't, the extra cells are not an error
anywhere -- so the artifact is authored, registered, resolvable, spelled correctly,
and either absent from the world or standing over nothing.

Measured on this corpus the day the detector was written (2026-08-31):

    62 non-empty cells across 29 maps stand on coordinates the structure does not have

and every gate was green over them:

    gate C  Map Validation ......... PASS
    gate G  Map Token Resolution ... PASS  (231 maps, 1323 placements, 0 unresolved --
                                            it asks whether a token NAMES something,
                                            never whether the cell EXISTS)

The pathfinder is the sharpest case, because it is not blind -- it is unweighted.
On Tutorial_Single it printed, in plain English:

    Rule 2 [WARN] Teleport at (2,18) -- no structure row at z=19 to catch player
    Rule 3 [WARN] Teleport at (2,18) is NOT reachable from spawn via walking
    === 1 maps checked: 1 OK, 0 FAIL (0 issues) ===   exit 0

A tutorial map whose only exit teleporter stood two rows past the end of the world,
reported as OK.

TWO FAULTS, NOT ONE -- AND A NUMBER IN map_info DECIDES WHICH (2026-09-01)

The first version of this file called every one of them "nothing is there". That is
true of fewer than half. Both overlay layers are placed by the same loop --

    GridUtilitiesComponent.generate_utilities   / GridInteractablesComponent, both:
    for z in range(min(dimensions.z, layout.size())):
        for x in range(min(dimensions.x, row.size())):

-- and `dimensions` comes from GridDataComponent, which takes it from
JsonMapLoader.get_dimensions(), which returns `map_info.dimensions` VERBATIM. The
engine sizes the world by the declared numbers; only the Python side
(place_artifacts.grid_dims_from_map) resolves size from `len(structure)`. So:

    UNREACHED   x >= declared width, or z >= declared depth. The loop never visits
                the cell. Authored and never built -- nothing is there.
    UNFLOORED   the loop DOES visit it, because the declaration is larger than the
                structure. The thing is built, and stands over void.

Vectors_6 and Vectors_1 carry the same authored cell -- an info board at (0, 8) above
a 7-wide structure row. Vectors_6 declares width 9, so its board floats one column
outside the world; Vectors_1 declares 7, so its board does not exist. One authored
mistake, two different repairs, and the difference is not in the cell.

WHAT THIS DOES NOT CLAIM

A ragged structure is normal -- rows of a map are allowed to be different widths, and
a short row is not damage. This only convicts a NON-EMPTY cell in `interactables` or
`utilities` whose coordinate has no structure cell under it at all. Whitespace-only
cells are the filler that keeps a row rectangular and are ignored, which is what makes
the ragged-row case safe; the self-test pins that in both directions.

Nor does it convict a cell that HAS a structure cell holding '0'. A teleporter is
supposed to stand on void (map_pathfinder rule 5), so "no floor" is not by itself a
fault; "no coordinate" is.

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


def declared(map_data: dict) -> tuple[int, int]:
    """(width, depth) exactly as the ENGINE reads them -- map_info.dimensions,
    verbatim, defaulting to 0 the way JsonMapLoader.get_dimensions() does. A
    zero here is not a missing datum: it is a world with no columns or no rows."""
    dims = (map_data.get("map_info") or {}).get("dimensions") or {}
    try:
        return int(dims.get("width", 0) or 0), int(dims.get("depth", 0) or 0)
    except (TypeError, ValueError):
        return 0, 0


def offworld(map_data: dict) -> list[dict]:
    """Every non-empty overlay cell with no structure cell beneath it.

    `verdict` is UNREACHED when the engine's placement loop never visits the
    cell (outside the DECLARED dimensions) and UNFLOORED when it does visit it
    and builds the thing over nothing. See the module docstring."""
    layers = map_data.get("layers")
    if not isinstance(layers, dict):
        return []
    structure = layers.get("structure")
    if not isinstance(structure, list) or not structure:
        return []
    d_width, d_depth = declared(map_data)

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
                    reached = z < d_depth and x < d_width
                    out.append(
                        {
                            "layer": layer_name,
                            "z": z,
                            "x": x,
                            "cell": cell.strip(),
                            "kind": kind,
                            "verdict": "UNFLOORED" if reached else "UNREACHED",
                            "structure_depth": len(structure),
                            "row_width": width,
                            "declared_width": d_width,
                            "declared_depth": d_depth,
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
    print("THE DECLARED DIMENSIONS DECIDE WHICH OF THE TWO FAULTS A CELL HAS")
    # The engine's loop runs to map_info.dimensions, not to len(structure). The
    # same authored cell is UNREACHED under one declaration and UNFLOORED under
    # another, so both directions get a case.
    small = {"map_info": {"dimensions": {"width": 2, "depth": 2}},
             "layers": {"structure": [["1", "1"], ["1", "1"]],
                        "utilities": [[" ", " "], [" ", " "], [" ", "t"]]}}
    hits = offworld(small)
    check("declared depth 2 does not reach row 2 -- UNREACHED",
          len(hits) == 1 and hits[0]["verdict"] == "UNREACHED")
    big = json.loads(json.dumps(small))
    big["map_info"]["dimensions"]["depth"] = 5
    hits = offworld(big)
    check("the SAME cell under declared depth 5 is built over void -- UNFLOORED",
          len(hits) == 1 and hits[0]["verdict"] == "UNFLOORED")
    wide = {"map_info": {"dimensions": {"width": 9, "depth": 1}},
            "layers": {"structure": [["1", "1", "1"]],
                       "utilities": [[" ", " ", " ", " ", "an:-90"]]}}
    check("a column inside the declared width but past the row is UNFLOORED",
          offworld(wide)[0]["verdict"] == "UNFLOORED")
    nodims = {"layers": {"structure": [["1"]], "utilities": [[" "], ["t"]]}}
    check("no declared dimensions at all means the loop reaches nothing",
          offworld(nodims)[0]["verdict"] == "UNREACHED")

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
    unreached = sum(1 for v in findings.values() for h in v
                    if h["verdict"] == "UNREACHED")

    if args.json:
        print(json.dumps(
            {
                "maps_scanned": scanned,
                "maps_affected": len(findings),
                "cells": cells,
                "past_end": past_end,
                "past_edge": cells - past_end,
                "unreached": unreached,
                "unfloored": cells - unreached,
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
        print("  %s  (%d)   declared %dw x %dd, structure %d rows"
              % (name, len(hits), hits[0]["declared_width"],
                 hits[0]["declared_depth"], hits[0]["structure_depth"]))
        for h in hits:
            where = ("structure ends at row %d" % h["structure_depth"]
                     if h["kind"] == "PAST_END"
                     else "row %d is %d wide" % (h["z"], h["row_width"]))
            print("    %-9s %-13s (z=%d, x=%d)  %-38s %s"
                  % (h["verdict"], h["layer"], h["z"], h["x"], h["cell"], where))

    print()
    print("FAIL: %d cell(s) in %d map(s) stand on coordinates the structure does not have."
          % (cells, len(findings)))
    print("  UNREACHED %3d -- outside the DECLARED dimensions, so the placement loop "
          "never visits them. Authored, resolvable, never built." % unreached)
    print("  UNFLOORED %3d -- inside the declared dimensions but past the structure, "
          "so they are built and stand over void." % (cells - unreached))
    print("  (%d past the last row, %d past their row's edge.)"
          % (past_end, cells - past_end))
    return len(findings)


if __name__ == "__main__":
    sys.exit(main())
