#!/usr/bin/env python3
"""One token, two entries: which object does a map actually get?

GridArtifactRegistry loads every commons/artifacts/registry/*.json in DirAccess
order and does, at line 102:

    artifacts[artifact_id] = artifact

Last file wins. It even prints "Note: Overwriting artifact 'X' with definition
from Y" — and nobody reads engine stdout, so the corpus has been quietly
resolving duplicate tokens by FILENAME ALPHABET for as long as there have been
two registry files.

Two things go wrong when a token collides:

  * SAME scene, different metadata — the thin auto-generated stub usually sorts
    later than the authored entry, so the authored name, sequence and
    qfep_connection lose to a stub. box_counting_dimension's declared DNA axis
    sat in chaos.json while procgen_extra.json won the token, so the sweep
    could never reach it and the declaration gate reported it undeclared.

  * DIFFERENT scenes — two genuinely different objects wearing one name. A map
    that writes `microscope` gets commons/lab/microscope, not
    commons/artifacts/microscope, because "w" > "l". Nobody chose that.

This gate names both. Exit code is the number of colliding tokens, so it can sit
in a chain. It does not repair anything: picking which object a name means is a
content ruling, not a merge.

    python tools/check_registry_collisions.py [--quiet]
"""

from __future__ import annotations

import collections
import glob
import json
import os
import sys

REG_DIR = os.path.join("commons", "artifacts", "registry")


def entries():
    """token -> [(filename, entry_dict)] in DirAccess (alphabetical) order."""
    found = collections.defaultdict(list)
    for path in sorted(glob.glob(os.path.join(REG_DIR, "*.json"))):
        try:
            data = json.load(open(path, encoding="utf-8"))
        except Exception as exc:  # a broken registry is a different gate's job
            print(f"  ! unreadable: {path} ({exc})")
            continue
        arts = data.get("artifacts") if isinstance(data, dict) else None
        if not isinstance(arts, dict):
            continue
        for token, entry in arts.items():
            if isinstance(entry, dict):
                found[token].append((os.path.basename(path), entry))
    return found


def target(entry: dict) -> str:
    return str(entry.get("scene") or entry.get("delegate_to") or "")


def placements() -> collections.Counter:
    count = collections.Counter()
    for path in glob.glob(os.path.join("commons", "maps", "*", "map_data.json")):
        try:
            data = json.load(open(path, encoding="utf-8"))
        except Exception:
            continue
        rows = (data.get("layers") or {}).get("interactables") or []
        for row in rows:
            if not isinstance(row, list):
                continue
            for cell in row:
                if isinstance(cell, str) and cell:
                    count[cell.split(":")[0]] += 1
    return count


def main() -> int:
    quiet = "--quiet" in sys.argv
    found = entries()
    placed = placements()

    collisions = {t: v for t, v in found.items() if len(v) > 1}
    if not collisions:
        print("no token is declared in more than one registry file")
        return 0

    forked, shadowed = [], []
    for token, rows in sorted(collisions.items()):
        (forked if len({target(e) for _f, e in rows} - {""}) > 1 else shadowed).append(token)

    lost = sum(placed[t] for t in collisions)
    print(
        f"{len(collisions)} tokens declared twice · {len(forked)} resolve to DIFFERENT "
        f"objects · {lost} placements ride on the alphabet"
    )

    def show(title: str, tokens: list, note: str) -> None:
        if not tokens:
            return
        print(f"\n{title}  [{note}]")
        for token in tokens:
            rows = collisions[token]
            winner = rows[-1][0]  # last file loaded wins
            print(f"  {token}  ({placed[token]} placements)")
            for fname, entry in rows:
                mark = "WINS " if fname == winner else "     "
                keys = len(entry)
                dna = "dna " if isinstance(entry.get("dna"), dict) and entry["dna"].get("axes") else "    "
                if not quiet:
                    print(f"    {mark}{dna}{keys:>3} keys  {fname:<28} {target(entry) or '—'}")

    show(
        "TWO OBJECTS, ONE NAME",
        forked,
        "a map cannot ask for the other one; the filename decides",
    )
    show(
        "ONE OBJECT, TWO ENTRIES",
        shadowed,
        "the later file's metadata wins wholesale — no key-level merge happens",
    )

    print(
        "\nThe loser is not a fallback. GridArtifactRegistry REPLACES the entry, so every\n"
        "key the winner omits — name, sequence, qfep_connection, dna.axes — is simply gone."
    )
    return len(collisions)


if __name__ == "__main__":
    sys.exit(main())
