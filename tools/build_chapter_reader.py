#!/usr/bin/env python3
"""build_chapter_reader.py — assemble developed walked.md pages into readable chapters.

The book's pages live scattered as commons/maps/<Map>/walked.md. This gathers
them per sequence in tutorial/chapter_maps order (R-028 load-bearing selection)
and writes ada_encyclopedia/public/chapters.json for the /chapter reader — so a
chapter can be read straight through, which is how a voice gets ruled.

Only DEVELOPED pages are included (a seed page — "not yet walked" — is skipped).

Usage: python tools/build_chapter_reader.py
"""
from __future__ import annotations

import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.path.join(os.path.dirname(REPO), "ada_encyclopedia")
MAPS_DIR = os.path.join(REPO, "commons", "maps")
CHAPTER_MAPS = os.path.join(REPO, "doc", "book", "chapter_maps.json")
OUT = os.path.join(ENC, "public", "chapters.json")

SPINE = ["primitives", "transformation", "symmetry", "array_tutorial", "color", "change",
         "isosurfaces", "boolean_surfaces", "forces", "formfinding", "wavefunctions", "randomness",
         "noise", "cellularautomata", "fractals", "lsystems", "proceduralgeneration",
         "swarmintelligence", "softbodies", "machinelearning", "graphtheory",
         "foundationscrisis", "qfeplaboratory", "postfoundationscrisis"]

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass


def load_json(p):
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def developed(md: str) -> bool:
    # a developed page has a real (non-placeholder) walk section
    if "## The walk" not in md:
        return False
    walk = section(md, "The walk")
    return "not yet walked" not in walk and len(walk) > 300


def section(md: str, header: str) -> str:
    """extract one '## <header>' section body, stripped."""
    m = re.search(rf"##\s*{re.escape(header)}\s*\n(.*?)(?=\n##\s|\Z)", md, re.S)
    return m.group(1).strip() if m else ""


def main() -> int:
    order = {}
    if os.path.exists(CHAPTER_MAPS):
        cm = load_json(CHAPTER_MAPS).get("chapters", {})
        order = {s: cm.get(s, {}).get("keep", []) for s in cm}

    chapters = []
    for seq in SPINE:
        maps = list(order.get(seq) or [])
        # include ANY developed page in the sequence not already selected, so the
        # reader never hides a page that was written (e.g. a narratively load-
        # bearing map the mechanical R-028 criterion dropped — Palle rules in/out).
        seq_json = os.path.join(REPO, "commons", "maps", "sequences", f"{seq}.json")
        if os.path.exists(seq_json):
            d = load_json(seq_json)
            for v in (d.get("sequences") or {}).values():
                for mm in v.get("maps", []):
                    nm = mm if isinstance(mm, str) else mm.get("name", "")
                    wp = os.path.join(MAPS_DIR, nm, "walked.md")
                    if nm and nm not in maps and os.path.exists(wp) and developed(open(wp, encoding="utf-8").read()):
                        maps.append(nm)
        pages = []
        for m in maps:
            wp = os.path.join(MAPS_DIR, m, "walked.md")
            if not os.path.exists(wp):
                continue
            md = open(wp, encoding="utf-8").read()
            if not developed(md):
                continue
            pages.append({
                "map": m,
                "cast": section(md, "The cast").replace("\n", " ").strip(),
                "walk": section(md, "The walk"),
                "turn": section(md, "The turn (critical)"),
            })
        if pages:
            chapters.append({"seq": seq, "pages": pages, "n": len(pages)})

    out = {"generated_by": "tools/build_chapter_reader.py", "chapters": chapters}
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        json.dump(out, f, indent=1, ensure_ascii=False)
    tot = sum(c["n"] for c in chapters)
    print(f"chapters.json: {len(chapters)} chapters, {tot} developed pages -> {OUT}")
    for c in chapters:
        print(f"  {c['seq']}: {c['n']} pages")
    return 0


if __name__ == "__main__":
    sys.exit(main())
