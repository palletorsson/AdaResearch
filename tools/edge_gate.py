#!/usr/bin/env python3
"""THE EDGE GATE — does each map's edge still stand on the line it was read from?

    python tools/edge_gate.py                 # the report
    python tools/edge_gate.py --chapter color # one chapter
    python tools/edge_gate.py --quiet         # only the failures and the tally
    exit 1 when any edge has LOST its anchor

2026-08-28, Palle: "how can we improve this in relation to the meaning of ada
research" — then: build the gate.

WHY THIS EXISTS AT ALL. An edge is one sentence naming the dependency a map
cannot absorb. 269 of them were written into the book, and they were the only
thing made that day with no gate: prose that could not be wrong. The project's own
method, applied everywhere else in the same session, is that a claim which cannot
fail was never verified — so the edges were the least Ada Research thing in the
book, whatever they said.

WHAT IT CHECKS, AND WHAT IT DELIBERATELY DOES NOT. It does not read the sentence.
No parser is going to decide whether "the trace has no origin, only a sampling
rate" is true. What it checks is the ANCHOR: every edge records the file it was
read out of and the words it was read from, and this asks whether those words are
still there.

That is a narrower claim and a much more useful one. When somebody fixes
Change_Intro to actually take a limit, the comment the edge was built on changes,
this fails, and the failure is the curriculum moving — the edge is not wrong, it
has become out of date, and somebody should walk the room again and say so. A gate
that fires when the world moves is worth more than one that scores prose.

FOUR VERDICTS:
    HELD        the quote is verbatim in the file it names
    NEAR        every content word is there but the wording has drifted — a
                reformat, a rename, an edit that did not change the sense
    LOST        neither. The ground the sentence stood on is gone; read it again
    UNGROUNDED  the edge records no anchor. Not a failure — a to-do, and the
                report names them so they can be given one

CHECK THE INSTRUMENT BEFORE BELIEVING IT. The first matcher written for this said
21% of quotes were missing from their own files. Three spot-checks found all three
present and the matcher at fault: a quote spanning two comment lines has a "##"
sitting in the middle of it once whitespace collapses, and a markdown quote loses
its ** emphasis on the way into a model's mouth. With comment lead-ins and
emphasis stripped the same corpus read 94% HELD, 5% NEAR, 1% LOST. Every number
this tool prints depends on norm() below being right about what a source file
looks like.
"""
from __future__ import annotations

import argparse
import io
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
BOOK = REPO / "commons" / "data" / "book"

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

SPINE = ["primitives", "transformation", "symmetry", "array_tutorial", "color", "change", "forces",
         "formfinding", "wavefunctions", "randomness", "noise", "cellularautomata", "fractals",
         "lsystems", "proceduralgeneration", "softbodies", "isosurfaces", "boolean_surfaces",
         "swarmintelligence", "machinelearning", "graphtheory", "foundationscrisis",
         "qfeplaboratory", "postfoundationscrisis"]


def norm(s: str) -> str:
    """A quote and a file, compared on sense rather than on typography.

    Smart quotes and dashes come back from a model in their plain forms; a
    comment continued on a second line carries its own marker into the middle of
    the sentence; markdown emphasis is invisible when read aloud and absent when
    quoted. None of those are drift, so none of them may register as drift."""
    s = (s.replace("—", "-").replace("–", "-")
         .replace("‘", "'").replace("’", "'")
         .replace("“", '"').replace("”", '"')
         .replace(" ", " "))
    s = re.sub(r"^[ \t]*(?:##?#?|//|--)[ \t]?", " ", s, flags=re.M)
    s = re.sub(r"[*_`>]", "", s)
    return re.sub(r"\s+", " ", s).strip().lower()


def content(s: str) -> list[str]:
    return [w for w in re.findall(r"[a-z0-9_().]+", s) if len(w) > 2]


def edges(only: str = "") -> list[dict]:
    """Every edge in the book with whatever anchor it carries.

    An edge lives in one of two places and both are correct: `note` on the
    pearl's hero line where the pearl has lines, and `edge` on the pearl itself
    where it has none. The hero's note wins — a pearl can carry several
    reflections and the first one is often not the edge."""
    out: list[dict] = []
    names = [c for c in SPINE if (BOOK / f"{c}.json").exists()]
    names += sorted(p.stem for p in BOOK.glob("*.json") if p.stem not in names)
    for ch in names:
        if only and ch != only:
            continue
        try:
            doc = json.loads((BOOK / f"{ch}.json").read_text(encoding="utf-8"))
        except Exception as e:
            print(f"  ! {ch}: {e}", file=sys.stderr)
            continue
        for p in doc.get("pearls", []):
            lines = p.get("lines", [])
            hero = str(p.get("hero", ""))
            ln = (next((l for l in lines if l.get("token") == hero and str(l.get("note", "")).strip()), None)
                  or next((l for l in lines if str(l.get("note", "")).strip()), None))
            if ln is not None:
                out.append({"chapter": ch, "map": str(p.get("map", "")), "where": "line",
                            "edge": str(ln["note"]).strip(), "src": ln.get("note_src") or {}})
            elif str(p.get("edge", "")).strip():
                out.append({"chapter": ch, "map": str(p.get("map", "")), "where": "pearl",
                            "edge": str(p["edge"]).strip(), "src": p.get("edge_src") or {}})
    return out


_CACHE: dict[str, str] = {}


def body_of(rel: str) -> str | None:
    if rel not in _CACHE:
        f = REPO / rel
        if not f.exists():
            _CACHE[rel] = ""
        else:
            try:
                _CACHE[rel] = norm(io.open(f, encoding="utf-8", errors="replace").read())
            except Exception:
                _CACHE[rel] = ""
    return _CACHE[rel] or None


def verdict(e: dict) -> tuple[str, str]:
    src = e.get("src") or {}
    rel, quote = str(src.get("file", "")), str(src.get("quote", "")).strip()
    if not rel or not quote:
        return "UNGROUNDED", "no anchor recorded"
    body = body_of(rel)
    if body is None:
        return "LOST", f"{rel} is not in the repo"
    q = norm(quote)
    if q and q in body:
        return "HELD", rel
    qw = set(content(q))
    if qw and sum(1 for w in qw if w in body) / len(qw) >= 0.9:
        return "NEAR", f"{rel} — the words are there, the wording moved"
    return "LOST", f"{rel} no longer says it"


def main() -> int:
    ap = argparse.ArgumentParser(description="does each edge still stand on the line it was read from")
    ap.add_argument("--chapter", default="")
    ap.add_argument("--quiet", action="store_true")
    a = ap.parse_args()

    rows = [(e, *verdict(e)) for e in edges(a.chapter)]
    tally = {k: sum(1 for _, v, _ in rows if v == k) for k in ("HELD", "NEAR", "LOST", "UNGROUNDED")}
    tot = max(1, len(rows))

    print("THE EDGE GATE — %d edge(s)" % len(rows))
    for k in ("HELD", "NEAR", "LOST", "UNGROUNDED"):
        print("  %-11s %4d  (%3.0f%%)" % (k, tally[k], 100 * tally[k] / tot))

    for want in ("LOST", "NEAR", "UNGROUNDED"):
        pick = [(e, w) for e, v, w in rows if v == want]
        if not pick:
            continue
        if a.quiet and want != "LOST":
            continue
        print()
        print("  %s:" % want)
        for e, why in pick:
            print("    %-20s %-34s %s" % (e["chapter"], e["map"], why))

    if tally["LOST"]:
        print()
        print("  A LOST anchor does not mean the sentence is wrong. It means the ground it")
        print("  stood on has moved, and the room should be read again before the sentence")
        print("  is trusted. Fix the anchor, or rewrite the edge — both are answers.")
    return 1 if tally["LOST"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
