#!/usr/bin/env python3
"""THE SOURCE DOCS BEHIND ONE final.md — segments, draws, and what went unused.

    python tools/compose_docs.py --map Euclid_Parallel
    python tools/compose_docs.py --map Euclid_Parallel --json     # what the page serves
    python tools/compose_docs.py --unused                         # every room, worst first

2026-09-03, Palle: "I want tabs for every intent, tutorial, critical summary etc
.md I want to cross tag the segments or paragraphs so that the final becomes a
mix of part from critical and tutorial."

WHY DRAWS ARE REFERENCES AND NOT TRANSCLUSION. final.md does not contain the
source text and should not. Euclid's critical.md and its final.md reach the same
thesis in different voices — critical is third-person essay, final is second
person standing in the room — and splicing paragraphs from one into the other
puts a seam at every join. What the writer actually needs is not a merge engine
but SIGHT: on 2026-09-03 seven finals were written for foundationscrisis without
anyone opening the seven critical.md files, which are the largest document in
every one of those rooms. That is the failure this measures.

THE GRAMMAR. Source docs need no new markup — their `## headings` are already the
segments, slugified for an id. In final.md a draw line sits beside the artifact
tag and uses `~` where the artifact tag uses `@`:

    <!-- @euclid_postulates_plaque -->
    <!-- ~critical#the-state-of-exception ~tutorial#toggle-fifth -->

Same line-anchored HTML-comment shape as the artifact tag, so it is invisible to
every markdown renderer and legible to the same eye. A draw naming a heading that
no longer exists is STALE and reported, the same class of error as an artifact tag
naming a work that is not in the map.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MAPS = ROOT / "commons" / "maps"
TRIAGE = ROOT / "ada_run" / "spine_triage.json"

#: the docs a room can carry, in the order the writer should meet them
DOCS = ["blurb", "intent", "summary", "tutorial", "critical", "artifacts", "walked"]

#: What each document is WORTH, which is not the same as whether it exists.
#: Measured across the corpus on 2026-09-03 and from the spine triage's evidence
#: field: tutorials in foundationscrisis describe plinths, doors and alarms that
#: were never placed, and intent.md routinely names artifacts absent from the map.
TRUST = {
    "blurb": ("reliable", "usually carries the room's thesis in its last sentence"),
    "critical": ("rich", "theory-grounded and the most under-used document in the corpus"),
    "summary": ("reliable", "a compression of the room, safe to draw on"),
    "intent": ("drifts", "a spec written before the build; often names artifacts not placed"),
    "tutorial": ("check first", "often pseudo-code for a hypothetical build, not the placed works"),
    "artifacts": ("derived", "generated from the registry"),
    "walked": ("observed", "notes from an actual walk"),
}

HEADING = re.compile(r"^(#{1,3})\s+(.+?)\s*$")
DRAW_LINE = re.compile(r"^[ \t]*<!--[ \t]*((?:~[A-Za-z0-9_]+#[A-Za-z0-9_-]+[ \t]*)+)-->[ \t]*$")
DRAW = re.compile(r"~([A-Za-z0-9_]+)#([A-Za-z0-9_-]+)")
ART = re.compile(r"^[ \t]*<!--[ \t]*@([A-Za-z0-9_]*)[ \t]*-->[ \t]*$")


def sha(text: str) -> str:
    """A document's fingerprint at read time. The page sends it back with an
    edit; if the file has moved on since, the write is refused rather than
    silently overwriting whoever got there first — several Claude sessions edit
    this repo at once, and one has already lost work to a blind overwrite."""
    return hashlib.sha1(text.encode("utf-8")).hexdigest()[:12]


def write_range(path: Path, start: int, end: int, text: str, base: str) -> dict:
    """Replace lines [start, end] (1-based, inclusive) with `text`.

    Segment-level rather than whole-file: the writer edits one segment, so only
    that range moves, and a concurrent edit elsewhere in the same file is not
    clobbered by a stale copy of the rest of it.
    """
    if not path.exists():
        return {"ok": False, "error": "no such document: %s" % path.name}
    # PRESERVE THE FILE'S OWN LINE ENDINGS. The corpus is mixed — critical.md is
    # CRLF, the finals written today are LF — and writing the other kind rewrites
    # every line of the file, turning a one-segment edit into a whole-file diff.
    raw = path.read_bytes()
    crlf = b"\r\n" in raw
    cur = raw.decode("utf-8").replace("\r\n", "\n")
    if base and sha(cur) != base:
        return {"ok": False, "error": "stale",
                "detail": "%s changed on disk since you opened it" % path.name,
                "hash": sha(cur)}
    lines = cur.splitlines()
    if start < 1 or end > len(lines) + 1 or end < start - 1:
        return {"ok": False, "error": "range %d-%d is outside %s (%d lines)"
                % (start, end, path.name, len(lines))}
    norm = text.replace("\r\n", "\n")
    # empty text DELETES the range — that is how the last citation comes off a
    # block, and "".split("\n") would otherwise leave a blank line behind
    body = [] if norm.strip() == "" else norm.rstrip("\n").split("\n")
    out = lines[:start - 1] + body + lines[end:]
    joined = "\n".join(out) + "\n"
    path.write_bytes((joined.replace("\n", "\r\n") if crlf else joined).encode("utf-8"))
    return {"ok": True, "hash": sha(joined), "lines": len(out),
            "eol": "crlf" if crlf else "lf"}


def trim(lines: list[str], lo: int, hi: int) -> tuple[int, int]:
    """1-based inclusive range of the NON-BLANK content inside 0-based [lo, hi).

    The range has to match the stripped `text` the page is handed exactly, or a
    save round-trips lossily: the first version included the blank separator
    line before the next heading, and writing the segment back unchanged
    deleted it. An empty span comes back as (lo+1, lo) — a legal insert point.
    """
    a, b = lo, hi - 1
    while a <= b and not lines[a].strip():
        a += 1
    while b >= a and not lines[b].strip():
        b -= 1
    return a + 1, b + 1


def reorder_final(path: Path, frm: int, to: int, base: str) -> dict:
    """Move one block of final.md to another position.

    Done here rather than as a line splice from the page: a reorder rewrites
    everything between the two positions, and the client has no business
    computing that. Blocks TILE the file — block 0 starts at line 1, each span
    runs heading-through-prose, and only blank lines sit between them — so the
    file can be rebuilt from the spans alone without losing anything.
    """
    if not path.exists():
        return {"ok": False, "error": "no final.md"}
    rawb = path.read_bytes()
    crlf = b"\r\n" in rawb
    cur = rawb.decode("utf-8").replace("\r\n", "\n")
    if base and sha(cur) != base:
        return {"ok": False, "error": "stale",
                "detail": "final.md changed on disk since you opened it", "hash": sha(cur)}
    blocks, _, coda = read_final(path)
    n = len(blocks)
    if not (0 <= frm < n) or not (0 <= to < n):
        return {"ok": False, "error": "block %d/%d out of range (%d blocks)" % (frm, to, n)}
    # THE PREAMBLE DOES NOT MOVE, and nothing moves above it. Block 0 carries no
    # artifact tag and no heading — it is the room's establishing shot — so once
    # it is not first the file opens on a bare heading and the heading-handoff
    # re-reads every section one place off. Moving it corrupted the order in
    # testing (content intact, sequence wrong), which is the worst kind of bug:
    # it looks like a successful save.
    if blocks and blocks[0].get("marker", 0) == 0 and (frm == 0 or to == 0):
        return {"ok": False, "error": "the opening block is fixed — it has no work "
                                      "of its own, and the chapter has to start on it"}
    if frm == to:
        return {"ok": True, "hash": sha(cur), "moved": False}
    lines = cur.split("\n")
    chunks = ["\n".join(lines[b["span_start"] - 1:b["span_end"]]).strip("\n") for b in blocks]
    order = list(range(n))
    order.insert(to, order.pop(frm))
    out = "\n\n".join(chunks[i] for i in order)
    # the coda sits OUTSIDE every span, so rebuilding from spans alone would
    # delete the chapter's closing section. It is fixed: always last.
    if coda.get("text"):
        out += "\n\n" + coda["text"]
    out += "\n"
    path.write_bytes((out.replace("\n", "\r\n") if crlf else out).encode("utf-8"))
    return {"ok": True, "hash": sha(out), "moved": True, "order": order,
            "eol": "crlf" if crlf else "lf"}


def slug(s: str) -> str:
    s = re.sub(r"[^A-Za-z0-9]+", "-", s.lower()).strip("-")
    return s[:60] or "section"


def segments(text: str) -> list[dict]:
    """A document's `## headings` ARE its segments. No new markup to author."""
    lines = text.splitlines()
    marks = [(i, m.group(2)) for i, l in enumerate(lines) if (m := HEADING.match(l))
             and len(m.group(1)) >= 2]
    if not marks:
        # No headings — blurb, intent, summary and most tutorials are unbroken
        # prose. Fall back to PARAGRAPHS, because "the whole document" is not a
        # thing anyone can draw on precisely, and precision is the entire point.
        # Split on blank lines, but NEVER inside a fenced code block — a tutorial
        # is mostly code, and a segment whose heading is "```gdscript" is useless
        # to point at.
        out: list[dict] = []
        buf: list[str] = []
        start = 1
        fence = False
        n = 0

        def emit(at: int) -> None:
            nonlocal n
            body = "\n".join(buf).strip()
            if not body:
                return
            n += 1
            head = next((re.sub(r"^#+\s*", "", l).strip() for l in body.splitlines()
                         if l.strip() and not l.lstrip().startswith("```")), "code")
            out.append({"id": "p%d" % n,
                        "heading": (head[:46] + "…") if len(head) > 46 else head,
                        "line": at, "start": at, "end": at + len(buf) - 1,
                        "words": len(body.split()),
                        "lead": body[:180], "text": body})

        for i, l in enumerate(lines):
            if l.lstrip().startswith("```"):
                fence = not fence
            if not fence and not l.strip():
                emit(start)
                buf = []
                start = i + 2
                continue
            buf.append(l)
        emit(start)
        return out
    out = []
    used: dict[str, int] = {}
    for n, (i, head) in enumerate(marks):
        end = marks[n + 1][0] if n + 1 < len(marks) else len(lines)
        body = "\n".join(lines[i + 1:end]).strip()
        sid = slug(head)
        if sid in used:  # two headings can slugify the same
            used[sid] += 1
            sid = "%s-%d" % (sid, used[sid])
        else:
            used[sid] = 1
        # start/end are the 1-based INCLUSIVE line range of the segment's BODY —
        # the heading line itself is never inside it, so an edit can never rename
        # the segment out from under a draw that points at its slug.
        a, b = trim(lines, i + 1, end)
        out.append({"id": sid, "heading": head, "line": i + 1,
                    "start": a, "end": b,
                    "words": len(body.split()), "lead": body[:180], "text": body})
    return out


def read_final(p: Path) -> tuple[list[dict], list[tuple[str, str]]]:
    """final.md as blocks, each carrying the work it is about and what it draws on."""
    if not p.exists():
        return [], []
    blocks: list[dict] = []
    draws: list[tuple[str, str]] = []
    # `marker` is the <!-- @token --> line and `draw_line` the <!-- ~... --> line
    # if one exists (0 = none). Together they say WHERE a citation belongs: on the
    # existing draw line, or on a fresh line immediately after the marker — never
    # against the prose, where it would land after the blank and read wrong.
    cur = {"token": "", "draws": [], "lead": "", "text": "", "words": 0,
           "marker": 0, "draw_line": 0}
    body: list[str] = []

    span = {"start": 1, "end": 0}  # 1-based inclusive range of this block's body

    def flush() -> None:
        text = "\n".join(body).strip()
        cur["words"] = len(text.split())
        cur["lead"] = re.sub(r"\s+", " ", re.sub(r"```.*?```", "", text, flags=re.S))[:160]
        cur["text"] = text  # the composing surface renders the whole block, not a lead
        cur["start"] = span["start"]
        cur["end"] = span["end"]
        blocks.append(dict(cur))

    for n, line in enumerate(p.read_text(encoding="utf-8").splitlines(), start=1):
        if (m := ART.match(line)) is not None:
            flush()
            body = []
            cur = {"token": m.group(1), "draws": [], "lead": "", "text": "", "words": 0,
                   "marker": n, "draw_line": 0}
            span = {"start": n + 1, "end": n}
            continue
        if (m := DRAW_LINE.match(line)) is not None:
            cur["draw_line"] = n
            for doc, sid in DRAW.findall(m.group(1)):
                cur["draws"].append("%s#%s" % (doc, sid))
                draws.append((doc, sid))
            span["start"] = n + 1  # the body begins AFTER the draw line, so an
            continue               # edit to the prose never eats the citation
        if not body and not line.strip():
            span["start"] = n + 1  # skip the blank between the markers and the text
            continue
        body.append(line)
        if line.strip():
            span["end"] = n  # trailing blanks stay OUTSIDE the writable range
    flush()

    # A SECTION HEADING BELONGS TO THE SECTION IT OPENS, not to the block above.
    # Markers are the only cut the loop knows, so `## Parallel because somebody
    # typed it` lands at the tail of the PREVIOUS block's body — which read wrong
    # on the page and would have scrambled any reorder, carrying the wrong title
    # with the moved block. Hand each trailing heading down to the block it names.
    raw = p.read_text(encoding="utf-8").replace("\r\n", "\n").split("\n")

    # A `#` INSIDE A FENCE IS NOT A HEADING. Every final.md quotes source, and
    # `# commons/primitives/line/parallel_lines.tscn` is a GDScript comment, not
    # a section. Reading it as one split a block at the wrong line and a reorder
    # then scattered the prose — the same fence rule the source segmenter already
    # follows, which this pass was missing.
    fenced = [False] * len(raw)
    inside = False
    for i, ln in enumerate(raw):
        if ln.lstrip().startswith("```"):
            inside = not inside
            fenced[i] = True
            continue
        fenced[i] = inside

    def head_at(ln: int):
        """HEADING match for 1-based line `ln`, or None if it is inside a fence."""
        if ln < 1 or ln > len(raw) or fenced[ln - 1]:
            return None
        return HEADING.match(raw[ln - 1])

    for b in blocks:
        b.setdefault("heading", "")
        b.setdefault("heading_line", 0)
    for i in range(len(blocks) - 1):
        b = blocks[i]
        e = b["end"]
        while e >= b["start"] and not raw[e - 1].strip():
            e -= 1
        m = head_at(e)
        if e >= b["start"] and m:
            blocks[i + 1]["heading"] = m.group(2)
            blocks[i + 1]["heading_line"] = e
            e -= 1
            while e >= b["start"] and not raw[e - 1].strip():
                e -= 1
            b["end"] = e
            b["text"] = "\n".join(raw[b["start"] - 1:e]).strip()
            b["words"] = len(b["text"].split())
            b["lead"] = re.sub(r"\s+", " ", re.sub(r"```.*?```", "", b["text"], flags=re.S))[:160]

    # THE CODA. Nothing follows the last artifact tag, so the closing section —
    # "## What you are standing on", and the line the whole chapter lands on —
    # gets swallowed by the last block. Dragging that block would carry the
    # conclusion into the middle of the room. Split it off; it is not a block and
    # it does not move.
    coda = {"text": "", "start": 0, "end": 0, "heading": ""}
    if blocks:
        last = blocks[-1]
        h = 0
        for ln in range(last["start"] + 1, last["end"] + 1):
            if head_at(ln):
                h = ln
                break
        if h:
            coda = {"heading": head_at(h).group(2), "start": h,
                    "end": last["end"],
                    "text": "\n".join(raw[h - 1:last["end"]]).strip()}
            e = h - 1
            while e >= last["start"] and not raw[e - 1].strip():
                e -= 1
            last["end"] = e
            last["text"] = "\n".join(raw[last["start"] - 1:e]).strip()
            last["words"] = len(last["text"].split())

    # the whole movable unit: heading (if any) through the last line of prose
    for b in blocks:
        b["span_start"] = b["heading_line"] or b["marker"] or b["start"]
        b["span_end"] = b["end"]
    return blocks, draws, coda


def fold(map_name: str) -> dict:
    d = MAPS / map_name
    blocks, draws, coda = read_final(d / "final.md")
    drawn: dict[str, set[str]] = {}
    for doc, sid in draws:
        drawn.setdefault(doc, set()).add(sid)

    docs = []
    for name in DOCS:
        p = d / ("%s.md" % name)
        if not p.exists():
            continue
        text = p.read_text(encoding="utf-8")
        segs = segments(text)
        hit = drawn.get(name, set())
        for s in segs:
            s["drawn"] = s["id"] in hit
            s["tag"] = "<!-- ~%s#%s -->" % (name, s["id"])
        trust, why = TRUST.get(name, ("", ""))
        docs.append({
            "name": name, "words": len(text.split()), "segments": segs,
            "drawn": sum(1 for s in segs if s["drawn"]),
            "trust": trust, "trust_why": why, "hash": sha(text),
        })

    # a draw pointing at a heading that is gone is stale — same class as a stale
    # artifact tag, and it must be loud rather than silently ignored
    have = {"%s#%s" % (dd["name"], s["id"]) for dd in docs for s in dd["segments"]}
    stale = sorted({"%s#%s" % (a, b) for a, b in draws} - have)

    fin = d / "final.md"
    src_words = sum(x["words"] for x in docs if x["name"] in ("tutorial", "critical", "summary"))
    ftext = fin.read_text(encoding="utf-8") if fin.exists() else ""
    fw = len(ftext.split())
    return {
        "map": map_name, "docs": docs,
        "final": {"words": fw, "blocks": blocks, "hash": sha(ftext), "coda": coda},
        "stale": stale,
        "totals": {
            "segments": sum(len(x["segments"]) for x in docs),
            "drawn": sum(x["drawn"] for x in docs),
            "source_words": src_words, "final_words": fw,
            "ratio": round(fw / src_words, 2) if src_words else 0.0,
        },
    }


def all_maps() -> list[str]:
    if TRIAGE.exists():
        seen = json.loads(TRIAGE.read_text(encoding="utf-8")).get("maps", [])
        return [m["map"] for m in seen]
    return sorted(p.name for p in MAPS.iterdir() if p.is_dir())


def main() -> int:
    ap = argparse.ArgumentParser(description="source docs behind one final.md")
    ap.add_argument("--map")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--unused", action="store_true",
                    help="every written room, least-drawn-on first")
    ap.add_argument("--write", metavar="DOC",
                    help="replace a line range in <map>/<DOC>.md with stdin")
    ap.add_argument("--start", type=int)
    ap.add_argument("--end", type=int)
    ap.add_argument("--base-hash", default="")
    ap.add_argument("--reorder", nargs=2, type=int, metavar=("FROM", "TO"),
                    help="move final.md's block FROM to position TO")
    args = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")

    if args.reorder:
        if not args.map:
            ap.error("--reorder needs --map")
        res = reorder_final(MAPS / args.map / "final.md",
                            args.reorder[0], args.reorder[1], args.base_hash)
        print(json.dumps(res, ensure_ascii=False))
        return 0 if res.get("ok") else 1

    if args.write:
        if not args.map or args.start is None or args.end is None:
            ap.error("--write needs --map, --start and --end")
        if not re.fullmatch(r"[A-Za-z0-9_]+", args.write):
            ap.error("--write takes a bare document name")
        target = (MAPS / args.map / ("%s.md" % args.write)).resolve()
        if MAPS.resolve() not in target.parents:  # no traversal out of commons/maps
            ap.error("refusing to write outside commons/maps")
        text = sys.stdin.buffer.read().decode("utf-8")
        res = write_range(target, args.start, args.end, text, args.base_hash)
        print(json.dumps(res, ensure_ascii=False))
        return 0 if res.get("ok") else 1

    if args.unused:
        rows = []
        for m in all_maps():
            if not (MAPS / m / "final.md").exists():
                continue
            f = fold(m)
            rows.append((f["totals"]["drawn"], f["totals"]["segments"], m, f["totals"]["ratio"]))
        rows.sort(key=lambda r: (r[0] / r[1] if r[1] else 1, -r[1]))
        print("%-30s %-12s %s" % ("room", "drawn/segs", "final:source"))
        for dr, sg, m, ratio in rows:
            print("  %-28s %2d/%-8d %.2f" % (m, dr, sg, ratio))
        print("\n%d written room(s); %d of %d source segments drawn on"
              % (len(rows), sum(r[0] for r in rows), sum(r[1] for r in rows)))
        return 0

    if not args.map:
        ap.error("--map is required unless --unused")
    data = fold(args.map)
    if args.json:
        print(json.dumps(data, ensure_ascii=False))
        return 0

    t = data["totals"]
    print("%s — final %d words against %d of source (%.2f)"
          % (data["map"], t["final_words"], t["source_words"], t["ratio"]))
    for doc in data["docs"]:
        print("\n  %-9s %5dw  %-11s %d/%d drawn   %s"
              % (doc["name"], doc["words"], doc["trust"], doc["drawn"],
                 len(doc["segments"]), doc["trust_why"]))
        for s in doc["segments"]:
            print("      %s %-34s %4dw  %s"
                  % ("*" if s["drawn"] else " ", s["heading"][:34], s["words"], s["tag"]))
    if data["stale"]:
        print("\n  STALE draws (heading gone): %s" % ", ".join(data["stale"]))
    return 1 if data["stale"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
