#!/usr/bin/env python3
"""ASSEMBLE THE BASE LAYER — every work's own explanation, in the book's order.

    python tools/build_base_layer.py            # report only
    python tools/build_base_layer.py --write    # + doc/book/BASE_LAYER.md and the JSON
    python tools/build_base_layer.py --json

2026-08-30, Palle: "assemble the 1539 KB into the book's base layer."

WHAT WAS FOUND, AND WHY IT NEEDED ASSEMBLING. Ada Research is "a tutorial gone
strange": each artifact explains one part of its own world, from the point to
non-Euclidean space, irreducibility, QFEP. Measured on 2026-08-30, that
explanation already exists and is enormous — 670 of 770 book works carry a real
header in their own script, 1,539 KB of prose, against 50 KB for every wall text
in the museum combined. The base layer was never missing. It was written, thirty
times the size of the poem, and unassembled.

THE EDITORIAL RULE, because a raw dump is not a book. A header is part prose and
part API documentation: science_screen opens "The meeting point of 2D and 3D in
Ada Research — you EXPERIENCE the pattern with your body while you UNDERSTAND it
with your eyes" and later says "Detects nearby artifacts that have grid data (via
apply_grid_config)". The first belongs in a book and the second does not.

So, in order of preference:

  1. THE @identity BLOCK, where there is one — 606 of 800 book works, 76%. This
     is the project's own authored voice: `essence` (what it is), `desire` (what
     it wants of you), `truth` (what it asserts). The field vocabulary is
     IMPORTED from tools/query_identities.py rather than retyped, so there is one
     list of what an identity contains, not two.
  2. THE LEADING PROSE, cut at the first technical line. 92 works have a real
     header and no identity block.
  3. NOTHING — and the work is still NAMED, with the reason. 95 works have no
     header at all. A silent work that is listed is a want; a silent work that is
     dropped is a work you will never think about again.

Beside each, the book's own two registers: the WALL TEXT you read standing in
front of it, and the REFLECTION if one was written. Palle: "sometimes artifacts
and wallnote content overlap" — they sit together so the overlap is visible.

ORDER IS THE BOOK'S ORDER: chapters by curriculum_spine.json, then halls, then
works, which is the order a reader meets them walking.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
from concord import BOOK, spine_order, spine_meta, registry, header_of  # noqa: E402
from query_identities import IDENTITY_FIELDS  # noqa: E402  one vocabulary, not two

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

# A line that is documentation for a programmer rather than prose for a reader.
# Deliberately conservative: it is better to carry one technical sentence into
# the book, where an editor will see it, than to cut a real paragraph in half.
TECH = re.compile(
    r"@export|@onready|@tool|\bfunc \w+\(|Vector[234]\b|Node3D|SubViewport|MeshInstance"
    r"|_ready\(|_process\(|signal \w+|class_name|res://|\.tscn\b|\.gd\b"
    r"|^\s*(?:Usage|Parameters?|Returns?|Args?|Example|API|TODO|FIXME|NOTE)\s*:",
    re.I | re.M)

FIELD = re.compile(r"^\s*(" + "|".join(IDENTITY_FIELDS) + r")\s*:\s*(.*)$", re.I)


def identity_of(header: str) -> dict:
    """The @identity block as a dict, continuation lines folded in.

    A field runs until the next field or the end: `essence` is routinely wrapped
    over three or four lines and taking only the first would publish a sentence
    cut mid-clause."""
    if "@identity" not in header:
        return {}
    out: dict = {}
    key = ""
    for raw in header.split("\n"):
        m = FIELD.match(raw)
        if m:
            key = m.group(1).lower()
            out[key] = m.group(2).strip()
        elif key and raw.strip() and not raw.strip().startswith("@"):
            out[key] = (out[key] + " " + raw.strip()).strip()
        elif not raw.strip():
            key = ""
    return {k: v for k, v in out.items() if v}


def lead_prose(header: str) -> str:
    """Everything before the first line that is documentation, minus the title."""
    lines = header.split("\n")
    cut = len(lines)
    for i, l in enumerate(lines):
        if TECH.search(l):
            cut = i
            break
    body = "\n".join(lines[:cut]).strip()
    # the first line is usually "name.gd - short label"; keep it only if it is a
    # sentence rather than a filename gloss
    first, _, rest = body.partition("\n")
    if re.search(r"\.gd\b|^\s*\w+\s+-\s", first) and rest.strip():
        body = rest.strip()
    return body


def assemble() -> dict:
    reg = registry()
    meta = spine_meta()
    chapters = []
    seen: dict = {}
    tally = {"works": 0, "identity": 0, "prose": 0, "silent": 0,
             "said": 0, "noted": 0, "chars": 0, "cut_chars": 0}

    for ci, ch in enumerate(spine_order()):
        try:
            doc = json.loads((BOOK / (ch + ".json")).read_text(encoding="utf-8"))
        except Exception:
            continue
        m = meta.get(ch, {})
        halls = []
        for p in doc.get("pearls", []):
            if p.get("drop"):
                continue
            works = []
            for l in p.get("lines", []):
                tok = str(l.get("token", "")).strip()
                if not tok:
                    continue
                tally["works"] += 1
                if tok not in seen:
                    seen[tok] = header_of(reg.get(tok, {}) or {})
                head = seen[tok]
                ident = identity_of(head)
                prose = "" if ident else lead_prose(head)
                if ident:
                    tally["identity"] += 1
                elif len(prose) >= 120:
                    tally["prose"] += 1
                else:
                    prose = ""
                    tally["silent"] += 1
                kept = sum(len(v) for v in ident.values()) + len(prose)
                tally["chars"] += kept
                tally["cut_chars"] += max(0, len(head) - kept)
                text = str(l.get("text", "")).strip()
                note = str(l.get("note", "")).strip()
                if text:
                    tally["said"] += 1
                if note:
                    tally["noted"] += 1
                works.append({"token": tok, "name": str((reg.get(tok) or {}).get("name", "")),
                              "wall": text, "reflection": note,
                              "identity": ident, "prose": prose,
                              "source": "identity" if ident else ("prose" if prose else "none")})
            halls.append({"pearl": str(p.get("pearl", "")), "map": str(p.get("map", "")),
                          "hero": str(p.get("hero", "")), "edge": str(p.get("edge", "")).strip(),
                          "works": works})
        chapters.append({"chapter": ch, "order": ci + 1, "phase": m.get("phase", ""),
                         "qfep_role": m.get("qfep_role", ""), "halls": halls})
    return {"generated": time.strftime("%Y-%m-%dT%H:%M:%S"), "tally": tally, "chapters": chapters}


def to_markdown(d: dict) -> str:
    t = d["tally"]
    out = ["# The base layer",
           "",
           "*Every work's own explanation of its part of the world, in the order the book walks them.*",
           "",
           "Assembled %s by `tools/build_base_layer.py`. Do not edit this file — it is derived."
           % d["generated"],
           "",
           "Ada Research is a tutorial gone strange: each artifact explains one part of its own",
           "world, beginning at the point and ending somewhere in non-Euclidean space,",
           "irreducibility, QFEP. That explanation was already written — it lives in each work's",
           "own script header — and this is the first time it has been put in order.",
           "",
           "| | |",
           "|---|---|",
           "| works in the book | %d |" % t["works"],
           "| speaking through an `@identity` block | %d (%.0f%%) |" % (t["identity"], 100 * t["identity"] / max(1, t["works"])),
           "| speaking through leading prose | %d |" % t["prose"],
           "| **silent — no header of their own** | **%d** |" % t["silent"],
           "| with a wall text | %d |" % t["said"],
           "| with a reflection | %d |" % t["noted"],
           "| prose assembled | %.0f KB |" % (t["chars"] / 1024),
           "| documentation cut away | %.0f KB |" % (t["cut_chars"] / 1024),
           "",
           "A silent work is still listed, with its name and its silence. A work dropped for",
           "having nothing to say is a work nobody will think about again.",
           "",
           "---",
           ""]
    for c in d["chapters"]:
        head = "## %d · %s" % (c["order"], c["chapter"])
        if c["phase"]:
            head += " — *%s*" % c["phase"]
        out += [head, ""]
        if c["qfep_role"]:
            out += ["> %s" % c["qfep_role"], ""]
        for h in c["halls"]:
            out += ["### %s  <span>·</span>  `%s`" % (h["pearl"], h["map"]), ""]
            if h["edge"]:
                out += ["*%s*" % h["edge"], ""]
            for w in h["works"]:
                label = w["name"] or w["token"]
                out += ["#### %s" % label, "", "`%s`" % w["token"], ""]
                if w["wall"]:
                    out += ["> " + w["wall"].replace("\n", "  \n> "), ""]
                if w["source"] == "identity":
                    for f in ("essence", "desire", "truth", "emerges", "critical_parameter"):
                        if w["identity"].get(f):
                            out += ["**%s** — %s" % (f, w["identity"][f]), ""]
                elif w["source"] == "prose":
                    out += [w["prose"], ""]
                else:
                    out += ["*This work has no words of its own. Its header is empty.*", ""]
                if w["reflection"]:
                    out += ["*Reflection.* %s" % w["reflection"].replace("\n", " "), ""]
    return "\n".join(out) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description="assemble every work's own explanation into the book's order")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()

    d = assemble()
    t = d["tally"]

    if a.write:
        md = to_markdown(d)
        for path, body in ((REPO / "doc" / "book" / "BASE_LAYER.md", md),
                           (REPO.parent / "ada_encyclopedia" / "public" / "base_layer.json",
                            json.dumps(d, ensure_ascii=False, indent=1) + "\n")):
            try:
                path.parent.mkdir(parents=True, exist_ok=True)
                tmp = Path(str(path) + ".tmp")
                tmp.write_text(body, encoding="utf-8", newline="\n")
                for _ in range(30):
                    try:
                        os.replace(tmp, path)
                        break
                    except OSError:
                        time.sleep(0.3)
                print("wrote %s  (%.0f KB)" % (path, len(body) / 1024), file=sys.stderr)
            except Exception as e:
                print("  ! could not write %s: %s" % (path, e), file=sys.stderr)

    if a.json:
        print(json.dumps(d, ensure_ascii=False, indent=1))
        return 0

    print("THE BASE LAYER, assembled %s" % d["generated"])
    print()
    print("  %d chapters · %d halls · %d works"
          % (len(d["chapters"]), sum(len(c["halls"]) for c in d["chapters"]), t["works"]))
    print()
    print("  speaking through @identity : %4d  (%.0f%%)" % (t["identity"], 100 * t["identity"] / max(1, t["works"])))
    print("  speaking through prose     : %4d" % t["prose"])
    print("  SILENT, and still named    : %4d" % t["silent"])
    print()
    print("  prose assembled            : %6.0f KB" % (t["chars"] / 1024))
    print("  documentation cut away     : %6.0f KB   (%.0f%% of the headers)"
          % (t["cut_chars"] / 1024, 100 * t["cut_chars"] / max(1, t["chars"] + t["cut_chars"])))
    print("  beside it: %d wall texts, %d reflections" % (t["said"], t["noted"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
