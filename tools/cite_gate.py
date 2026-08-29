#!/usr/bin/env python3
"""THE CITATION GATE — is this passage still where the book says it is?

    python tools/cite_gate.py                  # the report
    python tools/cite_gate.py --apply          # + write the derived index
    python tools/cite_gate.py --token=X        # one work
    python tools/cite_gate.py --json
    exit 1 when any citation is LOST or names no such work

2026-08-29. The second register of the concordance: tools/concord.py finds where
a work MIGHT be discussed and stores nothing; this checks where a human has SAID
it is, and that claim is permanent.

PASS ZERO IS FREE, AND THAT IS THE WHOLE DESIGN. A citation is note_src plus a
subject. The book already carries 218 lines with BOTH a `token` and a `note_src`
{file, quote} — written for the edges work, every one of them naming a real
registry artifact, every one already anchored to a file and a verbatim quote.
Those ARE artifact-to-passage citations; nobody had read them as such. So this
tool writes no new JSON to start with and the index opens with 218 rows.

WHAT IT CHECKS, AND WHAT IT REFUSES TO. It does not read the sentence. No parser
decides whether "a point borrows its whole existence from a coordinate system"
is true. It asks the narrower and more useful question — are those words still
in that file? When somebody edits the room, the citation fails, and the failure
is the curriculum moving. The sentence is not wrong; it has gone out of date,
and someone should walk the room again and say so.

SIX VERDICTS. Four inherited from tools/edge_gate.py unchanged, because file +
quote is byte-identical there and verdict() is already generic over its host:

    HELD          the quote is verbatim in the file it names
    NEAR          every content word survives; the wording moved
    LOST          neither. The ground is gone.                        FAILS
    UNGROUNDED    no anchor recorded. A to-do, named.

Two added here, and they are the only reason this is a CITATION and not an
anchor — an anchor knows its source, a citation also knows its subject:

    NO SUCH WORK  the token is in no registry artifacts dict.         FAILS
                  Zero today among the 218. But the book carries exactly one
                  ghost — calder_mobile_primaries, forces / "sky climb" — a
                  Calder mobile written about and never built. The rule bites
                  the moment anyone cites it.
    ELSEWHERE     the citation points into commons/maps/<M>/ and the token is
                  not in M's layers.interactables.                    PASSES
                  An artifact discussed where it does not stand is a FINDING,
                  not a bug. Three today, and all three are their pearl's own
                  declared HERO: the work the hall is about is not in the hall.

WIDER THAN edge_gate's OWN COLLECTOR, DELIBERATELY. edge_gate.edges() takes one
anchor per pearl — the hero's note, else the first noted line — so 218 of the 219
notes are checked and exactly one (Point_One / origin) is invisible to it. This
walks EVERY line carrying a note_src. Any new anchor made on a non-hero line
would otherwise ship unchecked, which is the failure the gate exists to prevent.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
BOOK = REPO / "commons" / "data" / "book"
REPORTS = REPO / "doc" / "reports"
MIRROR = REPO.parent / "ada_encyclopedia" / "public" / "research-map"

sys.path.insert(0, str(REPO / "tools"))
from edge_gate import verdict as _verdict  # noqa: E402  the SAME rule, not a copy
from concord import registry, placements  # noqa: E402

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")


def collect() -> list:
    """Every citation in the book: a line that carries both a token and an anchor.

    Also reads the optional `cites` list — a list of {file, quote, ...} rows on a
    line or a pearl, for the SECOND citation of a work and for works whose line
    already spent its single note_src. It does not exist on disk yet; the key is
    deliberately absent from book.py's TRUNK_OWNS_LINE / TRUNK_OWNS_PEARL, so a
    `migrate` preserves it and `compile` never projects it. A chapter that never
    grows one stays byte-identical."""
    out = []
    for f in sorted(BOOK.glob("*.json")):
        try:
            doc = json.loads(f.read_text(encoding="utf-8"))
        except Exception as e:
            print("  ! %s: %s" % (f.stem, e), file=sys.stderr)
            continue
        for pi, p in enumerate(doc.get("pearls", [])):
            base = {"chapter": f.stem, "pearl": str(p.get("pearl", "")),
                    "map": str(p.get("map", "")), "hero": str(p.get("hero", ""))}
            for li, l in enumerate(p.get("lines", [])):
                tok = str(l.get("token", "")).strip()
                if tok and isinstance(l.get("note_src"), dict):
                    out.append(dict(base, token=tok, li=li, host="note_src",
                                    src=l["note_src"], said=str(l.get("note", ""))))
                for c in (l.get("cites") or []):
                    if isinstance(c, dict):
                        out.append(dict(base, token=str(c.get("token") or tok), li=li,
                                        host="cites", src=c, said=str(c.get("why", ""))))
            for c in (p.get("cites") or []):
                if isinstance(c, dict) and c.get("token"):
                    out.append(dict(base, token=str(c["token"]), li=-1, host="pearl_cites",
                                    src=c, said=str(c.get("why", ""))))
            if isinstance(p.get("edge_src"), dict):
                if str(p.get("hero", "")).strip():
                    out.append(dict(base, token=str(p["hero"]), li=-1, host="edge_src",
                                    src=p["edge_src"], said=str(p.get("edge", ""))))
                else:
                    SUBJECTLESS.append(dict(base, said=str(p.get("edge", "")),
                                            src=p["edge_src"]))
    return out


# AN EDGE WITH NOTHING TO ATTRIBUTE IT TO. 51 pearls carry a pearl-level `edge`
# and `edge_src`, and 50 of them have no hero and no lines — the chamber halls,
# Chamber_Arrays, Chamber_Color, Chamber_CA. Somebody wrote a sentence about that
# room and there is no work in the book to hang it on.
#
# These are NOT dropped silently, and they are not failures either. They are the
# fourth want: a thought with no body. The citation needs a subject by
# construction — that is the whole difference between an anchor and a citation —
# so the honest move is to count them and name them, not to invent an owner.
SUBJECTLESS: list = []


def judge(rows: list, reg: dict, place: dict) -> list:
    out = []
    for r in rows:
        v, why = _verdict(r)
        if r["token"] not in reg:
            v, why = "NO SUCH WORK", "%s is in no registry artifacts dict" % r["token"]
        elif v in ("HELD", "NEAR"):
            rel = str((r.get("src") or {}).get("file", "")).replace("\\", "/")
            if rel.startswith("commons/maps/"):
                parts = rel.split("/")
                m = parts[2] if len(parts) > 2 else ""
                if m and not (REPO / "commons" / "maps" / m / "map_data.json").exists():
                    why = why + " · that map has no map_data.json"
                elif m and m not in place.get(r["token"], set()):
                    v = "ELSEWHERE"
                    why = "discussed in %s, where it does not stand%s" % (
                        m, " — and it is this hall's declared hero" if r["token"] == r["hero"] else "")
        out.append(dict(r, verdict=v, why=why))
    return out


def write_index(rows: list) -> None:
    by: dict = {}
    for r in rows:
        by.setdefault(r["token"], []).append(
            {k: r[k] for k in ("chapter", "pearl", "map", "li", "host", "verdict", "why", "said")}
            | {"file": (r.get("src") or {}).get("file", ""),
               "quote": (r.get("src") or {}).get("quote", "")})
    tally = {}
    for r in rows:
        tally[r["verdict"]] = tally.get(r["verdict"], 0) + 1
    doc = {"schema": "artifact_citations/1",
           "generated": time.strftime("%Y-%m-%dT%H:%M:%S"),
           "totals": {"citations": len(rows), "works": len(by), **tally},
           "by_token": by}
    body = json.dumps(doc, ensure_ascii=False, indent=1) + "\n"
    for d in (REPORTS, MIRROR):
        try:
            d.mkdir(parents=True, exist_ok=True)
            p = d / "artifact_citations.json"
            tmp = Path(str(p) + ".tmp")
            tmp.write_text(body, encoding="utf-8", newline="\n")
            for _ in range(30):
                try:
                    os.replace(tmp, p)
                    break
                except OSError:
                    time.sleep(0.3)
            print("  wrote %s" % p)
        except Exception as e:
            print("  ! could not write %s: %s" % (d, e), file=sys.stderr)


def main() -> int:
    ap = argparse.ArgumentParser(description="is this passage still where the book says it is")
    ap.add_argument("--token", default="")
    ap.add_argument("--apply", action="store_true", help="write the derived index")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--quiet", action="store_true")
    a = ap.parse_args()

    reg, place = registry(), placements()
    rows = judge(collect(), reg, place)
    if a.token:
        rows = [r for r in rows if r["token"] == a.token]

    order = ["HELD", "NEAR", "ELSEWHERE", "LOST", "NO SUCH WORK", "UNGROUNDED"]
    tally = {k: sum(1 for r in rows if r["verdict"] == k) for k in order}
    fails = tally["LOST"] + tally["NO SUCH WORK"]

    if a.json:
        print(json.dumps({"totals": {"citations": len(rows), **tally}, "rows": rows},
                         ensure_ascii=False, indent=1))
        if a.apply:
            write_index(rows)
        return 1 if fails else 0

    tot = max(1, len(rows))
    print("THE CITATION GATE — %d citation(s) over %d work(s)" %
          (len(rows), len({r["token"] for r in rows})))
    for k in order:
        print("  %-13s %4d  (%3.0f%%)" % (k, tally[k], 100 * tally[k] / tot))

    for want in ("LOST", "NO SUCH WORK", "ELSEWHERE", "NEAR", "UNGROUNDED"):
        pick = [r for r in rows if r["verdict"] == want]
        if not pick or (a.quiet and want not in ("LOST", "NO SUCH WORK")):
            continue
        print()
        print("  %s:" % want)
        for r in pick[:40]:
            print("    %-18s %-30s %-26s %s" % (r["chapter"], r["map"][:30], r["token"][:26], r["why"]))
        if len(pick) > 40:
            print("    ... and %d more" % (len(pick) - 40))

    if SUBJECTLESS and not a.token:
        print()
        print("  AN EDGE WITH NO SUBJECT — %d pearl(s) carry a sentence and no work to hang it on:" % len(SUBJECTLESS))
        for r in SUBJECTLESS[:8]:
            print("    %-18s %-28s %s" % (r["chapter"], r["map"][:28],
                                          (r["said"] or "")[:60].replace("\n", " ")))
        if len(SUBJECTLESS) > 8:
            print("    ... and %d more" % (len(SUBJECTLESS) - 8))
        print("    These are chamber halls: a thought was written and the book holds no body")
        print("    for it. Not a failure — the fourth want. Give one a hero, or a line.")

    print()
    print("  COVERAGE, honest denominator first:")
    placed_in_book_halls = set()
    book_maps = {r["map"] for r in rows if r["map"]}
    for t, maps in place.items():
        if t in reg and (maps & book_maps):
            placed_in_book_halls.add(t)
    cited = {r["token"] for r in rows}
    print("    %d of %d works standing in the halls the book has entered  (%.0f%%)" %
          (len(cited), max(1, len(placed_in_book_halls)),
           100 * len(cited) / max(1, len(placed_in_book_halls))))
    print("    %d of %d works in the registry                             (%.1f%%)" %
          (len(cited), len(reg), 100 * len(cited) / max(1, len(reg))))
    print("    The second number will be quoted and it is the misleading one: most of")
    print("    that corpus stands in halls the book has never walked into, and a work")
    print("    nobody has walked has no citation to make.")

    if a.apply:
        print()
        write_index(rows)
    if fails:
        print()
        print("  A LOST citation does not mean the sentence is wrong. It means the ground it")
        print("  stood on has moved, and the room should be read again before the sentence is")
        print("  trusted. Fix the anchor, or rewrite the claim — both are answers.")
    return 1 if fails else 0


if __name__ == "__main__":
    raise SystemExit(main())
