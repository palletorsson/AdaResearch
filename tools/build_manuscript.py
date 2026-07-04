#!/usr/bin/env python3
"""build_manuscript.py — merge the frame + the tutorial chapters into ONE book.

The synthesis layer: /book is the encyclopedia (every path), /tutorial is THE
path (8 pages per spine sequence, authored overlays), brain-vault holds the
six-part narrative arc. This tool merges them:

  doc/manuscript_frame.json          the arc — parts, epigraphs, front matter
  ada_encyclopedia/public/tutorial/  the chapters — skeleton + authored prose

into a single linear manuscript:

  ada_encyclopedia/public/manuscript.md    the book, one markdown file
  ada_encyclopedia/public/manuscript.json  structure (parts -> chapters), small

manuscript.json stays prose-free (like book.json) so it never goes stale; the
.md is the export — feed it to a reader page, pandoc, or auto-indesign.

Usage:
  python tools/build_manuscript.py            # build both outputs
  python tools/build_manuscript.py --stats    # coverage report only
"""
from __future__ import annotations

import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.environ.get("ADA_ENCYCLOPEDIA_PATH", "C:/Users/palle/Documents/GitHub/ada_encyclopedia")
FRAME = os.path.join(REPO, "doc", "manuscript_frame.json")
TUTORIAL_DIR = os.path.join(ENC, "public", "tutorial")
OUT_MD = os.path.join(ENC, "public", "manuscript.md")
OUT_JSON = os.path.join(ENC, "public", "manuscript.json")

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass


def load_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def demojibake(s):
    """Repair double-encoded UTF-8 (â€", Â², â€™ …) that leaks in from some
    sequence JSONs. Strings that are already clean pass through untouched;
    strings that mix mojibake with real non-cp1252 chars stay as they are."""
    if not isinstance(s, str) or not any(m in s for m in ("â€", "Â", "Ã")):
        return s
    try:
        return s.encode("cp1252").decode("utf-8")
    except Exception:
        return s


def clean(node):
    if isinstance(node, str):
        return demojibake(node)
    if isinstance(node, list):
        return [clean(x) for x in node]
    if isinstance(node, dict):
        return {k: clean(v) for k, v in node.items()}
    return node


def art_prose(a: dict) -> str:
    """Authored prose wins; else essence + description as the fallback voice."""
    if a.get("prose"):
        return a["prose"]
    bits = []
    if a.get("essence"):
        bits.append(f"*{a['essence']}*")
    if a.get("description"):
        bits.append(a["description"])
    return "\n\n".join(bits)


def render_artifact(a: dict, lines: list, heading: str | None = None) -> None:
    title = heading or a.get("title") or a.get("name", "")
    lines.append(f"**{title}**")
    lines.append("")
    if a.get("image"):
        lines.append(f"![{title}]({a['image']})")
        lines.append("")
    prose = art_prose(a)
    if prose:
        lines.append(prose)
        lines.append("")
    if a.get("truth"):
        lines.append(f"> {a['truth']}")
        lines.append("")


def render_chapter(t: dict, number: int, lines: list) -> dict:
    """Render one tutorial (8 pages) as a chapter; return its TOC entry."""
    name = t.get("name") or t["seq"]
    lines.append(f"## Chapter {number}: {name}")
    lines.append("")
    stats = {"seq": t["seq"], "name": name, "number": number,
             "authored": bool(t.get("authored")), "truth": t.get("truth", "")}
    walk_count = 0
    for p in t.get("pages", []):
        kind = p["kind"]
        if kind == "question":
            if p.get("truth"):
                lines.append(f"> **{p['truth']}**")
                lines.append("")
            if p.get("formula"):
                lines.append(f"`{p['formula']}`")
                lines.append("")
            if p.get("text"):
                lines.append(p["text"])
                lines.append("")
        elif kind == "primitive":
            lines.append("### The Primitive")
            lines.append("")
            if p.get("lead"):
                lines.append(f"*{p['lead']}*")
                lines.append("")
            if isinstance(p.get("artifact"), dict):
                render_artifact(p["artifact"], lines)
        elif kind == "walk":
            walk_count += 1
            lines.append(f"### {p.get('title') or 'The Walk'}")
            lines.append("")
            if p.get("lead"):
                lines.append(f"*{p['lead']}*")
                lines.append("")
            for a in p.get("artifacts") or []:
                render_artifact(a, lines)
        elif kind == "turn":
            lines.append("### The Turn — parameters")
            lines.append("")
            if p.get("text"):
                lines.append(p["text"])
                lines.append("")
            knobs = [k.get("title") or k.get("name", "") for k in p.get("knobs") or []]
            if knobs:
                lines.append("Open in the dressing-room viewer: " + ", ".join(knobs) + ".")
                lines.append("")
        elif kind == "critical":
            lines.append("### The Critical Reading")
            lines.append("")
            if p.get("lead"):
                lines.append(f"*{p['lead']}*")
                lines.append("")
            if p.get("qfep_term"):
                lines.append(f"QFEP term: **{p['qfep_term']}**")
                lines.append("")
            if p.get("qfep_connection"):
                lines.append(p["qfep_connection"])
                lines.append("")
            claims = p.get("claims") or []
            if claims:
                lines.append("The artifacts' own claims:")
                lines.append("")
                for c in claims:
                    nm = c.get("name", "").replace("_", " ")
                    lines.append(f"> {c.get('truth', '')} — *{nm}*")
                    lines.append("")
        elif kind == "world":
            lines.append("### In the World")
            lines.append("")
            if p.get("lead"):
                lines.append(f"*{p['lead']}*")
                lines.append("")
            maps = p.get("maps") or []
            if maps:
                lines.append("| Room | Grid | Artifacts | Footprint |")
                lines.append("|------|------|-----------|-----------|")
                for m in maps:
                    lines.append(f"| {m.get('name', '')} | {m.get('cols', '?')}×{m.get('rows', '?')} "
                                 f"| {m.get('artifacts', 0)} | {m.get('footprint', '')} m |")
                lines.append("")
            objs = p.get("objectives") or []
            if objs:
                lines.append("What this chapter teaches, walked rather than read:")
                lines.append("")
                for o in objs:
                    lines.append(f"- {o}")
                lines.append("")
            # Fold 5 — the machine's ride, the second machine register.
            ride = p.get("ride")
            if isinstance(ride, dict) and ride.get("lines"):
                lines.append(f"The machine walked {ride.get('map', 'the room')} "
                             "and filed this ride log:")
                lines.append("")
                for ln in ride["lines"]:
                    lines.append(f"> {ln}")
                    lines.append("")
        elif kind == "seed":
            lines.append("### The Seed")
            lines.append("")
            if p.get("truth"):
                lines.append(f"> **{p['truth']}**")
                lines.append("")
            exs = p.get("exercises") or []
            if exs:
                lines.append("Exercises:")
                lines.append("")
                for i, e in enumerate(exs, 1):
                    lines.append(f"{i}. {e}")
                lines.append("")
            if p.get("coda"):
                lines.append(p["coda"])
                lines.append("")
            if p.get("next"):
                lines.append(f"*Next: {p['next']}*")
                lines.append("")
    # Declared blanks (R-008) — the excavation's open slots, in print.
    blanks = t.get("blanks") if isinstance(t.get("blanks"), list) else []
    if blanks:
        lines.append("### The Blanks — declared open")
        lines.append("")
        for b in blanks:
            lines.append(f"- ◇ {b.get('note', '')}")
        lines.append("")
    # The ledger — the second voice, closing the chapter. Two registers:
    # authored motif entries (human, uneven, deliberate) and one computed
    # field note (the machine reporting its own edge decision).
    motifs = t.get("motifs") if isinstance(t.get("motifs"), dict) else {}
    dig = t.get("dig") if isinstance(t.get("dig"), dict) else {}
    if motifs or dig.get("pearls"):
        lines.append("### The Ledger")
        lines.append("")
        for k, v in motifs.items():
            lines.append(f"- **{k}** — {v}")
        if dig.get("pearls"):
            total, walked = dig["pearls"], dig.get("walked", 0)
            left = total - walked
            note = (f"{walked} of {total} artifacts excavated; {left} remain at depth."
                    if left > 0 else
                    f"{walked} of {total} artifacts excavated; this stratum is fully exposed.")
            if dig.get("curated"):
                note += " The cut was made by hand."
            lines.append(f"- **the dig** — {note}")
        lines.append("")
        stats["motifs"] = list(motifs.keys())
    return stats


def main() -> int:
    frame = load_json(FRAME)
    if not frame:
        print(f"!! no frame: {FRAME}")
        return 1

    chapters: dict[str, dict] = {}
    for part in frame["parts"]:
        for seq in part["sequences"]:
            t = load_json(os.path.join(TUTORIAL_DIR, f"{seq}.json"))
            if t:
                chapters[seq] = clean(t)

    total = sum(len(p["sequences"]) for p in frame["parts"])
    authored = [s for s, t in chapters.items() if t.get("authored")]
    missing = [s for p in frame["parts"] for s in p["sequences"] if s not in chapters]
    print(f"chapters: {len(chapters)}/{total} built, {len(authored)} authored "
          f"({', '.join(authored) or 'none'})")
    if missing:
        print(f"missing tutorials (skipped in body, flagged in TOC): {', '.join(missing)}")
    if "--stats" in sys.argv[1:]:
        return 0

    lines: list = []
    toc_entries: list = []
    # Front matter.
    lines += [f"# {frame['title']}", "", f"*{frame['subtitle']}*", ""]
    if frame.get("formula"):
        lines += [f"> **{frame['formula']}**", ""]
    if frame.get("intro"):
        lines += [frame["intro"], ""]

    # The ledger, declared: the book's undertow, five threads under the pedagogy.
    if frame.get("motifs"):
        lines += ["## The Ledger", ""]
        if frame.get("motifs_intro"):
            lines += [f"*{frame['motifs_intro']}*", ""]
        for m in frame["motifs"]:
            lines.append(f"- **{m['name']}** — {m['statement']}")
        lines.append("")

    # The dig, declared: the book as excavation report, not survey.
    if frame.get("excavation_note"):
        lines += ["## The Dig", "", frame["excavation_note"], ""]

    # Table of contents.
    lines += ["## Contents", ""]
    num = 0
    for part in frame["parts"]:
        lines.append(f"**Part: {part['title']}**")
        lines.append("")
        for seq in part["sequences"]:
            num += 1
            t = chapters.get(seq)
            if t:
                nm = t.get("name") or seq
                tr = f" — *{t['truth']}*" if t.get("truth") else ""
                mark = "" if t.get("authored") else " †"
                lines.append(f"{num}. {nm}{tr}{mark}")
            else:
                lines.append(f"{num}. {seq} *(not yet built)*")
        lines.append("")
    lines += ["*† skeleton chapter — assembled from truth sources, awaiting its writing pass.*", ""]

    # Body: parts and chapters.
    num = 0
    for part in frame["parts"]:
        lines += [f"# Part: {part['title']}", ""]
        if part.get("epigraph"):
            lines += [f"*{part['epigraph']}*", ""]
        part_toc = {"title": part["title"], "chapters": []}
        for seq in part["sequences"]:
            num += 1
            t = chapters.get(seq)
            if not t:
                continue
            part_toc["chapters"].append(render_chapter(t, num, lines))
        toc_entries.append(part_toc)

    md = "\n".join(lines)
    with open(OUT_MD, "w", encoding="utf-8") as f:
        f.write(md)
    with open(OUT_JSON, "w", encoding="utf-8") as f:
        json.dump({"title": frame["title"], "subtitle": frame["subtitle"],
                   "formula": frame.get("formula", ""), "parts": toc_entries},
                  f, indent=1)
    print(f"manuscript: {len(md)} chars, {num} chapter slots -> {OUT_MD}")
    print(f"structure  -> {OUT_JSON}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
