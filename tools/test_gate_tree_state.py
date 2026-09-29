"""Negative test for prop-025 clause 2 -- the per-row tree state on a failing gate.

A column that answers "modified" to everything is worse than no column: it
would have convicted the release on 2026-08-10 (sole failing row untracked)
and exonerated it on 2026-09-08 (five rooms tracked-and-modified). So the
cases here are chosen so that a classifier which collapses the three states
fails at least one of them.

Hermetic: the tracked set and the porcelain map are supplied, so the test
says the same thing on a clean clone and on a tree with 1300 dirty paths.

    python tools/test_gate_tree_state.py
"""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]

_spec = importlib.util.spec_from_file_location("rrg", REPO / "tools/run_release_gates.py")
assert _spec and _spec.loader
rrg = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(rrg)

FAILURES: list[str] = []


def check(name: str, got: object, want: object) -> None:
    if got != want:
        FAILURES.append(f"{name}\n     got  {got!r}\n     want {want!r}")
    else:
        print(f"  ok  {name}")


def classify(subjects: list[str], tracked: set[str], changed: dict[str, str]) -> dict:
    return rrg.classify_subjects(subjects, tracked, changed)


def main() -> int:
    print("=== gate tree-state detector selftest ===")

    # 1. THE 2026-08-10 SHAPE. A failing row whose only subject never landed.
    #    Calling this tracked-clean would blame the release for content that
    #    is not in it.
    # NB: fixture paths deliberately avoid the tools/ namespace. Gate H
    # collects every path under that directory NAMED anywhere in a gate
    # tool's source, so an invented one here lands in the release report as a
    # referenced tool absent from disk. It did, on the first run of this file
    # -- and then a second time, from the comment written to warn about it.
    v = classify(["fixture/brand_new.py"], tracked=set(), changed={"fixture/brand_new.py": "??"})
    check("untracked subject reads untracked", v.get("untracked"), 1)
    check("untracked subject is not tracked-clean", v.get("tracked_clean"), None)

    # 2. THE 2026-09-08 SHAPE. Tracked, and dirty in the working tree. HEAD is
    #    green; the disk is red; the two demand opposite actions.
    v = classify(
        ["commons/maps/X/critical.md"],
        tracked={"commons/maps/X/critical.md"},
        changed={"commons/maps/X/critical.md": " M"},
    )
    check("tracked + dirty reads tracked-modified", v.get("tracked_modified"), 1)
    check("tracked + dirty is not untracked", v.get("untracked"), None)

    # 3. THE CASE THAT MAKES THE COLUMN WORTH HAVING. Same file, same gate,
    #    nothing dirty -- this one IS a finding about the release, and a
    #    classifier that answers "modified" to everything fails here.
    v = classify(
        ["commons/maps/X/critical.md"],
        tracked={"commons/maps/X/critical.md"},
        changed={},
    )
    check("tracked + clean reads tracked-clean", v.get("tracked_clean"), 1)
    check("tracked + clean is not tracked-modified", v.get("tracked_modified"), None)

    # 4. A dirty sibling must not smear onto a clean subject. Prefix matching
    #    on directories is where that leaks.
    v = classify(
        ["commons/maps/X/critical.md"],
        tracked={"commons/maps/X/critical.md", "commons/maps/X/final.md"},
        changed={"commons/maps/X/final.md": " M"},
    )
    check("a dirty sibling does not convict a clean file", v.get("tracked_clean"), 1)

    # 5. A bare room name resolves to its directory, and the directory's
    #    dirtiest member decides. Gate I names rooms, not paths, which is why
    #    six occurrences of this fault were never attributable.
    room = "commons/maps/Point_Line_Grid"
    if (REPO / room).is_dir():
        v = classify(
            ["Point_Line_Grid"],
            tracked={f"{room}/critical.md"},
            changed={f"{room}/critical.md": " M"},
        )
        check("bare room name resolves and reads tracked-modified", v.get("tracked_modified"), 1)
        v = classify(["Point_Line_Grid"], tracked={f"{room}/critical.md"}, changed={})
        check("same room, clean tree, reads tracked-clean", v.get("tracked_clean"), 1)
    else:
        print("  skip  bare room name (Point_Line_Grid absent)")

    # 6. A name that is neither a path nor a room is NOT a subject. Reporting
    #    it as untracked would invent a file.
    v = classify(["Definitely_Not_A_Room_9x"], tracked=set(), changed={})
    check("an unresolvable name reads not-resolved", v.get("not_resolved"), 1)

    # 7. The metric scanner must not mine prose counters or selftest verdicts
    #    for filenames. gate K's open_not_counted and every detector_selftest
    #    would otherwise become dozens of phantom subjects.
    subs = rrg._metric_subjects(
        {
            "detector_selftest": "PASS",
            "open_not_counted": "empty 118 · stub 32",
            "reason": "contended_builder",
            "declared_case_mismatch": "none",
            "lost": 5,
            "unreachable": "fixture/a.py, fixture/b.py (26h)",
        }
    )
    check("only real subjects are mined", subs, ["fixture/a.py", "fixture/b.py"])

    # 7b. THE 2026-09-29 SHAPE. Gate I names rooms AND anchor files. The room
    #     is display only: resolved to its directory it lets a dirty
    #     map_data.json convict a clean critical.md.
    subs = rrg._metric_subjects(
        {"lost_rooms": "Point_Line_Grid", "lost_files": "commons/maps/Point_Line_Grid/critical.md"}
    )
    check("gate I is attributed by anchor file, not room", subs,
          ["commons/maps/Point_Line_Grid/critical.md"])
    v = classify(
        subs,
        tracked={"commons/maps/Point_Line_Grid/critical.md", "commons/maps/Point_Line_Grid/map_data.json"},
        changed={"commons/maps/Point_Line_Grid/map_data.json": " M"},
    )
    check("a lost anchor in a clean file reads tracked-clean", v.get("tracked_clean"), 1)
    check("edge row -> anchor file",
          rrg._edge_anchor_file({"map": "X", "why": "commons/maps/X/critical.md no longer says it"}),
          "commons/maps/X/critical.md")
    check("edge row with no path falls back to the room",
          rrg._edge_anchor_file({"map": "X", "why": "no anchor recorded"}), "X")

    # 8. A gate that names nothing must say so rather than read clean.
    v = classify([], tracked=set(), changed={})
    check("a gate with no named rows reports 0 subjects", v, {"subjects": 0})

    print("")
    if FAILURES:
        print(f"FAIL: {len(FAILURES)} case(s)")
        for f in FAILURES:
            print("  - " + f)
        return 1
    print("PASS: tree-state detector discriminates all three states")
    return 0


if __name__ == "__main__":
    sys.exit(main())
