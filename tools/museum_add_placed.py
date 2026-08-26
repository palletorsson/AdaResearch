#!/usr/bin/env python3
"""PUT THE PLACED ROOMS INTO THE MUSEUM — or take them back out.

2026-08-25, Palle: "ok can we add these configs to the endless museum?"

The 165 generated rooms are real maps that pass every gate, but the museum
only builds what commons/data/map_authored.json names. This adds them and can
remove them again, because the decision is worth being able to reverse in one
command rather than by hand-editing a list of 165.

    python tools/museum_add_placed.py            # what it would do
    python tools/museum_add_placed.py --apply
    python tools/museum_add_placed.py --remove --apply

THEY JOIN THEIR OWN SEQUENCE'S CHAPTER, and there is no third option. The
museum resolves a chapter against its POOL, built from spine_artifact_order
.json, which knows 23 sequences — `placed_museums` is not one of them, so a
chapter of that name would be authored and unreachable. A generated room can
therefore only be walked inside the chapter it was furnished from.

WHICH HAS A CONSEQUENCE WORTH SAYING OUT LOUD: the curriculum walk gets
longer. color is 7 authored halls today and becomes 14; randomness becomes 16.
The generated rooms are APPENDED, so the hand-authored halls still come first
and the walk reads as the taught sequence followed by its variations — but it
is no longer only the taught sequence, and --remove is how that is undone.

Every added map is recorded under `_placed_added` so removal is exact, and a
hand-authored hall can never be dropped by mistake.
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUTHORED = os.path.join(ROOT, "commons", "data", "map_authored.json")
PLACED = os.path.join(ROOT, "commons", "maps", "sequences", "placed_museums.json")


def placed_by_sequence():
    with open(PLACED, encoding="utf-8") as fh:
        names = json.load(fh)["sequences"]["placed_museums"]["maps"]
    out = {}
    for n in names:
        p = os.path.join(ROOT, "commons", "maps", n, "map_data.json")
        if not os.path.exists(p):
            continue
        with open(p, encoding="utf-8") as fh:
            meta = (json.load(fh).get("map_info") or {}).get("metadata") or {}
        seq = meta.get("sequence", "")
        if seq:
            out.setdefault(seq, []).append(n)
    for k in out:
        out[k].sort()
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--remove", action="store_true")
    ap.add_argument("--all-chapters", action="store_true",
                    help="also author chapters the museum currently DEALS — see the warning")
    args = ap.parse_args()

    with open(AUTHORED, encoding="utf-8") as fh:
        doc = json.load(fh)
    added = doc.get("_placed_added") or {}
    by_seq = placed_by_sequence()

    if args.remove:
        print("REMOVING the placed rooms from the museum\n")
        n = 0
        for chapter, names in (added or {}).items():
            if chapter not in doc or not isinstance(doc[chapter], list):
                continue
            before = len(doc[chapter])
            doc[chapter] = [m for m in doc[chapter] if m not in names]
            gone = before - len(doc[chapter])
            n += gone
            print("  %-22s %2d removed, %2d hand-authored hall(s) remain"
                  % (chapter, gone, len(doc[chapter])))
        doc.pop("_placed_added", None)
        print("\n  %d hall(s) would be removed" % n)
    else:
        print("ADDING the placed rooms to the museum\n")
        print("  %-22s %5s %7s %6s" % ("chapter", "hand", "placed", "total"))
        record, n, skipped = {}, 0, []
        for chapter, names in sorted(by_seq.items()):
            have = doc.get(chapter)
            if not isinstance(have, list):
                # A CHAPTER NOT IN map_authored IS DEALT — the museum composes
                # its halls from its own vocabulary. Adding it here does not
                # append to that; it REPLACES it, and the chapter becomes only
                # these generated rooms. Sixteen of nineteen are in that state,
                # so this is opt-in rather than the default.
                if not args.all_chapters:
                    skipped.append((chapter, len(names)))
                    continue
                have = []
                doc[chapter] = have
            hand = [m for m in have if m not in names]
            fresh = [m for m in names if m not in have]
            doc[chapter] = hand + [m for m in names]
            record[chapter] = names
            n += len(fresh)
            print("  %-22s %5d %7d %6d" % (chapter, len(hand), len(names), len(doc[chapter])))
        doc["_placed_added"] = record
        print("\n  %d hall(s) would be added across %d chapter(s)" % (n, len(record)))

    if args.apply:
        with open(AUTHORED, "w", encoding="utf-8") as fh:
            json.dump(doc, fh, indent=1, ensure_ascii=False)
            fh.write("\n")
        r = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "em_map_halls.py"), "--apply"],
                           cwd=ROOT, capture_output=True, text=True)
        tail = [ln for ln in (r.stdout or "").splitlines() if "APPLIED" in ln or "map-authored" in ln]
        print("\n  " + "\n  ".join(tail[-4:] if tail else ["em_map_halls said nothing"]))
    else:
        print("  nothing written — pass --apply")
    return 0


if __name__ == "__main__":
    sys.exit(main())
