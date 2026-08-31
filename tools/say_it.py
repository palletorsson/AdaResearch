#!/usr/bin/env python3
"""GET THE WORDS ONTO THE WALL — every step from the book to the headset.

    python tools/say_it.py                    # every chapter whose book is newer
    python tools/say_it.py --chapter=primitives
    python tools/say_it.py --quest            # ...and push it to a connected Quest
    python tools/say_it.py --check            # say what is stale, change nothing

2026-08-31, Palle: "the new texts are not updated in VR. How does it work, I
rather have it be automatic?"

HOW IT WORKED, which is the reason this exists. A wall sentence is written in
/compose, /wall-texts, /lines or the museum itself, and lands in
commons/data/book/<chapter>.json. Nothing downstream watches that file:

    book/<chapter>.json
      -> book.py compile          writes commons/data/trunk_branches.json
      -> the desktop museum         reads the trunk (NOT the book) for wall text
      -> em_ship.py               copies the trunk into commons/data/museum/
      -> the export                carries commons/, so the headset sees it
      -> adb push (--quest)        an override the museum reads BEFORE the export

Two of those steps were manual and neither announced itself, so a sentence could
be correct in the book, correct on the web, and three days old on the wall. That
happened: the trunk was stamped 2026-08-28 against a book touched 2026-08-31, and
the museum went on saying "Show me what you can do with those hands".

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


def main() -> int:
    ap = argparse.ArgumentParser(description="book -> trunk -> export -> headset")
    ap.add_argument("--chapter", default="", help="one chapter, whether or not it is stale")
    ap.add_argument("--quest", action="store_true", help="also adb-push the trunk as an override")
    ap.add_argument("--check", action="store_true", help="report staleness, write nothing")
    a = ap.parse_args()

    todo = [a.chapter] if a.chapter else stale_chapters()

    print("SAY IT — from the book to the wall")
    print()
    if not TRUNK.exists():
        print("  no trunk yet: %s" % TRUNK)
    else:
        print("  trunk written  : %s" % __import__("datetime").datetime.fromtimestamp(
            TRUNK.stat().st_mtime).isoformat(timespec="seconds"))
    print("  chapters stale : %d%s" % (len(todo), ("  " + ", ".join(todo)) if todo else ""))
    if SHIPPED.exists():
        drift = TRUNK.stat().st_mtime - SHIPPED.stat().st_mtime if TRUNK.exists() else 0
        print("  shipped copy   : %s" % ("BEHIND the trunk" if drift > 1 else "current"))
    else:
        print("  shipped copy   : ABSENT — the export would carry no trunk at all")

    if a.check:
        print()
        print("  --check: nothing written.")
        return 1 if todo else 0
    if not todo:
        print()
        print("  Nothing to compile. The trunk is newer than every book file.")
        # the ship is still worth doing: the trunk can be newer than the copy
        if SHIPPED.exists() and TRUNK.exists() and TRUNK.stat().st_mtime <= SHIPPED.stat().st_mtime:
            if not a.quest:
                return 0

    print()
    for ch in todo:
        if not (BOOK / (ch + ".json")).exists():
            print("  no such chapter: %s" % ch)
            return 2
        print("  compiling %s" % ch)
        if not run([sys.executable, "tools/book.py", "compile", "--chapter", ch], "book.py compile " + ch):
            return 1

    print("  shipping into commons/data/museum/")
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
        print("  For VR: --quest pushes an override, or export as usual.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
