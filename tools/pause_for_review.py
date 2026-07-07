#!/usr/bin/env python3
"""
pause_for_review.py — declare a hold that must be cleared before the loop continues.

This is the substrate for *propose, hold, return*. A session that has
produced proposals (sieve docs, structural moves, artifact placements)
writes a hold via this tool. The /loop skill (and any other skill that
honors the convention) reads `ada_run/pause_holds.md` before continuing
and refuses to proceed if any holds are unresolved.

Holds are cleared either:
  - by the user resolving each chip via the encyclopedia's /sieve-proposals
    page (apply or defer or reject), which atomically advances the related
    proposal record's status away from `pending`
  - by explicit `python tools/pause_for_review.py --clear <hold_id>`

The check function `check_holds()` is used by callers (`/loop` skill, this
tool's CLI) to decide whether a session is allowed to continue.

Usage:
    python tools/pause_for_review.py --declare --reason "..." --linked-pass <id>
    python tools/pause_for_review.py --check         # exit 0 if clear, 2 if held
    python tools/pause_for_review.py --list
    python tools/pause_for_review.py --clear <hold_id>

Background:
  doc/proposals/2026-05-13_chip-and-pause.md
  /blog/2026-05-13-the-hold-collapsed
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path
from typing import Optional

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

REPO_ROOT = Path(__file__).resolve().parent.parent
ADA_RUN = REPO_ROOT / "ada_run"
HOLDS_PATH = ADA_RUN / "pause_holds.md"
HOLDS_JSON = ADA_RUN / "pause_holds.json"
PROPOSALS_DIR = REPO_ROOT / "data" / "sieve_proposals"


def _now() -> str:
    return dt.datetime.now().isoformat(timespec="seconds")


def load_holds() -> list[dict]:
    if not HOLDS_JSON.exists():
        return []
    try:
        return json.loads(HOLDS_JSON.read_text(encoding="utf-8"))
    except Exception:
        return []


def write_holds(holds: list[dict]) -> None:
    ADA_RUN.mkdir(parents=True, exist_ok=True)
    HOLDS_JSON.write_text(json.dumps(holds, indent="\t", ensure_ascii=False) + "\n", encoding="utf-8")
    # Mirror to markdown for human readability and bridge compatibility.
    lines: list[str] = []
    lines.append("# Pause holds")
    lines.append("")
    lines.append("Holds declared by sessions that produced proposals but have not yet been")
    lines.append("reviewed. Skills that honor *propose, hold, return* must NOT continue while")
    lines.append("any hold below is active.")
    lines.append("")
    if not holds:
        lines.append("_No active holds._")
    else:
        for h in holds:
            status = h.get("status", "active")
            lines.append(f"## {h.get('id')} — {status}")
            lines.append("")
            lines.append(f"- declared: {h.get('declared_at')}")
            lines.append(f"- reason: {h.get('reason')}")
            if h.get("linked_pass"):
                lines.append(f"- linked pass: `{h['linked_pass']}`")
                pending = pending_count_for_pass(h["linked_pass"])
                lines.append(f"- pending proposals: {pending}")
            if h.get("cleared_at"):
                lines.append(f"- cleared: {h['cleared_at']} ({h.get('cleared_by', '?')})")
            lines.append("")
    HOLDS_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


def pending_count_for_pass(pass_id: str) -> int:
    """Count proposals in the named pass that still have status=pending."""
    if not PROPOSALS_DIR.exists():
        return 0
    matches = list(PROPOSALS_DIR.glob(f"*{pass_id}*_proposals.json"))
    if not matches:
        return 0
    count = 0
    for jf in matches:
        try:
            data = json.loads(jf.read_text(encoding="utf-8"))
            for p in data.get("proposals", []):
                if p.get("status") == "pending":
                    count += 1
        except Exception:
            continue
    return count


def declare_hold(reason: str, linked_pass: Optional[str]) -> str:
    holds = load_holds()
    hold_id = f"hold_{dt.datetime.now().strftime('%Y%m%dT%H%M%S')}"
    holds.append({
        "id": hold_id,
        "declared_at": _now(),
        "reason": reason,
        "linked_pass": linked_pass,
        "status": "active",
    })
    write_holds(holds)
    return hold_id


def auto_clear_resolved_holds(holds: list[dict]) -> int:
    """For each hold linked to a pass, mark cleared if no pending proposals remain.
    Returns the number of holds auto-cleared."""
    changed = 0
    for h in holds:
        if h.get("status") != "active":
            continue
        linked = h.get("linked_pass")
        if not linked:
            continue
        if pending_count_for_pass(linked) == 0:
            h["status"] = "cleared"
            h["cleared_at"] = _now()
            h["cleared_by"] = "auto (linked pass fully resolved)"
            changed += 1
    return changed


def check_holds() -> tuple[bool, list[dict]]:
    """Return (clear?, list_of_active_holds). Auto-clears resolved-by-chip holds."""
    holds = load_holds()
    if auto_clear_resolved_holds(holds):
        write_holds(holds)
    active = [h for h in holds if h.get("status") == "active"]
    return len(active) == 0, active


def clear_hold(hold_id: str, note: str = "manual --clear") -> bool:
    holds = load_holds()
    for h in holds:
        if h.get("id") == hold_id and h.get("status") == "active":
            h["status"] = "cleared"
            h["cleared_at"] = _now()
            h["cleared_by"] = note
            write_holds(holds)
            return True
    return False


def list_holds() -> None:
    holds = load_holds()
    if not holds:
        print("No holds.")
        return
    for h in holds:
        marker = "ACTIVE " if h.get("status") == "active" else "cleared"
        line = f"  [{marker}] {h['id']}  reason='{h['reason']}'"
        if h.get("linked_pass"):
            line += f"  linked={h['linked_pass']}"
            pc = pending_count_for_pass(h["linked_pass"])
            line += f"  pending={pc}"
        print(line)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--declare", action="store_true", help="Declare a new hold.")
    parser.add_argument("--reason", help="Reason for the hold (required with --declare).")
    parser.add_argument("--linked-pass", dest="linked_pass", help="Sieve pass id this hold is linked to. Used for auto-clear.")
    parser.add_argument("--check", action="store_true", help="Exit 0 if no active holds, 2 if held. Auto-clears resolved holds first.")
    parser.add_argument("--list", action="store_true", help="List all holds (active + cleared).")
    parser.add_argument("--clear", metavar="HOLD_ID", help="Explicitly mark a hold cleared.")
    args = parser.parse_args()

    if args.declare:
        if not args.reason:
            print("--reason is required with --declare", file=sys.stderr)
            return 1
        hid = declare_hold(args.reason, args.linked_pass)
        print(f"declared hold: {hid}")
        if args.linked_pass:
            pc = pending_count_for_pass(args.linked_pass)
            print(f"  linked pass {args.linked_pass}: {pc} pending proposals")
        print(f"  see {HOLDS_PATH.relative_to(REPO_ROOT)}")
        return 0

    if args.check:
        clear, active = check_holds()
        if clear:
            print("clear: no active holds")
            return 0
        print(f"HELD: {len(active)} active hold(s)")
        for h in active:
            print(f"  - {h['id']}: {h['reason']}")
            if h.get("linked_pass"):
                print(f"      pending in pass {h['linked_pass']}: {pending_count_for_pass(h['linked_pass'])}")
        print(f"\nResolve via /sieve-proposals UI, or `python tools/pause_for_review.py --clear <hold_id>`")
        return 2

    if args.clear:
        if clear_hold(args.clear):
            print(f"cleared: {args.clear}")
            return 0
        print(f"not found or already cleared: {args.clear}", file=sys.stderr)
        return 1

    if args.list:
        list_holds()
        return 0

    parser.print_help()
    return 1


if __name__ == "__main__":
    sys.exit(main())
