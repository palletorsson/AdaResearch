#!/usr/bin/env python3
"""
Move all uncommitted PNG/JPG images out of the Godot repo and into the
encyclopedia's public/ directory. Generated images don't belong in the
Godot project — they're rendered artifacts that the web encyclopedia
serves to users. Their natural home is ada_encyclopedia/public/.

Two source families:

  commons/maps/<MapName>/*.png
      → ada_encyclopedia/public/map-thumbnails/<MapName>/*.png
      Map preview thumbnails written by the Godot capture pipeline.

  ada_run/captures/<category>/<subname>/*.png  (+ capture_report.json)
      → ada_encyclopedia/public/godot-captures/<category>/<subname>/*
      Capture-script outputs (substrate research, spine research, etc.)

We move (not copy) so the Godot repo no longer carries the files. A
companion .gitignore patch makes future captures ignored, so this is a
one-time cleanup.

Run:  python tools/move_uncommitted_images.py
Dry:  python tools/move_uncommitted_images.py --dry-run
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
ENCYCLOPEDIA = Path(os.environ.get(
    "ADA_ENCYCLOPEDIA_PATH",
    r"C:\Users\palle\Documents\GitHub\ada_encyclopedia",
))

IMG_SUFFIXES = {".png", ".jpg", ".jpeg", ".gif", ".webp"}


def list_untracked_images() -> list[Path]:
    """Return all untracked image files relative to PROJECT_ROOT."""
    cmd = ["git", "ls-files", "--others", "--exclude-standard"]
    out = subprocess.check_output(cmd, cwd=str(PROJECT_ROOT), text=True)
    paths = []
    for line in out.splitlines():
        p = Path(line.strip())
        if p.suffix.lower() in IMG_SUFFIXES:
            paths.append(p)
    return paths


def target_for(rel_path: Path) -> Path | None:
    """Translate a Godot-repo-relative image path into its encyclopedia
    counterpart. Returns None if the path doesn't match a known pattern.
    """
    parts = rel_path.parts
    if len(parts) >= 3 and parts[0] == "commons" and parts[1] == "maps":
        # commons/maps/<MapName>/<file>
        return ENCYCLOPEDIA / "public" / "map-thumbnails" / Path(*parts[2:])
    if len(parts) >= 3 and parts[0] == "ada_run" and parts[1] == "captures":
        # ada_run/captures/<rest>
        return ENCYCLOPEDIA / "public" / "godot-captures" / Path(*parts[2:])
    if (
        len(parts) >= 4
        and parts[0] == "doc"
        and parts[1] == "reports"
        and parts[2] in {"map_comparisons", "map_strategies"}
    ):
        # doc/reports/map_comparisons/<rest> -> public/map-comparisons/<rest>
        # doc/reports/map_strategies/<rest>  -> public/map-strategies/<rest>
        web_dir = parts[2].replace("_", "-")
        return ENCYCLOPEDIA / "public" / web_dir / Path(*parts[3:])
    return None


def companion_files(image_path: Path) -> list[Path]:
    """Return any sibling capture_report.json files alongside an image
    that should travel with it. Avoids leaving orphaned reports."""
    parent = PROJECT_ROOT / image_path.parent
    sidecars: list[Path] = []
    if parent.exists():
        for f in parent.iterdir():
            if f.name == "capture_report.json":
                sidecars.append(image_path.parent / f.name)
    return sidecars


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--dry-run", action="store_true",
                    help="Print moves without performing them")
    args = ap.parse_args()

    if not ENCYCLOPEDIA.exists():
        print(f"FATAL: encyclopedia path missing — {ENCYCLOPEDIA}")
        return 2

    images = list_untracked_images()
    print(f"Found {len(images)} untracked image files in {PROJECT_ROOT}")

    skipped: list[Path] = []
    moves: list[tuple[Path, Path]] = []
    seen_companions: set[Path] = set()

    for img in images:
        target = target_for(img)
        if target is None:
            skipped.append(img)
            continue
        moves.append((PROJECT_ROOT / img, target))
        # Sidecars
        for s in companion_files(img):
            if s in seen_companions:
                continue
            seen_companions.add(s)
            t = target_for(s)
            if t is not None:
                moves.append((PROJECT_ROOT / s, t))

    if skipped:
        print(f"\nSkipped {len(skipped)} image(s) outside known patterns:")
        for s in skipped[:5]:
            print(f"  {s}")
        if len(skipped) > 5:
            print(f"  ... +{len(skipped) - 5} more")

    print(f"\nWill move {len(moves)} files (images + capture_report sidecars).")

    if args.dry_run:
        print("\n(dry-run; not moving)")
        for src, dst in moves[:5]:
            print(f"  {src.relative_to(PROJECT_ROOT)} -> {dst.relative_to(ENCYCLOPEDIA)}")
        if len(moves) > 5:
            print(f"  ... +{len(moves) - 5} more")
        return 0

    moved = 0
    failed: list[tuple[Path, Path, str]] = []
    for src, dst in moves:
        if not src.exists():
            failed.append((src, dst, "source missing"))
            continue
        try:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(src), str(dst))
            moved += 1
            if moved % 200 == 0:
                print(f"  ... {moved} moved")
        except Exception as e:
            failed.append((src, dst, str(e)))

    print(f"\nMoved {moved} files.")
    if failed:
        print(f"FAILED {len(failed)}:")
        for src, dst, reason in failed[:10]:
            print(f"  {src.name}: {reason}")

    # Report empty source dirs that can be deleted (no contents left)
    empty_dirs: list[Path] = []
    seen_dirs: set[Path] = set()
    for src, _ in moves:
        d = src.parent
        if d in seen_dirs:
            continue
        seen_dirs.add(d)
        if d.exists() and not any(d.iterdir()):
            empty_dirs.append(d)
    if empty_dirs:
        print(f"\n{len(empty_dirs)} source dir(s) are now empty and can be removed:")
        for d in empty_dirs[:10]:
            print(f"  {d.relative_to(PROJECT_ROOT)}")
        if len(empty_dirs) > 10:
            print(f"  ... +{len(empty_dirs) - 10} more")

    return 0 if not failed else 1


if __name__ == "__main__":
    sys.exit(main())
