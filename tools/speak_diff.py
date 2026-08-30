#!/usr/bin/env python3
"""WHICH OF PALLE'S OWN LINES NEVER REACHED THE BOOK.

    python tools/speak_diff.py               # the report
    python tools/speak_diff.py --all         # every tag, not only [hand]
    python tools/speak_diff.py --json

2026-08-30. A survey of every text repo asked where the best writing is. The
answer was mostly "argument about the corpus, outside the pipeline" — but one
file inside the pipeline turned out to be a SUPERSET of the book and nobody had
diffed it.

doc/SPEAK.md is 966 lines, one per chapter, per pearl, per body, each attributed:
[hand] Palle, [claude] written in his register, [draft] the corpus's own words.
No tool writes it and no tool reads it. Some of its [hand] lines are in
commons/data/book/*.json and some are not, and until this ran nobody knew which.

WHAT COUNTS AS LANDED, and the rule is deliberately generous. SPEAK joins a
poem's lines with spaces; the book keeps the newlines. So both sides are
collapsed to single-spaced lowercase and a line counts as landed if either
contains the other. A generous rule errs toward saying "already in", which
under-reports the find — the opposite error would send Palle to re-enter lines
that are already there, which is worse than missing one.

The report says WHERE each missing line was addressed to, because SPEAK carries
the chapter and pearl above it. That is the difference between "here are some
orphaned sentences" and "this line was written for that hall and never arrived".
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SPEAK = REPO / "doc" / "SPEAK.md"

sys.path.insert(0, str(REPO / "tools"))
from concord import book_lines  # noqa: E402

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

TAG = re.compile(r"^(.*?)\s*`\[(hand|claude|draft)\]`\s*$")


def norm(s: str) -> str:
    s = re.sub(r"^>\s*", "", str(s or ""))
    return re.sub(r"\s+", " ", s).strip().lower()


def parse() -> list:
    """Every attributed line, with the chapter and pearl standing over it."""
    rows, chapter, pearl = [], "", ""
    for i, raw in enumerate(SPEAK.read_text(encoding="utf-8").split("\n"), 1):
        line = raw.rstrip()
        if line.startswith("## "):
            chapter, pearl = line[3:].strip(), ""
            continue
        if line.startswith("### "):
            pearl = line[4:].strip()
            continue
        m = TAG.match(line)
        if not m:
            continue
        text = re.sub(r"^>\s*", "", m.group(1)).strip()
        if not text:
            continue    # the bare `[hand]` under a blockquote tags the line above
        rows.append({"n": i, "chapter": chapter, "pearl": pearl,
                     "tag": m.group(2), "text": text})
    return rows


def main() -> int:
    ap = argparse.ArgumentParser(description="which SPEAK lines never reached the book")
    ap.add_argument("--all", action="store_true", help="every tag, not only [hand]")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()

    if not SPEAK.exists():
        print("no doc/SPEAK.md", file=sys.stderr)
        return 2

    rows = parse()
    want = rows if a.all else [r for r in rows if r["tag"] == "hand"]

    bl = book_lines()
    book = [{"chapter": l["chapter"], "pearl": l["pearl"], "token": l["token"],
             "text": l["text"], "n": norm(l["text"])} for l in bl if str(l.get("text", "")).strip()]

    out = []
    for r in want:
        q = norm(r["text"])
        where = None
        if len(q) >= 8:
            for b in book:
                if q in b["n"] or b["n"] in q:
                    where = b
                    break
        out.append({**r, "landed": where is not None,
                    "at": ({"chapter": where["chapter"], "pearl": where["pearl"],
                            "token": where["token"]} if where else None)})

    missing = [r for r in out if not r["landed"]]
    landed = [r for r in out if r["landed"]]

    if a.json:
        print(json.dumps({"speak_lines": len(rows), "checked": len(want),
                          "landed": len(landed), "missing": len(missing),
                          "rows": out}, ensure_ascii=False, indent=1))
        return 0

    print("SPEAK vs THE BOOK — %d attributed line(s) in doc/SPEAK.md" % len(rows))
    by = {}
    for r in rows:
        by[r["tag"]] = by.get(r["tag"], 0) + 1
    print("  " + " · ".join("%s %d" % (k, v) for k, v in sorted(by.items())))
    print()
    print("  checked : %d  (%s)" % (len(want), "every tag" if a.all else "[hand] only"))
    print("  in the book  : %d" % len(landed))
    print("  NEVER LANDED : %d" % len(missing))
    if not missing:
        print()
        print("  Every one of these lines is already in the book.")
        return 0
    print()
    print("  These were written for a hall and never arrived. The chapter and pearl")
    print("  are the ones standing over the line in SPEAK, so each says where it goes.")
    print()
    for r in missing:
        head = (r["chapter"] or "—") + (" / " + r["pearl"] if r["pearl"] else "")
        print("  %s   (SPEAK.md:%d)" % (head, r["n"]))
        for ln in r["text"].split("  "):
            if ln.strip():
                print("      %s" % ln.strip())
        print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
