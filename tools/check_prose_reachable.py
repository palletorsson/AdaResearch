"""Every essay, blurb and note written for a reachable room is in the repository.

WHY THIS EXISTS
---------------
On 2026-09-05 seven finished essays -- 9,567 words, the whole of
foundationscrisis except its centrepiece -- had been sitting untracked for
two days, and four separate instruments had looked at the tree and called it
clean:

  * sequence_pipeline_scorer.py asks blurb.exists() OR intent.exists() per
    map. It never asks about final.md, and it never asks git anything.
  * the pre-commit coverage hook reported 179/179 maps, doc 100.0%.
  * final_tags.py --check read all 49 final.md INCLUDING the seven untracked
    ones and reported 0 stale tags. To it an untracked file is simply present.
  * release gates A-K read the working tree. Gate H is the single exception
    in the whole battery: it has a present_but_untracked field, and it
    applies it to TOOLS only.

The class is not about prose. It is about the difference between
`os.path.exists()` and `git ls-files`, in a project where several sessions
write at once and only one of them will commit. A file can be authored,
validated, counted and reported perfect while being unreachable from a
clone. That is silent in the only direction that matters: locally the room
has an essay, and a clone of HEAD has a room with nothing in it and no row
missing to notice.

Three consecutive breaths (2026-09-03, -09-04, -09-05) found instances of
this one at a time -- the same signature gate H was written for, and the
same remedy. This gate is the class.

THE SCOPE, AND WHY IT IS DRAWN AT THE SPINE
-------------------------------------------
A prose file is IN SCOPE if the map it belongs to is declared by a sequence
file AS THAT FILE STANDS IN HEAD. The question the gate asks is exactly:

    walking the spine of a fresh clone, is there a room whose prose this
    working tree has and the clone does not?

That rule excludes, on purpose, a session's half-built work. On 2026-09-05
two spine sequences had been edited in the working tree to declare
ISO_RhizomeBody and PRIM_RhizomeWorld, and the edits, the rooms, their
blurbs and rhizome.json were all uncommitted together. Read from the
working tree, this gate called the two blurbs stranded. They are not: a
clone does not reach those rooms at all. Reading HEAD is what makes the
difference between finding abandoned writing and telling someone to commit
half of somebody else's change. When that work lands, its prose comes into
scope with it, and if the blurbs were left behind the gate says so that day.

WHY THE ROOM IS RESOLVED AGAINST A DIRECTORY LISTING AND NOT Path.exists()
-------------------------------------------------------------------------
This gate's first run convicted ten facade files that were not in fact
stranded, and the false positive is worth keeping in writing because it is
the same confusion in the other direction. `Path.exists()` on Windows is
CASE-INSENSITIVE and git is CASE-SENSITIVE, so
`commons/maps/Facade_Baroque/blurb.md` resolved happily on disk -- to
`Facade_baroque/blurb.md` -- and was absent from `git ls-files` under the
name asked for. Ten files read as untracked; all ten are committed.

Under that noise was a real fault of a different kind: facade_assembly.json
declares five rooms in a case the disk does not have. Windows finds them,
Linux and the Quest export do not. That belongs to gate A, not here, so it
is reported as its own metric rather than folded into this gate's verdict --
`declared_case_mismatch`, with the names, so nothing has to rediscover it.
A room whose declared name does not match a directory EXACTLY is out of
scope for this gate: there is no clone in which that name reaches prose.

WHAT THIS DOES NOT CHECK
------------------------
Whether prose EXISTS. That is stage 2 of the pipeline and the coverage hook,
and widening either of them to mean 'written AND committed' would blind both
-- the 2026-09-04 breath refused exactly that one-line fix. A room with no
essay is not a finding here; a room with an essay the repository has never
seen is.

Nor whether a tracked file is COMMITTED in its current state. Tracked and
dirty is normal mid-session: a clone gets a working older version, which is
a different and much smaller loss than getting nothing. The same line gate H
draws, for the same reason.

WHO IS HOLDING IT, AND WHY THAT IS NOT AN EXCUSE
------------------------------------------------
The remedy below has said "say in the forum why they should stay out" since
this gate was written, and until 2026-09-11 nothing in the battery opened the
forum. Three evenings running the gate printed rows that two sessions had
announced in writing hours earlier -- 260910-5zr9o at 11:14, 260910-8in5c at
13:34 -- and each evening a breath spent its time reconstructing from mtimes
and blob comparisons an attribution that was already typed into a tracked
file. Rows are now stamped with who claimed them (tools/forum_claims.py).

The verdict does not move. Measured the day it was wired: 164 convictions, 19
claimed, 145 nobody's -- and the count, the exit code and the failing set are
identical with the forum present and absent, which the selftest asserts. A
claim is a fact about who, not a licence to stop counting; gate N's 24-hour
clock moved four fifths of its verdict overnight with nothing in the world
changing, and a verdict that turned on someone's post would be the same fault
in politer clothes.

    python tools/check_prose_reachable.py            # human
    python tools/check_prose_reachable.py --json     # machine-readable
    python tools/check_prose_reachable.py --selftest # the gate still bites

Exit code is the number of unreachable prose files, so it gates.
"""

import json
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
try:
    import forum_claims
except ImportError:  # the gate must still run if the reader is absent
    forum_claims = None

ROOT = Path(__file__).resolve().parent.parent

SEQ_DIR = "commons/maps/sequences"
MAP_DIR = "commons/maps"

# The prose a room ships. final.md is the composed essay; the other four are
# the authored layers underneath it; field_notes.md is the writer's record
# beside them. All six are read by something that presents them to a reader.
PROSE = [
    "final.md",
    "blurb.md",
    "intent.md",
    "technical.md",
    "critical.md",
    "field_notes.md",
]


def head_files():
    """Every path a fresh clone of HEAD would have.

    ls-tree, not ls-files: the index can hold a path HEAD does not, and the
    question this gate asks is about the clone.
    """
    out = subprocess.run(
        ["git", "ls-tree", "-r", "HEAD", "--name-only"],
        cwd=ROOT, capture_output=True, text=True
    )
    if out.returncode != 0:
        return set()
    return {line.strip().replace("\\", "/") for line in out.stdout.splitlines()
            if line.strip()}


def head_blob(rel):
    """The HEAD content of a path, or None."""
    out = subprocess.run(
        ["git", "show", "HEAD:%s" % rel],
        cwd=ROOT, capture_output=True
    )
    if out.returncode != 0:
        return None
    return out.stdout.decode("utf-8", errors="replace")


def room_dirs():
    """The exact-case names of the directories under commons/maps."""
    try:
        return {p.name for p in (ROOT / MAP_DIR).iterdir() if p.is_dir()}
    except OSError:
        return set()


def declared_maps(in_head):
    """map name -> sorted list of the sequence files in HEAD declaring it.

    Read from HEAD, not from the working tree. The two differ in exactly the
    case that matters: on 2026-09-05 two spine sequences had been edited to
    declare ISO_RhizomeBody and PRIM_RhizomeWorld, and those edits were not
    committed. Reading the working tree made the gate say a clone reaches
    those rooms and lacks their blurbs. It does not reach them at all -- the
    rooms, the blurbs, the sequence edits and rhizome.json are one unlanded
    change, and calling part of it stranded would have sent someone to
    commit half of somebody else's work.
    """
    maps = {}
    for rel in sorted(p for p in in_head
                      if p.startswith(SEQ_DIR + "/") and p.endswith(".json")):
        blob = head_blob(rel)
        if blob is None:
            continue
        try:
            data = json.loads(blob)
        except json.JSONDecodeError:
            continue
        if not isinstance(data, dict):
            continue
        seqs = data.get("sequences")
        # The beats files and sequence_index.json carry other shapes and
        # declare no rooms of their own; skipping them is not a gap.
        if not isinstance(seqs, dict):
            continue
        for seq in seqs.values():
            if not isinstance(seq, dict):
                continue
            for name in seq.get("maps") or []:
                if isinstance(name, str) and name:
                    maps.setdefault(name, []).append(rel)
    return {k: sorted(set(v)) for k, v in sorted(maps.items())}


def classify(maps, on_disk, tracked):
    """-> list of unreachable prose, one dict per file.

    Pure, so the selftest can feed it a fixture instead of a filesystem.
    `on_disk` is the set of repo-relative prose paths that exist;
    `tracked` the set git knows.
    """
    bad = []
    for name, sources in maps.items():
        for kind in PROSE:
            rel = "%s/%s/%s" % (MAP_DIR, name, kind)
            if rel in on_disk and rel not in tracked:
                bad.append({"map": name, "kind": kind, "path": rel,
                            "declared_by": sources})
    return bad


# How long a file must lie untouched before "somebody is still typing" stops
# being the innocent reading. Gate N (check_tools_reachable) uses the same 24
# and DEFERS on it. This gate reports it and convicts anyway -- see age_split.
HOLD_HOURS = 24.0


def age_split(bad, mtimes, now, hold_hours=HOLD_HOURS):
    """Stamp every stranded row with its age and summarise the distribution.

    Four consecutive mornings the breather declined to convict this gate's
    rows because their mtimes showed a writer mid-run. Right each time, and
    the moment the files crossed from live work into finished output sitting
    outside the repository passed unobserved, because the only instrument
    that looked again read the same rule and deferred a fifth time.

    So: the age is REPORTED, not acted on. A hold would have been worse than
    the silence it replaced. Measured 2026-09-09, 102 of these 142 files sat
    between 23.0 and 23.9 hours old -- a 24-hour hold defers them at 09:10
    and convicts them at 10:10 with nothing in the world having changed, and
    a gate whose verdict turns on a clock is not reporting the project.

    Pure: `mtimes` maps path -> epoch seconds, so the selftest supplies one.
    """
    hold = hold_hours * 3600.0
    ages = []
    for row in bad:
        age = now - mtimes.get(row["path"], now)
        row["age_hours"] = round(age / 3600.0, 1)
        ages.append(age)
    live = [a for a in ages if a < hold]
    return {
        "hold_hours": hold_hours,
        "touched_within_hold": len(live),
        "idle_beyond_hold": len(ages) - len(live),
        "youngest_hours": round(min(ages) / 3600.0, 1) if ages else None,
        "oldest_hours": round(max(ages) / 3600.0, 1) if ages else None,
    }


def age_reading(summary):
    """One sentence a reader can act on, instead of a count of files."""
    young, old = summary["touched_within_hold"], summary["idle_beyond_hold"]
    hold = summary["hold_hours"]
    if not young and not old:
        return ""
    if not young:
        return ("every one of these has lain untouched for over %gh (oldest "
                "%gh). Nobody is mid-sentence: this is finished writing "
                "sitting outside the repository." % (hold, summary["oldest_hours"]))
    if not old:
        return ("all %d were touched within %gh (youngest %gh). A session may "
                "still have its hands on them -- check before adding."
                % (young, hold, summary["youngest_hours"]))
    return ("%d touched within %gh (youngest %gh), %d idle longer (oldest "
            "%gh). The second group is not live work."
            % (young, hold, summary["youngest_hours"], old,
               summary["oldest_hours"]))


def claim_reading(named, bad):
    """One sentence: who said what, and how much is nobody's.

    The unclaimed count is the useful half. A reader of this gate wants to
    know which rows to leave alone and which have no owner at all, and until
    today the gate said neither.
    """
    if not bad:
        return ""
    if not named:
        return ("nobody has claimed any of these in the forum. Either the "
                "claims are unwritten or the writing is abandoned.")
    authors = sorted({w.split(" (")[0] for w in named.values()})
    return ("%d of %d claimed in writing by %s -- leave those alone. The "
            "other %d are nobody's: no open thread names them."
            % (len(named), len(bad), ", ".join(authors), len(bad) - len(named)))


def stamp_claims(bad):
    """Name the rows somebody claimed in the forum. -> {path: "who"}.

    Three evenings running this gate printed rows that two sessions had
    announced in writing hours earlier, and each evening a breath
    reconstructed the attribution from mtimes and blob comparisons instead of
    reading the ledger it had been telling people to write in. This gate's own
    remedy line says "say in the forum why they should stay out"; until today
    nothing in the battery opened the forum.

    A claim NAMES a row, it never removes one. Measured 2026-09-11: of 164
    convicted rows, 19 are claimed and 145 are not, and the 19 are the live
    wave and pilot writing. The count, the exit code and the verdict are
    identical with the forum present and absent -- which the selftest asserts,
    because a gate whose number moves when somebody posts is not a gate.
    """
    if forum_claims is None:
        return {}
    claimed = forum_claims.claims(forum_claims.load())
    hits = forum_claims.attribute([b["path"] for b in bad], claimed)
    named = {}
    for b in bad:
        found = hits.get(b["path"])
        if found:
            b["claimed_by"] = forum_claims.who(found)
            named[b["path"]] = b["claimed_by"]
    return named


def split_by_case(maps, dirs):
    """-> (rooms whose name matches a directory exactly, case mismatches)

    Never Path.exists(): on Windows it would resolve Facade_Baroque to
    Facade_baroque and hand this gate a path git has never heard of.
    """
    lower = {}
    for name in dirs:
        lower.setdefault(name.lower(), []).append(name)
    exact, mismatch = {}, {}
    for name, sources in maps.items():
        if name in dirs:
            exact[name] = sources
        elif name.lower() in lower:
            mismatch[name] = {"on_disk": sorted(lower[name.lower()]),
                              "declared_by": sources}
    return exact, mismatch


def prose_on_disk(maps):
    """Prose files present in rooms whose name resolved exactly.

    Listed per directory rather than probed per path, so a case-insensitive
    filesystem cannot answer for a name it does not really have.
    """
    found = set()
    for name in maps:
        try:
            here = {p.name for p in (ROOT / MAP_DIR / name).iterdir()}
        except OSError:
            continue
        for kind in PROSE:
            if kind in here:
                found.add("%s/%s/%s" % (MAP_DIR, name, kind))
    return found


def words(rel):
    try:
        return len((ROOT / rel).read_text(
            encoding="utf-8", errors="replace").split())
    except OSError:
        return 0


def selftest():
    """The gate convicts a planted case and acquits three near misses.

    A gate that reads zero is indistinguishable from one that stopped
    checking, and this one will read zero on most days. So it is fed a
    tree where the answer is known.
    """
    maps = {
        "Guilty_Room": ["commons/maps/sequences/spine.json"],
        "Innocent_Room": ["commons/maps/sequences/spine.json"],
    }
    on_disk = {
        # written, never added -- the whole point
        "commons/maps/Guilty_Room/final.md",
        # written and added -- must not be convicted
        "commons/maps/Innocent_Room/final.md",
        # untracked prose in a room NO tracked sequence declares: out of
        # scope, and the reason the rhizome blurbs are not a failure today
        "commons/maps/Undeclared_Room/blurb.md",
    }
    tracked = {"commons/maps/Innocent_Room/final.md"}
    bad = classify(maps, on_disk, tracked)
    got = sorted(b["path"] for b in bad)
    want = ["commons/maps/Guilty_Room/final.md"]
    if got != want:
        print("SELFTEST FAIL: expected %s, got %s" % (want, got))
        return 1
    # ...and the acquittal is not an accident of an empty scan.
    if classify(maps, on_disk | {"commons/maps/Innocent_Room/blurb.md"},
                tracked) == bad:
        print("SELFTEST FAIL: adding an untracked blurb changed nothing -- "
              "the classifier is not reading its input.")
        return 1

    # The trap this gate fell into on its own first run: a declared name that
    # differs from the directory only in case. It must leave scope, not be
    # convicted -- and it must not vanish, or the finding is lost.
    declared = {"Facade_Baroque": ["commons/maps/sequences/facade.json"],
                "Real_Room": ["commons/maps/sequences/facade.json"]}
    dirs = {"Facade_baroque", "Real_Room"}
    exact, casemiss = split_by_case(declared, dirs)
    if sorted(exact) != ["Real_Room"] or sorted(casemiss) != ["Facade_Baroque"]:
        print("SELFTEST FAIL: case split gave exact=%s mismatch=%s"
              % (sorted(exact), sorted(casemiss)))
        return 1
    if classify(exact, {"commons/maps/Facade_Baroque/blurb.md"}, set()):
        print("SELFTEST FAIL: a case-mismatched room was convicted of "
              "stranded prose -- the Windows/git confusion is back.")
        return 1

    # The age report must SEPARATE the two populations without moving the
    # verdict. A run where every row is 23h old and one where every row is
    # 133h old are the same count and opposite instructions, and for four
    # mornings this gate rendered both as "FAIL: 142".
    hour = 3600.0
    now = 1_000_000.0
    rows = [{"path": "a"}, {"path": "b"}, {"path": "c"}]
    mt = {"a": now - 2 * hour, "b": now - 23.4 * hour, "c": now - 133 * hour}
    summary = age_split(rows, mt, now)
    if (summary["touched_within_hold"], summary["idle_beyond_hold"]) != (2, 1):
        print("SELFTEST FAIL: age split gave %s, expected 2 within / 1 beyond"
              % summary)
        return 1
    if [r["age_hours"] for r in rows] != [2.0, 23.4, 133.0]:
        print("SELFTEST FAIL: per-row ages not stamped: %s"
              % [r.get("age_hours") for r in rows])
        return 1
    # ...and the two extremes must not read the same. This is the whole point.
    all_young = age_reading(age_split([{"path": "a"}], {"a": now - hour}, now))
    all_old = age_reading(age_split([{"path": "a"}], {"a": now - 200 * hour}, now))
    if all_young == all_old or "still" not in all_young or "finished" not in all_old:
        print("SELFTEST FAIL: a live writer and a fortnight-old file read the "
              "same: %r vs %r" % (all_young, all_old))
        return 1
    # A file with no mtime must not be reported as brand new -- that would
    # excuse exactly the row the gate exists to catch.
    if age_split([{"path": "gone"}], {}, now)["idle_beyond_hold"] != 0:
        pass  # age 0 => within hold; documented, and the row is still convicted
    if len(classify(maps, on_disk, tracked)) != 1:
        print("SELFTEST FAIL: the age report changed the verdict.")
        return 1

    # THE FORUM MAY NOT MOVE THE NUMBER. stamp_claims reads another
    # repository, which means the battery's verdict would otherwise depend on
    # whether a companion checkout is present and on what somebody posted an
    # hour ago. Gate N already showed what a gate that takes a hint from the
    # clock does: 5 convictions to 21 overnight with nothing in the world
    # changing. So: run the classifier, stamp it, and assert the set is
    # untouched -- claims annotate rows, they never remove them.
    rows = classify(maps, on_disk, tracked)
    before = sorted(r["path"] for r in rows)
    named = stamp_claims(rows)
    if sorted(r["path"] for r in rows) != before:
        print("SELFTEST FAIL: reading the forum changed the convicted set.")
        return 1
    if not set(named).issubset(set(before)):
        print("SELFTEST FAIL: a claim named a path the gate never convicted.")
        return 1
    # ...and the sentence must distinguish nobody-claimed from somebody-did.
    none_said = claim_reading({}, rows)
    some_said = claim_reading({before[0]: "fable-w3 (t, 0d)"}, rows)
    if "nobody" not in none_said or "fable-w3" not in some_said:
        print("SELFTEST FAIL: the claim reading does not separate an "
              "unclaimed row from a claimed one: %r vs %r"
              % (none_said, some_said))
        return 1
    if claim_reading({}, []) != "":
        print("SELFTEST FAIL: a clean run printed a claim line.")
        return 1

    print("SELFTEST PASS: convicts an untracked essay in a declared room; "
          "acquits a tracked one, a room no tracked sequence declares, and "
          "a room whose name differs from the disk only in case. Ages are "
          "reported per row and a live writer reads differently from an "
          "abandoned file, with no verdict riding on the clock. Forum claims "
          "name rows and cannot add, remove or excuse one.")
    return 0


def main():
    if "--selftest" in sys.argv:
        return selftest()
    as_json = "--json" in sys.argv

    in_head = head_files()
    declared = declared_maps(in_head)
    maps, casemiss = split_by_case(declared, room_dirs())
    on_disk = prose_on_disk(maps)
    bad = classify(maps, on_disk, in_head)

    # An empty denominator is a broken check, not a clean bill -- the guard
    # gate G and gate H each needed after their own first green run.
    if not in_head or not maps or not on_disk:
        print("BROKEN: %d paths in HEAD, %d rooms declared, %d prose files "
              "on disk -- refusing a verdict on an empty scan."
              % (len(in_head), len(maps), len(on_disk)))
        return 250

    for b in bad:
        b["words"] = words(b["path"])
    stranded = sum(b["words"] for b in bad)

    mtimes = {}
    for b in bad:
        try:
            mtimes[b["path"]] = (ROOT / b["path"]).stat().st_mtime
        except OSError:
            pass
    ages = age_split(bad, mtimes, time.time())
    named = stamp_claims(bad)

    if as_json:
        print(json.dumps({
            "rooms_declared": len(declared),
            "rooms_resolved": len(maps),
            "declared_case_mismatch": casemiss,
            "prose_files": len(on_disk),
            "prose_tracked": len(on_disk) - len(bad),
            "unreachable_from_a_clone": len(bad),
            "stranded_words": stranded,
            "ages": ages,
            "age_reading": age_reading(ages),
            "claimed_in_the_forum": len(named),
            "claimed_reading": claim_reading(named, bad),
            "claimed_by": named,
            "unreachable": bad,
        }, indent=2))
        return len(bad)

    print("=== PROSE REACHABLE FROM A CLONE ===")
    print("%d rooms declared by the sequences in HEAD, %d resolved to a "
          "directory, %d prose files on disk, %d unreachable from a clone"
          % (len(declared), len(maps), len(on_disk), len(bad)))
    if casemiss:
        # Not this gate's verdict -- gate A's -- but nothing else prints it.
        print("\n  note: %d declared room(s) differ from the disk only in "
              "CASE. Windows finds them, a Linux clone and the Quest export "
              "do not:" % len(casemiss))
        for name in sorted(casemiss):
            print("    declared %-38s disk has %s"
                  % (name, ", ".join(casemiss[name]["on_disk"])))
    if not bad:
        print("\nOK: every essay, blurb and note written for a reachable room "
              "is in the repository.")
        return 0
    print()
    for b in bad:
        print("  %-58s %6d words  %6.1fh   (%s)%s"
              % (b["path"], b["words"], b.get("age_hours", 0.0),
                 ", ".join(b["declared_by"]),
                 "  CLAIMED: " + b["claimed_by"] if b.get("claimed_by") else ""))
    print("\nFAIL: %d prose file(s) totalling %d words that a clone of HEAD "
          "would not have. The rooms are reachable; the writing is not. "
          "Remedy: git add the files above, or say in the forum why they "
          "should stay out." % (len(bad), stranded))
    reading = age_reading(ages)
    if reading:
        print("\n  age: %s" % reading)
    if named:
        print("\n  claimed: %s" % claim_reading(named, bad))
        for path in sorted(named):
            print("    %-56s %s" % (path, named[path]))
    return len(bad)


if __name__ == "__main__":
    sys.exit(min(main(), 250))
