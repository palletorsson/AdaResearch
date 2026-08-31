#!/usr/bin/env python3
"""ARTIFACT TAGS IN final.md — the reader, and the parity check against the editor.

    python tools/final_tags.py                      # every tagged final.md
    python tools/final_tags.py --map=Point_One      # one map's regions
    python tools/final_tags.py --json
    python tools/final_tags.py --check              # grammar + cross-implementation parity

2026-08-31. `/compose` writes artifact tags into `commons/maps/<map>/final.md` as
line-anchored HTML comments:

    <!-- @coordinate_system_3m -->
    the prose that is about that work

    <!-- @ -->
    prose about no work

A marker alone on its line OPENS a region; the region runs to the next marker or
the end of the file. Text before the first marker is untagged. The grammar and
the reasoning behind it are written out in
`ada_encyclopedia/src/lib/artifact-tags.ts` — this file is the same grammar on
the Python side, because a tag only one program can read is not a tag, it is a
private convention inside a React component.

WHY --check EXISTS. Two implementations of one rule drift. That has already cost
this project a session once: `long_museum.py` re-derived the museum's geometry
in Python and gave every hall the wrong height for weeks, with its own --check
green because it compared the strip against its own input. So --check does not
test this file against itself. It runs the SAME fixtures through the TypeScript
parser via `npx tsx` and compares, and if it cannot run the TypeScript it exits
2 — "not compared" is a distinct outcome from "agrees", and it is loud.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
MAPS = REPO / "commons" / "maps"
TS_LIB = REPO.parent / "ada_encyclopedia" / "src" / "lib" / "artifact-tags.ts"

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

MARKER = re.compile(r"^[ \t]*<!--[ \t]*@([a-z0-9_]*)[ \t]*-->[ \t]*$")


def marker(token: str) -> str:
    return "<!-- @" + token + " -->" if token else "<!-- @ -->"


def parse(src: str) -> list[dict]:
    """The file as regions, in order. Always at least one block."""
    out: list[dict] = []
    token, buf = "", []

    def flush() -> None:
        text = "\n".join(buf).lstrip("\n").rstrip()
        if not out and not token and not text:
            return          # empty leading region of a file that opens with a marker
        out.append({"token": token, "text": text})

    for line in str(src or "").split("\n"):
        m = MARKER.match(line)
        if m:
            flush()
            token, buf = m.group(1), []
        else:
            buf.append(line)
    flush()
    return out or [{"token": "", "text": ""}]


def serialize(blocks: list[dict]) -> str:
    parts = []
    for i, b in enumerate(blocks):
        text = str(b.get("text") or "").rstrip()
        if i == 0 and not b.get("token"):
            if text:
                parts.append(text)
            continue
        parts.append(marker(str(b.get("token") or "")) + "\n\n" + text)
    return ("\n\n".join(parts) + "\n") if parts else ""


def tokens_of(blocks: list[dict]) -> list[str]:
    seen, out = set(), []
    for b in blocks:
        t = b.get("token")
        if t and t not in seen:
            seen.add(t)
            out.append(t)
    return out


def finals() -> list[tuple[str, str]]:
    """(map, text) for every final.md on disk."""
    rows = []
    for p in sorted(MAPS.glob("*/final.md")):
        rows.append((p.parent.name, p.read_text(encoding="utf-8")))
    return rows


# ---------------------------------------------------------------- fixtures

# Deliberately awkward. Each one is a way the grammar could be got wrong, and
# every one of them is a shape a hand-edited file will actually take.
FIXTURES = [
    "",                                                     # nothing
    "just prose, never tagged\n",                           # the untouched file
    "<!-- @a_token -->\nfirst line\nsecond line\n",          # opens with a marker
    "lead-in\n\n<!-- @a_token -->\n\nbody\n",                # untagged head, then tagged
    "<!-- @a -->\nA\n\n<!-- @b -->\nB\n\n<!-- @ -->\nloose\n",  # the empty marker
    "<!-- @a -->\n\n\n\nA\n\n\n",                            # blank runs around the text
    "  <!-- @a -->  \nA\n",                                  # leading/trailing space on the marker
    "<!-- @a -->\n<!-- @b -->\nB\n",                         # an empty region between markers
    "text with <!-- @inline --> in the middle of a line\n",  # NOT a marker: not alone on its line
    "<!-- from critical.md -->\nA\n",                        # /studio's provenance comment is not a tag
    "<!-- @A_Token -->\nA\n",                                # uppercase is not a token: not a marker
    "A\n\n<!-- @x -->\n\nB\n\n<!-- @x -->\n\nC\n",           # the same token twice
]


def check() -> int:
    bad = 0

    def fail(what: str, detail: str) -> None:
        nonlocal bad
        bad += 1
        print("  FAIL  %s" % what)
        for line in detail.split("\n"):
            print("        %s" % line)

    # 1. the property that matters: parse is a fixed point of the round trip.
    #    parse(serialize(x)) == x for every x that parse itself produced.
    for i, src in enumerate(FIXTURES):
        once = parse(src)
        twice = parse(serialize(once))
        if once != twice:
            fail("round trip #%d" % i,
                 "in   : %r\nonce : %s\ntwice: %s" % (src, json.dumps(once), json.dumps(twice)))

    # 2. the two negative fixtures must really be negative — a rule that never
    #    fires cannot be told from a rule that is not there.
    if parse(FIXTURES[8]) != [{"token": "", "text": FIXTURES[8].rstrip()}]:
        fail("inline comment", "an <!-- @x --> inside a line opened a region")
    if tokens_of(parse(FIXTURES[9])):
        fail("provenance comment", "<!-- from critical.md --> was read as a tag")
    if tokens_of(parse(FIXTURES[10])):
        fail("uppercase token", "<!-- @A_Token --> was read as a tag")

    # 3. an untagged document must be written back byte-identical, or /compose
    #    would rewrite 215 files the first time anyone opened them
    plain = "just prose, never tagged\n"
    if serialize(parse(plain)) != plain:
        fail("plain passthrough", "%r -> %r" % (plain, serialize(parse(plain))))

    print("  %d fixture(s), %d grammar failure(s)" % (len(FIXTURES), bad))

    # 4. THE PARITY. The same fixtures through the editor's own parser.
    if not TS_LIB.exists():
        print("  NOT COMPARED — no %s" % TS_LIB)
        return 2
    site = TS_LIB.parent.parent.parent                      # ada_encyclopedia/
    tsx = site / "node_modules" / ".bin" / ("tsx.cmd" if sys.platform == "win32" else "tsx")
    if not tsx.exists():
        print("  NOT COMPARED — no %s (npm install in ada_encyclopedia)" % tsx)
        return 2
    runner = ("import {parse, serialize} from " + json.dumps(TS_LIB.as_posix()) + ";\n"
              "import {readFileSync} from 'fs';\n"
              "const F = JSON.parse(readFileSync(process.argv[2], 'utf-8'));\n"
              "console.log(JSON.stringify(F.map((s:string) => "
              "({p: parse(s), s: serialize(parse(s))}))));\n")
    with tempfile.TemporaryDirectory() as td:
        f = Path(td) / "parity.ts"
        f.write_text(runner, encoding="utf-8")
        fx = Path(td) / "fixtures.json"
        fx.write_text(json.dumps(FIXTURES), encoding="utf-8")
        try:
            r = subprocess.run([str(tsx), str(f), str(fx)],
                               capture_output=True, text=True, timeout=180, cwd=str(site))
        except Exception as e:                                  # noqa: BLE001
            print("  NOT COMPARED — could not run tsx: %s" % e)
            return 2
    if r.returncode != 0 or not r.stdout.strip():
        print("  NOT COMPARED — tsx exited %d" % r.returncode)
        print((r.stderr or "").strip()[:800])
        return 2
    try:
        ts = json.loads(r.stdout.strip().split("\n")[-1])
    except Exception as e:                                      # noqa: BLE001
        print("  NOT COMPARED — unreadable tsx output: %s" % e)
        return 2

    drift = 0
    for i, src in enumerate(FIXTURES):
        if ts[i]["p"] != parse(src):
            drift += 1
            print("  DRIFT #%d parse   py=%s ts=%s" % (i, json.dumps(parse(src)), json.dumps(ts[i]["p"])))
        if ts[i]["s"] != serialize(parse(src)):
            drift += 1
            print("  DRIFT #%d write   py=%r ts=%r" % (i, serialize(parse(src)), ts[i]["s"]))
    print("  parity: %d fixture(s) through both parsers, %d disagreement(s)" % (len(FIXTURES), drift))
    return 1 if (bad or drift) else 0


def main() -> int:
    ap = argparse.ArgumentParser(description="artifact tags in final.md")
    ap.add_argument("--map", default="", help="one map")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--check", action="store_true", help="grammar + parity with the editor")
    a = ap.parse_args()

    if a.check:
        print("ARTIFACT TAG GRAMMAR")
        return check()

    rows = finals()
    if a.map:
        rows = [r for r in rows if r[0] == a.map]
        if not rows:
            print("no commons/maps/%s/final.md" % a.map, file=sys.stderr)
            return 2

    docs = [{"map": m, "blocks": parse(t), "tokens": tokens_of(parse(t))} for m, t in rows]
    tagged = [d for d in docs if d["tokens"]]

    if a.json:
        print(json.dumps({"finals": len(docs), "tagged": len(tagged), "docs": docs},
                         ensure_ascii=False, indent=1))
        return 0

    print("final.md — %d file(s), %d carrying artifact tags" % (len(docs), len(tagged)))
    if not docs:
        print()
        print("  Nothing has been written yet. /compose writes them.")
        return 0
    print()
    for d in docs:
        n = sum(1 for b in d["blocks"] if b["token"])
        print("  %-34s %2d region(s), %2d tagged, %d work(s)"
              % (d["map"], len(d["blocks"]), n, len(d["tokens"])))
        if a.map:
            for b in d["blocks"]:
                head = b["text"].split("\n")[0][:64]
                print("      %-28s %s" % (b["token"] or "—", head))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
