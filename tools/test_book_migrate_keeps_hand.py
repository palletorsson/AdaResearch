#!/usr/bin/env python3
"""A migrate must not delete the hand's work.

    python tools/test_book_migrate_keeps_hand.py

`book.py migrate` rebuilds a chapter's book FROM THE TRUNK. Everything the trunk
does not carry was therefore erased by every migrate ever run — and the command
is documented in two places, including the message /lines prints when a chapter
has no book yet ("run python tools/book.py migrate --chapter X"). Run it once on
a chapter that already has one and the reflections, the adoptions, the hangs and
the visualizations are gone, with no error and no diff to read.

This test calls the real migrate against the real books, in memory. It never
writes. It fails if any key the book alone carries does not survive.
"""
from __future__ import annotations
import io
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

import book as B  # noqa: E402

BOOK_DIR = REPO / "commons" / "data" / "book"


def hand_keys(doc: dict) -> dict:
    """Every key in this book that the trunk does not own, counted."""
    out: dict[str, int] = {}
    for p in doc.get("pearls", []):
        for k in p:
            if k not in B.TRUNK_OWNS_PEARL:
                out[k] = out.get(k, 0) + 1
        for ln in p.get("lines", []):
            for k in ln:
                if k not in B.TRUNK_OWNS_LINE:
                    out["line." + k] = out.get("line." + k, 0) + 1
    return out


def main() -> int:
    fails: list[str] = []
    notes: list[str] = []
    chapters = sorted(p.stem for p in BOOK_DIR.glob("*.json"))
    if not chapters:
        print("no books to test"); return 1

    total_before: dict[str, int] = {}
    total_after: dict[str, int] = {}
    for ch in chapters:
        on_disk = json.load(io.open(BOOK_DIR / f"{ch}.json", encoding="utf-8"))
        before = hand_keys(on_disk)
        for k, n in before.items():
            total_before[k] = total_before.get(k, 0) + n
        try:
            fresh = B.migrate(ch)
        except SystemExit as e:      # a chapter the trunk does not hold
            notes.append(f"{ch}: skipped ({e})")
            for k, n in before.items():
                total_after[k] = total_after.get(k, 0) + n
            continue
        after = hand_keys(fresh)
        for k, n in after.items():
            total_after[k] = total_after.get(k, 0) + n
        for k, n in before.items():
            # a pearl the trunk has dropped entirely cannot carry anything, so
            # compare only what the fresh book still has pearls for
            got = after.get(k, 0)
            if got < n:
                fails.append(f"{ch}: {k} — {n} before, {got} after the migrate")

    # the reflection lane specifically: it is the point of the exercise, so it
    # is asserted even while empty, to pin the contract before the content exists
    for k in ("line.note", "line.viz", "adopt", "hang"):
        if k not in B.TRUNK_OWNS_PEARL and ("line." + k.split(".")[-1]) not in B.TRUNK_OWNS_LINE:
            continue
        fails.append(f"{k} is claimed by the trunk — a migrate would rebuild over it")

    print("A MIGRATE MUST NOT DELETE THE HAND'S WORK")
    print(f"  {len(chapters)} chapters")
    for k in sorted(set(total_before) | set(total_after)):
        b_, a_ = total_before.get(k, 0), total_after.get(k, 0)
        mark = "ok  " if a_ >= b_ else "LOST"
        print(f"  {mark} {k:22s} {b_:4d} before -> {a_:4d} after")
    for n in notes:
        print(f"  note {n}")
    for f in fails:
        print(f"  FAIL {f}")
    print(f"{len(fails)} fail(s)")
    return 1 if fails else 0


if __name__ == "__main__":
    raise SystemExit(main())
