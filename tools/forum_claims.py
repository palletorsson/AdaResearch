"""Who said, in writing, that they are holding this file.

WHY THIS EXISTS
---------------
The agent forum is this project's ownership ledger and until today nothing
except forum.py had ever opened it. Measured 2026-09-10: the store is a
tracked 234 KB file holding 66 threads, 57 open, and `git grep -l agent-forum`
across AdaResearch_46 returned exactly one tracked file. No gate, no scorer,
no phase of the breather read it.

The cost was paid three evenings running. Gate L convicts prose a clone of
HEAD would not have and prints it as bare rows. On 2026-09-10 ten of those
rows belonged to two sessions that had said so first -- thread 260910-5zr9o
at 11:14 naming three maps, 260910-8in5c at 13:34 naming two more -- and the
evening breath spent its time reconstructing from mtimes and blob comparisons
an attribution that was already typed into a file, on top of the answer. Gate
L's own remedy line has been telling people to "say in the forum why they
should stay out" the whole time.

WHAT A CLAIM IS, AND WHY THE BROAD VERSION WAS REJECTED
-------------------------------------------------------
The prescription (prop-049 clause 1) was to cross a gate's convicted paths
against open threads and print the intersection. Measured against gate L's
164 rows on 2026-09-11, before any code was written:

    explicit repo paths named in open threads      2 rows of 164
    any mention of the room's name anywhere       40 rows, 24 rooms
    a first-person claim sentence only            19 rows, 10 rooms

The middle number is the trap. Fourteen of those 24 rooms are mentions, not
claims, and reading them proves it: Accumulation_Riemann appears in a handoff
from eight days earlier as a to-do ("fix Accumulation_Riemann blurb"),
Color_Pillar in the breather's own ruling request about .gitignore,
VFM_05_Launch in a list of rooms a loop session had finished. Attributing
stranded prose to those authors would be a fabricated name beside a real
conviction, which is worse than the anonymous row it replaces.

So a claim is one of exactly two things:

  DECLARED   the thread carries a `claims` list -- paths or room names as
             data, written by `forum.py ask --claims=a,b`. Exact, no parsing.
  CLAIMED    a sentence in the thread makes a first-person claim ("I am
             editing X", "X is in your working tree, uncommitted") and the
             name is IN THAT SENTENCE. Names elsewhere in the post do not
             count, which is the whole difference from the broad version.

A CLAIM DOES NOT SUPPRESS A CONVICTION
--------------------------------------
It names who, it does not grant a licence to stop counting. Gate N holds a
24-hour clock and went from 5 convictions to 21 overnight with nothing in
the world changing; a verdict that rides on someone's word is the same fault
wearing a politer face. Every consumer of this module gets a name to print
beside a row, never a row removed.

THE STORE IS IN ANOTHER REPOSITORY
----------------------------------
ada_encyclopedia/public/agent-forum/threads.json, beside this checkout. A
clone of AdaResearch alone does not have it, so every function here answers
emptily and says so rather than raising. A gate must not fail because the
companion repo is absent.

    python tools/forum_claims.py                      what is claimed, by whom
    python tools/forum_claims.py --json
    python tools/forum_claims.py commons/maps/X/final.md ...   attribute paths
    python tools/forum_claims.py --selftest           the reader still bites
"""

from __future__ import annotations

import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STORE = (ROOT.parent / "ada_encyclopedia" / "public" / "agent-forum"
         / "threads.json")

# A first-person claim on work in progress. Deliberately short: every phrase
# here was read in a live thread before being added, and a phrase that has
# never appeared in the forum is a guess about how agents write.
CLAIM = re.compile(
    r"\b(?:"
    r"I am (?:editing|writing|building|revising|rewriting|touching)"
    r"|I have .{0,30}\b(?:open|uncommitted)"
    r"|about to (?:touch|edit|regenerate|rewrite)"
    r"|in (?:your|the|my) working (?:tree|copy)"
    r"|is open in|has .{0,20}open"
    r")\b", re.I)

# Room and artifact names: CamelCase or Snake_Case with at least one
# underscore, which is what every map directory in the corpus looks like.
NAME = re.compile(r"\b[A-Za-z][A-Za-z0-9]*(?:_[A-Za-z0-9]+)+\b")

# A repo-relative path, so a thread that names the file exactly is read
# exactly. The prefixes are the top-level directories a claim has ever named.
PATH = re.compile(
    r"(?:commons|tools|algorithms|addons|doc|ada_run|scripts)"
    r"/[A-Za-z0-9_./\-]+")

# Sentence split on sentence-ending punctuation ONLY. Not the colon: the
# claim that reads "Two placements are in your working tree, uncommitted:
# Color_Context_Placed (30,5) and Primitives_Melencolia (24,9)" puts its
# names after the colon, and splitting there loses both.
SENTENCE = re.compile(r"(?<=[.;\n])\s+")


def load(store: Path | None = None) -> list:
    """Every thread in the store, or [] if the companion repo is absent.

    Reads the FILE, never the dev server: a gate runs with npm down.
    """
    path = Path(store) if store else STORE
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError):
        return []
    return data if isinstance(data, list) else []


def units(thread: dict):
    """(author, at, text) for the opening post and for each reply.

    Separately, because a reply's claim belongs to the replier. Three of the
    threads read on 2026-09-11 carry a claim in a reply by a different agent
    from the one who opened the thread.
    """
    yield (thread.get("author"), thread.get("at"),
           "%s. %s" % (thread.get("title") or "", thread.get("body") or ""))
    for reply in thread.get("replies") or []:
        if isinstance(reply, dict):
            yield reply.get("author"), reply.get("at"), reply.get("body") or ""


def claims(threads: list, open_only: bool = True) -> dict:
    """-> {name or path: [claim dict, ...]}

    Pure, so the selftest feeds it threads instead of a store. Keys are both
    room names and repo paths; `attribute` resolves a path through either.
    """
    out: dict[str, list] = {}
    for thread in threads:
        if not isinstance(thread, dict):
            continue
        if open_only and thread.get("status") != "open":
            continue
        tid = thread.get("id")

        # DECLARED: data, not prose. A reply's `claims` belong to the replier,
        # which is why the opening post and the replies are walked separately
        # here as well -- a thread is often opened by one session and claimed
        # by another three messages later.
        posts = [(thread.get("author"), thread.get("at"), thread.get("claims"))]
        posts += [(r.get("author"), r.get("at"), r.get("claims"))
                  for r in thread.get("replies") or [] if isinstance(r, dict)]
        for author, at, declared in posts:
            if not isinstance(declared, list):
                continue
            for item in declared:
                if isinstance(item, str) and item.strip():
                    out.setdefault(item.strip().replace("\\", "/"), []).append({
                        "thread": tid, "author": author, "at": at,
                        "how": "declared", "sentence": None,
                    })

        # CLAIMED: a first-person sentence, names from that sentence only.
        for author, at, text in units(thread):
            for sentence in SENTENCE.split(text):
                if not CLAIM.search(sentence):
                    continue
                found = set(PATH.findall(sentence))
                found |= {n for n in NAME.findall(sentence)
                          if not any(n in p for p in found)}
                for item in found:
                    out.setdefault(item.rstrip(".,;").replace("\\", "/"), []
                                   ).append({
                        "thread": tid, "author": author, "at": at,
                        "how": "claimed",
                        "sentence": " ".join(sentence.split())[:200],
                    })
    return out


def attribute(paths, claimed: dict) -> dict:
    """-> {path: [claim dict, ...]} for the paths someone has claimed.

    A path matches on the path itself or on the name of the directory it
    sits in, because a heads-up names the ROOM ("I am editing
    WaveFunctions_AirMusic") and the gate convicts the file inside it.
    Paths nobody claimed are absent, not present-and-empty: a caller that
    iterates the result gets only the named group.
    """
    hits = {}
    for raw in paths:
        rel = str(raw).replace("\\", "/")
        found = list(claimed.get(rel, []))
        room = os.path.basename(os.path.dirname(rel))
        if room:
            for claim in claimed.get(room, []):
                if claim not in found:
                    found.append(claim)
        if found:
            hits[rel] = found
    return hits


def age_days(at, now=None) -> float | None:
    """How old the claim is, in days. None if the stamp is unreadable.

    Reported, never acted on -- the same line gate L draws on mtimes. A claim
    from this morning and one from 2026-08-31 are both open threads and both
    true statements about what was said; only the reader can judge which still
    has hands on the file. The oldest live claim in the store on 2026-09-11 was
    eleven days old and still the right thing to print.
    """
    try:
        stamp = str(at).replace("Z", "+00:00")
        then = datetime.fromisoformat(stamp)
    except (TypeError, ValueError):
        return None
    if then.tzinfo is None:
        then = then.replace(tzinfo=timezone.utc)
    moment = now or datetime.now(timezone.utc)
    return round((moment - then).total_seconds() / 86400.0, 1)


def who(found: list, now=None) -> str:
    """The authors of a list of claims, in thread order, as one string.

    "said by", not "owned by". Half the claims in the store are second-person
    reports -- "four tokens are in YOUR working copy" -- so the author is who
    wrote it down, and the thread says who is holding the file. The age is
    here because an open thread is not evidence that anyone still is.
    """
    seen = []
    for claim in found:
        days = age_days(claim.get("at"), now)
        label = "%s (%s%s)" % (claim.get("author") or "?", claim.get("thread"),
                               ", %gd" % days if days is not None else "")
        if label not in seen:
            seen.append(label)
    return ", ".join(seen)


def summarise(hits: dict) -> dict:
    """The shape a gate puts in its JSON: counts plus one row per path."""
    authors: dict[str, list] = {}
    for rel, found in hits.items():
        for claim in found:
            authors.setdefault(claim.get("author") or "?", []).append(rel)
    return {
        "store_present": STORE.exists(),
        "claimed_paths": len(hits),
        "claimed_by": {a: sorted(set(v)) for a, v in sorted(authors.items())},
        "claims": {rel: who(found) for rel, found in sorted(hits.items())},
    }


def selftest() -> int:
    """The reader accepts a claim, a declaration and a reply -- and refuses
    a mention, which is the only reason it exists in this form.
    """
    threads = [
        {   # the shape five Fable heads-ups took on 2026-09-10/11
            "id": "t-claim", "author": "fable-w3", "status": "open",
            "at": "2026-09-11T06:12:00Z",
            "title": "Fable W3: I am editing WaveFunctions_AirMusic (map, docs)",
            "body": "Heads-up for the wave sessions.", "replies": [],
        },
        {   # the shape a handoff took: a name as a TO-DO, eight days old
            "id": "t-mention", "author": "claude-room-writer", "status": "open",
            "at": "2026-09-03T11:15:00Z",
            "title": "Handoff: eight findings",
            "body": "Keep it as the chosen disagreement; fix "
                    "Accumulation_Riemann blurb + tutorial.",
            "replies": [],
        },
        {   # names after a colon, in the same sentence as the claim
            "id": "t-colon", "author": "claude-opus-artifacts", "status": "open",
            "at": "2026-09-09T13:05:00Z",
            "title": "Two placements",
            "body": "Two placements are in your working tree, uncommitted: "
                    "Color_Context_Placed (30,5) and Primitives_Melencolia.",
            "replies": [],
        },
        {   # a claim in a REPLY belongs to the replier, not the opener
            "id": "t-reply", "author": "asker", "status": "open",
            "at": "2026-09-01T10:00:00Z", "title": "Who owns the strip?",
            "body": "Asking before I regenerate.",
            "replies": [{"author": "late-session", "at": "2026-09-02T10:00:00Z",
                         "body": "I am editing Strip_Room right now."}],
        },
        {   # paths as data beat any amount of parsing
            "id": "t-declared", "author": "tidy-session", "status": "open",
            "at": "2026-09-11T08:00:00Z", "title": "Declared",
            "body": "No names in this prose at all.",
            "claims": ["commons/maps/Declared_Room/final.md"],
            "replies": [{"author": "second-session", "at": "2026-09-11T08:30:00Z",
                         "body": "Taking the other one.",
                         "claims": ["commons/maps/Reply_Room/final.md"]}],
        },
        {   # settled threads are history, not a live hand
            "id": "t-closed", "author": "old-session", "status": "answered",
            "at": "2026-08-01T10:00:00Z",
            "title": "I am editing Closed_Room", "body": "", "replies": [],
        },
    ]
    got = claims(threads)

    if "WaveFunctions_AirMusic" not in got:
        print("SELFTEST FAIL: a first-person claim in a title was not read.")
        return 1
    if "Accumulation_Riemann" in got:
        print("SELFTEST FAIL: a room named as a TO-DO was read as a claim -- "
              "this is the broad version the measurement rejected.")
        return 1
    if "Color_Context_Placed" not in got or "Primitives_Melencolia" not in got:
        print("SELFTEST FAIL: names after a colon were lost; the sentence "
              "split is eating the claim it is supposed to scope.")
        return 1
    if not got.get("Strip_Room") or got["Strip_Room"][0]["author"] != "late-session":
        print("SELFTEST FAIL: a claim in a reply was attributed to the "
              "thread's author: %s" % got.get("Strip_Room"))
        return 1
    declared = got.get("commons/maps/Declared_Room/final.md") or []
    if not declared or declared[0]["how"] != "declared":
        print("SELFTEST FAIL: a `claims` list was not read as data.")
        return 1
    reply_claim = got.get("commons/maps/Reply_Room/final.md") or []
    if not reply_claim or reply_claim[0]["author"] != "second-session":
        print("SELFTEST FAIL: a declared claim in a REPLY was lost or "
              "credited to the thread's author: %s" % reply_claim)
        return 1
    if "Closed_Room" in got:
        print("SELFTEST FAIL: a settled thread was read as a live claim.")
        return 1

    # The gate's own question: a convicted file inside a claimed room.
    hits = attribute([
        "commons/maps/WaveFunctions_AirMusic/final.md",   # claimed room
        "commons/maps/Declared_Room/final.md",            # declared path
        "commons/maps/Accumulation_Riemann/final.md",     # mentioned only
        "commons/maps/Nobody_Said/final.md",              # never named
    ], got)
    if sorted(hits) != ["commons/maps/Declared_Room/final.md",
                        "commons/maps/WaveFunctions_AirMusic/final.md"]:
        print("SELFTEST FAIL: attribution gave %s" % sorted(hits))
        return 1
    now = datetime(2026, 9, 11, 9, 0, tzinfo=timezone.utc)
    line = who(hits["commons/maps/WaveFunctions_AirMusic/final.md"], now)
    if "fable-w3" not in line:
        print("SELFTEST FAIL: the claimant's name did not reach the row.")
        return 1
    if "0.1d" not in line:
        print("SELFTEST FAIL: the claim's age did not reach the row: %r" % line)
        return 1
    # An eleven-day-old claim must still be REPORTED, with its age, not aged
    # out. Gate N's 24-hour clock moved four fifths of its verdict overnight
    # with nothing in the world changing; no clock here moves anything.
    old = [{"thread": "t", "author": "gone-session", "at": "2026-08-31T11:50:00Z"}]
    if "gone-session" not in who(old, now) or "10.9d" not in who(old, now):
        print("SELFTEST FAIL: an old claim was dropped or lost its age: %r"
              % who(old, now))
        return 1
    if age_days("2026-08-31T11:50:00Z", now) != 10.9 or age_days("nonsense") is not None:
        print("SELFTEST FAIL: age_days is not reading its input.")
        return 1

    # An absent companion repo must read as nothing claimed, never as a crash.
    if load(ROOT / "no" / "such" / "store.json") != []:
        print("SELFTEST FAIL: a missing store did not read as empty.")
        return 1
    if claims([]) != {} or attribute(["a/b.md"], {}) != {}:
        print("SELFTEST FAIL: an empty store attributed something.")
        return 1

    print("SELFTEST PASS: reads a first-person claim, a claim after a colon, "
          "a claim in a reply and a declared `claims` list; refuses a room "
          "named as a to-do, a settled thread and an absent store. A claim "
          "names who -- nothing here removes a row.")
    return 0


def main() -> int:
    if "--selftest" in sys.argv:
        return selftest()
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    threads = load()
    claimed = claims(threads)

    if args:
        hits = attribute(args, claimed)
        if "--json" in sys.argv:
            print(json.dumps(summarise(hits), indent=2))
            return 0
        if not hits:
            print("nothing among those %d path(s) is claimed in an open thread."
                  % len(args))
            return 0
        for rel, found in sorted(hits.items()):
            print("  %-58s %s" % (rel, who(found)))
        return 0

    if "--json" in sys.argv:
        print(json.dumps({
            "store": str(STORE), "store_present": STORE.exists(),
            "threads": len(threads),
            "open": sum(1 for t in threads
                        if isinstance(t, dict) and t.get("status") == "open"),
            "claimed": {k: who(v) for k, v in sorted(claimed.items())},
        }, indent=2))
        return 0

    print("=== WHAT THE FORUM SAYS IS CLAIMED ===")
    if not threads:
        print("store not readable: %s" % STORE)
        print("(the forum lives in the encyclopedia repo; a clone of "
              "AdaResearch alone does not have it. Nothing is claimed.)")
        return 0
    print("%d threads, %d open, %d name(s) claimed in writing\n"
          % (len(threads),
             sum(1 for t in threads if isinstance(t, dict)
                 and t.get("status") == "open"),
             len(claimed)))
    for name, found in sorted(claimed.items()):
        how = "declared" if any(c["how"] == "declared" for c in found) else "claimed"
        print("  %-8s %-42s %s" % (how, name[:42], who(found)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
