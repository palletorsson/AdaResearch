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


def log_event(kind: str, message: str, image: str | None = None, alt: str = "",
              spark: list | None = None) -> None:
    """Append one event. Optional attachments:
    image — a web path the encyclopedia serves (e.g. /artifact-gallery/captures/x/front.png
            or /book-log/<file>); rendered as a thumbnail on /book-log.
    spark — a small number series (e.g. a scale melody, gaze angles per station);
            rendered as an inline sparkline. Stored as plain markdown either way."""
    try:
        os.makedirs(os.path.dirname(LOG), exist_ok=True)
        if not os.path.exists(LOG):
            with open(LOG, "w", encoding="utf-8", newline="\n") as f:
                f.write(HEADER)
        extra = ""
        if spark:
            vals = ",".join(str(round(float(v), 1)).rstrip("0").rstrip(".") for v in spark)
            extra += f" `spark:[{vals}]`"
        if image:
            extra += f" ![{alt or 'attachment'}]({image})"
        stamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
        with open(LOG, "a", encoding="utf-8", newline="\n") as f:
            f.write(f"- {stamp} · **{kind}** · {message}{extra}\n")
    except Exception:
        pass  # the feed must never break a tool


if __name__ == "__main__":
    argv = sys.argv[1:]
    image = next((a.split("=", 1)[1] for a in argv if a.startswith("--image=")), None)
    alt = next((a.split("=", 1)[1] for a in argv if a.startswith("--alt=")), "")
    spark_s = next((a.split("=", 1)[1] for a in argv if a.startswith("--spark=")), None)
    rest = [a for a in argv if not a.startswith("--")]
    if len(rest) < 2:
        print(__doc__)
        sys.exit(1)
    spark = [float(x) for x in spark_s.split(",")] if spark_s else None
    log_event(rest[0], " ".join(rest[1:]), image=image, alt=alt, spark=spark)
    print(f"logged [{rest[0]}]" + (" +img" if image else "") + (" +spark" if spark else ""))
