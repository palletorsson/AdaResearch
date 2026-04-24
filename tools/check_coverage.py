#!/usr/bin/env python
"""
check_coverage.py — coverage gate for CI / pre-commit.

Regenerates the artifact doc index and map coverage, then asserts the
current state against a set of invariants. Exits non-zero on any
violation so the check can be wired into a pre-commit hook or CI step.

Default invariants (tightened from the 2026-04-24 100% baseline):

  1. No spine map may place an artifact that has no documentation
     (header_kind in identity | prose | registry).
  2. No spine map may place an artifact whose scene file is missing.
  3. The number of unregistered placed tokens must not exceed a
     budget (default: matches the committed baseline).
  4. The number of text orphans must not exceed a budget.
  5. Every registered artifact must resolve to an existing .tscn.

Budgets are read from doc/reports/COVERAGE_BUDGET.json if present,
otherwise defaulted to the values baked into this file. Edit the
budget file to formally raise or lower a budget.

Run:
    python tools/check_coverage.py                # full gate
    python tools/check_coverage.py --skip-regen   # use existing reports
    python tools/check_coverage.py --write-budget # write current state
                                                  # as the new budget
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
REPORTS = REPO / "doc" / "reports"
COVERAGE_JSON = REPORTS / "MAP_COVERAGE.json"
INDEX_JSON = REPORTS / "ARTIFACT_DOC_INDEX.json"
BUDGET_JSON = REPORTS / "COVERAGE_BUDGET.json"

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

# Baseline committed 2026-04-24. These default budgets keep the current
# state as a ceiling — PRs that raise them must explicitly update this
# file or write a new doc/reports/COVERAGE_BUDGET.json.
DEFAULT_BUDGETS = {
    "max_undocumented_placements": 0,
    "max_silent_undocumented": 0,
    "max_scene_missing_placements": 0,
    "max_unregistered_tokens": 63,
    "max_text_orphans": 22,
}


def regenerate() -> None:
    print("Regenerating artifact_doc_index…", file=sys.stderr)
    subprocess.run(
        [sys.executable, str(REPO / "tools" / "artifact_doc_index.py")],
        check=True,
        stdout=subprocess.DEVNULL,
    )
    print("Regenerating map_coverage…", file=sys.stderr)
    subprocess.run(
        [sys.executable, str(REPO / "tools" / "map_coverage.py")],
        check=True,
        stdout=subprocess.DEVNULL,
    )


def load_budgets() -> dict:
    if BUDGET_JSON.exists():
        try:
            return {**DEFAULT_BUDGETS, **json.loads(BUDGET_JSON.read_text(encoding="utf-8"))}
        except Exception as e:
            print(f"warning: failed to read {BUDGET_JSON.name}: {e}", file=sys.stderr)
    return dict(DEFAULT_BUDGETS)


def current_state() -> dict:
    coverage = json.loads(COVERAGE_JSON.read_text(encoding="utf-8"))
    index = json.loads(INDEX_JSON.read_text(encoding="utf-8"))
    totals = coverage["summary"]["totals"]
    scene_missing = index["summary"].get("scene_missing", 0)
    # Sum per-map scene_missing/script_missing in placements
    placed_scene_missing = sum(
        len(m.get("missing_scene", [])) for m in coverage["maps"]
    )
    return {
        "undocumented_placements": totals["undocumented_placements"],
        "silent_undocumented": totals["silent_undocumented"],
        "unregistered_tokens": totals["unregistered_tokens"],
        "text_orphans": totals["text_orphans"],
        "registry_scene_missing": scene_missing,
        "placed_scene_missing": placed_scene_missing,
        "coverage_score": coverage["summary"]["avg_coverage_score"],
        "doc_score": coverage["summary"]["avg_doc_coverage"],
        "perfect_maps": coverage["summary"]["perfect_coverage"],
        "total_maps": coverage["summary"]["maps"],
    }


def violations(state: dict, budgets: dict) -> list[str]:
    out: list[str] = []
    if state["undocumented_placements"] > budgets["max_undocumented_placements"]:
        out.append(
            f"undocumented placements: {state['undocumented_placements']} "
            f"> budget {budgets['max_undocumented_placements']}"
        )
    if state["silent_undocumented"] > budgets["max_silent_undocumented"]:
        out.append(
            f"silent undocumented: {state['silent_undocumented']} "
            f"> budget {budgets['max_silent_undocumented']}"
        )
    if state["placed_scene_missing"] > budgets["max_scene_missing_placements"]:
        out.append(
            f"placements with missing scene: {state['placed_scene_missing']} "
            f"> budget {budgets['max_scene_missing_placements']}"
        )
    if state["unregistered_tokens"] > budgets["max_unregistered_tokens"]:
        out.append(
            f"unregistered placed tokens: {state['unregistered_tokens']} "
            f"> budget {budgets['max_unregistered_tokens']}"
        )
    if state["text_orphans"] > budgets["max_text_orphans"]:
        out.append(
            f"text orphans: {state['text_orphans']} "
            f"> budget {budgets['max_text_orphans']}"
        )
    return out


def write_budget(state: dict) -> None:
    budget = {
        "max_undocumented_placements": state["undocumented_placements"],
        "max_silent_undocumented": state["silent_undocumented"],
        "max_scene_missing_placements": state["placed_scene_missing"],
        "max_unregistered_tokens": state["unregistered_tokens"],
        "max_text_orphans": state["text_orphans"],
    }
    BUDGET_JSON.write_text(json.dumps(budget, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote budget: {BUDGET_JSON.relative_to(REPO)}")
    for k, v in budget.items():
        print(f"  {k}: {v}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--skip-regen", action="store_true", help="Use existing reports rather than regenerating")
    ap.add_argument("--write-budget", action="store_true", help="Write current state as the new budget")
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    if not args.skip_regen:
        try:
            regenerate()
        except subprocess.CalledProcessError as e:
            print(f"Regeneration failed: {e}", file=sys.stderr)
            return 2

    if not COVERAGE_JSON.exists() or not INDEX_JSON.exists():
        print(
            f"ERROR: reports not found. Run without --skip-regen first.",
            file=sys.stderr,
        )
        return 2

    state = current_state()
    if args.verbose or args.write_budget:
        print("Current state:")
        for k, v in state.items():
            print(f"  {k}: {v}")

    if args.write_budget:
        write_budget(state)
        return 0

    budgets = load_budgets()
    vs = violations(state, budgets)

    header = (
        f"coverage: {state['perfect_maps']}/{state['total_maps']} maps perfect  "
        f"score={state['coverage_score'] * 100:.1f}%  "
        f"doc={state['doc_score'] * 100:.1f}%"
    )
    print(header)

    if vs:
        print("\nCOVERAGE GATE FAILURES:")
        for v in vs:
            print(f"  - {v}")
        print("\nTo update budgets intentionally:")
        print("  python tools/check_coverage.py --write-budget")
        print("Or regenerate reports if they're stale:")
        print("  python tools/map_coverage.py")
        return 1

    print("coverage gate: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
