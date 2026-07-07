#!/usr/bin/env python3
"""Assemble the book from the game.

The book's table of contents IS the artifact order in the game. We walk the
spine artifact order (ada_encyclopedia/public/order_of_things.json — produced by
build_order_of_things.py), group it into chapters (one per map, in order), and
for each map gather its prose from the four text files the author writes:

    commons/maps/<Map>/{summary,intent,tutorial,critical}.md

We emit two siblings into the encyclopedia's public/ so the /book page can read
them statically:

    book.json  — structured TOC: chapters[] with sequence/phase, the artifacts
                 that appear in each map (lookup/name/image), and which text
                 sections exist. This is what the /book page consumes.
    book.md    — the concatenated, human-readable book (export/snapshot).

The live editable text the /book page shows comes from the .md files directly
(via /api/book-text); book.json only needs the structure + artifact lists, so it
stays small and the prose never goes stale.

Run:  python tools/build_book.py
Refresh order_of_things.json first if maps/sequences changed:
      python tools/build_order_of_things.py && python tools/build_book.py
"""
from __future__ import annotations
import json
from collections import OrderedDict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENC = ROOT.parent / "ada_encyclopedia"
ORDER_JSON = ENC / "public" / "order_of_things.json"
MAPS_DIR = ROOT / "commons" / "maps"
OUT_JSON = ENC / "public" / "book.json"
OUT_MD = ENC / "public" / "book.md"

# The four files the user names as the book's prose, in reading order.
SECTIONS = ["summary", "intent", "tutorial", "critical"]


def titleize(name: str) -> str:
    return name.replace("_", " ").strip() if name else name


def read_section(map_name: str, section: str) -> str:
    if not map_name:
        return ""
    p = MAPS_DIR / map_name / f"{section}.md"
    if not p.exists():
        return ""
    try:
        return p.read_text(encoding="utf-8").strip()
    except Exception:
        return ""


def main() -> None:
    if not ORDER_JSON.exists():
        raise SystemExit(f"missing {ORDER_JSON} — run: python tools/build_order_of_things.py")
    data = json.loads(ORDER_JSON.read_text(encoding="utf-8"))
    spine = data.get("spine", [])

    # Group the spine into chapters in order. One chapter per map; the four
    # foundation atoms (map == "") collect into a single "Foundations" chapter.
    chapters: "OrderedDict[str, dict]" = OrderedDict()
    for it in spine:
        mp = it.get("map") or ""
        key = mp if mp else "_foundations"
        ch = chapters.get(key)
        if ch is None:
            ch = {
                "id": key,
                "map": mp,
                "title": titleize(mp) if mp else "Foundations",
                "sequence": it.get("sequence", ""),
                "phase": it.get("phase", ""),
                "seq_truth": it.get("seq_truth", ""),
                "artifacts": [],
            }
            chapters[key] = ch
        ch["artifacts"].append({
            "pos": it.get("pos"),
            "lookup": it.get("lookup"),
            "name": it.get("name"),
            "image": it.get("image"),
            "why": it.get("why", ""),
        })

    out_chapters: list[dict] = []
    md: list[str] = [
        "# Ada — The Book",
        "",
        "The table of contents is the artifact order in the game. Each chapter is a "
        "map, walked in spine order; each chapter's prose is assembled from that map's "
        "summary, intent, tutorial and critical files.",
        "",
    ]
    last_seq = None
    n_text = 0

    for ch in chapters.values():
        texts = {s: read_section(ch["map"], s) for s in SECTIONS}
        has = {s: bool(texts[s]) for s in SECTIONS}
        ch["sections"] = has
        ch["hasText"] = any(has.values())
        if ch["hasText"]:
            n_text += 1
        # book.json carries structure only (no prose) — keep it small.
        out_chapters.append({k: ch[k] for k in ("id", "map", "title", "sequence", "phase", "seq_truth", "artifacts", "sections", "hasText")})

        # book.md carries the full prose.
        if ch["sequence"] != last_seq:
            md.append(f"\n# {ch['sequence']}\n")
            if ch.get("seq_truth"):
                md.append(f"> {ch['seq_truth']}\n")
            last_seq = ch["sequence"]
        md.append(f"\n## {ch['title']}\n")
        for s in SECTIONS:
            if texts[s]:
                md.append(f"\n### {s.capitalize()}\n\n{texts[s]}\n")
        if ch["artifacts"]:
            names = ", ".join(a["name"] or a["lookup"] for a in ch["artifacts"])
            md.append(f"\n**Artifacts in this chapter:** {names}\n")

    book = {
        "generated": data.get("generated", ""),
        "chapterCount": len(out_chapters),
        "withText": n_text,
        "sections": SECTIONS,
        "chapters": out_chapters,
    }
    OUT_JSON.write_text(json.dumps(book, indent=1, ensure_ascii=False), encoding="utf-8")
    OUT_MD.write_text("\n".join(md), encoding="utf-8")

    total_artifacts = sum(len(c["artifacts"]) for c in out_chapters)
    print(f"book.json: {len(out_chapters)} chapters, {total_artifacts} artifacts, {n_text} with prose -> {OUT_JSON}")
    print(f"book.md:   {OUT_MD.stat().st_size:,} bytes -> {OUT_MD}")


if __name__ == "__main__":
    main()
