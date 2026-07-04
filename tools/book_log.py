#!/usr/bin/env python3
"""book_log.py — the process feed: one dated line per event, append-only.

The book's record lives on five surfaces (RULINGS = decisions, STATE = position,
FIELD_JOURNAL = site drift, git = code, blog = narrative). This is the sixth and
simplest: a single chronological feed the whole toolchain appends to, so the
process can be followed like a log. Web face: /book-log in the encyclopedia.

As a library:   from book_log import log_event; log_event("dig", "…")
As a CLI:       python tools/book_log.py <kind> "<message>"

Kinds: ruling · draft · build · dig · drift · stage · room · ride · capture · note
log_event never raises — a broken feed must not break a tool.
"""
from __future__ import annotations

import datetime
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOG = os.path.join(REPO, "doc", "book", "LOG.md")
HEADER = (
    "# BOOK LOG — the process, as a feed\n\n"
    "> Append-only, machine-written by the toolchain (tools/book_log.py); newest last.\n"
    "> Decisions in full live in RULINGS.md; position in STATE.md; site drift in\n"
    "> FIELD_JOURNAL.md. This file is how you follow the process without reading them.\n\n"
)


def log_event(kind: str, message: str) -> None:
    try:
        os.makedirs(os.path.dirname(LOG), exist_ok=True)
        if not os.path.exists(LOG):
            with open(LOG, "w", encoding="utf-8") as f:
                f.write(HEADER)
        stamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
        with open(LOG, "a", encoding="utf-8") as f:
            f.write(f"- {stamp} · **{kind}** · {message}\n")
    except Exception:
        pass  # the feed must never break a tool


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    log_event(sys.argv[1], " ".join(sys.argv[2:]))
    print(f"logged [{sys.argv[1]}]")
