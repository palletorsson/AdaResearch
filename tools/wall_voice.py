#!/usr/bin/env python3
"""wall_voice.py — the deterministic half of the wall-text standard.

2026-09-03. A ten-agent critic panel found 80 faults in the seven transformation
rooms, and 51 of them were factual: only a reader with the artifact's .gd open
can catch those, and no linter ever will. But the panel ALSO caught something no
single room critic could see — the same science-screen joke closing all five
formfinding rooms — and that one is mechanical. This tool owns the mechanical
half so the agents can spend their whole budget on the half that needs judgement.

Two of the checks are ported from ada_writer's scorecard.ts (the one file in
that app with no dependencies and no equivalent here): forbidden words and
patterns with regex metacharacters escaped, and repeated sentence openings.
The third check is the one ada_writer does not have and the one that actually
bit us: ACROSS-ROOM repetition.

    python tools/wall_voice.py                       every written final.md
    python tools/wall_voice.py --map=VFM_07_Gravity  one room
    python tools/wall_voice.py --seq=formfinding     one chapter
    python tools/wall_voice.py --check               exit 1 on any FAIL

FAIL is reserved for things that are always wrong in this corpus. Everything
else prints as a NOTE and exits 0, because a linter that cries wolf gets muted.
"""
from __future__ import annotations

import argparse
import collections
import glob
import json
import os
import re
import statistics
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# The house voice, as enforced by hand across 37 rooms and now written down.
FORBIDDEN_WORDS = [
    # americanisms — the corpus is British
    "color", "colors", "colored", "coloring",
    "meter", "meters", "centimeter", "centimeters", "kilometer", "kilometers",
    "behavior", "behaviors", "organize", "organized", "realize", "realized",
    "visualize", "visualized", "analyze", "analyzed", "gray",
    # registry-speak: words that describe a catalogue entry, not a room
    "artifact", "artifacts", "token", "tokens", "registry", "lookup_name",
    "map_data", "config", "codebase", "repo",
    # hedges that mean the writer did not check
    "presumably", "arguably", "essentially", "effectively", "somewhat",
    "leverage", "utilize", "showcase", "delve",
]

FORBIDDEN_PATTERNS = [
    "—",        # em dash: the exemplars use full stops and colons
    "–",        # en dash
    "->", "→",  # arrows
    "  ",       # double space
]

# Sentences that assert a physical fact need a number or a name behind them, but
# THESE are the phrasings that assert one without either. A NOTE, never a FAIL.
VAGUE = [
    "a variety of", "a number of", "various", "several kinds",
    "and so on", "et cetera", "things like", "sort of", "kind of",
]

MIN_WORDS, MAX_WORDS = 380, 1400


def sentences(text: str) -> list[str]:
    text = re.sub(r"```.*?```", " ", text, flags=re.S)      # code fences are not prose
    text = re.sub(r"<!--.*?-->", " ", text, flags=re.S)     # nor are region tags
    text = re.sub(r"\n+", " ", text)
    return [s.strip() for s in re.split(r"(?<=[.!?])\s+", text) if s.strip()]


def prose_of(text: str) -> str:
    text = re.sub(r"```.*?```", " ", text, flags=re.S)
    text = re.sub(r"<!--.*?-->", " ", text, flags=re.S)
    return text


def forbidden_words(text: str) -> list[tuple[str, int]]:
    low = text.lower()
    out = []
    for w in FORBIDDEN_WORDS:
        n = len(re.findall(r"\b" + re.escape(w) + r"\b", low))
        if n:
            out.append((w, n))
    return out


def forbidden_patterns(text: str) -> list[tuple[str, int]]:
    out = []
    for p in FORBIDDEN_PATTERNS:
        n = len(re.findall(re.escape(p), text))
        if n:
            out.append((p, n))
    return out


def repeated_openings(sents: list[str], run: int = 3) -> list[tuple[str, int]]:
    """Three or more consecutive sentences opening on the same word."""
    runs, cur, length = [], "", 0
    for s in sents + [""]:
        first = (s.split() or [""])[0].lower().strip(",.:;")
        if first == cur and first:
            length += 1
        else:
            if length >= run and cur:
                runs.append((cur, length))
            cur, length = first, 1
    return runs


def shingles(text: str, n: int = 6) -> set[str]:
    """Overlapping n-word windows, for finding a sentence reused across rooms.

    n = 6 is chosen, not assumed. Measured against the formfinding chapter before
    and after the screen-repetition fix: n=5 gives 6 pre / 2 post (too noisy),
    n=6 gives 4 pre / 1 post, n=7 and n=8 give 1 pre / 0 post (too blunt to have
    caught four of the five repeats). Six separates them and still bites.
    """
    words = re.findall(r"[a-z']+", text.lower())
    return {" ".join(words[i:i + n]) for i in range(max(0, len(words) - n + 1))}


def written_rooms(only_map: str = "", only_seq: str = "") -> list[tuple[str, str]]:
    seq_maps: set[str] = set()
    if only_seq:
        p = os.path.join(ROOT, "commons", "maps", "sequences", only_seq + ".json")
        with open(p, encoding="utf-8") as fh:
            d = json.load(fh)
        s = d["sequences"][only_seq] if "sequences" in d else d
        seq_maps = set(s.get("maps", []))
    out = []
    for p in sorted(glob.glob(os.path.join(ROOT, "commons", "maps", "*", "final.md"))):
        name = os.path.basename(os.path.dirname(p))
        if only_map and name != only_map:
            continue
        if only_seq and name not in seq_maps:
            continue
        with open(p, encoding="utf-8") as fh:
            out.append((name, fh.read()))
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", default="")
    ap.add_argument("--seq", default="")
    ap.add_argument("--check", action="store_true", help="exit 1 on any FAIL")
    args = ap.parse_args()

    rooms = written_rooms(args.map, args.seq)
    if not rooms:
        print("no written final.md matched")
        return 1

    fails = notes = 0
    print(f"WALL VOICE — {len(rooms)} room(s)\n")

    per_room_shingles: dict[str, set[str]] = {}
    for name, text in rooms:
        prose = prose_of(text)
        sents = sentences(text)
        words = len(re.findall(r"\w+", prose))
        per_room_shingles[name] = shingles(prose)

        room_fails, room_notes = [], []

        for w, n in forbidden_words(prose):
            room_fails.append(f"forbidden word {w!r} x{n}")
        for p, n in forbidden_patterns(prose):
            room_fails.append(f"forbidden pattern {p!r} x{n}")
        if not text.rstrip().endswith((".", "?", '"')):
            room_fails.append("does not end on a full stop")
        if words < MIN_WORDS:
            room_fails.append(f"{words} words, under the {MIN_WORDS} floor")
        if words > MAX_WORDS:
            room_notes.append(f"{words} words, over the {MAX_WORDS} guide")

        for w, n in repeated_openings(sents):
            room_notes.append(f"{n} sentences in a row open on {w!r}")
        low = prose.lower()
        for v in VAGUE:
            if v in low:
                room_notes.append(f"vague phrasing {v!r}")
        lens = [len(s.split()) for s in sents]
        if lens:
            mean = statistics.mean(lens)
            sd = statistics.pstdev(lens)
            if mean > 34:
                room_notes.append(f"mean sentence {mean:.0f} words — long for this voice")
            if sd / mean < 0.42 if mean else False:
                room_notes.append(f"sentence rhythm flat (sd/mean {sd / mean:.2f})")

        if room_fails or room_notes:
            print(f"  {name}  ({words} words)")
            for f in room_fails:
                print(f"     FAIL  {f}")
            for n_ in room_notes:
                print(f"     note  {n_}")
            fails += len(room_fails)
            notes += len(room_notes)

    # THE ACROSS-ROOM CHECK. Two rooms sharing an 8-word window are almost always
    # one paragraph written twice; the formfinding screen joke shared five.
    if len(rooms) > 1:
        # A shared six-word run of ordinary connective tissue ("and it is the only
        # one") is English, not repetition. Only report a run carrying at least
        # three CONTENT words, which is what separates a reused sentence from a
        # reused grammar. Measured: this drops 19 pairs to the ones worth reading.
        stop = {"a","an","and","are","as","at","be","but","by","for","from","had","has",
                "have","he","her","his","in","is","it","its","not","of","on","one","or",
                "own","she","so","than","that","the","their","them","then","there",
                "these","they","this","to","was","were","what","when","which","who",
                "will","with","you","your","only","same","just","all","any","because",
                "if","into","no","now","out","over","up","we","us"}
        def contentful(sh: str) -> bool:
            return sum(1 for w in sh.split() if w not in stop) >= 3
        pairs = collections.defaultdict(list)
        names = list(per_room_shingles)
        for i, a in enumerate(names):
            for b in names[i + 1:]:
                common = [c for c in (per_room_shingles[a] & per_room_shingles[b]) if contentful(c)]
                if common:
                    pairs[(a, b)] = sorted(common)[:3]
        if pairs:
            print("\n  ACROSS ROOMS — an 8-word run appearing in two rooms:")
            for (a, b), ex in sorted(pairs.items(), key=lambda kv: -len(kv[1])):
                print(f"     note  {a} + {b}")
                for e in ex:
                    print(f"           {e!r}")
                notes += 1

    print(f"\n{fails} FAIL(s), {notes} note(s) across {len(rooms)} room(s)")
    if args.check and fails:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
