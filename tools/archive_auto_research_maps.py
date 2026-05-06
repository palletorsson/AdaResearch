"""
archive_auto_research_maps.py

One-time housekeeping: relocate every auto-research-generated map
(*_v<N>_<style>) out of commons/maps/ into _archive/auto_research_maps/
so the live Ada Godot project sees only ~1,100 curated entries instead
of 2,881.

Safety nets:
  • Walks every commons/maps/sequences/*.json and harvests every
    map name referenced. Any directory whose name appears in a
    sequence is SKIPPED (one is currently in this state:
    AdvancedLaboratory_Lab_Equipment_Simulation_v5_symmetric — it was
    promoted from research output to spine-curated).
  • Default mode is --dry-run: prints what would move, no changes.
    Pass --apply to actually execute.
  • Uses os.rename (atomic per directory). Git on the next `git
    status` will detect the moves as renames automatically because
    the contents are unchanged.

Result:
  commons/maps/                        ~2,881  →  ~1,100 entries
  _archive/auto_research_maps/         empty   →  ~1,764 dirs

Run:
  python tools/archive_auto_research_maps.py            # dry run
  python tools/archive_auto_research_maps.py --apply    # commit
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sys
import time
from pathlib import Path

# ─────────────────────────────────────────────────────────────────────
# Paths
# ─────────────────────────────────────────────────────────────────────

REPO = Path(r"C:\Users\palle\Documents\GitHub\AdaResearch_46")
MAPS = REPO / "commons" / "maps"
SEQS = MAPS / "sequences"
ARCHIVE = REPO / "_archive" / "auto_research_maps"

# Auto-research suffix — the seven topology styles the generator emits.
# Anchored to end-of-name so we don't catch things like
# "..._v3_terraced_demo" (which would be a hand-curated derivative).
SUFFIX_RE = re.compile(
    r".+_v\d+_(?:corridor|bsp|terraced|islands|symmetric|column_grid|curve)$"
)


# ─────────────────────────────────────────────────────────────────────
# Step 1 — read every sequence file, collect all referenced map names.
# Anything that appears in a sequence's "maps" array (or anywhere as
# a quoted string matching a directory name) is OFF-LIMITS.
# ─────────────────────────────────────────────────────────────────────

def referenced_map_names() -> set[str]:
    referenced: set[str] = set()
    if not SEQS.is_dir():
        print(f"  ! sequences dir missing: {SEQS}", file=sys.stderr)
        return referenced

    for seq_path in sorted(SEQS.glob("*.json")):
        try:
            with seq_path.open("r", encoding="utf-8") as f:
                doc = json.load(f)
        except Exception as e:
            print(f"  ! could not parse {seq_path.name}: {e}", file=sys.stderr)
            continue

        # Walk the JSON looking for "maps": [...] arrays AND any
        # standalone string that is a known directory name. Belt +
        # braces; sequences vary in shape.
        def visit(node):
            if isinstance(node, dict):
                for k, v in node.items():
                    if k == "maps" and isinstance(v, list):
                        for m in v:
                            if isinstance(m, str):
                                referenced.add(m)
                    else:
                        visit(v)
            elif isinstance(node, list):
                for item in node:
                    visit(item)
            elif isinstance(node, str):
                # Loose match: if a string looks like a dir name and the
                # dir actually exists, treat as referenced. This catches
                # references in odd places (e.g. "first_map" fields).
                if SUFFIX_RE.match(node):
                    candidate = MAPS / node
                    if candidate.is_dir():
                        referenced.add(node)

        visit(doc)
    return referenced


# ─────────────────────────────────────────────────────────────────────
# Step 2 — find candidates. Walk commons/maps/, match the suffix
# pattern, exclude anything in the referenced set.
# ─────────────────────────────────────────────────────────────────────

def find_candidates(protected: set[str]) -> list[Path]:
    cands: list[Path] = []
    for p in sorted(MAPS.iterdir()):
        if not p.is_dir():
            continue
        if not SUFFIX_RE.match(p.name):
            continue
        if p.name in protected:
            continue
        cands.append(p)
    return cands


# ─────────────────────────────────────────────────────────────────────
# Step 3 — move each into _archive/auto_research_maps/
# ─────────────────────────────────────────────────────────────────────

def archive_dir(src: Path) -> tuple[bool, str]:
    dest = ARCHIVE / src.name
    if dest.exists():
        return False, f"destination exists, skipping: {dest}"
    try:
        # os.rename is atomic on the same filesystem and faster than
        # shutil.move for a few thousand small dirs. shutil.move falls
        # back automatically across filesystems, but in our case the
        # archive is on the same drive.
        os.rename(str(src), str(dest))
    except OSError as e:
        try:
            shutil.move(str(src), str(dest))
        except Exception as e2:
            return False, f"move failed: {e2}"
    return True, ""


# ─────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--apply",
        action="store_true",
        help="actually move the directories (default: dry-run)",
    )
    args = parser.parse_args()

    print("ada_research housekeeping - archive auto-research maps")
    print("=" * 60)

    if not MAPS.is_dir():
        print(f"!! commons/maps not found: {MAPS}")
        return 1

    print(f"  reading sequences: {SEQS}")
    protected = referenced_map_names()
    print(f"    {len(protected)} map names referenced by sequences")
    if protected:
        # Show the protected ones that match the suffix pattern (the
        # ones we'd otherwise have moved). Most won't match.
        stuck = [n for n in sorted(protected) if SUFFIX_RE.match(n)]
        if stuck:
            print(f"    {len(stuck)} of those are auto-research-suffixed:")
            for n in stuck:
                print(f"      -{n}  (PROTECTED — will not be moved)")

    print(f"  scanning {MAPS}")
    cands = find_candidates(protected)
    print(f"    {len(cands)} candidates for archive")

    if not args.apply:
        print()
        print("DRY RUN — no files moved. Re-run with --apply to commit.")
        # Show first few + last few so user can sanity-check the list
        if cands:
            print("  first 5:", *[c.name for c in cands[:5]], sep="\n    ")
            if len(cands) > 10:
                print("  ...")
            print("  last 5: ", *[c.name for c in cands[-5:]], sep="\n    ")
        return 0

    # Apply — make sure the archive dir exists first.
    ARCHIVE.mkdir(parents=True, exist_ok=True)

    # Stamp a README so future-us / future-Palle remembers what this is.
    readme = ARCHIVE.parent / "README.md"
    if not readme.exists():
        readme.write_text(
            "# _archive/\n\n"
            "Material that's not part of the active Ada Godot project but "
            "kept around for reference / future use.\n\n"
            "## auto_research_maps/\n\n"
            f"Snapshot of the auto-research-generated maps that were "
            f"polluting `commons/maps/`. Moved {time.strftime('%Y-%m-%d')} "
            f"by `tools/archive_auto_research_maps.py`. Each is just a "
            f"`map_data.json` with a structure layer the generator "
            f"sampled — useful as scenario seeds (see the 100-presets "
            f"plan).\n\n"
            "Naming: `<base>_v<N>_<style>` where `<style>` is one of "
            "`corridor`, `bsp`, `terraced`, `islands`, `symmetric`, "
            "`column_grid`, `curve`.\n",
            encoding="utf-8",
        )
        print(f"    wrote {readme}")

    print()
    print(f"applying {len(cands)} moves → {ARCHIVE}")
    started = time.time()
    moved = 0
    failed: list[tuple[str, str]] = []
    for i, src in enumerate(cands, 1):
        ok, err = archive_dir(src)
        if ok:
            moved += 1
        else:
            failed.append((src.name, err))
        if i % 200 == 0 or i == len(cands):
            elapsed = time.time() - started
            print(f"  {i}/{len(cands)}  ({moved} moved, {len(failed)} failed)  "
                  f"{elapsed:.1f}s")

    print()
    print(f"DONE: {moved} moved, {len(failed)} failed in "
          f"{time.time() - started:.1f}s")
    if failed:
        print("failures:")
        for name, err in failed[:20]:
            print(f"  {name}: {err}")
        if len(failed) > 20:
            print(f"  ... and {len(failed) - 20} more")

    # Print follow-up reminder.
    print()
    print("next steps:")
    print("  1. run `git status` — git will detect the moves as renames")
    print("  2. confirm the count: ls commons/maps | wc -l   (~1100 expected)")
    print("  3. if Godot is running, close + reopen so .godot/ rebuilds")
    print("  4. commit with a message like:")
    print("       chore: archive auto-research maps to _archive/")
    return 0 if not failed else 2


if __name__ == "__main__":
    raise SystemExit(main())
