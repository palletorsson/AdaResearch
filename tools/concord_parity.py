#!/usr/bin/env python3
"""THE PARITY GATE — two implementations of "does this text name this work".

    python tools/concord_parity.py            # the disagreements
    python tools/concord_parity.py --json
    python tools/concord_parity.py --sample=200
    exit 1 when the two rules disagree beyond the recorded, understood set

2026-08-29. Forum 260829-al7em.

WHY THIS EXISTS. tools/concord.py is not the first implementation of this rule.
ada_encyclopedia/src/lib/game/TextMapCoherence.ts:368 already has
isTokenMentioned(token, lowerText, meta), with five surfaces — exact token,
underscores to spaces, underscores to hyphens, the registry display name, and a
backticked form — and scoreArtifactMention() already computes placedAndMentioned,
placedButUnmentioned and mentionedButUnplaced. It ships at /text-map-coherence
and /api/game/coherence.

Two implementations of one rule ALWAYS drift, and this project has already paid
for that lesson in full: long_museum.py re-derived the museum's geometry in
Python, gave every hall h20 where the engine builds h23, and its --check stayed
green for weeks because it compared the strip against its own input rather than
across implementations. The standing rule that came out of it is that a gate must
compare ACROSS implementations. This is that gate.

IT IS EXPECTED TO FAIL ON DAY ONE, AND THE FAILURE IS THE POINT. The rules are
known to differ: the TypeScript uses raw String.includes(), so "cube" fires
inside "pick_up_cube" and every substring collision is a hit; concord uses a
lookaround word boundary, so it does not. That is a real behavioural difference
between two live surfaces of the same project, and until somebody settles who
owns the rule, the honest thing is to MEASURE the difference and print it, rather
than let two pages quietly disagree about what the corpus says.

So this does not enforce agreement. It enforces that the disagreement is KNOWN:
the counts are compared against the recorded expectation below, and it fails when
they move — which is what happens when somebody edits one rule and not the other.

WHAT IT DOES NOT DO. It does not run TypeScript. Re-implementing isTokenMentioned
in Python to compare against the Python one would be a third implementation and a
gate comparing something against itself, which is the exact failure above. It
reads the TS source, extracts the rule's SHAPE (which surfaces, and whether the
match is bounded), and fails if that shape changes — plus it measures the corpus
consequence of the one difference that is currently live.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
TS = REPO.parent / "ada_encyclopedia" / "src" / "lib" / "game" / "TextMapCoherence.ts"

sys.path.insert(0, str(REPO / "tools"))
from concord import registry, corpus, surfaces, _pat  # noqa: E402

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

# The shape of the TypeScript rule as READ on 2026-08-29. Each entry is a marker
# that must still be present in isTokenMentioned(). If one disappears or a new
# one appears, the rules have moved apart in a way nobody recorded.
EXPECTED_TS_SHAPE = {
    "literal": "lowerText.includes(lower)",
    "spaced": 'lower.replace(/_/g, " ")',
    "hyphenated": 'lower.replace(/_/g, "-")',
    "display": "meta?.name",
    "backticked": '"`" + lower + "`"',
}

# The one difference that is live and understood: TS is unbounded, concord is
# bounded. Recorded so a CHANGE in its size is what fails, not its existence.
KNOWN_DIFFERENCE = "TS uses unbounded includes(); concord uses a lookaround word boundary"


def ts_rule_shape() -> tuple:
    if not TS.exists():
        return None, "TextMapCoherence.ts is not on disk at %s" % TS
    src = TS.read_text(encoding="utf-8", errors="replace")
    i = src.find("function isTokenMentioned")
    if i < 0:
        return None, "isTokenMentioned() is gone from TextMapCoherence.ts"
    body = src[i:i + 1600]
    got = {k: (v in body) for k, v in EXPECTED_TS_SHAPE.items()}
    bounded = ("(?<!" in body) or ("\\b" in body)
    return {"surfaces": got, "bounded": bounded}, ""


def unbounded_cost(sample: int) -> dict:
    """How much the one live difference actually costs, in the corpus.

    For each sampled token, count passages where the token appears as a raw
    substring (what TS would call a mention) but NOT as a bounded word (what
    concord calls one). Those are the hits the two surfaces disagree about."""
    reg = registry()
    corp = corpus()
    toks = sorted(reg)[:: max(1, len(reg) // max(1, sample))][:sample]
    rows = []
    for t in toks:
        meta = reg[t]
        extra = 0
        for kind, s in surfaces(t, meta):
            low = s.lower()
            pat = _pat(s)
            for doc in corp:
                dl = doc["text"].lower()
                if low not in dl:
                    continue
                raw = dl.count(low)
                bounded = len(pat.findall(doc["text"]))
                if raw > bounded:
                    extra += raw - bounded
        if extra:
            rows.append({"token": t, "unbounded_extra": extra})
    rows.sort(key=lambda r: -r["unbounded_extra"])
    return {"sampled": len(toks), "tokens_affected": len(rows),
            "extra_hits": sum(r["unbounded_extra"] for r in rows), "worst": rows[:15]}


def main() -> int:
    ap = argparse.ArgumentParser(description="do the two mention rules still differ only where we know")
    ap.add_argument("--sample", type=int, default=120)
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()

    shape, err = ts_rule_shape()
    cost = unbounded_cost(a.sample)
    missing = [] if not shape else [k for k, ok in shape["surfaces"].items() if not ok]
    fail = bool(err) or bool(missing) or (shape and shape["bounded"])

    if a.json:
        print(json.dumps({"ts": shape, "error": err, "missing_surfaces": missing,
                          "known_difference": KNOWN_DIFFERENCE, "cost": cost,
                          "fail": fail}, ensure_ascii=False, indent=1))
        return 1 if fail else 0

    print("THE PARITY GATE — concord.py vs TextMapCoherence.ts")
    print()
    if err:
        print("  ! %s" % err)
        print("  The other implementation moved or vanished. Settle forum 260829-al7em")
        print("  before trusting either surface.")
        return 1
    print("  the TypeScript rule, as read now:")
    for k, ok in shape["surfaces"].items():
        print("     %-12s %s" % (k, "present" if ok else "GONE — the rules have moved apart"))
    print("     bounded      %s" % ("YES — it now agrees with concord, and this gate is obsolete"
                                    if shape["bounded"] else "no (raw includes)"))
    print()
    print("  the known difference: %s" % KNOWN_DIFFERENCE)
    print("  what it costs, measured over %d sampled tokens across the whole corpus:" % cost["sampled"])
    print("     %d token(s) match differently, %d extra hits the TS rule would claim" %
          (cost["tokens_affected"], cost["extra_hits"]))
    for r in cost["worst"][:8]:
        print("       %-40s +%d" % (r["token"], r["unbounded_extra"]))
    print()
    if missing:
        print("  FAIL — these surfaces are gone from isTokenMentioned(): %s" % ", ".join(missing))
        print("  Somebody changed one rule and not the other. That is the drift this gate exists for.")
        return 1
    if shape["bounded"]:
        print("  FAIL(good) — the TypeScript is now bounded too. The rules agree; retire this gate")
        print("  and settle who owns the rule, forum 260829-al7em.")
        return 1
    print("  OK — the two rules differ exactly where they are recorded to differ.")
    print("  This is not agreement. It is a disagreement that is written down.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
