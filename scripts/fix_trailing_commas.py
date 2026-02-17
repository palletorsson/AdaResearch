#!/usr/bin/env python3
"""
fix_trailing_commas.py — Fix trailing commas in map_data.json files.

Godot's parser accepts them, Python's json.loads doesn't.
This script strips trailing commas before ] and } so the files are strict JSON.

Usage:
    python scripts/fix_trailing_commas.py --dry-run     # Preview what would change
    python scripts/fix_trailing_commas.py               # Fix all broken files
    python scripts/fix_trailing_commas.py path/to/file   # Fix one file
"""

import argparse
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
MAPS_DIR = REPO / "commons" / "maps"

# Regex: comma followed by optional whitespace/newlines, then ] or }
TRAILING_COMMA = re.compile(r',(\s*[}\]])')


def has_trailing_commas(text: str) -> bool:
    return bool(TRAILING_COMMA.search(text))


def fix_trailing_commas(text: str) -> str:
    return TRAILING_COMMA.sub(r'\1', text)


def is_valid_json(text: str) -> bool:
    try:
        json.loads(text)
        return True
    except Exception:
        return False


def find_broken_maps() -> list[Path]:
    maps = []
    for md in sorted(MAPS_DIR.rglob("map_data*.json")):
        try:
            raw = md.read_text(encoding="utf-8")
            if not is_valid_json(raw) and has_trailing_commas(raw):
                maps.append(md)
        except Exception:
            pass
    return maps


def main():
    parser = argparse.ArgumentParser(description="Fix trailing commas in map JSON files")
    parser.add_argument("path", nargs="?", help="Single file to fix")
    parser.add_argument("--dry-run", action="store_true", help="Preview only")
    args = parser.parse_args()

    if args.path:
        targets = [Path(args.path)]
    else:
        targets = find_broken_maps()

    if not targets:
        print("No files with trailing commas found.")
        return 0

    fixed = 0
    still_broken = 0

    for p in targets:
        raw = p.read_text(encoding="utf-8")
        cleaned = fix_trailing_commas(raw)

        if is_valid_json(cleaned):
            rel = p.relative_to(REPO)
            if args.dry_run:
                print(f"  WOULD FIX: {rel}")
            else:
                p.write_text(cleaned, encoding="utf-8")
                print(f"  FIXED: {rel}")
            fixed += 1
        else:
            rel = p.relative_to(REPO)
            print(f"  STILL BROKEN after comma fix: {rel}")
            still_broken += 1

    print(f"\n{'Would fix' if args.dry_run else 'Fixed'}: {fixed}")
    if still_broken:
        print(f"Still broken (other JSON issues): {still_broken}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
