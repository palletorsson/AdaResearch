#!/usr/bin/env python3
"""check_loop_doc.py — the reader's checklist, applied to the document that
contains it.

doc/MUSEUM_LOOP.md tells a reader to find every place an artifact's DECLARATIONS
disagree with its RUNNING CODE. The document is an artifact by that definition:
it quotes counts, line numbers and tool behaviour. On 2026-09-03 it drifted three
times in one day, twice from the same session's own commits — a probe count that
went stale because two probes were added hours after it was written, and a line
reference that moved 99 lines because a function was inserted above it.

So this is the checker rather than a promise to be careful. It reads each number
OUT OF the document and compares it against a fresh measurement, which is the
only form of this check that can fail honestly: an earlier draft asserted the
measurement instead of the claim, so it went red the moment the corpus moved even
when the document was right.

    python tools/check_loop_doc.py          exit code = disagreements

WHAT IT CANNOT CHECK. The document's STEER is ontological — what IS this subject,
what does the room make thinkable, what is foreclosed — and none of that is
measurable, which is exactly why it is the steer and this is only hygiene. A
green run here means the document is honest. It does not mean it is right.
"""
from __future__ import annotations

import glob
import io
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
sys.path.insert(0, os.path.join(ROOT, "tools"))

DOC_PATH = os.path.join("doc", "MUSEUM_LOOP.md")
DOC = io.open(DOC_PATH, encoding="utf-8").read()


def claimed(pattern: str):
    """The number the DOCUMENT states, or None if it does not state one.

    An alternation can match with the capture group empty - "twenty-two" spelled
    out rather than written as a numeral - which is a claim this checker cannot
    read rather than a claim that is absent. Both come back None and are
    reported as unchecked rather than as agreement.
    """
    m = re.search(pattern, DOC)
    if not m or not m.group(1):
        return None
    return int(m.group(1))


def line_of(path: str, needle: str):
    try:
        t = io.open(path, encoding="utf-8", errors="replace").read()
    except Exception:
        return None
    i = t.find(needle)
    return t[:i].count("\n") + 1 if i >= 0 else None


# ── the measurements ────────────────────────────────────────────────────────
def measure() -> dict:
    import museum_walk as mw

    m = {"probes": len(glob.glob("commons/testing/probe_*.gd"))}

    mh2 = 0
    for p in glob.glob("commons/maps/*/map_data.json"):
        try:
            d = json.load(io.open(p, encoding="utf-8"))
        except Exception:
            continue
        if ((d.get("map_info") or {}).get("dimensions") or {}).get("max_height") == 2:
            mh2 += 1
    m["max_height_2"] = mh2

    authored = json.load(io.open("commons/data/map_authored.json", encoding="utf-8"))
    chapters = [k for k in authored if not k.startswith("_")]
    m["chapters"] = len(chapters)

    live = []
    for sid in chapters:
        f = os.path.join("commons/maps/sequences", sid + ".json")
        if not os.path.exists(f):
            continue
        d = json.load(io.open(f, encoding="utf-8"))
        s = d["sequences"].get(sid) if isinstance(d.get("sequences"), dict) else d
        if isinstance(s, dict):
            live += s.get("maps", [])
    entry = exits = walks = pinch = door = nodoor = 0
    for name in sorted(set(live)):
        f = os.path.join("commons/maps", name, "map_data.json")
        if not os.path.exists(f):
            continue
        d = json.load(io.open(f, encoding="utf-8"))
        st = (d.get("layers") or {}).get("structure") or []
        if not st:
            continue
        e, x = mw.museum_doors(st)
        entry += 1 if e else 0
        exits += 1 if x else 0
        ev = mw.evaluate(d)
        if ev.get("error"):
            continue
        walks += 1 if ev["walks"] else 0
        pinch += ev["cut_where"] == "interior"
        door += ev["cut_where"] == "door"
        nodoor += ev["cut_where"] == "no door"
    m.update(entry=entry, exits=exits, walks=walks,
             pinch=pinch, door=door, nodoor=nodoor)

    toks = set()
    for p in glob.glob("commons/artifacts/registry/*.json"):
        try:
            d = json.load(io.open(p, encoding="utf-8"))
        except Exception:
            continue
        for k in (d.get("artifacts", d) or {}):
            if re.match(r"^(example|exercise)_\d+_\d+", str(k)):
                toks.add(k)
    m["noc_tokens"] = len(toks)
    return m


#: (label, regex pulling the doc's own number, key into the measurement)
#:
#: ONLY claims the document actually makes. An earlier draft of this list
#: carried rows for numbers that live in the blog posts and not here, and they
#: reported "the doc states no number" and counted as agreement — a vacuous
#: green, which is precisely the failure this checker exists to catch. A claim
#: the regex cannot find is now a FAILURE, not a pass, because the two causes
#: are indistinguishable from here: the sentence moved, or it was never there.
NUMBERS = [
    ("probe_*.gd files", r"\*\*(\d+) files matching", "probes"),
    ("halls that walk, in the protocol", r"\*\*(\d+) walk row 0 to row H-1\*\*", "walks"),
    ("halls that walk, in the rationale", r"entirely\. (\d+) of\s*\n185 halls walk", "walks"),
    ("interior pinches", r"(\d+) are narrower than their own doorways", "pinch"),
    ("Nature of Code tokens", r"corpus admits it by name: (\d+)", "noc_tokens"),
]

#: Stated in WORDS rather than numerals and therefore unreadable from here.
#: Listed so their absence is deliberate rather than an oversight:
#:   "the spine here runs twenty-two"
#: The blog posts carry numbers too and NOTHING checks those.

#: (label, file, the code the doc quotes, the line the doc claims)
LINES = [
    ("walk_evaluator's discard", "tools/walk_evaluator.py",
     "existing_placements(map_data, room)", r"walk_evaluator\.py` \| .*?`:(\d+)`"),
    ("endless_museum UTIL_ALLOWED", "commons/scenes/endless_museum.gd",
     "UTIL_ALLOWED", r"endless_museum\.gd:(\d+)"),
]


def main() -> int:
    m = measure()
    ok, bad = [], []

    for label, pat, key in NUMBERS:
        said = claimed(pat)
        got = m[key]
        if said is None:
            bad.append((label, "CANNOT FIND this claim in the document. The "
                               "sentence moved, or it was never there. Measured %d."
                               % got))
        elif said == got:
            ok.append((label, "%d, agrees" % got))
        else:
            bad.append((label, "the doc says %d, measured %d" % (said, got)))

    for label, path, needle, pat in LINES:
        said = claimed(pat)
        got = line_of(path, needle)
        if got is None:
            bad.append((label, "the quoted code is GONE from %s" % os.path.basename(path)))
        elif said is None:
            ok.append((label, "no line claimed; code is at %d" % got))
        elif abs(said - got) <= 3:
            ok.append((label, "line %d, agrees" % got))
        else:
            bad.append((label, "the doc says line %d, code is at %d" % (said, got)))

    rows = [l for l in DOC.split("\n")
            if l.startswith("| `tools/") or l.startswith("| `commons/testing/")]
    with_status = [l for l in rows
                   if any(k in l for k in ("READY", "LIMITED", "BROKEN", "TO BUILD"))]
    if len(rows) == len(with_status):
        ok.append(("every toolchain row carries a status", "%d of %d" % (len(rows), len(rows))))
    else:
        bad.append(("every toolchain row carries a status",
                    "only %d of %d — the preamble says every one does"
                    % (len(with_status), len(rows))))

    print("doc/MUSEUM_LOOP.md, checked against the code it describes\n")
    for a, b in ok:
        print("  ok   %-38s %s" % (a[:38], b))
    if bad:
        print("")
        for a, b in bad:
            print("  XX   %-38s %s" % (a[:38], b))
    print("\n  %d agree, %d disagree" % (len(ok), len(bad)))
    print("\n  HYGIENE ONLY. The steer is ontological and no tool can check it.")
    return len(bad)


if __name__ == "__main__":
    sys.exit(main())
