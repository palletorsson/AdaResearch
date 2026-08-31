#!/usr/bin/env python3
"""GET THE WORDS ONTO THE WALL — every step from the book to the headset.

    python tools/say_it.py                    # every chapter whose book is newer
    python tools/say_it.py --chapter=primitives
    python tools/say_it.py --quest            # ...and push it to a connected Quest
    python tools/say_it.py --check            # say what is stale, change nothing
    python tools/say_it.py --ship             # also refresh commons/data/museum/
                                              #   (belt and braces — see below)
    python tools/say_it.py --pack=<file>      # does that .pck/.apk carry today's
                                              #   sentences? (see WAS IT BUILT AFTER)

2026-08-31, Palle: "the new texts are not updated in VR. How does it work, I
rather have it be automatic?"

ONE TRANSLATION, NOT THREE. 2026-08-31, Palle: "Can we skip any extra layer or
translation between the editing tool and vr to keep it more simple? Use the same
principle as for the desktop endless museum?"

Yes, and one of the layers was already dead. The desktop principle is that the
museum reads the file WHERE IT LIVES — res://commons/data/trunk_branches.json,
no copy. VR could not do that once, so em_ship.py copied the generated files into
commons/data/museum/ and _shipped fell back to them: exports excluded
ada_run/*,ada_run/** wholesale, and the Quest walked a plan-less museum for a day
because of it.

That exclusion is gone. Commit 8c6ea0c00 narrowed it to specific subdirectories
and non-json extensions, and export_presets.cfg now reads
include_filter="*.md,*.json" with nothing excluding ada_run/*.json. Checked file
by file against the live filters: em_plan, em_bake, em_control, em_overrides,
em_layout_walk and trunk_branches are ALL in the export already. The copy has
been copying files the .pck was carrying anyway.

So the chain is what the desktop's always was, plus one arm for the headset:

    book/<chapter>.json
      -> book.py compile        writes commons/data/trunk_branches.json
      -> the museum               reads it directly, desktop AND export
      -> adb push (--quest)     an override read BEFORE the export, no rebuild

That step was manual and did not announce itself, so a sentence could be correct
in the book, correct on the web, and three days old on the wall. It was: the
trunk was stamped 2026-08-28 against a book touched 2026-08-31.

WAS IT BUILT AFTER THE WORDS WERE. 2026-08-31, Palle: "still not the right text
in wall text ... I do the export via the Godot program menu but the data should
not be made on export it should be the data of the project."

He is right that nothing should be MADE on export, and nothing is: the project's
own commons/data/trunk_branches.json is what the export carries. Checked by
building a pack and reading it — both that file and the museum/ fallback are
inside, with the current sentences in them.

Which leaves the question the eye cannot answer: was the APK on the headset built
BEFORE or AFTER the last compile? An export is a photograph of the project, and
a photograph taken this morning does not show this afternoon. --pack reads a
built .pck or .apk and says whether the sentences in it are the ones on disk now.
It greps rather than parses, because a pack is a container and the sentence is
the evidence: if the words are in there, they shipped.

WHAT MAKES IT SAFE TO RUN OFTEN. It compiles only chapters whose book is NEWER
than the trunk, so the default run on an unchanged tree does nothing and says so.
--check does the same reading and no writing, which is the form to put in front
of a gate.
"""
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
BOOK = REPO / "commons" / "data" / "book"
TRUNK = REPO / "commons" / "data" / "trunk_branches.json"
SHIPPED = REPO / "commons" / "data" / "museum" / "trunk_branches.json"

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")


def stale_chapters() -> list[str]:
    """Chapters whose book has been touched since the trunk was last written."""
    if not TRUNK.exists():
        return sorted(p.stem for p in BOOK.glob("*.json"))
    at = TRUNK.stat().st_mtime
    return sorted(p.stem for p in BOOK.glob("*.json") if p.stat().st_mtime > at)


def run(args: list[str], why: str) -> bool:
    r = subprocess.run(args, cwd=str(REPO), capture_output=True, text=True)
    if r.returncode != 0:
        print("  FAILED: %s" % why)
        print((r.stdout or "")[-1500:])
        print((r.stderr or "")[-1500:])
        return False
    return True


def push_quest() -> bool:
    """The override the museum now reads before anything the export carries —
    endless_museum._shipped looks in override_data/ first on Android. Same
    mechanism as tools/push_map_to_quest.ps1, which has spared maps the APK
    rebuild since August; the trunk simply never had the arm."""
    pkg = "com.adaresearch.zeroone"
    rel = "override_data/trunk_branches.json"
    tmp = "/data/local/tmp/trunk_branches.json"
    steps = [
        (["adb", "push", str(TRUNK), tmp], "adb push to /data/local/tmp"),
        (["adb", "shell", "run-as %s mkdir -p files/override_data" % pkg], "mkdir override_data"),
        (["adb", "shell", "run-as %s cp %s files/%s" % (pkg, tmp, rel)], "cp into the app's files dir"),
    ]
    for args, why in steps:
        if not run(args, why):
            print("  the headset did not take it — is a Quest connected and authorised?")
            return False
    print("  pushed to the headset as %s — no APK rebuild" % rel)
    return True


def sentences() -> list[tuple[str, str]]:
    """EVERY wall line long enough to be its own fingerprint.

    This took the forty LONGEST and it was wrong. Mutation-tested by planting a
    94-character sentence in the trunk and re-running against an unchanged pack:
    it reported 0 missing, because the planted line was not in the top forty. A
    sample cannot answer "is this build current" — the line that changed is
    precisely the one nobody thought to sample.

    40 characters is the floor. Below it lines repeat across the corpus ("You are
    here", "the fold") and a hit proves nothing about which build a pack is."""
    out: list[tuple[str, str]] = []
    try:
        d = json.loads(TRUNK.read_text(encoding="utf-8"))
    except Exception:
        return out
    for ch, pearls in (d.get("hand_pearls") or {}).items():
        for pl in pearls or []:
            for tok, txt in (pl.get("says") or {}).items():
                t = str(txt or "").strip()
                if len(t) >= 40:
                    out.append(("%s/%s/%s" % (ch, pl.get("pearl", "?"), tok), t))
    return out


def check_pack(pack: Path) -> int:
    """Is what was built the same as what is on disk? A pack is a container, so
    this looks for the SENTENCE, not for the file: if the words are in there,
    they shipped, whatever path they arrived under."""
    print("SAY IT — is that build current?")
    print()
    if not pack.exists():
        print("  no such pack: %s" % pack)
        return 2
    blob = pack.read_bytes()
    # THE TRUNK IS ONE CONTIGUOUS RUN INSIDE THE PACK, so the search is done in a
    # window around it rather than over 593 MB per sentence. Without this,
    # checking every line instead of a sample would take minutes; with it, the
    # complete check is faster than the sampled one was.
    #
    # If the marker is absent the pack either does not carry the trunk or stores
    # it compressed, and BOTH are answers rather than reasons to fall back to a
    # whole-blob scan that would report every line missing without saying why.
    mark = b'"hand_pearls"'
    at = blob.find(mark)
    window = blob if at < 0 else blob[max(0, at - 2_000_000): at + 4_000_000]
    print("  pack   : %s (%.0f MB)" % (pack.name, len(blob) / 1048576))
    if at < 0:
        print()
        print("  NO TRUNK IN THIS PACK — no \"hand_pearls\" anywhere in it. Either the")
        print("  export did not carry commons/data/trunk_branches.json, or it stored it")
        print("  compressed. Either way no wall in that build can say anything new.")
        return 2
    print("  built  : %s" % __import__("datetime").datetime.fromtimestamp(
        pack.stat().st_mtime).isoformat(timespec="seconds"))
    print("  trunk  : %s" % __import__("datetime").datetime.fromtimestamp(
        TRUNK.stat().st_mtime).isoformat(timespec="seconds"))
    print()

    rows = sentences()
    if not rows:
        print("  the trunk carries no long wall line to look for.")
        return 2
    # AS THE FILE SPELLS IT, not as json.loads handed it over. A wall line
    # holding a newline or a quote is stored ESCAPED, so searching for the
    # DECODED string misses it: four of 651 came back missing from a pack that
    # demonstrably carried them, and every one of the four held a newline.
    #
    # json.dumps re-encodes exactly as the file does; the slice drops the
    # surrounding quote marks, leaving the body as it sits on disk.
    def as_stored(t: str) -> bytes:
        return json.dumps(t, ensure_ascii=False)[1:-1].encode("utf-8")

    missing = [(w, t) for w, t in rows if as_stored(t) not in window]
    print("  checked %d wall lines — EVERY line of 40 characters or more" % len(rows))
    print("  in the pack   : %d" % (len(rows) - len(missing)))
    print("  MISSING       : %d" % len(missing))
    if missing:
        print()
        print("  This build predates those sentences — export again, after say_it.py.")
        for w, t in missing[:6]:
            print("    %-46s %s" % (w, (t[:60] + "…") if len(t) > 60 else t))
        return 1
    print()
    print("  Every one is in there. If a wall still reads wrong, the build is not")
    print("  the problem — look at whether the hall was rebuilt, or at which pearl")
    print("  that wall is adopted to.")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description="book -> trunk -> export -> headset")
    ap.add_argument("--chapter", default="", help="one chapter, whether or not it is stale")
    ap.add_argument("--quest", action="store_true", help="also adb-push the trunk as an override")
    ap.add_argument("--ship", action="store_true",
                    help="also run em_ship.py — redundant since 8c6ea0c00, kept for an old build")
    ap.add_argument("--check", action="store_true", help="report staleness, write nothing")
    ap.add_argument("--pack", default="", help="a built .pck or .apk: does it carry today's sentences?")
    a = ap.parse_args()

    if a.pack:
        return check_pack(Path(a.pack))

    todo = [a.chapter] if a.chapter else stale_chapters()

    print("SAY IT — from the book to the wall")
    print()
    if not TRUNK.exists():
        print("  no trunk yet: %s" % TRUNK)
    else:
        print("  trunk written  : %s" % __import__("datetime").datetime.fromtimestamp(
            TRUNK.stat().st_mtime).isoformat(timespec="seconds"))
    print("  chapters stale : %d%s" % (len(todo), ("  " + ", ".join(todo)) if todo else ""))
    # the fallback copy is reported, not required: the export carries the real
    # file, so a stale or absent copy here is not a fault
    if SHIPPED.exists():
        drift = TRUNK.stat().st_mtime - SHIPPED.stat().st_mtime if TRUNK.exists() else 0
        print("  fallback copy  : %s (unused — the export carries the real file)"
              % ("behind" if drift > 1 else "current"))

    if a.check:
        print()
        print("  --check: nothing written.")
        return 1 if todo else 0
    if not todo and not a.quest and not a.ship:
        print()
        print("  Nothing to compile. The trunk is newer than every book file.")
        return 0

    print()
    for ch in todo:
        if not (BOOK / (ch + ".json")).exists():
            print("  no such chapter: %s" % ch)
            return 2
        print("  compiling %s" % ch)
        if not run([sys.executable, "tools/book.py", "compile", "--chapter", ch], "book.py compile " + ch):
            return 1

    if a.ship:
        # NOT the path any more: _shipped reads res://commons/data/trunk_branches
        # .json first and the export carries it, so this only feeds the fallback.
        # Kept behind a flag for a headset running a build older than 8c6ea0c00.
        print("  also shipping into commons/data/museum/ (fallback copy)")
        if not run([sys.executable, "tools/em_ship.py"], "em_ship.py"):
            return 1

    if a.quest:
        print("  pushing to the headset")
        if not push_quest():
            return 1

    print()
    print("  Done. The DESKTOP museum re-reads the trunk on its own — _speak_for")
    print("  drops its cache when the file's mtime changes — but a hall keeps the")
    print("  labels it was BUILT with, so walk out and back, or relaunch.")
    if not a.quest:
        print("  For VR: --quest pushes an override (no rebuild), or export as usual —")
        print("  the export carries commons/data/trunk_branches.json itself.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
