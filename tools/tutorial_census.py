#!/usr/bin/env python3
"""WHAT ALGORITHM DOES EACH TUTORIAL TEACH, AND IS IT THE ROOM'S OWN?

    python tools/tutorial_census.py             # the census
    python tools/tutorial_census.py --lexicon   # the words it is looking for
    python tools/tutorial_census.py --map=Point_Lines
    python tools/tutorial_census.py --json

2026-08-31, Palle: "they are ... an account of what algorithms the artifacts and
maps are made of. Obviously there are a lot of algorithms used that are not the
main focus of that artifact, data structures, vectors, sine, xr grab etc. what
are the algorithms described in the tutorials. And do they match the maps?"

TWO QUESTIONS, AND THE SECOND IS THE ONE WITH A NUMBER IN IT.

  ABOUT    a hall belongs to a chapter — one of the spine's 22 — and that is what
           the room is FOR. Does its tutorial speak that chapter's vocabulary at
           all? A lesson in a fractals hall that never says fractal, self-similar
           or recursion is teaching something, but not the room.

  MADE OF  which OTHER chapters' vocabularies the lesson reaches for. This is
           Palle's own point: a hall about noise is made of vectors and sine, and
           a tutorial that reaches for them is not off-topic, it is accounting
           for the substrate. Reported separately, never as a fault.

WHERE THE WORDS COME FROM, and what was thrown away. The lexicon is DERIVED from
curriculum_spine.json — each chapter's name, and the distinctive words of its own
qfep_role line. The first version also swept algorithms/<topic>/'s subdirectory
names, which gave randomness 59 terms and formfinding 2 — and the 59 were
artwork names: carousel_cake, homagetothesquare, berninicolumns. Counting with
that measures the lexicon, not the corpus. They are gone.

The remaining lists are still uneven (--lexicon prints every one, and the sizes,
so the unevenness is visible rather than buried). That is tolerable because the
question that matters is per-tutorial and binary — does THIS lesson speak ITS
chapter — which no other chapter's vocabulary size can affect.

AND IT THROWS AWAY ITS OWN USELESS WORDS. The first run reported `change` in 232
of 244 lessons and `graphtheory` in 221 — nearly the whole corpus — which would
have read as "every lesson is made of calculus and graphs". It was measuring
ordinary language: `node`, `edge`, `path`, `rate`, `limit` are in any GDScript
ever written, and `change` is an English word.

A term that appears in most documents cannot discriminate between them, so any
term found in more than COMMON_AT of the tutorials is dropped before counting,
and --lexicon prints what went. This is the idf half of tf-idf, applied to a
hand-built vocabulary, and it is the difference between measuring the corpus and
measuring the word list.

THIS IS A FINDING, NOT A CLAIM. It is a word matcher over prose. It cannot tell a
lesson that teaches recursion without the word from one that never goes near it,
and it will call a passing mention a match. Read it as a place to look.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SPINE = REPO / "commons" / "maps" / "curriculum_spine.json"
BASE = REPO.parent / "ada_encyclopedia" / "public" / "base_layer.json"
MAPS = REPO / "commons" / "maps"

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

# words a role line shares with every other role line, or with ordinary English
STOP = {
    "the", "and", "for", "that", "are", "was", "from", "into", "with", "its",
    "becomes", "become", "as", "of", "a", "an", "is", "in", "on", "to", "by",
    "or", "not", "but", "all", "one", "two", "complete", "foundation", "term",
    "made", "always", "systems", "system", "rules", "rule", "local", "simple",
    "enable", "creates", "define", "defines", "applied", "limits", "substrate",
}

## A term found in more than this share of the tutorials is discarded as unable
## to tell them apart. 0.35 is a judgement call; --lexicon shows what it costs.
COMMON_AT = 0.35

# a handful of cognates the role lines imply but do not spell. Kept SHORT and
# listed here rather than buried, because every one is a judgement call and the
# next reader should be able to argue with it.
COGNATE = {
    "primitives": ["point", "line", "plane", "vertex", "triangle"],
    "transformation": ["matrix", "translate", "scale", "basis"],
    "change": ["rate", "slope", "integral", "limit", "calculus"],
    "forces": ["gravity", "acceleration", "velocity", "mass"],
    "formfinding": ["catenary", "tension", "minimal", "relax", "equilibrium"],
    "wavefunctions": ["sine", "cosine", "frequency", "amplitude", "oscillat", "phase"],
    "randomness": ["random", "randf", "seed", "probability", "dice", "distribution"],
    "noise": ["perlin", "simplex", "octave", "flow field"],
    "cellularautomata": ["neighbour", "neighbor", "generation", "grid of cells"],
    "fractals": ["self-similar", "recursion", "recursive", "koch", "sierpinski", "iterate"],
    "lsystems": ["grammar", "axiom", "turtle", "production", "rewrite"],
    "proceduralgeneration": ["procedural", "wave function collapse", "markov", "seed"],
    "softbodies": ["spring", "damping", "verlet", "deform", "cloth"],
    "isosurfaces": ["marching cubes", "isosurface", "scalar field", "implicit"],
    "boolean_surfaces": ["union", "intersection", "difference", "csg", "subtract"],
    "swarmintelligence": ["boid", "flock", "swarm", "pheromone", "ant"],
    "machinelearning": ["gradient", "weight", "neuron", "train", "loss"],
    "graphtheory": ["node", "edge", "vertex", "adjacency", "path", "traversal"],
    "foundationscrisis": ["incompleteness", "halting", "paradox", "undecidab", "proof"],
    "qfeplaboratory": ["qfep", "free energy", "entropy"],
    "postfoundationscrisis": ["bias", "rhizome", "molecular"],
    "color": ["hue", "saturation", "rgb", "palette", "gradient"],
}


def lexicon() -> dict[str, list[str]]:
    d = json.loads(SPINE.read_text(encoding="utf-8"))
    seq = d.get("spine", {}).get("sequences", [])
    out: dict[str, list[str]] = {}
    for s in seq:
        name = str(s.get("name", ""))
        terms = {name.lower()}
        for part in re.split(r"_", name):
            if len(part) > 3:
                terms.add(part.lower())
        for w in re.findall(r"[A-Za-zÀ-ÿ][A-Za-zÀ-ÿ'\-]{3,}", str(s.get("qfep_role", ""))):
            wl = w.lower()
            if wl not in STOP:
                terms.add(wl)
        terms.update(COGNATE.get(name, []))
        out[name] = sorted(terms)
    return out


def chapters() -> dict[str, str]:
    """map name -> chapter, from the book's own account of the museum."""
    out: dict[str, str] = {}
    try:
        d = json.loads(BASE.read_text(encoding="utf-8"))
    except Exception:
        return out
    for c in d.get("chapters", []):
        for h in c.get("halls", []):
            if h.get("map"):
                out[str(h["map"])] = str(c.get("chapter", ""))
    return out


def winnow(lex: dict[str, list[str]], texts: list[str]) -> tuple[dict, list[tuple[str, str, float]]]:
    """Drop the terms that are in most lessons: they cannot discriminate.

    Returns the trimmed lexicon and what was dropped, so the cost is visible.
    A topic can lose every term — formfinding nearly does — and that is reported
    rather than hidden, because a topic with no discriminating word left is a
    topic this instrument cannot see."""
    n = max(len(texts), 1)
    dropped: list[tuple[str, str, float]] = []
    out: dict[str, list[str]] = {}
    for topic, terms in lex.items():
        keep = []
        for t in terms:
            df = sum(1 for x in texts if t in x) / n
            if df > COMMON_AT:
                dropped.append((topic, t, df))
            else:
                keep.append(t)
        out[topic] = keep
    dropped.sort(key=lambda d: -d[2])
    return out, dropped


def census(lex: dict, chap: dict, only: str = "") -> list[dict]:
    rows = []
    for p in sorted(MAPS.glob("*/tutorial.md")):
        mp = p.parent.name
        if only and mp != only:
            continue
        ch = chap.get(mp, "")
        text = p.read_text(encoding="utf-8", errors="replace").lower()
        spoken = []
        for topic, terms in lex.items():
            hits = [t for t in terms if t in text]
            if hits:
                spoken.append({"topic": topic, "terms": hits[:6], "n": len(hits)})
        spoken.sort(key=lambda s: -s["n"])
        own = next((s for s in spoken if s["topic"] == ch), None)
        rows.append({"map": mp, "chapter": ch, "chars": len(text),
                     "own": own["n"] if own else 0,
                     "own_terms": own["terms"] if own else [],
                     "spoken": [s for s in spoken if s["topic"] != ch]})
    return rows


def main() -> int:
    ap = argparse.ArgumentParser(description="what each tutorial teaches, against its room's chapter")
    ap.add_argument("--map", default="")
    ap.add_argument("--lexicon", action="store_true")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()

    lex = lexicon()
    all_text = [p.read_text(encoding="utf-8", errors="replace").lower()
                for p in sorted(MAPS.glob("*/tutorial.md"))]
    lex, dropped = winnow(lex, all_text)

    if a.lexicon:
        print("THE WORDS THIS LOOKS FOR — derived from curriculum_spine.json plus")
        print("the cognate lists in this file, which are judgement calls and are")
        print("printed so they can be argued with.")
        print()
        for n, t in lex.items():
            print("  %-22s %2d  %s" % (n, len(t), ", ".join(t) if t else "— NOTHING LEFT, this instrument cannot see this topic"))
        print()
        print("  DISCARDED — in more than %.0f%% of the lessons, so unable to tell them apart:" % (COMMON_AT * 100))
        for topic, t, df in dropped:
            print("    %-22s %-18s %.0f%% of lessons" % (topic, t, df * 100))
        return 0

    chap = chapters()
    rows = census(lex, chap, a.map)
    if not rows:
        print("no tutorial for %s" % (a.map or "any map"), file=sys.stderr)
        return 2

    known = [r for r in rows if r["chapter"]]
    match = [r for r in known if r["own"] > 0]

    if a.json:
        print(json.dumps({"tutorials": len(rows), "placed_in_a_chapter": len(known),
                          "speak_their_own": len(match), "rows": rows},
                         ensure_ascii=False, indent=1))
        return 0

    if a.map:
        r = rows[0]
        print("%s — chapter %s, %d characters" % (r["map"], r["chapter"] or "(none)", r["chars"]))
        print()
        print("  ABOUT    its own chapter: %s" % (
            "%d term(s) — %s" % (r["own"], ", ".join(r["own_terms"])) if r["own"] else "SILENT"))
        print("  MADE OF  the substrates it reaches for:")
        for s in r["spoken"][:8]:
            print("    %-22s %2d  %s" % (s["topic"], s["n"], ", ".join(s["terms"])))
        if not r["spoken"]:
            print("    (none)")
        return 0

    print("THE TUTORIAL AND THE ALGORITHM — %d tutorial(s)" % len(rows))
    print()
    print("  in a chapter the book knows   : %d" % len(known))
    print("  SPEAKING their own chapter    : %d  (%.0f%%)" % (len(match), 100.0 * len(match) / max(len(known), 1)))
    print("  silent on it                  : %d" % (len(known) - len(match)))
    print()

    # which substrates the corpus reaches for, across every lesson
    sub: dict[str, int] = {}
    for r in rows:
        for s in r["spoken"]:
            sub[s["topic"]] = sub.get(s["topic"], 0) + 1
    blind = [t for t, v in lex.items() if not v]
    if blind:
        print("  NOT VISIBLE to this instrument — every term too common to discriminate:")
        print("    %s" % ", ".join(blind))
        print()
    print("  THE SUBSTRATE — chapters other lessons reach for, and how many do.")
    print("  A topic in most of the corpus is not a substrate, it is the language:")
    for t, n in sorted(sub.items(), key=lambda kv: -kv[1])[:12]:
        share = n / max(len(rows), 1)
        mark = "  <- everywhere; says more about GDScript than about the lesson" if share > 0.5 else ""
        print("    %-22s %3d of %d  (%2.0f%%)%s" % (t, n, len(rows), share * 100, mark))
    print()
    print("  SILENT ON THEIR OWN CHAPTER — the lesson is not about the room:")
    for r in [r for r in known if r["own"] == 0][:12]:
        loud = r["spoken"][0]["topic"] if r["spoken"] else "nothing"
        print("    %-30s chapter %-20s speaks %s" % (r["map"], r["chapter"], loud))
    print()
    print("  --map=<Name> for one lesson, --lexicon for the words.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
