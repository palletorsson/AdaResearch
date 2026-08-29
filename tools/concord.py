#!/usr/bin/env python3
"""THE CONCORDANCE — where in the text does this artifact appear?

    python tools/concord.py --token=science_screen             # where is it named
    python tools/concord.py --file=commons/maps/X/critical.md  # what does this text name
    python tools/concord.py --wants                            # the two gaps, both directions
    python tools/concord.py --silent                           # works nobody has written about
    python tools/concord.py --stats                            # the corpus, measured

2026-08-29, Palle: "how do we know where in the text the artifact exists."

TWO REGISTERS, AND THIS TOOL IS ONLY THE FIRST ONE. A finding is cheap, fallible,
re-runnable and stores NOTHING. A claim is authored, permanent, and gated — that
is `note_src` in the book, checked by tools/edge_gate.py, and promoted from a
finding by a human pressing a button. This file never writes a claim. It reads
the corpus fresh every call, so it is never stale, because there is nothing to be
stale. Every persisted index in this repo has already rotted with no freshness
gate: doc/artifact_to_maps.json covers 1661 of 2789 maps, doc/LOD_TREE.json is
months old, ARTIFACT_DOC_INDEX.json sits at 1764 of 2878 artifacts.

WHY THIS DOES NOT IMPORT edge_gate.norm() — and the trap is worth the paragraph.
The obvious move is to share the gate's normaliser so the search and the gate
agree. It is wrong, and measurably: edge_gate.norm() strips markdown emphasis,
which DELETES EVERY UNDERSCORE. Through it, norm("grid_lines") == norm("gridlines")
== "gridlines", so the token grid_lines would match the ordinary English word, and
body_of() returns text with zero underscores. Searching there is searching a
corpus with the artifact names dissolved.

They are two different questions and they get two different rules:
    the SEARCH asks   does this text name this token      -> raw text, this file
    the GATE asks     is this quote still in this file    -> edge_gate.norm()
The gate keeps its normaliser. The search never borrows it.

THE MEASURED SHAPE OF THE PROBLEM, which decides every tier below:
    2878 registry tokens. 1102 (38.3%) are named at least once in map prose.
    BUT 67.7% of all raw matches come from 30 common English words that happen to
    be artifact tokens — point (2338), cube (1583), line (1118), sphere, origin.
    The 328 single-word tokens are 11% of the corpus and carry 73.7% of matches.
So single-word tokens are QUARANTINED, not blocklisted: a blocklist makes `point`
unfindable in its own room, which is absurd. They are admitted only where the map
actually places them — the `placed` tier — and the reason is printed on the row.

AND A SURFACE BUG THAT ALREADY SHIPPED ONCE AT 6x: measuring literal snake_case
gave 114 artifacts when the truth is 781, because a human-form regex was allowed
to treat "_" as a word separator, the two patterns came out the same length, and
the alternation tie-broke arbitrarily. Green run, plausible number, no error.
The surfaces are asserted DISJOINT by --stats for that reason.

DUPLICATION, DECLARED. ada_encyclopedia/src/lib/game/TextMapCoherence.ts:368
isTokenMentioned() implements a mention rule too, and a different one — raw
includes(), so `cube` fires inside `pick_up_cube`. That is a real second
implementation of one sub-rule, which is the long_museum h20/h23 shape. It is not
hidden: tools/concord_parity.py runs both rules over the corpus and reports every
disagreement, so the drift is loud. Forum 260829-al7em asks who should own it.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
ENC = REPO.parent / "ada_encyclopedia"
REG = REPO / "commons" / "artifacts" / "registry"
BOOK = REPO / "commons" / "data" / "book"

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

# The six map prose kinds. tutorial.md is IN, against the advice to drop it: the
# argument for dropping was 84.1% of its declared GDScript symbols not resolving,
# which is a fact about its code blocks, not its prose — and 5 of the 218 anchors
# a human actually wrote cite tutorial.md as their source. Dropping it would make
# five real citations unreachable by the tool meant to find them. Code fences are
# stripped instead, which is the fix that addresses the actual complaint.
PROSE_KINDS = ("critical", "tutorial", "summary", "intent", "technical", "blurb")

FENCE = re.compile(r"```.*?```", re.S)
INLINE = re.compile(r"`[^`\n]*`")
UNDERSCORED = re.compile(r"(?<![A-Za-z0-9_])([a-z][a-z0-9]*(?:_[a-z0-9]+)+)(?![A-Za-z0-9_])")


def strip_code(text: str) -> str:
    """Code is not prose about the work; it is the work's address.

    The blog alone names 528 registry tokens in underscored form, and the sample
    is dominated by command lines and map cells — "--target=three_body_problem",
    "balance_puzzle:0:1". Counting those as "this text discusses this artifact"
    is how an index looks full and says nothing. tools/semantic_coverage.py
    already strips fences before tokenizing; this follows it."""
    return INLINE.sub(" ", FENCE.sub(" ", text))


def registry() -> dict:
    """token -> {name, class_name, ...}.

    substrate_vectors.json is skipped by construction: it is a FLAT
    token->weights sidecar with no `artifacts` key, and a reader doing
    d.get("artifacts", d) silently folds 448 substrate keys into the
    denominator."""
    out: dict = {}
    for f in sorted(REG.glob("*.json")):
        try:
            d = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        a = d.get("artifacts")
        if isinstance(a, dict):
            for k, v in a.items():
                if isinstance(v, dict):
                    out.setdefault(k, v)
    return out


def placements() -> dict:
    """token -> set of map dir names, parsed from layers.interactables.

    NEVER doc/artifact_to_maps.json. It keys maps by DISPLAY title ("Gallery:
    QFEP"), which does not join to the commons/maps/<Dir>/ path the prose lives
    at; 646 of its 1325 titles are not directory names, `sequence` is empty in
    100% of rows, and it covers 1661 of 2789 maps. Thirty lines here is the
    difference between a working join and a June answer.

    A cell is lookup[:rot[:y]][#key:value...] — split on BOTH : and #, or the
    config shorthand lands 66 placements in the wrong bucket."""
    out: dict = {}
    for m in REPO.glob("commons/maps/*/map_data.json"):
        try:
            d = json.loads(m.read_text(encoding="utf-8"))
        except Exception:
            continue
        rows = (d.get("layers") or {}).get("interactables") or []
        for row in rows:
            for cell in (row or []):
                s = str(cell).strip().lstrip("#")
                if not s or s in {"0", "1", "2", "3", "4", "5"}:
                    continue
                tok = re.split(r"[:#]", s, 1)[0].strip()
                if tok:
                    out.setdefault(tok, set()).add(m.parent.name)
    return out


def corpus() -> list:
    """Every passage the concordance is allowed to point at.

    Each entry: {rel, kind, map, text} — text already code-stripped.

    Refused, and the reason matters: artifacts.md (202/202) and eye_shot.md
    (208/208) are deterministic template output, and doc/book/eye_shots/ is a
    byte-identical twin of the latter that would double-count 208 pages."""
    out = []
    for d in sorted((REPO / "commons" / "maps").iterdir()):
        if not d.is_dir():
            continue
        for k in PROSE_KINDS:
            p = d / (k + ".md")
            if p.exists():
                try:
                    out.append({"rel": str(p.relative_to(REPO)).replace("\\", "/"),
                                "kind": k, "map": d.name,
                                "text": strip_code(p.read_text(encoding="utf-8", errors="replace"))})
                except Exception:
                    pass
    blog = ENC / "src" / "content" / "blog"
    if blog.exists():
        for p in sorted(blog.glob("*.md*")):
            try:
                out.append({"rel": "blog/" + p.name, "kind": "blog", "map": None,
                            "text": strip_code(p.read_text(encoding="utf-8", errors="replace"))})
            except Exception:
                pass
    for p in sorted((REPO / "doc").glob("*.md")):
        try:
            out.append({"rel": str(p.relative_to(REPO)).replace("\\", "/"),
                        "kind": "essay", "map": None,
                        "text": strip_code(p.read_text(encoding="utf-8", errors="replace"))})
        except Exception:
            pass
    return out


def book_lines() -> list:
    """Every line in the book, with where it lives.

    The book is a corpus too, and this is the half of the loop that already
    works: a reflection typed in the headset lands as `note` on the line, and is
    searchable the minute the next scan reads the file. No rebuild, no reindex."""
    out = []
    for f in sorted(BOOK.glob("*.json")):
        try:
            doc = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        for pi, p in enumerate(doc.get("pearls", [])):
            for li, l in enumerate(p.get("lines", [])):
                out.append({"chapter": f.stem, "pearl": str(p.get("pearl", "")),
                            "map": str(p.get("map", "")), "hero": str(p.get("hero", "")),
                            "pi": pi, "li": li, "token": str(l.get("token", "")),
                            "text": str(l.get("text", "")), "note": str(l.get("note", "")),
                            "note_src": l.get("note_src") or None})
    return out


def surfaces(tok: str, meta: dict) -> list:
    """The three ways a text can name a work, kept mutually distinct.

    literal  the underscored token. 781 artifacts, 561 of them found ONLY here —
             the prose quotes map data far more often than it talks like a person.
    display  the registry `name`. Worth +143 artifacts, and it reaches the 1487
             of 2878 whose real display name is not the token with spaces. This
             is the surface a human writing naturally uses, and it was nearly
             missed by every reading of the problem.
    human    the token with spaces. 329 artifacts, 109 unique to it.

    class_name is dropped: 102 artifacts, 32 unique, and 30 of those 32 are a
    shared class (Grid2DSubstrate, Cylinder) that cannot identify one object."""
    out = [("literal", tok)]
    if "_" in tok:
        out.append(("human", tok.replace("_", " ")))
    name = str(meta.get("name", "")).strip()
    if name and len(name) >= 4 and name.lower() not in {s.lower() for _, s in out}:
        out.append(("display", name))
    return out


def _pat(s: str) -> re.Pattern:
    r"""Word boundary as a lookaround, so `cube` does not fire inside
    pick_up_cube. \b will not do it: an underscore is a word character, so
    \bcube\b matches happily inside pick_up_cube and the junk problem doubles."""
    return re.compile(r"(?<![A-Za-z0-9_])" + re.escape(s) + r"(?![A-Za-z0-9_])", re.I)


def paragraphs(text: str) -> list:
    out = []
    for n, blk in enumerate(re.split(r"\n\s*\n", text)):
        b = blk.strip()
        if b:
            out.append((n, b))
    return out


ROSTER_HEAD = re.compile(
    r"^\s*(?:[#>*\-\d.]+\s*)?(?:key artifacts|artifacts|the cast|placeholders|"
    r"contents|inventory|what it holds|in the order you meet them)\b", re.I)


def is_roster(para: str, regset: set) -> bool:
    """A roster names many works; a passage discusses one.

    This is the difference between an index that looks full and one that says
    something. Measured on science_screen before the rule existed: of 53 `named`
    hits, the overwhelming majority were one generated sentence repeated across
    the Archetype_* maps — "Key artifacts: - Placeholders: library_rack
    (centerpiece), science_screen (wall display), xyz_slider_plate ...". Fifty
    citations that all say the same nothing.

    Two tells, and the second is the general one: an explicit roster heading, or
    a paragraph naming three or more distinct registry tokens. A text genuinely
    about a work rarely names two others in the same breath; a list always does."""
    if ROSTER_HEAD.search(para):
        return True
    return len(set(UNDERSCORED.findall(para.lower())) & regset) >= 3


def find(tok: str, meta: dict, corp: list, placed: set, regset: set) -> dict:
    """Every passage naming this work, tiered.

    named   a literal (multi-word) or display hit in a paragraph that is not a
            roster. This is the answer.
    placed  a single-word or human hit in the prose of a map that ACTUALLY
            places the token. A co-occurrence proxy, not a proof — and the
            reason is printed on every row so it stays a guess out loud.
    roster  a hit inside a list of works. Counted and folded: it is evidence the
            work is CATALOGUED, never evidence it is discussed.
    loose   everything else. Counted, folded, never listed by default."""
    hits = {"named": [], "placed": [], "roster": [], "loose": []}
    single = "_" not in tok
    pats = [(kind, s, _pat(s)) for kind, s in surfaces(tok, meta)]
    for doc in corp:
        low = doc["text"].lower()
        if not any(s.lower() in low for _, s, _ in pats):
            continue
        for pn, para in paragraphs(doc["text"]):
            for kind, s, pat in pats:
                m = pat.search(para)
                if not m:
                    continue
                strong = (kind == "display") or (kind == "literal" and not single)
                in_own = bool(doc["map"] and doc["map"] in placed)
                if is_roster(para, regset):
                    tier, why = "roster", "a list of works, not a passage about one"
                elif strong:
                    tier, why = "named", ""
                elif in_own:
                    tier, why = "placed", "single-word token, admitted because this map places it"
                else:
                    tier, why = "loose", "single-word token in a map that does not place it"
                hits[tier].append({"file": doc["rel"], "kind": doc["kind"], "map": doc["map"],
                                   "para": pn, "surface": kind, "matched": m.group(0),
                                   "own": in_own, "why": why,
                                   # 1000, not 400. Measured: only 56% of named
                                   # hits live in a file /book can render — the
                                   # rest are blog, doc essays, technical.md and
                                   # blurb.md. For those the excerpt IS the
                                   # reading, so it has to carry the paragraph
                                   # rather than a taste of it.
                                   "excerpt": re.sub(r"\s+", " ", para)[:1000]})
                break
    return hits


def cmd_stats() -> int:
    reg = registry()
    bad = []
    for t, m in reg.items():
        seen = {}
        for kind, s in surfaces(t, m):
            k = s.lower()
            if k in seen:
                bad.append((t, kind, seen[k], s))
            seen[k] = kind
    corp = corpus()
    chars = sum(len(d["text"]) for d in corp)
    print("CORPUS   %d passages, %.2f MB, %d map dirs" %
          (len(corp), chars / 1e6, len({d["map"] for d in corp if d["map"]})))
    for k in sorted({d["kind"] for d in corp}):
        print("   %-10s %5d" % (k, sum(1 for d in corp if d["kind"] == k)))
    print("REGISTRY %d tokens, %d single-word (quarantined to the placed tier)" %
          (len(reg), sum(1 for t in reg if "_" not in t)))
    print("SURFACES within-token disjointness: %s" %
          ("FAIL — %d collisions" % len(bad) if bad else "ok"))
    for t, a, b, s in bad[:10]:
        print("   %s: %s and %s both produce %r" % (t, a, b, s))
    return 1 if bad else 0


def subjectless_edges() -> list:
    """A thought with no body: a pearl carrying an `edge` and an `edge_src` and
    no hero and no lines. 50 of the 51 pearl-level edges are like this — the
    chamber halls. Somebody wrote a sentence about the room and the book holds no
    work to attribute it to."""
    out = []
    for f in sorted(BOOK.glob("*.json")):
        try:
            doc = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        for p in doc.get("pearls", []):
            if isinstance(p.get("edge_src"), dict) and not str(p.get("hero", "")).strip():
                out.append({"chapter": f.stem, "pearl": str(p.get("pearl", "")),
                            "map": str(p.get("map", "")), "said": str(p.get("edge", "")),
                            "lines": len(p.get("lines", []))})
    return out


def cmd_wants(as_json: bool) -> int:
    reg, place, bl = registry(), placements(), book_lines()
    booktok = {l["token"] for l in bl if l["token"]}
    no_words = sorted((set(place) & set(reg)) - booktok)
    empty = [l for l in bl if l["token"] and not l["text"].strip()]
    no_work = sorted(t for t in booktok if t not in place)
    first = {}
    for l in bl:
        first.setdefault(l["token"], l)
    out = {
        "work_with_no_words": {"n": len(no_words), "tokens": no_words[:500]},
        "slot_with_no_words": {"n": len(empty),
                               "lines": [{"chapter": l["chapter"], "pearl": l["pearl"],
                                          "token": l["token"], "map": l["map"],
                                          "pi": l["pi"], "li": l["li"]} for l in empty[:500]]},
        "line_with_no_work": {"n": len(no_work),
                              "lines": [{"token": t, "said": first.get(t, {}).get("text", ""),
                                         "chapter": first.get(t, {}).get("chapter", ""),
                                         "pearl": first.get(t, {}).get("pearl", ""),
                                         "map": first.get(t, {}).get("map", ""),
                                         "in_registry": t in reg} for t in no_work]},
        "edge_with_no_subject": {"n": len(subjectless_edges()), "pearls": subjectless_edges()[:200]},
    }
    if as_json:
        print(json.dumps(out, ensure_ascii=False, indent=1))
        return 0
    print("THE TWO WANTS — the chain runs both ways")
    print()
    print("  A WORK WITH NO WORDS   %5d artifacts stand in a map and have no book line" % out["work_with_no_words"]["n"])
    print("  A SLOT WITH NO WORDS   %5d book lines carry a token and empty text" % out["slot_with_no_words"]["n"])
    print("  A LINE WITH NO WORK    %5d book tokens are placed in no map anywhere" % out["line_with_no_work"]["n"])
    print("  A THOUGHT WITH NO BODY %5d pearls carry an edge and no work to hang it on" % out["edge_with_no_subject"]["n"])
    print()
    print("  a want is a direction of travel, not a deficit:")
    print("     work -> text   write the line          %d + %d waiting" %
          (out["work_with_no_words"]["n"], out["slot_with_no_words"]["n"]))
    print("     text -> work   build the artifact      %d waiting" % out["line_with_no_work"]["n"])
    print("     text -> body   give the thought a home %d waiting" % out["edge_with_no_subject"]["n"])
    print()
    print("  the lines asking for a work to be built:")
    for r in out["line_with_no_work"]["lines"]:
        print("    %-42s %s / %s%s" % (r["token"], r["chapter"], r["pearl"],
                                       "" if r["in_registry"] else "   [not in the registry either]"))
        if r["said"]:
            print("        %s" % re.sub(r"\s+", " ", r["said"])[:120])
    return 0


def cmd_file(rel: str, as_json: bool) -> int:
    rel = rel.replace("\\", "/")
    corp = corpus()
    doc = next((d for d in corp if d["rel"].endswith(rel) or rel.endswith(d["rel"])), None)
    if not doc:
        print("not in corpus: %s" % rel, file=sys.stderr)
        return 2
    reg = registry()
    low = doc["text"].lower()
    found = []
    for t, m in reg.items():
        for kind, s in surfaces(t, m):
            if s.lower() in low and _pat(s).search(doc["text"]):
                found.append({"token": t, "surface": kind,
                              "named": (kind == "display") or (kind == "literal" and "_" in t)})
                break
    found.sort(key=lambda r: (not r["named"], r["token"]))
    if as_json:
        print(json.dumps({"file": doc["rel"], "artifacts": found}, ensure_ascii=False, indent=1))
        return 0
    print("%s names %d artifacts (%d strongly)" %
          (doc["rel"], len(found), sum(1 for r in found if r["named"])))
    for r in found[:60]:
        print("   %-42s %-8s %s" % (r["token"], r["surface"], "" if r["named"] else "(quarantined)"))
    return 0


def cmd_silent(as_json: bool) -> int:
    reg = registry()
    booktok = {l["token"] for l in book_lines() if l["token"]}
    big = "\n".join(d["text"] for d in corpus()).lower()
    named = set(UNDERSCORED.findall(big)) & set(reg)
    quiet = sorted(t for t in reg if t not in named and t not in booktok)
    if as_json:
        print(json.dumps({"n": len(quiet), "of": len(reg), "tokens": quiet}, ensure_ascii=False, indent=1))
        return 0
    print("SILENT — %d of %d works have no book line and are named nowhere in prose" % (len(quiet), len(reg)))
    print("  A work nobody has walked has no citation to make. This is a list, not a failure —")
    print("  and a list is a different kind of silence from a blank.")
    for t in quiet[:40]:
        print("   %s" % t)
    if len(quiet) > 40:
        print("   ... and %d more" % (len(quiet) - 40))
    return 0


def cmd_token(tok: str, as_json: bool) -> int:
    reg = registry()
    meta = reg.get(tok)
    if meta is None:
        if as_json:
            print(json.dumps({"token": tok, "error": "no such work in the registry"}))
        else:
            print("NO SUCH WORK — %s is in no registry artifacts dict" % tok)
        return 1
    place = placements()
    hits = find(tok, meta, corpus(), place.get(tok, set()), set(reg))
    bl = [l for l in book_lines() if l["token"] == tok]
    out = {"token": tok, "name": meta.get("name", ""),
           "placed_in": sorted(place.get(tok, set())),
           "book": [{"chapter": l["chapter"], "pearl": l["pearl"], "map": l["map"],
                     "pi": l["pi"], "li": l["li"], "text": l["text"], "note": l["note"],
                     "note_src": l["note_src"]} for l in bl],
           "named": hits["named"], "placed": hits["placed"],
           "roster_n": len(hits["roster"]), "loose_n": len(hits["loose"])}
    if as_json:
        print(json.dumps(out, ensure_ascii=False, indent=1))
        return 0
    print("%s  (%s)" % (tok, meta.get("name", "")))
    print("  stands in %d map(s) · %d book line(s)" % (len(out["placed_in"]), len(bl)))
    for l in bl:
        print("  BOOK  %s / %s" % (l["chapter"], l["pearl"]))
        if l["note_src"]:
            print("        anchored -> %s" % l["note_src"].get("file", ""))
        elif l["note"]:
            print("        A REFLECTION WITH NO ANCHOR — this is the one to ground")
    print("  named in %d passage(s) · %d placed-tier · %d roster · %d loose (both folded)" %
          (len(hits["named"]), len(hits["placed"]), len(hits["roster"]), len(hits["loose"])))
    for r in hits["named"][:25]:
        print("   %-54s para %-3d %s" % (r["file"], r["para"], "[own room]" if r["own"] else ""))
        print("        %s" % r["excerpt"][:150])
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description="where in the text does this artifact appear")
    ap.add_argument("--token", default="")
    ap.add_argument("--file", default="")
    ap.add_argument("--wants", action="store_true",
                    help="the two gaps: a work with no words, a line with no work")
    ap.add_argument("--silent", action="store_true", help="works nobody has written about")
    ap.add_argument("--stats", action="store_true")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()
    if a.stats:
        return cmd_stats()
    if a.wants:
        return cmd_wants(a.json)
    if a.file:
        return cmd_file(a.file, a.json)
    if a.silent:
        return cmd_silent(a.json)
    if a.token:
        return cmd_token(a.token, a.json)
    ap.print_help()
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
