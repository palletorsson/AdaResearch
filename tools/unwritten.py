#!/usr/bin/env python3
"""Where the book is silent — the museum's map of its own unwritten places.

2026-08-28, Palle: "I want to build the museum and at the same time write the
book ... The development of the game is the research into algorithms."

The machinery for that already exists and is almost entirely unused. A book line
is a BINDING — {token, text, by} — one sentence fastened to one artifact, and it
may carry a `note`: what was found while making the sentence true. The museum
renders it under the line on the hall's panel; /lines edits it; the in-world page
editor writes it from inside the hall you are standing in. The loop closes:

    walk -> find something -> write the note in the hall -> book.py compile
         -> it is on the wall next time

On the day this tool was written, one line in eight hundred and forty-two carried
a note, and one chapter in twenty-four carried a speak. This tool is the view of
the other 99%.

THREE TIERS, because a finding is not always about an object:

    chapter   `speak`   the argument of the whole chapter. 24 of them.
                        Where a SYSTEMIC finding goes — the ones that are about
                        the building rather than about any object in it.
    pearl     (none)    a hall has no note vocabulary at all. Reported here as a
                        gap rather than invented: a hall-level finding currently
                        has nowhere to live except a commit message.
    line      `note`    the field note proper, bound to the artifact it is about
                        and read standing in front of it.

RANKING, and it is a heuristic, not a truth. An unwritten line is more
interesting when the claim above it was made by HAND (Palle wrote it himself, so
somebody already decided it mattered), when it is the pearl's hero, when the hall
is really built rather than scaffolded, and when the sentence is long enough to
be an argument. The score is printed so you can disagree with it.

    python tools/unwritten.py                     # the whole book
    python tools/unwritten.py --chapter=primitives
    python tools/unwritten.py --by=hand --top=40  # only what Palle claimed
    python tools/unwritten.py --json              # what /unwritten reads
"""
from __future__ import annotations

import argparse
import glob
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BOOK = os.path.join(ROOT, "commons", "data", "book")
#: A hall builds from its own map only when map_authored.json says so; everything
#: else is scaffolded from a template. A note about a scaffolded hall is a note
#: about a room nobody has really made yet.
AUTHORED = os.path.join(ROOT, "commons", "data", "map_authored.json")


def authored_maps() -> set:
    try:
        with open(AUTHORED, encoding="utf-8") as fh:
            d = json.load(fh)
    except Exception:
        return set()
    # SHAPE: {chapter: [map, map, ...]} — the maps of that chapter that build
    # from their own map_data.json rather than from a template. Measured, not
    # assumed: the first version of this read the keys as map names and scored
    # every line as unbuilt, which is the quiet-wrong-answer this whole tool
    # exists to complain about.
    out = set()
    if isinstance(d, dict):
        for k, v in d.items():
            if k.startswith("_"):
                continue
            if isinstance(v, list):
                out |= {str(x) for x in v}
            elif isinstance(v, dict):
                out |= {str(x) for x in v.keys()}
            else:
                out.add(str(k))
    elif isinstance(d, list):
        out |= {str(x) for x in d}
    return out


def score(line: dict, pearl: dict, built: bool) -> tuple:
    """How much we want a note here. Reported, not hidden — argue with it."""
    s, why = 0, []
    if str(line.get("by", "")) == "hand":
        s += 3; why.append("hand")
    if str(line.get("token", "")) and line.get("token") == pearl.get("hero"):
        s += 2; why.append("hero")
    if built:
        s += 1; why.append("built")
    if len(str(line.get("text", ""))) > 100:
        s += 1; why.append("long")
    if line.get("claimed"):
        s += 1; why.append("claimed")
    return s, why


def read(chapter_filter: str = "") -> dict:
    built_maps = authored_maps()
    chapters, rows = [], []
    for path in sorted(glob.glob(os.path.join(BOOK, "*.json"))):
        name = os.path.splitext(os.path.basename(path))[0]
        if chapter_filter and name != chapter_filter:
            continue
        with open(path, encoding="utf-8") as fh:
            doc = json.load(fh)
        pearls = doc.get("pearls") or []
        n_lines = n_notes = 0
        for pearl in pearls:
            built = str(pearl.get("map", "")) in built_maps
            for idx, line in enumerate(pearl.get("lines") or []):
                if not isinstance(line, dict):
                    continue
                n_lines += 1
                has = bool(str(line.get("note") or "").strip())
                if has:
                    n_notes += 1
                    continue
                s, why = score(line, pearl, built)
                rows.append({
                    "chapter": name, "pearl": pearl.get("pearl"), "map": pearl.get("map"),
                    "index": idx, "token": line.get("token"), "by": line.get("by", "?"),
                    "text": str(line.get("text", "")).replace("\n", " / ")[:180],
                    "built": built, "score": s, "why": why,
                })
        chapters.append({
            "chapter": name,
            "pearls": len(pearls),
            "lines": n_lines,
            "notes": n_notes,
            "speak": bool(str(doc.get("speak") or "").strip()),
            "speak_by": doc.get("speak_by", ""),
        })
    rows.sort(key=lambda r: (-r["score"], r["chapter"], str(r["pearl"]), r["index"]))
    return {"chapters": chapters, "unwritten": rows}


def main() -> int:
    ap = argparse.ArgumentParser(description="where the book has no field notes")
    ap.add_argument("--chapter", default="", help="one chapter, by file name")
    ap.add_argument("--by", default="", help="only lines whose claim has this provenance")
    ap.add_argument("--top", type=int, default=25)
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()

    data = read(a.chapter)
    if a.by:
        data["unwritten"] = [r for r in data["unwritten"] if r["by"] == a.by]
    if a.json:
        json.dump(data, sys.stdout, ensure_ascii=False)
        sys.stdout.write("\n")
        return 0

    ch = data["chapters"]
    lines = sum(c["lines"] for c in ch)
    notes = sum(c["notes"] for c in ch)
    speaks = sum(1 for c in ch if c["speak"])
    print("THE BOOK'S SILENCE\n")
    print("  %-26s %5s %6s %6s  %s" % ("chapter", "lines", "notes", "speak", "written"))
    print("  " + "-" * 62)
    for c in sorted(ch, key=lambda c: (-c["notes"], c["chapter"])):
        frac = (c["notes"] / c["lines"]) if c["lines"] else 0.0
        bar = "#" * int(round(frac * 20)) + "." * (20 - int(round(frac * 20)))
        print("  %-26s %5d %6d %6s  %s %4.0f%%" % (
            c["chapter"][:26], c["lines"], c["notes"], "yes" if c["speak"] else "-", bar, frac * 100))
    print("  " + "-" * 62)
    print("  %-26s %5d %6d %6s  %d of %d chapters argue for themselves" % (
        "ALL", lines, notes, "%d" % speaks, speaks, len(ch)))
    print()
    print("  %d of %d lines carry a field note. A hall has no note vocabulary at all —" % (notes, lines))
    print("  a finding about a ROOM rather than an object currently has nowhere to go.")
    print()
    print("THE %d MOST WORTH WRITING (score, and why it scored)\n" % min(a.top, len(data["unwritten"])))
    for r in data["unwritten"][:a.top]:
        print("  %2d  %-13s %-16s %-22s %s" % (
            r["score"], r["chapter"][:13], str(r["pearl"])[:16], str(r["token"])[:22],
            ",".join(r["why"])))
        print("      %s" % r["text"][:150])
    print()
    print("  write one in the hall (the page editor), at /lines, or at /unwritten.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
