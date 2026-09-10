"""Every cell in every map layer is a STRING -- a census of the corpus, by type.

WHY THIS EXISTS
---------------
The three layers of a map are grids of strings: "1", "2", "p", "sp", "" for the
empty cell, "artifact:rotation:y_offset" for a placement. That has been the
convention for as long as there have been maps, and until today nothing in
either language checked it.

IT HAS NOW BITTEN TWICE, TWO YEARS APART, IN TWO LANGUAGES.

  2026-08-24  A live museum walk crashed. GDScript's String() constructor
              throws "Invalid call" on a JSON number, and a hall's structure
              row held one. The engine side was swept to str() that day, which
              made the reader survive and left the data exactly as it was.

  2026-09-10  The encyclopedia's long-museum strip crashed on a different
              reader, in TypeScript, on the same eleven maps:
              TypeError: (v ?? "").trim is not a function. The `??` operator
              only catches null and undefined, so a number goes straight
              through and (1).trim is undefined. That reader was swept the same
              day, and the data was again left as it was.

Two victims, two sweeps of the READER, zero checks of the DATA. A third reader
written tomorrow inherits the same trap, and the trap is not always a crash:
the silent form is a comparison. A structure test spelled `cell == "1"` is
False against the integer 1, so a floor tile reads as void and a room quietly
loses its floor with nothing printed anywhere. A crash gets fixed in an hour.
A wrong answer does not get found at all.

So the population this gate asks about is the DATA, once, rather than each
reader as it is discovered. Fixing readers is unbounded work; there is one
corpus.

WHAT IT CONVICTS, AND WHAT IT ONLY COUNTS
-----------------------------------------
Measured across the corpus on 2026-09-10 before this gate was written:
3,578,745 cells, of which 3,578,112 are strings and 633 are integers, in 11
maps, all in the structure layer. No nulls. No nested lists or objects. No
layer that is not a list of lists. The convicted set is therefore exactly the
633 and the innocent set is exactly everything else -- this gate has no grey
band to argue about, which is rare enough to say out loud.

  convicted  any cell in structure / utilities / interactables that is not a
             string. Integers and floats are the live case; booleans, nulls,
             lists and objects are convicted too, on the same grounds, and none
             of them exist today.
  counted    whether the offending map is modified in the working tree, printed
             as `in_working_tree`. Several sessions edit this repo at once and
             one of the eleven maps was somebody's open buffer the day this was
             written. That is worth SEEING and it is not a defence: the cell is
             the wrong type in HEAD too, and a verdict that rides on who has a
             file open is a verdict about the day, not about the data. Gate L
             settled this shape on 2026-09-09 -- report the state, convict the
             fact.

WHAT IT DOES NOT CHECK, ON PURPOSE
----------------------------------
The VOCABULARY. Whether "1" is a legal structure height, whether an
interactables cell names a registered artifact, whether a utilities token
parses -- those have their own gates, and pulling them in here would make one
red row mean four different things. This gate answers one question and the
answer is a type.

    python tools/check_cell_types.py            # human
    python tools/check_cell_types.py --json     # machine-readable
    python tools/check_cell_types.py --selftest # the gate still bites
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parents[1]
MAPS_DIR = REPO / "commons" / "maps"
LAYERS = ("structure", "utilities", "interactables")

# How many offending cells to name per map before the report says "and N more".
# Eleven maps at 63 cells each is 633 rows of identical text; the shape is
# carried by the first few and the count.
SAMPLE_PER_MAP = 4


def layer_dict(doc: Any) -> dict:
    """Map JSON nests the three layers under `layers`; a few older files do not."""
    if not isinstance(doc, dict):
        return {}
    inner = doc.get("layers")
    if isinstance(inner, dict):
        return inner
    return doc


def scan_document(doc: Any) -> tuple[int, list[dict]]:
    """Return (cells_seen, offences) for one parsed map document."""
    layers = layer_dict(doc)
    seen = 0
    offences: list[dict] = []
    for layer_name in LAYERS:
        layer = layers.get(layer_name)
        if not isinstance(layer, list):
            # A missing layer is somebody else's gate. A layer that is present
            # but not a grid is this gate's business, because every reader in
            # the project indexes it as [row][col].
            if layer is not None:
                offences.append(
                    {
                        "layer": layer_name,
                        "row": -1,
                        "col": -1,
                        "kind": type(layer).__name__,
                        "value": "<layer is not a list>",
                    }
                )
            continue
        for r, row in enumerate(layer):
            if not isinstance(row, list):
                offences.append(
                    {
                        "layer": layer_name,
                        "row": r,
                        "col": -1,
                        "kind": type(row).__name__,
                        "value": "<row is not a list>",
                    }
                )
                continue
            for c, cell in enumerate(row):
                seen += 1
                if isinstance(cell, str):
                    continue
                offences.append(
                    {
                        "layer": layer_name,
                        "row": r,
                        "col": c,
                        "kind": type(cell).__name__,
                        "value": repr(cell)[:40],
                    }
                )
    return seen, offences


def modified_maps() -> set[str]:
    """Map names whose map_data.json is dirty in the working tree right now."""
    try:
        out = subprocess.run(
            ["git", "status", "--porcelain", "--", "commons/maps"],
            cwd=REPO,
            capture_output=True,
            text=True,
            timeout=120,
        ).stdout
    except Exception:
        return set()
    dirty: set[str] = set()
    for line in out.splitlines():
        path = line[3:].strip().strip('"')
        parts = path.split("/")
        if len(parts) >= 4 and parts[-1] == "map_data.json":
            dirty.add(parts[2])
    return dirty


def census() -> dict:
    dirty = modified_maps()
    maps_scanned = 0
    cells_scanned = 0
    unreadable: list[str] = []
    offenders: list[dict] = []
    for path in sorted(MAPS_DIR.glob("*/map_data.json")):
        name = path.parent.name
        try:
            doc = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            unreadable.append("%s (%s)" % (name, type(exc).__name__))
            continue
        maps_scanned += 1
        seen, offences = scan_document(doc)
        cells_scanned += seen
        if offences:
            kinds = sorted({o["kind"] for o in offences})
            offenders.append(
                {
                    "map": name,
                    "count": len(offences),
                    "kinds": kinds,
                    "layers": sorted({o["layer"] for o in offences}),
                    "in_working_tree": name in dirty,
                    "sample": offences[:SAMPLE_PER_MAP],
                }
            )
    offenders.sort(key=lambda o: (-o["count"], o["map"]))
    bad_cells = sum(o["count"] for o in offenders)
    return {
        "maps_scanned": maps_scanned,
        "cells_scanned": cells_scanned,
        "unreadable": unreadable,
        "maps_with_non_string_cells": len(offenders),
        "non_string_cells": bad_cells,
        "in_working_tree": sum(1 for o in offenders if o["in_working_tree"]),
        "offenders": offenders,
    }


def render(report: dict) -> str:
    lines: list[str] = []
    lines.append("CELLS ARE STRINGS")
    lines.append("=" * 60)
    lines.append(
        "scanned      %d maps, %d cells"
        % (report["maps_scanned"], report["cells_scanned"])
    )
    lines.append(
        "convicted    %d cells in %d maps"
        % (report["non_string_cells"], report["maps_with_non_string_cells"])
    )
    if report["in_working_tree"]:
        lines.append(
            "counted      %d of those maps are modified in the working tree -- "
            "somebody has them open, which is not a defence" % report["in_working_tree"]
        )
    if report["unreadable"]:
        lines.append("unreadable   %s" % ", ".join(report["unreadable"]))
    lines.append("")
    if not report["offenders"]:
        lines.append("Every cell in every layer is a string.")
        return "\n".join(lines)
    for off in report["offenders"]:
        flag = "  [open in working tree]" if off["in_working_tree"] else ""
        lines.append(
            "%-52s %4d  %s in %s%s"
            % (
                off["map"],
                off["count"],
                "/".join(off["kinds"]),
                "/".join(off["layers"]),
                flag,
            )
        )
        for s in off["sample"]:
            lines.append(
                "        %s[%d][%d] = %s (%s)"
                % (s["layer"], s["row"], s["col"], s["value"], s["kind"])
            )
        if off["count"] > len(off["sample"]):
            lines.append("        ... and %d more" % (off["count"] - len(off["sample"])))
    lines.append("")
    lines.append(
        "A number here does not always crash. `cell == \"1\"` is False against the"
    )
    lines.append("integer 1, so the floor reads as void and nothing is printed.")
    return "\n".join(lines)


# --------------------------------------------------------------------------
# The negative half. Every gate in this battery convicted something innocent on
# its first run, so this one is fixtured against the shapes it must NOT convict
# as much as the one it must.
# --------------------------------------------------------------------------

CLEAN = {
    "layers": {
        "structure": [["1", "1"], ["1", "0"]],
        "utilities": [["", "sp"], ["", ""]],
        "interactables": [["", ""], ["", "pick_up_cube:0:0"]],
    }
}

FIXTURES = [
    ("a clean map is not convicted", CLEAN, 0),
    (
        "one integer in structure is convicted",
        {
            "layers": {
                "structure": [["1", 1], ["1", "0"]],
                "utilities": [["", ""], ["", ""]],
                "interactables": [["", ""], ["", ""]],
            }
        },
        1,
    ),
    (
        "a whole numeric structure layer is convicted cell by cell",
        {
            "layers": {
                "structure": [[1, 1], [1, 0]],
                "utilities": [["", ""], ["", ""]],
                "interactables": [["", ""], ["", ""]],
            }
        },
        4,
    ),
    (
        "a float, a bool and a null are convicted on the same grounds",
        {
            "layers": {
                "structure": [["1", 1.5], [True, None]],
                "utilities": [["", ""], ["", ""]],
                "interactables": [["", ""], ["", ""]],
            }
        },
        3,
    ),
    (
        "a numeric-looking STRING is innocent -- this is the whole convention",
        {
            "layers": {
                "structure": [["1", "2"], ["12", "0"]],
                "utilities": [["", ""], ["", ""]],
                "interactables": [["", ""], ["", ""]],
            }
        },
        0,
    ),
    (
        "the empty string is innocent, and is most of the corpus",
        {
            "layers": {
                "structure": [["", ""], ["", ""]],
                "utilities": [["", ""], ["", ""]],
                "interactables": [["", ""], ["", ""]],
            }
        },
        0,
    ),
    (
        "a layer flat at the top level, without the layers wrapper",
        {
            "structure": [["1", 1]],
            "utilities": [["", ""]],
            "interactables": [["", ""]],
        },
        1,
    ),
    (
        "a missing layer is another gate's verdict, not this one's",
        {"layers": {"structure": [["1", "1"]]}},
        0,
    ),
    (
        "a layer that is present but not a grid is convicted once",
        {"layers": {"structure": "1111", "utilities": [["", ""]]}},
        1,
    ),
    (
        "a row that is not a list is convicted once, and its siblings still scan",
        {"layers": {"structure": [["1", "1"], "11", ["1", 1]]}},
        2,
    ),
    (
        "extra keys beside the layers are ignored",
        {
            "name": "X",
            "modifiers": [{"op": "raise"}],
            "layers": CLEAN["layers"],
        },
        0,
    ),
]


def selftest() -> int:
    failures = 0
    for label, doc, expected in FIXTURES:
        _, offences = scan_document(doc)
        got = len(offences)
        ok = got == expected
        if not ok:
            failures += 1
        print("  %-4s %-62s expected %d, got %d" % ("ok" if ok else "FAIL", label, expected, got))

    # The census must also survive the real corpus without throwing, and must
    # agree with itself: the offender counts sum to the headline.
    report = census()
    total = sum(o["count"] for o in report["offenders"])
    if total != report["non_string_cells"]:
        print("  FAIL census headline %d != sum of offenders %d" % (report["non_string_cells"], total))
        failures += 1
    else:
        print("  ok   census headline agrees with its own rows")
    if report["maps_scanned"] <= 0:
        print("  FAIL an empty scan is a broken check, not a green one")
        failures += 1
    else:
        print("  ok   scan is non-empty (%d maps)" % report["maps_scanned"])

    print("selftest: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
    return 1 if failures else 0


def main() -> int:
    ap = argparse.ArgumentParser(description="Every map layer cell is a string.")
    ap.add_argument("--json", action="store_true", help="machine-readable report")
    ap.add_argument("--selftest", action="store_true", help="prove the gate bites")
    args = ap.parse_args()

    if args.selftest:
        return selftest()

    report = census()
    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=True))
    else:
        print(render(report))
    return 1 if report["non_string_cells"] else 0


if __name__ == "__main__":
    sys.exit(main())
