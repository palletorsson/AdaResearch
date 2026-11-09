#!/usr/bin/env python3
"""Tests for tools/grammar_assembly.py (the grammar's assembly index), without Godot. Each check has a twin that
must come out DIFFERENT, so a rule that stopped working cannot pass by accident.

    python tools/test_grammar_assembly.py
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import grammar_assembly as ga  # noqa: E402

failed = 0


def check(what: str, ok: bool, data=None) -> None:
    global failed
    print(("ok   " if ok else "FAIL ") + what + ("" if ok else f"  {data}"))
    failed += 0 if ok else 1


def index(terms: dict, name: str) -> int:
    return ga.Assembly(terms).term(name)[0].__len__()


P = {"t": "point"}
mv = lambda node, x: {"op": "transform", "of": node, "at": [x, 0, 0]}
mesh = lambda s: {"p": "mesh", "shape": "box", "size": [s, s, s]}
T = {
    "point": {"build": {"p": "point"}},
    "eight_same": {"build": {"op": "compose", "parts": [mv(P, i) for i in range(8)]}},
    "eight_times": {"build": {"op": "times", "of": P, "n": 8, "layout": "row"}},
    "eight_distinct": {"build": {"op": "compose", "parts": [mesh(i + 1) for i in range(8)]}},
    "two_of_same": {"build": {"op": "compose", "parts": [{"t": "eight_same"}, mv({"t": "eight_same"}, 3)]}},
    "line": {"build": {"op": "compose", "parts": [mv(P, -0.5), mv(P, 0.5)]}},
    "named_line": {"build": {"op": "associate", "of": {"t": "line"}, "surface": "wood"}},
    "grid3": {"build": {"op": "array", "of": P, "n": [3, 3], "step": 1, "dims": 2}},
}

check("A a block costs nothing: point a = 0", index(T, "point") == 0, index(T, "point"))
check("B reuse: eight identical points composed = 3 joins (doubling), the same as `point * 8`",
      index(T, "eight_same") == 3 and index(T, "eight_times") == 3, (index(T, "eight_same"), index(T, "eight_times")))
check("B' twin: eight DIFFERENT parts cannot reuse - 7 joins", index(T, "eight_distinct") == 7, index(T, "eight_distinct"))
check("C a term used twice is built once: 3 (inside) + 1 (two copies) = 4, not 7",
      index(T, "two_of_same") == 4, index(T, "two_of_same"))
check("D a transform is the same object: line = 1 join (two points, reused); naming it adds 1 -> 2",
      index(T, "line") == 1 and index(T, "named_line") == 2, (index(T, "line"), index(T, "named_line")))
check("E an array counts its copies by doubling: 3 x 3 = 9 -> 4 joins", index(T, "grid3") == 4, index(T, "grid3"))

# the floor-order check: a work standing on floor 1 uses `line`, which first stands on its own on floor 5
work = {"build": {"op": "compose", "parts": [{"t": "line"}, mesh(2)]}}
terms = dict(T, work=work)
floors = [{"artifacts": []}, {"artifacts": [{"artifact": "work"}]}] + [{"artifacts": []}] * 3 + [{"artifacts": [{"artifact": "line"}]}]
r = ga.analyse(terms, floors, {"main": [], "environment": []})
e = r["used_before_shown"]
check("F used before shown: the work on floor 1 uses `line`, first standing on floor 5",
      len(e) == 1 and e[0]["work"] == "work" and e[0]["part"] == "line" and e[0]["part_first_floor"] == 5, e)
floors_ok = [{"artifacts": [{"artifact": "line"}]}, {"artifacts": [{"artifact": "work"}]}]
r2 = ga.analyse(terms, floors_ok, {"main": [], "environment": []})
check("F' twin: `line` shown first on floor 0, then used on floor 1 - nothing to report", not r2["used_before_shown"], r2["used_before_shown"])
check("G copy number and selection: `line` twice in the tower = n 2, selected e^1 x 1",
      ga.analyse(terms, [{"artifacts": [{"artifact": "line"}, {"artifact": "line"}]}], {"main": [], "environment": []})["placed"]["line"]["selected"] == 2.7)
check("H a timeline form maps a work to its term: token `oak_rail` with form term `line` counts as a line",
      "line" in ga.analyse(terms, [{"artifacts": [{"artifact": "oak_rail"}]}],
                           {"main": [{"key": "oak_rail", "form": {"term": "line"}}], "environment": []})["placed"])

print("all passed" if not failed else f"{failed} failed")
sys.exit(1 if failed else 0)
