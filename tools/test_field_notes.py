#!/usr/bin/env python3
"""A reflection must report the wall it was written at, or none at all.

    python tools/test_field_notes.py

THE CHAIN TO THE WALL IS TWO LINKS. `hang.page` and `adopt.page` both count
SHOWINGS — the wall works in a segment, numbered by the dresser — while a line is
numbered by its position in the pearl, which also counts text-only lines and
every body that hangs nothing. Those are different numbers that are both
integers, so looking a hang up by line index returns a confident wrong cell
rather than an error. It did, until this test existed.

So the fixture is built to make the two disagree: the noted line sits at index 6,
and there is a hang row for page 6 pointing somewhere absurd. Anything that
reads the line index gets 99,99. Only the adopt-then-hang chain gets 10,7.
"""
from __future__ import annotations
import json
import sys
import unittest.mock as mock
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

import field_notes as F  # noqa: E402


def gather_one(doc: dict) -> dict:
    with mock.patch.object(F, "spine_order", lambda: ["primitives"]), \
            mock.patch("pathlib.Path.read_text", lambda self, **k: json.dumps(doc)):
        return F.gather()


def main() -> int:
    fails: list[str] = []
    notes: list[str] = []

    pearl = {
        "pearl": "point one", "map": "Point_One",
        "adopt": [{"page": 3, "token": "origin"}],
        # page 3 is the one the adoption names; page 6 is the trap — it is the
        # LINE index of the noted line, and it points nowhere real
        "hang": [{"page": 3, "cell": [10, 7], "dir": [1, 0]},
                 {"page": 6, "cell": [99, 99], "dir": [0, 1]}],
        "lines": [{"text": "the hall's own wall text"},
                  {"token": "a"}, {"token": "b"}, {"token": "c"},
                  {"token": "d"}, {"token": "e"},
                  {"token": "origin", "text": "The origin.",
                   "note": "It is not a place, it is an agreement."}],
    }
    g = gather_one({"chapter": "primitives", "pearls": [pearl]})

    rows = (g["chapters"][0]["pearls"][0]["notes"] if g["chapters"] else [])
    if len(rows) != 1:
        fails.append("expected exactly one reflection, got %d" % len(rows))
        _report(fails, notes); return 1
    r = rows[0]

    if r["token"] != "origin":
        fails.append("the reflection came back on token %r" % r["token"])
    elif r["note"] != "It is not a place, it is an agreement.":
        fails.append("the reflection's text did not survive")
    else:
        notes.append("the reflection is read off the line that carries it")

    if r["hang"] is None:
        fails.append("no wall reported, though the hand ruled one through adopt")
    elif r["hang"]["cell"] == [99, 99]:
        fails.append("THE LINE INDEX WAS USED AS A PAGE: reported cell 99,99, "
                     "which is the trap row, not the adopted page's face")
    elif r["hang"]["cell"] != [10, 7]:
        fails.append("reported cell %s, the adopted page hangs at 10,7" % r["hang"]["cell"])
    else:
        notes.append("the wall is found through adopt then hang (cell 10,7), "
                     "not through the line index (which would say 99,99)")

    # a token nobody adopted must report NO wall rather than guessing one
    p2 = dict(pearl)
    p2["adopt"] = []
    g2 = gather_one({"chapter": "primitives", "pearls": [p2]})
    r2 = g2["chapters"][0]["pearls"][0]["notes"][0]
    if r2["hang"] is not None:
        fails.append("with no adoption it still reported a wall: %s" % r2["hang"])
    else:
        notes.append("with no adoption it reports no wall, rather than a wrong one")

    # and the render must not fall over on either shape
    try:
        out = F.render(g)
        if "10,7" not in out:
            fails.append("the document does not mention the cell it found")
        elif "It is not a place" not in out:
            fails.append("the document does not carry the reflection")
        else:
            notes.append("the document carries the reflection and its cell")
    except Exception as e:
        fails.append("render raised: %r" % e)

    _report(fails, notes)
    return 1 if fails else 0


def _report(fails: list[str], notes: list[str]) -> None:
    print("A REFLECTION MUST REPORT THE RIGHT WALL, OR NONE")
    for n in notes:
        print("  ok   " + n)
    for f in fails:
        print("  FAIL " + f)
    print("%d fail(s)" % len(fails))


if __name__ == "__main__":
    raise SystemExit(main())
