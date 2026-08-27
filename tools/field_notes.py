#!/usr/bin/env python3
"""THE FIELD NOTES — the reflections, gathered as a chapter you can read.

    python tools/field_notes.py                 # the summary: how many, where
    python tools/field_notes.py --apply         # writes doc/book/FIELD_NOTES.md
    python tools/field_notes.py --json          # the document on stdout
    python tools/field_notes.py --chapter color # one chapter

2026-08-27, Palle: "Make it possible to write things into the wall text with my
own reflections. How do I access this reflection as field notes later? I think I
want them to be part of the book?"

THE ANSWER IS THAT A LINE HAS TWO REGISTERS AND ALWAYS HAS.

    text   the LINE — the sentence the wall hangs. Short, public, in the room.
    note   the REFLECTION — what the line has no room for. The field note,
           written standing in front of the thing.

That is not a new idea bolted on: `note` has been a field on a line since the
in-world page editor was built, and four editors can already write it — the
museum's inspector, the museum's world reader, /lines, /wall-texts and
/wall-map. What was missing was every other half. Nothing ever WROTE one (the
museum's save was dead behind a stale guard until 2026-08-27, so the corpus held
842 lines and zero notes), and nothing ever READ them back out of the JSON into
something a person could sit down with.

So the reflection lives on the line it reflects on — one file per chapter, the
same file the wall reads, no second store to drift. And this tool is the reading
end: the notes in walk order, each under its own line, with the hall it was
written in and the work it was written about. That is what makes them part of
the book rather than a comment field: the book's own order, the book's own
chapters, assembled from the book's own files.

WHY NOT A SEPARATE JOURNAL. There are already three — doc/book/RULINGS.md,
doc/book/LOOK_RULINGS.md, commons/maps/*/walked.md (215 of them) — and none of
them reach commons/data/book, which is why none of them can be read in the room.
A reflection written on the line is legible from both ends: at the desk in
/wall-texts, and in the museum by clicking the wall it hangs on.

Nothing here writes a book file. This tool only reads them.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
BOOK_DIR = REPO / "commons" / "data" / "book"
SPINE = REPO / "commons" / "maps" / "curriculum_spine.json"
OUT = REPO / "doc" / "book" / "FIELD_NOTES.md"

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")


def spine_order() -> list[str]:
    """Chapters in walk order. The spine is the authority; anything the spine
    does not name still gets read, appended in name order, so a chapter cannot
    go missing from the notes just because it is not on the spine yet."""
    order: list[str] = []
    try:
        d = json.loads(SPINE.read_text(encoding="utf-8"))
        for s in (d.get("spine", {}) or {}).get("sequences", []) or []:
            n = s if isinstance(s, str) else str(s.get("id") or s.get("sequence") or "")
            if n:
                order.append(n)
    except Exception:
        pass
    rest = sorted(p.stem for p in BOOK_DIR.glob("*.json") if p.stem not in order)
    return [c for c in order if (BOOK_DIR / f"{c}.json").exists()] + rest


def gather(only: str = "") -> dict:
    """Every reflection in the book, in walk order.

    A note is reported with everything needed to FIND it again: the chapter, the
    pearl, the map that pearl is built from, the token it was written about, and
    the line it sits under. `hang` is carried when the hand has ruled where that
    page hangs, because "which wall was I standing at" is the first thing you
    want to know reading a note back.

    THE CHAIN TO THE WALL IS TWO LINKS, NOT ONE. `hang.page` and `adopt.page`
    both count SHOWINGS — the wall works in a segment, numbered by the dresser —
    while a line is numbered by its position in the pearl, which also counts the
    text-only lines and every body that hangs nothing. The first cut of this
    function looked a hang up by line index, which is a different number that
    happens to be an integer. So: adopt binds page to token, hang binds page to
    face, and a line reaches its wall through its TOKEN. Closeness supplies most
    adoptions and is not written down here, so a cell is reported only when the
    hand has ruled both links — which is honest, and better than a confident
    wrong cell."""
    chapters: list[dict] = []
    n_notes = n_lines = 0
    for ch in spine_order():
        if only and ch != only:
            continue
        try:
            doc = json.loads((BOOK_DIR / f"{ch}.json").read_text(encoding="utf-8"))
        except Exception as e:
            print(f"  ! {ch}: {e}", file=sys.stderr)
            continue
        pearls: list[dict] = []
        for p in doc.get("pearls", []):
            hang = {int(h["page"]): h for h in (p.get("hang") or []) if "page" in h}
            # token -> the face the hand hung its page on, via adopt
            face_of: dict[str, dict] = {}
            for ad in (p.get("adopt") or []):
                tok, pg = str(ad.get("token", "") or ""), ad.get("page")
                if tok and pg is not None and int(pg) in hang:
                    face_of[tok] = hang[int(pg)]
            rows: list[dict] = []
            for i, ln in enumerate(p.get("lines", [])):
                n_lines += 1
                note = str(ln.get("note", "") or "").strip()
                if not note:
                    continue
                n_notes += 1
                h = face_of.get(str(ln.get("token", "") or "")) if ln.get("token") else None
                rows.append({
                    "index": i,
                    "token": str(ln.get("token", "") or ""),
                    "text": str(ln.get("text", "") or "").strip(),
                    "by": str(ln.get("by", "") or ""),
                    "viz": str(ln.get("viz", "") or ""),
                    "note": note,
                    "hang": ({"cell": list(h.get("cell", [])), "dir": list(h.get("dir", []))} if h else None),
                })
            if rows:
                pearls.append({
                    "pearl": str(p.get("pearl", "") or ""),
                    "map": str(p.get("map", "") or ""),
                    "hero": str(p.get("hero", "") or ""),
                    "dropped": bool(p.get("drop")),
                    "notes": rows,
                })
        if pearls:
            chapters.append({"chapter": ch, "pearls": pearls})
    return {
        "schema": "field_notes/1",
        "totals": {
            "chapters": len(chapters),
            "pearls": sum(len(c["pearls"]) for c in chapters),
            "notes": n_notes,
            "lines_read": n_lines,
            "characters": sum(len(r["note"]) for c in chapters for p in c["pearls"] for r in p["notes"]),
        },
        "chapters": chapters,
    }


def plural(n: int, word: str) -> str:
    return word if n == 1 else word + "s"


def render(doc: dict) -> str:
    """The document. Chapter, hall, then the line in italic with the reflection
    under it — the same shape the wall has in the room, where the line is the
    loud thing and the note is what you get when you look closer."""
    t = doc["totals"]
    out: list[str] = [
        "# The field notes",
        "",
        "The reflections written on the walls of the endless museum, in walk order.",
        "",
        "Each entry is one line of the book: the sentence a wall hangs, and under it what",
        "was written standing in front of it. The line lives in",
        "`commons/data/book/<chapter>.json` as `text`; the reflection is `note` on the same",
        "line. Both are editable in the museum (click the wall, then the inspector), at",
        "[/wall-map](http://localhost:3003/wall-map), [/wall-texts](http://localhost:3003/wall-texts)",
        "and [/lines](http://localhost:3003/lines).",
        "",
        "*Generated by `python tools/field_notes.py --apply`. Do not edit this file — edit",
        "the book, and run it again.*",
        "",
        f"**{t['notes']} {plural(t['notes'], 'reflection')}** across {t['pearls']} "
        f"{plural(t['pearls'], 'hall')} in {t['chapters']} {plural(t['chapters'], 'chapter')} — "
        f"{t['characters']:,} characters, out of {t['lines_read']} lines in the book.",
        "",
    ]
    if not doc["chapters"]:
        out += [
            "---",
            "",
            "Nothing written yet. The register exists and every editor can reach it — this",
            "page fills itself the first time a wall is written on.",
            "",
        ]
        return "\n".join(out) + "\n"
    for c in doc["chapters"]:
        out += ["---", "", f"## {c['chapter']}", ""]
        for p in c["pearls"]:
            where = p["pearl"] or p["map"]
            tail = f" · `{p['map']}`" if p["map"] and p["map"] != p["pearl"] else ""
            drop = "  *(dropped)*" if p["dropped"] else ""
            out += [f"### {where}{tail}{drop}", ""]
            for r in p["notes"]:
                # bold the token, but never wrap the italic fallback in bold too —
                # ***three stars*** is a different mark and renders as neither
                who = f"**`{r['token']}`**" if r["token"] else "*the hall's own wall text*"
                at = ""
                if r["hang"] and len(r["hang"]["cell"]) >= 2:
                    cx, cz = r["hang"]["cell"][0], r["hang"]["cell"][1]
                    at = f" — hung at cell {cx},{cz}"
                out += [f"{who}{at}", ""]
                if r["text"]:
                    out += [f"> *{r['text']}*", ""]
                else:
                    out += ["> *(no line yet — the reflection came first)*", ""]
                out += [r["note"], ""]
    return "\n".join(out) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="write doc/book/FIELD_NOTES.md")
    ap.add_argument("--json", action="store_true", help="the document on stdout")
    ap.add_argument("--chapter", default="", help="one chapter only")
    a = ap.parse_args()

    doc = gather(a.chapter)
    if a.json:
        print(json.dumps(doc, indent=1, ensure_ascii=False))
        return 0

    t = doc["totals"]
    print(f"THE FIELD NOTES — {t['notes']} reflection(s), {t['characters']:,} characters")
    print(f"  read {t['lines_read']} lines across the book")
    for c in doc["chapters"]:
        n = sum(len(p["notes"]) for p in c["pearls"])
        print(f"  {c['chapter']:24s} {n:3d} in {len(c['pearls'])} hall(s)")
    if not doc["chapters"]:
        print("  nothing written yet — the register is empty, which is not the same as absent")

    if a.apply:
        OUT.parent.mkdir(parents=True, exist_ok=True)
        tmp = OUT.with_suffix(".md.tmp")
        tmp.write_text(render(doc), encoding="utf-8")
        os.replace(tmp, OUT)
        print(f"  -> {OUT.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
