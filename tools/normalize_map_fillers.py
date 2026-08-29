"""Normalise the EMPTY-CELL FILLER in the utilities + interactables layers.

The corpus convention for "nothing is here" in those two layers is a single space
(`" "`) or the empty string (`""`). Both engine components test exactly that:

    GridUtilitiesComponent.gd:192   if utility_cell.is_empty() or utility_cell == " ": continue
    GridInteractablesComponent.gd:586  if token != " " and not token.is_empty():

so ANY other filler is not empty to the engine -- it is a token, and it is placed,
or rather it fails to place, once per cell. Measured 2026-08-27 over 2788 maps:
2783 use " " or "", two use "0", three use ", ". Forces_PropGallery alone carried
664 phantom interactable cells, which dragged the forces sequence from pipeline
stage 6 to stage 3 and the project average from 6.091 to 5.955.

The rewrite is deliberately LINE-SCOPED rather than a json round-trip:

  * a json.dump would reformat all 177 lines and bury the actual change, and
  * the ", " filler is textually indistinguishable from the ", " separator, so a
    naive string replace corrupts the row. Parsing ONE ROW LINE as JSON resolves
    it exactly.

Every real token is preserved -- the tool refuses to run if the count of non-filler
cells changes.

Usage:
    python tools/normalize_map_fillers.py --scan
    python tools/normalize_map_fillers.py --apply
    python tools/normalize_map_fillers.py --apply --map=Forces_PropGallery
"""

import argparse
import collections
import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent
MAPS_DIR = ROOT / "commons" / "maps"

LAYERS = ("utilities", "interactables")
GOOD_FILLERS = (" ", "")
CANON = " "

_ROW_RE = re.compile(r'^(\s*)(\[.*?\])(,?)\s*$')

# THE PREDICATE IS BORROWED, NOT REWRITTEN. The first cut of this tool decided
# what was empty by majority vote -- the most common cell in a layer -- which
# fixed all five bulk offenders and then failed the negative test: one stray "0"
# among 663 blanks is not the dominant value, so the tool reported the map clean
# while check_map_tokens.py failed it. A gate whose named remedy cannot fix what
# the gate finds is worse than no remedy. Both now ask the same question.
sys.path.insert(0, str(Path(__file__).parent))
from check_map_tokens import is_empty_cell  # noqa: E402


def bad_cells_in_row(row):
    """Indices of cells that mean 'empty' but are not written as " " or ""."""
    out = []
    for i, cell in enumerate(row):
        raw = (cell or "").strip() if isinstance(cell, str) else str(cell or "")
        if raw in GOOD_FILLERS or raw.startswith("#"):
            continue
        if is_empty_cell(raw):
            out.append(i)
    return out


def scan_map(path: Path):
    """Return {layer_name: (sample_value, count, is_bulk)} for layers holding bad blanks.

    `is_bulk` is the whole safety story. A layer whose bad value IS its dominant
    cell is a filler chosen by an authoring tool -- mechanical, evidence-free, and
    safe to rewrite. A handful of odd cells in a layer that is otherwise properly
    blank is something else entirely, and the corpus says so out loud:

        F30_Ramp_Walkpath  utilities  ":180"  x1   <- a rotation suffix with no token
        Tutorial_Single    utilities  "1"     x19  <- beside "pick_up_cub", which is
                                                      not registered; "pick_up_cube" is

    Those are LOST TOKENS. Normalising them to " " would erase the evidence of an
    authoring mistake and call it a repair, so --apply refuses them and says why.
    """
    try:
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
    except Exception:
        return {}
    layers = data.get("layers", {})
    out = {}
    for name in LAYERS:
        layer = layers.get(name)
        if not layer:
            continue
        vals = collections.Counter()
        allcells = collections.Counter()
        for row in layer:
            if not isinstance(row, list):
                continue
            allcells.update(str(c) for c in row)
            for i in bad_cells_in_row(row):
                vals[str(row[i])] += 1
        if vals:
            worst = vals.most_common(1)[0][0]
            dominant = allcells.most_common(1)[0][0] if allcells else None
            out[name] = (worst, sum(vals.values()), worst == dominant)
    return out


def _real_cells(path: Path):
    """Every cell that is NOT a blank of any spelling -- the payload that must
    survive the rewrite untouched, counted by value."""
    with open(path, encoding="utf-8") as fh:
        data = json.load(fh)
    layers = data.get("layers", {})
    total = collections.Counter()
    for name in LAYERS:
        for row in layers.get(name) or []:
            if not isinstance(row, list):
                continue
            bad = set(bad_cells_in_row(row))
            for i, c in enumerate(row):
                s = str(c)
                if i not in bad and s not in GOOD_FILLERS:
                    total[s] += 1
    return total


def rewrite(path: Path, bad: dict) -> int:
    """Replace each layer's bad filler with " ", line by line. Returns cells changed."""
    src = open(path, encoding="utf-8").read()
    lines = src.split("\n")

    # Which line range belongs to which layer: the layer key opens the block and the
    # next layer key (or the close of "layers") ends it. Grid rows are one per line,
    # which is what makes the line-scoped edit safe.
    starts = {}
    for i, ln in enumerate(lines):
        for name in LAYERS:
            if ln.strip().startswith('"%s": [' % name):
                starts[name] = i
    changed = 0
    for name in [n for n, v in bad.items() if v[2]]:
        if name not in starts:
            print("  ! %s: could not locate the %s block on its own line" % (path.name, name))
            return -1
        i = starts[name] + 1
        while i < len(lines):
            m = _ROW_RE.match(lines[i])
            if not m:
                break
            pad, body, comma = m.groups()
            try:
                row = json.loads(body)
            except Exception:
                break
            if not isinstance(row, list):
                break
            hits = bad_cells_in_row(row)
            if hits:
                # `col`, NOT `i`: `i` is the LINE index this loop is walking, and
                # shadowing it here wrote the rebuilt row to lines[<column>] --
                # line 0, clobbering the opening brace. Caught by the negative test.
                for col in hits:
                    row[col] = CANON
                changed += len(hits)
                lines[i] = pad + "[" + ", ".join(json.dumps(c, ensure_ascii=False) for c in row) + "]" + comma
            i += 1

    out = "\n".join(lines)

    # A map_data.json is never a handful of bytes. open(mode="w") truncates BEFORE it
    # validates its arguments, so the write goes to a temp file and lands by rename.
    if len(out) < 200:
        print("  ! refusing to write %d bytes to %s" % (len(out), path))
        return -1

    # A line-scoped rewrite can produce text that is no longer JSON without any
    # step raising -- an off-by-one in the line index silently moves a row on top
    # of another line. Parse what we are about to write, and compare the three
    # layers cell-for-cell against what we read, before it touches the disk.
    try:
        after = json.loads(out)
    except Exception as exc:
        print("  ! %s: rewrite did not produce valid JSON (%s) -- NOT written"
              % (path.name, str(exc)[:80]))
        return -1
    before = json.loads(src)
    for k in ("structure", "utilities", "interactables"):
        b = before.get("layers", {}).get(k) or []
        a = after.get("layers", {}).get(k) or []
        if len(b) != len(a) or any(len(br) != len(ar) for br, ar in zip(b, a)):
            print("  ! %s: %s changed shape -- NOT written" % (path.name, k))
            return -1
    if before.get("layers", {}).get("structure") != after.get("layers", {}).get("structure"):
        print("  ! %s: the structure layer moved -- NOT written" % path.name)
        return -1
    tmp = path.with_suffix(".json.tmp")
    with open(tmp, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(out)
    os.replace(tmp, path)
    return changed


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="write the fix (default is a scan)")
    ap.add_argument("--map", default="", help="restrict to one map name")
    ap.add_argument("--scan", action="store_true")
    args = ap.parse_args()

    paths = sorted(MAPS_DIR.glob("*/map_data.json"))
    if args.map:
        paths = [p for p in paths if p.parent.name == args.map]
        if not paths:
            print("no such map: %s" % args.map)
            return 2

    print("=== EMPTY-CELL FILLER (utilities + interactables) ===")
    print("%d maps read" % len(paths))
    offenders = []
    for p in paths:
        bad = scan_map(p)
        if bad:
            offenders.append((p, bad))

    if not offenders:
        print("OK: every map fills its empty cells with \" \" or \"\".")
        return 0

    bulk = [(p, {k: v for k, v in b.items() if v[2]}) for p, b in offenders]
    bulk = [(p, b) for p, b in bulk if b]
    stray = [(p, {k: v for k, v in b.items() if not v[2]}) for p, b in offenders]
    stray = [(p, b) for p, b in stray if b]

    total_cells = 0
    if bulk:
        print("\nBULK FILLER -- a whole layer written with the wrong blank. Mechanical, "
              "no information in it, safe to rewrite:")
        for p, b in bulk:
            total_cells += sum(v[1] for v in b.values())
            print("  %-28s %s" % (p.parent.name,
                                  ", ".join("%s=%r x%d" % (k, v[0], v[1]) for k, v in b.items())))
    if stray:
        print("\nSTRAY CELLS -- a properly blank layer with a few cells that are not "
              "blank and not tokens. These are almost certainly LOST TOKENS, so they "
              "are reported and NOT rewritten: turning one into \" \" would erase the "
              "evidence and call it a repair. Fix each by hand, or delete it knowingly:")
        for p, b in stray:
            print("  %-28s %s" % (p.parent.name,
                                  ", ".join("%s=%r x%d" % (k, v[0], v[1]) for k, v in b.items())))
    print("\n%d map(s): %d bulk cell(s) fixable, %d map(s) with strays to read by hand."
          % (len(offenders), total_cells, len(stray)))

    if not args.apply:
        print("\n(scan only -- pass --apply to normalise the bulk cases)")
        return 1
    if not bulk:
        print("\nnothing to apply -- every finding is a stray that must be read by hand.")
        return 1

    print("\n--- applying ---")
    failed = 0
    for p, bad in bulk:
        before = _real_cells(p)
        n = rewrite(p, bad)
        if n < 0:
            failed += 1
            continue
        after = _real_cells(p)
        if before != after:
            print("  ! %s: REAL TOKENS CHANGED -- %d before, %d after" %
                  (p.parent.name, sum(before.values()), sum(after.values())))
            failed += 1
            continue
        # only BULK residue is a failure here -- a stray in the same map is a
        # finding this tool deliberately declines to touch, not an unfinished write
        still = [k for k, v in scan_map(p).items() if v[2]]
        print("  %-28s %4d cells normalised, %d real tokens intact%s" %
              (p.parent.name, n, sum(after.values()), "" if not still else "  ! STILL BAD"))
        if still:
            failed += 1
    return 1 if (failed or stray) else 0


if __name__ == "__main__":
    sys.exit(main())
