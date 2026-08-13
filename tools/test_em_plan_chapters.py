"""NT1 from spike 04 — every chapter the spine run assigned must be able to find
ITS OWN plan, not a stranger's.

The v1 schema keyed em_plan.json by BUILDING alone, first-wins. Six crowned
chapters were displaced by an uncrowned chapter that reached the same building
earlier in the rotation, so `change` looked up grande-galerie-axial and received
symmetry's cast — a substitution, not a shortfall, and silent until the banner
learned to print the chapter name.

This test gates the v2 schema: a `plans` array keyed by (museum, sequence).
It must FAIL against a v1 file — that failure is the finding, phrased as the
spike phrases it: `change -> grande-galerie-axial: plan holds 'symmetry'`.

Pure Python, no Godot. Joins the discover suite.
"""
from __future__ import annotations

import json
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PLAN = REPO / "ada_run" / "em_plan.json"


def lookup(plan: dict, museum: str, seq: str):
    """The reader's resolution order: chapter-keyed v2 first, v1 fallback."""
    for row in plan.get("plans", []):
        if row.get("museum") == museum and row.get("sequence") == seq:
            return row
    entry = plan.get("museums", {}).get(museum)
    return entry if entry is not None else None


class ChapterKeyedPlan(unittest.TestCase):
    def test_every_assigned_chapter_finds_its_own_plan(self):
        if not PLAN.exists():
            self.skipTest("no em_plan.json — run spine_run --write-plan first")
        plan = json.loads(PLAN.read_text(encoding="utf-8"))
        owner = (plan.get("_spine_run") or {}).get("owner") or {}
        displaced = (plan.get("_spine_run") or {}).get("displaced") or []
        if not owner and not displaced:
            self.skipTest("plan carries no _spine_run block to check against")

        # every chapter the run touched: the owners plus the displaced
        wanted: list[tuple[str, str]] = [(seq, key) for key, seq in owner.items()]
        wanted += [(d["sequence"], d["museum"]) for d in displaced]

        problems: list[str] = []
        for seq, museum in wanted:
            entry = lookup(plan, museum, seq)
            if entry is None:
                problems.append(f"{seq} -> {museum}: no plan at all")
            elif str(entry.get("sequence", "")) != seq:
                problems.append(
                    f"{seq} -> {museum}: plan holds {entry.get('sequence')!r}")
        self.assertEqual(problems, [],
            "\n  " + "\n  ".join(problems) if problems else "")


if __name__ == "__main__":
    unittest.main()
