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

    python tools/check_prose_reachable.py            # human
    python tools/check_prose_reachable.py --json     # machine-readable
    python tools/check_prose_reachable.py --selftest # the gate still bites

Exit code is the number of unreachable prose files, so it gates.
"""

import json
import subprocess
import sys
from pathlib import Path

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

    print("SELFTEST PASS: convicts an untracked essay in a declared room; "
          "acquits a tracked one, a room no tracked sequence declares, and "
          "a room whose name differs from the disk only in case.")
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

    if as_json:
        print(json.dumps({
            "rooms_declared": len(declared),
            "rooms_resolved": len(maps),
            "declared_case_mismatch": casemiss,
            "prose_files": len(on_disk),
            "prose_tracked": len(on_disk) - len(bad),
            "unreachable_from_a_clone": len(bad),
            "stranded_words": stranded,
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
        print("  %-58s %6d words   (%s)"
              % (b["path"], b["words"], ", ".join(b["declared_by"])))
    print("\nFAIL: %d prose file(s) totalling %d words that a clone of HEAD "
          "would not have. The rooms are reachable; the writing is not. "
          "Remedy: git add the files above, or say in the forum why they "
          "should stay out." % (len(bad), stranded))
    return len(bad)


if __name__ == "__main__":
    sys.exit(min(main(), 250))
